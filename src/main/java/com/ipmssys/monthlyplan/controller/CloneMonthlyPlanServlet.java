package com.ipmssys.monthlyplan.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.ipmssys.configuration.GlobalVariables;
import com.ipmssys.connection.DBConnectionDataSource;
import com.ipmssys.monthlyplan.dao.MonthlyPlanDAO;
import com.ipmssys.monthlyplan.model.MonthlyPlan;
import com.ipmssys.preconditionraw.dao.PreconditionRawDAO;
import com.ipmssys.preconditionraw.model.PreconditionRaw;
import com.ipmssys.saggering.dao.SaggeringDAO;
import com.ipmssys.saggering.model.Saggering;
import com.ipmssys.saggering.model.SaggeringDay;
import com.ipmssys.saggering.model.SaggeringItem;

/**
 * Clone a monthly plan's INPUTS into a new month.
 *
 * Carries forward (inputs only — the Excel's "start from last month" habit):
 *   - the plan header (same machine type, production time, efficiency,
 *     working days, available machines; status reset to DRAFT)
 *   - Precondition Raw rows (per-item raw inputs)
 *   - the Saggering pattern (items + per-day batch values), with each day's
 *     date shifted to the SAME day-of-month in the target month
 *
 * Machine Allocation and the Loading Plan are intentionally NOT copied — they
 * are recomputed fresh from the carried-forward inputs, so last month's
 * one-off machine assignments and manual cell edits never leak into the new
 * plan.
 *
 * POST params:
 *   sourcePlanId   (required) — the plan to clone from
 *   targetMonth    (required) — YYYY-MM or YYYY-MM-01 for the new plan's month
 *   description    (optional) — overrides the copied description
 */
@WebServlet("/monthlyplan/clone")
public class CloneMonthlyPlanServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int status = 400;
        String message = "Unexpected server error occurred, please check your transaction.";

        String srcParam   = request.getParameter("sourcePlanId");
        String monthParam  = request.getParameter("targetMonth");
        String descParam   = request.getParameter("description");

        if (isBlank(srcParam) || isBlank(monthParam)) {
            respond(response, 400, "sourcePlanId and targetMonth are required.");
            return;
        }

        int sourcePlanId;
        LocalDate targetMonth;
        try {
            sourcePlanId = Integer.parseInt(srcParam.trim());
        } catch (NumberFormatException e) {
            respond(response, 400, "Invalid sourcePlanId.");
            return;
        }
        try {
            String m = monthParam.trim();
            // Accept YYYY-MM or a full date; normalise to the 1st of the month.
            if (m.length() == 7) { m = m + "-01"; }
            targetMonth = LocalDate.parse(m).withDayOfMonth(1);
        } catch (Exception e) {
            respond(response, 400, "Invalid targetMonth. Expected YYYY-MM.");
            return;
        }

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {
            con.setAutoCommit(false);
            try {
                MonthlyPlanDAO planDAO = new MonthlyPlanDAO(con);

                MonthlyPlan source = planDAO.get(sourcePlanId);
                if (source == null) {
                    respond(response, 404, "Source plan not found.");
                    return;
                }

                // Reject if a plan already exists for (target month, same machine type).
                if (planDAO.findDuplicate(new MonthlyPlan(targetMonth, source.getMachineTypeId())) != null) {
                    respond(response, 409,
                        "A plan already exists for that month and machine type. "
                      + "Delete it first or choose another month.");
                    return;
                }

                // ---- 1. New plan header (inputs carried, status DRAFT) ----
                String desc = !isBlank(descParam) ? descParam.trim() : source.getDescription();
                LocalDate newLastDay = shiftToMonth(source.getLastDayProduction(), targetMonth);

                MonthlyPlan clone = new MonthlyPlan(
                    targetMonth, source.getMachineTypeId(), desc,
                    source.getProductionTime(), source.getEfficiency(),
                    source.getWorkingDays(), source.getAvailableMachine(),
                    "DRAFT", newLastDay
                );
                if (planDAO.create(clone) == null) {
                    con.rollback();
                    respond(response, 500, "Failed to create the new plan.");
                    return;
                }

                // Fetch the new PLAN_ID (unique by month + machine type).
                MonthlyPlan created = planDAO.findDuplicate(
                    new MonthlyPlan(targetMonth, source.getMachineTypeId()));
                if (created == null || created.getPlanId() == null) {
                    con.rollback();
                    respond(response, 500, "Could not resolve the new plan id after create.");
                    return;
                }
                int newPlanId = created.getPlanId();

                // ---- 2. Copy Precondition Raw rows ----
                PreconditionRawDAO rawDAO = new PreconditionRawDAO(con);
                List<PreconditionRaw> rawRows = rawDAO.getByPlanId(sourcePlanId);
                int rawCopied = 0;
                for (PreconditionRaw src : rawRows) {
                    PreconditionRaw copy = new PreconditionRaw();
                    copy.setPreconditionRawId(null);      // new sequence id
                    copy.setPlanId(newPlanId);
                    copy.setItem(src.getItem());          // same ITEM FK
                    copy.setCapCode(src.getCapCode());
                    copy.setLotsPerBatch(src.getLotsPerBatch());
                    copy.setInternalSheet(src.getInternalSheet());
                    copy.setDummySheet(src.getDummySheet());
                    copy.setBlkPerLot(src.getBlkPerLot());
                    copy.setKpcsPerLot(src.getKpcsPerLot());
                    copy.setSecPerSht(src.getSecPerSht());
                    copy.setEff(src.getEff());
                    copy.setLotsPerMonth(src.getLotsPerMonth());
                    if (rawDAO.create(copy) != null) { rawCopied++; }
                }

                // ---- 3. Copy the Saggering pattern (dates shifted to new month) ----
                SaggeringDAO sagDAO = new SaggeringDAO(con);
                int sagItems = 0;
                Saggering srcSag = sagDAO.getByPlanId(sourcePlanId);
                if (srcSag != null && srcSag.getItems() != null && !srcSag.getItems().isEmpty()) {
                    Saggering newSag = new Saggering();
                    newSag.setPlanId(newPlanId);
                    newSag.setStatus("DRAFT");

                    for (SaggeringItem srcItem : srcSag.getItems()) {
                        SaggeringItem it = new SaggeringItem();
                        it.setSaggeringItemId(null);
                        it.setItem(srcItem.getItem());        // same ITEM FK
                        it.setCapCode(srcItem.getCapCode());
                        it.setLotsPerBatch(srcItem.getLotsPerBatch());

                        if (srcItem.getDays() != null) {
                            for (SaggeringDay srcDay : srcItem.getDays()) {
                                if (srcDay.getPlanDate() == null) { continue; }
                                LocalDate shifted = shiftToMonth(srcDay.getPlanDate(), targetMonth);
                                if (shifted == null) { continue; }   // day doesn't exist in target month
                                SaggeringDay d = new SaggeringDay();
                                d.setSaggeringDayId(null);
                                d.setPlanDate(shifted);
                                d.setValue(srcDay.getValue());
                                it.getDays().add(d);
                            }
                        }
                        newSag.getItems().add(it);
                        sagItems++;
                    }
                    sagDAO.saveForPlan(newSag);
                }

                con.commit();
                status = 200;
                message = "Cloned to " + targetMonth.getYear() + "-"
                        + String.format("%02d", targetMonth.getMonthValue())
                        + ": " + rawCopied + " precondition row(s), "
                        + sagItems + " saggering item(s). "
                        + "Allocation and Loading Plan will recompute fresh. "
                        + "newPlanId=" + newPlanId;

            } catch (SQLException e) {
                con.rollback();
                throw e;
            }
        } catch (Exception e) {
            e.printStackTrace();
            status = 500;
            message = "Clone failed: " + e.getMessage();
        }

        respond(response, status, message);
    }

    // Shift a date to the same day-of-month in the target month, clamping to the
    // target month's length (e.g. Mar 31 -> Feb 28). Returns null if the input is null.
    private LocalDate shiftToMonth(LocalDate src, LocalDate targetMonthFirst) {
        if (src == null) { return null; }
        YearMonth tm = YearMonth.from(targetMonthFirst);
        int day = Math.min(src.getDayOfMonth(), tm.lengthOfMonth());
        return tm.atDay(day);
    }

    private boolean isBlank(String s) { return s == null || s.trim().isEmpty(); }

    private void respond(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status);
        response.setContentType("text/plain");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(message);
    }
}
