package com.ipmssys.loadingplan.controller;

import java.io.IOException;
import java.sql.Connection;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.ipmssys.configuration.GlobalVariables;
import com.ipmssys.connection.DBConnectionDataSource;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.ipmssys.loadingplan.dao.LoadingPlanFractionPlotDAO;
import com.ipmssys.loadingplan.dao.LoadingPlanItemPriorityDAO;
import com.ipmssys.loadingplan.dao.LoadingPlanOverrideDAO;
import com.ipmssys.loadingplan.model.LoadingPlanFractionPlot;
import com.ipmssys.loadingplan.model.LoadingPlanItemPriority;
import com.ipmssys.loadingplan.model.LoadingPlanOverride;
import com.ipmssys.loadingplan.model.LoadingPlanRow;
import com.ipmssys.loadingplan.service.LoadingPlanService;
import com.ipmssys.item.dao.ItemDAO;
import com.ipmssys.item.model.Item;
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

@WebServlet("/loadingplan/l")
public class ComputeLoadingPlanServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // GET params:
    //   planId           — PLAN_ID (required)
    //   useConvertedCapa — "true" or "false" (optional, default false)
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json;charset=UTF-8");

        String planIdParam  = request.getParameter("planid");
        if (planIdParam == null) { planIdParam = request.getParameter("planId"); }
        String useConvParam = request.getParameter("useConvertedCapa");

        if (isBlank(planIdParam)) {
            response.setStatus(400);
            response.getWriter().write("planId is required.");
            return;
        }

        int planId;
        try {
            planId = Integer.parseInt(planIdParam.trim());
        } catch (NumberFormatException e) {
            response.setStatus(400);
            response.getWriter().write("Invalid planId.");
            return;
        }

        // Default ON (converted capa) when the param is absent — planner workflow choice.
        boolean useConvertedCapa = isBlank(useConvParam)
                ? true
                : "true".equalsIgnoreCase(safe(useConvParam));

        DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);

        try (Connection con = dbConnection.getConnection()) {
            MonthlyPlanDAO         planDAO     = new MonthlyPlanDAO(con);
            MachineAllocationDAO   allocDAO    = new MachineAllocationDAO(con);
            PreconditionRawDAO     rawDAO      = new PreconditionRawDAO(con);
            PlottingSummaryDAO     plotDAO     = new PlottingSummaryDAO(con);
            ItemDAO                itemDAO     = new ItemDAO(con);

            MonthlyPlan       plan       = planDAO.get(planId);
            MachineAllocation allocation = allocDAO.getFullByPlanId(planId);

            if (plan == null) {
                response.setStatus(404);
                response.getWriter().write("Monthly plan not found.");
                return;
            }

            List<PreconditionRaw> rawList      = rawDAO.getByPlanId(planId);
            PreconditionService   preService   = new PreconditionService();
            java.util.Map<String, Integer> saggeredLots =
                new com.ipmssys.saggering.dao.SaggeringDAO(con).getMonthlyLotsByItemName(planId);
            List<Precondition>    preconditions = preService.compute(rawList, plan, saggeredLots);

            List<Item>            saggeredItems = itemDAO.listAll();

            List<PlottingSummary> plottingList  = plotDAO.listByMonthYear(
                plan.getPlanMonth().getMonthValue(),
                plan.getPlanMonth().getYear()
            );

            List<LoadingPlanOverride>     overrides      = new LoadingPlanOverrideDAO(con).getByPlanId(planId);
            List<LoadingPlanFractionPlot> fractionPlots  = new LoadingPlanFractionPlotDAO(con).getByPlanId(planId);
            List<LoadingPlanItemPriority> itemPriorities = new LoadingPlanItemPriorityDAO(con).getByPlanId(planId);

            LoadingPlanService  service = new LoadingPlanService();
            List<LoadingPlanRow> rows   = service.compute(
                plan, allocation, preconditions, saggeredItems,
                plottingList, overrides, fractionPlots, itemPriorities, useConvertedCapa
            );

            Gson gson = new GsonBuilder().serializeNulls().create();
            response.setStatus(200);
            response.getWriter().write(gson.toJson(rows));

        } catch (Exception e) {
            log("ComputeLoadingPlanServlet error — planId=" + planIdParam, e);
            response.setStatus(500);
            response.getWriter().write("Server error while computing loading plan.");
        }
    }

    private boolean isBlank(String value) { return value == null || value.trim().isEmpty(); }
    private String  safe(String value)    { return value == null ? "" : value; }
}