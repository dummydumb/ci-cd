package com.ipmssys.machineallocation.model;

/**
 * A machine assigned to an allocation group: either FIX (fully dedicated,
 * requirement 1.0) or FRACTION1 (a fractional share &lt; 1.0 of a shared machine).
 */
public class MachineAllocationMachine {

    private int    machineEntryId;
    private int    groupId;
    private String machineRole;       // "FIX" or "FRACTION1"
    private int    machineSeq;
    private String machineName;
    private double requirementValue;  // 1.0 for FIX, fraction (e.g. 0.4) for FRACTION1

    public MachineAllocationMachine() {}

    public MachineAllocationMachine(int groupId, String machineRole,
            int machineSeq, String machineName, double requirementValue) {
        this.groupId          = groupId;
        this.machineRole      = machineRole;
        this.machineSeq       = machineSeq;
        this.machineName      = machineName;
        this.requirementValue = requirementValue;
    }

    public int getMachineEntryId() { return machineEntryId; }
    public void setMachineEntryId(int machineEntryId) { this.machineEntryId = machineEntryId; }

    public int getGroupId() { return groupId; }
    public void setGroupId(int groupId) { this.groupId = groupId; }

    public String getMachineRole() { return machineRole; }
    public void setMachineRole(String machineRole) { this.machineRole = machineRole; }

    public int getMachineSeq() { return machineSeq; }
    public void setMachineSeq(int machineSeq) { this.machineSeq = machineSeq; }

    public String getMachineName() { return machineName; }
    public void setMachineName(String machineName) { this.machineName = machineName; }

    public double getRequirementValue() { return requirementValue; }
    public void setRequirementValue(double requirementValue) { this.requirementValue = requirementValue; }
}
