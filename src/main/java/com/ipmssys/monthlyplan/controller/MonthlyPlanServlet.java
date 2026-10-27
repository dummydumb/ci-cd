package com.ipmssys.monthlyplan.controller;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Serves the Monthly Plan maintenance page.
 */
@WebServlet("/monthlyplan")
public class MonthlyPlanServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/jsp/MonthlyPlan/MonthlyPlanMaintenance.jsp").forward(request, response);
    }
}
