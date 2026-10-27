package com.ipmssys.loadingplan.controller;

import java.io.BufferedReader;
import java.io.IOException;
import java.sql.Connection;
import java.util.Arrays;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.ipmssys.configuration.GlobalVariables;
import com.ipmssys.connection.DBConnectionDataSource;
import com.google.gson.Gson;
import com.ipmssys.loadingplan.dao.LoadingPlanItemPriorityDAO;
import com.ipmssys.loadingplan.model.LoadingPlanItemPriority;

/**
 * GET    /loadingplan/itempriority?planId=X[&machineName=Y|&allMachines=true]
 *        — returns current priorities as JSON
 * POST   /loadingplan/itempriority
 *        Body: { planId, machineName, orderedItems: ["ITEM_A","ITEM_B",...] }
 *        — saves a new order for one machine
 * DELETE /loadingplan/itempriority?planId=X&machineName=Y
 *        — resets to allocation order (query string only)
 */
@WebServlet("/loadingplan/itempriority")
public class SaveItemPriorityServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private static class PriorityRequest {
        int      planId;
        String   machineName;
        String[] orderedItems;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json;charset=UTF-8");

        String planIdParam = request.getParameter("planId");
        String machineName = request.getParameter("machineName");
        String allMachines = request.getParameter("allMachines");

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
            List<LoadingPlanItemPriority> all = new LoadingPlanItemPriorityDAO(con).getByPlanId(planId);

            if ("true".equalsIgnoreCase(allMachines)) {
                response.setStatus(200);
                response.getWriter().write(new Gson().toJson(all));
            } else {
                if (isBlank(machineName)) {
                    response.setStatus(400); response.getWriter().write("[]"); return;
                }
                final String mn = machineName.trim();
                List<String> items = new java.util.ArrayList<String>();
                for (LoadingPlanItemPriority p : all) {
                    if (p.getMachineName().equalsIgnoreCase(mn)) {
                        items.add(p.getItemName());
                    }
                }
                response.setStatus(200);
                response.getWriter().write(new Gson().toJson(items));
            }
        } catch (Exception e) {
            log("SaveItemPriorityServlet.doGet error — planId=" + planIdParam, e);
            response.setStatus(500);
            response.getWriter().write("[]");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/plain;charset=UTF-8");

        StringBuilder sb = new StringBuilder();
        try (BufferedReader r = request.getReader()) {
            String line;
            while ((line = r.readLine()) != null) { sb.append(line); }
        }

        if (isBlank(sb.toString())) {
            response.setStatus(400); response.getWriter().write("Empty request body."); return;
        }

        PriorityRequest req;
        try { req = new Gson().fromJson(sb.toString(), PriorityRequest.class); }
        catch (Exception e) {
            response.setStatus(400); response.getWriter().write("Invalid JSON."); return;
        }

        if (req.planId <= 0 || isBlank(req.machineName)
                || req.orderedItems == null || req.orderedItems.length == 0) {
            response.setStatus(400);
            response.getWriter().write("planId, machineName, and orderedItems are required.");
            return;
        }

        List<String> orderedList = Arrays.asList(req.orderedItems);

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {
            con.setAutoCommit(false);
            try {
                new LoadingPlanItemPriorityDAO(con).saveForMachine(
                    req.planId, req.machineName.trim(), orderedList
                );
                con.commit();
                response.setStatus(200);
                response.getWriter().write("Item priority saved for " + req.machineName.trim() + ".");
            } catch (Exception e) {
                try { con.rollback(); }
                catch (Exception rb) { log("Rollback failed in SaveItemPriorityServlet.doPost", rb); }
                throw e;
            } finally {
                try { con.setAutoCommit(true); } catch (Exception ignored) {}
            }
        } catch (Exception e) {
            log("SaveItemPriorityServlet.doPost error — planId=" + req.planId
                + " machine=" + req.machineName, e);
            response.setStatus(500);
            response.getWriter().write("Server error: " + e.getMessage());
        }
    }

    @Override
    protected void doDelete(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("text/plain;charset=UTF-8");

        // DELETE params must be in query string
        String planIdParam = request.getParameter("planId");
        String machineName = request.getParameter("machineName");

        if (isBlank(planIdParam) || isBlank(machineName)) {
            response.setStatus(400);
            response.getWriter().write("planId and machineName are required.");
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
                new LoadingPlanItemPriorityDAO(con).deleteForMachine(planId, machineName.trim());
                con.commit();
                response.setStatus(200);
                response.getWriter().write("Priority reset. Reverted to allocation order.");
            } catch (Exception e) {
                try { con.rollback(); }
                catch (Exception rb) { log("Rollback failed in SaveItemPriorityServlet.doDelete", rb); }
                throw e;
            } finally {
                try { con.setAutoCommit(true); } catch (Exception ignored) {}
            }
        } catch (Exception e) {
            log("SaveItemPriorityServlet.doDelete error — planId=" + planIdParam
                + " machine=" + machineName, e);
            response.setStatus(500);
            response.getWriter().write("Server error: " + e.getMessage());
        }
    }

    private boolean isBlank(String v) { return v == null || v.trim().isEmpty(); }
}