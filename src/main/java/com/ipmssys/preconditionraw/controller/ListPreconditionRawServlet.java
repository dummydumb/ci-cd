package com.ipmssys.preconditionraw.controller;

import java.io.IOException;
import java.sql.Connection;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.ipmssys.configuration.GlobalVariables;
import com.ipmssys.connection.DBConnectionDataSource;
import com.ipmssys.preconditionraw.dao.PreconditionRawDAO;
import com.ipmssys.preconditionraw.model.PreconditionRaw;

/**
 * JSON list of raw precondition rows. Scoped to a plan when planid is given.
 */
@WebServlet("/precondition/l")
public class ListPreconditionRawServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String message = "Unexpected error occurred, please check your transaction.";
        Integer planId = parseInt(request.getParameter("planid"));

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {
            PreconditionRawDAO dao = new PreconditionRawDAO(con);
            List<PreconditionRaw> list = (planId != null) ? dao.getByPlanId(planId) : dao.listAll();
            Gson gson = new GsonBuilder().serializeNulls().create();
            message = gson.toJson(list);
            response.setContentType("application/json");
        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(400);
        }

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
