package com.ipmssys.plottingsummary.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.ipmssys.configuration.GlobalVariables;
import com.ipmssys.connection.DBConnectionDataSource;
import com.ipmssys.plottingsummary.dao.PlottingSummaryDAO;
import com.ipmssys.plottingsummary.dao.PlottingSummaryDetailDAO;
import com.ipmssys.plottingsummary.model.PlottingSummary;
import com.ipmssys.plottingsummary.model.PlottingSummaryDetail;

/**
 * Create a plotting summary (header + per-day detail rows) in one transaction,
 * after checking the stacking machine's cumulative-hours capacity.
 */
@WebServlet("/plottingsummary/n")
public class CreatePlottingSummaryServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int status = 400;
        String message = "Unexpected server error occurred, please check your transaction";

        PlottingForm form = PlottingForm.from(request);
        if (form.getError() != null) {
            message = form.getError();
        } else {
            DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
            try (Connection con = dbConnection.getConnection()) {
                con.setAutoCommit(false);
                try {
                    PlottingSummaryDAO dao = new PlottingSummaryDAO(con);
                    PlottingSummary ps = form.plotting;

                    Integer stackId = (ps.getStackingMachine() != null)
                            ? ps.getStackingMachine().getMachineId() : null;
                    String conflict = dao.findCumulativeHoursConflict(stackId, form.details, null);

                    if (conflict != null) {
                        message = conflict;
                    } else if (dao.create(ps) != null) {
                        for (PlottingSummaryDetail d : form.details) {
                            d.setPlottingId(ps.getPlottingId());
                        }
                        new PlottingSummaryDetailDAO(con).createAll(form.details);
                        con.commit();
                        status = 200;
                        message = "Plotting summary was created successfully.";
                    } else {
                        con.rollback();
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
}
