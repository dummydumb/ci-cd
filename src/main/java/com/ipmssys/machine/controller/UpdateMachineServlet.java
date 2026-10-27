package com.ipmssys.machine.controller;

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
import com.ipmssys.machine.dao.MachineDAO;
import com.ipmssys.machine.model.Machine;
import com.ipmssys.machinetype.model.MachineType;

/**
 * GET loads one machine (for the edit dialog); POST saves the changes.
 */
@WebServlet("/machine/u")
public class UpdateMachineServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int status = 400;
        String message = "An error was encountered during processing.";
        String contentType = "text/plain";

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {
            Integer id = parseInt(request.getParameter("id"));
            Machine existing = new MachineDAO(con).get(id);
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

        Integer id      = parseInt(request.getParameter("id"));
        String strName  = request.getParameter("machinename");
        String strUsage = request.getParameter("machineusage");
        Integer typeId  = parseInt(request.getParameter("machinetypeid"));

        int status = 400;
        String message = "Unexpected server error occurred, please check your transaction";

        if (id == null || isBlank(strName) || typeId == null) {
            message = "Please complete all required fields.";
        } else if (!isValidUsage(strUsage)) {
            message = "Invalid usage.";
        } else {
            DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
            try (Connection con = dbConnection.getConnection()) {
                con.setAutoCommit(false);
                try {
                    MachineDAO machineDAO = new MachineDAO(con);
                    Machine machine = machineDAO.get(id);
                    if (machine == null) {
                        message = "Failed to update. The machine does not exist. "
                                + "It might have been deleted by another user.";
                    } else {
                        machine.setMachineName(strName.trim());
                        machine.setMachineUsage(strUsage);
                        MachineType type = new MachineType();
                        type.setMachineTypeId(typeId);
                        machine.setMachineType(type);

                        if (machineDAO.findDuplicateUpdate(machine) != null) {
                            message = "Failed to update. The machine name already exists.";
                        } else if (machineDAO.update(machine) != null) {
                            con.commit();
                            status = 200;
                            message = machine.getMachineName() + " was updated successfully.";
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

    private Integer parseInt(String value) {
        try {
            return Integer.valueOf(value);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private boolean isValidUsage(String value) {
        return "AVAILABLE".equals(value) || "UNAVAILABLE".equals(value);
    }
}
