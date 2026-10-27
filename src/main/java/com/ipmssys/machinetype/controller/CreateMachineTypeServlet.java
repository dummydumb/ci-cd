package com.ipmssys.machinetype.controller;

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
import com.ipmssys.machinetype.dao.MachineTypeDAO;
import com.ipmssys.machinetype.model.MachineType;

/**
 * Create a machine type. Enforces: required fields, unique code (case-insensitive),
 * valid status. Owns the transaction.
 */
@WebServlet("/machinetype/n")
public class CreateMachineTypeServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String strCode   = request.getParameter("machinecode");
        String strName   = request.getParameter("machinename");
        String strStatus = request.getParameter("status");

        int status = 400;
        String message = "Unexpected server error occurred, please check your transaction";

        if (isBlank(strCode) || isBlank(strName)) {
            message = "Please complete all required fields.";
        } else if (!isValidStatus(strStatus)) {
            message = "Invalid status.";
        } else {
            strCode = strCode.trim().toUpperCase();
            strName = strName.trim();

            DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
            try (Connection con = dbConnection.getConnection()) {
                con.setAutoCommit(false);
                try {
                    MachineTypeDAO machineTypeDAO = new MachineTypeDAO(con);
                    if (machineTypeDAO.findDuplicate(new MachineType(strCode)) != null) {
                        message = "Failed to create. The machine type code already exists.";
                    } else {
                        MachineType newType = new MachineType(strCode, strName, strStatus);
                        if (machineTypeDAO.create(newType) != null) {
                            con.commit();
                            status = 200;
                            message = strCode + " was registered successfully.";
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

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private boolean isValidStatus(String value) {
        return "ACTIVE".equals(value) || "INACTIVE".equals(value);
    }
}