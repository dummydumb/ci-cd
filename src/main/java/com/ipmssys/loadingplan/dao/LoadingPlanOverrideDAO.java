package com.ipmssys.loadingplan.dao;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import com.ipmssys.loadingplan.model.LoadingPlanOverride;

public class LoadingPlanOverrideDAO {

    private Connection con;

    public LoadingPlanOverrideDAO(Connection con) {
        this.con = con;
    }

    // -------------------------------------------------------------------------
    // SEQUENCE
    // -------------------------------------------------------------------------

    private int getNextOverrideId() throws SQLException {
        String sql = "SELECT LOADING_PLAN_OVERRIDE_SEQ.NEXTVAL FROM DUAL";
        try (PreparedStatement pstmt = con.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            if (rs.next()) { return rs.getInt(1); }
        }
        throw new SQLException("Failed to get next LOADING_PLAN_OVERRIDE_ID.");
    }

    // -------------------------------------------------------------------------
    // MAP
    // -------------------------------------------------------------------------

    private LoadingPlanOverride mapRow(ResultSet rs) throws SQLException {
        LoadingPlanOverride ov = new LoadingPlanOverride();
        ov.setOverrideId(rs.getInt("OVERRIDE_ID"));
        ov.setPlanId(rs.getInt("PLAN_ID"));
        ov.setMachineName(rs.getString("MACHINE_NAME"));
        ov.setItemName(rs.getString("ITEM_NAME"));

        Date planDate = rs.getDate("PLAN_DATE");
        if (planDate != null) { ov.setPlanDate(planDate.toLocalDate()); }

        ov.setOverrideValue(rs.getDouble("OVERRIDE_VALUE"));
        ov.setReassignReason(rs.getString("REASSIGN_REASON"));
        ov.setOverrideType(rs.getString("OVERRIDE_TYPE") != null ? rs.getString("OVERRIDE_TYPE") : "STANDARD");
        ov.setRemarks(rs.getString("REMARKS"));
        Date rsd = rs.getDate("RECOVERY_SOURCE_DATE");
        if (rsd != null) { ov.setRecoverySourceDate(rsd.toLocalDate()); }

        ov.setCellStatus(rs.getString("CELL_STATUS"));

        Timestamp ca = rs.getTimestamp("CREATED_AT");
        if (ca != null) { ov.setCreatedAt(ca.toLocalDateTime()); }

        Timestamp ua = rs.getTimestamp("UPDATED_AT");
        if (ua != null) { ov.setUpdatedAt(ua.toLocalDateTime()); }

        return ov;
    }

    // -------------------------------------------------------------------------
    // READ
    // -------------------------------------------------------------------------

    // Returns all overrides for a plan — used by the service to overlay on computed rows
    public List<LoadingPlanOverride> getByPlanId(int planId) throws SQLException {
        List<LoadingPlanOverride> list = new ArrayList<LoadingPlanOverride>();

        String sql =
            "SELECT OVERRIDE_ID, PLAN_ID, MACHINE_NAME, ITEM_NAME, " +
            "       PLAN_DATE, OVERRIDE_VALUE, REASSIGN_REASON, " +
            "       OVERRIDE_TYPE, REMARKS, RECOVERY_SOURCE_DATE, CELL_STATUS, CREATED_AT, UPDATED_AT " +
            "FROM   LOADING_PLAN_OVERRIDE " +
            "WHERE  PLAN_ID = ? " +
            "ORDER  BY MACHINE_NAME ASC, ITEM_NAME ASC, PLAN_DATE ASC";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, planId);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) { list.add(mapRow(rs)); }
            }
        }

        return list;
    }

    // -------------------------------------------------------------------------
    // WRITE — upsert
    // If a row exists for plan/machine/item/date, update the value.
    // If not, insert a new row.
    // -------------------------------------------------------------------------

    public LoadingPlanOverride upsert(LoadingPlanOverride override) throws SQLException {
        // Check if this specific cell already has an override
        String selectSql =
            "SELECT OVERRIDE_ID FROM LOADING_PLAN_OVERRIDE " +
            "WHERE  PLAN_ID      = ? " +
            "AND    MACHINE_NAME = ? " +
            "AND    ITEM_NAME    = ? " +
            "AND    PLAN_DATE    = ?";

        Integer existingId = null;

        try (PreparedStatement pstmt = con.prepareStatement(selectSql)) {
            pstmt.setInt(1,    override.getPlanId());
            pstmt.setString(2, override.getMachineName());
            pstmt.setString(3, override.getItemName());
            pstmt.setDate(4,   Date.valueOf(override.getPlanDate()));

            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) { existingId = rs.getInt("OVERRIDE_ID"); }
            }
        }

        if (existingId != null) {
            // Update existing override
            String updateSql =
                "UPDATE LOADING_PLAN_OVERRIDE " +
                "SET    OVERRIDE_VALUE = ?, REASSIGN_REASON = ?, " +
                "       OVERRIDE_TYPE = ?, REMARKS = ?, RECOVERY_SOURCE_DATE = ?, " +
                "       CELL_STATUS = ?, UPDATED_AT = SYSTIMESTAMP " +
                "WHERE  OVERRIDE_ID = ?";

            try (PreparedStatement pstmt = con.prepareStatement(updateSql)) {
                pstmt.setDouble(1, override.getOverrideValue());
                pstmt.setString(2, override.getReassignReason());
                pstmt.setString(3, override.getOverrideType());
                pstmt.setString(4, override.getRemarks());
                pstmt.setDate(5, override.getRecoverySourceDate() != null
                    ? Date.valueOf(override.getRecoverySourceDate()) : null);
                pstmt.setString(6, override.getCellStatus());
                pstmt.setInt(7,    existingId);
                pstmt.executeUpdate();
            }

            override.setOverrideId(existingId);

        } else {
            // Insert new override
            int overrideId = getNextOverrideId();

            String insertSql =
                "INSERT INTO LOADING_PLAN_OVERRIDE " +
                "    (OVERRIDE_ID, PLAN_ID, MACHINE_NAME, ITEM_NAME, " +
                "     PLAN_DATE, OVERRIDE_VALUE, REASSIGN_REASON, " +
                "     OVERRIDE_TYPE, REMARKS, RECOVERY_SOURCE_DATE, CELL_STATUS) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

            try (PreparedStatement pstmt = con.prepareStatement(insertSql)) {
                pstmt.setInt(1,    overrideId);
                pstmt.setInt(2,    override.getPlanId());
                pstmt.setString(3, override.getMachineName());
                pstmt.setString(4, override.getItemName());
                pstmt.setDate(5,   Date.valueOf(override.getPlanDate()));
                pstmt.setDouble(6, override.getOverrideValue());
                pstmt.setString(7, override.getReassignReason());
                pstmt.setString(8, override.getOverrideType());
                pstmt.setString(9, override.getRemarks());
                pstmt.setDate(10, override.getRecoverySourceDate() != null
                    ? Date.valueOf(override.getRecoverySourceDate()) : null);
                pstmt.setString(11, override.getCellStatus());
                pstmt.executeUpdate();
            }

            override.setOverrideId(overrideId);
        }

        return override;
    }

    // -------------------------------------------------------------------------
    // Status-only change — sets the manual CELL_STATUS flag WITHOUT touching the
    // computed OVERRIDE_VALUE. If a row already exists for this cell (a value
    // override), only its status is updated. If none exists, a minimal status-only
    // row is inserted (value 0, type STANDARD) so the flag persists.
    // Passing status = "NONE" clears the flag; if the row was status-only it is
    // removed, otherwise the value override is left intact.
    // -------------------------------------------------------------------------
    public void updateCellStatus(int planId, String machineName, String itemName,
                                 LocalDate planDate, String status) throws SQLException {
        String st = (status == null || status.trim().isEmpty()) ? "NONE" : status.trim();

        // Does a row already exist?
        Integer existingId = null;
        String  existingReason = null;
        double  existingValue = 0;
        String  selectSql =
            "SELECT OVERRIDE_ID, OVERRIDE_VALUE, REASSIGN_REASON " +
            "FROM   LOADING_PLAN_OVERRIDE " +
            "WHERE  PLAN_ID = ? AND MACHINE_NAME = ? AND ITEM_NAME = ? AND PLAN_DATE = ?";
        try (PreparedStatement ps = con.prepareStatement(selectSql)) {
            ps.setInt(1, planId);
            ps.setString(2, machineName);
            ps.setString(3, itemName);
            ps.setDate(4, Date.valueOf(planDate));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    existingId     = rs.getInt("OVERRIDE_ID");
                    existingValue  = rs.getDouble("OVERRIDE_VALUE");
                    existingReason = rs.getString("REASSIGN_REASON");
                }
            }
        }

        if (existingId != null) {
            boolean valueOverride = existingValue != 0
                || (existingReason != null && !existingReason.trim().isEmpty());
            if ("NONE".equals(st) && !valueOverride) {
                // status-only row being cleared → remove it
                delete(planId, machineName, itemName, planDate);
                return;
            }
            String upd =
                "UPDATE LOADING_PLAN_OVERRIDE SET CELL_STATUS = ?, UPDATED_AT = SYSTIMESTAMP " +
                "WHERE  OVERRIDE_ID = ?";
            try (PreparedStatement ps = con.prepareStatement(upd)) {
                ps.setString(1, st);
                ps.setInt(2, existingId);
                ps.executeUpdate();
            }
        } else {
            if ("NONE".equals(st)) { return; }   // nothing to set, nothing exists
            int id = getNextOverrideId();
            String ins =
                "INSERT INTO LOADING_PLAN_OVERRIDE " +
                "    (OVERRIDE_ID, PLAN_ID, MACHINE_NAME, ITEM_NAME, PLAN_DATE, " +
                "     OVERRIDE_VALUE, OVERRIDE_TYPE, CELL_STATUS) " +
                "VALUES (?, ?, ?, ?, ?, 0, 'STANDARD', ?)";
            try (PreparedStatement ps = con.prepareStatement(ins)) {
                ps.setInt(1, id);
                ps.setInt(2, planId);
                ps.setString(3, machineName);
                ps.setString(4, itemName);
                ps.setDate(5, Date.valueOf(planDate));
                ps.setString(6, st);
                ps.executeUpdate();
            }
        }
    }

    // Deletes a specific override — used when user clears a cell (revert to computed)
    public void delete(int planId, String machineName, String itemName, LocalDate planDate) throws SQLException {
        String sql =
            "DELETE FROM LOADING_PLAN_OVERRIDE " +
            "WHERE  PLAN_ID      = ? " +
            "AND    MACHINE_NAME = ? " +
            "AND    ITEM_NAME    = ? " +
            "AND    PLAN_DATE    = ?";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1,    planId);
            pstmt.setString(2, machineName);
            pstmt.setString(3, itemName);
            pstmt.setDate(4,   Date.valueOf(planDate));
            pstmt.executeUpdate();
        }
    }

    // Deletes all overrides for a plan — used when resetting to computed values
    public void deleteByPlanId(int planId) throws SQLException {
        String sql = "DELETE FROM LOADING_PLAN_OVERRIDE WHERE PLAN_ID = ?";
        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, planId);
            pstmt.executeUpdate();
        }
    }

    // Returns all override dates for a machine+item within a date range.
    // Used by SaveFractionPlotServlet to warn before saving a plot that
    // overlaps with existing manual edits or reassign/recovery records.
    // Returns all override dates for a machine+item within a date range.
    // Used by SaveFractionPlotServlet to warn before saving a plot that
    // overlaps with existing manual edits or reassign/recovery records.
    public List<LocalDate> getConflictingDates(int planId, String machineName,
            String itemName, LocalDate plotStart, LocalDate plotEnd) throws SQLException {

        List<LocalDate> dates = new ArrayList<LocalDate>();
        String sql =
            "SELECT PLAN_DATE FROM LOADING_PLAN_OVERRIDE " +
            "WHERE  PLAN_ID      = ? " +
            "AND    MACHINE_NAME = ? " +
            "AND    ITEM_NAME    = ? " +
            "AND    PLAN_DATE   >= ? " +
            "AND    PLAN_DATE   <= ? " +
            "ORDER  BY PLAN_DATE ASC";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1,    planId);
            pstmt.setString(2, machineName);
            pstmt.setString(3, itemName);
            pstmt.setDate(4,   Date.valueOf(plotStart));
            pstmt.setDate(5,   Date.valueOf(plotEnd));
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    Date d = rs.getDate("PLAN_DATE");
                    if (d != null) { dates.add(d.toLocalDate()); }
                }
            }
        }

        return dates;
    }

    // Checks which of the given target (machineName, itemName, date) combinations
    // already have an existing non-zero override — meaning something is actively
    // running there. Used by BatchSaveLoadingPlanOverrideServlet to catch
    // stale client-side conflict checks before committing a reassign/recovery.
    // Returns a list of "YYYY-MM-DD" date strings that are already occupied.
    public List<String> getOccupiedDates(int planId, String machineName,
            String itemName, List<LocalDate> targetDates) throws SQLException {

        List<String> occupied = new ArrayList<String>();
        if (targetDates == null || targetDates.isEmpty()) { return occupied; }

        StringBuilder inClause = new StringBuilder();
        for (int i = 0; i < targetDates.size(); i++) {
            if (i > 0) { inClause.append(","); }
            inClause.append("?");
        }

        String sql =
            "SELECT TO_CHAR(PLAN_DATE, 'YYYY-MM-DD') AS DATE_STR " +
            "FROM   LOADING_PLAN_OVERRIDE " +
            "WHERE  PLAN_ID      = ? " +
            "AND    MACHINE_NAME = ? " +
            "AND    ITEM_NAME    = ? " +
            "AND    OVERRIDE_VALUE > 0 " +
            "AND    PLAN_DATE IN (" + inClause + ") " +
            "ORDER  BY PLAN_DATE";

        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1,    planId);
            ps.setString(2, machineName);
            ps.setString(3, itemName);
            for (int i = 0; i < targetDates.size(); i++) {
                ps.setDate(4 + i, Date.valueOf(targetDates.get(i)));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) { occupied.add(rs.getString("DATE_STR")); }
            }
        }

        return occupied;
    }
}