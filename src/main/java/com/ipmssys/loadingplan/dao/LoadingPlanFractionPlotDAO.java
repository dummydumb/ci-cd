package com.ipmssys.loadingplan.dao;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

import com.ipmssys.loadingplan.model.LoadingPlanFractionPlot;

public class LoadingPlanFractionPlotDAO {

    private final Connection con;

    public LoadingPlanFractionPlotDAO(Connection con) {
        this.con = con;
    }

    private int nextPlotId() throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT LP_FRACTION_PLOT_SEQ.NEXTVAL FROM DUAL");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) { return rs.getInt(1); }
        }
        throw new SQLException("Failed to get LP_FRACTION_PLOT_SEQ.NEXTVAL");
    }

    private LoadingPlanFractionPlot mapRow(ResultSet rs) throws SQLException {
        LoadingPlanFractionPlot p = new LoadingPlanFractionPlot();
        p.setPlotId(rs.getInt("PLOT_ID"));
        p.setPlanId(rs.getInt("PLAN_ID"));
        p.setMachineName(rs.getString("MACHINE_NAME"));
        p.setItemName(rs.getString("ITEM_NAME"));

        Date start = rs.getDate("PLOT_START");
        if (start != null) { p.setPlotStart(start.toLocalDate()); }

        Date end = rs.getDate("PLOT_END");
        if (end != null) { p.setPlotEnd(end.toLocalDate()); }

        p.setTotalLots(rs.getInt("TOTAL_LOTS"));

        Timestamp ca = rs.getTimestamp("CREATED_AT");
        if (ca != null) { p.setCreatedAt(ca.toLocalDateTime()); }

        Timestamp ua = rs.getTimestamp("UPDATED_AT");
        if (ua != null) { p.setUpdatedAt(ua.toLocalDateTime()); }

        return p;
    }

    // ── READ ──────────────────────────────────────────────────────────

    // Returns all extended plots for a plan — used by LoadingPlanService Phase 2b.
    public List<LoadingPlanFractionPlot> getByPlanId(int planId) throws SQLException {
        List<LoadingPlanFractionPlot> list = new ArrayList<LoadingPlanFractionPlot>();

        String sql =
            "SELECT PLOT_ID, PLAN_ID, MACHINE_NAME, ITEM_NAME, " +
            "       PLOT_START, PLOT_END, TOTAL_LOTS, CREATED_AT, UPDATED_AT " +
            "FROM   LOADING_PLAN_FRACTION_PLOT " +
            "WHERE  PLAN_ID = ? " +
            "ORDER  BY MACHINE_NAME, ITEM_NAME";

        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, planId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) { list.add(mapRow(rs)); }
            }
        }

        return list;
    }

    // Returns the plot for a specific machine+item, or null if not configured.
    public LoadingPlanFractionPlot get(int planId, String machineName, String itemName)
            throws SQLException {

        String sql =
            "SELECT PLOT_ID, PLAN_ID, MACHINE_NAME, ITEM_NAME, " +
            "       PLOT_START, PLOT_END, TOTAL_LOTS, CREATED_AT, UPDATED_AT " +
            "FROM   LOADING_PLAN_FRACTION_PLOT " +
            "WHERE  PLAN_ID = ? AND MACHINE_NAME = ? AND ITEM_NAME = ?";

        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, planId);
            ps.setString(2, machineName);
            ps.setString(3, itemName);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) { return mapRow(rs); }
            }
        }

        return null;
    }

    // ── WRITE ─────────────────────────────────────────────────────────

    // Upsert — inserts if no record exists for this plan/machine/item,
    // updates if one already exists. Safe to call repeatedly from the JSP
    // whenever the planner changes the date range or total lots.
    public LoadingPlanFractionPlot upsert(LoadingPlanFractionPlot plot) throws SQLException {
        // Check for existing
        String selSql =
            "SELECT PLOT_ID FROM LOADING_PLAN_FRACTION_PLOT " +
            "WHERE  PLAN_ID = ? AND MACHINE_NAME = ? AND ITEM_NAME = ?";

        Integer existingId = null;
        try (PreparedStatement ps = con.prepareStatement(selSql)) {
            ps.setInt(1, plot.getPlanId());
            ps.setString(2, plot.getMachineName());
            ps.setString(3, plot.getItemName());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) { existingId = rs.getInt("PLOT_ID"); }
            }
        }

        if (existingId != null) {
            String updSql =
                "UPDATE LOADING_PLAN_FRACTION_PLOT " +
                "SET    PLOT_START = ?, PLOT_END = ?, TOTAL_LOTS = ?, " +
                "       UPDATED_AT = SYSTIMESTAMP " +
                "WHERE  PLOT_ID = ?";

            try (PreparedStatement ps = con.prepareStatement(updSql)) {
                ps.setDate(1, Date.valueOf(plot.getPlotStart()));
                ps.setDate(2, Date.valueOf(plot.getPlotEnd()));
                ps.setInt(3,  plot.getTotalLots());
                ps.setInt(4,  existingId);
                ps.executeUpdate();
            }

            plot.setPlotId(existingId);

        } else {
            int newId = nextPlotId();

            String insSql =
                "INSERT INTO LOADING_PLAN_FRACTION_PLOT " +
                "    (PLOT_ID, PLAN_ID, MACHINE_NAME, ITEM_NAME, " +
                "     PLOT_START, PLOT_END, TOTAL_LOTS) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?)";

            try (PreparedStatement ps = con.prepareStatement(insSql)) {
                ps.setInt(1,    newId);
                ps.setInt(2,    plot.getPlanId());
                ps.setString(3, plot.getMachineName());
                ps.setString(4, plot.getItemName());
                ps.setDate(5,   Date.valueOf(plot.getPlotStart()));
                ps.setDate(6,   Date.valueOf(plot.getPlotEnd()));
                ps.setInt(7,    plot.getTotalLots());
                ps.executeUpdate();
            }

            plot.setPlotId(newId);
        }

        return plot;
    }

    // Delete the extended plot for one fraction machine+item.
    // Reverts that row to its base computed fraction allocation.
    public void delete(int planId, String machineName, String itemName) throws SQLException {
        String sql =
            "DELETE FROM LOADING_PLAN_FRACTION_PLOT " +
            "WHERE  PLAN_ID = ? AND MACHINE_NAME = ? AND ITEM_NAME = ?";

        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1,    planId);
            ps.setString(2, machineName);
            ps.setString(3, itemName);
            ps.executeUpdate();
        }
    }

    // Delete all extended plots for a plan — used on plan reset.
    public void deleteByPlanId(int planId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "DELETE FROM LOADING_PLAN_FRACTION_PLOT WHERE PLAN_ID = ?")) {
            ps.setInt(1, planId);
            ps.executeUpdate();
        }
    }
}