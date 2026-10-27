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
 * Create a monthly plan. Enforces required fields, valid ranges, a unique
 * (month, machine type), and last-day-of-production within/after the month.
 */
@WebServlet("/monthlyplan/n")
public class CreateMonthlyPlanServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int status = 400;
        String message = "Unexpected server error occurred, please check your transaction";

        PlanForm form = PlanForm.from(request);
        String validationError = form.validate();

        if (validationError != null) {
            message = validationError;
        } else {
            DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
            try (Connection con = dbConnection.getConnection()) {
                con.setAutoCommit(false);
                try {
                    MonthlyPlanDAO planDAO = new MonthlyPlanDAO(con);
                    if (planDAO.findDuplicate(new MonthlyPlan(form.planMonth, form.machineTypeId)) != null) {
                        message = "Failed to create. A plan already exists for that month and machine type.";
                    } else {
                        MonthlyPlan newPlan = new MonthlyPlan(form.planMonth, form.machineTypeId,
                                form.description, form.productionTime, form.efficiency, form.workingDays,
                                form.availableMachine, form.statusValue, form.lastDayProduction);
                        if (planDAO.create(newPlan) != null) {
                            con.commit();
                            status = 200;
                            message = "Monthly plan was created successfully.";
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
}
