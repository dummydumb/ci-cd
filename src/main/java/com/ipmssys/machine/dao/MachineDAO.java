package com.ipmssys.machine.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

import com.ipmssys.configuration.GenericDAO;
import com.ipmssys.machine.model.Machine;
import com.ipmssys.machinetype.model.MachineType;

/**
 * Data access for MACHINE. One method per query. Every read joins
 * MACHINE_TYPE so the embedded type (code/name) comes back in one trip.
 */
public class MachineDAO implements GenericDAO<Machine> {

    private final Connection con;

    public MachineDAO(Connection con) {
        this.con = con;
    }

    private static final String SELECT_WITH_TYPE =
            "SELECT m.MACHINE_ID, m.MACHINE_NAME, m.MACHINE_USAGE, m.CREATED_AT, m.UPDATED_AT, "
          + "mt.MACHINE_TYPE_ID, mt.MACHINE_CODE, mt.MACHINE_NAME AS TYPE_NAME, mt.STATUS AS TYPE_STATUS "
          + "FROM MACHINE m "
          + "JOIN MACHINE_TYPE mt ON mt.MACHINE_TYPE_ID = m.MACHINE_TYPE_ID ";

    // ------------------------------------------------------------------ //
    //  GenericDAO contract
    // ------------------------------------------------------------------ //

    @Override
    public Machine get(Object machineId) throws SQLException {
        String sql = SELECT_WITH_TYPE + "WHERE m.MACHINE_ID = ?";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, (Integer) machineId);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    @Override
    public Machine create(Machine machine) throws SQLException {
        String sql = "INSERT INTO MACHINE (MACHINE_ID, MACHINE_NAME, MACHINE_TYPE_ID, MACHINE_USAGE) "
                   + "VALUES (MACHINE_SEQ.NEXTVAL, ?, ?, ?)";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setString(1, machine.getMachineName());
            pstmt.setInt(2, machine.getMachineType().getMachineTypeId());
            pstmt.setString(3, machine.getMachineUsage());
            if (pstmt.executeUpdate() > 0) {
                return machine;
            }
        }
        return null;
    }

    @Override
    public Machine update(Machine machine) throws SQLException {
        String sql = "UPDATE MACHINE SET "
                   + "MACHINE_NAME = ?, MACHINE_TYPE_ID = ?, MACHINE_USAGE = ?, UPDATED_AT = SYSTIMESTAMP "
                   + "WHERE MACHINE_ID = ?";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setString(1, machine.getMachineName());
            pstmt.setInt(2, machine.getMachineType().getMachineTypeId());
            pstmt.setString(3, machine.getMachineUsage());
            pstmt.setInt(4, machine.getMachineId());
            if (pstmt.executeUpdate() > 0) {
                return machine;
            }
        }
        return null;
    }

    @Override
    public Machine delete(Machine machine) throws SQLException {
        String sql = "DELETE FROM MACHINE WHERE MACHINE_ID = ?";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, machine.getMachineId());
            if (pstmt.executeUpdate() > 0) {
                return machine;
            }
        }
        return null;
    }

    @Override
    public List<Machine> listAll() throws SQLException {
        String sql = SELECT_WITH_TYPE + "ORDER BY mt.MACHINE_CODE ASC, m.MACHINE_NAME ASC";

        List<Machine> list = new ArrayList<>();
        try (PreparedStatement pstmt = con.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        }
        return list;
    }

    /** Duplicate check by machine name (case-insensitive). */
    @Override
    public Machine findDuplicate(Machine machine) throws SQLException {
        String sql = SELECT_WITH_TYPE + "WHERE UPPER(m.MACHINE_NAME) = UPPER(?)";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setString(1, machine.getMachineName());
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    // ------------------------------------------------------------------ //
    //  Machine-specific queries
    // ------------------------------------------------------------------ //

    /** Duplicate check on update: another machine already holds this name. */
    public Machine findDuplicateUpdate(Machine machine) throws SQLException {
        String sql = SELECT_WITH_TYPE + "WHERE UPPER(m.MACHINE_NAME) = UPPER(?) AND m.MACHINE_ID <> ?";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setString(1, machine.getMachineName());
            pstmt.setInt(2, machine.getMachineId());
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    /** Live count of AVAILABLE machines for a type — feeds Monthly Plan reconciliation. */
    public int countAvailableByType(int machineTypeId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM MACHINE "
                   + "WHERE MACHINE_TYPE_ID = ? AND MACHINE_USAGE = 'AVAILABLE'";

        try (PreparedStatement pstmt = con.prepareStatement(sql)) {
            pstmt.setInt(1, machineTypeId);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        return 0;
    }

    // ------------------------------------------------------------------ //
    //  Helpers
    // ------------------------------------------------------------------ //

    private Machine mapRow(ResultSet rs) throws SQLException {
        Machine machine = new Machine();
        machine.setMachineId(rs.getInt("MACHINE_ID"));
        machine.setMachineName(rs.getString("MACHINE_NAME"));
        machine.setMachineUsage(rs.getString("MACHINE_USAGE"));

        MachineType type = new MachineType();
        type.setMachineTypeId(rs.getInt("MACHINE_TYPE_ID"));
        type.setMachineCode(rs.getString("MACHINE_CODE"));
        type.setMachineName(rs.getString("TYPE_NAME"));
        type.setStatus(rs.getString("TYPE_STATUS"));
        machine.setMachineType(type);

        Timestamp created = rs.getTimestamp("CREATED_AT");
        machine.setCreatedAt(created != null ? created.toLocalDateTime() : null);

        Timestamp updated = rs.getTimestamp("UPDATED_AT");
        machine.setUpdatedAt(updated != null ? updated.toLocalDateTime() : null);
        return machine;
    }
}
