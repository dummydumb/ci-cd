package com.ipmssys.preconditionraw.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

import com.ipmssys.configuration.GenericDAO;
import com.ipmssys.item.model.Item;
import com.ipmssys.preconditionraw.model.PreconditionRaw;

/**
 * Data access for PRECONDITION_RAW. Reads join ITEM so the screen shows the
 * item name/group. One raw row per (plan, item).
 */
public class PreconditionRawDAO implements GenericDAO<PreconditionRaw> {

    private final Connection con;

    public PreconditionRawDAO(Connection con) {
        this.con = con;
    }

    private static final String SELECT_ALL =
            "SELECT pr.PRECONDITION_RAW_ID, pr.PLAN_ID, pr.CAP_CODE, pr.LOTS_PER_BATCH, "
          + "pr.INTERNAL_SHEET, pr.DUMMY_SHEET, pr.BLK_PER_LOT, pr.KPCS_PER_LOT, pr.SEC_PER_SHT, "
          + "pr.EFF, pr.LOTS_PER_MONTH, pr.CREATED_AT, pr.UPDATED_AT, "
          + "i.ITEM_ID, i.ITEM_NAME, i.GROUP_CODE "
          + "FROM PRECONDITION_RAW pr "
          + "JOIN ITEM i ON i.ITEM_ID = pr.ITEM_ID ";

    // ------------------------------------------------------------------ //
    //  GenericDAO contract
    // ------------------------------------------------------------------ //

    @Override
    public PreconditionRaw get(Object id) throws SQLException {
        String sql = SELECT_ALL + "WHERE pr.PRECONDITION_RAW_ID = ?";
        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, (Integer) id);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    @Override
    public PreconditionRaw create(PreconditionRaw pr) throws SQLException {
        String sql = "INSERT INTO PRECONDITION_RAW "
                   + "(PRECONDITION_RAW_ID, PLAN_ID, ITEM_ID, CAP_CODE, LOTS_PER_BATCH, INTERNAL_SHEET, "
                   + "DUMMY_SHEET, BLK_PER_LOT, KPCS_PER_LOT, SEC_PER_SHT, EFF, LOTS_PER_MONTH) "
                   + "VALUES (PRECONDITION_RAW_SEQ.NEXTVAL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (PreparedStatement pstmt = con.prepareStatement(sql, new String[] { "PRECONDITION_RAW_ID" })) {
            bindBody(pstmt, pr);
            if (pstmt.executeUpdate() > 0) {
                try (ResultSet keys = pstmt.getGeneratedKeys()) {
                    if (keys.next()) {
                        pr.setPreconditionRawId(keys.getInt(1));
                    }
                }
                return pr;
            }
        }
        return null;
    }

    @Override
    public PreconditionRaw update(PreconditionRaw pr) throws SQLException {
        String sql = "UPDATE PRECONDITION_RAW SET "
                   + "ITEM_ID = ?, CAP_CODE = ?, LOTS_PER_BATCH = ?, INTERNAL_SHEET = ?, DUMMY_SHEET = ?, "
                   + "BLK_PER_LOT = ?, KPCS_PER_LOT = ?, SEC_PER_SHT = ?, EFF = ?, LOTS_PER_MONTH = ?, "
                   + "UPDATED_AT = SYSTIMESTAMP "
                   + "WHERE PRECONDITION_RAW_ID = ?";

        // Note: PLAN_ID is fixed on update; only the body changes.
        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, pr.getItem().getItemId());
            pstmt.setString(2, pr.getCapCode());
            pstmt.setInt(3, pr.getLotsPerBatch());
            pstmt.setInt(4, pr.getInternalSheet());
            pstmt.setInt(5, pr.getDummySheet());
            pstmt.setInt(6, pr.getBlkPerLot());
            pstmt.setDouble(7, pr.getKpcsPerLot());
            pstmt.setDouble(8, pr.getSecPerSht());
            pstmt.setDouble(9, pr.getEff());
            pstmt.setInt(10, pr.getLotsPerMonth());
            pstmt.setInt(11, pr.getPreconditionRawId());
            if (pstmt.executeUpdate() > 0) {
                return pr;
            }
        }
        return null;
    }

    @Override
    public PreconditionRaw delete(PreconditionRaw pr) throws SQLException {
        String sql = "DELETE FROM PRECONDITION_RAW WHERE PRECONDITION_RAW_ID = ?";
        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, pr.getPreconditionRawId());
            if (pstmt.executeUpdate() > 0) {
                return pr;
            }
        }
        return null;
    }

    @Override
    public List<PreconditionRaw> listAll() throws SQLException {
        String sql = SELECT_ALL + "ORDER BY pr.PLAN_ID ASC, i.ITEM_NAME ASC";
        List<PreconditionRaw> list = new ArrayList<>();
        try (PreparedStatement pstmt = con.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        }
        return list;
    }

    /** Duplicate check: a raw row already exists for this (plan, item). */
    @Override
    public PreconditionRaw findDuplicate(PreconditionRaw pr) throws SQLException {
        String sql = SELECT_ALL + "WHERE pr.PLAN_ID = ? AND pr.ITEM_ID = ?";
        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, pr.getPlanId());
            pstmt.setInt(2, pr.getItem().getItemId());
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    // ------------------------------------------------------------------ //
    //  Precondition-specific queries
    // ------------------------------------------------------------------ //

    /** All raw rows for a plan (with item), by item name — feeds the compute view. */
    public List<PreconditionRaw> getByPlanId(int planId) throws SQLException {
        String sql = SELECT_ALL + "WHERE pr.PLAN_ID = ? ORDER BY i.ITEM_NAME ASC";
        List<PreconditionRaw> list = new ArrayList<>();
        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, planId);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    /** Duplicate check on update: another row already holds this (plan, item). */
    public PreconditionRaw findDuplicateUpdate(PreconditionRaw pr) throws SQLException {
        String sql = SELECT_ALL
                   + "WHERE pr.PLAN_ID = ? AND pr.ITEM_ID = ? AND pr.PRECONDITION_RAW_ID <> ?";
        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, pr.getPlanId());
            pstmt.setInt(2, pr.getItem().getItemId());
            pstmt.setInt(3, pr.getPreconditionRawId());
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    // ------------------------------------------------------------------ //
    //  Helpers
    // ------------------------------------------------------------------ //

    /** Binds create's 11 body params (PLAN_ID, ITEM_ID, then the measures). */
    private void bindBody(PreparedStatement pstmt, PreconditionRaw pr) throws SQLException {
        pstmt.setInt(1, pr.getPlanId());
        pstmt.setInt(2, pr.getItem().getItemId());
        pstmt.setString(3, pr.getCapCode());
        pstmt.setInt(4, pr.getLotsPerBatch());
        pstmt.setInt(5, pr.getInternalSheet());
        pstmt.setInt(6, pr.getDummySheet());
        pstmt.setInt(7, pr.getBlkPerLot());
        pstmt.setDouble(8, pr.getKpcsPerLot());
        pstmt.setDouble(9, pr.getSecPerSht());
        pstmt.setDouble(10, pr.getEff());
        pstmt.setInt(11, pr.getLotsPerMonth());
    }

    private PreconditionRaw mapRow(ResultSet rs) throws SQLException {
        PreconditionRaw pr = new PreconditionRaw();
        pr.setPreconditionRawId(rs.getInt("PRECONDITION_RAW_ID"));
        pr.setPlanId(rs.getInt("PLAN_ID"));
        pr.setCapCode(rs.getString("CAP_CODE"));
        pr.setLotsPerBatch(rs.getInt("LOTS_PER_BATCH"));
        pr.setInternalSheet(rs.getInt("INTERNAL_SHEET"));
        pr.setDummySheet(rs.getInt("DUMMY_SHEET"));
        pr.setBlkPerLot(rs.getInt("BLK_PER_LOT"));
        pr.setKpcsPerLot(rs.getDouble("KPCS_PER_LOT"));
        pr.setSecPerSht(rs.getDouble("SEC_PER_SHT"));
        pr.setEff(rs.getDouble("EFF"));
        pr.setLotsPerMonth(rs.getInt("LOTS_PER_MONTH"));

        Timestamp created = rs.getTimestamp("CREATED_AT");
        pr.setCreatedAt(created != null ? created.toLocalDateTime() : null);
        Timestamp updated = rs.getTimestamp("UPDATED_AT");
        pr.setUpdatedAt(updated != null ? updated.toLocalDateTime() : null);

        Item item = new Item();
        item.setItemId(rs.getInt("ITEM_ID"));
        item.setItemName(rs.getString("ITEM_NAME"));
        item.setGroupCode(rs.getString("GROUP_CODE"));
        pr.setItem(item);
        return pr;
    }
}
