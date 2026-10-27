package com.ipmssys.machinetype.controller;

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
import com.ipmssys.machinetype.dao.MachineTypeDAO;
import com.ipmssys.machinetype.model.MachineType;

/**
 * GET loads one machine type (for the edit dialog); POST saves the changes.
 */
@WebServlet("/machinetype/u")
public class UpdateMachineTypeServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int status = 400;
        String message = "An error was encountered during processing.";
        String contentType = "text/plain";

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {
            Integer id = parseId(request.getParameter("id"));
            MachineType existing = new MachineTypeDAO(con).get(id);
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

        Integer id       = parseId(request.getParameter("id"));
        String strCode   = request.getParameter("machinecode");
        String strName   = request.getParameter("machinename");
        String strStatus = request.getParameter("status");

        int status = 400;
        String message = "Unexpected server error occurred, please check your transaction";

        if (id == null || isBlank(strCode) || isBlank(strName)) {
            message = "Please complete all required fields.";
        } else if (!isValidStatus(strStatus)) {
            message = "Invalid status.";
        } else {
            DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
            try (Connection con = dbConnection.getConnection()) {
                con.setAutoCommit(false);
                try {
                    MachineTypeDAO machineTypeDAO = new MachineTypeDAO(con);
                    MachineType machineType = machineTypeDAO.get(id);
                    if (machineType == null) {
                        message = "Failed to update. The machine type does not exist. "
                                + "It might have been deleted by another user.";
                    } else {
                        machineType.setMachineCode(strCode.trim().toUpperCase());
                        machineType.setMachineName(strName.trim());
                        machineType.setStatus(strStatus);

                        if (machineTypeDAO.findDuplicateUpdate(machineType) != null) {
                            message = "Failed to update. The machine type code already exists.";
                        } else if (machineTypeDAO.update(machineType) != null) {
                            con.commit();
                            status = 200;
                            message = machineType.getMachineCode() + " was updated successfully.";
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

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private boolean isValidStatus(String value) {
        return "ACTIVE".equals(value) || "INACTIVE".equals(value);
    }
}