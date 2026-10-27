package com.ipmssys.loadingplan.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.ipmssys.loadingplan.model.LoadingPlanFractionPlot;
import com.ipmssys.loadingplan.model.LoadingPlanItemPriority;
import com.ipmssys.loadingplan.model.LoadingPlanOverride;
import com.ipmssys.item.model.Item;
import com.ipmssys.machine.model.Machine;
import com.ipmssys.loadingplan.model.LoadingPlanRow;
import com.ipmssys.machineallocation.model.MachineAllocation;
import com.ipmssys.machineallocation.model.MachineAllocationGroup;
import com.ipmssys.machineallocation.model.MachineAllocationItem;
import com.ipmssys.machineallocation.model.MachineAllocationMachine;
import com.ipmssys.monthlyplan.model.MonthlyPlan;
import com.ipmssys.precondition.model.Precondition;
import com.ipmssys.plottingsummary.model.PlottingSummary;
import com.ipmssys.plottingsummary.model.PlottingSummaryDetail;

public class LoadingPlanService {

    // =========================================================================
    // PUBLIC API
    // =========================================================================

    /**
     * Computes the full loading plan row list for a given plan.
     *
     * Pipeline:
     *   1. Build machine bins from allocation groups (FIX = capacity 1.0, FRACTION1 = fraction value)
     *   2. Compute daily values: floor(capa × share × day) - previousCumulative
     *   3. Add qualified-only rows — machines that are qualified for an item via ITEM_MACHINE
     *      but were not allocated a FIX or FRACTION1 role. These rows start at zero and serve
     *      as candidate targets for maintenance reassignment.
     *   4. Apply plotting maintenance adjustment: (convCapa / 1440) × (remainingHours × 60)
     *   5. Redistribute excess to qualified-only rows when maintenance cuts allocated rows
     *   6. Overlay user overrides on top of computed values
     *   7. Recompute monthly totals
     *
     * @param plan           MonthlyPlan header — provides working days
     * @param allocation     MachineAllocation — provides groups, machines per group
     * @param preconditions  Computed precondition rows — provides capaLotsPerDay, convCapaLotsPerDay
     * @param saggeredItems  Items in the saggering plan with their qualified machines from ITEM_MACHINE
     * @param plottingList   Plotting summary schedules — provides maintenance hours per machine/day
     * @param overrides      User-edited cell values — applied last, after computation
     * @param useConvertedCapa if true, uses convCapaLotsPerDay instead of capaLotsPerDay for base plan
     * @return List of LoadingPlanRow, one per (machine, item, share) combination
     */
    public List<LoadingPlanRow> compute(
            MonthlyPlan plan,
            MachineAllocation allocation,
            List<Precondition> preconditions,
            List<Item> saggeredItems,
            List<PlottingSummary> plottingList,
            List<LoadingPlanOverride> overrides,
            List<LoadingPlanFractionPlot> fractionPlots,
            List<LoadingPlanItemPriority> itemPriorities,
            boolean useConvertedCapa) {

        int planMonth   = plan.getPlanMonth().getMonthValue();
        int planYear    = plan.getPlanMonth().getYear();
        int daysInMonth = plan.getPlanMonth().lengthOfMonth();

        // lastDayOfProduction drives Fraction row compression.
        // If not set, default to full month (no compression).
        int lastProductionDay = daysInMonth;
        if (plan.getLastDayProduction() != null
                && plan.getLastDayProduction().getMonthValue() == planMonth
                && plan.getLastDayProduction().getYear() == planYear) {
            int lpd = plan.getLastDayProduction().getDayOfMonth();
            if (lpd > 0 && lpd <= daysInMonth) {
                lastProductionDay = lpd;
            }
        }

        // Build lookup maps
        Map<String, Precondition>            preconditionMap  = buildPreconditionMap(preconditions);
        Map<String, Map<Integer, MaintenanceDay>> maintenanceMap = buildMaintenanceMap(plottingList, planMonth, planYear);

        List<LoadingPlanRow> rows = new ArrayList<LoadingPlanRow>();

        if (allocation != null && allocation.getGroups() != null) {
            rows = buildAllocatedRows(
                allocation, preconditionMap, maintenanceMap,
                useConvertedCapa, daysInMonth, lastProductionDay, planYear, planMonth
            );
        }

        // Phase 2c — REMOVED (mid-day handoff / same-day split).
        // The Excel runs each item to its last day, then the next item starts the
        // FOLLOWING day — a clean day boundary, never a same-day split. IPMSTEST's
        // applyMidDayHandoff plotted both items on the shared day, which the Excel
        // never does, so it was removed to keep the grid accurate to the Excel.
        // Conversions are a MANUAL planner annotation (see Phase 5 CONVERSION status).

        // Phase 2b — apply extended fraction plots (planner-configured date range + total lots).
        // Applied AFTER base fraction computation so the extended days add on top of whatever
        // the base already placed. Since base fraction puts 0 in days after lastProductionDay,
        // the addition is always clean — no overwriting of computed base values.
        if (fractionPlots != null && !fractionPlots.isEmpty()) {
            applyFractionPlots(rows, fractionPlots, overrides, planYear, planMonth, daysInMonth);
        }

        // Phase 3 — add qualified-only rows for machines not in the allocation.
        // These have zero daily values but appear in the table so the user can
        // see all available options when reassigning items during maintenance.
        if (saggeredItems != null && !saggeredItems.isEmpty()) {
            List<LoadingPlanRow> qualifiedRows = buildQualifiedOnlyRows(
                rows, saggeredItems, preconditionMap, daysInMonth
            );
            rows.addAll(qualifiedRows);
        }

        // Phase 4 — apply maintenance adjustments and excess redistribution
        applyMaintenanceAdjustments(rows, preconditionMap, maintenanceMap, daysInMonth, planYear, planMonth);

        // Snapshot computed values BEFORE overrides — used in edit dialog "Original: X → Current: Y"
        for (LoadingPlanRow row : rows) {
            for (int d = 1; d <= daysInMonth; d++) {
                row.getOriginalDayValues().put(d, row.getDayValue(d));
            }
        }

        // Phase 5 — overlay user overrides on top of computed values
        if (overrides != null && !overrides.isEmpty()) {
            applyOverrides(rows, overrides);
        }

        // Phase 6 — sort rows by planner-defined item priority per machine.
        // Falls back to role → item name order if no priority is set.
        if (itemPriorities != null && !itemPriorities.isEmpty()) {
            applyItemPrioritySort(rows, itemPriorities);
        }

        // Phase 6b — REMOVED (auto conversion-day detection).
        // The Excel does NOT auto-flag changeovers: the planner manually shades the
        // ~few cells that truly need a conversion (purple #7030A0). Auto-detecting
        // every item boundary produced flags the Excel never has (false positives).
        // Manual conversion flags are applied via Phase 5 overrides (CELL_STATUS).

        // Recompute monthly totals after all adjustments
        for (LoadingPlanRow row : rows) {
            int total = 0;
            for (int day = 1; day <= daysInMonth; day++) {
                total += row.getDayValue(day);
            }
            row.setMonthTotalLots(total);
        }

        return rows;
    }

    // =========================================================================
    // PHASE 1 — Build allocated rows from machine bins
    // =========================================================================

    private List<LoadingPlanRow> buildAllocatedRows(
            MachineAllocation allocation,
            Map<String, Precondition> preconditionMap,
            Map<String, Map<Integer, MaintenanceDay>> maintenanceMap,
            boolean useConvertedCapa,
            int daysInMonth, int lastProductionDay, int year, int month) {

        List<LoadingPlanRow> rows = new ArrayList<LoadingPlanRow>();

        for (MachineAllocationGroup group : allocation.getGroups()) {
            List<MachineBin> bins = buildMachineBins(group);

            for (MachineAllocationItem item : group.getItems()) {
                double itemMcDay            = item.getMcPerDay();
                double remainingRequirement = round2(itemMcDay);

                resetBins(bins);

                // Determine whether this specific item needs Fix machine capacity.
                // An item with floor(mcPerDay) = 0 is a pure-fraction item — it should
                // never absorb Fix bin capacity even if the group has a Fix machine
                // (which may be there for another item in the same group).
                // floor(1.49) = 1 → needs Fix   ✓
                // floor(0.08) = 0 → pure fraction, skip Fix bins ✓
                boolean itemNeedsFix = Math.floor(itemMcDay) >= 1;

                int binIndex = 0;

                while (remainingRequirement > 0 && binIndex < bins.size()) {
                    MachineBin bin = bins.get(binIndex);

                    // Skip Fix bins for pure-fraction items
                    if (!itemNeedsFix && "Fix".equals(bin.role)) {
                        binIndex++;
                        continue;
                    }

                    if (bin.remaining <= 0) {
                        binIndex++;
                        continue;
                    }

                    double share = Math.min(remainingRequirement, bin.remaining);
                    share = round2(share);

                    LoadingPlanRow row = buildRow(
                        bin, item, group, share, preconditionMap,
                        useConvertedCapa, daysInMonth, lastProductionDay
                    );

                    rows.add(row);

                    bin.remaining = round2(bin.remaining - share);
                    remainingRequirement = round2(remainingRequirement - share);

                    if (bin.remaining <= 0) {
                        binIndex++;
                    }
                }

                if (remainingRequirement > 0) {
                    rows.add(buildUnallocatedRow(item, group, remainingRequirement, daysInMonth));
                }
            }
        }

        return rows;
    }

    // Resets each bin's remaining capacity to its original capacity.
    // Called at the start of each item within a group so every item
    // gets a fresh view of the available machine bins.
    private void resetBins(List<MachineBin> bins) {
        for (MachineBin bin : bins) {
            bin.remaining = bin.capacity;
        }
    }

    private LoadingPlanRow buildRow(
            MachineBin bin, MachineAllocationItem item, MachineAllocationGroup group,
            double share, Map<String, Precondition> preconditionMap,
            boolean useConvertedCapa, int daysInMonth, int lastProductionDay) {

        String itemKey    = item.getItemName().toUpperCase();
        Precondition pre  = preconditionMap.get(itemKey);

        double capaLotsPerDay     = pre != null ? pre.getCapaLotsPerDay()     : 0;
        double convCapaLotsPerDay = pre != null ? pre.getConvCapaLotsPerDay() : 0;

        double baseCapa = (useConvertedCapa && convCapaLotsPerDay > 0) ? convCapaLotsPerDay : capaLotsPerDay;

        // Max Capa and Conv Capa show the MACHINE'S full capacity per day —
        // not scaled by the allocation share. The share already drives the daily
        // value computation in addDailyValues(). Showing the full capacity lets
        // the planner compare FIX and Fraction rows on equal terms.
        // Stored as double to preserve 3-decimal precision (e.g. 3.847 not 3).
        double maxCapa = capaLotsPerDay;
        double capaCon = convCapaLotsPerDay;
        int    capaCon_legacy = (int) Math.floor(convCapaLotsPerDay * share); // for capaWithConversion (legacy)

        LoadingPlanRow row = new LoadingPlanRow();
        row.setMachineRole(bin.role);
        row.setMachineName(bin.machineName);
        row.setItemName(item.getItemName());
        row.setGroupCode(group.getGroupCode());
        row.setMachineShare(share);
        row.setMaxCapaLotsPerDay(maxCapa);             // full machine capa, double precision
        row.setCapaWithConversion(capaCon_legacy);     // legacy int field kept for backward compat
        row.setConvCapaLotsPerDay(convCapaLotsPerDay); // full conv capa, double precision
        row.setStatus("OK");
        row.setQualifiedOnly(false);

        // Phase 2: Compute daily values using the correct per-row formula.
        // Fix rows run all daysInMonth. Fraction rows compute their own lastDay
        // from ceil(totalLots / (capa × share)) — each fraction allocation
        // finishes independently based on its own share and capa.
        boolean isFraction = "Fraction".equals(bin.role);
        int lastDay = addDailyValues(row, baseCapa, share, daysInMonth, isFraction, lastProductionDay);
        row.setLastProductionDay(lastDay); // store per-row last day for mid-day handoff phase

        return row;
    }

    private LoadingPlanRow buildUnallocatedRow(
            MachineAllocationItem item, MachineAllocationGroup group,
            double remainingRequirement, int daysInMonth) {

        LoadingPlanRow row = new LoadingPlanRow();
        row.setMachineRole("Unallocated");
        row.setMachineName("-");
        row.setItemName(item.getItemName());
        row.setGroupCode(group.getGroupCode());
        row.setMachineShare(remainingRequirement);
        row.setMaxCapaLotsPerDay(0);
        row.setCapaWithConversion(0);
        row.setConvCapaLotsPerDay(0);
        row.setStatus("NO ALLOCATED MACHINE");
        row.setQualifiedOnly(false);

        for (int day = 1; day <= daysInMonth; day++) {
            row.setDayValue(day, 0);
        }

        return row;
    }

    // =========================================================================
    // Daily value formula — verified against guide (Input Plan Plotting Guide)
    // =========================================================================
    //
    // FIX rows:  runs all daysInMonth
    //   day_n = floor(capa × share × n) - floor(capa × share × (n-1))
    //
    // FRACTION rows:  each row computes its OWN last production day as:
    //   totalLots = floor(capa × share × workingDays)
    //   lastDay   = ceil(totalLots / (capa × share))
    //   Same formula as Fix, but zero-fills days after lastDay.
    //
    // workingDays is the plan's working days (= daysInMonth for a standard month).
    // The global lastProductionDay from the plan is no longer used here —
    // each fraction row computes its own natural stopping point independently.
    //
    // Returns the lastDay used (so buildRow can store it on the row).
    private int addDailyValues(LoadingPlanRow row, double capa, double share,
                                int daysInMonth, boolean isFraction, int lastProductionDay) {

        double dailyRate  = capa * share;
        int    totalLots  = (int) Math.floor(dailyRate * daysInMonth);
        int    lastDay    = daysInMonth;
        double plotRate   = dailyRate; // rate used for actual day-by-day plotting

        if (isFraction && dailyRate > 0) {
            // Natural last day = how many days the item needs at the base rate
            int naturalLastDay = (int) Math.ceil((double) totalLots / dailyRate);
            if (naturalLastDay > daysInMonth) { naturalLastDay = daysInMonth; }

            // Cap at lastProductionDay from the plan
            lastDay = Math.min(naturalLastDay, lastProductionDay);
            if (lastDay < 1) { lastDay = 1; }

            // If lastProductionDay forced a shorter window than the natural last day,
            // compress the rate so all totalLots still fit within lastDay.
            // Example: totalLots=120, naturalLastDay=31, lastProductionDay=11
            //   plotRate = 120 / 11 = 10.909 → 11 10 11 11 10 11 11 10 11 11 10 (sums to 120)
            // If the item naturally finishes before lastProductionDay, no compression needed —
            // the natural rate already fits all lots within lastDay.
            if (lastDay < naturalLastDay && lastDay > 0) {
                plotRate = (double) totalLots / lastDay;
            }
        }

        int previousCumulative = 0;
        int lastFilledDay      = lastDay;

        for (int day = 1; day <= daysInMonth; day++) {
            if (day > lastDay) {
                row.setDayValue(day, 0);
                continue;
            }
            int cumulative = (int) Math.floor(plotRate * day);
            int dailyValue = cumulative - previousCumulative;
            row.setDayValue(day, dailyValue);
            previousCumulative = cumulative;
            lastFilledDay = day;
        }

        // Absorb any rounding loss into the last day so the monthly total
        // is always exactly totalLots (e.g. 120/11=10.909 → cumulative floors
        // may give 119; add 1 to the last day to make it 120).
        if (isFraction && previousCumulative < totalLots && lastFilledDay > 0) {
            int remainder = totalLots - previousCumulative;
            row.setDayValue(lastFilledDay, row.getDayValue(lastFilledDay) + remainder);
            previousCumulative = totalLots;
        }

        row.setMonthTotalLots(previousCumulative);
        return lastDay;
    }

    // =========================================================================
    // PHASE 3 — Build qualified-only rows
    // One zero-value row per (machine, item) pair where:
    //   - the item appears in the saggering plan
    //   - the machine is in ITEM_MACHINE for that item (qualified)
    //   - the (machine, item) combination is NOT already in the allocated rows
    // These rows exist purely as reassignment targets — they start at 0 lots.
    // =========================================================================

    private List<LoadingPlanRow> buildQualifiedOnlyRows(
            List<LoadingPlanRow> allocatedRows,
            List<Item> saggeredItems,
            Map<String, Precondition> preconditionMap,
            int daysInMonth) {

        // Build set of (machineName, itemName) pairs already covered by allocated rows
        java.util.Set<String> allocatedKeys = new java.util.HashSet<String>();
        for (LoadingPlanRow r : allocatedRows) {
            if (r.getMachineName() != null && !"-".equals(r.getMachineName())) {
                allocatedKeys.add(r.getMachineName().toUpperCase() + "|" + r.getItemName().toUpperCase());
            }
        }

        // Build a lookup: machineName.toUpperCase() → the role that machine has
        // in the allocation. A machine that appears as "Fraction" in Machine Allocation
        // keeps that role even when it shows up as a qualified-only row for another item.
        // This fixes the "Fix label on a Fraction machine" display bug.
        java.util.Map<String, String> machineRoleMap = new java.util.HashMap<String, String>();
        for (LoadingPlanRow r : allocatedRows) {
            if (r.getMachineName() == null || "-".equals(r.getMachineName())) { continue; }
            String mk = r.getMachineName().toUpperCase();
            // Fraction role takes precedence — if a machine is Fraction anywhere,
            // treat it as Fraction in qualified rows too
            if (!machineRoleMap.containsKey(mk) || "Fraction".equals(r.getMachineRole())) {
                machineRoleMap.put(mk, r.getMachineRole());
            }
        }

        List<LoadingPlanRow> qualifiedRows = new ArrayList<LoadingPlanRow>();

        for (Item item : saggeredItems) {
            String itemName = item.getItemName();
            if (itemName == null) { continue; }

            String itemKey     = itemName.toUpperCase();
            Precondition pre   = preconditionMap.get(itemKey);
            double capaLpd     = pre != null ? pre.getCapaLotsPerDay()     : 0;
            double convCapa    = pre != null ? pre.getConvCapaLotsPerDay() : 0;

            for (Machine machine : item.getMachines()) {
                if (machine.getMachineName() == null) { continue; }

                // Only show AVAILABLE machines — DISQUALIFIED machines cannot receive lots
                // ipmssys machine usage is AVAILABLE | UNAVAILABLE (IPMSTEST used DISQUALIFIED).
                String usage = machine.getMachineUsage();
                if (usage != null && !"AVAILABLE".equalsIgnoreCase(usage.trim())) { continue; }

                String machineKey = machine.getMachineName().toUpperCase() + "|" + itemKey;

                // Skip if this (machine, item) pair is already an allocated row
                if (allocatedKeys.contains(machineKey)) { continue; }

                // Inherit the machine's real role from the allocation lookup.
                // If the machine has no allocation role (it's only in ITEM_MACHINE
                // but not in MACHINE_ALLOCATION), fall back to "Qualified".
                String role = machineRoleMap.getOrDefault(
                    machine.getMachineName().toUpperCase(), "Qualified"
                );

                LoadingPlanRow row = new LoadingPlanRow();
                row.setMachineRole(role);
                row.setMachineName(machine.getMachineName());
                row.setItemName(itemName);
                row.setGroupCode(item.getGroupCode());
                row.setMachineShare(0);
                row.setMaxCapaLotsPerDay(capaLpd);
                row.setCapaWithConversion((int) Math.floor(convCapa));
                row.setConvCapaLotsPerDay(convCapa);
                row.setMonthTotalLots(0);
                row.setStatus("OK");
                row.setQualifiedOnly(true);

                for (int day = 1; day <= daysInMonth; day++) {
                    row.setDayValue(day, 0);
                }

                qualifiedRows.add(row);
            }
        }

        return qualifiedRows;
    }
    // Formula: (convCapaLotsPerDay / 1440) × (remainingHours × 60)
    // =========================================================================

    private void applyMaintenanceAdjustments(
            List<LoadingPlanRow> rows,
            Map<String, Precondition> preconditionMap,
            Map<String, Map<Integer, MaintenanceDay>> maintenanceMap,
            int daysInMonth, int year, int month) {

        // Apply maintenance cuts and record hours + type per day per row
        for (LoadingPlanRow row : rows) {
            if (row.getMachineName() == null || "-".equals(row.getMachineName())) { continue; }

            Map<Integer, MaintenanceDay> machineDayMaint =
                maintenanceMap.get(row.getMachineName().toUpperCase());
            if (machineDayMaint == null) { continue; }

            String key = row.getItemName().toUpperCase();
            Precondition pre = preconditionMap.get(key);
            double convCapa  = pre != null ? pre.getConvCapaLotsPerDay() : 0;

            for (int day = 1; day <= daysInMonth; day++) {
                MaintenanceDay md = machineDayMaint.get(day);
                if (md == null || md.hours <= 0) { continue; }

                double maintHours = Math.min(md.hours, 24.0);

                double remainingHours = 24.0 - maintHours;
                double adjustedValue  = remainingHours > 0 ? (convCapa / 1440.0) * (remainingHours * 60.0) : 0;

                boolean isAllocated = "Fix".equals(row.getMachineRole()) || "Fraction".equals(row.getMachineRole());

                if (isAllocated) {
                    int originalValue = row.getDayValue(day);
                    int reducedValue  = (int) Math.min(originalValue, Math.floor(adjustedValue));
                    int excess        = originalValue - reducedValue;

                    row.setDayValue(day, reducedValue);

                    if (excess > 0) { row.setExcess(day, excess); }
                }

                // Record hours and type — ALL rows on an affected machine are marked
                // (not just allocated ones) so the JSP can highlight Qualified rows too
                row.setMaintenanceHours(day, maintHours);
                row.setMaintenanceType(day, md.type);
                row.setMaintenancePic(day, md.pic);
            }
        }

        // Phase 4: Redistribute excess to other qualified rows for same item
        for (int day = 1; day <= daysInMonth; day++) {
            for (LoadingPlanRow sourceRow : rows) {
                int excess = sourceRow.getExcess(day);
                if (excess <= 0) { continue; }

                // Track total actually rerouted for the source cell indicator
                int originalExcess = excess;

                String sourceItem    = sourceRow.getItemName().toUpperCase();
                String sourceMachine = sourceRow.getMachineName().toUpperCase();

                List<LoadingPlanRow> targets = new ArrayList<LoadingPlanRow>();

                for (LoadingPlanRow targetRow : rows) {
                    if (targetRow.getMachineName() == null || "-".equals(targetRow.getMachineName())) { continue; }
                    if (!targetRow.getItemName().toUpperCase().equals(sourceItem)) { continue; }
                    if (targetRow.getMachineName().toUpperCase().equals(sourceMachine)) { continue; }
                    targets.add(targetRow);
                }

                // Priority order for receiving excess:
                //   1. Fraction rows for the same item — natural overflow receiver
                //   2. Other Fix rows for the same item
                //   3. Qualified-only rows
                targets.sort((a, b) -> {
                    int ap = "Fraction".equals(a.getMachineRole()) ? 1
                           : "Fix".equals(a.getMachineRole())      ? 2
                           : "Qualified".equals(a.getMachineRole()) ? 3
                           : 4;
                    int bp = "Fraction".equals(b.getMachineRole()) ? 1
                           : "Fix".equals(b.getMachineRole())      ? 2
                           : "Qualified".equals(b.getMachineRole()) ? 3
                           : 4;
                    if (ap != bp) { return ap - bp; }
                    return a.getMachineName().compareTo(b.getMachineName());
                });

                for (LoadingPlanRow targetRow : targets) {
                    if (excess <= 0) { break; }

                    String tKey      = targetRow.getItemName().toUpperCase();
                    Precondition pre  = preconditionMap.get(tKey);
                    double convCapa   = pre != null ? pre.getConvCapaLotsPerDay() : 0;
                    if (convCapa <= 0) { continue; }

                    Map<Integer, MaintenanceDay> tMaint = maintenanceMap.get(targetRow.getMachineName().toUpperCase());
                    MaintenanceDay tMd = (tMaint != null) ? tMaint.get(day) : null;
                    double tMaintHours   = (tMd != null) ? Math.min(tMd.hours, 24.0) : 0;
                    double remainingHours = 24.0 - tMaintHours;
                    if (remainingHours <= 0) { continue; }

                    double availableCapa = (convCapa / 1440.0) * (remainingHours * 60.0);
                    int    currentValue  = targetRow.getDayValue(day);
                    double spareCapacity = availableCapa - currentValue;
                    if (spareCapacity <= 0) { continue; }

                    int absorbed = (int) Math.min(excess, Math.floor(spareCapacity));
                    if (absorbed <= 0) { continue; }

                    targetRow.setDayValue(day, currentValue + absorbed);

                    // Mark this target cell as receiving rerouted lots
                    // Accumulate if multiple source rows send to same target cell
                    targetRow.setReroutedTarget(day, targetRow.getReroutedTarget(day) + absorbed);

                    excess -= absorbed;
                }

                // Mark source cell — record how many lots were successfully rerouted
                int actuallyRerouted = originalExcess - excess;
                if (actuallyRerouted > 0) {
                    sourceRow.setReroutedSource(day, actuallyRerouted);
                }
            }
        }
    }

    // =========================================================================
    // MACHINE BINS
    // =========================================================================

    private List<MachineBin> buildMachineBins(MachineAllocationGroup group) {
        List<MachineBin> bins = new ArrayList<MachineBin>();

        // FIX_REQUIREMENT and FRACTION1_REQUIREMENT on the group drive the allocation.
        // FIX_REQUIREMENT = how much of the item's MC_PER_DAY goes to Fix machines.
        // If FIX_REQUIREMENT = 0, the item is pure-fraction — no Fix bins should be created.
        // We distribute FIX_REQUIREMENT evenly across Fix machines (each gets 1.0 normally).
        // FRACTION1_REQUIREMENT is split across fraction machines by their individual
        // REQUIREMENT_VALUE in MACHINE_ALLOCATION_MACHINE.
        double fixReqRemaining = round2(group.getFixRequirement());

        for (MachineAllocationMachine machine : group.getMachines()) {
            String role = machine.getMachineRole();

            if ("FIX".equalsIgnoreCase(role)) {
                // Each Fix machine gets capacity = min(1.0, remaining fix requirement).
                // If FIX_REQUIREMENT = 0, fixReqRemaining = 0 → no Fix bin created.
                // If FIX_REQUIREMENT = 1.0, first Fix machine gets capacity 1.0.
                // If FIX_REQUIREMENT = 2.0, two Fix machines each get 1.0.
                if (fixReqRemaining <= 0) { continue; }
                double cap = Math.min(1.0, fixReqRemaining);
                bins.add(new MachineBin(machine.getMachineName(), "Fix", cap, cap));
                fixReqRemaining = round2(fixReqRemaining - cap);

            } else if ("FRACTION1".equalsIgnoreCase(role)) {
                double req = machine.getRequirementValue();
                if (req > 0) {
                    bins.add(new MachineBin(machine.getMachineName(), "Fraction", req, req));
                }
            }
        }

        return bins;
    }

    // =========================================================================
    // LOOKUP MAP BUILDERS
    // =========================================================================

    private Map<String, Precondition> buildPreconditionMap(List<Precondition> list) {
        Map<String, Precondition> map = new HashMap<String, Precondition>();
        if (list == null) { return map; }
        for (Precondition p : list) {
            if (p.getItemName() != null) {
                map.put(p.getItemName().toUpperCase(), p);
            }
        }
        return map;
    }

    // maintenanceMap: machineName.toUpper → { dayNumber → MaintenanceDay(hours, type) }
    // Each detail row has its own scheduleDate — no index-based offset needed.
    // If the same machine has two schedules on the same day, hours are summed
    // and the type of the first/dominant one is kept.
    private Map<String, Map<Integer, MaintenanceDay>> buildMaintenanceMap(
            List<PlottingSummary> plottingList, int planMonth, int planYear) {

        Map<String, Map<Integer, MaintenanceDay>> map =
            new HashMap<String, Map<Integer, MaintenanceDay>>();

        if (plottingList == null) { return map; }

        for (PlottingSummary ps : plottingList) {
            String machine = (ps.getStackingMachine() != null) ? ps.getStackingMachine().getMachineName() : null;
            if (machine == null || machine.trim().isEmpty()) { continue; }

            String machineKey = machine.trim().toUpperCase();
            String type       = ps.getType() != null ? ps.getType().trim() : "";
            String pic        = ps.getPic()  != null ? ps.getPic().trim()  : "";

            if (!map.containsKey(machineKey)) {
                map.put(machineKey, new HashMap<Integer, MaintenanceDay>());
            }

            Map<Integer, MaintenanceDay> dayMap = map.get(machineKey);

            // Details are populated by PlottingSummaryDAO.listByMonthYear().
            // Each detail row has its own scheduleDate — use it directly.
            if (ps.getDetails() == null || ps.getDetails().isEmpty()) { continue; }

            for (PlottingSummaryDetail detail : ps.getDetails()) {
                if (detail.getScheduleDate() == null) { continue; }

                LocalDate d = detail.getScheduleDate();

                // Only include days within the target month/year
                if (d.getYear() != planYear || d.getMonthValue() != planMonth) { continue; }

                int    dayNum = d.getDayOfMonth();
                double hours  = detail.getHours();
                if (hours <= 0) { continue; }

                if (dayMap.containsKey(dayNum)) {
                    // Same machine, same day — accumulate hours, keep existing type/pic
                    MaintenanceDay existing = dayMap.get(dayNum);
                    existing.hours += hours;
                } else {
                    dayMap.put(dayNum, new MaintenanceDay(hours, type, pic));
                }
            }
        }

        return map;
    }

    // =========================================================================
    // PHASE 2b — Fraction plot redistribution
    // =========================================================================
    // When a planner configures a LOADING_PLAN_FRACTION_PLOT record, the
    // fraction row's computed base allocation is REPLACED, not extended.
    //
    // What this does:
    //   1. Zeroes ALL day values on this fraction row for the whole month.
    //   2. Redistributes the configured TOTAL_LOTS across the chosen
    //      PLOT_START → PLOT_END date range using the same cumulative
    //      formula as addDailyValues() — giving the same even spread
    //      (e.g. 162 lots over 9 days → 18 18 18 18 18 18 18 18 18).
    //   3. Days outside the chosen range stay at 0, freeing them for
    //      Reassign and Recovery actions in Phase 5.
    //
    // TOTAL_LOTS defaults to the row's base monthTotalLots in the JSP,
    // so the planner is redistributing the same total into a tighter
    // window by default — not adding extra lots.
    //
    // Phase 5 (overrides: reassign, recovery, manual edits) applies on
    // top of these redistributed values exactly as it does on base values.
    // =========================================================================

    private void applyFractionPlots(List<LoadingPlanRow> rows,
                                     List<LoadingPlanFractionPlot> plots,
                                     List<LoadingPlanOverride> overrides,
                                     int planYear, int planMonth, int daysInMonth) {

        // Build a set of (machineName|itemName|dayOfMonth) keys that have
        // existing overrides — these days are skipped during zeroing so the
        // override in Phase 5 lands on the correct computed-before-override value.
        java.util.Set<String> overrideDays = new java.util.HashSet<String>();
        if (overrides != null) {
            for (LoadingPlanOverride ov : overrides) {
                if (ov.getPlanDate() == null) { continue; }
                String key = ov.getMachineName().toUpperCase() + "|"
                           + ov.getItemName().toUpperCase() + "|"
                           + ov.getPlanDate().getDayOfMonth();
                overrideDays.add(key);
            }
        }

        for (LoadingPlanFractionPlot plot : plots) {
            if (plot.getPlotStart() == null || plot.getPlotEnd() == null) { continue; }
            if (plot.getTotalLots() < 0) { continue; }

            java.util.List<Integer> plotDays = new java.util.ArrayList<Integer>();
            for (int d = 1; d <= daysInMonth; d++) {
                java.time.LocalDate day = java.time.LocalDate.of(planYear, planMonth, d);
                if (!day.isBefore(plot.getPlotStart()) && !day.isAfter(plot.getPlotEnd())) {
                    plotDays.add(d);
                }
            }

            if (plotDays.isEmpty()) { continue; }

            for (LoadingPlanRow row : rows) {
                if (!"Fraction".equals(row.getMachineRole())) { continue; }
                if (row.getMachineName() == null || row.getItemName() == null) { continue; }
                if (!row.getMachineName().equalsIgnoreCase(plot.getMachineName())) { continue; }
                if (!row.getItemName().equalsIgnoreCase(plot.getItemName())) { continue; }

                String machineItemPrefix = row.getMachineName().toUpperCase() + "|"
                                         + row.getItemName().toUpperCase() + "|";

                // Step 1 — zero every day, but SKIP days that have an existing override.
                // This prevents the fraction plot from wiping the base value on a day
                // where the planner has a manual edit or reassign target, since Phase 5
                // will write the override value on top regardless. Keeping the original
                // computed value under the override means originalDayValues reflects the
                // correct baseline in the edit dialog ("Original: X → Current: Y").
                for (int d = 1; d <= daysInMonth; d++) {
                    if (overrideDays.contains(machineItemPrefix + d)) { continue; }
                    row.setDayValue(d, 0);
                }

                // Step 2 — distribute totalLots across plotDays, skipping days that
                // have overrides (they'll be filled by Phase 5 anyway)
                if (plot.getTotalLots() > 0) {
                    // Only distribute across days that are NOT overridden
                    java.util.List<Integer> freePlotDays = new java.util.ArrayList<Integer>();
                    for (int dayNum : plotDays) {
                        if (!overrideDays.contains(machineItemPrefix + dayNum)) {
                            freePlotDays.add(dayNum);
                        }
                    }

                    if (!freePlotDays.isEmpty()) {
                        double dailyRate          = (double) plot.getTotalLots() / freePlotDays.size();
                        int    previousCumulative = 0;
                        for (int i = 0; i < freePlotDays.size(); i++) {
                            int dayNum     = freePlotDays.get(i);
                            int cumulative = (int) Math.floor(dailyRate * (i + 1));
                            int dayLots    = cumulative - previousCumulative;
                            row.setDayValue(dayNum, dayLots);
                            previousCumulative = cumulative;
                        }
                    }
                }

                // Step 3 — recompute monthly total
                int total = 0;
                for (int d = 1; d <= daysInMonth; d++) { total += row.getDayValue(d); }
                row.setMonthTotalLots(total);

                break;
            }
        }
    }

    // =========================================================================
    // PHASE 2c & 6b — REMOVED (conversion now matches the Excel)
    // =========================================================================
    // The Excel handles item changeovers on a fraction machine as a CLEAN DAY
    // BOUNDARY: item A runs to its last day, item B starts the FOLLOWING day;
    // the two items never share a day. And "NEEDS CONVERSION" is a MANUAL
    // planner annotation (purple #7030A0 in the Excel), not an auto-detected
    // calculation. IPMSTEST's applyMidDayHandoff (same-day split) and
    // detectConversionDays (auto flagging) were inaccurate to the Excel and have
    // been removed. Manual conversion / status flags are persisted on
    // LOADING_PLAN_OVERRIDE (CELL_STATUS) and applied in Phase 5 (applyOverrides).
    // =========================================================================

    // =========================================================================
    // PHASE 6 — Apply planner-defined item priority sort
    // =========================================================================
    // Sorts the rows list so that for each machine, allocated items appear
    // in the planner's chosen order (from LOADING_PLAN_ITEM_PRIORITY),
    // followed by qualified-only rows (which are always last, unordered).
    // Machines with no priority record keep their original order (role then item name).
    // =========================================================================

    private void applyItemPrioritySort(List<LoadingPlanRow> rows,
                                        List<LoadingPlanItemPriority> priorities) {

        // Build lookup: "MACHINE|ITEM" -> prioritySeq
        final Map<String, Integer> priorityMap = new HashMap<String, Integer>();
        for (LoadingPlanItemPriority p : priorities) {
            String key = p.getMachineName().toUpperCase() + "|" + p.getItemName().toUpperCase();
            priorityMap.put(key, p.getPrioritySeq());
        }

        rows.sort((a, b) -> {
            // First sort by machine name so all rows for a machine stay grouped
            String ma = a.getMachineName() != null ? a.getMachineName().toUpperCase() : "";
            String mb = b.getMachineName() != null ? b.getMachineName().toUpperCase() : "";
            int machineCmp = ma.compareTo(mb);
            if (machineCmp != 0) { return machineCmp; }

            // Qualified-only rows always go after allocated rows
            boolean aq = a.isQualifiedOnly(), bq = b.isQualifiedOnly();
            if (aq != bq) { return aq ? 1 : -1; }

            // Both qualified-only or both allocated — apply priority map
            String keyA = ma + "|" + (a.getItemName() != null ? a.getItemName().toUpperCase() : "");
            String keyB = mb + "|" + (b.getItemName() != null ? b.getItemName().toUpperCase() : "");

            Integer seqA = priorityMap.get(keyA);
            Integer seqB = priorityMap.get(keyB);

            // If both have a priority: use it
            if (seqA != null && seqB != null) { return Integer.compare(seqA, seqB); }
            // If only one has a priority: prioritised item goes first
            if (seqA != null) { return -1; }
            if (seqB != null) { return  1; }
            // Neither has a priority: fall back to item name
            String ia = a.getItemName() != null ? a.getItemName() : "";
            String ib = b.getItemName() != null ? b.getItemName() : "";
            return ia.compareTo(ib);
        });
    }

    // =========================================================================
    // PHASE 5 — Apply user overrides
    // =========================================================================
    // Uses the existing DB schema: OVERRIDE_TYPE ("STANDARD" or "RECOVERY"),
    // REASSIGN_REASON ("MACHINE_TROUBLE","UNPLANNED_MAINTENANCE","OTHER"),
    // RECOVERY_SOURCE_DATE (set on RECOVERY target rows only).
    //
    // Logic per override row:
    //   RECOVERY + RECOVERY_SOURCE_DATE set → target row: green highlight
    //   RECOVERY + RECOVERY_SOURCE_DATE null → source row: pink, value kept
    //   STANDARD + REASSIGN_REASON set → source row: reason colour, value = 0
    //   STANDARD + REASSIGN_REASON null, value normal → reassign target (blue)
    //     OR plain manual edit (amber) — distinguished by whether another row
    //     for the same item has a zero value with a reason on the same date.
    //     Simpler approach: target rows from batch come with value > 0 and no
    //     reason. Source rows come with value = 0 and a reason. Manual edits
    //     come through single-cell endpoint with STANDARD and no reason.
    // =========================================================================

    private void applyOverrides(List<LoadingPlanRow> rows, List<LoadingPlanOverride> overrides) {
        for (LoadingPlanOverride ov : overrides) {
            if (ov.getPlanDate() == null) { continue; }

            int    day         = ov.getPlanDate().getDayOfMonth();
            String type        = ov.getOverrideType() != null ? ov.getOverrideType() : "STANDARD";
            String reason      = ov.getReassignReason();
            String remarks     = ov.getRemarks() != null ? ov.getRemarks() : "";
            boolean hasReason  = reason != null && !reason.trim().isEmpty();
            boolean isRecovery   = "RECOVERY".equals(type);
            boolean isConversion = "CONVERSION".equals(type);  // manually flagged conversion day
            boolean isRecoveryTarget = isRecovery && ov.getRecoverySourceDate() != null;
            boolean isRecoverySource = isRecovery && ov.getRecoverySourceDate() == null;

            // Manual per-cell status (Excel legend). Back-compat: a legacy
            // OVERRIDE_TYPE='CONVERSION' with no explicit status means NEEDS_CONVERSION.
            String cellStatus = ov.getCellStatus();
            if (("NONE".equals(cellStatus) || cellStatus == null) && isConversion) {
                cellStatus = "NEEDS_CONVERSION";
            }

            // A status-only override just carries a manual flag — it must NOT touch the
            // day value. It is a STANDARD override with no reason, no remarks, value 0,
            // but a real status flag set.
            boolean hasStatus  = cellStatus != null && !"NONE".equals(cellStatus);
            boolean statusOnly = hasStatus && !isRecovery && !isConversion
                                 && !hasReason && remarks.isEmpty()
                                 && ov.getOverrideValue() == 0;

            for (LoadingPlanRow row : rows) {
                if (row.getMachineName() == null || row.getItemName() == null) { continue; }
                if (!row.getMachineName().equalsIgnoreCase(ov.getMachineName())) { continue; }
                if (!row.getItemName().equalsIgnoreCase(ov.getItemName())) { continue; }

                // Apply the manual status flag regardless of value/override type.
                row.setCellStatus(day, cellStatus);
                if ("NEEDS_CONVERSION".equals(cellStatus)) {
                    row.setConversionDay(day, true);   // keep the boolean in sync for existing consumers
                }

                // Status-only flag: do not alter the computed value.
                if (statusOnly) { break; }

                if (isConversion) {
                    // Legacy conversion override — apply value if the planner changed it.
                    row.setDayValue(day, (int) Math.floor(ov.getOverrideValue()));
                    row.setOverridden(day, true);
                    if (!remarks.isEmpty()) { row.setRemarks(day, remarks); }

                } else if (isRecoverySource) {
                    // Pink: source value kept, only flag the cell
                    row.setRecoverySource(day, true);
                    if (!remarks.isEmpty()) { row.setRemarks(day, remarks); }

                } else if (isRecoveryTarget) {
                    // Green: extra lots added via conv capa
                    row.setDayValue(day, (int) Math.floor(ov.getOverrideValue()));
                    row.setOverridden(day, true);
                    row.setRecoveryTarget(day, true);
                    if (!remarks.isEmpty()) { row.setRemarks(day, remarks); }

                } else if (hasReason) {
                    // Reassign source: zeroed, reason drives colour
                    row.setDayValue(day, (int) Math.floor(ov.getOverrideValue())); // 0
                    row.setOverridden(day, true);
                    row.setReassignReason(day, reason);
                    if (!remarks.isEmpty()) { row.setRemarks(day, remarks); }

                } else if (ov.getOverrideValue() > 0 || ov.getRemarks() != null) {
                    // Reassign target (value > 0, no reason) OR manual edit
                    // If another override for same item/date has a reason → this is a target (blue)
                    // Otherwise → manual edit (amber)
                    boolean isTarget = false;
                    for (LoadingPlanOverride other : overrides) {
                        if (other == ov) { continue; }
                        if (other.getPlanDate() == null) { continue; }
                        if (other.getPlanDate().getDayOfMonth() != day) { continue; }
                        if (!other.getItemName().equalsIgnoreCase(ov.getItemName())) { continue; }
                        if (other.getReassignReason() != null && !other.getReassignReason().isEmpty()) {
                            isTarget = true; break;
                        }
                    }
                    row.setDayValue(day, (int) Math.floor(ov.getOverrideValue()));
                    row.setOverridden(day, true);
                    if (isTarget) { row.setReassigned(day, true); }
                    if (!remarks.isEmpty()) { row.setRemarks(day, remarks); }

                } else {
                    // Plain zero override (clear)
                    row.setDayValue(day, 0);
                    row.setOverridden(day, true);
                    if (!remarks.isEmpty()) { row.setRemarks(day, remarks); }
                }

                break;
            }
        }
    }

    // =========================================================================
    // ROUNDING
    // =========================================================================

    private double round2(double value) {
        if (Double.isNaN(value) || Double.isInfinite(value)) { return 0.0; }
        return BigDecimal.valueOf(value)
                .setScale(2, RoundingMode.HALF_UP)
                .doubleValue();
    }

    // =========================================================================
    // INNER CLASSES
    // =========================================================================

    // Maintenance data for one machine/day — carries hours, type, and PIC for cell tooltip
    public static class MaintenanceDay {
        public double hours;
        public String type;   // "PM", "Evaluation", "ME Improvement", or ""
        public String pic;    // Person In Charge for this maintenance schedule

        public MaintenanceDay(double hours, String type, String pic) {
            this.hours = hours;
            this.type  = type != null ? type : "";
            this.pic   = pic  != null ? pic  : "";
        }
    }

    // Machine bin — represents one FIX or FRACTION1 machine slot with remaining capacity.
    // Used by buildAllocatedRows() to distribute item requirements across available machines.
    public static class MachineBin {
        public String machineName;
        public String role;           // "Fix" or "Fraction"
        public double capacity;
        public double remaining;

        public MachineBin(String machineName, String role, double capacity, double remaining) {
            this.machineName = machineName;
            this.role        = role;
            this.capacity    = capacity;
            this.remaining   = remaining;
        }
    }
}