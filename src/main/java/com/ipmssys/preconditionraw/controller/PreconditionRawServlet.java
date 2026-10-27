package com.ipmssys.preconditionraw.controller;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Serves the Precondition Raw maintenance page (per-item raw inputs + Excel
 * import). The computed Precondition output is a separate page served by
 * {@code com.ipmssys.precondition.controller.PreconditionViewServlet} at
 * /precondition/view.
 */
@WebServlet("/precondition")
public class PreconditionRawServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String planId = request.getParameter("planid");
        request.setAttribute("preselectPlanId", planId != null ? planId : "");
        request.getRequestDispatcher("/jsp/Precondition/PreconditionRawMaintenance.jsp")
               .forward(request, response);
    }
}
