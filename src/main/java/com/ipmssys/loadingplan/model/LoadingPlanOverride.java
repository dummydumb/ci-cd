package com.ipmssys.loadingplan.model;

import java.time.LocalDate;
import java.time.LocalDateTime;

public class LoadingPlanOverride {

    private int           overrideId;
    private int           planId;
    private String        machineName;
    private String        itemName;
    private LocalDate     planDate;
    private double        overrideValue;
    private String        reassignReason;    // "MACHINE_TROUBLE", "UNPLANNED_MAINTENANCE", "OTHER", or null
    private String        overrideType;      // "STANDARD" (default) or "RECOVERY"
    private String        remarks;           // free-text for supervisor review
    private LocalDate     recoverySourceDate;// target row only: source date being compensated
    private String        cellStatus;        // manual Excel-style status flag (see CELL_STATUS values)
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public LoadingPlanOverride() {}

    public LoadingPlanOverride(int planId, String machineName,
            String itemName, LocalDate planDate, double overrideValue) {
        this.planId        = planId;
        this.machineName   = machineName;
        this.itemName      = itemName;
        this.planDate      = planDate;
        this.overrideValue = overrideValue;
    }

    public int getOverrideId() { return overrideId; }
    public void setOverrideId(int overrideId) { this.overrideId = overrideId; }

    public int getPlanId() { return planId; }
    public void setPlanId(int planId) { this.planId = planId; }

    public String getMachineName() { return machineName; }
    public void setMachineName(String machineName) { this.machineName = machineName; }

    public String getItemName() { return itemName; }
    public void setItemName(String itemName) { this.itemName = itemName; }

    public LocalDate getPlanDate() { return planDate; }
    public void setPlanDate(LocalDate planDate) { this.planDate = planDate; }

    public double getOverrideValue() { return overrideValue; }
    public void setOverrideValue(double overrideValue) { this.overrideValue = overrideValue; }

    public String getReassignReason() { return reassignReason; }
    public void setReassignReason(String reassignReason) { this.reassignReason = reassignReason; }

    public String getOverrideType() { return overrideType != null ? overrideType : "STANDARD"; }
    public void setOverrideType(String overrideType) { this.overrideType = overrideType; }

    public String getRemarks() { return remarks; }
    public void setRemarks(String remarks) { this.remarks = remarks; }

    public LocalDate getRecoverySourceDate() { return recoverySourceDate; }
    public void setRecoverySourceDate(LocalDate recoverySourceDate) { this.recoverySourceDate = recoverySourceDate; }

    // Manual per-cell status matching the Excel legend. One of:
    //   NONE, PM, TROUBLE, EVALUATION, ADVANCE, ME_IMPROVEMENT, NEEDS_CONVERSION, OK_SUBMITTED
    public String getCellStatus() { return cellStatus != null ? cellStatus : "NONE"; }
    public void setCellStatus(String cellStatus) { this.cellStatus = cellStatus; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}