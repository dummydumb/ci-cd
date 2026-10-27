package com.ipmssys.item.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.ipmssys.configuration.GenericDAO;
import com.ipmssys.item.model.Item;
import com.ipmssys.machine.model.Machine;
import com.ipmssys.machinetype.model.MachineType;

/**
 * Data access for ITEM and its ITEM_MACHINE junction.
 *
 * The read methods (get, listAll) left-join ITEM_MACHINE -> MACHINE ->
 * MACHINE_TYPE and fold the rows into one Item per id, each carrying its
 * qualified machines. Machine links are rewritten as a set via
 * replaceMachines(), called by the servlet inside the same transaction.
 */
public class ItemDAO implements GenericDAO<Item> {

    private final Connection con;

    public ItemDAO(Connection con) {
        this.con = con;
    }

    private static final String SELECT_ITEM_WITH_MACHINES =
            "SELECT i.ITEM_ID, i.ITEM_NAME, i.GROUP_CODE, i.CREATED_AT, i.UPDATED_AT, "
          + "m.MACHINE_ID, m.MACHINE_NAME, m.MACHINE_USAGE, "
          + "mt.MACHINE_TYPE_ID, mt.MACHINE_CODE, mt.MACHINE_NAME AS TYPE_NAME "
          + "FROM ITEM i "
          + "LEFT JOIN ITEM_MACHINE im ON im.ITEM_ID = i.ITEM_ID "
          + "LEFT JOIN MACHINE m       ON m.MACHINE_ID = im.MACHINE_ID "
          + "LEFT JOIN MACHINE_TYPE mt ON mt.MACHINE_TYPE_ID = m.MACHINE_TYPE_ID ";

    // ------------------------------------------------------------------ //
    //  GenericDAO contract
    // ------------------------------------------------------------------ //

    /** Load one item with its qualified machines. */
    @Override
    public Item get(Object itemId) throws SQLException {
        String sql = SELECT_ITEM_WITH_MACHINES
                   + "WHERE i.ITEM_ID = ? ORDER BY m.MACHINE_NAME ASC";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, (Integer) itemId);
            try (ResultSet rs = pstmt.executeQuery()) {
                List<Item> items = foldRows(rs);
                return items.isEmpty() ? null : items.get(0);
            }
        }
    }

    /** Insert the ITEM row only. Machine links are set via replaceMachines(). */
    @Override
    public Item create(Item item) throws SQLException {
        String sql = "INSERT INTO ITEM (ITEM_ID, ITEM_NAME, GROUP_CODE) "
                   + "VALUES (ITEM_SEQ.NEXTVAL, ?, ?)";

        // Need the generated id back so the caller can write the junction.
        try (PreparedStatement pstmt = con.prepareStatement(sql, new String[] { "ITEM_ID" })) {
            pstmt.setString(1, item.getItemName());
            pstmt.setString(2, item.getGroupCode());
            if (pstmt.executeUpdate() > 0) {
                try (ResultSet keys = pstmt.getGeneratedKeys()) {
                    if (keys.next()) {
                        item.setItemId(keys.getInt(1));
                    }
                }
                return item;
            }
        }
        return null;
    }

    /** Update the ITEM row only. Machine links are set via replaceMachines(). */
    @Override
    public Item update(Item item) throws SQLException {
        String sql = "UPDATE ITEM SET ITEM_NAME = ?, GROUP_CODE = ?, UPDATED_AT = SYSTIMESTAMP "
                   + "WHERE ITEM_ID = ?";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setString(1, item.getItemName());
            pstmt.setString(2, item.getGroupCode());
            pstmt.setInt(3, item.getItemId());
            if (pstmt.executeUpdate() > 0) {
                return item;
            }
        }
        return null;
    }

    /** Delete the item. ITEM_MACHINE rows cascade via the FK. */
    @Override
    public Item delete(Item item) throws SQLException {
        String sql = "DELETE FROM ITEM WHERE ITEM_ID = ?";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, item.getItemId());
            if (pstmt.executeUpdate() > 0) {
                return item;
            }
        }
        return null;
    }

    /** All items with their qualified machines, by name. */
    @Override
    public List<Item> listAll() throws SQLException {
        String sql = SELECT_ITEM_WITH_MACHINES
                   + "ORDER BY i.ITEM_NAME ASC, m.MACHINE_NAME ASC";

        try (PreparedStatement pstmt = con.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            return foldRows(rs);
        }
    }

    /** Duplicate check by item name (case-insensitive). */
    @Override
    public Item findDuplicate(Item item) throws SQLException {
        String sql = "SELECT ITEM_ID, ITEM_NAME, GROUP_CODE, CREATED_AT, UPDATED_AT "
                   + "FROM ITEM WHERE UPPER(ITEM_NAME) = UPPER(?)";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setString(1, item.getItemName());
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return mapItemRow(rs);
                }
            }
        }
        return null;
    }

    // ------------------------------------------------------------------ //
    //  Item-specific queries
    // ------------------------------------------------------------------ //

    /** Duplicate check on update: another item already holds this name. */
    public Item findDuplicateUpdate(Item item) throws SQLException {
        String sql = "SELECT ITEM_ID, ITEM_NAME, GROUP_CODE, CREATED_AT, UPDATED_AT "
                   + "FROM ITEM WHERE UPPER(ITEM_NAME) = UPPER(?) AND ITEM_ID <> ?";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setString(1, item.getItemName());
            pstmt.setInt(2, item.getItemId());
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return mapItemRow(rs);
                }
            }
        }
        return null;
    }

    /**
     * Rewrite an item's qualified-machine set: delete all existing links,
     * then insert the given machine ids. Call inside the caller's transaction.
     */
    public void replaceMachines(int itemId, int[] machineIds) throws SQLException {
        try (PreparedStatement del = con.prepareStatement(
                "DELETE FROM ITEM_MACHINE WHERE ITEM_ID = ?")) {
            del.setInt(1, itemId);
            del.executeUpdate();
        }

        if (machineIds == null || machineIds.length == 0) {
            return;
        }

        String insert = "INSERT INTO ITEM_MACHINE (ITEM_MACHINE_ID, ITEM_ID, MACHINE_ID) "
                      + "VALUES (ITEM_MACHINE_SEQ.NEXTVAL, ?, ?)";
        try (PreparedStatement ins = con.prepareStatement(insert)) {
            for (int machineId : machineIds) {
                ins.setInt(1, itemId);
                ins.setInt(2, machineId);
                ins.addBatch();
            }
            ins.executeBatch();
        }
    }

    // ------------------------------------------------------------------ //
    //  Helpers
    // ------------------------------------------------------------------ //

    /** Fold joined rows into one Item per id, collecting its machines. */
    private List<Item> foldRows(ResultSet rs) throws SQLException {
        Map<Integer, Item> byId = new LinkedHashMap<>();

        while (rs.next()) {
            int itemId = rs.getInt("ITEM_ID");
            Item item = byId.get(itemId);
            if (item == null) {
                item = mapItemRow(rs);
                byId.put(itemId, item);
            }

            int machineId = rs.getInt("MACHINE_ID");
            if (!rs.wasNull()) {
                item.getMachines().add(mapMachineRow(rs));
            }
        }

        return new ArrayList<>(byId.values());
    }

    private Item mapItemRow(ResultSet rs) throws SQLException {
        Item item = new Item();
        item.setItemId(rs.getInt("ITEM_ID"));
        item.setItemName(rs.getString("ITEM_NAME"));
        item.setGroupCode(rs.getString("GROUP_CODE"));

        Timestamp created = rs.getTimestamp("CREATED_AT");
        item.setCreatedAt(created != null ? created.toLocalDateTime() : null);

        Timestamp updated = rs.getTimestamp("UPDATED_AT");
        item.setUpdatedAt(updated != null ? updated.toLocalDateTime() : null);
        return item;
    }

    private Machine mapMachineRow(ResultSet rs) throws SQLException {
        Machine machine = new Machine();
        machine.setMachineId(rs.getInt("MACHINE_ID"));
        machine.setMachineName(rs.getString("MACHINE_NAME"));
        machine.setMachineUsage(rs.getString("MACHINE_USAGE"));

        MachineType type = new MachineType();
        type.setMachineTypeId(rs.getInt("MACHINE_TYPE_ID"));
        type.setMachineCode(rs.getString("MACHINE_CODE"));
        type.setMachineName(rs.getString("TYPE_NAME"));
        machine.setMachineType(type);
        return machine;
    }
}
