package com.ipmssys.loadingplan.model;

import java.util.HashMap;
import java.util.Map;

public class LoadingPlanRow {

    private String  machineRole;         // "Fix", "Fraction", "Qualified", "Unallocated"
    private String  machineName;
    private String  itemName;
    private String  groupCode;
    private double  machineShare;
    private double  maxCapaLotsPerDay;   // full machine capacity, 3-decimal precision
    private int     capaWithConversion;  // legacy int — use convCapaLotsPerDay for display
    private double  convCapaLotsPerDay;  // full converted capacity, 3-decimal precision
    private int     monthTotalLots;
    private int     lastProductionDay; // per-row: last day with a value (fraction rows compute their own)
    private String  status;
    private boolean qualifiedOnly;

    // Per-day computed lot values — key: day number (1–31)
    private Map<Integer, Integer> dayValues        = new HashMap<Integer, Integer>();

    // Per-day maintenance hours — populated during maintenance adjustment phase
    private Map<Integer, Double>  maintenanceHours = new HashMap<Integer, Double>();

    // Per-day maintenance type — "PM", "Evaluation", "ME Improvement"
    // Drives cell highlight colour in the JSP
    private Map<Integer, String>  maintenanceTypes = new HashMap<Integer, String>();

    // Per-day maintenance PIC (Person In Charge) — shown in hover tooltip
    private Map<Integer, String>  maintenancePics  = new HashMap<Integer, String>();

    // Per-day excess after maintenance cut — used for redistribution
    private Map<Integer, Integer> excessValues        = new HashMap<Integer, Integer>();

    // Reroute indicators — set during Phase 4 excess redistribution.
    // Source: cell whose value was cut by maintenance and excess was rerouted away.
    //         Value = lots that were rerouted (for tooltip: "X lots rerouted to fraction").
    // Target: cell that received rerouted lots from another machine's maintenance excess.
    //         Value = lots received (for tooltip: "X lots received from F01 Day 10").
    private Map<Integer, Integer> reroutedSourceFlags = new HashMap<Integer, Integer>();
    private Map<Integer, Integer> reroutedTargetFlags = new HashMap<Integer, Integer>();

    // ── Override state maps — populated by LoadingPlanService.applyOverrides() ──

    // Snapshot of computed values taken BEFORE overrides are applied.
    // Shown in edit dialog as "Original: X → Current: Y"
    private Map<Integer, Integer> originalDayValues = new HashMap<Integer, Integer>();

    // True when a cell has been manually edited (amber border)
    private Map<Integer, Boolean> overriddenFlags   = new HashMap<Integer, Boolean>();

    // True when lots were MOVED HERE from another machine (blue — reassign target)
    private Map<Integer, Boolean> reassignedFlags   = new HashMap<Integer, Boolean>();

    // Reason a source cell was zeroed out — drives highlight colour on source
    // "MACHINE_TROUBLE" → red, "UNPLANNED_MAINTENANCE" → orange, "OTHER" → grey
    private Map<Integer, String>  reassignReasons   = new HashMap<Integer, String>();

    // True when this is a RECOVERY source (pink — original value kept intact)
    private Map<Integer, Boolean> recoverySourceFlags = new HashMap<Integer, Boolean>();

    // True when this cell received recovery lots (green — extra lots via conv capa)
    private Map<Integer, Boolean> recoveryTargetFlags = new HashMap<Integer, Boolean>();

    // conversionDayFlags  — incoming item's first day (pink dashed border): machine is switching
    //                        to this item, value should be at convCapaLotsPerDay
    private Map<Integer, Boolean> conversionDayFlags   = new HashMap<Integer, Boolean>();

    // conversionSourceFlags — outgoing item's LAST day (pink border + purple background):
    //                         tomorrow this machine switches to a different item,
    //                         indicating conversion/setup time will be needed
    private Map<Integer, Boolean> conversionSourceFlags = new HashMap<Integer, Boolean>();

    // Free-text remarks attached to any overridden cell — shown in tooltip
    private Map<Integer, String>  remarksMap        = new HashMap<Integer, String>();

    // cellStatusByDay — MANUAL Excel-style status flag per day (planner-applied).
    // Values: NONE, PM, TROUBLE, EVALUATION, ADVANCE, ME_IMPROVEMENT, NEEDS_CONVERSION, OK_SUBMITTED.
    private Map<Integer, String>  cellStatusByDay   = new HashMap<Integer, String>();

    public LoadingPlanRow() {}

    // ---- Day value accessors ----

    public int getDayValue(int day) {
        Integer v = dayValues.get(day);
        return v != null ? v : 0;
    }
    public void setDayValue(int day, int value) {
        dayValues.put(day, value);
    }

    public double getMaintenanceHours(int day) {
        Double v = maintenanceHours.get(day);
        return v != null ? v : 0.0;
    }
    public void setMaintenanceHours(int day, double hours) {
        maintenanceHours.put(day, hours);
    }

    public String getMaintenanceType(int day) {
        String v = maintenanceTypes.get(day);
        return v != null ? v : "";
    }
    public void setMaintenanceType(int day, String type) {
        maintenanceTypes.put(day, type);
    }

    public String getMaintenancePic(int day) {
        String v = maintenancePics.get(day);
        return v != null ? v : "";
    }
    public void setMaintenancePic(int day, String pic) {
        maintenancePics.put(day, pic);
    }

    public int getExcess(int day) {
        Integer v = excessValues.get(day); return v != null ? v : 0;
    }
    public void setExcess(int day, int excess) { excessValues.put(day, excess); }

    public int getReroutedSource(int day) {
        Integer v = reroutedSourceFlags.get(day); return v != null ? v : 0;
    }
    public void setReroutedSource(int day, int lots) { reroutedSourceFlags.put(day, lots); }

    public int getReroutedTarget(int day) {
        Integer v = reroutedTargetFlags.get(day); return v != null ? v : 0;
    }
    public void setReroutedTarget(int day, int lots) { reroutedTargetFlags.put(day, lots); }

    // ── Override state accessors ───────────────────────────────────────

    public int getOriginalDayValue(int day) {
        Integer v = originalDayValues.get(day);
        return v != null ? v : getDayValue(day);
    }

    public boolean isOverridden(int day) {
        Boolean v = overriddenFlags.get(day); return v != null && v;
    }
    public void setOverridden(int day, boolean v) { overriddenFlags.put(day, v); }

    public boolean isReassigned(int day) {
        Boolean v = reassignedFlags.get(day); return v != null && v;
    }
    public void setReassigned(int day, boolean v) { reassignedFlags.put(day, v); }

    public String getReassignReason(int day) {
        String v = reassignReasons.get(day); return v != null ? v : "";
    }
    public void setReassignReason(int day, String reason) { reassignReasons.put(day, reason); }

    public boolean isRecoverySource(int day) {
        Boolean v = recoverySourceFlags.get(day); return v != null && v;
    }
    public void setRecoverySource(int day, boolean v) { recoverySourceFlags.put(day, v); }

    public boolean isRecoveryTarget(int day) {
        Boolean v = recoveryTargetFlags.get(day); return v != null && v;
    }
    public void setRecoveryTarget(int day, boolean v) { recoveryTargetFlags.put(day, v); }

    public boolean isConversionDay(int day) {
        Boolean v = conversionDayFlags.get(day); return v != null && v;
    }
    public void setConversionDay(int day, boolean v) { conversionDayFlags.put(day, v); }

    public boolean isConversionSource(int day) {
        Boolean v = conversionSourceFlags.get(day); return v != null && v;
    }
    public void setConversionSource(int day, boolean v) { conversionSourceFlags.put(day, v); }

    public String getRemarks(int day) {
        String v = remarksMap.get(day); return v != null ? v : "";
    }
    public void setRemarks(int day, String remarks) { remarksMap.put(day, remarks); }

    // ---- Standard getters/setters ----

    public String getMachineRole() { return machineRole; }
    public void setMachineRole(String machineRole) { this.machineRole = machineRole; }

    public String getMachineName() { return machineName; }
    public void setMachineName(String machineName) { this.machineName = machineName; }

    public String getItemName() { return itemName; }
    public void setItemName(String itemName) { this.itemName = itemName; }

    public String getGroupCode() { return groupCode; }
    public void setGroupCode(String groupCode) { this.groupCode = groupCode; }

    public double getMachineShare() { return machineShare; }
    public void setMachineShare(double machineShare) { this.machineShare = machineShare; }

    public double getMaxCapaLotsPerDay() { return maxCapaLotsPerDay; }
    public void setMaxCapaLotsPerDay(double maxCapaLotsPerDay) { this.maxCapaLotsPerDay = maxCapaLotsPerDay; }

    public int getCapaWithConversion() { return capaWithConversion; }
    public void setCapaWithConversion(int capaWithConversion) { this.capaWithConversion = capaWithConversion; }

    public double getConvCapaLotsPerDay() { return convCapaLotsPerDay; }
    public void setConvCapaLotsPerDay(double convCapaLotsPerDay) { this.convCapaLotsPerDay = convCapaLotsPerDay; }

    public int getMonthTotalLots() { return monthTotalLots; }
    public void setMonthTotalLots(int monthTotalLots) { this.monthTotalLots = monthTotalLots; }

    public int getLastProductionDay() { return lastProductionDay; }
    public void setLastProductionDay(int lastProductionDay) { this.lastProductionDay = lastProductionDay; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public boolean isQualifiedOnly() { return qualifiedOnly; }
    public void setQualifiedOnly(boolean qualifiedOnly) { this.qualifiedOnly = qualifiedOnly; }

    // Expose maps for Gson serialization to JSP JSON
    public Map<Integer, Integer> getDayValues()          { return dayValues; }
    public Map<Integer, Double>  getMaintenanceHours()   { return maintenanceHours; }
    public Map<Integer, String>  getMaintenanceTypes()   { return maintenanceTypes; }
    public Map<Integer, String>  getMaintenancePics()    { return maintenancePics; }
    public Map<Integer, Integer> getOriginalDayValues()  { return originalDayValues; }
    public Map<Integer, Boolean> getOverriddenFlags()    { return overriddenFlags; }
    public Map<Integer, Boolean> getReassignedFlags()    { return reassignedFlags; }
    public Map<Integer, String>  getReassignReasons()    { return reassignReasons; }
    public Map<Integer, Boolean> getRecoverySourceFlags(){ return recoverySourceFlags; }
    public Map<Integer, Boolean> getRecoveryTargetFlags(){ return recoveryTargetFlags; }
    public Map<Integer, String>  getRemarksMap()         { return remarksMap; }

    public String getCellStatus(int day) {
        String v = cellStatusByDay.get(day); return v != null ? v : "NONE";
    }
    public void setCellStatus(int day, String status) {
        if (status == null || status.isEmpty() || "NONE".equals(status)) {
            cellStatusByDay.remove(day);
        } else {
            cellStatusByDay.put(day, status);
        }
    }
    public Map<Integer, String>  getCellStatusByDay()    { return cellStatusByDay; }
    public Map<Integer, Integer> getReroutedSourceFlags(){ return reroutedSourceFlags; }
    public Map<Integer, Integer> getReroutedTargetFlags(){ return reroutedTargetFlags; }
    public Map<Integer, Boolean> getConversionDayFlags()    { return conversionDayFlags; }
    public Map<Integer, Boolean> getConversionSourceFlags() { return conversionSourceFlags; }
}