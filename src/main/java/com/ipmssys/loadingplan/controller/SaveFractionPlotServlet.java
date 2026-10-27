package com.ipmssys.loadingplan.controller;

import java.io.IOException;
import java.sql.Connection;
import java.time.LocalDate;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.ipmssys.configuration.GlobalVariables;
import com.ipmssys.connection.DBConnectionDataSource;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.ipmssys.loadingplan.dao.LoadingPlanFractionPlotDAO;
import com.ipmssys.loadingplan.dao.LoadingPlanOverrideDAO;
import com.ipmssys.loadingplan.model.LoadingPlanFractionPlot;

/**
 * GET    /loadingplan/fractionplot?planId=X         — list all plots for a plan as JSON
 * POST   /loadingplan/fractionplot                  — save or update a fraction plot
 *        ?force=true skips the override conflict check
 * DELETE /loadingplan/fractionplot?planId=X&...     — remove a fraction plot (query string only)
 */
@WebServlet("/loadingplan/fractionplot")
public class SaveFractionPlotServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json;charset=UTF-8");

        String planIdParam = request.getParameter("planId");
        if (isBlank(planIdParam)) {
            response.setStatus(400); response.getWriter().write("[]"); return;
        }

        int planId;
        try { planId = Integer.parseInt(planIdParam.trim()); }
        catch (NumberFormatException e) {
            response.setStatus(400); response.getWriter().write("[]"); return;
        }

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {
            List<LoadingPlanFractionPlot> plots = new LoadingPlanFractionPlotDAO(con).getByPlanId(planId);
            response.setStatus(200);
            response.getWriter().write(new GsonBuilder().serializeNulls().create().toJson(plots));
        } catch (Exception e) {
            log("SaveFractionPlotServlet.doGet error — planId=" + planIdParam, e);
            response.setStatus(500);
            response.getWriter().write("[]");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json;charset=UTF-8");

        String planIdParam    = request.getParameter("planId");
        String machineName    = request.getParameter("machineName");
        String itemName       = request.getParameter("itemName");
        String plotStartParam = request.getParameter("plotStart");
        String plotEndParam   = request.getParameter("plotEnd");
        String totalLotsParam = request.getParameter("totalLots");

        if (isBlank(planIdParam) || isBlank(machineName) || isBlank(itemName)
                || isBlank(plotStartParam) || isBlank(plotEndParam) || isBlank(totalLotsParam)) {
            response.setStatus(400);
            response.getWriter().write("{\"error\":\"planId, machineName, itemName, plotStart, plotEnd, and totalLots are required.\"}");
            return;
        }

        int planId;
        LocalDate plotStart, plotEnd;
        int totalLots;

        try { planId = Integer.parseInt(planIdParam.trim()); }
        catch (NumberFormatException e) {
            response.setStatus(400); response.getWriter().write("{\"error\":\"Invalid planId.\"}"); return;
        }
        try { plotStart = LocalDate.parse(plotStartParam.trim()); }
        catch (Exception e) {
            response.setStatus(400); response.getWriter().write("{\"error\":\"Invalid plotStart. Expected YYYY-MM-DD.\"}"); return;
        }
        try { plotEnd = LocalDate.parse(plotEndParam.trim()); }
        catch (Exception e) {
            response.setStatus(400); response.getWriter().write("{\"error\":\"Invalid plotEnd. Expected YYYY-MM-DD.\"}"); return;
        }
        try { totalLots = Integer.parseInt(totalLotsParam.trim()); }
        catch (NumberFormatException e) {
            response.setStatus(400); response.getWriter().write("{\"error\":\"Invalid totalLots.\"}"); return;
        }

        if (plotEnd.isBefore(plotStart)) {
            response.setStatus(400);
            response.getWriter().write("{\"error\":\"Plot end date must be on or after plot start date.\"}");
            return;
        }
        if (totalLots < 0) {
            response.setStatus(400);
            response.getWriter().write("{\"error\":\"Total lots cannot be negative.\"}");
            return;
        }

        boolean force = "true".equalsIgnoreCase(request.getParameter("force"));

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {

            if (!force) {
                List<LocalDate> conflicts = new LoadingPlanOverrideDAO(con)
                    .getConflictingDates(planId, machineName.trim(), itemName.trim(), plotStart, plotEnd);

                if (!conflicts.isEmpty()) {
                    StringBuilder sb = new StringBuilder("[");
                    for (int i = 0; i < conflicts.size(); i++) {
                        if (i > 0) { sb.append(","); }
                        sb.append("\"").append(conflicts.get(i).toString()).append("\"");
                    }
                    sb.append("]");
                    response.setStatus(409);
                    response.getWriter().write(sb.toString());
                    return;
                }
            }

            con.setAutoCommit(false);
            try {
                new LoadingPlanFractionPlotDAO(con).upsert(
                    new LoadingPlanFractionPlot(planId, machineName.trim(), itemName.trim(),
                        plotStart, plotEnd, totalLots)
                );
                con.commit();
                response.setStatus(200);
                response.getWriter().write("{\"success\":true}");
            } catch (Exception e) {
                try { con.rollback(); }
                catch (Exception rb) { log("Rollback failed in SaveFractionPlotServlet.doPost", rb); }
                throw e;
            } finally {
                try { con.setAutoCommit(true); } catch (Exception ignored) {}
            }

        } catch (Exception e) {
            log("SaveFractionPlotServlet.doPost error — planId=" + planIdParam
                + " machine=" + machineName + " item=" + itemName, e);
            response.setStatus(500);
            response.getWriter().write("{\"error\":\"Server error: " + escape(e.getMessage()) + "\"}");
        }
    }

    @Override
    protected void doDelete(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("text/plain;charset=UTF-8");

        // DELETE params must be in query string — getParameter() ignores body for DELETE
        String planIdParam = request.getParameter("planId");
        String machineName = request.getParameter("machineName");
        String itemName    = request.getParameter("itemName");

        if (isBlank(planIdParam) || isBlank(machineName) || isBlank(itemName)) {
            response.setStatus(400);
            response.getWriter().write("planId, machineName, and itemName are required.");
            return;
        }

        int planId;
        try { planId = Integer.parseInt(planIdParam.trim()); }
        catch (NumberFormatException e) {
            response.setStatus(400); response.getWriter().write("Invalid planId."); return;
        }

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {
            con.setAutoCommit(false);
            try {
                new LoadingPlanFractionPlotDAO(con).delete(planId, machineName.trim(), itemName.trim());
                con.commit();
                response.setStatus(200);
                response.getWriter().write("Fraction plot removed. Row reverts to base computed allocation.");
            } catch (Exception e) {
                try { con.rollback(); }
                catch (Exception rb) { log("Rollback failed in SaveFractionPlotServlet.doDelete", rb); }
                throw e;
            } finally {
                try { con.setAutoCommit(true); } catch (Exception ignored) {}
            }
        } catch (Exception e) {
            log("SaveFractionPlotServlet.doDelete error — planId=" + planIdParam
                + " machine=" + machineName + " item=" + itemName, e);
            response.setStatus(500);
            response.getWriter().write("Server error while removing fraction plot: " + e.getMessage());
        }
    }

    private boolean isBlank(String v)  { return v == null || v.trim().isEmpty(); }
    private String  escape(String msg) { return msg != null ? msg.replace("\"", "'") : ""; }
}