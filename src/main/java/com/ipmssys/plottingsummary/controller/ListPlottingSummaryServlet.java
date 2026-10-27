package com.ipmssys.plottingsummary.controller;

import java.io.IOException;
import java.sql.Connection;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.ipmssys.configuration.GlobalVariables;
import com.ipmssys.connection.DBConnectionDataSource;
import com.ipmssys.plottingsummary.dao.PlottingSummaryDAO;
import com.ipmssys.plottingsummary.model.PlottingSummary;

/**
 * JSON list of plotting summaries (headers with totals) for the table.
 */
@WebServlet("/plottingsummary/l")
public class ListPlottingSummaryServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String message = "Unexpected error occurred, please check your transaction.";

        Integer month = parseInt(request.getParameter("month"));
        Integer year = parseInt(request.getParameter("year"));

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {
            PlottingSummaryDAO dao = new PlottingSummaryDAO(con);
            List<PlottingSummary> list = (month != null && year != null)
                    ? dao.listByMonthYear(month, year)
                    : dao.listAll();
            Gson gson = new GsonBuilder().serializeNulls().create();
            message = gson.toJson(list);
            response.setContentType("application/json");
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
