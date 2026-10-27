package com.ipmssys.plottingsummary.dao;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import com.ipmssys.plottingsummary.model.PlottingSummaryDetail;

/**
 * Data access for PLOTTING_SUMMARY_DETAIL (per-day schedule rows).
 * The set of rows for a plotting entry is rewritten on save
 * (deleteByPlottingId then createAll), inside the caller's transaction.
 */
public class PlottingSummaryDetailDAO {

    private final Connection con;

    public PlottingSummaryDetailDAO(Connection con) {
        this.con = con;
    }

    /** All detail rows for a plotting entry, earliest date first. */
    public List<PlottingSummaryDetail> getByPlottingId(int plottingId) throws SQLException {
        String sql = "SELECT DETAIL_ID, PLOTTING_ID, SCHEDULE_DATE, HOURS "
                   + "FROM PLOTTING_SUMMARY_DETAIL WHERE PLOTTING_ID = ? ORDER BY SCHEDULE_DATE ASC";

        List<PlottingSummaryDetail> list = new ArrayList<>();
        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, plottingId);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    /** Insert all detail rows for an entry (sequence-driven PK, batched). */
    public void createAll(List<PlottingSummaryDetail> details) throws SQLException {
        if (details == null || details.isEmpty()) {
            return;
        }
        String sql = "INSERT INTO PLOTTING_SUMMARY_DETAIL (DETAIL_ID, PLOTTING_ID, SCHEDULE_DATE, HOURS) "
                   + "VALUES (PLOTTING_SUMMARY_DETAIL_SEQ.NEXTVAL, ?, ?, ?)";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            for (PlottingSummaryDetail d : details) {
                pstmt.setInt(1, d.getPlottingId());
                pstmt.setDate(2, Date.valueOf(d.getScheduleDate()));
                pstmt.setDouble(3, d.getHours());
                pstmt.addBatch();
            }
            pstmt.executeBatch();
        }
    }

    /** Remove all detail rows for an entry (called before re-inserting on update). */
    public void deleteByPlottingId(int plottingId) throws SQLException {
        String sql = "DELETE FROM PLOTTING_SUMMARY_DETAIL WHERE PLOTTING_ID = ?";
        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, plottingId);
            pstmt.executeUpdate();
        }
    }

    private PlottingSummaryDetail mapRow(ResultSet rs) throws SQLException {
        PlottingSummaryDetail detail = new PlottingSummaryDetail();
        detail.setDetailId(rs.getInt("DETAIL_ID"));
        detail.setPlottingId(rs.getInt("PLOTTING_ID"));
        Date d = rs.getDate("SCHEDULE_DATE");
        detail.setScheduleDate(d != null ? d.toLocalDate() : null);
        detail.setHours(rs.getDouble("HOURS"));
        return detail;
    }
}
