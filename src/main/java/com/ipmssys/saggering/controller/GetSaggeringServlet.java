package com.ipmssys.saggering.controller;

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
import com.ipmssys.saggering.dao.SaggeringDAO;
import com.ipmssys.saggering.model.Saggering;

/**
 * Returns the full saggering tree for a plan as JSON (empty object when none).
 */
@WebServlet("/saggering/g")
public class GetSaggeringServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String message = "{}";
        Integer planId = parseInt(request.getParameter("planid"));

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {
            if (planId == null) {
                response.setStatus(400);
                message = "Missing plan reference.";
                response.setContentType("text/plain");
            } else {
                Saggering saggering = new SaggeringDAO(con).getByPlanId(planId);
                Gson gson = new GsonBuilder().serializeNulls().create();
                message = (saggering != null) ? gson.toJson(saggering) : "{}";
                response.setContentType("application/json");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(400);
        }

        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(message);
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
