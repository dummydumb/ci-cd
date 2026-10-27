package com.ipmssys.monthlyplan.dao;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import com.ipmssys.configuration.GenericDAO;
import com.ipmssys.monthlyplan.model.MonthlyPlan;

/**
 * Data access for MONTHLY_PLAN. One method per query.
 * The list query joins MACHINE_TYPE so the screen can show the machine
 * code/name without a second round-trip.
 */
public class MonthlyPlanDAO implements GenericDAO<MonthlyPlan> {

    private final Connection con;

    public MonthlyPlanDAO(Connection con) {
        this.con = con;
    }

    private static final String SELECT_WITH_TYPE =
            "SELECT mp.PLAN_ID, mp.PLAN_MONTH, mp.MACHINE_TYPE_ID, mp.DESCRIPTION, "
          + "mp.PRODUCTION_TIME, mp.EFFICIENCY, mp.WORKING_DAYS, mp.AVAILABLE_MACHINE, mp.STATUS, "
          + "mp.LAST_DAY_PRODUCTION, mp.CREATED_AT, mp.UPDATED_AT, "
          + "mt.MACHINE_CODE, mt.MACHINE_NAME "
          + "FROM MONTHLY_PLAN mp "
          + "JOIN MACHINE_TYPE mt ON mt.MACHINE_TYPE_ID = mp.MACHINE_TYPE_ID ";

    // ------------------------------------------------------------------ //
    //  GenericDAO contract
    // ------------------------------------------------------------------ //

    /** Load one plan by id (with machine type), for the edit dialog. */
    @Override
    public MonthlyPlan get(Object planId) throws SQLException {
        String sql = SELECT_WITH_TYPE + "WHERE mp.PLAN_ID = ?";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, (Integer) planId);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    /** Insert a new plan. */
    @Override
    public MonthlyPlan create(MonthlyPlan plan) throws SQLException {
        String sql = "INSERT INTO MONTHLY_PLAN "
                   + "(PLAN_ID, PLAN_MONTH, MACHINE_TYPE_ID, DESCRIPTION, PRODUCTION_TIME, "
                   + "EFFICIENCY, WORKING_DAYS, AVAILABLE_MACHINE, STATUS, LAST_DAY_PRODUCTION) "
                   + "VALUES (MONTHLY_PLAN_SEQ.NEXTVAL, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setDate(1, toSqlDate(plan.getPlanMonth()));
            pstmt.setInt(2, plan.getMachineTypeId());
            pstmt.setString(3, plan.getDescription());
            pstmt.setInt(4, plan.getProductionTime());
            pstmt.setInt(5, plan.getEfficiency());
            pstmt.setInt(6, plan.getWorkingDays());
            pstmt.setInt(7, plan.getAvailableMachine());
            pstmt.setString(8, plan.getStatus());
            pstmt.setDate(9, toSqlDate(plan.getLastDayProduction()));
            if (pstmt.executeUpdate() > 0) {
                return plan;
            }
        }
        return null;
    }

    /** Update an existing plan. */
    @Override
    public MonthlyPlan update(MonthlyPlan plan) throws SQLException {
        String sql = "UPDATE MONTHLY_PLAN SET "
                   + "PLAN_MONTH = ?, MACHINE_TYPE_ID = ?, DESCRIPTION = ?, PRODUCTION_TIME = ?, "
                   + "EFFICIENCY = ?, WORKING_DAYS = ?, AVAILABLE_MACHINE = ?, STATUS = ?, LAST_DAY_PRODUCTION = ?, "
                   + "UPDATED_AT = SYSTIMESTAMP "
                   + "WHERE PLAN_ID = ?";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setDate(1, toSqlDate(plan.getPlanMonth()));
            pstmt.setInt(2, plan.getMachineTypeId());
            pstmt.setString(3, plan.getDescription());
            pstmt.setInt(4, plan.getProductionTime());
            pstmt.setInt(5, plan.getEfficiency());
            pstmt.setInt(6, plan.getWorkingDays());
            pstmt.setInt(7, plan.getAvailableMachine());
            pstmt.setString(8, plan.getStatus());
            pstmt.setDate(9, toSqlDate(plan.getLastDayProduction()));
            pstmt.setInt(10, plan.getPlanId());
            if (pstmt.executeUpdate() > 0) {
                return plan;
            }
        }
        return null;
    }

    /** Delete a plan. */
    @Override
    public MonthlyPlan delete(MonthlyPlan plan) throws SQLException {
        String sql = "DELETE FROM MONTHLY_PLAN WHERE PLAN_ID = ?";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, plan.getPlanId());
            if (pstmt.executeUpdate() > 0) {
                return plan;
            }
        }
        return null;
    }

    /** All plans (with machine type), newest month first. */
    @Override
    public List<MonthlyPlan> listAll() throws SQLException {
        String sql = SELECT_WITH_TYPE + "ORDER BY mp.PLAN_MONTH DESC, mt.MACHINE_CODE ASC";

        List<MonthlyPlan> list = new ArrayList<>();
        try (PreparedStatement pstmt = con.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        }
        return list;
    }

    /** Duplicate check: a plan already exists for this (month, machine type). */
    @Override
    public MonthlyPlan findDuplicate(MonthlyPlan plan) throws SQLException {
        String sql = SELECT_WITH_TYPE + "WHERE mp.PLAN_MONTH = ? AND mp.MACHINE_TYPE_ID = ?";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setDate(1, toSqlDate(plan.getPlanMonth()));
            pstmt.setInt(2, plan.getMachineTypeId());
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    // ------------------------------------------------------------------ //
    //  Plan-specific queries
    // ------------------------------------------------------------------ //

    /** Duplicate check on update: another plan already holds this (month, type). */
    public MonthlyPlan findDuplicateUpdate(MonthlyPlan plan) throws SQLException {
        String sql = SELECT_WITH_TYPE
                   + "WHERE mp.PLAN_MONTH = ? AND mp.MACHINE_TYPE_ID = ? AND mp.PLAN_ID <> ?";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setDate(1, toSqlDate(plan.getPlanMonth()));
            pstmt.setInt(2, plan.getMachineTypeId());
            pstmt.setInt(3, plan.getPlanId());
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

    private MonthlyPlan mapRow(ResultSet rs) throws SQLException {
        MonthlyPlan plan = new MonthlyPlan();
        plan.setPlanId(rs.getInt("PLAN_ID"));

        Date planMonth = rs.getDate("PLAN_MONTH");
        plan.setPlanMonth(planMonth != null ? planMonth.toLocalDate() : null);

        plan.setMachineTypeId(rs.getInt("MACHINE_TYPE_ID"));
        plan.setDescription(rs.getString("DESCRIPTION"));
        plan.setProductionTime(rs.getInt("PRODUCTION_TIME"));
        plan.setEfficiency(rs.getInt("EFFICIENCY"));
        plan.setWorkingDays(rs.getInt("WORKING_DAYS"));
        plan.setAvailableMachine(rs.getInt("AVAILABLE_MACHINE"));
        plan.setStatus(rs.getString("STATUS"));

        Date lastDay = rs.getDate("LAST_DAY_PRODUCTION");
        plan.setLastDayProduction(lastDay != null ? lastDay.toLocalDate() : null);

        Timestamp created = rs.getTimestamp("CREATED_AT");
        plan.setCreatedAt(created != null ? created.toLocalDateTime() : null);

        Timestamp updated = rs.getTimestamp("UPDATED_AT");
        plan.setUpdatedAt(updated != null ? updated.toLocalDateTime() : null);

        plan.setMachineCode(rs.getString("MACHINE_CODE"));
        plan.setMachineName(rs.getString("MACHINE_NAME"));
        return plan;
    }

    private Date toSqlDate(LocalDate value) {
        return value != null ? Date.valueOf(value) : null;
    }
}
