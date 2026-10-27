package com.ipmssys.loadingplan.controller;

import java.io.BufferedReader;
import java.io.IOException;
import java.lang.reflect.Type;
import java.sql.Connection;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.ipmssys.configuration.GlobalVariables;
import com.ipmssys.connection.DBConnectionDataSource;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.ipmssys.loadingplan.dao.LoadingPlanOverrideDAO;
import com.ipmssys.loadingplan.model.LoadingPlanOverride;

/**
 * POST /loadingplan/override/batch
 *
 * Saves a batch of overrides from Reassign or Recovery actions in a single
 * transaction. Server-side conflict check runs before the transaction opens —
 * any target day that already has an existing override returns 409 with details.
 * Remarks are required on every entry.
 */
@WebServlet("/loadingplan/override/batch")
public class BatchSaveLoadingPlanOverrideServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // DTO — matches the JSON structure sent from the JSP
    private static class OverrideEntry {
        int    planId;
        String machineName;
        String itemName;
        String planDate;           // "YYYY-MM-DD"
        double value;
        String reassignReason;     // "MACHINE_TROUBLE", "UNPLANNED_MAINTENANCE", "OTHER", or null
        String overrideType;       // "STANDARD" or "RECOVERY"
        String remarks;            // required on all entries
        String recoverySourceDate; // "YYYY-MM-DD" — set on RECOVERY target rows only
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/plain;charset=UTF-8");

        // Read JSON body
        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = request.getReader()) {
            String line;
            while ((line = reader.readLine()) != null) { sb.append(line); }
        }

        String rawJson = sb.toString().trim();
        if (rawJson.isEmpty()) {
            response.setStatus(400);
            response.getWriter().write("No override data received.");
            return;
        }

        List<OverrideEntry> entries;
        try {
            Type listType = new TypeToken<List<OverrideEntry>>(){}.getType();
            entries = new Gson().fromJson(rawJson, listType);
        } catch (Exception e) {
            response.setStatus(400);
            response.getWriter().write("Invalid JSON format.");
            return;
        }

        if (entries == null || entries.isEmpty()) {
            response.setStatus(400);
            response.getWriter().write("No override entries in request.");
            return;
        }

        // Validate all entries up-front — remarks required, dates parseable
        for (int i = 0; i < entries.size(); i++) {
            OverrideEntry entry = entries.get(i);
            if (isBlank(entry.machineName) || isBlank(entry.itemName) || isBlank(entry.planDate)) {
                response.setStatus(400);
                response.getWriter().write("Entry " + i + ": machineName, itemName, and planDate are required.");
                return;
            }
            if (isBlank(entry.remarks)) {
                response.setStatus(400);
                response.getWriter().write("Remarks are required on all entries. "
                    + "Entry for " + entry.machineName + " / " + entry.itemName
                    + " on " + entry.planDate + " has no remark.");
                return;
            }
            try { LocalDate.parse(entry.planDate.trim()); }
            catch (Exception e) {
                response.setStatus(400);
                response.getWriter().write("Entry " + i + ": invalid planDate '" + entry.planDate + "'.");
                return;
            }
        }

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);

        try (Connection con = dbConnection.getConnection()) {

            // ---- Server-side conflict check (read-only, before transaction) ----
            // Groups target entries by machine+item and queries the DB for any
            // that already have a non-zero override value. Catches stale client state.
            LoadingPlanOverrideDAO overrideDAO = new LoadingPlanOverrideDAO(con);

            Map<String, List<LocalDate>> targetsByMachineItem = new HashMap<String, List<LocalDate>>();
            for (OverrideEntry entry : entries) {
                boolean isReassignSource = entry.value == 0 && !isBlank(entry.reassignReason);
                boolean isRecoverySource = "RECOVERY".equals(entry.overrideType)
                                        && isBlank(entry.recoverySourceDate);
                if (isReassignSource || isRecoverySource) { continue; }

                LocalDate pd = LocalDate.parse(entry.planDate.trim()); // already validated above
                String key   = entry.machineName.trim() + "|" + entry.itemName.trim();
                if (!targetsByMachineItem.containsKey(key)) {
                    targetsByMachineItem.put(key, new ArrayList<LocalDate>());
                }
                targetsByMachineItem.get(key).add(pd);
            }

            List<String> allConflicts = new ArrayList<String>();
            int planId = entries.get(0).planId;

            for (Map.Entry<String, List<LocalDate>> e : targetsByMachineItem.entrySet()) {
                String[] parts      = e.getKey().split("\\|", 2);
                String   machine    = parts[0];
                String   item       = parts.length > 1 ? parts[1] : "";
                List<String> occ    = overrideDAO.getOccupiedDates(planId, machine, item, e.getValue());
                for (String date : occ) {
                    allConflicts.add(machine + " / " + item + " on " + date);
                }
            }

            if (!allConflicts.isEmpty()) {
                response.setStatus(409);
                StringBuilder msg = new StringBuilder("Conflict: the following days already have values — ");
                for (int i = 0; i < Math.min(allConflicts.size(), 3); i++) {
                    if (i > 0) { msg.append("; "); }
                    msg.append(allConflicts.get(i));
                }
                if (allConflicts.size() > 3) {
                    msg.append(" and ").append(allConflicts.size() - 3).append(" more.");
                }
                msg.append(" Refresh the Loading Plan and try again.");
                response.getWriter().write(msg.toString());
                return;
            }

            // ---- All clear — save in a single transaction ----
            con.setAutoCommit(false);
            try {
                int saved = 0, skipped = 0;

                for (OverrideEntry entry : entries) {
                    LocalDate planDate = LocalDate.parse(entry.planDate.trim());

                    if (entry.value < 0) {
                        overrideDAO.delete(planId, entry.machineName.trim(),
                            entry.itemName.trim(), planDate);
                        skipped++;
                        continue;
                    }

                    LoadingPlanOverride override = new LoadingPlanOverride(
                        planId,
                        entry.machineName.trim(),
                        entry.itemName.trim(),
                        planDate,
                        entry.value
                    );
                    override.setReassignReason(entry.reassignReason);
                    override.setOverrideType(!isBlank(entry.overrideType) ? entry.overrideType : "STANDARD");
                    override.setRemarks(entry.remarks.trim());

                    if (!isBlank(entry.recoverySourceDate)) {
                        try {
                            override.setRecoverySourceDate(LocalDate.parse(entry.recoverySourceDate.trim()));
                        } catch (Exception ignored) {
                            log("BatchSaveLoadingPlanOverrideServlet: unparseable recoverySourceDate '"
                                + entry.recoverySourceDate + "' on entry for "
                                + entry.machineName + "/" + entry.itemName
                                + "/" + entry.planDate + " — ignored", null);
                        }
                    }

                    overrideDAO.upsert(override);
                    saved++;
                }

                con.commit();
                response.setStatus(200);
                response.getWriter().write(saved + " override(s) saved."
                    + (skipped > 0 ? " " + skipped + " cleared." : ""));

            } catch (Exception e) {
                try { con.rollback(); }
                catch (Exception rb) { log("Rollback failed in BatchSaveLoadingPlanOverrideServlet", rb); }
                throw e;
            } finally {
                try { con.setAutoCommit(true); } catch (Exception ignored) {}
            }

        } catch (Exception e) {
            log("BatchSaveLoadingPlanOverrideServlet.doPost error — planId="
                + (entries != null && !entries.isEmpty() ? entries.get(0).planId : "?"), e);
            response.setStatus(500);
            response.getWriter().write("Server error while saving overrides: " + e.getMessage());
        }
    }

    private boolean isBlank(String value) { return value == null || value.trim().isEmpty(); }
}