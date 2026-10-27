package com.ipmssys.plottingsummary.controller;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Serves the Plotting Summary maintenance page.
 */
@WebServlet("/plottingsummary")
public class PlottingSummaryServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/jsp/PlottingSummary/PlottingSummaryMaintenance.jsp")
               .forward(request, response);
    }
}
