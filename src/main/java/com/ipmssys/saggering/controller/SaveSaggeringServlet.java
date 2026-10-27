package com.ipmssys.saggering.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.ipmssys.configuration.GlobalVariables;
import com.ipmssys.connection.DBConnectionDataSource;
import com.ipmssys.item.model.Item;
import com.ipmssys.saggering.dao.SaggeringDAO;
import com.ipmssys.saggering.model.Saggering;
import com.ipmssys.saggering.model.SaggeringDay;
import com.ipmssys.saggering.model.SaggeringItem;

/**
 * Saves (rewrites) the whole saggering tree for a plan.
 *
 * Parameters:
 *   planid   int
 *   items    JSON array:
 *     [{ "itemId": 1, "capCode": "X", "lotsPerBatch": 3,
 *        "days": [{ "planDate": "2026-10-01", "value": 2 }, ...] }, ...]
 */
@WebServlet("/saggering/s")
public class SaveSaggeringServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int status = 400;
        String message = "Unexpected server error occurred, please check your transaction";

        Integer planId = parseInt(request.getParameter("planid"));
        String itemsJson = request.getParameter("items");

        if (planId == null) {
            message = "Missing plan reference.";
        } else {
            List<SaggeringItem> items;
            try {
                items = parseItems(itemsJson);
            } catch (Exception e) {
                items = null;
            }

            if (items == null) {
                message = "Invalid saggering data.";
            } else if (items.isEmpty()) {
                message = "At least one item is required.";
            } else {
                // Status ACTIVE after a successful save (matches the pipeline:
                // a saggering plan that has been saved is active for the plan).
                Saggering saggering = new Saggering(planId, "ACTIVE");
                saggering.setItems(items);

                DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
                try (Connection con = dbConnection.getConnection()) {
                    con.setAutoCommit(false);
                    try {
                        new SaggeringDAO(con).saveForPlan(saggering);
                        con.commit();
                        status = 200;
                        message = "Saggering plan saved successfully.";
                    } catch (SQLException e) {
                        con.rollback();
                        throw e;
                    }
                } catch (Exception e) {
                    // Surface the real cause instead of a generic message, so a
                    // schema/constraint error is visible to the planner.
                    e.printStackTrace();
                    status = 500;
                    message = "Failed to save saggering plan: " + e.getMessage();
                }
            }
        }

        response.setStatus(status);
        response.setContentType("text/plain");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(message);
    }

    private List<SaggeringItem> parseItems(String json) {
        List<SaggeringItem> list = new ArrayList<>();
        if (json == null || json.trim().isEmpty()) {
            return list;
        }
        JsonElement root = JsonParser.parseString(json);
        if (!root.isJsonArray()) {
            return list;
        }
        JsonArray arr = root.getAsJsonArray();
        for (JsonElement el : arr) {
            JsonObject o = el.getAsJsonObject();

            SaggeringItem item = new SaggeringItem();
            Item it = new Item();
            if (!o.has("itemId") || o.get("itemId").isJsonNull()) {
                throw new IllegalArgumentException("Each item must have an itemId.");
            }
            it.setItemId(o.get("itemId").getAsInt());
            item.setItem(it);
            item.setCapCode(o.has("capCode") && !o.get("capCode").isJsonNull()
                    ? o.get("capCode").getAsString() : null);
            item.setLotsPerBatch(o.has("lotsPerBatch") && !o.get("lotsPerBatch").isJsonNull()
                    ? o.get("lotsPerBatch").getAsInt() : 0);

            List<SaggeringDay> days = new ArrayList<>();
            if (o.has("days") && o.get("days").isJsonArray()) {
                for (JsonElement de : o.get("days").getAsJsonArray()) {
                    JsonObject d = de.getAsJsonObject();
                    String dateStr = d.has("planDate") && !d.get("planDate").isJsonNull()
                            ? d.get("planDate").getAsString() : null;
                    int value = d.has("value") && !d.get("value").isJsonNull()
                            ? d.get("value").getAsInt() : 0;
                    if (dateStr != null && value != 0) {
                        days.add(new SaggeringDay(LocalDate.parse(dateStr), value));
                    }
                }
            }
            item.setDays(days);
            list.add(item);
        }
        return list;
    }

    private Integer parseInt(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        try {
            return Integer.valueOf(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
