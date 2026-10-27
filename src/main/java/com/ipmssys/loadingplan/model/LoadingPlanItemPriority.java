package com.ipmssys.loadingplan.model;

public class LoadingPlanItemPriority {
    private int    priorityId;
    private int    planId;
    private String machineName;
    private String itemName;
    private int    prioritySeq;  // lower = runs first

    public LoadingPlanItemPriority() {}

    public LoadingPlanItemPriority(int planId, String machineName, String itemName, int prioritySeq) {
        this.planId      = planId;
        this.machineName = machineName;
        this.itemName    = itemName;
        this.prioritySeq = prioritySeq;
    }

    public int    getPriorityId()  { return priorityId; }
    public void   setPriorityId(int v)  { this.priorityId = v; }
    public int    getPlanId()      { return planId; }
    public void   setPlanId(int v)      { this.planId = v; }
    public String getMachineName() { return machineName; }
    public void   setMachineName(String v) { this.machineName = v; }
    public String getItemName()    { return itemName; }
    public void   setItemName(String v)    { this.itemName = v; }
    public int    getPrioritySeq() { return prioritySeq; }
    public void   setPrioritySeq(int v)  { this.prioritySeq = v; }
}