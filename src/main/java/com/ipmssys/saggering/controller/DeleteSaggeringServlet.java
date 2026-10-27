package com.ipmssys.saggering.controller;

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
import com.ipmssys.saggering.dao.SaggeringDAO;

/**
 * Delete the whole saggering tree for a plan.
 */
@WebServlet("/saggering/d")
public class DeleteSaggeringServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int status = 400;
        String message = "Unexpected server error occurred, please check your transaction";

        Integer planId = parseInt(request.getParameter("planid"));
        if (planId == null) {
            message = "Missing plan reference.";
        } else {
            DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
            try (Connection con = dbConnection.getConnection()) {
                con.setAutoCommit(false);
                try {
                    SaggeringDAO dao = new SaggeringDAO(con);
                    if (!dao.existsByPlanId(planId)) {
                        status = 404;
                        message = "Saggering plan does not exist or has already been deleted.";
                    } else {
                        dao.deleteByPlanId(planId);
                        con.commit();
                        status = 200;
                        message = "Saggering plan has been deleted.";
                    }
                } catch (SQLException e) {
                    con.rollback();
                    throw e;
                }
            } catch (Exception e) {
                e.printStackTrace();
                status = 500;
                message = "Failed to delete saggering plan: " + e.getMessage();
            }
        }

        response.setStatus(status);
        response.setContentType("text/plain");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(message);
    }

    private Integer parseInt(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        try {
            return Integer.valueOf(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
