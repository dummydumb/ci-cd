package com.ipmssys.plottingsummary.model;

import java.io.Serializable;
import java.time.LocalDate;

/**
 * One per-day schedule row under a PlottingSummary: a date and the hours
 * planned on it. Belongs to PLOTTING_SUMMARY_DETAIL.
 */
public class PlottingSummaryDetail implements Serializable {

    private static final long serialVersionUID = 1L;

    private Integer detailId;
    private Integer plottingId;
    private LocalDate scheduleDate;
    private double hours;

    public PlottingSummaryDetail() {
    }

    /** Insert helper (detailId comes from the sequence). */
    public PlottingSummaryDetail(Integer plottingId, LocalDate scheduleDate, double hours) {
        this.plottingId = plottingId;
        this.scheduleDate = scheduleDate;
        this.hours = hours;
    }

    public Integer getDetailId() {
        return detailId;
    }

    public void setDetailId(Integer detailId) {
        this.detailId = detailId;
    }

    public Integer getPlottingId() {
        return plottingId;
    }

    public void setPlottingId(Integer plottingId) {
        this.plottingId = plottingId;
    }

    public LocalDate getScheduleDate() {
        return scheduleDate;
    }

    public void setScheduleDate(LocalDate scheduleDate) {
        this.scheduleDate = scheduleDate;
    }

    public double getHours() {
        return hours;
    }

    public void setHours(double hours) {
        this.hours = hours;
    }
}
