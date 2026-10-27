package com.ipmssys.saggering.model;

import java.io.Serializable;
import java.time.LocalDate;

/**
 * One day's saggering value for an item: a date and the planned value on it.
 */
public class SaggeringDay implements Serializable {

    private static final long serialVersionUID = 1L;

    private Integer saggeringDayId;
    private Integer saggeringItemId;
    private LocalDate planDate;
    private int value;

    public SaggeringDay() {
    }

    public SaggeringDay(LocalDate planDate, int value) {
        this.planDate = planDate;
        this.value = value;
    }

    public Integer getSaggeringDayId() {
        return saggeringDayId;
    }

    public void setSaggeringDayId(Integer saggeringDayId) {
        this.saggeringDayId = saggeringDayId;
    }

    public Integer getSaggeringItemId() {
        return saggeringItemId;
    }

    public void setSaggeringItemId(Integer saggeringItemId) {
        this.saggeringItemId = saggeringItemId;
    }

    public LocalDate getPlanDate() {
        return planDate;
    }

    public void setPlanDate(LocalDate planDate) {
        this.planDate = planDate;
    }

    public int getValue() {
        return value;
    }

    public void setValue(int value) {
        this.value = value;
    }
}
