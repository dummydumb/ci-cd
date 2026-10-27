package com.ipmssys.saggering.controller;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.FormulaEvaluator;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.ipmssys.configuration.GlobalVariables;
import com.ipmssys.connection.DBConnectionDataSource;
import com.ipmssys.item.dao.ItemDAO;
import com.ipmssys.item.model.Item;
import com.ipmssys.preconditionraw.dao.PreconditionRawDAO;
import com.ipmssys.preconditionraw.model.PreconditionRaw;

/**
 * Parses an uploaded saggering Excel template and returns the parsed rows as
 * JSON for the matrix to populate. Does NOT save — the planner reviews, then
 * saves via /saggering/s.
 *
 * Template layout (sheet "SAGGERING"): a header row with an "ITEM" column,
 * followed by up to 31 day columns. Each data row is one item with its day
 * values. capCode / lotsPerBatch are auto-filled from PRECONDITION_RAW for the
 * plan; itemId is resolved against ITEM so the row can be saved with its FK.
 *
 * Response: 200 + JSON { items:[{itemId,itemName,capCode,lotsPerBatch,days:[..],
 * missingPrecondition, unknownItem}], skipped:[...] }, or 400 + plain error.
 */
@WebServlet("/saggering/i")
@MultipartConfig
public class ImportSaggeringServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private static final String TARGET_SHEET = "SAGGERING";
    private static final int HEADER_ROW_INDEX = 3;  // row 4
    private static final int DATA_START_INDEX = 5;  // row 6
    private static final int MAX_DAYS = 31;
    private static final String COL_ITEM = "ITEM";

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        Part filePart = request.getPart("file");
        String planIdParam = request.getParameter("planid");

        if (filePart == null || filePart.getSize() == 0) {
            sendError(response, "No file uploaded. Please select the saggering import Excel file.");
            return;
        }
        Integer planId = parseInt(planIdParam);
        if (planId == null) {
            sendError(response, "Plan ID is required.");
            return;
        }

        // Lookups: precondition by item name, and item id by item name.
        Map<String, PreconditionRaw> preMap = new HashMap<>();
        Map<String, Integer> itemIdMap = new HashMap<>();

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {
            List<PreconditionRaw> prList = new PreconditionRawDAO(con).getByPlanId(planId);
            for (PreconditionRaw pr : prList) {
                if (pr.getItem() != null && pr.getItem().getItemName() != null) {
                    preMap.put(pr.getItem().getItemName().trim().toUpperCase(), pr);
                }
            }
            for (Item it : new ItemDAO(con).listAll()) {
                if (it.getItemName() != null) {
                    itemIdMap.put(it.getItemName().trim().toUpperCase(), it.getItemId());
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            sendError(response, "Server error loading reference data: " + e.getMessage());
            return;
        }

        List<Map<String, Object>> result = new ArrayList<>();
        List<String> skipped = new ArrayList<>();

        try (InputStream is = filePart.getInputStream();
             Workbook workbook = new XSSFWorkbook(is)) {

            Sheet sheet = workbook.getSheet(TARGET_SHEET);
            if (sheet == null) {
                sendError(response, "Sheet \"" + TARGET_SHEET + "\" not found. "
                        + "Please use the official Saggering import template.");
                return;
            }

            DataFormatter formatter = new DataFormatter();
            FormulaEvaluator evaluator = workbook.getCreationHelper().createFormulaEvaluator();

            Row headerRow = sheet.getRow(HEADER_ROW_INDEX);
            int itemColIdx = findItemColumn(headerRow, formatter, evaluator);
            if (itemColIdx < 0) {
                sendError(response, "Could not find the \"ITEM\" column in the header row. "
                        + "Please ensure the template has not been modified.");
                return;
            }
            int dayStartCol = itemColIdx + 1;

            int imported = 0;
            for (int rowIdx = DATA_START_INDEX; rowIdx <= sheet.getLastRowNum(); rowIdx++) {
                Row row = sheet.getRow(rowIdx);
                if (row == null || isRowBlank(row, formatter, evaluator)) {
                    continue;
                }
                String rawItem = getCellValue(row, itemColIdx, formatter, evaluator).trim();
                if (rawItem.isEmpty()) {
                    break;
                }
                String itemKey = rawItem.toUpperCase();

                List<Integer> days = new ArrayList<>();
                for (int d = 0; d < MAX_DAYS; d++) {
                    String cellVal = getCellValue(row, dayStartCol + d, formatter, evaluator).trim();
                    days.add(parseSafeInt(cellVal));
                }

                PreconditionRaw pre = preMap.get(itemKey);
                Integer itemId = itemIdMap.get(itemKey);

                Map<String, Object> entry = new HashMap<>();
                entry.put("itemId", itemId);
                entry.put("itemName", itemKey);
                entry.put("capCode", pre != null ? pre.getCapCode() : "");
                entry.put("lotsPerBatch", pre != null ? pre.getLotsPerBatch() : 0);
                entry.put("days", days);
                entry.put("missingPrecondition", pre == null);
                entry.put("unknownItem", itemId == null);
                result.add(entry);

                if (pre == null || itemId == null) {
                    skipped.add(rawItem);
                }
                imported++;
            }

            if (imported == 0) {
                sendError(response, "No data rows found. Make sure the template has data below the header "
                        + "and the ITEM column is not empty.");
                return;
            }

            Map<String, Object> body = new HashMap<>();
            body.put("items", result);
            body.put("skipped", skipped);

            Gson gson = new GsonBuilder().serializeNulls().create();
            response.setContentType("application/json;charset=UTF-8");
            response.setStatus(200);
            response.getWriter().write(gson.toJson(body));

        } catch (Exception e) {
            e.printStackTrace();
            sendError(response, "Server error while reading the Excel file. "
                    + "Please ensure the file is a valid .xlsx.");
        }
    }

    // ------------------------------------------------------------------ //
    //  Helpers
    // ------------------------------------------------------------------ //

    private int findItemColumn(Row headerRow, DataFormatter fmt, FormulaEvaluator eval) {
        if (headerRow == null) {
            return -1;
        }
        for (Cell cell : headerRow) {
            String val = fmt.formatCellValue(cell, eval).trim().toUpperCase();
            if (COL_ITEM.equals(val)) {
                return cell.getColumnIndex();
            }
        }
        return -1;
    }

    private String getCellValue(Row row, int colIdx, DataFormatter fmt, FormulaEvaluator eval) {
        if (row == null || colIdx < 0) {
            return "";
        }
        Cell cell = row.getCell(colIdx);
        return cell != null ? fmt.formatCellValue(cell, eval).trim() : "";
    }

    private boolean isRowBlank(Row row, DataFormatter fmt, FormulaEvaluator eval) {
        for (Cell cell : row) {
            if (!fmt.formatCellValue(cell, eval).trim().isEmpty()) {
                return false;
            }
        }
        return true;
    }

    private int parseSafeInt(String value) {
        try {
            if (value == null || value.trim().isEmpty()) {
                return 0;
            }
            return (int) Double.parseDouble(value.replace(",", "").replace("%", "").trim());
        } catch (Exception e) {
            return 0;
        }
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

    private void sendError(HttpServletResponse response, String message) throws IOException {
        response.setContentType("text/plain;charset=UTF-8");
        response.setStatus(400);
        response.getWriter().write(message);
    }
}
