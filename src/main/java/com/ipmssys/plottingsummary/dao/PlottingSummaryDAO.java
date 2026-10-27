package com.ipmssys.plottingsummary.dao;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.ipmssys.configuration.GenericDAO;
import com.ipmssys.item.model.Item;
import com.ipmssys.machine.model.Machine;
import com.ipmssys.machinetype.model.MachineType;
import com.ipmssys.plottingsummary.model.PlottingSummary;
import com.ipmssys.plottingsummary.model.PlottingSummaryDetail;

/**
 * Data access for PLOTTING_SUMMARY (header). Reads join ITEM, MACHINE_TYPE
 * and (optionally) the stacking MACHINE, and aggregate TOTAL_HOURS / TOTAL_DAYS
 * from the detail table. Detail rows themselves are handled by
 * {@link PlottingSummaryDetailDAO}; create/update here persist only the header.
 */
public class PlottingSummaryDAO implements GenericDAO<PlottingSummary> {

    private final Connection con;

    public PlottingSummaryDAO(Connection con) {
        this.con = con;
    }

    private static final String SELECT_ALL =
            "SELECT ps.PLOTTING_ID, ps.EVALUATION, ps.CATEGORY, ps.TYPE, ps.ITEM_TYPE, ps.PLAN, "
          + "ps.NO_OF_LOTS, ps.WOS_TYPE, ps.DATE_PREFERRED, ps.CONFIRMED_DATE, ps.PIC, "
          + "ps.CREATED_AT, ps.UPDATED_AT, "
          + "i.ITEM_ID, i.ITEM_NAME, i.GROUP_CODE, "
          + "mt.MACHINE_TYPE_ID, mt.MACHINE_CODE, mt.MACHINE_NAME AS TYPE_NAME, "
          + "sm.MACHINE_ID AS STACK_ID, sm.MACHINE_NAME AS STACK_NAME, "
          + "NVL(SUM(psd.HOURS), 0) AS TOTAL_HOURS, COUNT(psd.DETAIL_ID) AS TOTAL_DAYS "
          + "FROM PLOTTING_SUMMARY ps "
          + "JOIN ITEM i          ON i.ITEM_ID = ps.ITEM_ID "
          + "JOIN MACHINE_TYPE mt ON mt.MACHINE_TYPE_ID = ps.MACHINE_TYPE_ID "
          + "LEFT JOIN MACHINE sm ON sm.MACHINE_ID = ps.STACKING_MACHINE_ID "
          + "LEFT JOIN PLOTTING_SUMMARY_DETAIL psd ON psd.PLOTTING_ID = ps.PLOTTING_ID ";

    private static final String GROUP_BY =
            "GROUP BY ps.PLOTTING_ID, ps.EVALUATION, ps.CATEGORY, ps.TYPE, ps.ITEM_TYPE, ps.PLAN, "
          + "ps.NO_OF_LOTS, ps.WOS_TYPE, ps.DATE_PREFERRED, ps.CONFIRMED_DATE, ps.PIC, "
          + "ps.CREATED_AT, ps.UPDATED_AT, "
          + "i.ITEM_ID, i.ITEM_NAME, i.GROUP_CODE, "
          + "mt.MACHINE_TYPE_ID, mt.MACHINE_CODE, mt.MACHINE_NAME, "
          + "sm.MACHINE_ID, sm.MACHINE_NAME ";

    // ------------------------------------------------------------------ //
    //  GenericDAO contract
    // ------------------------------------------------------------------ //

    @Override
    public PlottingSummary get(Object plottingId) throws SQLException {
        String sql = SELECT_ALL + "WHERE ps.PLOTTING_ID = ? " + GROUP_BY;

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, (Integer) plottingId);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    @Override
    public List<PlottingSummary> listAll() throws SQLException {
        String sql = SELECT_ALL + GROUP_BY + "ORDER BY ps.DATE_PREFERRED DESC, ps.PLOTTING_ID DESC";

        List<PlottingSummary> list = new ArrayList<>();
        try (PreparedStatement pstmt = con.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        }
        return list;
    }

    /**
     * Rows with at least one scheduled day in the given month/year, each with
     * its detail rows attached — the calendar matrix reads these to fill the
     * day columns. Ordered by machine type then preferred date.
     */
    public List<PlottingSummary> listByMonthYear(int month, int year) throws SQLException {
        String sql = SELECT_ALL
                   + "WHERE EXISTS ("
                   + "  SELECT 1 FROM PLOTTING_SUMMARY_DETAIL d2 "
                   + "  WHERE d2.PLOTTING_ID = ps.PLOTTING_ID "
                   + "  AND EXTRACT(MONTH FROM d2.SCHEDULE_DATE) = ? "
                   + "  AND EXTRACT(YEAR FROM d2.SCHEDULE_DATE) = ?) "
                   + GROUP_BY
                   + "ORDER BY mt.MACHINE_CODE ASC, ps.DATE_PREFERRED ASC, ps.PLOTTING_ID ASC";

        List<PlottingSummary> list = new ArrayList<>();
        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, month);
            pstmt.setInt(2, year);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }

        // Attach each row's detail rows for the day-column fill.
        PlottingSummaryDetailDAO detailDAO = new PlottingSummaryDetailDAO(con);
        for (PlottingSummary ps : list) {
            ps.setDetails(detailDAO.getByPlottingId(ps.getPlottingId()));
        }
        return list;
    }

    @Override
    public PlottingSummary create(PlottingSummary ps) throws SQLException {
        String sql = "INSERT INTO PLOTTING_SUMMARY "
                   + "(PLOTTING_ID, EVALUATION, CATEGORY, TYPE, ITEM_ID, ITEM_TYPE, PLAN, NO_OF_LOTS, "
                   + "WOS_TYPE, MACHINE_TYPE_ID, STACKING_MACHINE_ID, DATE_PREFERRED, CONFIRMED_DATE, PIC) "
                   + "VALUES (PLOTTING_SUMMARY_SEQ.NEXTVAL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (PreparedStatement pstmt = con.prepareStatement(sql, new String[] { "PLOTTING_ID" })) {
            bindHeader(pstmt, ps);
            if (pstmt.executeUpdate() > 0) {
                try (ResultSet keys = pstmt.getGeneratedKeys()) {
                    if (keys.next()) {
                        ps.setPlottingId(keys.getInt(1));
                    }
                }
                return ps;
            }
        }
        return null;
    }

    @Override
    public PlottingSummary update(PlottingSummary ps) throws SQLException {
        String sql = "UPDATE PLOTTING_SUMMARY SET "
                   + "EVALUATION = ?, CATEGORY = ?, TYPE = ?, ITEM_ID = ?, ITEM_TYPE = ?, PLAN = ?, "
                   + "NO_OF_LOTS = ?, WOS_TYPE = ?, MACHINE_TYPE_ID = ?, STACKING_MACHINE_ID = ?, "
                   + "DATE_PREFERRED = ?, CONFIRMED_DATE = ?, PIC = ?, UPDATED_AT = SYSTIMESTAMP "
                   + "WHERE PLOTTING_ID = ?";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            int next = bindHeader(pstmt, ps);
            pstmt.setInt(next, ps.getPlottingId());
            if (pstmt.executeUpdate() > 0) {
                return ps;
            }
        }
        return null;
    }

    @Override
    public PlottingSummary delete(PlottingSummary ps) throws SQLException {
        // Detail rows are removed by ON DELETE CASCADE.
        String sql = "DELETE FROM PLOTTING_SUMMARY WHERE PLOTTING_ID = ?";
        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, ps.getPlottingId());
            if (pstmt.executeUpdate() > 0) {
                return ps;
            }
        }
        return null;
    }

    /** No standalone duplicate concept — schedule conflicts are checked separately. */
    @Override
    public PlottingSummary findDuplicate(PlottingSummary ps) throws SQLException {
        return null;
    }

    // ------------------------------------------------------------------ //
    //  Conflict check
    // ------------------------------------------------------------------ //

    /**
     * For the given stacking machine, check whether adding newDetails would push
     * any date's cumulative hours (existing on other plotting entries + new) over 24.
     * excludePlottingId ignores the entry being edited. Returns an error message,
     * or null when clear. No stacking machine (null) means no shared-capacity check.
     */
    public String findCumulativeHoursConflict(Integer stackingMachineId,
                                              List<PlottingSummaryDetail> newDetails,
                                              Integer excludePlottingId) throws SQLException {
        if (stackingMachineId == null || newDetails == null || newDetails.isEmpty()) {
            return null;
        }

        // Sum the new hours per date.
        Map<LocalDate, Double> newByDate = new LinkedHashMap<>();
        for (PlottingSummaryDetail d : newDetails) {
            Double running = newByDate.get(d.getScheduleDate());
            newByDate.put(d.getScheduleDate(), (running == null ? 0 : running) + d.getHours());
        }

        String sql = "SELECT NVL(SUM(psd.HOURS), 0) AS USED "
                   + "FROM PLOTTING_SUMMARY ps "
                   + "JOIN PLOTTING_SUMMARY_DETAIL psd ON psd.PLOTTING_ID = ps.PLOTTING_ID "
                   + "WHERE ps.STACKING_MACHINE_ID = ? AND psd.SCHEDULE_DATE = ? "
                   + (excludePlottingId != null ? "AND ps.PLOTTING_ID <> ? " : "");

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            for (Map.Entry<LocalDate, Double> e : newByDate.entrySet()) {
                pstmt.setInt(1, stackingMachineId);
                pstmt.setDate(2, Date.valueOf(e.getKey()));
                if (excludePlottingId != null) {
                    pstmt.setInt(3, excludePlottingId);
                }
                double used = 0;
                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) {
                        used = rs.getDouble("USED");
                    }
                }
                double total = used + e.getValue();
                if (total > 24.0) {
                    return "Schedule conflict on " + e.getKey()
                         + ": the stacking machine would be at " + trim(total)
                         + "h (max 24h). " + trim(used) + "h is already used by other entries.";
                }
            }
        }
        return null;
    }

    // ------------------------------------------------------------------ //
    //  Helpers
    // ------------------------------------------------------------------ //

    /** Binds the 13 header columns in order; returns the next index (14). */
    private int bindHeader(PreparedStatement pstmt, PlottingSummary ps) throws SQLException {
        pstmt.setString(1, ps.getEvaluation());
        pstmt.setString(2, ps.getCategory());
        pstmt.setString(3, ps.getType());
        pstmt.setInt(4, ps.getItem().getItemId());
        pstmt.setString(5, ps.getItemType());
        pstmt.setString(6, ps.getPlan());
        pstmt.setInt(7, ps.getNoOfLots());
        pstmt.setString(8, ps.getWosType());
        pstmt.setInt(9, ps.getMachineType().getMachineTypeId());
        if (ps.getStackingMachine() != null && ps.getStackingMachine().getMachineId() != null) {
            pstmt.setInt(10, ps.getStackingMachine().getMachineId());
        } else {
            pstmt.setNull(10, Types.NUMERIC);
        }
        pstmt.setDate(11, Date.valueOf(ps.getDatePreferred()));
        if (ps.getConfirmedDate() != null) {
            pstmt.setDate(12, Date.valueOf(ps.getConfirmedDate()));
        } else {
            pstmt.setNull(12, Types.DATE);
        }
        pstmt.setString(13, ps.getPic());
        return 14;
    }

    private PlottingSummary mapRow(ResultSet rs) throws SQLException {
        PlottingSummary ps = new PlottingSummary();
        ps.setPlottingId(rs.getInt("PLOTTING_ID"));
        ps.setEvaluation(rs.getString("EVALUATION"));
        ps.setCategory(rs.getString("CATEGORY"));
        ps.setType(rs.getString("TYPE"));
        ps.setItemType(rs.getString("ITEM_TYPE"));
        ps.setPlan(rs.getString("PLAN"));
        ps.setNoOfLots(rs.getInt("NO_OF_LOTS"));
        ps.setWosType(rs.getString("WOS_TYPE"));

        Date pref = rs.getDate("DATE_PREFERRED");
        ps.setDatePreferred(pref != null ? pref.toLocalDate() : null);
        Date conf = rs.getDate("CONFIRMED_DATE");
        ps.setConfirmedDate(conf != null ? conf.toLocalDate() : null);
        ps.setPic(rs.getString("PIC"));

        Timestamp created = rs.getTimestamp("CREATED_AT");
        ps.setCreatedAt(created != null ? created.toLocalDateTime() : null);
        Timestamp updated = rs.getTimestamp("UPDATED_AT");
        ps.setUpdatedAt(updated != null ? updated.toLocalDateTime() : null);

        Item item = new Item();
        item.setItemId(rs.getInt("ITEM_ID"));
        item.setItemName(rs.getString("ITEM_NAME"));
        item.setGroupCode(rs.getString("GROUP_CODE"));
        ps.setItem(item);

        MachineType type = new MachineType();
        type.setMachineTypeId(rs.getInt("MACHINE_TYPE_ID"));
        type.setMachineCode(rs.getString("MACHINE_CODE"));
        type.setMachineName(rs.getString("TYPE_NAME"));
        ps.setMachineType(type);

        int stackId = rs.getInt("STACK_ID");
        if (!rs.wasNull()) {
            Machine stack = new Machine();
            stack.setMachineId(stackId);
            stack.setMachineName(rs.getString("STACK_NAME"));
            ps.setStackingMachine(stack);
        }

        ps.setTotalHours(rs.getDouble("TOTAL_HOURS"));
        ps.setTotalDays(rs.getInt("TOTAL_DAYS"));
        return ps;
    }

    private String trim(double v) {
        if (v == Math.floor(v)) {
            return String.valueOf((long) v);
        }
        return String.valueOf(v);
    }
}
