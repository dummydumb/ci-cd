package com.ipmssys.monthlyplan.controller;

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
import com.ipmssys.monthlyplan.dao.MonthlyPlanDAO;
import com.ipmssys.monthlyplan.model.MonthlyPlan;

/**
 * GET loads one plan (for the edit dialog); POST saves the changes.
 */
@WebServlet("/monthlyplan/u")
public class UpdateMonthlyPlanServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int status = 400;
        String message = "An error was encountered during processing.";
        String contentType = "text/plain";

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {
            Integer id = parseId(request.getParameter("id"));
            MonthlyPlan existing = new MonthlyPlanDAO(con).get(id);
            if (existing != null) {
                Gson gson = new GsonBuilder().serializeNulls().create();
                message = gson.toJson(existing);
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
        PlanForm form = PlanForm.from(request);
        String validationError = form.validate();

        if (id == null) {
            message = "Invalid plan reference.";
        } else if (validationError != null) {
            message = validationError;
        } else {
            DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
            try (Connection con = dbConnection.getConnection()) {
                con.setAutoCommit(false);
                try {
                    MonthlyPlanDAO planDAO = new MonthlyPlanDAO(con);
                    MonthlyPlan plan = planDAO.get(id);
                    if (plan == null) {
                        message = "Failed to update. The plan does not exist. "
                                + "It might have been deleted by another user.";
                    } else {
                        plan.setPlanMonth(form.planMonth);
                        plan.setMachineTypeId(form.machineTypeId);
                        plan.setDescription(form.description);
                        plan.setProductionTime(form.productionTime);
                        plan.setEfficiency(form.efficiency);
                        plan.setWorkingDays(form.workingDays);
                        plan.setAvailableMachine(form.availableMachine);
                        plan.setStatus(form.statusValue);
                        plan.setLastDayProduction(form.lastDayProduction);

                        if (planDAO.findDuplicateUpdate(plan) != null) {
                            message = "Failed to update. A plan already exists for that month and machine type.";
                        } else if (planDAO.update(plan) != null) {
                            con.commit();
                            status = 200;
                            message = "Monthly plan was updated successfully.";
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
