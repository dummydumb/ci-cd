package com.ipmssys.item.controller;

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
import com.ipmssys.item.dao.ItemDAO;
import com.ipmssys.item.model.Item;

/**
 * Create an item and its qualified-machine links in one transaction.
 */
@WebServlet("/item/n")
public class CreateItemServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String strName  = request.getParameter("itemname");
        String strGroup = request.getParameter("groupcode");
        int[] machineIds = MachineIds.from(request);

        int status = 400;
        String message = "Unexpected server error occurred, please check your transaction";

        if (isBlank(strName)) {
            message = "Please enter an item name.";
        } else {
            strName = strName.trim();
            strGroup = strGroup != null ? strGroup.trim().toUpperCase() : null;

            DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
            try (Connection con = dbConnection.getConnection()) {
                con.setAutoCommit(false);
                try {
                    ItemDAO itemDAO = new ItemDAO(con);
                    if (itemDAO.findDuplicate(new Item(strName)) != null) {
                        message = "Failed to create. The item name already exists.";
                    } else {
                        Item newItem = new Item(strName, strGroup);
                        if (itemDAO.create(newItem) != null) {
                            itemDAO.replaceMachines(newItem.getItemId(), machineIds);
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

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
