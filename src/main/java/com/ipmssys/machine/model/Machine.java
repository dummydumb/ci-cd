package com.ipmssys.machine.model;

import java.io.Serializable;
import java.time.LocalDateTime;

import com.ipmssys.machinetype.model.MachineType;

/**
 * A physical machine. Belongs to one MACHINE_TYPE (process). MACHINE_USAGE
 * marks whether it counts toward planning (AVAILABLE) or not (UNAVAILABLE).
 *
 * The machineType is populated from the join so the screen can show the
 * type code/name and serialize it to JSON in one object.
 */
public class Machine implements Serializable {

    private static final long serialVersionUID = 1L;

    private Integer machineId;
    private String machineName;
    private MachineType machineType;
    private String machineUsage;       // AVAILABLE | UNAVAILABLE
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public Machine() {
    }

    /** Duplicate check by name. */
    public Machine(String machineName) {
        this.machineName = machineName;
    }

    /** Create / full save. */
    public Machine(String machineName, MachineType machineType, String machineUsage) {
        this.machineName = machineName;
        this.machineType = machineType;
        this.machineUsage = machineUsage;
    }

    public Integer getMachineId() {
        return machineId;
    }

    public void setMachineId(Integer machineId) {
        this.machineId = machineId;
    }

    public String getMachineName() {
        return machineName;
    }

    public void setMachineName(String machineName) {
        this.machineName = machineName;
    }

    public MachineType getMachineType() {
        return machineType;
    }

    public void setMachineType(MachineType machineType) {
        this.machineType = machineType;
    }

    public String getMachineUsage() {
        return machineUsage;
    }

    public void setMachineUsage(String machineUsage) {
        this.machineUsage = machineUsage;
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
