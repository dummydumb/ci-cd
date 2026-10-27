package com.ipmssys.precondition.controller;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Serves the computed Precondition Output page (read-only derived capacity).
 * The actual numbers are fetched client-side from /precondition/compute.
 */
@WebServlet("/precondition/view")
public class PreconditionViewServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String planId = request.getParameter("planid");
        request.setAttribute("preselectPlanId", planId != null ? planId : "");
        request.getRequestDispatcher("/jsp/Precondition/PreconditionMaintenance.jsp")
               .forward(request, response);
    }
}
