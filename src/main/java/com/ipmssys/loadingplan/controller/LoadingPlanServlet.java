package com.ipmssys.loadingplan.controller;

import java.io.IOException;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/loadingplan")
public class LoadingPlanServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    public LoadingPlanServlet() {
        super();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String planIdParam = request.getParameter("planid");
        if (planIdParam == null) { planIdParam = request.getParameter("planId"); }

        if (planIdParam == null || planIdParam.trim().isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing planId parameter.");
            return;
        }

        request.setAttribute("planId",      planIdParam);
        request.setAttribute("month",       request.getParameter("month")       != null ? request.getParameter("month")       : "");
        request.setAttribute("year",        request.getParameter("year")        != null ? request.getParameter("year")        : "");
        request.setAttribute("machineCode", request.getParameter("machineCode") != null ? request.getParameter("machineCode") : "");
        request.setAttribute("monthName",   request.getParameter("monthName")   != null ? request.getParameter("monthName")   : "");

        RequestDispatcher rd = request.getRequestDispatcher("/jsp/LoadingPlan/LoadingPlanMaintenance.jsp");
        rd.forward(request, response);
    }
}