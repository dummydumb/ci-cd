package com.ipmssys.plottingsummary.controller;

import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.http.HttpServletRequest;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.ipmssys.item.model.Item;
import com.ipmssys.machine.model.Machine;
import com.ipmssys.machinetype.model.MachineType;
import com.ipmssys.plottingsummary.model.PlottingSummary;
import com.ipmssys.plottingsummary.model.PlottingSummaryDetail;

/**
 * Parses and validates the plotting-summary request (header fields + a JSON
 * array of per-day detail rows), shared by the create and update servlets.
 *
 * Expected parameters:
 *   evaluation, category, type, itemtype, plan, wostype, pic   (text, optional)
 *   itemid            int  (required, FK to ITEM)
 *   machinetypeid     int  (required, FK to MACHINE_TYPE)
 *   stackingmachineid int  (optional, FK to MACHINE; blank = none)
 *   nooflots          int  >= 0
 *   datepreferred     "YYYY-MM-DD" (required)
 *   confirmeddate     "YYYY-MM-DD" (optional)
 *   details           JSON array: [{"scheduleDate":"YYYY-MM-DD","hours":8}, ...]
 */
class PlottingForm {

    PlottingSummary plotting;
    List<PlottingSummaryDetail> details = new ArrayList<>();
    private String error;

    static PlottingForm from(HttpServletRequest request) {
        PlottingForm form = new PlottingForm();
        PlottingSummary ps = new PlottingSummary();

        ps.setEvaluation(trimToNull(request.getParameter("evaluation")));
        ps.setCategory(trimToNull(request.getParameter("category")));
        ps.setType(trimToNull(request.getParameter("type")));
        ps.setItemType(trimToNull(request.getParameter("itemtype")));
        ps.setPlan(trimToNull(request.getParameter("plan")));
        ps.setWosType(trimToNull(request.getParameter("wostype")));
        ps.setPic(trimToNull(request.getParameter("pic")));

        Integer itemId = parseInt(request.getParameter("itemid"));
        Integer typeId = parseInt(request.getParameter("machinetypeid"));
        Integer stackId = parseInt(request.getParameter("stackingmachineid"));
        Integer noOfLots = parseInt(request.getParameter("nooflots"));
        LocalDate pref = parseDate(request.getParameter("datepreferred"));
        LocalDate conf = parseDate(request.getParameter("confirmeddate"));

        if (itemId != null) {
            Item item = new Item();
            item.setItemId(itemId);
            ps.setItem(item);
        }
        if (typeId != null) {
            MachineType mt = new MachineType();
            mt.setMachineTypeId(typeId);
            ps.setMachineType(mt);
        }
        if (stackId != null) {
            Machine sm = new Machine();
            sm.setMachineId(stackId);
            ps.setStackingMachine(sm);
        }
        ps.setNoOfLots(noOfLots != null ? noOfLots : 0);
        ps.setDatePreferred(pref);
        ps.setConfirmedDate(conf);

        form.plotting = ps;
        form.details = parseDetails(request.getParameter("details"));

        // Validation
        if (itemId == null) {
            form.error = "Please select an item.";
        } else if (ps.getCategory() == null) {
            form.error = "Please select a category.";
        } else if (ps.getType() == null) {
            form.error = "Please select a type.";
        } else if (typeId == null) {
            form.error = "Please select a machine type.";
        } else if (noOfLots != null && noOfLots < 0) {
            form.error = "Number of lots cannot be negative.";
        } else if (pref == null) {
            form.error = "Please select a preferred date.";
        } else {
            form.error = validateDetails(form.details);
        }
        return form;
    }

    String getError() {
        return error;
    }

    double totalHours() {
        double sum = 0;
        for (PlottingSummaryDetail d : details) {
            sum += d.getHours();
        }
        return sum;
    }

    private static String validateDetails(List<PlottingSummaryDetail> details) {
        for (PlottingSummaryDetail d : details) {
            if (d.getScheduleDate() == null) {
                return "Each schedule row needs a valid date.";
            }
            if (d.getHours() < 0 || d.getHours() > 24) {
                return "Hours on " + d.getScheduleDate() + " must be between 0 and 24.";
            }
        }
        return null;
    }

    private static List<PlottingSummaryDetail> parseDetails(String json) {
        List<PlottingSummaryDetail> list = new ArrayList<>();
        if (json == null || json.trim().isEmpty()) {
            return list;
        }
        try {
            JsonElement root = JsonParser.parseString(json);
            if (!root.isJsonArray()) {
                return list;
            }
            JsonArray arr = root.getAsJsonArray();
            for (JsonElement el : arr) {
                JsonObject o = el.getAsJsonObject();
                LocalDate date = parseDate(o.has("scheduleDate") && !o.get("scheduleDate").isJsonNull()
                        ? o.get("scheduleDate").getAsString() : null);
                double hours = o.has("hours") && !o.get("hours").isJsonNull()
                        ? o.get("hours").getAsDouble() : 0;
                list.add(new PlottingSummaryDetail(null, date, hours));
            }
        } catch (Exception ignored) {
            // malformed detail payload -> treated as empty; validation flags the empty/invalid rows
        }
        return list;
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
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        try {
            return Integer.valueOf(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String t = value.trim();
        return t.isEmpty() ? null : t;
    }

    // Kept for symmetry if a caller wants a configured Gson later.
    static Gson gson() {
        return new Gson();
    }
}
