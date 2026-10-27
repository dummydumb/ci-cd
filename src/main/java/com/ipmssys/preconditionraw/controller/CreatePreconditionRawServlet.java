package com.ipmssys.preconditionraw.controller;

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
import com.ipmssys.preconditionraw.dao.PreconditionRawDAO;
import com.ipmssys.preconditionraw.model.PreconditionRaw;

/**
 * Create a precondition-raw row for an item within a plan. One per (plan, item).
 */
@WebServlet("/precondition/n")
public class CreatePreconditionRawServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int status = 400;
        String message = "Unexpected server error occurred, please check your transaction";

        RawForm form = RawForm.from(request);
        if (form.getError() != null) {
            message = form.getError();
        } else {
            DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
            try (Connection con = dbConnection.getConnection()) {
                con.setAutoCommit(false);
                try {
                    PreconditionRawDAO dao = new PreconditionRawDAO(con);
                    if (dao.findDuplicate(form.raw) != null) {
                        message = "Failed to create. That item already has preconditions for this plan.";
                    } else if (dao.create(form.raw) != null) {
                        con.commit();
                        status = 200;
                        message = "Precondition was created successfully.";
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
