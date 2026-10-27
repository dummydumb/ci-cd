package com.ipmssys.monthlyplan.controller;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Serves the Monthly Planner — the pipeline workflow hub for a plan.
 * An optional "planid" request parameter pre-selects a plan; the page itself
 * loads the plan list and each stage's status via AJAX.
 */
@WebServlet("/monthlyplanner")
public class MonthlyPlannerServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String planId = request.getParameter("planid");
        request.setAttribute("preselectPlanId", planId != null ? planId : "");
        request.getRequestDispatcher("/jsp/MonthlyPlan/MonthlyPlanner.jsp").forward(request, response);
    }
}
