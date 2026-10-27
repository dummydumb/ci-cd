package com.ipmssys.plottingsummary.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;

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
import com.ipmssys.plottingsummary.dao.PlottingSummaryDetailDAO;
import com.ipmssys.plottingsummary.model.PlottingSummary;
import com.ipmssys.plottingsummary.model.PlottingSummaryDetail;

/**
 * GET loads one plotting summary with its detail rows (for the edit dialog);
 * POST rewrites the header and the whole detail set in one transaction.
 */
@WebServlet("/plottingsummary/u")
public class UpdatePlottingSummaryServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int status = 400;
        String message = "An error was encountered during processing.";
        String contentType = "text/plain";

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {
            Integer id = parseId(request.getParameter("id"));
            PlottingSummaryDAO dao = new PlottingSummaryDAO(con);
            PlottingSummary ps = dao.get(id);
            if (ps != null) {
                ps.setDetails(new PlottingSummaryDetailDAO(con).getByPlottingId(id));
                Gson gson = new GsonBuilder().serializeNulls().create();
                message = gson.toJson(ps);
                status = 200;
                contentType = "application/json";
            } else {
                message = "Data does not exist!";
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        response.setStatus(status);
        response.setContentType(contentType);
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(message);
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int status = 400;
        String message = "Unexpected server error occurred, please check your transaction";

        Integer id = parseId(request.getParameter("id"));
        PlottingForm form = PlottingForm.from(request);

        if (id == null) {
            message = "Invalid plotting reference.";
        } else if (form.getError() != null) {
            message = form.getError();
        } else {
            DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
            try (Connection con = dbConnection.getConnection()) {
                con.setAutoCommit(false);
                try {
                    PlottingSummaryDAO dao = new PlottingSummaryDAO(con);
                    PlottingSummary existing = dao.get(id);
                    if (existing == null) {
                        message = "Failed to update. The plotting summary does not exist. "
                                + "It might have been deleted by another user.";
                    } else {
                        PlottingSummary ps = form.plotting;
                        ps.setPlottingId(id);

                        Integer stackId = (ps.getStackingMachine() != null)
                                ? ps.getStackingMachine().getMachineId() : null;
                        String conflict = dao.findCumulativeHoursConflict(stackId, form.details, id);

                        if (conflict != null) {
                            message = conflict;
                        } else if (dao.update(ps) != null) {
                            PlottingSummaryDetailDAO detailDAO = new PlottingSummaryDetailDAO(con);
                            detailDAO.deleteByPlottingId(id);
                            for (PlottingSummaryDetail d : form.details) {
                                d.setPlottingId(id);
                            }
                            detailDAO.createAll(form.details);
                            con.commit();
                            status = 200;
                            message = "Plotting summary was updated successfully.";
                        } else {
                            con.rollback();
                        }
                    }
                } catch (SQLException e) {
                    con.rollback();
                    throw e;
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        response.setStatus(status);
        response.setContentType("text/plain");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(message);
    }

    private Integer parseId(String value) {
        try {
            return Integer.valueOf(value);
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
