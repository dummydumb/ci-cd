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
 * Delete a machine type. Blocked when any Monthly Plan references it —
 * the planner is told to set it INACTIVE instead (soft-disable preserves history).
 */
@WebServlet("/machinetype/d")
public class DeleteMachineTypeServlet extends HttpServlet {

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
                MachineTypeDAO machineTypeDAO = new MachineTypeDAO(con);
                MachineType existing = machineTypeDAO.get(id);

                if (existing == null) {
                    message = "Data does not exist!";
                } else if (machineTypeDAO.isReferencedByPlan(id)) {
                    message = "Cannot delete " + existing.getMachineCode()
                            + " — it is used by one or more monthly plans. "
                            + "Set it to INACTIVE instead.";
                } else if (machineTypeDAO.delete(existing) != null) {
                    con.commit();
                    status = 200;
                    message = existing.getMachineCode() + " has been deleted.";
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