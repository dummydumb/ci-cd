package com.ipmssys.machineallocation.model;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * One machine allocation per monthly plan. Holds the groups, each of which
 * splits its machine requirement into FIX and FRACTION machines.
 */
public class MachineAllocation {

    private int           allocationId;
    private int           planId;
    private int           fixLimit;
    private String        status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    private List<MachineAllocationGroup> groups = new ArrayList<>();

    public MachineAllocation() {}

    public MachineAllocation(int planId, int fixLimit) {
        this.planId   = planId;
        this.fixLimit = fixLimit;
        this.status   = "SAVED";
    }

    public int getAllocationId() { return allocationId; }
    public void setAllocationId(int allocationId) { this.allocationId = allocationId; }

    public int getPlanId() { return planId; }
    public void setPlanId(int planId) { this.planId = planId; }

    public int getFixLimit() { return fixLimit; }
    public void setFixLimit(int fixLimit) { this.fixLimit = fixLimit; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    public List<MachineAllocationGroup> getGroups() { return groups; }
    public void setGroups(List<MachineAllocationGroup> groups) { this.groups = groups; }
}
