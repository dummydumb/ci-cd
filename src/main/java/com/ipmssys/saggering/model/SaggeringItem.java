package com.ipmssys.saggering.model;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

import com.ipmssys.item.model.Item;

/**
 * One item within a saggering plan, with its per-day values. capCode and
 * lotsPerBatch are carried alongside (sourced from PRECONDITION_RAW when the
 * item has preconditions). item is the FK to ITEM.
 */
public class SaggeringItem implements Serializable {

    private static final long serialVersionUID = 1L;

    private Integer saggeringItemId;
    private Integer saggeringId;
    private Item item;             // FK to ITEM (embedded for display)
    private String capCode;
    private int lotsPerBatch;

    private List<SaggeringDay> days = new ArrayList<>();

    public SaggeringItem() {
    }

    public Integer getSaggeringItemId() {
        return saggeringItemId;
    }

    public void setSaggeringItemId(Integer saggeringItemId) {
        this.saggeringItemId = saggeringItemId;
    }

    public Integer getSaggeringId() {
        return saggeringId;
    }

    public void setSaggeringId(Integer saggeringId) {
        this.saggeringId = saggeringId;
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

    public List<SaggeringDay> getDays() {
        return days;
    }

    public void setDays(List<SaggeringDay> days) {
        this.days = days;
    }
}
