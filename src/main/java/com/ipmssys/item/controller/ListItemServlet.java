package com.ipmssys.item.controller;

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
import com.ipmssys.item.dao.ItemDAO;
import com.ipmssys.item.model.Item;

/**
 * JSON list of items (each with its qualified machines) for the table.
 */
@WebServlet("/item/l")
public class ListItemServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String message = "Unexpected error occurred, please check your transaction.";

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {
            List<Item> list = new ItemDAO(con).listAll();
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
}
