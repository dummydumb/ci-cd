package com.ipmssys.loadingplan.model;

import java.time.LocalDate;
import java.time.LocalDateTime;

public class LoadingPlanFractionPlot {

    private int           plotId;
    private int           planId;
    private String        machineName;
    private String        itemName;
    private LocalDate     plotStart;
    private LocalDate     plotEnd;
    private int           totalLots;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public LoadingPlanFractionPlot() {}

    public LoadingPlanFractionPlot(int planId, String machineName, String itemName,
            LocalDate plotStart, LocalDate plotEnd, int totalLots) {
        this.planId      = planId;
        this.machineName = machineName;
        this.itemName    = itemName;
        this.plotStart   = plotStart;
        this.plotEnd     = plotEnd;
        this.totalLots   = totalLots;
    }

    public int getPlotId() { return plotId; }
    public void setPlotId(int plotId) { this.plotId = plotId; }

    public int getPlanId() { return planId; }
    public void setPlanId(int planId) { this.planId = planId; }

    public String getMachineName() { return machineName; }
    public void setMachineName(String machineName) { this.machineName = machineName; }

    public String getItemName() { return itemName; }
    public void setItemName(String itemName) { this.itemName = itemName; }

    public LocalDate getPlotStart() { return plotStart; }
    public void setPlotStart(LocalDate plotStart) { this.plotStart = plotStart; }

    public LocalDate getPlotEnd() { return plotEnd; }
    public void setPlotEnd(LocalDate plotEnd) { this.plotEnd = plotEnd; }

    public int getTotalLots() { return totalLots; }
    public void setTotalLots(int totalLots) { this.totalLots = totalLots; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}