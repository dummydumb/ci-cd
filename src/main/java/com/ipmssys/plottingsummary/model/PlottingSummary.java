package com.ipmssys.plottingsummary.model;

import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import com.ipmssys.item.model.Item;
import com.ipmssys.machine.model.Machine;
import com.ipmssys.machinetype.model.MachineType;

/**
 * A plotting summary header. Relationships are proper FKs now:
 *   item           -> ITEM
 *   machineType    -> MACHINE_TYPE (the process)
 *   stackingMachine-> MACHINE (nullable)
 *
 * The free-text attributes (evaluation, category, type, itemType, plan,
 * wosType, pic) stay as plain strings. Per-day schedule rows live in
 * {@code details}; totalHours/totalDays are aggregated from them.
 */
public class PlottingSummary implements Serializable {

    private static final long serialVersionUID = 1L;

    private Integer plottingId;
    private String evaluation;
    private String category;
    private String type;
    private Item item;
    private String itemType;
    private String plan;
    private int noOfLots;
    private String wosType;
    private MachineType machineType;
    private Machine stackingMachine;   // nullable
    private LocalDate datePreferred;
    private LocalDate confirmedDate;   // nullable
    private String pic;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Computed from the detail rows (not stored)
    private double totalHours;
    private int totalDays;

    // Per-day schedule rows (loaded for get/edit; set for save)
    private List<PlottingSummaryDetail> details = new ArrayList<>();

    public PlottingSummary() {
    }

    /** Minimal (delete / FK reference). */
    public PlottingSummary(Integer plottingId) {
        this.plottingId = plottingId;
    }

    public Integer getPlottingId() {
        return plottingId;
    }

    public void setPlottingId(Integer plottingId) {
        this.plottingId = plottingId;
    }

    public String getEvaluation() {
        return evaluation;
    }

    public void setEvaluation(String evaluation) {
        this.evaluation = evaluation;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public Item getItem() {
        return item;
    }

    public void setItem(Item item) {
        this.item = item;
    }

    public String getItemType() {
        return itemType;
    }

    public void setItemType(String itemType) {
        this.itemType = itemType;
    }

    public String getPlan() {
        return plan;
    }

    public void setPlan(String plan) {
        this.plan = plan;
    }

    public int getNoOfLots() {
        return noOfLots;
    }

    public void setNoOfLots(int noOfLots) {
        this.noOfLots = noOfLots;
    }

    public String getWosType() {
        return wosType;
    }

    public void setWosType(String wosType) {
        this.wosType = wosType;
    }

    public MachineType getMachineType() {
        return machineType;
    }

    public void setMachineType(MachineType machineType) {
        this.machineType = machineType;
    }

    public Machine getStackingMachine() {
        return stackingMachine;
    }

    public void setStackingMachine(Machine stackingMachine) {
        this.stackingMachine = stackingMachine;
    }

    public LocalDate getDatePreferred() {
        return datePreferred;
    }

    public void setDatePreferred(LocalDate datePreferred) {
        this.datePreferred = datePreferred;
    }

    public LocalDate getConfirmedDate() {
        return confirmedDate;
    }

    public void setConfirmedDate(LocalDate confirmedDate) {
        this.confirmedDate = confirmedDate;
    }

    public String getPic() {
        return pic;
    }

    public void setPic(String pic) {
        this.pic = pic;
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

    public double getTotalHours() {
        return totalHours;
    }

    public void setTotalHours(double totalHours) {
        this.totalHours = totalHours;
    }

    public int getTotalDays() {
        return totalDays;
    }

    public void setTotalDays(int totalDays) {
        this.totalDays = totalDays;
    }

    public List<PlottingSummaryDetail> getDetails() {
        return details;
    }

    public void setDetails(List<PlottingSummaryDetail> details) {
        this.details = details;
    }
}
