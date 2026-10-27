package com.ipmssys.monthlyplan.model;

import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * A monthly production plan — the anchor of the planning pipeline.
 * One plan per (month, machine type).
 *
 * machineCode / machineName are read-only join fields from MACHINE_TYPE,
 * populated by the list query for display; they are not persisted here.
 */
public class MonthlyPlan implements Serializable {

    private static final long serialVersionUID = 1L;

    private Integer planId;
    private LocalDate planMonth;            // always the 1st of the month
    private Integer machineTypeId;
    private String description;
    private Integer productionTime;
    private Integer efficiency;             // percent, 0..100
    private Integer workingDays;            // planner working days for precondition calc
    private Integer availableMachine;       // committed snapshot
    private String status;                  // DRAFT | ACTIVE | CLOSED
    private LocalDate lastDayProduction;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Join fields (display only)
    private String machineCode;
    private String machineName;

    public MonthlyPlan() {
    }

    /** Duplicate check by (month, machine type). */
    public MonthlyPlan(LocalDate planMonth, Integer machineTypeId) {
        this.planMonth = planMonth;
        this.machineTypeId = machineTypeId;
    }

    /** Create / full save. */
    public MonthlyPlan(LocalDate planMonth, Integer machineTypeId, String description,
                       Integer productionTime, Integer efficiency, Integer workingDays,
                       Integer availableMachine, String status, LocalDate lastDayProduction) {
        this.planMonth = planMonth;
        this.machineTypeId = machineTypeId;
        this.description = description;
        this.productionTime = productionTime;
        this.efficiency = efficiency;
        this.workingDays = workingDays;
        this.availableMachine = availableMachine;
        this.status = status;
        this.lastDayProduction = lastDayProduction;
    }

    public Integer getPlanId() {
        return planId;
    }

    public void setPlanId(Integer planId) {
        this.planId = planId;
    }

    public LocalDate getPlanMonth() {
        return planMonth;
    }

    public void setPlanMonth(LocalDate planMonth) {
        this.planMonth = planMonth;
    }

    public Integer getMachineTypeId() {
        return machineTypeId;
    }

    public void setMachineTypeId(Integer machineTypeId) {
        this.machineTypeId = machineTypeId;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Integer getProductionTime() {
        return productionTime;
    }

    public void setProductionTime(Integer productionTime) {
        this.productionTime = productionTime;
    }

    public Integer getEfficiency() {
        return efficiency;
    }

    public void setEfficiency(Integer efficiency) {
        this.efficiency = efficiency;
    }

    public Integer getWorkingDays() {
        return workingDays;
    }

    public void setWorkingDays(Integer workingDays) {
        this.workingDays = workingDays;
    }

    public Integer getAvailableMachine() {
        return availableMachine;
    }

    public void setAvailableMachine(Integer availableMachine) {
        this.availableMachine = availableMachine;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDate getLastDayProduction() {
        return lastDayProduction;
    }

    public void setLastDayProduction(LocalDate lastDayProduction) {
        this.lastDayProduction = lastDayProduction;
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
}
