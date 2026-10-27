package com.ipmssys.machineallocation.model;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * An allocation grouping: a firing group + material + batch of items that share
 * common qualified machines. Its total machine-per-day requirement is split into
 * {@code fixRequirement} (ROUNDDOWN -> fully dedicated machines) and
 * {@code fraction1Requirement} (the &lt; 1.0 remainder -> a shared machine).
 */
public class MachineAllocationGroup {

    private int    groupId;
    private int    allocationId;
    private int    groupNo;
    private String groupCode;
    private String materialCode;
    private String mergeKey;
    private double groupingMcPerDay;
    private double fixRequirement;
    private double fraction1Requirement;
    private String status;

    private List<MachineAllocationItem>    items    = new ArrayList<>();
    private List<MachineAllocationMachine> machines = new ArrayList<>();

    // Convenience fields built from the machines list on read, for the JSP.
    private List<String> fixMachineKeys      = new ArrayList<>();
    private String       fraction1MachineKey = "";   // first fraction machine (back-compat)

    // Multi-fraction support: each entry is { machine, share }.
    private List<Map<String, Object>> fractionMachines = new ArrayList<>();

    public MachineAllocationGroup() {}

    public int getGroupId() { return groupId; }
    public void setGroupId(int groupId) { this.groupId = groupId; }

    public int getAllocationId() { return allocationId; }
    public void setAllocationId(int allocationId) { this.allocationId = allocationId; }

    public int getGroupNo() { return groupNo; }
    public void setGroupNo(int groupNo) { this.groupNo = groupNo; }

    public String getGroupCode() { return groupCode; }
    public void setGroupCode(String groupCode) { this.groupCode = groupCode; }

    public String getMaterialCode() { return materialCode; }
    public void setMaterialCode(String materialCode) { this.materialCode = materialCode; }

    public String getMergeKey() { return mergeKey; }
    public void setMergeKey(String mergeKey) { this.mergeKey = mergeKey; }

    public double getGroupingMcPerDay() { return groupingMcPerDay; }
    public void setGroupingMcPerDay(double groupingMcPerDay) { this.groupingMcPerDay = groupingMcPerDay; }

    public double getFixRequirement() { return fixRequirement; }
    public void setFixRequirement(double fixRequirement) { this.fixRequirement = fixRequirement; }

    public double getFraction1Requirement() { return fraction1Requirement; }
    public void setFraction1Requirement(double v) { this.fraction1Requirement = v; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public List<MachineAllocationItem> getItems() { return items; }
    public void setItems(List<MachineAllocationItem> items) { this.items = items; }

    public List<MachineAllocationMachine> getMachines() { return machines; }
    public void setMachines(List<MachineAllocationMachine> machines) { this.machines = machines; }

    public List<String> getFixMachineKeys() { return fixMachineKeys; }
    public void setFixMachineKeys(List<String> fixMachineKeys) { this.fixMachineKeys = fixMachineKeys; }

    public String getFraction1MachineKey() { return fraction1MachineKey; }
    public void setFraction1MachineKey(String fraction1MachineKey) { this.fraction1MachineKey = fraction1MachineKey; }

    public List<Map<String, Object>> getFractionMachines() { return fractionMachines; }
    public void setFractionMachines(List<Map<String, Object>> fractionMachines) { this.fractionMachines = fractionMachines; }
}
