package com.ipmssys.monthlyplan.controller;

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
import com.ipmssys.monthlyplan.dao.MonthlyPlanDAO;
import com.ipmssys.monthlyplan.model.MonthlyPlan;

/**
 * Delete a monthly plan.
 */
@WebServlet("/monthlyplan/d")
public class DeleteMonthlyPlanServlet extends HttpServlet {

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
                MonthlyPlanDAO planDAO = new MonthlyPlanDAO(con);
                MonthlyPlan existing = planDAO.get(id);

                if (existing == null) {
                    message = "Data does not exist!";
                } else if (planDAO.delete(existing) != null) {
                    con.commit();
                    status = 200;
                    message = "Monthly plan has been deleted.";
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
