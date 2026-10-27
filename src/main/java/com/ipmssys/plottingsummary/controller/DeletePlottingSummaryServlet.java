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
import com.ipmssys.plottingsummary.model.PlottingSummary;

/**
 * Delete a plotting summary. Detail rows cascade via the FK.
 */
@WebServlet("/plottingsummary/d")
public class DeletePlottingSummaryServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int status = 400;
        String message = "Unexpected server error occurred, please check your transaction";

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {
            con.setAutoCommit(false);
            try {
                Integer id = Integer.valueOf(request.getParameter("id"));
                PlottingSummaryDAO dao = new PlottingSummaryDAO(con);
                PlottingSummary existing = dao.get(id);

                if (existing == null) {
                    message = "Data does not exist!";
                } else if (dao.delete(existing) != null) {
                    con.commit();
                    status = 200;
                    message = "Plotting summary has been deleted.";
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

        response.setStatus(status);
        response.setContentType("text/plain");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(message);
    }
}
