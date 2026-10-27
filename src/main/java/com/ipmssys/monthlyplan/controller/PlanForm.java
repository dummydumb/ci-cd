package com.ipmssys.monthlyplan.controller;

import java.time.LocalDate;
import java.time.format.DateTimeParseException;

import javax.servlet.http.HttpServletRequest;

/**
 * Parses and validates the monthly-plan request parameters, shared by the
 * create and update servlets so the rules live in one place.
 *
 * Expected parameters:
 *   planmonth          "YYYY-MM"   (normalized to the 1st of the month)
 *   machinetypeid      int
 *   description        optional text
 *   productiontime     int >= 0
 *   efficiency         int 0..100
 *   availablemachine   int >= 0
 *   status             DRAFT | ACTIVE | CLOSED
 *   lastdayproduction  "YYYY-MM-DD"  (must fall on/after planmonth)
 */
class PlanForm {

    LocalDate planMonth;
    Integer machineTypeId;
    String description;
    Integer productionTime;
    Integer efficiency;
    Integer workingDays;
    Integer availableMachine;
    String statusValue;
    LocalDate lastDayProduction;

    private boolean planMonthValid;
    private boolean lastDayValid;

    static PlanForm from(HttpServletRequest request) {
        PlanForm form = new PlanForm();

        form.planMonth = parseMonth(request.getParameter("planmonth"));
        form.planMonthValid = form.planMonth != null;

        form.machineTypeId = parseInt(request.getParameter("machinetypeid"));
        form.description = trimToNull(request.getParameter("description"));
        form.productionTime = parseInt(request.getParameter("productiontime"));
        form.efficiency = parseInt(request.getParameter("efficiency"));
        form.workingDays = parseInt(request.getParameter("workingdays"));
        form.availableMachine = parseInt(request.getParameter("availablemachine"));
        form.statusValue = trimToNull(request.getParameter("status"));

        form.lastDayProduction = parseDate(request.getParameter("lastdayproduction"));
        form.lastDayValid = form.lastDayProduction != null;

        return form;
    }

    /** Returns an error message, or null when the form is valid. */
    String validate() {
        if (!planMonthValid) {
            return "Please select a valid plan month.";
        }
        if (machineTypeId == null) {
            return "Please select a machine type.";
        }
        if (productionTime == null || productionTime < 0) {
            return "Production time must be zero or greater.";
        }
        if (efficiency == null || efficiency < 0 || efficiency > 100) {
            return "Efficiency must be between 0 and 100.";
        }
        if (workingDays == null || workingDays < 0 || workingDays > 31) {
            return "Working days must be between 0 and 31.";
        }
        if (availableMachine == null || availableMachine < 0) {
            return "Available machine must be zero or greater.";
        }
        if (!isValidStatus(statusValue)) {
            return "Invalid status.";
        }
        if (!lastDayValid) {
            return "Please select a valid last day of production.";
        }
        if (lastDayProduction.isBefore(planMonth)) {
            return "Last day of production cannot be before the plan month.";
        }
        return null;
    }

    private static boolean isValidStatus(String value) {
        return "DRAFT".equals(value) || "ACTIVE".equals(value) || "CLOSED".equals(value);
    }

    /** "YYYY-MM" -> first day of that month. */
    private static LocalDate parseMonth(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        try {
            return LocalDate.parse(value.trim() + "-01");
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    private static LocalDate parseDate(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        try {
            return LocalDate.parse(value.trim());
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    private static Integer parseInt(String value) {
        try {
            return Integer.valueOf(value.trim());
        } catch (Exception e) {
            return null;
        }
    }

    private static String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
