package com.ipmssys.machineallocation.controller;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Serves the Machine Allocation maintenance page (stage 3 of the pipeline).
 * An optional "planid" pre-selects the plan; the page loads items, the computed
 * precondition (MC REQT) and any saved allocation via AJAX.
 */
@WebServlet("/machineallocation")
public class MachineAllocationServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String planId = request.getParameter("planid");
        request.setAttribute("preselectPlanId", planId != null ? planId : "");
        request.getRequestDispatcher("/jsp/Machine/MachineAllocationMaintenance.jsp")
               .forward(request, response);
    }
}
