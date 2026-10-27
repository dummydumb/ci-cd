package com.ipmssys.preconditionraw.controller;

import javax.servlet.http.HttpServletRequest;

import com.ipmssys.item.model.Item;
import com.ipmssys.preconditionraw.model.PreconditionRaw;

/**
 * Parses and validates the precondition-raw request, shared by create/update.
 *
 * Parameters:
 *   planid, itemid          int (required)
 *   capcode                 text
 *   lotsperbatch, internalsheet, dummysheet, blkperlot, lotspermonth  int >= 0
 *   kpcsperlot, secpersht   double >= 0
 *   eff                     percent 0..100 (stored as decimal: 85 -> 0.85)
 */
class RawForm {

    PreconditionRaw raw;
    private String error;

    static RawForm from(HttpServletRequest request) {
        RawForm form = new RawForm();
        PreconditionRaw pr = new PreconditionRaw();

        Integer planId = parseInt(request.getParameter("planid"));
        Integer itemId = parseInt(request.getParameter("itemid"));

        pr.setPlanId(planId);
        if (itemId != null) {
            Item item = new Item();
            item.setItemId(itemId);
            pr.setItem(item);
        }
        pr.setCapCode(trimToNull(request.getParameter("capcode")));
        pr.setLotsPerBatch(parseIntOr0(request.getParameter("lotsperbatch")));
        pr.setInternalSheet(parseIntOr0(request.getParameter("internalsheet")));
        pr.setDummySheet(parseIntOr0(request.getParameter("dummysheet")));
        pr.setBlkPerLot(parseIntOr0(request.getParameter("blkperlot")));
        pr.setKpcsPerLot(parseDoubleOr0(request.getParameter("kpcsperlot")));
        pr.setSecPerSht(parseDoubleOr0(request.getParameter("secpersht")));
        pr.setLotsPerMonth(parseIntOr0(request.getParameter("lotspermonth")));

        // eff entered as a percent (0..100), stored as a decimal.
        Double effPercent = parseDouble(request.getParameter("eff"));
        if (effPercent != null) {
            pr.setEff(effPercent / 100.0);
        }

        form.raw = pr;

        if (planId == null) {
            form.error = "Missing plan reference.";
        } else if (itemId == null) {
            form.error = "Please select an item.";
        } else if (effPercent == null || effPercent < 0 || effPercent > 100) {
            form.error = "Efficiency must be between 0 and 100.";
        } else if (hasNegative(pr)) {
            form.error = "Numeric values cannot be negative.";
        }
        return form;
    }

    String getError() {
        return error;
    }

    private static boolean hasNegative(PreconditionRaw pr) {
        return pr.getLotsPerBatch() < 0 || pr.getInternalSheet() < 0 || pr.getDummySheet() < 0
                || pr.getBlkPerLot() < 0 || pr.getKpcsPerLot() < 0 || pr.getSecPerSht() < 0
                || pr.getLotsPerMonth() < 0;
    }

    private static Integer parseInt(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        try {
            return Integer.valueOf(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static int parseIntOr0(String value) {
        Integer v = parseInt(value);
        return v != null ? v : 0;
    }

    private static Double parseDouble(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        try {
            return Double.valueOf(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static double parseDoubleOr0(String value) {
        Double v = parseDouble(value);
        return v != null ? v : 0;
    }

    private static String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String t = value.trim();
        return t.isEmpty() ? null : t;
    }
}
