package com.ipmssys.precondition.controller;

import java.io.IOException;
import java.sql.Connection;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.ipmssys.configuration.GlobalVariables;
import com.ipmssys.connection.DBConnectionDataSource;
import com.ipmssys.monthlyplan.dao.MonthlyPlanDAO;
import com.ipmssys.monthlyplan.model.MonthlyPlan;
import com.ipmssys.precondition.model.Precondition;
import com.ipmssys.precondition.service.PreconditionService;
import com.ipmssys.saggering.dao.SaggeringDAO;
import com.ipmssys.preconditionraw.dao.PreconditionRawDAO;
import com.ipmssys.preconditionraw.model.PreconditionRaw;

/**
 * Returns the COMPUTED precondition rows for a plan (convCapa, machine
 * requirement, etc.). Loads the raw inputs and the plan constants, then runs
 * PreconditionService. Read-only, nothing stored.
 */
@WebServlet("/precondition/compute")
public class ComputePreconditionServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String message = "Unexpected error occurred, please check your transaction.";
        Integer planId = parseInt(request.getParameter("planid"));

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {
            if (planId == null) {
                response.setStatus(400);
                writePlain(response, "Missing plan reference.");
                return;
            }

            MonthlyPlan plan = new MonthlyPlanDAO(con).get(planId);
            List<PreconditionRaw> rawList = new PreconditionRawDAO(con).getByPlanId(planId);
            Map<String, Integer> saggeredLots = new SaggeringDAO(con).getMonthlyLotsByItemName(planId);
            List<Precondition> computed = new PreconditionService().compute(rawList, plan, saggeredLots);

            Gson gson = new GsonBuilder().serializeNulls().create();
            message = gson.toJson(computed);
            response.setContentType("application/json");
        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(400);
        }

        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(message);
    }

    private void writePlain(HttpServletResponse response, String text) throws IOException {
        response.setContentType("text/plain");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(text);
    }

    private Integer parseInt(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        try {
            return Integer.valueOf(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
