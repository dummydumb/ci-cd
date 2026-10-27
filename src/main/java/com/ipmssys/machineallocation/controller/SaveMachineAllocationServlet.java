package com.ipmssys.machineallocation.controller;

import java.io.BufferedReader;
import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.gson.Gson;
import com.ipmssys.configuration.GlobalVariables;
import com.ipmssys.connection.DBConnectionDataSource;
import com.ipmssys.machineallocation.dao.MachineAllocationDAO;
import com.ipmssys.machineallocation.model.MachineAllocation;
import com.ipmssys.machineallocation.model.MachineAllocationGroup;
import com.ipmssys.machineallocation.model.MachineAllocationMachine;

/**
 * Saves (upserts) the machine allocation for a plan. The JSP posts the whole
 * allocation tree as JSON. Server-side validation mirrors the client rules:
 *   - FIX machine count per group == round(fixRequirement)
 *   - no machine used twice as FIX within/across groups; totalFix <= fixLimit
 *   - FRACTION shares per group sum to fraction1Requirement
 *   - no machine used as both FIX and FRACTION; per-machine fraction total <= 1.0
 *
 * Response: 200 on success, 400/500 + plain message on failure.
 */
@WebServlet("/machineallocation/n")
public class SaveMachineAllocationServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/plain;charset=UTF-8");

        String rawJson = readBody(request);
        if (isBlank(rawJson)) {
            response.setStatus(400);
            response.getWriter().write("No allocation data received.");
            return;
        }

        MachineAllocation allocation;
        try {
            allocation = new Gson().fromJson(rawJson, MachineAllocation.class);
        } catch (Exception e) {
            response.setStatus(400);
            response.getWriter().write("Invalid JSON format.");
            return;
        }

        if (allocation == null || allocation.getPlanId() <= 0) {
            response.setStatus(400);
            response.getWriter().write("planId is required.");
            return;
        }
        if (allocation.getGroups() == null || allocation.getGroups().isEmpty()) {
            response.setStatus(400);
            response.getWriter().write("No allocation groups to save.");
            return;
        }

        int fixLimit = allocation.getFixLimit() <= 0 ? 30 : allocation.getFixLimit();

        String validationError = validateGroups(allocation.getGroups(), fixLimit);
        if (!isBlank(validationError)) {
            response.setStatus(400);
            response.getWriter().write(validationError);
            return;
        }

        String message;
        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {
            con.setAutoCommit(false);
            try {
                new MachineAllocationDAO(con).save(allocation);
                con.commit();
                message = "Machine allocation was saved successfully.";
                response.setStatus(200);
            } catch (SQLException e) {
                con.rollback();
                throw e;
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(500);
            message = "Error saving machine allocation: " + e.getMessage();
        }

        response.getWriter().write(message);
    }

    // ------------------------------------------------------------------ //
    //  Validation — mirrors the client validateFinalAllocation()
    // ------------------------------------------------------------------ //

    private String validateGroups(List<MachineAllocationGroup> groups, int fixLimit) {
        int             totalFix        = 0;
        Set<String>     globalFixSet    = new HashSet<>();
        Map<String, Double> fractionLoadMap = new HashMap<>();

        for (int i = 0; i < groups.size(); i++) {
            MachineAllocationGroup group = groups.get(i);

            if (group.getItems() == null || group.getItems().isEmpty()) {
                return buildGroupLabel(group, i) + ": this group has no items.";
            }

            int fixReqCount  = (int) Math.round(group.getFixRequirement());
            int fixMachCount = 0;
            if (group.getFixMachineKeys() != null) {
                for (String k : group.getFixMachineKeys()) {
                    if (k != null && !k.trim().isEmpty()) { fixMachCount++; }
                }
            }
            if (fixReqCount > 0 && fixMachCount != fixReqCount) {
                return buildGroupLabel(group, i)
                     + ": needs " + fixReqCount + " FIX machine(s) but " + fixMachCount
                     + " are assigned. Please assign exactly " + fixReqCount + " FIX machine(s).";
            }

            Set<String> groupFixSet = new HashSet<>();
            if (group.getFixMachineKeys() != null) {
                for (String machineKey : group.getFixMachineKeys()) {
                    String key = safe(machineKey).trim();
                    if (key.isEmpty()) { continue; }
                    totalFix++;
                    if (groupFixSet.contains(key)) {
                        return buildGroupLabel(group, i) + ": Machine " + key
                             + " is selected more than once as FIX — each FIX slot must use a different machine.";
                    }
                    groupFixSet.add(key);
                    if (globalFixSet.contains(key)) {
                        return "Machine " + key
                             + " is already assigned as FIX to another group — a FIX machine can only be used in one group.";
                    }
                    globalFixSet.add(key);
                }
            }
        }

        if (totalFix > fixLimit) {
            return "Too many FIX machines selected overall: " + totalFix
                 + " used, but only " + fixLimit + " are allowed.";
        }

        for (int gi = 0; gi < groups.size(); gi++) {
            MachineAllocationGroup group = groups.get(gi);
            if (group.getMachines() == null) { continue; }

            double totalFracShare = 0;
            Set<String> seenFracMachines = new HashSet<>();

            for (MachineAllocationMachine machine : group.getMachines()) {
                if (!"FRACTION1".equalsIgnoreCase(machine.getMachineRole())) { continue; }

                String fractionKey = safe(machine.getMachineName()).trim();
                if (fractionKey.isEmpty()) { continue; }

                if (globalFixSet.contains(fractionKey)) {
                    return "Machine " + fractionKey + " is selected as both FIX and FRACTION — "
                         + "choose a different machine for one of these roles.";
                }
                if (seenFracMachines.contains(fractionKey)) {
                    return buildGroupLabel(group, gi) + ": Machine " + fractionKey
                         + " is assigned more than once as FRACTION — each fraction slot must use a different machine.";
                }
                seenFracMachines.add(fractionKey);

                totalFracShare += machine.getRequirementValue();

                double current = fractionLoadMap.containsKey(fractionKey) ? fractionLoadMap.get(fractionKey) : 0;
                fractionLoadMap.put(fractionKey, current + machine.getRequirementValue());
            }

            double frac1Req = group.getFraction1Requirement();
            if (frac1Req > 0 && Math.abs(totalFracShare - frac1Req) > 0.001) {
                return buildGroupLabel(group, gi) + ": FRACTION shares must sum to "
                     + String.format("%.2f", frac1Req) + " — current total is "
                     + String.format("%.2f", totalFracShare) + ".";
            }
        }

        for (Map.Entry<String, Double> entry : fractionLoadMap.entrySet()) {
            if (entry.getValue() > 1.000001) {
                return "Machine " + entry.getKey() + " is overloaded as FRACTION: total share "
                     + String.format("%.2f", entry.getValue())
                     + " exceeds the maximum of 1.00 — reduce the FRACTION share in one of its groups.";
            }
        }

        return "";
    }

    private String buildGroupLabel(MachineAllocationGroup group, int index) {
        StringBuilder sb = new StringBuilder();
        String groupCode = safe(group.getGroupCode()).trim();
        String material  = safe(group.getMaterialCode()).trim();

        if (!groupCode.isEmpty() && !"NO_GROUP".equalsIgnoreCase(groupCode)) {
            sb.append("Group ").append(groupCode);
        }
        if (!material.isEmpty() && !"NO_MATERIAL".equalsIgnoreCase(material)) {
            if (sb.length() > 0) { sb.append(" — "); }
            sb.append("Material ").append(material);
        }
        if (sb.length() == 0) {
            sb.append("Group ").append(index + 1);
        }
        if (group.getItems() != null && !group.getItems().isEmpty()) {
            sb.append(" (Items: ");
            for (int i = 0; i < group.getItems().size(); i++) {
                if (i > 0) { sb.append(", "); }
                sb.append(group.getItems().get(i).getItemName());
            }
            sb.append(")");
        }
        return sb.toString();
    }

    // ------------------------------------------------------------------ //
    //  Helpers
    // ------------------------------------------------------------------ //

    private String readBody(HttpServletRequest request) throws IOException {
        String paramData = request.getParameter("allocationData");
        if (!isBlank(paramData)) { return paramData; }
        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = request.getReader()) {
            String line;
            while ((line = reader.readLine()) != null) { sb.append(line); }
        }
        return sb.toString().trim();
    }

    private boolean isBlank(String value) { return value == null || value.trim().isEmpty(); }

    private String safe(String value) { return value == null ? "" : value; }
}
