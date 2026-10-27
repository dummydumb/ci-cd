package com.ipmssys.preconditionraw.controller;

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
import com.ipmssys.preconditionraw.dao.PreconditionRawDAO;
import com.ipmssys.preconditionraw.model.PreconditionRaw;

/**
 * GET loads one raw row (for the edit dialog); POST saves the changes.
 */
@WebServlet("/precondition/u")
public class UpdatePreconditionRawServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int status = 400;
        String message = "An error was encountered during processing.";
        String contentType = "text/plain";

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {
            Integer id = parseId(request.getParameter("id"));
            PreconditionRaw existing = new PreconditionRawDAO(con).get(id);
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
        RawForm form = RawForm.from(request);

        if (id == null) {
            message = "Invalid precondition reference.";
        } else if (form.getError() != null) {
            message = form.getError();
        } else {
            DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
            try (Connection con = dbConnection.getConnection()) {
                con.setAutoCommit(false);
                try {
                    PreconditionRawDAO dao = new PreconditionRawDAO(con);
                    PreconditionRaw existing = dao.get(id);
                    if (existing == null) {
                        message = "Failed to update. The precondition does not exist. "
                                + "It might have been deleted by another user.";
                    } else {
                        form.raw.setPreconditionRawId(id);
                        if (dao.findDuplicateUpdate(form.raw) != null) {
                            message = "Failed to update. That item already has preconditions for this plan.";
                        } else if (dao.update(form.raw) != null) {
                            con.commit();
                            status = 200;
                            message = "Precondition was updated successfully.";
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
