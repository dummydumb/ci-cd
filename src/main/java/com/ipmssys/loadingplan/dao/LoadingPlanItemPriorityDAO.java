package com.ipmssys.loadingplan.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import com.ipmssys.loadingplan.model.LoadingPlanItemPriority;

public class LoadingPlanItemPriorityDAO {

    private final Connection con;

    public LoadingPlanItemPriorityDAO(Connection con) { this.con = con; }

    private int nextId() throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT LP_ITEM_PRIORITY_SEQ.NEXTVAL FROM DUAL");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) { return rs.getInt(1); }
        }
        throw new SQLException("Failed to get LP_ITEM_PRIORITY_SEQ.NEXTVAL");
    }

    // ── READ ──────────────────────────────────────────────────────────

    // All priorities for a plan, ordered by machine then sequence.
    // Used by ComputeLoadingPlanServlet to build the priorityMap for sorting.
    public List<LoadingPlanItemPriority> getByPlanId(int planId) throws SQLException {
        List<LoadingPlanItemPriority> list = new ArrayList<LoadingPlanItemPriority>();
        String sql =
            "SELECT PRIORITY_ID, PLAN_ID, MACHINE_NAME, ITEM_NAME, PRIORITY_SEQ " +
            "FROM   LOADING_PLAN_ITEM_PRIORITY " +
            "WHERE  PLAN_ID = ? " +
            "ORDER  BY MACHINE_NAME, PRIORITY_SEQ ASC";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, planId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    LoadingPlanItemPriority p = new LoadingPlanItemPriority();
                    p.setPriorityId(rs.getInt("PRIORITY_ID"));
                    p.setPlanId(rs.getInt("PLAN_ID"));
                    p.setMachineName(rs.getString("MACHINE_NAME"));
                    p.setItemName(rs.getString("ITEM_NAME"));
                    p.setPrioritySeq(rs.getInt("PRIORITY_SEQ"));
                    list.add(p);
                }
            }
        }
        return list;
    }

    // ── WRITE ─────────────────────────────────────────────────────────

    // Saves the full ordered list for one machine in a single transaction.
    // Deletes existing priorities for this machine first, then re-inserts
    // in the new order — simpler than tracking individual changes.
    public void saveForMachine(int planId, String machineName,
                                List<String> orderedItemNames) throws SQLException {

        // Delete existing order for this machine
        String delSql = "DELETE FROM LOADING_PLAN_ITEM_PRIORITY " +
                        "WHERE PLAN_ID = ? AND MACHINE_NAME = ?";
        try (PreparedStatement ps = con.prepareStatement(delSql)) {
            ps.setInt(1, planId);
            ps.setString(2, machineName);
            ps.executeUpdate();
        }

        // Re-insert in the new order
        if (orderedItemNames == null || orderedItemNames.isEmpty()) { return; }

        String insSql = "INSERT INTO LOADING_PLAN_ITEM_PRIORITY " +
                        "    (PRIORITY_ID, PLAN_ID, MACHINE_NAME, ITEM_NAME, PRIORITY_SEQ) " +
                        "VALUES (?, ?, ?, ?, ?)";
        try (PreparedStatement ps = con.prepareStatement(insSql)) {
            for (int i = 0; i < orderedItemNames.size(); i++) {
                ps.setInt(1,    nextId());
                ps.setInt(2,    planId);
                ps.setString(3, machineName);
                ps.setString(4, orderedItemNames.get(i));
                ps.setInt(5,    i + 1);   // 1-based sequence
                ps.addBatch();
            }
            ps.executeBatch();
        }
    }

    // Reset priorities for one machine (revert to allocation order)
    public void deleteForMachine(int planId, String machineName) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "DELETE FROM LOADING_PLAN_ITEM_PRIORITY " +
                "WHERE PLAN_ID = ? AND MACHINE_NAME = ?")) {
            ps.setInt(1, planId);
            ps.setString(2, machineName);
            ps.executeUpdate();
        }
    }
}