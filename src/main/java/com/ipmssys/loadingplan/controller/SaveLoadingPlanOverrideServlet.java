package com.ipmssys.loadingplan.controller;

import java.io.IOException;
import java.sql.Connection;
import java.time.LocalDate;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.ipmssys.configuration.GlobalVariables;
import com.ipmssys.connection.DBConnectionDataSource;
import com.ipmssys.loadingplan.dao.LoadingPlanOverrideDAO;
import com.ipmssys.loadingplan.model.LoadingPlanOverride;

/**
 * POST   /loadingplan/override/u — save a single manual cell edit
 * DELETE /loadingplan/override/u — revert a cell to its computed value
 *
 * POST params: planId, machineName, itemName, planDate (YYYY-MM-DD), value, remarks, overrideType
 * DELETE params: planId, machineName, itemName, planDate (query string only)
 */
@WebServlet("/loadingplan/override/u")
public class SaveLoadingPlanOverrideServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/plain;charset=UTF-8");

        String planIdParam   = request.getParameter("planId");
        String machineName   = request.getParameter("machineName");
        String itemName      = request.getParameter("itemName");
        String planDateParam = request.getParameter("planDate");
        String valueParam    = request.getParameter("value");
        String remarksParam  = request.getParameter("remarks");
        String overrideType  = request.getParameter("overrideType");
        String cellStatus    = request.getParameter("cellStatus");  // manual Excel-style status flag
        boolean statusOnly   = !isBlank(cellStatus) && isBlank(valueParam);

        // A status-only change (e.g. flag "Needs Conversion") carries no value and no
        // mandatory remarks. A value edit still requires planId/.../value and remarks.
        if (isBlank(planIdParam) || isBlank(machineName) || isBlank(itemName)
                || isBlank(planDateParam) || (!statusOnly && isBlank(valueParam))) {
            response.setStatus(400);
            response.getWriter().write("planId, machineName, itemName, planDate, and value are required.");
            return;
        }
        if (!statusOnly && isBlank(remarksParam)) {
            response.setStatus(400);
            response.getWriter().write("Remarks are required. Briefly explain why you are changing this value.");
            return;
        }

        int planId;
        double value;
        LocalDate planDate;

        try { planId = Integer.parseInt(planIdParam.trim()); }
        catch (NumberFormatException e) {
            response.setStatus(400); response.getWriter().write("Invalid planId."); return;
        }
        if (statusOnly) {
            value = 0;   // status-only change: value field is unused by the DAO status path
        } else {
            try { value = Double.parseDouble(valueParam.trim()); }
            catch (NumberFormatException e) {
                response.setStatus(400); response.getWriter().write("Invalid value."); return;
            }
            if (value < 0) {
                response.setStatus(400); response.getWriter().write("Value cannot be negative."); return;
            }
        }
        try { planDate = LocalDate.parse(planDateParam.trim()); }
        catch (Exception e) {
            response.setStatus(400); response.getWriter().write("Invalid planDate. Expected YYYY-MM-DD."); return;
        }

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);

        try (Connection con = dbConnection.getConnection()) {
            con.setAutoCommit(false);
            try {
                LoadingPlanOverrideDAO dao = new LoadingPlanOverrideDAO(con);

                if (statusOnly) {
                    // Manual status flag only — preserve any existing computed/override value.
                    dao.updateCellStatus(planId, machineName.trim(), itemName.trim(),
                                         planDate, cellStatus.trim());
                } else {
                    LoadingPlanOverride override = new LoadingPlanOverride(
                        planId, machineName.trim(), itemName.trim(), planDate, value
                    );
                    override.setOverrideType(!isBlank(overrideType) ? overrideType.trim() : "STANDARD");
                    override.setRemarks(!isBlank(remarksParam) ? remarksParam.trim() : null);
                    override.setCellStatus(!isBlank(cellStatus) ? cellStatus.trim() : "NONE");
                    dao.upsert(override);
                }

                con.commit();
                response.setStatus(200);
                response.getWriter().write(statusOnly ? "Status updated." : "Override saved.");
            } catch (Exception e) {
                try { con.rollback(); } catch (Exception rb) {
                    log("Rollback failed in SaveLoadingPlanOverrideServlet.doPost", rb);
                }
                throw e;
            } finally {
                try { con.setAutoCommit(true); } catch (Exception ignored) {}
            }
        } catch (Exception e) {
            log("SaveLoadingPlanOverrideServlet.doPost error — planId=" + planIdParam
                + " machine=" + machineName + " item=" + itemName + " date=" + planDateParam, e);
            response.setStatus(500);
            response.getWriter().write("Server error while saving override: " + e.getMessage());
        }
    }

    @Override
    protected void doDelete(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/plain;charset=UTF-8");

        // DELETE params must come from query string — getParameter() ignores body for DELETE
        String planIdParam   = request.getParameter("planId");
        String machineName   = request.getParameter("machineName");
        String itemName      = request.getParameter("itemName");
        String planDateParam = request.getParameter("planDate");

        if (isBlank(planIdParam) || isBlank(machineName) || isBlank(itemName) || isBlank(planDateParam)) {
            response.setStatus(400);
            response.getWriter().write("planId, machineName, itemName, and planDate are required.");
            return;
        }

        int planId;
        LocalDate planDate;

        try { planId = Integer.parseInt(planIdParam.trim()); }
        catch (NumberFormatException e) {
            response.setStatus(400); response.getWriter().write("Invalid planId."); return;
        }
        try { planDate = LocalDate.parse(planDateParam.trim()); }
        catch (Exception e) {
            response.setStatus(400); response.getWriter().write("Invalid planDate. Expected YYYY-MM-DD."); return;
        }

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);

        try (Connection con = dbConnection.getConnection()) {
            con.setAutoCommit(false);
            try {
                new LoadingPlanOverrideDAO(con).delete(
                    planId, machineName.trim(), itemName.trim(), planDate
                );
                con.commit();
                response.setStatus(200);
                response.getWriter().write("Override cleared.");
            } catch (Exception e) {
                try { con.rollback(); } catch (Exception rb) {
                    log("Rollback failed in SaveLoadingPlanOverrideServlet.doDelete", rb);
                }
                throw e;
            } finally {
                try { con.setAutoCommit(true); } catch (Exception ignored) {}
            }
        } catch (Exception e) {
            log("SaveLoadingPlanOverrideServlet.doDelete error — planId=" + planIdParam
                + " machine=" + machineName + " item=" + itemName + " date=" + planDateParam, e);
            response.setStatus(500);
            response.getWriter().write("Server error while clearing override.");
        }
    }

    private boolean isBlank(String value) { return value == null || value.trim().isEmpty(); }
}