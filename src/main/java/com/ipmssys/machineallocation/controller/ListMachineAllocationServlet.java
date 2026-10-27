package com.ipmssys.machineallocation.controller;

import java.io.IOException;
import java.sql.Connection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.ipmssys.configuration.GlobalVariables;
import com.ipmssys.connection.DBConnectionDataSource;
import com.ipmssys.machineallocation.dao.MachineAllocationDAO;
import com.ipmssys.machineallocation.model.MachineAllocation;

/**
 * Returns the saved machine-allocation tree for a plan as JSON, or {@code null}
 * if none exists yet. The JSP checks {@code data && data.allocationId > 0}.
 */
@WebServlet("/machineallocation/l")
public class ListMachineAllocationServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json;charset=UTF-8");
        response.setCharacterEncoding("UTF-8");

        Integer planId = parseInt(request.getParameter("planid"));
        if (planId == null) {
            response.setStatus(400);
            response.setContentType("text/plain;charset=UTF-8");
            response.getWriter().write("Plan ID is required.");
            return;
        }

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {
            MachineAllocation allocation = new MachineAllocationDAO(con).getFullByPlanId(planId);
            Gson gson = new GsonBuilder().serializeNulls().create();
            response.setStatus(200);
            response.getWriter().write(gson.toJson(allocation));
        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(500);
            response.setContentType("text/plain;charset=UTF-8");
            response.getWriter().write("Failed to load machine allocation.");
        }
    }

    private Integer parseInt(String value) {
        if (value == null || value.trim().isEmpty()) { return null; }
        try { return Integer.valueOf(value.trim()); }
        catch (NumberFormatException e) { return null; }
    }
}
