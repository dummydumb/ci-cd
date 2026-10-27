package com.ipmssys.precondition.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Collections;

import com.ipmssys.monthlyplan.model.MonthlyPlan;
import com.ipmssys.precondition.model.Precondition;
import com.ipmssys.preconditionraw.model.PreconditionRaw;

/**
 * Derives all Precondition fields from the raw inputs plus the MonthlyPlan
 * constants (production time, efficiency, working days). Pure computation —
 * no DB access, nothing stored. This is the capacity engine the downstream
 * stages (allocation, loading plan) consume via convCapa and mcReqt.
 */
public class PreconditionService {

    /** Standard rounding — HALF_UP to 2 dp (2.735 -> 2.74). */
    private double round(double value) {
        if (Double.isNaN(value) || Double.isInfinite(value)) {
            return 0.0;
        }
        return BigDecimal.valueOf(value).setScale(2, RoundingMode.HALF_UP).doubleValue();
    }

    /** Ceiling rounding — always up to 2 dp (2.731 -> 2.74). */
    private double roundUp(double value) {
        if (Double.isNaN(value) || Double.isInfinite(value)) {
            return 0.0;
        }
        return BigDecimal.valueOf(value).setScale(2, RoundingMode.CEILING).doubleValue();
    }

    /**
     * Compute the derived precondition rows for a plan's raw inputs.
     * workingDays uses the plan's value when valid (> 0 and within the month),
     * otherwise the plan month's calendar day count.
     */
    public List<Precondition> compute(List<PreconditionRaw> rawList, MonthlyPlan plan) {
        return compute(rawList, plan, Collections.<String, Integer>emptyMap());
    }

    /**
     * Same as compute(rawList, plan) but the monthly INPUT PLAN lots per item
     * are taken from the saggered total (Excel "Saggering plan (lots/month)")
     * when present in saggeredLotsByItem (key = UPPER item name), falling back to
     * the raw lots/month otherwise. This drives inputPlanLotsPerDay and MC REQT.
     */
    public List<Precondition> compute(List<PreconditionRaw> rawList, MonthlyPlan plan,
            Map<String, Integer> saggeredLotsByItem) {
        List<Precondition> results = new ArrayList<>();
        if (rawList == null || rawList.isEmpty() || plan == null) {
            return results;
        }
        Map<String, Integer> saggeredLots = (saggeredLotsByItem != null)
                ? saggeredLotsByItem : Collections.<String, Integer>emptyMap();

        double productionTime = plan.getProductionTime() != null ? plan.getProductionTime() : 0;

        int calendarDays = plan.getPlanMonth() != null ? plan.getPlanMonth().lengthOfMonth() : 30;
        Integer planWorking = plan.getWorkingDays();
        int workingDays = (planWorking != null && planWorking > 0 && planWorking <= calendarDays)
                ? planWorking
                : calendarDays;

        double efficiency = (plan.getEfficiency() != null ? plan.getEfficiency() : 0) / 100.0;

        for (PreconditionRaw raw : rawList) {
            Precondition p = new Precondition();

            // ---- Carry source fields ----
            p.setItemName(raw.getItem() != null ? raw.getItem().getItemName() : null);
            p.setCapCode(raw.getCapCode());
            p.setInternalSheet(raw.getInternalSheet());
            p.setDummySheet(raw.getDummySheet());
            p.setBlkPerLot(raw.getBlkPerLot());
            p.setKpcsPerLot(raw.getKpcsPerLot());
            p.setSecPerSht(raw.getSecPerSht());
            p.setLotsPerBatch(raw.getLotsPerBatch());

            int internalSheet = raw.getInternalSheet();
            int dummySheet = raw.getDummySheet();
            int blkPerLot = raw.getBlkPerLot();
            double kpcsPerLot = raw.getKpcsPerLot();
            double secPerSht = raw.getSecPerSht();
            double rawEff = raw.getEff();          // decimal: 0.85
            // INPUT PLAN source: prefer the saggered monthly total (Excel W col
            // from the Saggering Plan); fall back to the raw lots/month.
            String preItemName = (raw.getItem() != null && raw.getItem().getItemName() != null)
                    ? raw.getItem().getItemName().trim().toUpperCase() : null;
            int lotsPerMonth = (preItemName != null && saggeredLots.containsKey(preItemName))
                    ? saggeredLots.get(preItemName)
                    : raw.getLotsPerMonth();
            p.setLotsPerMonth(lotsPerMonth);

            // ---- Step 1: Sheet totals ----
            int ttlSheet = internalSheet + dummySheet;
            int shtPerLot = ttlSheet * blkPerLot;
            p.setTtlSheet(ttlSheet);
            p.setShtPerLot(shtPerLot);

            // ---- Step 2: Time ----
            // minPerBlk / minPerLot are display-only; keep the rounded form.
            double minPerBlk = roundUp((secPerSht / 60.0) * ttlSheet);
            double minPerLot = roundUp(minPerBlk * blkPerLot);
            p.setMinPerBlk(minPerBlk);
            p.setMinPerLot(minPerLot);

            // ---- Accuracy note ----
            // To match the Excel tool exactly, the chain that feeds the pipeline
            // (capaLotsPerDay, convCapaLotsPerDay, inputPlanLotsPerDay, mcReqt)
            // is computed at FULL double precision with NO intermediate rounding.
            // Only the integer sheet/day display fields are rounded (for the UI),
            // and they are not consumed downstream. This is the one place ipmssys
            // intentionally diverges from IPMSTEST, which rounded intermediates.

            // ---- Step 3: Standard efficiency (from plan) ----
            double minsPerKsht = (efficiency != 0)
                    ? ((secPerSht / 60.0) * 1000.0) / efficiency : 0;   // full precision
            p.setMinsPerKsht(minsPerKsht);

            // ---- Step 4: Converted efficiency (from raw.eff) ----
            int convPreconEff = (int) Math.round(rawEff * 100);
            double convPreconMinsPerKsht = (rawEff != 0)
                    ? ((secPerSht / 60.0) * 1000.0) / rawEff : 0;        // full precision
            p.setConvPreconEff(convPreconEff);
            p.setConvPreconMinsPerKsht(convPreconMinsPerKsht);

            // ---- Step 5: Daily capacity (standard) ----
            double capaShtPerDayPrecise = (minsPerKsht != 0)
                    ? (productionTime / minsPerKsht) * 1000.0 : 0;       // decimal (Excel Q)
            double capaLotsPerDay = (shtPerLot != 0)
                    ? capaShtPerDayPrecise / shtPerLot : 0;              // decimal (Excel R)
            p.setCapaShtPerDay((int) Math.round(capaShtPerDayPrecise));  // display only
            p.setCapaLotsPerDay(capaLotsPerDay);                         // full precision -> loading plan

            // ---- Step 6: Daily capacity (converted efficiency) -> convCapa ----
            double convCapaShtPerDayPrecise = (convPreconMinsPerKsht != 0)
                    ? (productionTime / convPreconMinsPerKsht) * 1000.0 : 0;  // decimal (Excel S)
            double convCapaLotsPerDay = (shtPerLot != 0)
                    ? convCapaShtPerDayPrecise / shtPerLot : 0;          // decimal (Excel T)
            p.setConvCapaShtPerDay((int) Math.round(convCapaShtPerDayPrecise));  // display only
            p.setConvCapaLotsPerDay(convCapaLotsPerDay);                // full precision -> loading plan

            // ---- Step 7: Monthly / daily output (display) ----
            double mpcsPerMonth = round(lotsPerMonth * (kpcsPerLot / 1000.0));
            double mpcsPerDay = (workingDays != 0) ? roundUp(mpcsPerMonth / workingDays) : 0;
            p.setMpcsPerMonth(mpcsPerMonth);
            p.setMpcsPerDay(mpcsPerDay);

            // ---- Step 8: Input plan (full precision -> mc reqt) ----
            double inputPlanLotsPerDay = (workingDays != 0)
                    ? (double) lotsPerMonth / workingDays : 0;           // Excel X
            p.setInputPlanLotsPerDay(inputPlanLotsPerDay);

            // ---- Step 9: Machine requirement (full precision -> allocation) ----
            double mcReqt = (capaLotsPerDay != 0)
                    ? inputPlanLotsPerDay / capaLotsPerDay : 0;          // Excel Y
            p.setMcReqtMcPerMos(mcReqt);

            results.add(p);
        }

        return results;
    }
}
