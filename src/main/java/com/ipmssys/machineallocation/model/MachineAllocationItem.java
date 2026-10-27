package com.ipmssys.machineallocation.model;

/**
 * An item inside an allocation group, with its machine-per-day requirement
 * (from the computed Precondition MC REQT).
 */
public class MachineAllocationItem {

    private int    itemId;        // allocation item PK (NOT ITEM.ITEM_ID)
    private int    groupId;
    private int    allocationId;
    private String itemName;
    private int    itemSeq;
    private double mcPerDay;
    private String groupCode;
    private String materialCode;

    public MachineAllocationItem() {}

    public MachineAllocationItem(int groupId, int allocationId,
            String itemName, int itemSeq, double mcPerDay,
            String groupCode, String materialCode) {
        this.groupId      = groupId;
        this.allocationId = allocationId;
        this.itemName     = itemName;
        this.itemSeq      = itemSeq;
        this.mcPerDay     = mcPerDay;
        this.groupCode    = groupCode;
        this.materialCode = materialCode;
    }

    public int getItemId() { return itemId; }
    public void setItemId(int itemId) { this.itemId = itemId; }

    public int getGroupId() { return groupId; }
    public void setGroupId(int groupId) { this.groupId = groupId; }

    public int getAllocationId() { return allocationId; }
    public void setAllocationId(int allocationId) { this.allocationId = allocationId; }

    public String getItemName() { return itemName; }
    public void setItemName(String itemName) { this.itemName = itemName; }

    public int getItemSeq() { return itemSeq; }
    public void setItemSeq(int itemSeq) { this.itemSeq = itemSeq; }

    public double getMcPerDay() { return mcPerDay; }
    public void setMcPerDay(double mcPerDay) { this.mcPerDay = mcPerDay; }

    public String getGroupCode() { return groupCode; }
    public void setGroupCode(String groupCode) { this.groupCode = groupCode; }

    public String getMaterialCode() { return materialCode; }
    public void setMaterialCode(String materialCode) { this.materialCode = materialCode; }
}
