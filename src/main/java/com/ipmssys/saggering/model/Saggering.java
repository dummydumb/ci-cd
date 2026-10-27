package com.ipmssys.saggering.model;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * A saggering plan header (one per monthly plan), carrying its item -> day
 * tree. Populated fully by SaggeringDAO.getByPlanId().
 */
public class Saggering implements Serializable {

    private static final long serialVersionUID = 1L;

    private Integer saggeringId;
    private Integer planId;
    private String status;         // DRAFT | ACTIVE | CLOSED
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    private List<SaggeringItem> items = new ArrayList<>();

    public Saggering() {
    }

    public Saggering(Integer planId, String status) {
        this.planId = planId;
        this.status = status;
    }

    public Integer getSaggeringId() {
        return saggeringId;
    }

    public void setSaggeringId(Integer saggeringId) {
        this.saggeringId = saggeringId;
    }

    public Integer getPlanId() {
        return planId;
    }

    public void setPlanId(Integer planId) {
        this.planId = planId;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
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

    public List<SaggeringItem> getItems() {
        return items;
    }

    public void setItems(List<SaggeringItem> items) {
        this.items = items;
    }
}
