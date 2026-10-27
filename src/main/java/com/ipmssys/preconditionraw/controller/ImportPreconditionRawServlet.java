package com.ipmssys.preconditionraw.controller;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.SQLException;
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

import com.ipmssys.configuration.GlobalVariables;
import com.ipmssys.connection.DBConnectionDataSource;
import com.ipmssys.item.dao.ItemDAO;
import com.ipmssys.item.model.Item;
import com.ipmssys.preconditionraw.dao.PreconditionRawDAO;
import com.ipmssys.preconditionraw.model.PreconditionRaw;

/**
 * Imports Precondition Raw inputs for a plan from an Excel (.xlsx) file.
 *
 * Template sheet "DB": header on row 6 (index 5), data from row 7. Columns are
 * matched by header name (Item, Cap code, Internal, G dummy, (BLK/LOT), (Kpcs),
 * (sec/sheet), Lot/batch, (%), lots/month). Each row's Item name is resolved to
 * an ITEM_ID (the row is skipped if the item is not registered). Rows whose item
 * already has a raw row for this plan are skipped and reported; the rest are
 * inserted in one transaction.
 *
 * Response: 200 + plain summary on success, 400 + plain message on failure.
 */
@WebServlet("/preconditionraw/i")
@MultipartConfig
public class ImportPreconditionRawServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private static final String TARGET_SHEET      = "DB";
    private static final int    HEADER_ROW_INDEX  = 5;   // row 6
    private static final int    DATA_START_INDEX  = 6;   // row 7

    private static final String COL_ITEM           = "Item";
    private static final String COL_CAPCODE        = "Cap code";
    private static final String COL_INTERNAL       = "Internal";
    private static final String COL_DUMMY          = "G dummy";
    private static final String COL_BLK_PER_LOT    = "(BLK/LOT)";
    private static final String COL_KPCS           = "(Kpcs)";
    private static final String COL_SEC_PER_SHT    = "(sec/sheet)";
    private static final String COL_LOTS_PER_BATCH = "Lot/batch";
    private static final String COL_EFF            = "(%)";
    private static final String COL_LOTS_PER_MONTH = "lots/month";

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/plain;charset=UTF-8");

        Part   filePart    = request.getPart("file");
        String planIdParam = request.getParameter("planId");

        if (filePart == null || filePart.getSize() == 0) {
            sendError(response, "No file uploaded. Please select an Excel file.");
            return;
        }
        Integer planId = parseInt(planIdParam);
        if (planId == null) {
            sendError(response, "Plan ID is required.");
            return;
        }

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);

        try (Connection con = dbConnection.getConnection();
             InputStream is = filePart.getInputStream();
             Workbook workbook = new XSSFWorkbook(is)) {

            con.setAutoCommit(false);

            PreconditionRawDAO prDAO = new PreconditionRawDAO(con);

            // Resolve item names to ids (ipmssys stores the FK, not the name).
            Map<String, Integer> itemIdMap = new HashMap<>();
            for (Item it : new ItemDAO(con).listAll()) {
                if (it.getItemName() != null) {
                    itemIdMap.put(it.getItemName().trim().toUpperCase(), it.getItemId());
                }
            }

            Sheet sheet = workbook.getSheet(TARGET_SHEET);
            if (sheet == null) {
                sendError(response, "Sheet \"" + TARGET_SHEET + "\" not found in the uploaded file. "
                        + "Please use the official Precondition Raw template.");
                return;
            }

            DataFormatter    formatter = new DataFormatter();
            FormulaEvaluator evaluator = workbook.getCreationHelper().createFormulaEvaluator();

            Map<String, Integer> columnMap = mapHeaders(sheet.getRow(HEADER_ROW_INDEX), formatter);
            Integer itemCol = columnMap.get(COL_ITEM);
            if (itemCol == null) {
                sendError(response, "Could not find the \"" + COL_ITEM + "\" column in the header row. "
                        + "Please ensure the template has not been modified.");
                return;
            }

            int          imported       = 0;
            List<String> duplicateItems = new ArrayList<>();
            List<String> unknownItems   = new ArrayList<>();

            for (int i = DATA_START_INDEX; i <= sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i);
                if (row == null || isRowBlank(row, formatter, evaluator)) {
                    continue;
                }
                String itemValue = getCellValue(row, itemCol, formatter, evaluator);
                if (isBlank(itemValue)) {
                    break; // first empty item = end of data
                }
                String itemKey = itemValue.trim().toUpperCase();

                Integer itemId = itemIdMap.get(itemKey);
                if (itemId == null) {
                    unknownItems.add(itemValue.trim());
                    continue;
                }

                PreconditionRaw pr = new PreconditionRaw();
                pr.setPlanId(planId);
                Item item = new Item();
                item.setItemId(itemId);
                item.setItemName(itemKey);
                pr.setItem(item);

                pr.setCapCode(getCellValue(row, columnMap.get(COL_CAPCODE), formatter, evaluator));
                pr.setInternalSheet(parseSafeInt(getCellValue(row, columnMap.get(COL_INTERNAL), formatter, evaluator)));
                pr.setDummySheet(parseSafeInt(getCellValue(row, columnMap.get(COL_DUMMY), formatter, evaluator)));
                pr.setBlkPerLot(parseSafeInt(getCellValue(row, columnMap.get(COL_BLK_PER_LOT), formatter, evaluator)));
                pr.setKpcsPerLot(parseSafeDouble(getCellValue(row, columnMap.get(COL_KPCS), formatter, evaluator), false));
                pr.setSecPerSht(parseSafeDouble(getCellValue(row, columnMap.get(COL_SEC_PER_SHT), formatter, evaluator), false));
                pr.setLotsPerBatch(parseSafeInt(getCellValue(row, columnMap.get(COL_LOTS_PER_BATCH), formatter, evaluator)));
                pr.setEff(parseSafeDouble(getCellValue(row, columnMap.get(COL_EFF), formatter, evaluator), true)); // % -> decimal
                pr.setLotsPerMonth(parseSafeInt(getCellValue(row, columnMap.get(COL_LOTS_PER_MONTH), formatter, evaluator)));

                // Skip items that already have a raw row for this plan.
                if (prDAO.findDuplicate(pr) != null) {
                    duplicateItems.add(itemKey);
                    continue;
                }
                if (prDAO.create(pr) == null) {
                    con.rollback();
                    sendError(response, "Import failed while saving a row. Transaction rolled back. "
                            + "Please check the file for invalid or unexpected data.");
                    return;
                }
                imported++;
            }

            if (imported == 0 && duplicateItems.isEmpty() && unknownItems.isEmpty()) {
                con.rollback();
                sendError(response, "No data rows found in the sheet.");
                return;
            }
            if (imported == 0 && duplicateItems.isEmpty()) {
                // only unknown items
                con.rollback();
                sendError(response, "Import skipped — none of the items in this file are registered in Item "
                        + "maintenance: " + buildItemListSummary(unknownItems)
                        + ". Add those items first, then re-import.");
                return;
            }

            con.commit();

            StringBuilder msg = new StringBuilder();
            msg.append(imported).append(" row(s) imported successfully.");
            if (!duplicateItems.isEmpty()) {
                msg.append(" ").append(duplicateItems.size())
                   .append(" item(s) already existed for this plan and were skipped: ")
                   .append(buildItemListSummary(duplicateItems)).append(".");
            }
            if (!unknownItems.isEmpty()) {
                msg.append(" ").append(unknownItems.size())
                   .append(" item(s) were not found in Item maintenance and were skipped: ")
                   .append(buildItemListSummary(unknownItems)).append(".");
            }

            response.setStatus(200);
            response.getWriter().write(msg.toString());

        } catch (SQLException e) {
            e.printStackTrace();
            sendError(response, "Import failed — a database error occurred. "
                    + "One or more items may already exist for this plan.");
        } catch (Exception e) {
            e.printStackTrace();
            sendError(response, "Server error while reading the Excel file. "
                    + "Please ensure the file is a valid .xlsx using the official template.");
        }
    }

    // ------------------------------------------------------------------ //
    //  Excel helpers
    // ------------------------------------------------------------------ //

    private Map<String, Integer> mapHeaders(Row headerRow, DataFormatter formatter) {
        Map<String, Integer> columnMap = new HashMap<>();
        if (headerRow != null) {
            for (Cell cell : headerRow) {
                String val = formatter.formatCellValue(cell).trim();
                if (!val.isEmpty()) {
                    columnMap.put(val, cell.getColumnIndex());
                }
            }
        }
        return columnMap;
    }

    private String getCellValue(Row row, Integer colIdx, DataFormatter formatter, FormulaEvaluator evaluator) {
        if (colIdx == null || row == null) {
            return "";
        }
        Cell cell = row.getCell(colIdx);
        return (cell == null) ? "" : formatter.formatCellValue(cell, evaluator).trim();
    }

    private boolean isRowBlank(Row row, DataFormatter formatter, FormulaEvaluator evaluator) {
        for (Cell cell : row) {
            if (!formatter.formatCellValue(cell, evaluator).trim().isEmpty()) {
                return false;
            }
        }
        return true;
    }

    private int parseSafeInt(String value) {
        try {
            if (isBlank(value)) {
                return 0;
            }
            return (int) Double.parseDouble(value.replace(",", "").trim());
        } catch (Exception e) {
            return 0;
        }
    }

    // isPercentage: when true and value > 1, divide by 100 so it is stored as a decimal.
    private double parseSafeDouble(String value, boolean isPercentage) {
        try {
            if (isBlank(value)) {
                return 0.0;
            }
            String cleaned = value.replace(",", "").replace("%", "").trim();
            double result  = Double.parseDouble(cleaned);
            if (isPercentage && result > 1.0) {
                return result / 100.0;
            }
            return result;
        } catch (Exception e) {
            return 0.0;
        }
    }

    private String buildItemListSummary(List<String> items) {
        int max = 10;
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < items.size() && i < max; i++) {
            if (i > 0) { sb.append(", "); }
            sb.append(items.get(i));
        }
        if (items.size() > max) {
            sb.append(", and ").append(items.size() - max).append(" more");
        }
        return sb.toString();
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
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
        response.setStatus(400);
        response.getWriter().write(message);
    }
}
