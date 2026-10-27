package com.ipmssys.saggering.dao;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.ipmssys.item.model.Item;
import com.ipmssys.saggering.model.Saggering;
import com.ipmssys.saggering.model.SaggeringDay;
import com.ipmssys.saggering.model.SaggeringItem;

/**
 * Data access for the saggering tree (SAGGERING -> SAGGERING_ITEM -> SAGGERING_DAY).
 * There is one saggering per plan; saveForPlan rewrites the whole tree in a
 * single transaction (the caller manages commit/rollback).
 */
public class SaggeringDAO {

    private final Connection con;

    public SaggeringDAO(Connection con) {
        this.con = con;
    }

    /** True if a saggering already exists for the plan. */
    public boolean existsByPlanId(int planId) throws SQLException {
        String sql = "SELECT 1 FROM SAGGERING WHERE PLAN_ID = ? FETCH FIRST 1 ROWS ONLY";
        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, planId);
            try (ResultSet rs = pstmt.executeQuery()) {
                return rs.next();
            }
        }
    }

    /** Full saggering tree for a plan (items with their days), or null if none. */
    public Saggering getByPlanId(int planId) throws SQLException {
        String sql =
                "SELECT s.SAGGERING_ID, s.PLAN_ID, s.STATUS, s.CREATED_AT, s.UPDATED_AT, "
              + "si.SAGGERING_ITEM_ID, si.CAP_CODE, si.LOTS_PER_BATCH, "
              + "i.ITEM_ID, i.ITEM_NAME, i.GROUP_CODE, "
              + "sd.SAGGERING_DAY_ID, sd.PLAN_DATE, sd.VALUE "
              + "FROM SAGGERING s "
              + "LEFT JOIN SAGGERING_ITEM si ON si.SAGGERING_ID = s.SAGGERING_ID "
              + "LEFT JOIN ITEM i           ON i.ITEM_ID = si.ITEM_ID "
              + "LEFT JOIN SAGGERING_DAY sd ON sd.SAGGERING_ITEM_ID = si.SAGGERING_ITEM_ID "
              + "WHERE s.PLAN_ID = ? "
              + "ORDER BY si.SAGGERING_ITEM_ID ASC, sd.PLAN_DATE ASC";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, planId);
            try (ResultSet rs = pstmt.executeQuery()) {
                Saggering saggering = null;
                Map<Integer, SaggeringItem> itemsById = new LinkedHashMap<>();

                while (rs.next()) {
                    if (saggering == null) {
                        saggering = new Saggering();
                        saggering.setSaggeringId(rs.getInt("SAGGERING_ID"));
                        saggering.setPlanId(rs.getInt("PLAN_ID"));
                        saggering.setStatus(rs.getString("STATUS"));
                        Timestamp c = rs.getTimestamp("CREATED_AT");
                        saggering.setCreatedAt(c != null ? c.toLocalDateTime() : null);
                        Timestamp u = rs.getTimestamp("UPDATED_AT");
                        saggering.setUpdatedAt(u != null ? u.toLocalDateTime() : null);
                    }

                    int itemRowId = rs.getInt("SAGGERING_ITEM_ID");
                    if (!rs.wasNull()) {
                        SaggeringItem item = itemsById.get(itemRowId);
                        if (item == null) {
                            item = new SaggeringItem();
                            item.setSaggeringItemId(itemRowId);
                            item.setSaggeringId(saggering.getSaggeringId());
                            item.setCapCode(rs.getString("CAP_CODE"));
                            item.setLotsPerBatch(rs.getInt("LOTS_PER_BATCH"));

                            Item it = new Item();
                            it.setItemId(rs.getInt("ITEM_ID"));
                            it.setItemName(rs.getString("ITEM_NAME"));
                            it.setGroupCode(rs.getString("GROUP_CODE"));
                            item.setItem(it);

                            itemsById.put(itemRowId, item);
                        }

                        int dayId = rs.getInt("SAGGERING_DAY_ID");
                        if (!rs.wasNull()) {
                            SaggeringDay day = new SaggeringDay();
                            day.setSaggeringDayId(dayId);
                            day.setSaggeringItemId(itemRowId);
                            Date pd = rs.getDate("PLAN_DATE");
                            day.setPlanDate(pd != null ? pd.toLocalDate() : null);
                            day.setValue(rs.getInt("VALUE"));
                            item.getDays().add(day);
                        }
                    }
                }

                if (saggering == null) {
                    return null;
                }
                saggering.setItems(new ArrayList<>(itemsById.values()));
                return saggering;
            }
        }
    }

    /**
     * Rewrite the whole saggering tree for a plan: delete any existing one
     * (cascades items + days), then insert the header, items and days.
     * Runs inside the caller's transaction.
     */
    public Saggering saveForPlan(Saggering saggering) throws SQLException {
        deleteByPlanId(saggering.getPlanId());

        // Header
        int saggeringId;
        String insHeader = "INSERT INTO SAGGERING (SAGGERING_ID, PLAN_ID, STATUS) "
                         + "VALUES (SAGGERING_SEQ.NEXTVAL, ?, ?)";
        try (PreparedStatement pstmt = con.prepareStatement(insHeader, new String[] { "SAGGERING_ID" })) {
            pstmt.setInt(1, saggering.getPlanId());
            pstmt.setString(2, saggering.getStatus() != null ? saggering.getStatus() : "DRAFT");
            pstmt.executeUpdate();
            try (ResultSet keys = pstmt.getGeneratedKeys()) {
                keys.next();
                saggeringId = keys.getInt(1);
            }
        }
        saggering.setSaggeringId(saggeringId);

        String insItem = "INSERT INTO SAGGERING_ITEM "
                       + "(SAGGERING_ITEM_ID, SAGGERING_ID, ITEM_ID, CAP_CODE, LOTS_PER_BATCH) "
                       + "VALUES (SAGGERING_ITEM_SEQ.NEXTVAL, ?, ?, ?, ?)";
        String insDay = "INSERT INTO SAGGERING_DAY "
                      + "(SAGGERING_DAY_ID, SAGGERING_ITEM_ID, PLAN_DATE, VALUE) "
                      + "VALUES (SAGGERING_DAY_SEQ.NEXTVAL, ?, ?, ?)";

        for (SaggeringItem item : saggering.getItems()) {
            int itemId;
            try (PreparedStatement pstmt = con.prepareStatement(insItem, new String[] { "SAGGERING_ITEM_ID" })) {
                pstmt.setInt(1, saggeringId);
                pstmt.setInt(2, item.getItem().getItemId());
                pstmt.setString(3, item.getCapCode());
                pstmt.setInt(4, item.getLotsPerBatch());
                pstmt.executeUpdate();
                try (ResultSet keys = pstmt.getGeneratedKeys()) {
                    keys.next();
                    itemId = keys.getInt(1);
                }
            }

            List<SaggeringDay> days = item.getDays();
            if (days != null && !days.isEmpty()) {
                try (PreparedStatement pstmt = con.prepareStatement(insDay)) {
                    for (SaggeringDay day : days) {
                        if (day.getPlanDate() == null) {
                            continue;
                        }
                        pstmt.setInt(1, itemId);
                        pstmt.setDate(2, Date.valueOf(day.getPlanDate()));
                        pstmt.setInt(3, day.getValue());
                        pstmt.addBatch();
                    }
                    pstmt.executeBatch();
                }
            }
        }

        return saggering;
    }

    /** Delete the saggering for a plan (items + days cascade). */
    public void deleteByPlanId(int planId) throws SQLException {
        String sql = "DELETE FROM SAGGERING WHERE PLAN_ID = ?";
        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, planId);
            pstmt.executeUpdate();
        }
    }

    /**
     * Per-item monthly saggered lots for a plan = SUM(day.value) * lotsPerBatch,
     * keyed by UPPER(item name). This is the Excel's "Saggering plan (lots/month)"
     * that feeds the Precondition INPUT PLAN (and therefore MC REQT), instead of a
     * raw lots/month field. Items with no saggering days are omitted.
     */
    public Map<String, Integer> getMonthlyLotsByItemName(int planId) throws SQLException {
        String sql =
                "SELECT UPPER(i.ITEM_NAME) AS ITEM_NAME, "
              + "       SUM(NVL(sd.VALUE, 0)) * MAX(si.LOTS_PER_BATCH) AS LOTS_PER_MONTH "
              + "FROM SAGGERING s "
              + "JOIN SAGGERING_ITEM si ON si.SAGGERING_ID = s.SAGGERING_ID "
              + "JOIN ITEM i            ON i.ITEM_ID = si.ITEM_ID "
              + "LEFT JOIN SAGGERING_DAY sd ON sd.SAGGERING_ITEM_ID = si.SAGGERING_ITEM_ID "
              + "WHERE s.PLAN_ID = ? "
              + "GROUP BY UPPER(i.ITEM_NAME)";

        Map<String, Integer> map = new LinkedHashMap<>();
        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, planId);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    map.put(rs.getString("ITEM_NAME"), rs.getInt("LOTS_PER_MONTH"));
                }
            }
        }
        return map;
    }
}
