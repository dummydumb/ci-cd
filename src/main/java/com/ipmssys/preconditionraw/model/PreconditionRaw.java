package com.ipmssys.preconditionraw.model;

import java.io.Serializable;
import java.time.LocalDateTime;

import com.ipmssys.item.model.Item;

/**
 * Raw precondition inputs for one item within one monthly plan. These are the
 * values a planner maintains; the derived capacity numbers (convCapa, machine
 * requirement, etc.) are computed on the fly by PreconditionService and are
 * not stored.
 *
 * EFF is stored as a decimal (0.85 = 85%).
 */
public class PreconditionRaw implements Serializable {

    private static final long serialVersionUID = 1L;

    private Integer preconditionRawId;
    private Integer planId;
    private Item item;              // FK to ITEM (embedded for display)
    private String capCode;
    private int lotsPerBatch;
    private int internalSheet;
    private int dummySheet;
    private int blkPerLot;
    private double kpcsPerLot;
    private double secPerSht;
    private double eff;             // decimal: 0.85 = 85%
    private int lotsPerMonth;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public PreconditionRaw() {
    }

    /** Minimal (delete reference). */
    public PreconditionRaw(Integer preconditionRawId) {
        this.preconditionRawId = preconditionRawId;
    }

    public Integer getPreconditionRawId() {
        return preconditionRawId;
    }

    public void setPreconditionRawId(Integer preconditionRawId) {
        this.preconditionRawId = preconditionRawId;
    }

    public Integer getPlanId() {
        return planId;
    }

    public void setPlanId(Integer planId) {
        this.planId = planId;
    }

    public Item getItem() {
        return item;
    }

    public void setItem(Item item) {
        this.item = item;
    }

    public String getCapCode() {
        return capCode;
    }

    public void setCapCode(String capCode) {
        this.capCode = capCode;
    }

    public int getLotsPerBatch() {
        return lotsPerBatch;
    }

    public void setLotsPerBatch(int lotsPerBatch) {
        this.lotsPerBatch = lotsPerBatch;
    }

    public int getInternalSheet() {
        return internalSheet;
    }

    public void setInternalSheet(int internalSheet) {
        this.internalSheet = internalSheet;
    }

    public int getDummySheet() {
        return dummySheet;
    }

    public void setDummySheet(int dummySheet) {
        this.dummySheet = dummySheet;
    }

    public int getBlkPerLot() {
        return blkPerLot;
    }

    public void setBlkPerLot(int blkPerLot) {
        this.blkPerLot = blkPerLot;
    }

    public double getKpcsPerLot() {
        return kpcsPerLot;
    }

    public void setKpcsPerLot(double kpcsPerLot) {
        this.kpcsPerLot = kpcsPerLot;
    }

    public double getSecPerSht() {
        return secPerSht;
    }

    public void setSecPerSht(double secPerSht) {
        this.secPerSht = secPerSht;
    }

    public double getEff() {
        return eff;
    }

    public void setEff(double eff) {
        this.eff = eff;
    }

    public int getLotsPerMonth() {
        return lotsPerMonth;
    }

    public void setLotsPerMonth(int lotsPerMonth) {
        this.lotsPerMonth = lotsPerMonth;
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
}
