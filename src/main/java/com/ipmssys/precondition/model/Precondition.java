package com.ipmssys.precondition.model;

import java.io.Serializable;

/**
 * Computed precondition result for one item — derived from a PreconditionRaw
 * row plus the MonthlyPlan constants. Not stored; produced on the fly by
 * PreconditionService. Field comments record each derivation step.
 */
public class Precondition implements Serializable {

    private static final long serialVersionUID = 1L;

    // Source (carried from PreconditionRaw)
    private String itemName;
    private String capCode;
    private int internalSheet;
    private int dummySheet;
    private int blkPerLot;
    private double kpcsPerLot;
    private double secPerSht;
    private int lotsPerBatch;
    private int lotsPerMonth;

    // Step 1 — sheet totals
    private int ttlSheet;       // internalSheet + dummySheet
    private int shtPerLot;      // ttlSheet * blkPerLot

    // Step 2 — time
    private double minPerBlk;   // (secPerSht/60) * ttlSheet          [roundUp]
    private double minPerLot;   // minPerBlk * blkPerLot               [roundUp]

    // Step 3 — standard efficiency (plan)
    private double minsPerKsht; // (secPerSht/60 * 1000) / efficiency  [round]

    // Step 4 — converted efficiency (raw.eff)
    private int convPreconEff;              // raw.eff * 100
    private double convPreconMinsPerKsht;   // (secPerSht/60 * 1000) / raw.eff [roundUp]

    // Step 5 — daily capacity (standard)
    private int capaShtPerDay;      // (productionTime / minsPerKsht) * 1000
    private double capaLotsPerDay;  // capaShtPerDay / shtPerLot          [roundUp]

    // Step 6 — daily capacity (converted efficiency) -> convCapa
    private int convCapaShtPerDay;      // (productionTime / convPreconMinsPerKsht) * 1000
    private double convCapaLotsPerDay;  // convCapaShtPerDay / shtPerLot  [roundUp]

    // Step 7 — monthly / daily output
    private double mpcsPerMonth;    // lotsPerMonth * (kpcsPerLot/1000)   [round]
    private double mpcsPerDay;      // mpcsPerMonth / workingDays         [roundUp]

    // Step 8 — input plan
    private double inputPlanLotsPerDay;     // lotsPerMonth / workingDays [roundUp]

    // Step 9 — machine requirement
    private double mcReqtMcPerMos;  // inputPlanLotsPerDay / capaLotsPerDay [round]

    public Precondition() {
    }

    public String getItemName() { return itemName; }
    public void setItemName(String itemName) { this.itemName = itemName; }

    public String getCapCode() { return capCode; }
    public void setCapCode(String capCode) { this.capCode = capCode; }

    public int getInternalSheet() { return internalSheet; }
    public void setInternalSheet(int internalSheet) { this.internalSheet = internalSheet; }

    public int getDummySheet() { return dummySheet; }
    public void setDummySheet(int dummySheet) { this.dummySheet = dummySheet; }

    public int getBlkPerLot() { return blkPerLot; }
    public void setBlkPerLot(int blkPerLot) { this.blkPerLot = blkPerLot; }

    public double getKpcsPerLot() { return kpcsPerLot; }
    public void setKpcsPerLot(double kpcsPerLot) { this.kpcsPerLot = kpcsPerLot; }

    public double getSecPerSht() { return secPerSht; }
    public void setSecPerSht(double secPerSht) { this.secPerSht = secPerSht; }

    public int getLotsPerBatch() { return lotsPerBatch; }
    public void setLotsPerBatch(int lotsPerBatch) { this.lotsPerBatch = lotsPerBatch; }

    public int getLotsPerMonth() { return lotsPerMonth; }
    public void setLotsPerMonth(int lotsPerMonth) { this.lotsPerMonth = lotsPerMonth; }

    public int getTtlSheet() { return ttlSheet; }
    public void setTtlSheet(int ttlSheet) { this.ttlSheet = ttlSheet; }

    public int getShtPerLot() { return shtPerLot; }
    public void setShtPerLot(int shtPerLot) { this.shtPerLot = shtPerLot; }

    public double getMinPerBlk() { return minPerBlk; }
    public void setMinPerBlk(double minPerBlk) { this.minPerBlk = minPerBlk; }

    public double getMinPerLot() { return minPerLot; }
    public void setMinPerLot(double minPerLot) { this.minPerLot = minPerLot; }

    public double getMinsPerKsht() { return minsPerKsht; }
    public void setMinsPerKsht(double minsPerKsht) { this.minsPerKsht = minsPerKsht; }

    public int getConvPreconEff() { return convPreconEff; }
    public void setConvPreconEff(int convPreconEff) { this.convPreconEff = convPreconEff; }

    public double getConvPreconMinsPerKsht() { return convPreconMinsPerKsht; }
    public void setConvPreconMinsPerKsht(double v) { this.convPreconMinsPerKsht = v; }

    public int getCapaShtPerDay() { return capaShtPerDay; }
    public void setCapaShtPerDay(int capaShtPerDay) { this.capaShtPerDay = capaShtPerDay; }

    public double getCapaLotsPerDay() { return capaLotsPerDay; }
    public void setCapaLotsPerDay(double capaLotsPerDay) { this.capaLotsPerDay = capaLotsPerDay; }

    public int getConvCapaShtPerDay() { return convCapaShtPerDay; }
    public void setConvCapaShtPerDay(int convCapaShtPerDay) { this.convCapaShtPerDay = convCapaShtPerDay; }

    public double getConvCapaLotsPerDay() { return convCapaLotsPerDay; }
    public void setConvCapaLotsPerDay(double v) { this.convCapaLotsPerDay = v; }

    public double getMpcsPerMonth() { return mpcsPerMonth; }
    public void setMpcsPerMonth(double mpcsPerMonth) { this.mpcsPerMonth = mpcsPerMonth; }

    public double getMpcsPerDay() { return mpcsPerDay; }
    public void setMpcsPerDay(double mpcsPerDay) { this.mpcsPerDay = mpcsPerDay; }

    public double getInputPlanLotsPerDay() { return inputPlanLotsPerDay; }
    public void setInputPlanLotsPerDay(double v) { this.inputPlanLotsPerDay = v; }

    public double getMcReqtMcPerMos() { return mcReqtMcPerMos; }
    public void setMcReqtMcPerMos(double mcReqtMcPerMos) { this.mcReqtMcPerMos = mcReqtMcPerMos; }
}
