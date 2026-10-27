package com.ipmssys.item.controller;

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
import com.ipmssys.item.dao.ItemDAO;
import com.ipmssys.item.model.Item;

/**
 * GET loads one item with its machines (for the edit dialog);
 * POST saves the item fields and rewrites its qualified-machine set.
 */
@WebServlet("/item/u")
public class UpdateItemServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int status = 400;
        String message = "An error was encountered during processing.";
        String contentType = "text/plain";

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {
            Integer id = parseId(request.getParameter("id"));
            Item existing = new ItemDAO(con).get(id);
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

        Integer id      = parseId(request.getParameter("id"));
        String strName  = request.getParameter("itemname");
        String strGroup = request.getParameter("groupcode");
        int[] machineIds = MachineIds.from(request);

        int status = 400;
        String message = "Unexpected server error occurred, please check your transaction";

        if (id == null || isBlank(strName)) {
            message = "Please enter an item name.";
        } else {
            DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
            try (Connection con = dbConnection.getConnection()) {
                con.setAutoCommit(false);
                try {
                    ItemDAO itemDAO = new ItemDAO(con);
                    Item item = itemDAO.get(id);
                    if (item == null) {
                        message = "Failed to update. The item does not exist. "
                                + "It might have been deleted by another user.";
                    } else {
                        item.setItemName(strName.trim());
                        item.setGroupCode(strGroup != null ? strGroup.trim().toUpperCase() : null);

                        if (itemDAO.findDuplicateUpdate(item) != null) {
                            message = "Failed to update. The item name already exists.";
                        } else if (itemDAO.update(item) != null) {
                            itemDAO.replaceMachines(item.getItemId(), machineIds);
                            con.commit();
                            status = 200;
                            message = item.getItemName() + " was updated successfully.";
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
}
