package com.ipmssys.machineallocation.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.ipmssys.machineallocation.model.MachineAllocation;
import com.ipmssys.machineallocation.model.MachineAllocationGroup;
import com.ipmssys.machineallocation.model.MachineAllocationItem;
import com.ipmssys.machineallocation.model.MachineAllocationMachine;

/**
 * Data access for the machine-allocation tree
 * (MACHINE_ALLOCATION -> _GROUP -> _ITEM / _MACHINE). One allocation per plan;
 * {@link #save(MachineAllocation)} is a full upsert (delete-then-recreate in the
 * caller's transaction), and {@link #getFullByPlanId(int)} returns the whole tree
 * in a single join.
 */
public class MachineAllocationDAO {

    private final Connection con;

    public MachineAllocationDAO(Connection con) {
        this.con = con;
    }

    // ------------------------------------------------------------------ //
    //  Sequences
    // ------------------------------------------------------------------ //

    private int getNextId(String sequenceName) throws SQLException {
        String sql = "SELECT " + sequenceName + ".NEXTVAL FROM DUAL";
        try (PreparedStatement pstmt = con.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            if (rs.next()) { return rs.getInt(1); }
        }
        throw new SQLException("Failed to get next value from sequence: " + sequenceName);
    }

    // ------------------------------------------------------------------ //
    //  Read
    // ------------------------------------------------------------------ //

    /** Header only — used by the planner workflow status check. */
    public MachineAllocation getHeaderByPlanId(int planId) throws SQLException {
        String sql =
            "SELECT ALLOCATION_ID, PLAN_ID, FIX_LIMIT, STATUS, CREATED_AT, UPDATED_AT "
          + "FROM   MACHINE_ALLOCATION "
          + "WHERE  PLAN_ID = ?";
        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, planId);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) { return mapHeader(rs); }
            }
        }
        return null;
    }

    /** Full tree (header + groups + items + machines) in a single join. */
    public MachineAllocation getFullByPlanId(int planId) throws SQLException {
        String sql =
            "SELECT "
          + "    MA.ALLOCATION_ID,   MA.PLAN_ID,          MA.FIX_LIMIT,    MA.STATUS, "
          + "    MA.CREATED_AT,      MA.UPDATED_AT, "
          + "    MAG.GROUP_ID,       MAG.GROUP_NO,         MAG.GROUP_CODE,  MAG.MATERIAL_CODE, "
          + "    MAG.MERGE_KEY,      MAG.GROUPING_MC_PER_DAY, "
          + "    MAG.FIX_REQUIREMENT, MAG.FRACTION1_REQUIREMENT, MAG.STATUS AS GROUP_STATUS, "
          + "    MAI.ITEM_ID,        MAI.ITEM_NAME,        MAI.ITEM_SEQ,    MAI.MC_PER_DAY, "
          + "    MAI.GROUP_CODE AS ITEM_GROUP_CODE, MAI.MATERIAL_CODE AS ITEM_MATERIAL_CODE, "
          + "    MAM.MACHINE_ENTRY_ID, MAM.MACHINE_ROLE,   MAM.MACHINE_SEQ, "
          + "    MAM.MACHINE_NAME,   MAM.REQUIREMENT_VALUE "
          + "FROM  MACHINE_ALLOCATION MA "
          + "LEFT  JOIN MACHINE_ALLOCATION_GROUP   MAG ON MAG.ALLOCATION_ID = MA.ALLOCATION_ID "
          + "LEFT  JOIN MACHINE_ALLOCATION_ITEM    MAI ON MAI.GROUP_ID      = MAG.GROUP_ID "
          + "LEFT  JOIN MACHINE_ALLOCATION_MACHINE MAM ON MAM.GROUP_ID      = MAG.GROUP_ID "
          + "WHERE MA.PLAN_ID = ? "
          + "ORDER BY MAG.GROUP_NO ASC, MAI.ITEM_SEQ ASC, MAM.MACHINE_ROLE ASC, MAM.MACHINE_SEQ ASC";

        MachineAllocation allocation = null;
        Map<Integer, MachineAllocationGroup>   groupMap   = new LinkedHashMap<>();
        Map<Integer, MachineAllocationItem>    itemMap    = new LinkedHashMap<>();
        Map<Integer, MachineAllocationMachine> machineMap = new LinkedHashMap<>();

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, planId);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {

                    if (allocation == null) {
                        allocation = mapHeader(rs);
                    }

                    int groupId = rs.getInt("GROUP_ID");
                    if (rs.wasNull()) { continue; }

                    MachineAllocationGroup group = groupMap.get(groupId);
                    if (group == null) {
                        group = mapGroup(rs);
                        groupMap.put(groupId, group);
                        allocation.getGroups().add(group);
                    }

                    int itemId = rs.getInt("ITEM_ID");
                    if (!rs.wasNull() && !itemMap.containsKey(itemId)) {
                        MachineAllocationItem item = mapItem(rs);
                        itemMap.put(itemId, item);
                        group.getItems().add(item);
                    }

                    int machineEntryId = rs.getInt("MACHINE_ENTRY_ID");
                    if (!rs.wasNull() && !machineMap.containsKey(machineEntryId)) {
                        MachineAllocationMachine machine = mapMachine(rs);
                        machineMap.put(machineEntryId, machine);
                        group.getMachines().add(machine);
                    }
                }
            }
        }

        if (allocation != null) {
            for (MachineAllocationGroup group : allocation.getGroups()) {
                buildGroupConvenienceFields(group);
            }
        }

        return allocation;
    }

    public boolean existsByPlanId(int planId) throws SQLException {
        String sql = "SELECT COUNT(1) FROM MACHINE_ALLOCATION WHERE PLAN_ID = ?";
        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, planId);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) { return rs.getInt(1) > 0; }
            }
        }
        return false;
    }

    // ------------------------------------------------------------------ //
    //  Row mappers
    // ------------------------------------------------------------------ //

    private MachineAllocation mapHeader(ResultSet rs) throws SQLException {
        MachineAllocation ma = new MachineAllocation();
        ma.setAllocationId(rs.getInt("ALLOCATION_ID"));
        ma.setPlanId(rs.getInt("PLAN_ID"));
        ma.setFixLimit(rs.getInt("FIX_LIMIT"));
        ma.setStatus(rs.getString("STATUS"));
        Timestamp ca = rs.getTimestamp("CREATED_AT");
        if (ca != null) { ma.setCreatedAt(ca.toLocalDateTime()); }
        Timestamp ua = rs.getTimestamp("UPDATED_AT");
        if (ua != null) { ma.setUpdatedAt(ua.toLocalDateTime()); }
        return ma;
    }

    private MachineAllocationGroup mapGroup(ResultSet rs) throws SQLException {
        MachineAllocationGroup g = new MachineAllocationGroup();
        g.setGroupId(rs.getInt("GROUP_ID"));
        g.setAllocationId(rs.getInt("ALLOCATION_ID"));
        g.setGroupNo(rs.getInt("GROUP_NO"));
        g.setGroupCode(rs.getString("GROUP_CODE"));
        g.setMaterialCode(rs.getString("MATERIAL_CODE"));
        g.setMergeKey(rs.getString("MERGE_KEY"));
        g.setGroupingMcPerDay(rs.getDouble("GROUPING_MC_PER_DAY"));
        g.setFixRequirement(rs.getDouble("FIX_REQUIREMENT"));
        g.setFraction1Requirement(rs.getDouble("FRACTION1_REQUIREMENT"));
        g.setStatus(rs.getString("GROUP_STATUS"));
        return g;
    }

    private MachineAllocationItem mapItem(ResultSet rs) throws SQLException {
        MachineAllocationItem i = new MachineAllocationItem();
        i.setItemId(rs.getInt("ITEM_ID"));
        i.setGroupId(rs.getInt("GROUP_ID"));
        i.setAllocationId(rs.getInt("ALLOCATION_ID"));
        i.setItemName(rs.getString("ITEM_NAME"));
        i.setItemSeq(rs.getInt("ITEM_SEQ"));
        i.setMcPerDay(rs.getDouble("MC_PER_DAY"));
        i.setGroupCode(rs.getString("ITEM_GROUP_CODE"));
        i.setMaterialCode(rs.getString("ITEM_MATERIAL_CODE"));
        return i;
    }

    private MachineAllocationMachine mapMachine(ResultSet rs) throws SQLException {
        MachineAllocationMachine m = new MachineAllocationMachine();
        m.setMachineEntryId(rs.getInt("MACHINE_ENTRY_ID"));
        m.setGroupId(rs.getInt("GROUP_ID"));
        m.setMachineRole(rs.getString("MACHINE_ROLE"));
        m.setMachineSeq(rs.getInt("MACHINE_SEQ"));
        m.setMachineName(rs.getString("MACHINE_NAME"));
        m.setRequirementValue(rs.getDouble("REQUIREMENT_VALUE"));
        return m;
    }

    /** Builds fixMachineKeys, fraction1MachineKey, and fractionMachines for the JSP. */
    private void buildGroupConvenienceFields(MachineAllocationGroup group) {
        List<String> fixKeys = new ArrayList<>();
        String fraction1Key  = "";
        List<Map<String, Object>> fractionMachines = new ArrayList<>();

        for (MachineAllocationMachine machine : group.getMachines()) {
            if ("FIX".equalsIgnoreCase(machine.getMachineRole())) {
                fixKeys.add(machine.getMachineName());
            } else if ("FRACTION1".equalsIgnoreCase(machine.getMachineRole())) {
                if (fraction1Key.isEmpty()) {
                    fraction1Key = machine.getMachineName();
                }
                Map<String, Object> entry = new HashMap<>();
                entry.put("machine", machine.getMachineName());
                entry.put("share",   machine.getRequirementValue());
                fractionMachines.add(entry);
            }
        }

        group.setFixMachineKeys(fixKeys);
        group.setFraction1MachineKey(fraction1Key);
        group.setFractionMachines(fractionMachines);
    }

    // ------------------------------------------------------------------ //
    //  Write — full upsert (delete-then-recreate, in the caller's txn)
    // ------------------------------------------------------------------ //

    public MachineAllocation save(MachineAllocation allocation) throws SQLException {
        MachineAllocation existing = getHeaderByPlanId(allocation.getPlanId());
        if (existing != null) {
            deleteByAllocationId(existing.getAllocationId());
        }

        int allocationId = getNextId("MACHINE_ALLOCATION_SEQ");

        String headerSql =
            "INSERT INTO MACHINE_ALLOCATION (ALLOCATION_ID, PLAN_ID, FIX_LIMIT, STATUS) "
          + "VALUES (?, ?, ?, 'SAVED')";
        try (PreparedStatement pstmt = con.prepareStatement(headerSql)) {
            pstmt.setInt(1, allocationId);
            pstmt.setInt(2, allocation.getPlanId());
            pstmt.setInt(3, allocation.getFixLimit() <= 0 ? 30 : allocation.getFixLimit());
            pstmt.executeUpdate();
        }
        allocation.setAllocationId(allocationId);

        for (int i = 0; i < allocation.getGroups().size(); i++) {
            MachineAllocationGroup group = allocation.getGroups().get(i);
            group.setAllocationId(allocationId);
            group.setGroupNo(i + 1);
            saveGroup(group);
        }

        return allocation;
    }

    private void saveGroup(MachineAllocationGroup group) throws SQLException {
        int groupId = getNextId("MACHINE_ALLOCATION_GROUP_SEQ");

        String sql =
            "INSERT INTO MACHINE_ALLOCATION_GROUP "
          + "    (GROUP_ID, ALLOCATION_ID, GROUP_NO, GROUP_CODE, MATERIAL_CODE, "
          + "     MERGE_KEY, GROUPING_MC_PER_DAY, FIX_REQUIREMENT, FRACTION1_REQUIREMENT, STATUS) "
          + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1,     groupId);
            pstmt.setInt(2,     group.getAllocationId());
            pstmt.setInt(3,     group.getGroupNo());
            pstmt.setString(4,  group.getGroupCode());
            pstmt.setString(5,  group.getMaterialCode());
            pstmt.setString(6,  group.getMergeKey());
            pstmt.setDouble(7,  group.getGroupingMcPerDay());
            pstmt.setDouble(8,  group.getFixRequirement());
            pstmt.setDouble(9,  group.getFraction1Requirement());
            pstmt.setString(10, isBlank(group.getStatus()) ? "OK" : group.getStatus());
            pstmt.executeUpdate();
        }
        group.setGroupId(groupId);

        if (group.getItems() != null) {
            for (int seq = 0; seq < group.getItems().size(); seq++) {
                MachineAllocationItem item = group.getItems().get(seq);
                item.setGroupId(groupId);
                item.setAllocationId(group.getAllocationId());
                item.setItemSeq(seq + 1);
                saveItem(item);
            }
        }

        if (group.getMachines() != null) {
            for (MachineAllocationMachine machine : group.getMachines()) {
                machine.setGroupId(groupId);
                saveMachine(machine);
            }
        }
    }

    private void saveItem(MachineAllocationItem item) throws SQLException {
        int itemId = getNextId("MACHINE_ALLOCATION_ITEM_SEQ");

        String sql =
            "INSERT INTO MACHINE_ALLOCATION_ITEM "
          + "    (ITEM_ID, GROUP_ID, ALLOCATION_ID, ITEM_NAME, ITEM_SEQ, "
          + "     MC_PER_DAY, GROUP_CODE, MATERIAL_CODE) "
          + "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1,    itemId);
            pstmt.setInt(2,    item.getGroupId());
            pstmt.setInt(3,    item.getAllocationId());
            pstmt.setString(4, item.getItemName());
            pstmt.setInt(5,    item.getItemSeq());
            pstmt.setDouble(6, item.getMcPerDay());
            pstmt.setString(7, item.getGroupCode());
            pstmt.setString(8, item.getMaterialCode());
            pstmt.executeUpdate();
        }
        item.setItemId(itemId);
    }

    private void saveMachine(MachineAllocationMachine machine) throws SQLException {
        int machineEntryId = getNextId("MACHINE_ALLOCATION_MACHINE_SEQ");

        String sql =
            "INSERT INTO MACHINE_ALLOCATION_MACHINE "
          + "    (MACHINE_ENTRY_ID, GROUP_ID, MACHINE_ROLE, MACHINE_SEQ, "
          + "     MACHINE_NAME, REQUIREMENT_VALUE) "
          + "VALUES (?, ?, ?, ?, ?, ?)";
        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1,    machineEntryId);
            pstmt.setInt(2,    machine.getGroupId());
            pstmt.setString(3, machine.getMachineRole());
            pstmt.setInt(4,    machine.getMachineSeq());
            pstmt.setString(5, machine.getMachineName());
            pstmt.setDouble(6, machine.getRequirementValue());
            pstmt.executeUpdate();
        }
        machine.setMachineEntryId(machineEntryId);
    }

    // ON DELETE CASCADE removes groups -> items -> machines.
    private void deleteByAllocationId(int allocationId) throws SQLException {
        String sql = "DELETE FROM MACHINE_ALLOCATION WHERE ALLOCATION_ID = ?";
        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, allocationId);
            pstmt.executeUpdate();
        }
    }

    public void deleteByPlanId(int planId) throws SQLException {
        String sql = "DELETE FROM MACHINE_ALLOCATION WHERE PLAN_ID = ?";
        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, planId);
            pstmt.executeUpdate();
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
