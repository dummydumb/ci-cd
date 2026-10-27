package com.ipmssys.machinetype.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

import com.ipmssys.machinetype.model.MachineType;
import com.ipmssys.configuration.GenericDAO;

/**
 * Data access for MACHINE_TYPE.
 * The Servlet owns the transaction; this DAO never commits or closes the connection.
 */
public class MachineTypeDAO implements GenericDAO<MachineType> {

    private final Connection con;

    public MachineTypeDAO(Connection con) {
        this.con = con;
    }

    private MachineType mapRow(ResultSet rs) throws SQLException {
        MachineType machineType = new MachineType();
        machineType.setMachineTypeId(rs.getInt("MACHINE_TYPE_ID"));
        machineType.setMachineCode(rs.getString("MACHINE_CODE"));
        machineType.setMachineName(rs.getString("MACHINE_NAME"));
        machineType.setStatus(rs.getString("STATUS"));

        Timestamp created = rs.getTimestamp("CREATED_AT");
        machineType.setCreatedAt(created != null ? created.toLocalDateTime() : null);

        Timestamp updated = rs.getTimestamp("UPDATED_AT");
        machineType.setUpdatedAt(updated != null ? updated.toLocalDateTime() : null);

        return machineType;
    }

    @Override
    public MachineType get(Object machineTypeId) throws SQLException {
        String sql = "SELECT "
                        + "MACHINE_TYPE_ID, MACHINE_CODE, MACHINE_NAME, STATUS, CREATED_AT, UPDATED_AT "
                    + "FROM "
                        + "MACHINE_TYPE "
                    + "WHERE "
                        + "MACHINE_TYPE_ID = ? ";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, (Integer) machineTypeId);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    @Override
    public MachineType create(MachineType machineType) throws SQLException {
        String sql = "INSERT INTO "
                        + "MACHINE_TYPE "
                        + "(MACHINE_TYPE_ID, MACHINE_CODE, MACHINE_NAME, STATUS) "
                    + "VALUES "
                        + "(MACHINE_TYPE_SEQ.NEXTVAL, ?, ?, ?) ";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setString(1, machineType.getMachineCode());
            pstmt.setString(2, machineType.getMachineName());
            pstmt.setString(3, machineType.getStatus());
            if (pstmt.executeUpdate() > 0) {
                return machineType;
            }
        }
        return null;
    }

    @Override
    public MachineType update(MachineType machineType) throws SQLException {
        String sql = "UPDATE "
                        + "MACHINE_TYPE "
                    + "SET "
                        + "MACHINE_CODE = ?, "
                        + "MACHINE_NAME = ?, "
                        + "STATUS       = ?, "
                        + "UPDATED_AT   = SYSTIMESTAMP "
                    + "WHERE "
                        + "MACHINE_TYPE_ID = ? ";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setString(1, machineType.getMachineCode());
            pstmt.setString(2, machineType.getMachineName());
            pstmt.setString(3, machineType.getStatus());
            pstmt.setInt(4, machineType.getMachineTypeId());
            if (pstmt.executeUpdate() > 0) {
                return machineType;
            }
        }
        return null;
    }

    @Override
    public MachineType delete(MachineType machineType) throws SQLException {
        String sql = "DELETE FROM MACHINE_TYPE WHERE MACHINE_TYPE_ID = ? ";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, machineType.getMachineTypeId());
            if (pstmt.executeUpdate() > 0) {
                return machineType;
            }
        }
        return null;
    }

    @Override
    public List<MachineType> listAll() throws SQLException {
        List<MachineType> list = new ArrayList<MachineType>();
        String sql = "SELECT "
                        + "MACHINE_TYPE_ID, MACHINE_CODE, MACHINE_NAME, STATUS, CREATED_AT, UPDATED_AT "
                    + "FROM "
                        + "MACHINE_TYPE "
                    + "ORDER BY "
                        + "MACHINE_CODE ASC ";

        try (PreparedStatement pstmt = con.prepareStatement(sql);
                ResultSet rs = pstmt.executeQuery()) {
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        }
        return list;
    }

    @Override
    public MachineType findDuplicate(MachineType machineType) throws SQLException {
        String sql = "SELECT "
                        + "MACHINE_TYPE_ID, MACHINE_CODE, MACHINE_NAME, STATUS, CREATED_AT, UPDATED_AT "
                    + "FROM "
                        + "MACHINE_TYPE "
                    + "WHERE "
                        + "UPPER(MACHINE_CODE) = UPPER(?) ";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setString(1, machineType.getMachineCode());
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    // ---- Extra query methods ----

    /** Duplicate check for update: another record with the same code. */
    public MachineType findDuplicateUpdate(MachineType machineType) throws SQLException {
        String sql = "SELECT "
                        + "MACHINE_TYPE_ID, MACHINE_CODE, MACHINE_NAME, STATUS, CREATED_AT, UPDATED_AT "
                    + "FROM "
                        + "MACHINE_TYPE "
                    + "WHERE "
                        + "UPPER(MACHINE_CODE) = UPPER(?) AND MACHINE_TYPE_ID <> ? ";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setString(1, machineType.getMachineCode());
            pstmt.setInt(2, machineType.getMachineTypeId());
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    /** Active machine types only — feeds dropdowns (e.g. Monthly Plan create/edit). */
    public List<MachineType> listActive() throws SQLException {
        List<MachineType> list = new ArrayList<MachineType>();
        String sql = "SELECT "
                        + "MACHINE_TYPE_ID, MACHINE_CODE, MACHINE_NAME, STATUS, CREATED_AT, UPDATED_AT "
                    + "FROM "
                        + "MACHINE_TYPE "
                    + "WHERE "
                        + "STATUS = 'ACTIVE' "
                    + "ORDER BY "
                        + "MACHINE_CODE ASC ";

        try (PreparedStatement pstmt = con.prepareStatement(sql);
                ResultSet rs = pstmt.executeQuery()) {
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        }
        return list;
    }

    /** True when any MONTHLY_PLAN references this machine type (guards delete). */
    public boolean isReferencedByPlan(int machineTypeId) throws SQLException {
        String sql = "SELECT "
                        + "1 "
                    + "FROM "
                        + "MONTHLY_PLAN "
                    + "WHERE "
                        + "MACHINE_TYPE_ID = ? "
                        + "FETCH FIRST 1 ROWS ONLY ";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, machineTypeId);
            try (ResultSet rs = pstmt.executeQuery()) {
                return rs.next();
            }
        }
    }
}