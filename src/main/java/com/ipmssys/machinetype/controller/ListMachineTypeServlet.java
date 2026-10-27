package com.ipmssys.machinetype.controller;

import java.io.IOException;
import java.sql.Connection;

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

/**
 * List all machine types (maintenance grid). Returns JSON.
 */
@WebServlet("/machinetype/l")
public class ListMachineTypeServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int status = 400;
        String message = "Unexpected server error occurred, please check your transaction";
        String contentType = "text/plain";

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {
            MachineTypeDAO machineTypeDAO = new MachineTypeDAO(con);
            Gson gson = new GsonBuilder().serializeNulls().create();
            message = gson.toJson(machineTypeDAO.listAll());
            status = 200;
            contentType = "application/json";
        } catch (Exception e) {
            e.printStackTrace();
        }

        response.setStatus(status);
        response.setContentType(contentType);
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(message);
    }
}