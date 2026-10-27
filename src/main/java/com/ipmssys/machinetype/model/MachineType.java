package com.ipmssys.machinetype.model;

import java.time.LocalDateTime;

/**
 * Machine Type master record (e.g. FRST, GSX).
 * Maintained through its own CRUD screen.
 */
public class MachineType {

    private int           machineTypeId;
    private String        machineCode;
    private String        machineName;
    private String        status;        // ACTIVE | INACTIVE
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public MachineType() {
    }

    // Duplicate-check by unique code
    public MachineType(String machineCode) {
        this.machineCode = machineCode;
    }

    // Create
    public MachineType(String machineCode, String machineName, String status) {
        this.machineCode = machineCode;
        this.machineName = machineName;
        this.status      = status;
    }

    public int getMachineTypeId() {
        return machineTypeId;
    }

    public void setMachineTypeId(int machineTypeId) {
        this.machineTypeId = machineTypeId;
    }

    public String getMachineCode() {
        return machineCode;
    }

    public void setMachineCode(String machineCode) {
        this.machineCode = machineCode;
    }

    public String getMachineName() {
        return machineName;
    }

    public void setMachineName(String machineName) {
        this.machineName = machineName;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}