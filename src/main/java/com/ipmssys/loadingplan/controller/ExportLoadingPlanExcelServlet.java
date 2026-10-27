package com.ipmssys.loadingplan.controller;

import java.io.IOException;
import java.io.OutputStream;
import java.sql.Connection;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.poi.ss.usermodel.BorderStyle;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.HorizontalAlignment;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xssf.usermodel.XSSFCellStyle;
import org.apache.poi.xssf.usermodel.XSSFColor;
import org.apache.poi.ss.usermodel.IndexedColorMap;
import org.apache.poi.xssf.usermodel.DefaultIndexedColorMap;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import com.ipmssys.configuration.GlobalVariables;
import com.ipmssys.connection.DBConnectionDataSource;
import com.ipmssys.item.dao.ItemDAO;
import com.ipmssys.item.model.Item;
import com.ipmssys.loadingplan.dao.LoadingPlanFractionPlotDAO;
import com.ipmssys.loadingplan.dao.LoadingPlanItemPriorityDAO;
import com.ipmssys.loadingplan.dao.LoadingPlanOverrideDAO;
import com.ipmssys.loadingplan.model.LoadingPlanFractionPlot;
import com.ipmssys.loadingplan.model.LoadingPlanItemPriority;
import com.ipmssys.loadingplan.model.LoadingPlanOverride;
import com.ipmssys.loadingplan.model.LoadingPlanRow;
import com.ipmssys.loadingplan.service.LoadingPlanService;
import com.ipmssys.machineallocation.dao.MachineAllocationDAO;
import com.ipmssys.machineallocation.model.MachineAllocation;
import com.ipmssys.monthlyplan.dao.MonthlyPlanDAO;
import com.ipmssys.monthlyplan.model.MonthlyPlan;
import com.ipmssys.plottingsummary.dao.PlottingSummaryDAO;
import com.ipmssys.plottingsummary.model.PlottingSummary;
import com.ipmssys.precondition.model.Precondition;
import com.ipmssys.precondition.service.PreconditionService;
import com.ipmssys.preconditionraw.dao.PreconditionRawDAO;
import com.ipmssys.preconditionraw.model.PreconditionRaw;
import com.ipmssys.saggering.dao.SaggeringDAO;

/**
 * Server-generated .xlsx of the final Loading Plan — the PC-submission output.
 *
 * Recomputes the exact same grid the screen shows (via LoadingPlanService) and
 * writes it as a spreadsheet matching the Excel '4. Loading Plan' layout:
 *   FRST MACHINE | ITEM | GROUP | MAX CAPA | CAPA W/ CONV | day 1 .. day N
 * Manual cell-status flags are rendered as cell fills in the Excel legend
 * colours (purple = NEEDS CONVERSION, etc.).
 *
 * GET /loadingplan/export?planId=X[&useConvertedCapa=true]
 */
@WebServlet("/loadingplan/export")
public class ExportLoadingPlanExcelServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    // Excel legend colours (ARGB hex, no leading #)
    private static final Map<String, String> STATUS_RGB = new HashMap<String, String>();
    static {
        STATUS_RGB.put("PM",               "FFFF00");
        STATUS_RGB.put("TROUBLE",          "C00000");
        STATUS_RGB.put("EVALUATION",       "66FF66");
        STATUS_RGB.put("ADVANCE",          "FFCCFF");
        STATUS_RGB.put("ME_IMPROVEMENT",   "CC99FF");
        STATUS_RGB.put("NEEDS_CONVERSION", "7030A0");
        STATUS_RGB.put("OK_SUBMITTED",     "92D050");
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String planIdParam = request.getParameter("planId");
        if (planIdParam == null) { planIdParam = request.getParameter("planid"); }
        if (isBlank(planIdParam)) {
            response.setStatus(400);
            response.getWriter().write("planId is required.");
            return;
        }
        int planId;
        try { planId = Integer.parseInt(planIdParam.trim()); }
        catch (NumberFormatException e) {
            response.setStatus(400);
            response.getWriter().write("Invalid planId.");
            return;
        }
        // Default ON (converted capa) when the param is absent — matches the screen default.
        String convParam = request.getParameter("useConvertedCapa");
        boolean useConvertedCapa = (convParam == null || convParam.trim().isEmpty())
                ? true
                : "true".equalsIgnoreCase(convParam.trim());

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
        try (Connection con = dbConnection.getConnection()) {

            MonthlyPlanDAO planDAO = new MonthlyPlanDAO(con);
            MonthlyPlan    plan    = planDAO.get(planId);
            if (plan == null) {
                response.setStatus(404);
                response.getWriter().write("Monthly plan not found.");
                return;
            }

            // --- Same input assembly as /loadingplan/l (identical numbers) ---
            MachineAllocation allocation = new MachineAllocationDAO(con).getFullByPlanId(planId);
            List<PreconditionRaw> rawList = new PreconditionRawDAO(con).getByPlanId(planId);
            Map<String, Integer> saggeredLots = new SaggeringDAO(con).getMonthlyLotsByItemName(planId);
            List<Precondition> preconditions = new PreconditionService().compute(rawList, plan, saggeredLots);
            List<Item> saggeredItems = new ItemDAO(con).listAll();
            List<PlottingSummary> plottingList = new PlottingSummaryDAO(con).listByMonthYear(
                plan.getPlanMonth().getMonthValue(), plan.getPlanMonth().getYear());
            List<LoadingPlanOverride>     overrides      = new LoadingPlanOverrideDAO(con).getByPlanId(planId);
            List<LoadingPlanFractionPlot> fractionPlots  = new LoadingPlanFractionPlotDAO(con).getByPlanId(planId);
            List<LoadingPlanItemPriority> itemPriorities = new LoadingPlanItemPriorityDAO(con).getByPlanId(planId);

            List<LoadingPlanRow> rows = new LoadingPlanService().compute(
                plan, allocation, preconditions, saggeredItems,
                plottingList, overrides, fractionPlots, itemPriorities, useConvertedCapa);

            YearMonth ym = YearMonth.from(plan.getPlanMonth());
            int daysInMonth = ym.lengthOfMonth();
            int year  = ym.getYear();
            int month = ym.getMonthValue();

            // --- Build the workbook ---
            try (XSSFWorkbook wb = new XSSFWorkbook()) {
                Sheet sheet = wb.createSheet("Loading Plan");
                final IndexedColorMap colorMap = new DefaultIndexedColorMap();

                // Styles
                XSSFCellStyle headStyle = (XSSFCellStyle) wb.createCellStyle();
                Font headFont = wb.createFont();
                headFont.setBold(true);
                headFont.setColor(org.apache.poi.ss.usermodel.IndexedColors.WHITE.getIndex());
                headStyle.setFont(headFont);
                headStyle.setFillForegroundColor(new XSSFColor(hex("0F5A47"), colorMap));
                headStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);
                headStyle.setAlignment(HorizontalAlignment.CENTER);
                border(headStyle);

                XSSFCellStyle titleStyle = (XSSFCellStyle) wb.createCellStyle();
                Font titleFont = wb.createFont();
                titleFont.setBold(true);
                titleFont.setFontHeightInPoints((short) 13);
                titleStyle.setFont(titleFont);

                XSSFCellStyle textStyle = (XSSFCellStyle) wb.createCellStyle();
                border(textStyle);

                XSSFCellStyle numStyle = (XSSFCellStyle) wb.createCellStyle();
                border(numStyle);
                numStyle.setAlignment(HorizontalAlignment.CENTER);

                // Pre-build one fill style per status (reused across cells)
                Map<String, CellStyle> statusStyles = new HashMap<String, CellStyle>();
                for (Map.Entry<String, String> e : STATUS_RGB.entrySet()) {
                    XSSFCellStyle st = (XSSFCellStyle) wb.createCellStyle();
                    border(st);
                    st.setAlignment(HorizontalAlignment.CENTER);
                    st.setFillForegroundColor(new XSSFColor(hex(e.getValue()), colorMap));
                    st.setFillPattern(FillPatternType.SOLID_FOREGROUND);
                    if ("TROUBLE".equals(e.getKey()) || "NEEDS_CONVERSION".equals(e.getKey())) {
                        Font wf = wb.createFont();
                        wf.setColor(org.apache.poi.ss.usermodel.IndexedColors.WHITE.getIndex());
                        st.setFont(wf);
                    }
                    statusStyles.put(e.getKey(), st);
                }

                int r = 0;

                // Title row
                Row titleRow = sheet.createRow(r++);
                Cell t = titleRow.createCell(0);
                String[] monthNames = {"January","February","March","April","May","June",
                    "July","August","September","October","November","December"};
                t.setCellValue("Loading Plan — " + monthNames[month - 1] + " " + year);
                t.setCellStyle(titleStyle);
                sheet.addMergedRegion(new CellRangeAddress(0, 0, 0, 6));
                r++; // blank spacer row

                // Header row
                int headerRowIdx = r++;
                Row hr = sheet.createRow(headerRowIdx);
                String[] fixedCols = { "FRST MACHINE", "ITEM", "GROUP", "MAX CAPA", "CAPA W/ CONV" };
                int c = 0;
                for (; c < fixedCols.length; c++) {
                    Cell cell = hr.createCell(c);
                    cell.setCellValue(fixedCols[c]);
                    cell.setCellStyle(headStyle);
                }
                for (int d = 1; d <= daysInMonth; d++) {
                    Cell cell = hr.createCell(c++);
                    cell.setCellValue(d + "-" + shortMonth(month));
                    cell.setCellStyle(headStyle);
                }

                // Data rows
                for (LoadingPlanRow row : rows) {
                    if (row.getItemName() == null) { continue; }
                    Row dr = sheet.createRow(r++);
                    int col = 0;
                    put(dr, col++, nz(row.getMachineName()), textStyle);
                    put(dr, col++, row.getItemName(), textStyle);
                    put(dr, col++, nz(row.getGroupCode()), numStyle);
                    putNum(dr, col++, round2(row.getMaxCapaLotsPerDay()), numStyle);
                    putNum(dr, col++, round2(row.getConvCapaLotsPerDay()), numStyle);

                    for (int d = 1; d <= daysInMonth; d++) {
                        int val = row.getDayValue(d);
                        String status = row.getCellStatus(d);
                        Cell cell = dr.createCell(col++);
                        if (val > 0) { cell.setCellValue(val); }
                        CellStyle st = (status != null && statusStyles.containsKey(status))
                            ? statusStyles.get(status) : numStyle;
                        cell.setCellStyle(st);
                    }
                }

                // Freeze the header + first two columns; size columns
                sheet.createFreezePane(2, headerRowIdx + 1);
                sheet.setColumnWidth(0, 14 * 256);
                sheet.setColumnWidth(1, 22 * 256);
                sheet.setColumnWidth(2, 8 * 256);
                sheet.setColumnWidth(3, 11 * 256);
                sheet.setColumnWidth(4, 13 * 256);
                for (int d = 0; d < daysInMonth; d++) { sheet.setColumnWidth(5 + d, 6 * 256); }

                // Stream the file
                String fname = "Loading_Plan_" + year + "_" + String.format("%02d", month) + ".xlsx";
                response.setContentType(
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
                response.setHeader("Content-Disposition", "attachment; filename=\"" + fname + "\"");
                try (OutputStream out = response.getOutputStream()) {
                    wb.write(out);
                    out.flush();
                }
            }

        } catch (Exception e) {
            log("ExportLoadingPlanExcelServlet error — planId=" + planIdParam, e);
            response.setStatus(500);
            response.setContentType("text/plain");
            response.getWriter().write("Server error while exporting loading plan.");
        }
    }

    // ---- helpers ----
    private static void put(Row row, int col, String val, CellStyle style) {
        Cell c = row.createCell(col); c.setCellValue(val); c.setCellStyle(style);
    }
    private static void putNum(Row row, int col, double val, CellStyle style) {
        Cell c = row.createCell(col); c.setCellValue(val); c.setCellStyle(style);
    }
    private static void border(XSSFCellStyle s) {
        s.setBorderTop(BorderStyle.THIN); s.setBorderBottom(BorderStyle.THIN);
        s.setBorderLeft(BorderStyle.THIN); s.setBorderRight(BorderStyle.THIN);
    }
    private static byte[] hex(String rgb) {
        return new byte[] {
            (byte) Integer.parseInt(rgb.substring(0, 2), 16),
            (byte) Integer.parseInt(rgb.substring(2, 4), 16),
            (byte) Integer.parseInt(rgb.substring(4, 6), 16)
        };
    }
    private static double round2(double v) { return Math.round(v * 100.0) / 100.0; }
    private static String nz(String s) { return s == null ? "" : s; }
    private static boolean isBlank(String s) { return s == null || s.trim().isEmpty(); }
    private static String shortMonth(int m) {
        String[] s = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"};
        return s[m - 1];
    }
}
