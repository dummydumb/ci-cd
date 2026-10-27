package com.ipmssys.machine.controller;

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
import com.ipmssys.machine.dao.MachineDAO;
import com.ipmssys.machine.model.Machine;
import com.ipmssys.machinetype.model.MachineType;

/**
 * Create a machine. Enforces required fields, unique name (case-insensitive),
 * and a valid usage value.
 */
@WebServlet("/machine/n")
public class CreateMachineServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String strName  = request.getParameter("machinename");
        String strUsage = request.getParameter("machineusage");
        Integer typeId  = parseInt(request.getParameter("machinetypeid"));

        int status = 400;
        String message = "Unexpected server error occurred, please check your transaction";

        if (isBlank(strName) || typeId == null) {
            message = "Please complete all required fields.";
        } else if (!isValidUsage(strUsage)) {
            message = "Invalid usage.";
        } else {
            strName = strName.trim();

            DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
            try (Connection con = dbConnection.getConnection()) {
                con.setAutoCommit(false);
                try {
                    MachineDAO machineDAO = new MachineDAO(con);
                    if (machineDAO.findDuplicate(new Machine(strName)) != null) {
                        message = "Failed to create. The machine name already exists.";
                    } else {
                        MachineType type = new MachineType();
                        type.setMachineTypeId(typeId);
                        Machine newMachine = new Machine(strName, type, strUsage);
                        if (machineDAO.create(newMachine) != null) {
                            con.commit();
                            status = 200;
                            message = strName + " was registered successfully.";
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
