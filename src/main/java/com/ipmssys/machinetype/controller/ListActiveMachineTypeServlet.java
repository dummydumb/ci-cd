package com.ipmssys.machinetype.controller;

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
import com.ipmssys.machinetype.dao.MachineTypeDAO;
import com.ipmssys.machinetype.model.MachineType;

/**
 * JSON list of ACTIVE machine types only. Feeds the machine-type dropdown
 * on dependent screens (e.g. Monthly Plan), so inactive types never appear
 * as a choice for new records.
 */
@WebServlet("/machinetype/la")
public class ListActiveMachineTypeServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String message = "Unexpected error occurred, please check your transaction.";

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {
            List<MachineType> listActive = new MachineTypeDAO(con).listActive();
            Gson gson = new GsonBuilder().serializeNulls().create();
            message = gson.toJson(listActive);
            response.setContentType("application/json");
        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(400);
        }

        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(message);
    }
}
