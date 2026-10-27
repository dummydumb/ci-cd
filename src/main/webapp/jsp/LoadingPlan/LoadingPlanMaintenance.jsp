<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Loading Plan</title>
    <%@include file="/Utilities/links.jsp" %>

    <style>
        body { font-family: 'FSEmericLight', Helvetica, 'Segoe UI', sans-serif; background:#f4f6f3; }
        .btn-primary { background:#0f5a47; border-color:#0f5a47; }
        .btn-primary:hover { background:#0c4a3b; border-color:#0c4a3b; }
        .lp-plan { height: 40px; min-width: 260px; padding: 0 12px; border: 1px solid #cfd8d2; border-radius: 8px; background:#fff; font: inherit; }
        .navigation .nav .nav-item:nth-child(1) { font-weight:600; position:relative; }
        .navigation .nav .nav-item:nth-child(1)::after {
            bottom:0; content:""; display:block; height:0.2rem;
            left:0; opacity:1; position:absolute; background:#28282B; width:100%;
        }

        .content_table {
            background:#ffffff; border-radius:12px;
            box-shadow:0 4px 15px rgba(0,0,0,0.05); padding-bottom:14px;
        }

        /* ── Summary cards ── */
        .loading-summary-card {
            background:#fff; border:1px solid #e5e7eb; border-radius:10px;
            padding:9px 10px; box-shadow:0 4px 12px rgba(15,23,42,0.04);
        }
        .loading-summary-label { color:#64748b; font-size:10px; text-transform:uppercase; font-weight:800; letter-spacing:.04em; }
        .loading-summary-value { color:#111827; font-size:18px; font-weight:900; line-height:1.1; }

        /* Validation banner (Excel "HAVE FALSE" output check) */
        .lp-recon { display:flex; align-items:center; gap:10px; border-radius:10px; padding:10px 16px; margin:0 1rem 12px; font-weight:700; font-size:13px; }
        .lp-recon-ok  { background:#e3efe9; color:#0f5a47; border:1px solid #b9d6c8; }
        .lp-recon-bad { background:#fdecea; color:#a32a1f; border:1px solid #f0c9c3; }
        .lp-recon .lp-recon-detail { font-weight:500; opacity:.9; }

        /* ── Table ── */
        .loading-plan-table th,
        .loading-plan-table td { border:1px solid #111827 !important; text-align:center; vertical-align:middle; white-space:nowrap; }
        .loading-plan-table th {
            background-color:#1f3b6d !important; color:#ffffff !important;
            font-weight:800; text-transform:uppercase; font-size:10px;
            letter-spacing:0.02em; padding:5px 4px !important;
        }
        .loading-plan-table tbody td { font-size:11px; padding:4px 5px !important; }

        .machine-plan-group-header td {
            background:#dbeafe !important; color:#1e3a8a !important;
            font-weight:900 !important; text-align:left !important;
            padding:6px 10px !important; border-top:3px solid #1e3a8a !important;
        }

        /* Role colours */
        .loading-role-fix       { background:#061cff !important; color:#fff !important; font-weight:900; }
        .loading-role-fraction  { background:#7c3aed !important; color:#fff !important; font-weight:900; }
        .loading-role-qualified { background:#64748b !important; color:#fff !important; font-weight:900; }
        .loading-role-unalloc   { background:#dc2626 !important; color:#fff !important; font-weight:900; }
        .loading-machine   { background:#f8fafc !important; font-weight:800; }
        .loading-item      { background:#061cff !important; color:#fff !important; font-weight:800; text-align:left !important; }
        .loading-group     { background:#f8fafc !important; font-weight:800; }
        .loading-capa      { background:#fef3c7 !important; font-weight:800; }
        .loading-day-total { background:#e0f2fe !important; font-weight:900; }

        .loading-date-cell { min-width:42px; max-width:58px; background:#fff !important; font-weight:700; padding:2px !important; }

        .loading-warning td { background:#fee2e2 !important; }
        .loading-warning .loading-item { background:#dc2626 !important; color:#fff !important; }
        .loading-qualified-only td { background:#f8fafc !important; color:#64748b !important; }
        .loading-qualified-only .loading-item { background:#e5e7eb !important; color:#111827 !important; }

        /* ── Maintenance cells ── */
        .loading-maint-cell {
            width:100%; min-height:32px; border-radius:4px; padding:3px 4px;
            color:#000; font-size:11px; line-height:14px; text-align:center;
            font-weight:900; border:1px solid rgba(17,24,39,0.45);
        }
        .loading-maint-value-only { font-size:12px; font-weight:900; line-height:22px; }
        .loading-maint-empty      { font-size:11px; line-height:22px; color:rgba(0,0,0,0.15); }

        /* ── Reassign: source — reason drives colour ── */
        .cell-reason-trouble    { background:#fee2e2 !important; border:2px solid #ef4444 !important; }
        .cell-reason-unplanned  { background:#ffedd5 !important; border:2px solid #f97316 !important; }
        .cell-reason-other      { background:#f3f4f6 !important; border:2px solid #9ca3af !important; }

        /* ── Reassign: target — blue ── */
        .cell-reassigned        { background:#dbeafe !important; border:2px solid #3b82f6 !important; }

        /* ── Recovery: source — pink, original value kept ── */
        .cell-recovery-source   { background:#fce7f3 !important; border:2px solid #ec4899 !important; }

        /* ── Conversion day — fraction machine switching items (incoming first day) ── */
        .cell-conversion-day    { border:2px solid #ec4899 !important; outline:2px dashed #be185d; outline-offset:-4px; }

        /* ── Conversion source — outgoing item's last day before machine switches ── */
        .cell-conversion-source { background:#f3e8ff !important; border:2px solid #ec4899 !important; }

        /* ── Manual cell-status flags — match the Excel '4. Loading Plan' colour legend ──
           Planner-applied (not auto). Purple #7030A0 = NEEDS CONVERSION. ── */
        .cell-status-pm             { background:#FFFF00 !important; }                     /* PM — yellow */
        .cell-status-trouble        { background:#C00000 !important; color:#fff !important; } /* Machine/Quality Trouble — dark red */
        .cell-status-evaluation     { background:#66FF66 !important; }                     /* Evaluation — green */
        .cell-status-advance        { background:#FFCCFF !important; }                     /* Advance to Prev Month — pink */
        .cell-status-me-improvement { background:#CC99FF !important; }                     /* ME Improvement — light purple */
        .cell-status-needs-conversion { background:#7030A0 !important; color:#fff !important; } /* NEEDS CONVERSION — purple */
        .cell-status-ok-submitted   { background:#92D050 !important; }                     /* OK, submitted to PC — light green */

        /* ── Recovery: target — green ── */
        .cell-recovery-target   { background:#d1fae5 !important; border:2px solid #059669 !important; }

        /* ── Rerouted: source — value was cut by maintenance, excess sent elsewhere ── */
        .cell-rerouted-source   { background:#fef3c7 !important; border:2px solid #92400e !important; }

        /* ── Rerouted: target — received excess from another machine's maintenance ── */
        .cell-rerouted-target   { background:#fdf4e7 !important; border:2px solid #b45309 !important; }

        /* ── Manual edit — amber border ── */
        .cell-manual-edit       { border:2px solid #f59e0b !important; background:#fffbeb !important; }

        /* ── Has remarks — dotted pink outline on top of any state ── */
        .cell-has-remarks       { outline:2px dotted #be185d !important; outline-offset:-2px; }

        /* ── Unallocated row — incomplete Machine Allocation ── */
        tr.loading-unallocated-row td { background:#fff5f5 !important; border-left:4px solid #dc2626 !important; }
        tr.loading-unallocated-row td:first-child::before {
            content: "⚠ Incomplete allocation";
            display: block; font-size: 10px; color: #dc2626; font-weight: 700;
        }
        .day-cell-editable:hover { outline:2px dashed #1f3b6d !important; }

        /* ── Extended fraction plot — light purple background on extended days ── */
        .cell-fraction-extended { background:#f3e8ff !important; border:1px dashed #7c3aed !important; }

        /* ── Fraction plot button on row ── */
        .btn-fraction-plot { font-size:10px; padding:1px 6px; border-radius:4px;
                             background:#f3e8ff; color:#5b21b6; border:1px solid #7c3aed; cursor:pointer; }
        .btn-fraction-plot:hover { background:#7c3aed; color:#fff; }

        /* ── Machine label badge — shown next to machine name for labelled machines ── */
        .machine-label-badge {
            display:inline-block; font-size:10px; font-weight:600;
            padding:1px 6px; border-radius:4px; margin-left:4px;
            background:#fef9c3; color:#713f12; border:1px solid #fbbf24;
            vertical-align:middle; letter-spacing:0.3px;
        }

        /* ── Reassigned role badge ── */
        .badge-reassigned { background:#2563eb !important; color:#fff !important; }

        /* ── Item priority drag list ── */
        .priority-item {
            display:flex; align-items:center; gap:10px;
            padding:8px 12px; margin-bottom:6px; border-radius:6px;
            background:#f8fafc; border:1px solid #e2e8f0; cursor:grab;
            font-size:13px; font-weight:600; user-select:none;
        }
        .priority-item:active { cursor:grabbing; opacity:.85; }
        .priority-item .seq-badge {
            min-width:22px; height:22px; border-radius:50%;
            background:#1f3b6d; color:#fff; font-size:11px;
            display:flex; align-items:center; justify-content:center;
        }
        .priority-item .drag-handle { color:#9ca3af; font-size:14px; }
        .priority-item.drag-over { border:2px dashed #1f3b6d; background:#eff6ff; }

        /* Inner div fills the full cell so colour is visible */
        /* ── Cell state icon — Font Awesome 5, top-right corner of inner div ── */
        .cell-state-icon {
            position:absolute; top:1px; right:2px;
            font-size:7px; line-height:1; pointer-events:none;
        }
        .loading-date-value { position:relative; display:block; width:100%; min-height:24px; padding:2px 3px; text-align:center; font-weight:700; font-size:12px; line-height:20px; }

        /* ── Last production day marker — border only, no hiding ── */
        .loading-date-cell.last-prod-day  { border-right:3px solid #f59e0b !important; }
        /* beyond-prod-day — subtle header tint only, content stays fully visible */
        .loading-date-cell.beyond-prod-day th { background:#f8fafc !important; }

        /* Legend dot */
        .legend-dot { display:inline-block; width:13px; height:13px; border-radius:3px; margin-right:3px; vertical-align:middle; }

        /* Machine type badges */
        .badge-machine-type    { font-size:.68rem; font-weight:800; text-transform:uppercase; letter-spacing:.04em; padding:2px 9px; border-radius:6px; }
        .badge-machine-frst    { background:rgba(16,185,129,.15); color:#065f46; border:1px solid rgba(16,185,129,.35); }
        .badge-machine-gsx     { background:rgba(59,130,246,.15);  color:#1d4ed8; border:1px solid rgba(59,130,246,.35); }
        .badge-machine-default { background:rgba(100,116,139,.12); color:#475569; border:1px solid rgba(100,116,139,.25); }

        .btn-emerald-outline { color:#065f46; background:#fff; border:1px solid #d1fae5; }
        .swal2-html-container { overflow:unset !important; }
        .swal2-actions { z-index:0; }
        .warning-text  { color:#b91c1c; font-weight:800; }

        /* =====================================================================
           PRINT / PC-SUBMIT VIEW
           Produces a clean paper / PDF of the final Loading Plan grid:
           hides all app chrome and the per-cell edit affordances, keeps the
           grid and its status colours, and repeats the header on each page.
           ===================================================================== */
        .print-only { display: none; }
        @media print {
            @page { size: A4 landscape; margin: 10mm; }

            /* Preserve the cell background colours (status/maintenance) on paper */
            * { -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; }

            /* Hide everything that is not the plan grid */
            header, nav, .navbar, .navigation,
            #btnBack, .row.mb-2, .lp-recon, .loading-summary-cards,
            #exportExcel, #btnPrint, #recalculatePlan, #btnWipTracker,
            .btn-reassign-machine, .btn-recovery-machine, .btn-item-priority,
            .btn-fraction-plot, .btn-set-fraction-plot,
            .dataTables_paginate, .dataTables_length, .dataTables_filter,
            .dataTables_info, .dt-buttons {
                display: none !important;
            }

            body { background: #fff !important; }
            .content, .content_container, .content_table {
                margin: 0 !important; padding: 0 !important; box-shadow: none !important; border: 0 !important;
            }

            /* Show the print-only caption */
            .print-only { display: block !important; text-align: center; margin: 0 0 8px; }
            #printTitle { font-size: 15px; font-weight: 800; }
            #printSub   { font-size: 11px; color: #333; }

            /* The grid itself */
            .table-responsive { overflow: visible !important; }
            table.loading-plan-table {
                width: 100% !important; font-size: 8px !important; border-collapse: collapse !important;
            }
            table.loading-plan-table th, table.loading-plan-table td {
                border: 0.5px solid #999 !important; padding: 1px 2px !important;
            }
            table.loading-plan-table thead { display: table-header-group; }  /* repeat header each page */
            table.loading-plan-table tr    { page-break-inside: avoid; }

            /* Neutralise hover/edit cursors in print */
            .day-cell-editable, .loading-date-value { cursor: default !important; }
        }
    </style>
</head>

<body>
<%@include file="/Utilities/Header.jsp" %>

<div class="content">
    <div class="d-flex align-items-center mx-2 mb-2">
        <a id="btnBack" href="${pageContext.request.contextPath}/monthlyplanner"
           class="btn btn-emerald-outline d-flex align-items-center gap-2 fw-semibold shadow-sm text-decoration-none">
            <i class="fa-solid fa-arrow-left"></i> Back
        </a>
    </div>

    <div class="content_container container-fluid">
        <div class="content_table pb-3">

            <div class="row text-center pt-2">
                <h2 class="mb-2"><b id="pageTitle">Loading Plan</b></h2>
            </div>

            <!-- Print-only caption (shown only when printing / saving PDF) -->
            <div class="print-only">
                <div id="printTitle">Loading Plan</div>
                <div id="printSub"></div>
            </div>

            <div class="row mb-2 mx-0 px-4">
                <div class="col d-flex align-items-center gap-2">
                    <label for="planSelect" class="fw-semibold" style="color:#55635d;">Plan:</label>
                    <select class="lp-plan" id="planSelect"><option value="">Select a monthly plan</option></select>
                </div>
            </div>

            <!-- Toolbar -->
            <div class="row mb-2 mx-0 px-3">
                <div class="col d-flex align-items-center gap-2">
                    <div class="form-check mb-0">
                        <input class="form-check-input" type="checkbox" id="useConvertedCapa" checked>
                        <label class="form-check-label fw-bold small" for="useConvertedCapa">Use Converted CAPA</label>
                    </div>
                </div>
                <div class="col d-flex justify-content-end align-items-center gap-2">
                    <button class="btn btn-sm btn-outline-success" id="btnWipTracker">
                        <i class="fa-solid fa-chart-line me-1"></i>WIP Tracker
                    </button>
                    <button class="btn btn-sm btn-dark" id="exportExcel"><i class="fa-solid fa-file-excel"></i> Export Excel</button>
                    <button class="btn btn-sm btn-outline-dark" id="btnPrint"><i class="fa-solid fa-print"></i> Print / PDF</button>
                    <button class="btn btn-sm btn-dark" id="recalculatePlan"><i class="fa-solid fa-calculator"></i> Recalculate</button>
                </div>
            </div>

            <!-- Legend -->
            <div class="row mb-2 mx-0 px-3">
                <div class="col-12">
                    <div class="d-flex flex-wrap gap-3 align-items-center py-2 px-3 border rounded bg-light" style="font-size:11px;">
                        <b>Maintenance:</b>
                        <span><span class="legend-dot" style="background:#FFFF00;border:1px solid #ccc;"></span>PM</span>
                        <span><span class="legend-dot" style="background:#66FF66;border:1px solid #ccc;"></span>Evaluation</span>
                        <span><span class="legend-dot" style="background:#B78DE1;border:1px solid #ccc;"></span>ME Improvement</span>
                        <b class="ms-2">Reassign:</b>
                        <span><span class="legend-dot" style="background:#dbeafe;border:2px solid #3b82f6;"></span><i class="fas fa-arrow-right" style="font-size:9px;color:#1d4ed8;"></i> Reassigned (target)</span>
                        <span><span class="legend-dot" style="background:#fee2e2;border:2px solid #ef4444;"></span><i class="fas fa-triangle-exclamation" style="font-size:9px;color:#dc2626;"></i> Machine Trouble</span>
                        <span><span class="legend-dot" style="background:#ffedd5;border:2px solid #f97316;"></span><i class="fas fa-triangle-exclamation" style="font-size:9px;color:#f97316;"></i> Unplanned Maintenance</span>
                        <span><span class="legend-dot" style="background:#f3f4f6;border:2px solid #9ca3af;"></span><i class="fas fa-circle-minus" style="font-size:9px;color:#9ca3af;"></i> Other</span>
                        <b class="ms-2">Recovery:</b>
                        <span><span class="legend-dot" style="background:#ffedd5;border:2px solid #f97316;"></span><i class="fas fa-clock-rotate-left" style="font-size:9px;color:#c2410c;"></i> Recovery source</span>
                        <span><span class="legend-dot" style="background:#d1fae5;border:2px solid #059669;"></span><i class="fas fa-check" style="font-size:9px;color:#065f46;"></i> Recovery target</span>
                        <span><span class="legend-dot" style="background:#fce7f3;border:2px solid #ec4899;"></span><i class="fas fa-comment" style="font-size:9px;color:#be185d;"></i> Has remarks</span>
                        <span><span class="legend-dot" style="border:2px solid #f59e0b;background:#fffbeb;"></span><i class="fas fa-pen" style="font-size:9px;color:#b45309;"></i> Manual edit</span>
                        <span><span class="legend-dot" style="background:#fdf4e7;border:2px solid #b45309;"></span> Rerouted here (received)</span>
                        <span><span class="legend-dot" style="background:#fef3c7;border:2px solid #92400e;"></span> Rerouted away (cut by maintenance)</span>
                        <span><span style="border-right:3px solid #f59e0b;padding-right:4px;">&nbsp;</span> Last prod day</span>
                        <span><span class="legend-dot" style="background:#f3e8ff;border:1px dashed #7c3aed;"></span> Extended fraction plot</span>
                        <b class="ms-2">Manual status (Excel):</b>
                        <span><span class="legend-dot" style="background:#7030A0;"></span> Needs Conversion</span>
                        <span><span class="legend-dot" style="background:#FFFF00;"></span> PM</span>
                        <span><span class="legend-dot" style="background:#C00000;"></span> Trouble</span>
                        <span><span class="legend-dot" style="background:#66FF66;"></span> Evaluation</span>
                        <span><span class="legend-dot" style="background:#FFCCFF;"></span> Advance to prev. month</span>
                        <span><span class="legend-dot" style="background:#CC99FF;"></span> ME Improvement</span>
                        <span><span class="legend-dot" style="background:#92D050;"></span> OK - submitted to PC</span>
                        <span class="ms-2 fw-bold"><i class="fa-solid fa-pen me-1 text-warning"></i>Click cell to edit &nbsp;|&nbsp; <i class="fa-solid fa-right-left me-1 text-primary"></i>Reassign on machine header</span>
                    </div>
                </div>
            </div>

            <!-- Summary cards -->
            <div class="row mb-2 mx-0 px-3 g-2 loading-summary-cards">
                <div class="col"><div class="loading-summary-card"><div class="loading-summary-label">Period</div><div class="loading-summary-value" id="summaryMonth">-</div></div></div>
                <div class="col"><div class="loading-summary-card"><div class="loading-summary-label">Days</div><div class="loading-summary-value" id="summaryDays">-</div></div></div>
                <div class="col"><div class="loading-summary-card"><div class="loading-summary-label">Last Prod Day</div><div class="loading-summary-value" id="summaryLastProdDay">-</div></div></div>
                <div class="col"><div class="loading-summary-card"><div class="loading-summary-label">Items</div><div class="loading-summary-value" id="summaryItems">-</div></div></div>
                <div class="col"><div class="loading-summary-card"><div class="loading-summary-label">Machines</div><div class="loading-summary-value" id="summaryMachines">-</div></div></div>
                <div class="col"><div class="loading-summary-card"><div class="loading-summary-label">Total Lots</div><div class="loading-summary-value" id="summaryTotalLots">-</div></div></div>
                <div class="col"><div class="loading-summary-card"><div class="loading-summary-label">Edits</div><div class="loading-summary-value text-warning fw-bold" id="summaryEdits">0</div></div></div>
                <div class="col"><div class="loading-summary-card"><div class="loading-summary-label">Warnings</div><div class="loading-summary-value text-danger" id="summaryWarnings">0</div></div></div>
            </div>

            <!-- Validation banner (mirrors Excel 4.Loading Plan D2 "HAVE FALSE" check) -->
            <div id="lpReconBanner" class="lp-recon lp-recon-ok" style="display:none;"></div>

            <!-- Loading plan DataTable -->
            <div class="table-responsive px-3">
                <table id="loading_plan_table" class="table hover w-100 text-nowrap loading-plan-table">
                    <thead></thead>
                    <tbody></tbody>
                </table>
            </div>

        </div>
    </div>
</div>

<script>

    /* ─────────────────────────────────────────────────────────────
       Plan context variables — injected by LoadingPlanServlet
       ───────────────────────────────────────────────────────────── */
    var basePath    = '${pageContext.request.contextPath}';
    var preselect   = '${preselectPlanId}';
    var planId      = "";
    var planMonth   = 0;
    var planYear    = 0;
    var machineCode = "";
    var monthName   = "";

    var MONTH_SHORT = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
    var daysInMonth       = 31;
    var lastProductionDay = 31;
    var monthShort        = "";
    var PLAN_CACHE        = [];

    function planMonthParts(pm) {
        if (!pm) { return null; }
        var y, m;
        if (typeof pm === "object") {
            var srcp = pm.date ? pm.date : pm;
            y = srcp.year; m = (srcp.monthValue != null) ? srcp.monthValue : srcp.month;
        } else {
            var parts = String(pm).split("T")[0].split("-");
            y = Number(parts[0]); m = parseInt(parts[1], 10);
        }
        return { year: y, month: m };
    }

    function loadPlans() {
        $.ajax({
            type: "GET", url: basePath + "/monthlyplan/l", dataType: "json",
            success: function (plans) {
                PLAN_CACHE = plans || [];
                var sel = $("#planSelect");
                $.each(PLAN_CACHE, function (i, pl) {
                    var p = planMonthParts(pl.planMonth);
                    var label = (p ? (MONTH_SHORT[p.month - 1] + " " + p.year) : "")
                              + " \u2014 " + (pl.machineCode || "");
                    sel.append('<option value="' + pl.planId + '">' + label + '</option>');
                });
                if (preselect) { sel.val(preselect); }
                setPlanFromSelection(sel.val());
                if (planId) { loadLoadingPlan(); }
            }
        });
    }

    function setPlanFromSelection(value) {
        planId = value || "";
        planMonth = 0; planYear = 0; machineCode = ""; monthName = ""; monthShort = "";
        var plan = null;
        for (var i = 0; i < PLAN_CACHE.length; i++) {
            if (String(PLAN_CACHE[i].planId) === String(planId)) { plan = PLAN_CACHE[i]; break; }
        }
        if (plan) {
            var p = planMonthParts(plan.planMonth);
            if (p) { planMonth = p.month; planYear = p.year; monthName = MONTH_SHORT[p.month - 1]; monthShort = MONTH_SHORT[p.month - 1]; }
            machineCode = plan.machineCode || "";
        }
        daysInMonth = (planYear && planMonth) ? new Date(planYear, planMonth, 0).getDate() : 31;
        lastProductionDay = daysInMonth;
        $("#pageTitle").html("Loading Plan &mdash; " + monthName + " " + planYear + (machineCode ? buildMachineTypeBadge(machineCode) : ""));
    }

    var loadingPlanTable = null;
    var lastLoadingRows  = [];
    var fractionPlotMap  = {}; // "MACHINE|ITEM" -> {plotStart,plotEnd,totalLots}
    var itemPriorityMap  = {}; // "MACHINE" -> ["ITEM_A","ITEM_B",...] in order
    var _loadDebounce    = null; // debounce timer for loadLoadingPlan

    // Machine display labels — shown in the UI alongside the machine name.
    // The machine name (e.g. "F23") is always the data identifier used for
    // all DB keys, AJAX params, and conflict checks. The label is display only.
    var machineLabels = {
        "F24": "RECOVERY B",
        "F26": "RECOVERY A"
    };

    function getMachineLabel(machineName) {
        if (!machineName) { return ""; }
        var label = machineLabels[machineName.toUpperCase()] || machineLabels[machineName];
        return label ? label : "";
    }

    function getMachineDisplay(machineName) {
        var label = getMachineLabel(machineName);
        return label ? machineName + " \u2014 " + label : machineName;
    }

    /* ─────────────────────────────────────────────────────────────
       General helpers
       ───────────────────────────────────────────────────────────── */
    function showLoadingScreen() {
        Swal.fire({
            title: '<span style="color:#28282B;font-size:22px;font-weight:600;">Please wait...</span>',
            html: '<div class="spinner"></div>',
            allowOutsideClick: false, showConfirmButton: false
        });
    }

    function pad2(n)     { return n < 10 ? "0" + n : "" + n; }
    function fmtNum(v)   { var n = Number(v); return isNaN(n) ? "" : n.toFixed(2); }
    function fmtWhole(v) { var n = Number(v); return (isNaN(n)||v===null||v==="") ? "" : n.toFixed(0); }
    function fmt3(v)     { var n = Number(v); return (isNaN(n)||v===null||v==="") ? "" : n.toFixed(3); }
    function escHtml(v)  {
        return String(v).replace(/&/g,"&amp;").replace(/</g,"&lt;")
                        .replace(/>/g,"&gt;").replace(/"/g,"&quot;").replace(/'/g,"&#039;");
    }
    function buildDateStr(d) { return planYear + "-" + pad2(planMonth) + "-" + pad2(d); }

    function buildMachineTypeBadge(code) {
        if (!code) { return ""; }
        var upper = code.trim().toUpperCase();
        var cls = upper === "FRST" ? "badge-machine-frst"
                : upper === "GSX"  ? "badge-machine-gsx"
                : "badge-secondary";
        return ' <span class="badge ' + cls + ' ms-2">' + escHtml(upper) + '</span>';
    }

    /* ─────────────────────────────────────────────────────────────
       Row data accessors
       ───────────────────────────────────────────────────────────── */
    function getDayValue(row, day) {
        if (!row || !row.dayValues) { return 0; }
        var v = row.dayValues[day];
        return (v !== undefined && v !== null) ? Number(v) : 0;
    }
    function getOriginalDayValue(row, day) {
        if (row && row.originalDayValues && row.originalDayValues[day] !== undefined) {
            return Number(row.originalDayValues[day]);
        }
        return getDayValue(row, day);
    }
    function getMaintHours(row, day) {
        if (!row || !row.maintenanceHours) { return 0; }
        var v = row.maintenanceHours[day];
        return (v !== undefined && v !== null) ? Number(v) : 0;
    }
    function getMaintType(row, day) { return (row && row.maintenanceTypes) ? (row.maintenanceTypes[day] || "") : ""; }
    function getMaintPic(row,  day) { return (row && row.maintenancePics)  ? (row.maintenancePics[day]  || "") : ""; }
    function getMaintColor(type) {
        if (type === "PM")             { return "#FFFF00"; }
        if (type === "Evaluation")     { return "#66FF66"; }
        if (type === "ME Improvement") { return "#B78DE1"; }
        return "#FFFF00";
    }

    /* ─────────────────────────────────────────────────────────────
       Override state accessors
       ───────────────────────────────────────────────────────────── */
    function isOverridden(row, day)    { return !!(row && row.overriddenFlags    && row.overriddenFlags[day]); }
    function isReassigned(row, day)    { return !!(row && row.reassignedFlags    && row.reassignedFlags[day]); }
    function isRecoverySource(row,day) { return !!(row && row.recoverySourceFlags && row.recoverySourceFlags[day]); }
    function isRecoveryTarget(row,day) { return !!(row && row.recoveryTargetFlags && row.recoveryTargetFlags[day]); }
    function getReassignReason(row, day) { return (row && row.reassignReasons) ? (row.reassignReasons[day] || "") : ""; }
    function getRemarks(row, day)        { return (row && row.remarksMap)      ? (row.remarksMap[day]      || "") : ""; }
    function getReroutedSource(row, day) { return (row && row.reroutedSourceFlags) ? (row.reroutedSourceFlags[day] || 0) : 0; }
    function getReroutedTarget(row, day) { return (row && row.reroutedTargetFlags) ? (row.reroutedTargetFlags[day] || 0) : 0; }
    function isConversionDay(row, day)    { return !!(row && row.conversionDayFlags    && row.conversionDayFlags[day]); }
    function isConversionSource(row, day) { return !!(row && row.conversionSourceFlags && row.conversionSourceFlags[day]); }

    // Manual Excel-style cell status (planner-applied). Returns one of
    // NONE/PM/TROUBLE/EVALUATION/ADVANCE/ME_IMPROVEMENT/NEEDS_CONVERSION/OK_SUBMITTED.
    function getCellStatus(row, day) {
        if (row && row.cellStatusByDay && row.cellStatusByDay[day]) { return row.cellStatusByDay[day]; }
        return "NONE";
    }
    function cellStatusClass(status) {
        switch (status) {
            case "PM":               return " cell-status-pm";
            case "TROUBLE":          return " cell-status-trouble";
            case "EVALUATION":       return " cell-status-evaluation";
            case "ADVANCE":          return " cell-status-advance";
            case "ME_IMPROVEMENT":   return " cell-status-me-improvement";
            case "NEEDS_CONVERSION": return " cell-status-needs-conversion";
            case "OK_SUBMITTED":     return " cell-status-ok-submitted";
            default:                 return "";
        }
    }
    var CELL_STATUS_LABEL = {
        PM: "PM (planned maintenance)",
        TROUBLE: "Machine / Quality Trouble",
        EVALUATION: "Evaluation",
        ADVANCE: "Advance to Previous Month",
        ME_IMPROVEMENT: "ME Improvement",
        NEEDS_CONVERSION: "Needs Conversion",
        OK_SUBMITTED: "OK - Already submitted to PC"
    };

    // Cell state priority: recovery target > recovery source > reassign target >
    //                      reassign source > manual edit >
    //                      rerouted target > rerouted source > conversion day
    // Override states always win. Conversion day is additive via TD class in drawCallback.
    function getCellStateClass(row, day) {
        if (isRecoveryTarget(row, day))  { return "cell-recovery-target"; }
        if (isRecoverySource(row, day))  { return "cell-recovery-source"; }
        if (isReassigned(row, day))      { return "cell-reassigned"; }
        var reason = getReassignReason(row, day);
        if (reason === "MACHINE_TROUBLE")       { return "cell-reason-trouble"; }
        if (reason === "UNPLANNED_MAINTENANCE") { return "cell-reason-unplanned"; }
        if (reason === "OTHER")                 { return "cell-reason-other"; }
        if (isOverridden(row, day))      { return "cell-manual-edit"; }
        if (getReroutedTarget(row, day) > 0) { return "cell-rerouted-target"; }
        if (getReroutedSource(row, day) > 0) { return "cell-rerouted-source"; }
        return "";
    }

    /* ─────────────────────────────────────────────────────────────
       Extended fraction plot helpers
       ───────────────────────────────────────────────────────────── */
    // Converts a Gson-serialized LocalDate (object or string) to "YYYY-MM-DD"
    // for use in <input type="date"> value attributes.
    function toDateInputStr(d) {
        if (!d) { return ""; }
        if (typeof d === "string") { return d.substring(0, 10); }
        // Gson serializes LocalDate as { year:N, monthValue:N, dayOfMonth:N }
        return d.year + "-" + pad2(d.monthValue) + "-" + pad2(d.dayOfMonth);
    }

    function isFractionExtendedDay(machineName, itemName, day) {
        var key  = machineName + "|" + itemName;
        var plot = fractionPlotMap[key];
        if (!plot || !plot.plotStart || !plot.plotEnd) { return false; }

        var cd = new Date(planYear, planMonth - 1, day);

        // plotStart and plotEnd arrive from Gson as LocalDate objects:
        // { year:2026, monthValue:5, dayOfMonth:1 } — not strings.
        // Build Date objects from those fields directly.
        var ps, pe;
        if (typeof plot.plotStart === "string") {
            ps = new Date(plot.plotStart.replace(/-/g, "/"));
        } else {
            ps = new Date(plot.plotStart.year, plot.plotStart.monthValue - 1, plot.plotStart.dayOfMonth);
        }
        if (typeof plot.plotEnd === "string") {
            pe = new Date(plot.plotEnd.replace(/-/g, "/"));
        } else {
            pe = new Date(plot.plotEnd.year, plot.plotEnd.monthValue - 1, plot.plotEnd.dayOfMonth);
        }

        return cd >= ps && cd <= pe;
    }

    /* ─────────────────────────────────────────────────────────────
       Cell renderer
       ───────────────────────────────────────────────────────────── */
    function renderDayCell(row, day) {
        var value      = getDayValue(row, day);
        var maintHours = getMaintHours(row, day);
        var maintType  = getMaintType(row, day);
        var dateStr    = buildDateStr(day);
        var remarks    = getRemarks(row, day);
        var orig       = getOriginalDayValue(row, day);
        var display    = (value > 0 || isOverridden(row, day)) ? value : "";

        var attrs = 'data-day="' + day + '" data-date="' + dateStr + '" '
                  + 'data-machine="' + escHtml(row.machineName || "") + '" '
                  + 'data-item="'    + escHtml(row.itemName    || "") + '" '
                  + 'data-original="' + orig + '"';

        // Maintenance cell
        if (maintHours > 0) {
            var maintCapped = Math.min(maintHours, 24);
            var remaining   = (24 - maintCapped).toFixed(1);
            var maintColor  = getMaintColor(maintType);
            var maintPic    = getMaintPic(row, day);
            var tipText = "\uD83D\uDD27 Maintenance \u2014 " + (maintType || "Unspecified")
                        + "\nMachine: "    + (row.machineName || "")
                        + " \u2502 Item: " + (row.itemName    || "")
                        + "\nDowntime: "   + maintCapped + "h  \u2502  Remaining: " + remaining + "h"
                        + "\nPIC: "        + (maintPic || "Unassigned")
                        + (display !== "" ? "\nLots today: " + display : "");
            return '<div class="loading-maint-cell" style="background-color:' + maintColor + ';" '
                 + 'title="' + escHtml(tipText) + '" ' + attrs + '>'
                 + (value > 0
                     ? '<div class="loading-maint-value-only">' + display + '</div>'
                     : '<div class="loading-maint-empty">&nbsp;</div>')
                 + '</div>';
        }

        // Override / state tooltip
        var tooltip = "";
        if (isRecoveryTarget(row, day)) {
            tooltip = "\u2705 Recovery Target\nMachine: " + (row.machineName||"") + " \u2502 Item: " + (row.itemName||"")
                    + "\nLots added via converted capa: " + display
                    + (remarks ? "\nRemarks: " + remarks : "");
        } else if (isRecoverySource(row, day)) {
            tooltip = "\uD83D\uDFE3 Recovery Source \u2014 original lots kept"
                    + "\nMachine: " + (row.machineName||"") + " \u2502 Item: " + (row.itemName||"")
                    + "\nValue: " + display
                    + (remarks ? "\nRemarks: " + remarks : "");
        } else if (isReassigned(row, day)) {
            tooltip = "\u27A1 Reassigned Here\nMachine: " + (row.machineName||"") + " \u2502 Item: " + (row.itemName||"")
                    + "\nLots received: " + display
                    + (remarks ? "\nRemarks: " + remarks : "");
        } else if (getReassignReason(row, day)) {
            var rl = { "MACHINE_TROUBLE":"Machine Trouble", "UNPLANNED_MAINTENANCE":"Unplanned Maintenance", "OTHER":"Other" };
            tooltip = "\u26A0 Reassigned Away \u2014 " + (rl[getReassignReason(row,day)] || getReassignReason(row,day))
                    + "\nMachine: " + (row.machineName||"") + " \u2502 Item: " + (row.itemName||"")
                    + "\nLots moved to another machine"
                    + (remarks ? "\nRemarks: " + remarks : "");
        } else if (isOverridden(row, day)) {
            tooltip = "\u270F Manual Edit\nMachine: " + (row.machineName||"") + " \u2502 Item: " + (row.itemName||"")
                    + "\nOriginal: " + orig + "  \u2192  Current: " + display
                    + (remarks ? "\nRemarks: " + remarks : "");
        } else if (getReroutedTarget(row, day) > 0) {
            tooltip = "\uD83D\uDFE4 Rerouted Here (maintenance overflow)"
                    + "\nMachine: " + (row.machineName||"") + " \u2502 Item: " + (row.itemName||"")
                    + "\n+" + getReroutedTarget(row, day) + " lots received from another machine's maintenance cut"
                    + "\nTotal today: " + display;
        } else if (getReroutedSource(row, day) > 0) {
            tooltip = "\uD83D\uDFE4 Rerouted Away (maintenance cut)"
                    + "\nMachine: " + (row.machineName||"") + " \u2502 Item: " + (row.itemName||"")
                    + "\n" + getReroutedSource(row, day) + " lots could not run due to maintenance \u2014 rerouted to fraction/qualified machine"
                    + "\nRemaining today: " + display;
        } else if (remarks) {
            tooltip = "\uD83D\uDFE4 Rerouted Here (maintenance overflow)"
                    + "\nMachine: " + (row.machineName||"") + " \u2502 Item: " + (row.itemName||"")
                    + "\n+" + getReroutedTarget(row, day) + " lots received from another machine's maintenance cut"
                    + "\nTotal today: " + display;
        } else if (getReroutedSource(row, day) > 0) {
            tooltip = "\uD83D\uDFE4 Rerouted Away (maintenance cut)"
                    + "\nMachine: " + (row.machineName||"") + " \u2502 Item: " + (row.itemName||"")
                    + "\n" + getReroutedSource(row, day) + " lots could not run due to maintenance — rerouted to fraction/qualified machine"
                    + "\nRemaining today: " + display;
        } else if (remarks) {
            tooltip = "\uD83D\uDCAC " + remarks;
        }

        // Extended fraction highlight
        var extCls = (row.machineRole === "Fraction" && isFractionExtendedDay(row.machineName, row.itemName, day))
            ? " cell-fraction-extended" : "";

        // Conversion source — outgoing item's last day before machine switches
        var convSrcCls = isConversionSource(row, day) ? " cell-conversion-source" : "";
        if (isConversionSource(row, day)) {
            var srcNote = "\n\n\uD83D\uDD04 Last day before item switch on this fraction machine."
                        + "\nThe next running day on this machine is a different item."
                        + "\nConversion/setup time will be required on the incoming item's first day.";
            tooltip = (tooltip || "") + srcNote;
        }

        // Conversion day — additive on top of any state class
        var convCls = isConversionDay(row, day) ? " cell-conversion-day" : "";
        if (isConversionDay(row, day)) {
            // Find the most accurate convCapaLotsPerDay for this machine+item:
            // prefer the allocated Fraction row over the qualified row since
            // the Fraction row has the correct precondition-derived conv capa.
            var convCapa = 0;
            $.each(lastLoadingRows, function(i, r) {
                if (r.machineName === row.machineName && r.itemName === row.itemName) {
                    if (Number(r.convCapaLotsPerDay || 0) > 0) {
                        convCapa = Number(r.convCapaLotsPerDay);
                        return false;
                    }
                }
            });
            if (convCapa === 0 && Number(row.convCapaLotsPerDay || 0) > 0) {
                convCapa = Number(row.convCapaLotsPerDay);
            }

            var convNote = "\n\n\uD83D\uDD04 Conversion Day \u2014 different item starts on this fraction machine."
                         + "\nMachine changeover required. Value may need adjustment to convCapaLotsPerDay.";
            if (convCapa > 0) {
                convNote += "\nConv capa for this item: " + convCapa.toFixed(2) + " lots/day";
                if (Number(display) > convCapa) {
                    convNote += " \u26A0 Current value exceeds conv capa \u2014 consider editing.";
                }
            } else {
                convNote += "\nConv capa: not available \u2014 check Precondition Raw EFF value.";
            }
            tooltip = (tooltip || "") + convNote;
        }

        // Manual status flag (Excel legend) — overrides the fill colour of the cell.
        var _status   = getCellStatus(row, day);
        var statusCls = cellStatusClass(_status);
        if (_status !== "NONE") {
            tooltip = (tooltip || "") + "\n\n\uD83C\uDFF7 Status: " + (CELL_STATUS_LABEL[_status] || _status)
                    + " (manually flagged)";
        }

        return '<div class="loading-date-value' + extCls + convSrcCls + convCls + statusCls + '"'
             + (tooltip ? ' title="' + escHtml(tooltip) + '"' : "")
             + ' ' + attrs + '>' + display + '</div>';
    }

    /* ─────────────────────────────────────────────────────────────
       Sort rows — machine order, then role priority, then item name
       ───────────────────────────────────────────────────────────── */
    function sortRowsByMachine(rows) {
        var rolePriority = { "Fix":1, "Fraction":2, "Unallocated":3, "Qualified":4 };
        var sorted = rows.slice();
        sorted.sort(function(a, b) {
            var ma = a.machineName || "-", mb = b.machineName || "-";
            if (ma === "-" && mb !== "-") { return 1; }
            if (mb === "-" && ma !== "-") { return -1; }
            if (ma !== mb) { return ma.localeCompare(mb); }

            // Qualified-only rows with NO value always go last
            var aEmpty = a.qualifiedOnly && a.monthTotalLots <= 0;
            var bEmpty = b.qualifiedOnly && b.monthTotalLots <= 0;
            if (aEmpty !== bEmpty) { return aEmpty ? 1 : -1; }

            // Apply planner priority if set for this machine
            var pri = itemPriorityMap[ma] || itemPriorityMap[a.machineName] || [];
            if (pri.length > 0) {
                var ia = pri.indexOf(a.itemName);
                var ib = pri.indexOf(b.itemName);
                // Both in priority list — use list order
                if (ia !== -1 && ib !== -1) { return ia - ib; }
                // Only one in list — prioritised item goes first
                if (ia !== -1) { return -1; }
                if (ib !== -1) { return  1; }
                // Neither in list — fall through to default
            }

            // Default: role priority then item name
            var pa = rolePriority[a.machineRole] || 9;
            var pb = rolePriority[b.machineRole] || 9;
            if (pa !== pb) { return pa - pb; }
            return String(a.itemName||"").localeCompare(String(b.itemName||""));
        });
        return sorted;
    }

    /* ─────────────────────────────────────────────────────────────
       Detect last production day from fraction rows
       ───────────────────────────────────────────────────────────── */
    function detectLastProductionDay(rows) {
        // Find the latest day any fraction row has a non-zero value.
        // With per-row last-day computation, different fraction rows end on
        // different days. The yellow border marks where the LAST fraction row
        // finishes — days beyond that are truly free for all fraction machines.
        var lpd = 0;
        $.each(rows, function(i, r) {
            if (r.machineRole !== "Fraction") { return true; }
            for (var d = daysInMonth; d >= 1; d--) {
                if (getDayValue(r, d) > 0) {
                    if (d > lpd) { lpd = d; }
                    break;
                }
            }
        });
        lastProductionDay = (lpd > 0) ? lpd : daysInMonth;
    }

    /* ─────────────────────────────────────────────────────────────
       Load plan — fetches fraction plots first, then plan rows
       ───────────────────────────────────────────────────────────── */
    // Debounced entry point — any code calling loadLoadingPlan() goes through here.
    // If called multiple times within 300ms (e.g. double-click, rapid saves),
    // only the last call fires. Prevents parallel AJAX races and stale data overwrites.
    // Validation — the Excel flags "HAVE FALSE" when any output cell fails its check.
    // Here: unallocated items (no machine), and any day cell exceeding the machine's
    // max capacity for that item. Shows a persistent banner instead of a transient alert.
    function renderValidation(rows) {
        var banner = $("#lpReconBanner");
        var unalloc = [];     // item names with no allocated machine
        var overCap = 0;      // cells exceeding max capa
        var overExamples = [];

        $.each(rows || [], function(i, row) {
            var role = row.machineRole || "";
            var status = row.status || "";
            if (role === "Unallocated" || status === "NO ALLOCATED MACHINE") {
                if (row.itemName) { unalloc.push(row.itemName); }
                return;
            }
            if (role === "Qualified") { return; } // zero candidate rows — not scheduled
            var maxCapa = Number(row.maxCapaLotsPerDay || 0);
            if (maxCapa <= 0) { return; }
            var cap = Math.floor(maxCapa + 0.0001);
            for (var d = 1; d <= daysInMonth; d++) {
                var v = getDayValue(row, d);
                if (v > cap) {
                    overCap++;
                    if (overExamples.length < 4) {
                        overExamples.push((row.machineName || "?") + " " + (row.itemName || "") + " D" + d + " (" + v + ">" + cap + ")");
                    }
                }
            }
        });

        var uniqUnalloc = [];
        var seen = {};
        $.each(unalloc, function(i, n) { if (!seen[n]) { seen[n] = true; uniqUnalloc.push(n); } });

        banner.removeClass("lp-recon-ok lp-recon-bad").show();

        if (uniqUnalloc.length === 0 && overCap === 0) {
            banner.addClass("lp-recon-ok").html(
                '<i class="fa-solid fa-circle-check"></i> OUTPUT VALID'
                + ' <span class="lp-recon-detail">&mdash; every item is allocated and no day exceeds machine capacity.</span>');
            return;
        }

        var parts = [];
        if (uniqUnalloc.length > 0) {
            parts.push(uniqUnalloc.length + ' item(s) have NO allocated machine: '
                + uniqUnalloc.slice(0, 6).join(", ") + (uniqUnalloc.length > 6 ? ", …" : ""));
        }
        if (overCap > 0) {
            parts.push(overCap + ' cell(s) exceed machine capacity' + (overExamples.length ? ' (e.g. ' + overExamples.join("; ") + ')' : ''));
        }
        banner.addClass("lp-recon-bad").html(
            '<i class="fa-solid fa-triangle-exclamation"></i> CHECK OUTPUT'
            + ' <span class="lp-recon-detail">&mdash; ' + parts.join(". ") + '.</span>');
    }

    function loadLoadingPlan() {
        if (!planId) { return; }
        clearTimeout(_loadDebounce);
        _loadDebounce = setTimeout(function() { _doLoadLoadingPlan(); }, 300);
    }

    function _doLoadLoadingPlan() {
        showLoadingScreen();
        var useConverted = $("#useConvertedCapa").is(":checked");

        // Load fraction plots and item priorities in parallel, then load rows
        var plotsDone    = false, prioritiesDone = false;

        function onBothDone() {
            if (plotsDone && prioritiesDone) { loadPlanRows(useConverted); }
        }

        $.ajax({
            type: "GET", url: basePath + "/loadingplan/fractionplot",
            data: { planId: planId }, dataType: "json",
            success: function(plots) {
                fractionPlotMap = {};
                $.each(plots || [], function(i, p) {
                    fractionPlotMap[p.machineName + "|" + p.itemName] = p;
                });
                plotsDone = true; onBothDone();
            },
            error: function() { fractionPlotMap = {}; plotsDone = true; onBothDone(); }
        });

        $.ajax({
            type: "GET", url: basePath + "/loadingplan/itempriority",
            data: { planId: planId, allMachines: true }, dataType: "json",
            success: function(priorities) {
                // priorities = [{machineName, itemName, prioritySeq}, ...]
                itemPriorityMap = {};
                $.each(priorities || [], function(i, p) {
                    if (!itemPriorityMap[p.machineName]) { itemPriorityMap[p.machineName] = []; }
                    itemPriorityMap[p.machineName].push(p.itemName);
                });
                prioritiesDone = true; onBothDone();
            },
            error: function() { itemPriorityMap = {}; prioritiesDone = true; onBothDone(); }
        });
    }

    function loadPlanRows(useConverted) {
        $.ajax({
            type: "GET",
            url:  basePath + "/loadingplan/l",
            data: { planId: planId, useConvertedCapa: useConverted },
            dataType: "json",
            success: function(rows) {
                lastLoadingRows = sortRowsByMachine(rows || []);
                detectLastProductionDay(lastLoadingRows);
                renderTable(lastLoadingRows);
                updateSummaryCards(lastLoadingRows);
                renderValidation(lastLoadingRows);
                Swal.close();
            },
            error: function(xhr) {
                Swal.close();
                Swal.fire({ text: xhr.responseText || "Error loading plan.", icon: "error" });
            }
        });
    }

    /* ─────────────────────────────────────────────────────────────
       DataTable rendering
       ───────────────────────────────────────────────────────────── */
    function renderTable(rows) {
        if (loadingPlanTable !== null) {
            // Update data in place — preserves scroll position, no flicker,
            // no full teardown + rebuild on every recalculate or save
            loadingPlanTable.clear();
            loadingPlanTable.rows.add(rows);
            loadingPlanTable.draw(false); // false = keep current page position
            return;
        }

        loadingPlanTable = $("#loading_plan_table").DataTable({
            ordering: false, fixedHeader: true, scrollX: true, scrollY: "50vh",
            pageLength: 100, deferRender: true, responsive: false,
            searching: true, lengthChange: false, data: rows,
            dom: '<"d-flex justify-content-between align-items-center px-2 mb-1"fB>rt<"d-flex justify-content-between align-items-center px-2 mt-1"ip>',
            buttons: [{
                extend: "excelHtml5", className: "excelButton",
                text: "Export to Excel",
                title: "Loading_Plan_" + planYear + "_" + pad2(planMonth) + "_" + new Date().getTime(),
                exportOptions: { columns: ":visible" }
            }],
            columns: buildColumns(),
            columnDefs: [{ targets: "_all", defaultContent: "", className: "text-center" }],
            createdRow: function(row, data) {
                if (data.status && data.status !== "OK") { $(row).addClass("loading-warning"); }
                if (data.qualifiedOnly) { $(row).addClass("loading-qualified-only"); }
                if (data.machineRole === "Unallocated") { $(row).addClass("loading-unallocated-row"); }
            },
            drawCallback: function() {
                var api = this.api();
                api.rows({ page: "current" }).every(function() {
                    var rowData = this.data();
                    if (!rowData) { return; }
                    var tr = $(this.node());
                    for (var d = 1; d <= daysInMonth; d++) {
                        var td = tr.find("td").has('[data-day="' + d + '"]');
                        if (!td.length) { continue; }
                        td.removeClass("cell-reason-trouble cell-reason-unplanned cell-reason-other " +
                                       "cell-reassigned cell-recovery-source cell-recovery-target " +
                                       "cell-manual-edit cell-has-remarks cell-fraction-extended " +
                                       "cell-rerouted-source cell-rerouted-target " +
                                       "cell-conversion-day cell-conversion-source " +
                                       "cell-status-pm cell-status-trouble cell-status-evaluation " +
                                       "cell-status-advance cell-status-me-improvement " +
                                       "cell-status-needs-conversion cell-status-ok-submitted");
                        var cls = getCellStateClass(rowData, d);
                        if (cls)               { td.addClass(cls); }
                        var _st = getCellStatus(rowData, d);
                        if (_st !== "NONE")    { td.addClass(cellStatusClass(_st).trim()); }
                        if (getRemarks(rowData, d)) { td.addClass("cell-has-remarks"); }
                        if (rowData.machineRole === "Fraction" &&
                            isFractionExtendedDay(rowData.machineName, rowData.itemName, d)) {
                            td.addClass("cell-fraction-extended");
                        }
                        if (isConversionSource(rowData, d)) { td.addClass("cell-conversion-source"); }
                        if (isConversionDay(rowData, d))    { td.addClass("cell-conversion-day"); }
                    }
                });
                insertMachineGroupHeaders(api);
                $(".excelButton").hide();
            }
        });

        loadingPlanTable.buttons().container().hide();
    }

    /* ─────────────────────────────────────────────────────────────
       Column definitions
       ───────────────────────────────────────────────────────────── */
    function buildColumns() {
        var base = [
            {
                title: "Type", data: "machineRole",
                render: function(data, type, row) {
                    if (type !== "display") { return data; }
                    var map = { "Fix":"badge-fix","Fraction":"badge-fraction","Qualified":"badge-qualified","Unallocated":"badge-warning" };

                    // A purely Qualified row (no allocation role) that received
                    // reassigned lots shows as "Reassigned" — it was a target only.
                    // Fix/Fraction rows that received extra lots keep their real role.
                    // Now that the service correctly assigns Fraction role to fraction
                    // machines, data === "Fraction" will already be correct here.
                    var hasValue           = row && Number(row.monthTotalLots || 0) > 0;
                    var isReassignedTarget = row && row.qualifiedOnly && hasValue && data === "Qualified";
                    var displayRole = isReassignedTarget ? "Reassigned" : (data || "");
                    var badgeCls    = isReassignedTarget ? "badge-reassigned" : (map[data] || "badge-warning");

                    var badge = '<span class="badge ' + badgeCls + '">' + escHtml(displayRole) + '</span>';
                    if (data === "Fraction" && row && row.machineName && row.itemName) {
                        var key     = row.machineName + "|" + row.itemName;
                        var hasPlot = !!fractionPlotMap[key];
                        badge += ' <button class="btn-fraction-plot ms-1 btn-set-fraction-plot" '
                               + 'data-machine="' + escHtml(row.machineName) + '" '
                               + 'data-item="'    + escHtml(row.itemName)    + '" '
                               + 'data-total="'   + (row.monthTotalLots || 0) + '" '
                               + 'data-share="'   + (row.machineShare   || 0) + '">'
                               + (hasPlot ? '<i class="fa-solid fa-chart-bar"></i> Plot'
                                          : '<i class="fa-solid fa-plus"></i> Plot')
                               + '</button>';
                    }
                    return badge;
                },
                createdCell: function(td, v) {
                    var m = { "Fix":"loading-role-fix","Fraction":"loading-role-fraction","Qualified":"loading-role-qualified","Unallocated":"loading-role-unalloc" };
                    $(td).addClass(m[v]||"loading-role-unalloc");
                }
            },
            { title: "Machine", data: "machineName", className: "loading-machine",
              render: function(data, type) {
                if (type !== "display") { return data || ""; }
                var label = getMachineLabel(data);
                return label
                    ? escHtml(data || "") + ' <span class="machine-label-badge">' + escHtml(label) + '</span>'
                    : escHtml(data || "");
              }
            },
            { title: "Item",    data: "itemName",    className: "loading-item",       render: function(d) { return escHtml(d||""); } },
            { title: "Group",   data: "groupCode",   className: "loading-group",      render: function(d) { return escHtml(d||""); } },
            { title: "Share",    data: "machineShare",      className: "loading-capa",      render: fmtNum   },
            { title: "Max Capa", data: "maxCapaLotsPerDay", className: "loading-capa",      render: fmt3     },
            { title: "Capa Con", data: "convCapaLotsPerDay",className: "loading-capa",      render: fmt3     },
            { title: "Total",    data: "monthTotalLots",    className: "loading-day-total", render: fmtWhole },
            {
                title: "Status", data: "status", className: "loading-group",
                render: function(data, type) {
                    if (type !== "display") { return data; }
                    if (!data || data === "OK") { return data||""; }
                    return '<span class="warning-text">' + escHtml(data) + '</span>';
                }
            }
        ];

        for (var day = 1; day <= daysInMonth; day++) {
            (function(d) {
                var dt    = new Date(planYear, planMonth - 1, d);
                var dName = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"][dt.getDay()];
                var isWk  = dt.getDay() === 0 || dt.getDay() === 6;

                var dayCls = "loading-date-cell day-cell-editable";
                if (isWk) { dayCls += " table-warning"; }
                if (d === lastProductionDay && lastProductionDay < daysInMonth) { dayCls += " last-prod-day"; }
                if (d >  lastProductionDay && lastProductionDay < daysInMonth)  { dayCls += " beyond-prod-day"; }

                base.push({
                    title: dName + "<br>" + d + "-" + monthShort,
                    data: null, className: dayCls, orderable: false,
                    render: function(data, type, row) {
                        if (type !== "display") { return getDayValue(row, d); }
                        return renderDayCell(row, d);
                    }
                });
            })(day);
        }

        return base;
    }

    /* ─────────────────────────────────────────────────────────────
       Machine group headers — Reassign + Recovery buttons
       ───────────────────────────────────────────────────────────── */
    function insertMachineGroupHeaders(api) {
        var tbody    = $(api.table().body());
        var rows     = api.rows({ page: "current" }).nodes();
        var data     = api.rows({ page: "current" }).data().toArray();
        var colCount = api.columns().count();

        tbody.find("tr.machine-plan-group-header").remove();

        var lastMachine = null;

        $(rows).each(function(idx) {
            var row     = data[idx];
            var machine = row ? (row.machineName || "-") : "-";

            if (machine !== lastMachine) {
                var total = 0, allocated = 0;
                $.each(data, function(j, r) {
                    if (r && r.machineName === machine) {
                        total++;
                        if (!r.qualifiedOnly) { allocated++; }
                    }
                });

                var btns = (machine !== "-")
                    ? '<button class="btn btn-sm btn-primary ms-2 py-0 px-2 btn-reassign-machine" '
                      + 'data-machine="' + escHtml(machine) + '" style="font-size:11px;">'
                      + '<i class="fa-solid fa-right-left me-1"></i>Reassign</button>'
                      + '<button class="btn btn-sm btn-success ms-1 py-0 px-2 btn-recovery-machine" '
                      + 'data-machine="' + escHtml(machine) + '" style="font-size:11px;">'
                      + '<i class="fa-solid fa-rotate-right me-1"></i>Recovery</button>'
                      + '<button class="btn btn-sm btn-secondary ms-1 py-0 px-2 btn-item-priority" '
                      + 'data-machine="' + escHtml(machine) + '" style="font-size:11px;">'
                      + '<i class="fa-solid fa-arrow-down-1-9 me-1"></i>Priority</button>'
                    : "";

                var machineDisplay = getMachineDisplay(machine);
                var headerHtml =
                    '<tr class="machine-plan-group-header">'
                  + '<td colspan="' + colCount + '">'
                  + '<i class="fa-solid fa-gears"></i> Machine: ' + escHtml(machineDisplay)
                  + ' <span class="badge bg-primary ms-2">'  + total     + ' qualified</span>'
                  + ' <span class="badge bg-success ms-1">' + allocated + ' allocated</span>'
                  + btns + '</td></tr>';

                $(this).before(headerHtml);
                lastMachine = machine;
            }
        });
    }

    /* ─────────────────────────────────────────────────────────────
       Summary cards
       ───────────────────────────────────────────────────────────── */
    function updateSummaryCards(rows) {
        var machineSet = {}, itemSet = {};
        var totalLots = 0, edits = 0, warnings = 0, convCapaFallbacks = 0;
        var unallocatedItems = []; // items where Machine Allocation is incomplete
        var useConverted = $("#useConvertedCapa").is(":checked");

        $.each(rows || [], function(i, r) {
            if (r.machineName && r.machineName !== "-") { machineSet[r.machineName] = true; }
            if (r.itemName) { itemSet[r.itemName] = true; }
            if (!r.qualifiedOnly && r.machineRole !== "Unallocated") {
                totalLots += Number(r.monthTotalLots || 0);
            }
            if (r.status && r.status !== "OK") { warnings++; }

            // Track unallocated rows — these mean Machine Allocation has an
            // incomplete fraction assignment (shares don't sum to FRACTION1_REQUIREMENT)
            if (r.machineRole === "Unallocated" && r.itemName) {
                unallocatedItems.push(r.itemName + " (" + Number(r.machineShare || 0).toFixed(2) + " MC unassigned)");
            }

            if (r.overriddenFlags)    { $.each(r.overriddenFlags,    function(d, v) { if (v) { edits++; } }); }
            if (r.recoverySourceFlags){ $.each(r.recoverySourceFlags, function(d, v) { if (v) { edits++; } }); }
            if (useConverted && !r.qualifiedOnly && r.machineRole !== "Unallocated"
                    && Number(r.convCapaLotsPerDay || 0) === 0) {
                convCapaFallbacks++;
            }
        });

        var monthNames = ["January","February","March","April","May","June",
                          "July","August","September","October","November","December"];
        $("#summaryMonth").text(monthNames[planMonth-1] + " " + planYear);
        $("#summaryDays").text(daysInMonth);
        $("#summaryLastProdDay").text(
            lastProductionDay < daysInMonth
                ? "Day " + lastProductionDay + " (last fraction)"
                : "Day " + lastProductionDay
        );
        $("#summaryItems").text(Object.keys(itemSet).length);
        $("#summaryMachines").text(Object.keys(machineSet).length);
        $("#summaryTotalLots").text(Math.floor(totalLots));
        $("#summaryEdits").text(edits);
        $("#summaryWarnings").text(warnings);

        // Unallocated warning — incomplete Machine Allocation
        if (unallocatedItems.length > 0) {
            var $uWarn = $("#unallocatedWarn");
            if (!$uWarn.length) {
                $uWarn = $('<div id="unallocatedWarn" class="alert alert-danger py-2 px-3 mb-2" style="font-size:12px;"></div>');
                $(".loading-summary-cards").after($uWarn);
            }
            $uWarn.html(
                '<i class="fa-solid fa-circle-xmark me-1"></i>'
              + '<b>' + unallocatedItems.length + ' item(s) have incomplete Machine Allocation</b> '
              + '— fraction machine shares do not sum to the required FRACTION1 requirement. '
              + 'These lots will NOT be plotted.<br>'
              + '<span class="text-danger fw-bold">' + unallocatedItems.join(", ") + '</span><br>'
              + '<small>Go to Machine Allocation and correct the fraction machine shares for these items, then recompute.</small>'
            );
        } else {
            $("#unallocatedWarn").remove();
        }

        // Converted capa fallback warning
        if (useConverted && convCapaFallbacks > 0) {
            var $warn = $("#convCapaWarn");
            if (!$warn.length) {
                $warn = $('<div id="convCapaWarn" class="alert alert-warning py-1 px-2 mb-2" style="font-size:12px;"></div>');
                $(".loading-summary-cards").after($warn);
            }
            $warn.html('<i class="fa-solid fa-triangle-exclamation me-1"></i>'
                + '<b>Converted Capa selected</b> but <b>' + convCapaFallbacks + ' row(s)</b> '
                + 'have no converted capacity data — those rows are still using Max Capa. '
                + 'Check Precondition Raw EFF values.');
        } else {
            $("#convCapaWarn").remove();
        }
    }

    /* ─────────────────────────────────────────────────────────────
       Reassign / Recovery helpers
       ───────────────────────────────────────────────────────────── */
    function getQualifiedTargetMachines(itemName, sourceMachine) {
        var machines = {}, result = [];
        $.each(lastLoadingRows, function(i, r) {
            if (!r.itemName || r.itemName !== itemName) { return; }
            if (r.machineName === sourceMachine || r.machineName === "-") { return; }
            if (machines[r.machineName]) { return; }
            machines[r.machineName] = true;
            result.push(r.machineName);
        });
        return result;
    }

    function hasRunningLots(targetMachine, itemName, dayNum) {
        var running = false;
        $.each(lastLoadingRows, function(i, r) {
            if (r.machineName === targetMachine && r.itemName === itemName && !r.qualifiedOnly) {
                if (getDayValue(r, dayNum) > 0) { running = true; return false; }
            }
        });
        return running;
    }

    /* ─────────────────────────────────────────────────────────────
       1. Manual cell edit dialog
       ───────────────────────────────────────────────────────────── */
    function openCellEditDialog(machineName, itemName, dateStr, currentValue, currentRemarks, originalValue) {
        var isEdited = (Number(currentValue) !== Number(originalValue));
        var diff     = Number(currentValue) - Number(originalValue);
        var diffHtml = (isEdited && diff !== 0)
            ? ' <span style="color:' + (diff > 0 ? "#16a34a" : "#dc2626") + ';font-size:11px;">'
              + (diff > 0 ? "+" : "") + diff + ' from computed</span>'
            : "";
        var banner = '<div class="alert py-1 px-2 mb-3 ' + (isEdited ? "alert-warning" : "alert-light border")
            + '" style="font-size:12px;"><b>Computed:</b> ' + originalValue
            + (isEdited ? ' &rarr; <b>Current:</b> ' + currentValue + diffHtml
                        : ' <span class="text-muted">(unchanged)</span>') + '</div>';

        // Determine current manual status for this cell
        var _curStatus = "NONE";
        $.each(lastLoadingRows, function(i, r) {
            if (r.machineName === machineName && r.itemName === itemName) {
                _curStatus = getCellStatus(r, extractDay(dateStr));
                return false;
            }
        });

        var _val = null, _rem = "", _status = "NONE";

        Swal.fire({
            title: '<span style="font-size:15px;">Edit Cell</span>',
            html: '<div class="text-start mt-1" style="font-size:13px;">'
                + '<div class="d-flex gap-3 mb-2 flex-wrap">'
                + '<span><b>Machine:</b> ' + escHtml(machineName) + '</span>'
                + '<span><b>Item:</b> '    + escHtml(itemName)    + '</span>'
                + '<span><b>Date:</b> '    + escHtml(dateStr)     + '</span></div>'
                + banner
                + '<div class="form-floating mb-3"><input type="number" id="swal-edit-val" '
                + 'class="form-control" value="' + escHtml(String(currentValue)) + '" min="0" step="1" placeholder="">'
                + '<label>New value (lots)</label></div>'
                + '<div class="form-floating mb-1">'
                + '<select id="swal-edit-status" class="form-select">'
                + '<option value="NONE"' + (_curStatus==="NONE"?" selected":"") + '>\u2014 No status \u2014</option>'
                + '<option value="NEEDS_CONVERSION"' + (_curStatus==="NEEDS_CONVERSION"?" selected":"") + '>Needs Conversion (purple)</option>'
                + '<option value="PM"' + (_curStatus==="PM"?" selected":"") + '>PM (yellow)</option>'
                + '<option value="TROUBLE"' + (_curStatus==="TROUBLE"?" selected":"") + '>Machine / Quality Trouble (dark red)</option>'
                + '<option value="EVALUATION"' + (_curStatus==="EVALUATION"?" selected":"") + '>Evaluation (green)</option>'
                + '<option value="ADVANCE"' + (_curStatus==="ADVANCE"?" selected":"") + '>Advance to Previous Month (pink)</option>'
                + '<option value="ME_IMPROVEMENT"' + (_curStatus==="ME_IMPROVEMENT"?" selected":"") + '>ME Improvement (light purple)</option>'
                + '<option value="OK_SUBMITTED"' + (_curStatus==="OK_SUBMITTED"?" selected":"") + '>OK - Submitted to PC (light green)</option>'
                + '</select><label>Cell status (manual flag)</label></div>'
                + '<div class="text-muted mb-3" style="font-size:11px;">'
                + 'A status is a manual colour flag only \u2014 it does not change the value. '
                + 'Leave the value as-is to flag the cell without editing it.</div>'
                + '<div class="form-floating"><textarea id="swal-edit-rem" class="form-control" '
                + 'maxlength="500" placeholder="" style="height:70px;">'
                + escHtml(currentRemarks || "") + '</textarea>'
                + '<label>Remarks <span class="text-danger">*</span></label></div></div>',
            showCancelButton: true,
            showDenyButton:   isEdited || (_curStatus !== "NONE"),
            confirmButtonText: '<i class="fa-solid fa-floppy-disk me-1"></i>Save',
            denyButtonText:    isEdited
                ? '<i class="fa-solid fa-rotate-left me-1"></i>Revert to ' + originalValue
                : '<i class="fa-solid fa-rotate-left me-1"></i>Clear Status Flag',
            cancelButtonText:  'Cancel',
            confirmButtonColor: "#16a34a",
            denyButtonColor:    "#6b7280",
            didOpen: function() { var i = document.getElementById("swal-edit-val"); if (i) { i.select(); } },
            preConfirm: function() {
                var v = $("#swal-edit-val").val().trim();
                var r = $("#swal-edit-rem").val().trim();
                _status = $("#swal-edit-status").val() || "NONE";

                // Did the value actually change from the current value?
                var valueChanged = (v !== "" && parseFloat(v) !== Number(currentValue));
                var statusChanged = (_status !== _curStatus);

                if (!valueChanged && statusChanged) {
                    // Status-only change: value + remarks not required.
                    _val = null; _rem = r;
                    return true;
                }

                // Otherwise treat as a value edit — value + remarks required.
                if (!v) { Swal.showValidationMessage("Enter a value, or change only the status."); return false; }
                var n = parseFloat(v);
                if (isNaN(n) || n < 0) { Swal.showValidationMessage("Enter a valid non-negative number."); return false; }
                if (!r) { Swal.showValidationMessage("Remarks are required when changing the value."); return false; }
                _val = n; _rem = r;
                return true;
            }
        }).then(function(result) {
            if (result.isDenied) {
                // Either revert value OR clear conversion flag
                Swal.fire({
                    title: isEdited ? "Revert to computed?" : "Clear status flag?",
                    html:  isEdited
                        ? "Restores <b>" + originalValue + "</b> for "
                            + escHtml(machineName) + " / " + escHtml(itemName) + " on " + escHtml(dateStr)
                        : "Removes the manual status flag for <b>"
                            + escHtml(machineName) + " / " + escHtml(itemName) + "</b> on " + escHtml(dateStr),
                    icon: "warning", showCancelButton: true,
                    confirmButtonText: isEdited ? "Yes, revert" : "Yes, clear",
                    confirmButtonColor: "#6b7280"
                }).then(function(c) {
                    if (!c.isConfirmed) { return; }
                    if (isEdited) {
                        // Revert value — remove the whole override row.
                        $.ajax({
                            type: "DELETE",
                            url:  basePath + "/loadingplan/override/u"
                                + "?planId="      + encodeURIComponent(planId)
                                + "&machineName=" + encodeURIComponent(machineName)
                                + "&itemName="    + encodeURIComponent(itemName)
                                + "&planDate="    + encodeURIComponent(dateStr),
                            success: function() { loadLoadingPlan(); },
                            error:   function(xhr) { Swal.fire({ icon: "error", title: "Failed", text: xhr.responseText || "" }); }
                        });
                    } else {
                        // Clear status only — keep any value, set status NONE (status-only POST).
                        $.ajax({
                            type: "POST", url: basePath + "/loadingplan/override/u",
                            data: { planId: planId, machineName: machineName, itemName: itemName,
                                    planDate: dateStr, cellStatus: "NONE" },
                            success: function() { loadLoadingPlan(); },
                            error:   function(xhr) { Swal.fire({ icon: "error", title: "Failed", text: xhr.responseText || "" }); }
                        });
                    }
                });
                return;
            }
            if (!result.isConfirmed) { return; }
            var postData;
            if (_val === null) {
                // Status-only change — no value, no mandatory remarks.
                postData = { planId: planId, machineName: machineName, itemName: itemName,
                             planDate: dateStr, cellStatus: _status };
            } else {
                // Value edit (optionally carrying a status flag too).
                postData = { planId: planId, machineName: machineName, itemName: itemName,
                             planDate: dateStr, value: _val, remarks: _rem,
                             overrideType: "STANDARD", cellStatus: _status };
            }
            $.ajax({
                type: "POST", url: basePath + "/loadingplan/override/u",
                data: postData,
                success: function() { loadLoadingPlan(); },
                error:   function(xhr) {
                    Swal.fire({ icon: "error", title: "Save Failed",
                        html: "<b>Could not save.</b><br><small>" + (xhr.responseText || "Server error") + "</small>" });
                }
            });
        });
    }

    // Helper — extract day-of-month integer from "YYYY-MM-DD"
    function extractDay(dateStr) {
        if (!dateStr) { return 0; }
        var parts = String(dateStr).split("-");
        return parts.length >= 3 ? parseInt(parts[2], 10) : 0;
    }

    /* ─────────────────────────────────────────────────────────────
       2. Reassign dialog
       ───────────────────────────────────────────────────────────── */
    function openReassignDialog(sourceMachine) {
        var allocRows = [];
        $.each(lastLoadingRows, function(i, r) {
            if (r.machineName === sourceMachine && !r.qualifiedOnly && r.machineName !== "-") {
                allocRows.push(r);
            }
        });
        if (!allocRows.length) { Swal.fire({ text: "No allocated items on " + sourceMachine + ".", icon: "info" }); return; }

        var today   = planYear + "-" + pad2(planMonth) + "-01";
        var lastDay = planYear + "-" + pad2(planMonth) + "-" + pad2(daysInMonth);

        var itemsHtml = "";
        $.each(allocRows, function(i, row) {
            var targets = getQualifiedTargetMachines(row.itemName, sourceMachine);
            var selHtml = '<select class="form-select form-select-sm rs-target-sel" data-item="' + escHtml(row.itemName) + '">'
                        + '<option value="">— skip —</option>';
            $.each(targets, function(j, m) { selHtml += '<option value="' + escHtml(m) + '">' + escHtml(m) + '</option>'; });
            if (!targets.length) { selHtml += '<option disabled>No other qualified machines</option>'; }
            selHtml += '</select>';
            itemsHtml += '<div class="d-flex align-items-center gap-2 p-2 mb-1 border rounded bg-light">'
                       + '<span style="min-width:120px;font-weight:700;font-size:12px;color:#1e3a8a;">' + escHtml(row.itemName) + '</span>'
                       + '<span class="badge bg-secondary">' + escHtml(row.machineRole) + '</span>'
                       + '<i class="fa-solid fa-arrow-right text-secondary"></i>' + selHtml + '</div>';
        });

        var _payload = null;

        Swal.fire({
            title: '<span style="font-size:15px;"><i class="fa-solid fa-right-left me-2 text-primary"></i>Reassign \u2014 ' + escHtml(getMachineDisplay(sourceMachine)) + '</span>',
            width: "660px", showCancelButton: true, allowOutsideClick: false,
            confirmButtonText: '<i class="fa-solid fa-floppy-disk me-1"></i>Apply Reassign',
            confirmButtonColor: "#2563eb",
            html: '<div class="text-start" style="font-size:13px;">'
                + '<div class="mb-2 text-danger fw-bold" style="font-size:11px;text-transform:uppercase;">Source dates (lots removed)</div>'
                + '<div class="row g-2 mb-3">'
                + '<div class="col"><div class="form-floating"><input type="date" id="rs-f1" class="form-control form-control-sm" value="' + today + '" min="' + today + '" max="' + lastDay + '"><label>From start</label></div></div>'
                + '<div class="col"><div class="form-floating"><input type="date" id="rs-f2" class="form-control form-control-sm" value="' + today + '" min="' + today + '" max="' + lastDay + '"><label>From end</label></div></div></div>'
                + '<div class="mb-2 text-primary fw-bold" style="font-size:11px;text-transform:uppercase;">Target dates (lots received)</div>'
                + '<div class="row g-2 mb-3">'
                + '<div class="col"><div class="form-floating"><input type="date" id="rs-t1" class="form-control form-control-sm" value="' + today + '" min="' + today + '" max="' + lastDay + '"><label>To start</label></div></div>'
                + '<div class="col"><div class="form-floating"><input type="date" id="rs-t2" class="form-control form-control-sm" value="' + today + '" min="' + today + '" max="' + lastDay + '"><label>To end</label></div></div></div>'
                + '<div class="mb-3"><label class="fw-bold mb-1" style="font-size:12px;">Reason:</label>'
                + '<div class="d-flex gap-3 flex-wrap">'
                + '<div class="form-check"><input class="form-check-input" type="radio" name="rsReason" id="rs-r1" value="MACHINE_TROUBLE" checked>'
                + '<label class="form-check-label" for="rs-r1" style="font-size:12px;color:#dc2626;">Machine Trouble</label></div>'
                + '<div class="form-check"><input class="form-check-input" type="radio" name="rsReason" id="rs-r2" value="UNPLANNED_MAINTENANCE">'
                + '<label class="form-check-label" for="rs-r2" style="font-size:12px;color:#f97316;">Unplanned Maintenance</label></div>'
                + '<div class="form-check"><input class="form-check-input" type="radio" name="rsReason" id="rs-r3" value="OTHER">'
                + '<label class="form-check-label" for="rs-r3" style="font-size:12px;">Other</label></div></div></div>'
                + '<div class="mb-2 fw-bold" style="font-size:11px;color:#64748b;text-transform:uppercase;">Capacity for target value:</div>'
                + '<div class="d-flex gap-3 mb-3">'
                + '<div class="form-check"><input class="form-check-input" type="radio" name="rsCapaMode" id="rs-cmax" value="max" checked>'
                + '<label class="form-check-label" for="rs-cmax" style="font-size:12px;">Max Capacity</label></div>'
                + '<div class="form-check"><input class="form-check-input" type="radio" name="rsCapaMode" id="rs-cconv" value="conv">'
                + '<label class="form-check-label" for="rs-cconv" style="font-size:12px;">Converted Capacity</label></div></div>'
                + '<div class="mb-1 fw-bold" style="font-size:11px;color:#64748b;text-transform:uppercase;">Assign to target machine:</div>'
                + itemsHtml
                + '<div class="mt-3"><label class="fw-bold" style="font-size:12px;">Remarks <span class="text-danger">*</span></label>'
                + '<textarea id="rs-rem" class="form-control mt-1" rows="2" maxlength="500" placeholder="Reason for reassignment..."></textarea></div>'
                + '</div>',
            didOpen: function() {
                $("#rs-f1").on("change", function() { var v = $(this).val(); if ($("#rs-f2").val() < v) { $("#rs-f2").val(v); } $("#rs-f2").attr("min", v); });
                $("#rs-t1").on("change", function() { var v = $(this).val(); if ($("#rs-t2").val() < v) { $("#rs-t2").val(v); } $("#rs-t2").attr("min", v); });
            },
            preConfirm: function() {
                var f1 = $("#rs-f1").val(), f2 = $("#rs-f2").val();
                var t1 = $("#rs-t1").val(), t2 = $("#rs-t2").val();
                var reason   = $("input[name='rsReason']:checked").val()  || "OTHER";
                var capaMode = $("input[name='rsCapaMode']:checked").val() || "max";
                var remarks  = $("#rs-rem").val().trim();
                if (!f1 || !f2 || f2 < f1) { Swal.showValidationMessage("Invalid source date range."); return false; }
                if (!t1 || !t2 || t2 < t1) { Swal.showValidationMessage("Invalid target date range."); return false; }
                if (!remarks) { Swal.showValidationMessage("Remarks are required."); return false; }
                var assignments = [];
                $(".rs-target-sel").each(function() {
                    var tgt = $(this).val(), item = $(this).data("item");
                    if (tgt && item) { assignments.push({ itemName: item, targetMachine: tgt }); }
                });
                if (!assignments.length) { Swal.showValidationMessage("Select at least one target machine."); return false; }
                // Conflict check
                var tgtFrom = new Date(t1 + "T00:00:00"), tgtTo = new Date(t2 + "T00:00:00"), conflicts = [];
                $.each(assignments, function(i, a) {
                    for (var d = 1; d <= daysInMonth; d++) {
                        var cd = new Date(planYear, planMonth - 1, d);
                        if (cd < tgtFrom || cd > tgtTo) { continue; }
                        if (hasRunningLots(a.targetMachine, a.itemName, d)) {
                            conflicts.push(a.targetMachine + " / " + a.itemName + " on Day " + d);
                        }
                    }
                });
                if (conflicts.length) {
                    Swal.showValidationMessage("Conflict: " + conflicts.slice(0, 3).join("; ")
                        + (conflicts.length > 3 ? " and " + (conflicts.length - 3) + " more." : ""));
                    return false;
                }
                _payload = { sourceMachine: sourceMachine, f1: f1, f2: f2, t1: t1, t2: t2,
                             reason: reason, capaMode: capaMode, remarks: remarks, assignments: assignments };
                return true;
            }
        }).then(function(result) {
            if (!result.isConfirmed || !_payload) { return; }
            applyReassign(_payload);
        });
    }

    function applyReassign(p) {
        showLoadingScreen();
        var batch = [], srcFrom = new Date(p.f1 + "T00:00:00"), srcTo = new Date(p.f2 + "T00:00:00");
        var tgtFrom = new Date(p.t1 + "T00:00:00"), tgtTo = new Date(p.t2 + "T00:00:00");
        var srcDays = [], tgtDays = [];
        for (var d = 1; d <= daysInMonth; d++) {
            var cd = new Date(planYear, planMonth - 1, d);
            if (cd >= srcFrom && cd <= srcTo) { srcDays.push(d); }
            if (cd >= tgtFrom && cd <= tgtTo) { tgtDays.push(d); }
        }
        if (!srcDays.length || !tgtDays.length) {
            Swal.close(); Swal.fire({ text: "No days in one of the date ranges.", icon: "warning" }); return;
        }
        $.each(p.assignments, function(i, asgn) {
            // Find source row to get original computed values
            var srcRow = null;
            $.each(lastLoadingRows, function(j, r) {
                if (r.machineName === p.sourceMachine && r.itemName === asgn.itemName && !r.qualifiedOnly) {
                    srcRow = r; return false;
                }
            });

            // Source rows — zeroed out
            $.each(srcDays, function(j, day) {
                batch.push({ planId: parseInt(planId, 10), machineName: p.sourceMachine,
                    itemName: asgn.itemName, planDate: buildDateStr(day), value: 0,
                    overrideType: "STANDARD", reassignReason: p.reason, remarks: p.remarks });
            });

            // Target rows — same cumulative formula as addDailyValues in service,
            // but capped per day by target machine's chosen capa (max or converted).
            // This ensures the target can physically run the lots each day.
            var total = 0;
            $.each(srcDays, function(j, day) { total += srcRow ? getOriginalDayValue(srcRow, day) : 0; });

            if (total > 0 && tgtDays.length > 0) {
                // Get per-day capacity of target machine for this item
                var capaPerDay = 0;
                $.each(lastLoadingRows, function(j, r) {
                    if (r.machineName === asgn.targetMachine && r.itemName === asgn.itemName) {
                        capaPerDay = (p.capaMode === "conv")
                            ? (Number(r.convCapaLotsPerDay) || 0)
                            : (Number(r.maxCapaLotsPerDay)  || 0);
                        return false;
                    }
                });

                // Distribute total across target days using cumulative formula —
                // same as addDailyValues() in LoadingPlanService:
                //   day_lots = floor(rate * (i+1)) - floor(rate * i)
                // This gives even spread like 5 5 6 5 6... for non-integer rates.
                // If capaPerDay is set, each day is further capped at that limit.
                var dailyRate       = total / tgtDays.length;
                var prevCumulative  = 0;
                var remainingTotal  = total;

                $.each(tgtDays, function(j, day) {
                    if (remainingTotal <= 0) { return false; }
                    var cumulative = Math.floor(dailyRate * (j + 1));
                    var dayLots    = cumulative - prevCumulative;

                    // Cap by target machine's per-day capacity if known
                    if (capaPerDay > 0) { dayLots = Math.min(dayLots, Math.floor(capaPerDay)); }
                    dayLots = Math.min(dayLots, remainingTotal);

                    if (dayLots > 0) {
                        batch.push({ planId: parseInt(planId, 10), machineName: asgn.targetMachine,
                            itemName: asgn.itemName, planDate: buildDateStr(day), value: dayLots,
                            overrideType: "STANDARD", reassignReason: null, remarks: p.remarks });
                        remainingTotal -= dayLots;
                    }
                    prevCumulative = cumulative;
                });
            }
        });
        if (!batch.length) { Swal.close(); Swal.fire({ text: "Nothing to reassign.", icon: "info" }); return; }
        $.ajax({
            type: "POST", url: basePath + "/loadingplan/override/batch",
            contentType: "application/json", data: JSON.stringify(batch),
            success: function(r) { Swal.fire({ text: r, icon: "success", showConfirmButton: false, timer: 1400 }).then(function() { loadLoadingPlan(); }); },
            error:   function(xhr) { Swal.close(); Swal.fire({ icon: "error", title: "Error", text: xhr.responseText || "" }); }
        });
    }

    /* ─────────────────────────────────────────────────────────────
       3. Recovery dialog
       ───────────────────────────────────────────────────────────── */
    function openRecoveryDialog(sourceMachine) {
        var allocRows = [];
        $.each(lastLoadingRows, function(i, r) {
            if (r.machineName === sourceMachine && !r.qualifiedOnly && r.machineName !== "-") { allocRows.push(r); }
        });
        if (!allocRows.length) { Swal.fire({ text: "No allocated items on " + sourceMachine + ".", icon: "info" }); return; }

        var today   = planYear + "-" + pad2(planMonth) + "-01";
        var lastDay = planYear + "-" + pad2(planMonth) + "-" + pad2(daysInMonth);

        var itemsHtml = "";
        $.each(allocRows, function(i, row) {
            var targets = getQualifiedTargetMachines(row.itemName, sourceMachine);
            var selHtml = '<select class="form-select form-select-sm rc-target-sel" data-item="' + escHtml(row.itemName) + '">'
                        + '<option value="">— skip —</option>';
            $.each(targets, function(j, m) { selHtml += '<option value="' + escHtml(m) + '">' + escHtml(m) + '</option>'; });
            if (!targets.length) { selHtml += '<option disabled>No other qualified machines</option>'; }
            selHtml += '</select>';
            itemsHtml += '<div class="d-flex align-items-center gap-2 p-2 mb-1 border rounded bg-light">'
                       + '<span style="min-width:120px;font-weight:700;font-size:12px;color:#1e3a8a;">' + escHtml(row.itemName) + '</span>'
                       + '<span class="badge bg-secondary">' + escHtml(row.machineRole) + '</span>'
                       + '<i class="fa-solid fa-arrow-right text-secondary"></i>' + selHtml + '</div>';
        });

        var _payload = null;

        Swal.fire({
            title: '<span style="font-size:15px;"><i class="fa-solid fa-rotate-right me-2 text-success"></i>Recovery \u2014 ' + escHtml(getMachineDisplay(sourceMachine)) + '</span>',
            width: "660px", showCancelButton: true, allowOutsideClick: false,
            confirmButtonText: '<i class="fa-solid fa-floppy-disk me-1"></i>Apply Recovery',
            confirmButtonColor: "#059669",
            html: '<div class="text-start" style="font-size:13px;">'
                + '<div class="alert alert-info py-2 mb-3" style="font-size:12px;">'
                + '<b>Recovery:</b> Source machine lots are <b>kept intact</b> (pink). '
                + 'Extra recovery lots are added to the target machine using converted capacity.</div>'
                + '<div class="mb-2 text-danger fw-bold" style="font-size:11px;text-transform:uppercase;">Source dates (affected on ' + escHtml(sourceMachine) + ')</div>'
                + '<div class="row g-2 mb-3">'
                + '<div class="col"><div class="form-floating"><input type="date" id="rc-s1" class="form-control form-control-sm" value="' + today + '" min="' + today + '" max="' + lastDay + '"><label>Source start</label></div></div>'
                + '<div class="col"><div class="form-floating"><input type="date" id="rc-s2" class="form-control form-control-sm" value="' + today + '" min="' + today + '" max="' + lastDay + '"><label>Source end</label></div></div></div>'
                + '<div class="mb-2 text-success fw-bold" style="font-size:11px;text-transform:uppercase;">Recovery dates (when extra lots will run)</div>'
                + '<div class="row g-2 mb-3">'
                + '<div class="col"><div class="form-floating"><input type="date" id="rc-t1" class="form-control form-control-sm" value="' + today + '" min="' + today + '" max="' + lastDay + '"><label>Recovery start</label></div></div>'
                + '<div class="col"><div class="form-floating"><input type="date" id="rc-t2" class="form-control form-control-sm" value="' + today + '" min="' + today + '" max="' + lastDay + '"><label>Recovery end</label></div></div></div>'
                + '<div class="mb-1 fw-bold" style="font-size:11px;color:#64748b;text-transform:uppercase;">Assign recovery to:</div>'
                + itemsHtml
                + '<div class="mt-3"><label class="fw-bold" style="font-size:12px;">Remarks <span class="text-danger">*</span></label>'
                + '<textarea id="rc-rem" class="form-control mt-1" rows="2" maxlength="500" placeholder="Describe the recovery action..."></textarea></div>'
                + '</div>',
            didOpen: function() {
                $("#rc-s1").on("change", function() { var v = $(this).val(); if ($("#rc-s2").val() < v) { $("#rc-s2").val(v); } $("#rc-s2").attr("min", v); });
                $("#rc-t1").on("change", function() { var v = $(this).val(); if ($("#rc-t2").val() < v) { $("#rc-t2").val(v); } $("#rc-t2").attr("min", v); });
            },
            preConfirm: function() {
                var s1 = $("#rc-s1").val(), s2 = $("#rc-s2").val();
                var t1 = $("#rc-t1").val(), t2 = $("#rc-t2").val();
                var remarks = $("#rc-rem").val().trim();
                if (!s1 || !s2 || s2 < s1) { Swal.showValidationMessage("Invalid source date range."); return false; }
                if (!t1 || !t2 || t2 < t1) { Swal.showValidationMessage("Invalid recovery date range."); return false; }
                if (!remarks) { Swal.showValidationMessage("Remarks are required."); return false; }
                var assignments = [];
                $(".rc-target-sel").each(function() {
                    var tgt = $(this).val(), item = $(this).data("item");
                    if (tgt && item) { assignments.push({ itemName: item, targetMachine: tgt }); }
                });
                if (!assignments.length) { Swal.showValidationMessage("Select at least one recovery target machine."); return false; }
                // Conflict check
                var tgtFrom = new Date(t1 + "T00:00:00"), tgtTo = new Date(t2 + "T00:00:00"), conflicts = [];
                $.each(assignments, function(i, a) {
                    for (var d = 1; d <= daysInMonth; d++) {
                        var cd = new Date(planYear, planMonth - 1, d);
                        if (cd < tgtFrom || cd > tgtTo) { continue; }
                        if (hasRunningLots(a.targetMachine, a.itemName, d)) {
                            conflicts.push(a.targetMachine + " / " + a.itemName + " on Day " + d);
                        }
                    }
                });
                if (conflicts.length) {
                    Swal.showValidationMessage("Conflict: " + conflicts.slice(0, 3).join("; ")
                        + (conflicts.length > 3 ? " and " + (conflicts.length - 3) + " more." : ""));
                    return false;
                }
                // Conv capa check
                var noCapa = [];
                $.each(assignments, function(i, a) {
                    $.each(lastLoadingRows, function(j, r) {
                        if (r.machineName === a.targetMachine && r.itemName === a.itemName) {
                            if ((r.convCapaLotsPerDay || 0) <= 0) { noCapa.push(a.itemName + " on " + a.targetMachine); }
                            return false;
                        }
                    });
                });
                if (noCapa.length) { Swal.showValidationMessage("No converted capacity for: " + noCapa.join(", ")); return false; }
                _payload = { sourceMachine: sourceMachine, s1: s1, s2: s2, t1: t1, t2: t2,
                             remarks: remarks, assignments: assignments };
                return true;
            }
        }).then(function(result) {
            if (!result.isConfirmed || !_payload) { return; }
            applyRecovery(_payload);
        });
    }

    function applyRecovery(p) {
        showLoadingScreen();
        var batch = [], srcFrom = new Date(p.s1 + "T00:00:00"), srcTo = new Date(p.s2 + "T00:00:00");
        var tgtFrom = new Date(p.t1 + "T00:00:00"), tgtTo = new Date(p.t2 + "T00:00:00");
        var srcDays = [], tgtDays = [];
        for (var d = 1; d <= daysInMonth; d++) {
            var cd = new Date(planYear, planMonth - 1, d);
            if (cd >= srcFrom && cd <= srcTo) { srcDays.push(d); }
            if (cd >= tgtFrom && cd <= tgtTo) { tgtDays.push(d); }
        }
        if (!srcDays.length || !tgtDays.length) {
            Swal.close(); Swal.fire({ text: "No days in one of the date ranges.", icon: "warning" }); return;
        }
        $.each(p.assignments, function(i, asgn) {

            var firstSrcDay = buildDateStr(srcDays[0]);

            // Collect source machine's original day values first
            // so we can mirror them on the target machine
            var srcRowData = null;
            $.each(lastLoadingRows, function(k, r) {
                if (r.machineName === p.sourceMachine && r.itemName === asgn.itemName && !r.qualifiedOnly) {
                    srcRowData = r; return false;
                }
            });

            // Source days — kept value (pink, RECOVERY source)
            $.each(srcDays, function(j, day) {
                var keptVal = srcRowData ? getOriginalDayValue(srcRowData, day) : 0;
                batch.push({ planId: parseInt(planId, 10), machineName: p.sourceMachine,
                    itemName: asgn.itemName, planDate: buildDateStr(day), value: keptVal,
                    overrideType: "RECOVERY", reassignReason: null, remarks: p.remarks,
                    recoverySourceDate: null });
            });

            // Target days — mirror the source machine's original values.
            // The planner is recovering the same lots onto the fraction machine,
            // so the target gets the same day-by-day quantities as the source.
            // The first target day will be flagged as a conversion day by
            // detectConversionDays (Phase 6b) — the planner can manually
            // adjust that day's value to convCapaLotsPerDay if needed.
            $.each(tgtDays, function(j, day) {
                // Use the corresponding source day's value.
                // If target range is longer than source range, fall back to 0.
                var srcDay   = srcDays[j];
                var lots     = (srcDay !== undefined && srcRowData)
                             ? getOriginalDayValue(srcRowData, srcDay)
                             : 0;
                if (lots > 0) {
                    batch.push({ planId: parseInt(planId, 10), machineName: asgn.targetMachine,
                        itemName: asgn.itemName, planDate: buildDateStr(day), value: lots,
                        overrideType: "RECOVERY", reassignReason: null, remarks: p.remarks,
                        recoverySourceDate: firstSrcDay });
                }
            });
        });
        if (!batch.length) { Swal.close(); Swal.fire({ text: "Nothing to save.", icon: "info" }); return; }
        $.ajax({
            type: "POST", url: basePath + "/loadingplan/override/batch",
            contentType: "application/json", data: JSON.stringify(batch),
            success: function(r) { Swal.fire({ text: r, icon: "success", showConfirmButton: false, timer: 1400 }).then(function() { loadLoadingPlan(); }); },
            error:   function(xhr) { Swal.close(); Swal.fire({ icon: "error", title: "Error", text: xhr.responseText || "" }); }
        });
    }

    /* ─────────────────────────────────────────────────────────────
       4. Extended fraction plot dialog
       ───────────────────────────────────────────────────────────── */
    function openFractionPlotDialog(machineName, itemName, currentMonthTotal, machineShare) {
        var key      = machineName + "|" + itemName;
        var existing = fractionPlotMap[key];
        var today    = planYear + "-" + pad2(planMonth) + "-01";
        var lastDay  = planYear + "-" + pad2(planMonth) + "-" + pad2(daysInMonth);

        // Default total lots to the row's current computed total —
        // the planner is redistributing the same total into a tighter window.
        // They can adjust the number if they want to redistribute a different amount.
        var defaultLots = existing ? existing.totalLots : currentMonthTotal;

        var _plotStart = null, _plotEnd = null, _totalLots = 0;

        Swal.fire({
            title: '<span style="font-size:15px;"><i class="fa-solid fa-chart-bar me-2" style="color:#7c3aed;"></i>Fraction Plot — Redistribute</span>',
            width: "580px", showCancelButton: true, allowOutsideClick: false,
            confirmButtonText: '<i class="fa-solid fa-floppy-disk me-1"></i>Save Plot',
            confirmButtonColor: "#7c3aed",
            showDenyButton:  !!existing,
            denyButtonText:  '<i class="fa-solid fa-trash me-1"></i>Remove Plot',
            denyButtonColor: "#dc2626",
            html: '<div class="text-start" style="font-size:13px;">'
                + '<div class="d-flex gap-3 mb-3 flex-wrap">'
                + '<span><b>Machine:</b> ' + escHtml(machineName) + '</span>'
                + '<span><b>Item:</b> '    + escHtml(itemName)    + '</span>'
                + '<span><b>Share:</b> '   + Number(machineShare).toFixed(2)  + '</span>'
                + '<span><b>Computed total:</b> ' + currentMonthTotal + ' lots</span></div>'
                + '<div class="alert alert-info py-2 mb-3" style="font-size:12px;">'
                + '<b>Redistribute</b> this fraction row\'s lots into a chosen date range. '
                + 'All other days are set to <b>0</b>, freeing them for Reassign and Recovery. '
                + 'Remove the plot to revert to the original computed allocation.</div>'
                + '<div class="row g-2 mb-3">'
                + '<div class="col"><div class="form-floating"><input type="date" id="fp-start" class="form-control form-control-sm" '
                + 'value="' + (existing ? toDateInputStr(existing.plotStart) : today) + '" min="' + today + '" max="' + lastDay + '"><label>Plot start</label></div></div>'
                + '<div class="col"><div class="form-floating"><input type="date" id="fp-end" class="form-control form-control-sm" '
                + 'value="' + (existing ? toDateInputStr(existing.plotEnd) : lastDay) + '" min="' + today + '" max="' + lastDay + '"><label>Plot end</label></div></div></div>'
                + '<div class="form-floating mb-2">'
                + '<input type="number" id="fp-lots" class="form-control" min="0" step="1" '
                + 'value="' + defaultLots + '" placeholder="">'
                + '<label>Total lots to redistribute across date range</label></div>'
                + '<div id="fp-preview" class="mt-1 p-2 rounded" style="font-size:12px;background:#f8fafc;border:1px solid #e2e8f0;min-height:32px;"></div>'
                + '</div>',
            didOpen: function() {
                function updatePreview() {
                    var s    = $("#fp-start").val();
                    var e    = $("#fp-end").val();
                    var lots = parseInt($("#fp-lots").val(), 10) || 0;
                    if (!s || !e || e < s) { $("#fp-preview").html('<span class="text-muted">Select a valid date range.</span>'); return; }

                    // Count days in range
                    var sd = new Date(s + "T00:00:00"), ed = new Date(e + "T00:00:00");
                    var days = 0, tmp = new Date(sd);
                    while (tmp <= ed) { days++; tmp.setDate(tmp.getDate() + 1); }

                    if (days <= 0 || lots <= 0) { $("#fp-preview").html('<span class="text-muted">Enter total lots to see preview.</span>'); return; }

                    // Simulate the same cumulative formula the service uses
                    var rate = lots / days;
                    var prev = 0, sample = [];
                    for (var i = 0; i < Math.min(days, 10); i++) {
                        var cum  = Math.floor(rate * (i + 1));
                        sample.push(cum - prev);
                        prev = cum;
                    }
                    var sampleStr = sample.join(" ");
                    if (days > 10) { sampleStr += " ..."; }

                    $("#fp-preview").html(
                        '<span class="text-success fw-bold"><i class="fa-solid fa-circle-check me-1"></i>'
                      + days + ' day(s)</span>'
                      + ' &rarr; approx <b>' + rate.toFixed(2) + ' lots/day</b>'
                      + '<br><span class="text-muted" style="font-size:11px;">Day values: ' + sampleStr + '</span>'
                    );
                }
                $("#fp-start, #fp-end, #fp-lots").on("change input", updatePreview);
                $("#fp-start").on("change", function() {
                    var v = $(this).val();
                    if ($("#fp-end").val() < v) { $("#fp-end").val(v); }
                    $("#fp-end").attr("min", v);
                    updatePreview();
                });
                updatePreview();
            },
            preConfirm: function() {
                var s    = $("#fp-start").val();
                var e    = $("#fp-end").val();
                var lots = parseInt($("#fp-lots").val(), 10);
                if (!s || !e || e < s) { Swal.showValidationMessage("Invalid date range."); return false; }
                if (isNaN(lots) || lots < 0) { Swal.showValidationMessage("Total lots must be a non-negative number."); return false; }
                _plotStart = s; _plotEnd = e; _totalLots = lots; return true;
            }
        }).then(function(result) {
            if (result.isDenied) {
                Swal.fire({
                    title: "Remove fraction plot?",
                    html:  "Reverts <b>" + escHtml(machineName) + " / " + escHtml(itemName)
                         + "</b> to its original computed allocation across all days.",
                    icon: "warning", showCancelButton: true,
                    confirmButtonText: "Yes, remove", confirmButtonColor: "#dc2626"
                }).then(function(c) {
                    if (!c.isConfirmed) { return; }
                    $.ajax({
                        type: "DELETE",
                        url:  basePath + "/loadingplan/fractionplot"
                            + "?planId="      + encodeURIComponent(planId)
                            + "&machineName=" + encodeURIComponent(machineName)
                            + "&itemName="    + encodeURIComponent(itemName),
                        success: function() { loadLoadingPlan(); },
                        error:   function(xhr) { Swal.fire({ icon: "error", text: xhr.responseText || "" }); }
                    });
                });
                return;
            }
            if (!result.isConfirmed) { return; }
            saveFractionPlot(machineName, itemName, _plotStart, _plotEnd, _totalLots, false);
        });
    }

    function saveFractionPlot(machineName, itemName, plotStart, plotEnd, totalLots, force) {
        // Check client-side for overrides OUTSIDE the plot range that would be zeroed
        var outsideConflicts = [];
        $.each(lastLoadingRows, function(i, r) {
            if (r.machineName !== machineName || r.itemName !== itemName) { return; }
            for (var d = 1; d <= daysInMonth; d++) {
                var cd = new Date(planYear, planMonth - 1, d);
                var ps = new Date(plotStart + "T00:00:00");
                var pe = new Date(plotEnd   + "T00:00:00");
                var outsideRange = cd < ps || cd > pe;
                if (outsideRange && (isOverridden(r, d) || isReassigned(r, d) ||
                        isRecoverySource(r, d) || isRecoveryTarget(r, d))) {
                    outsideConflicts.push(buildDateStr(d));
                }
            }
        });

        if (outsideConflicts.length > 0 && !force) {
            var dateList = outsideConflicts.slice(0, 5).join(", ")
                + (outsideConflicts.length > 5 ? " and " + (outsideConflicts.length - 5) + " more" : "");
            Swal.fire({
                title: "Overrides outside plot range",
                html:  "<b>" + outsideConflicts.length + " day(s)</b> outside the chosen plot range "
                     + "have existing manual edits or reassignments:<br><br>"
                     + "<code style='font-size:12px;'>" + escHtml(dateList) + "</code><br><br>"
                     + "Those days will be set to <b>0</b> by the plot. "
                     + "The override records will be preserved in the DB but will not be visible "
                     + "while this plot is active.<br><br>"
                     + "Do you want to continue?",
                icon: "warning", showCancelButton: true,
                confirmButtonText: "Yes, save plot", confirmButtonColor: "#7c3aed",
                cancelButtonText:  "Cancel"
            }).then(function(c) {
                if (c.isConfirmed) { saveFractionPlot(machineName, itemName, plotStart, plotEnd, totalLots, true); }
            });
            return;
        }

        $.ajax({
            type: "POST", url: basePath + "/loadingplan/fractionplot"
                + (force ? "?force=true" : ""),
            data: { planId: planId, machineName: machineName, itemName: itemName,
                    plotStart: plotStart, plotEnd: plotEnd, totalLots: totalLots },
            dataType: "json",
            success: function() { loadLoadingPlan(); },
            error: function(xhr) {
                var parsed = {};
                try { parsed = JSON.parse(xhr.responseText); } catch(e) {}

                if (xhr.status === 409) {
                    // Server found override conflicts WITHIN the plot range
                    var conflictDates = Array.isArray(parsed) ? parsed : [];
                    var dateList = conflictDates.slice(0, 5).join(", ")
                        + (conflictDates.length > 5 ? " and " + (conflictDates.length - 5) + " more" : "");
                    Swal.fire({
                        title: "Overrides within plot range",
                        html:  "<b>" + conflictDates.length + " day(s)</b> within the chosen range "
                             + "already have manual edits or reassignments:<br><br>"
                             + "<code style='font-size:12px;'>" + escHtml(dateList) + "</code><br><br>"
                             + "Those override values will be applied <b>on top of</b> the plot values. "
                             + "The plot total may not reflect the final result on those days.<br><br>"
                             + "Do you want to save the plot anyway?",
                        icon: "warning", showCancelButton: true,
                        confirmButtonText: "Yes, save anyway", confirmButtonColor: "#7c3aed",
                        cancelButtonText:  "Cancel"
                    }).then(function(c) {
                        if (c.isConfirmed) {
                            saveFractionPlot(machineName, itemName, plotStart, plotEnd, totalLots, true);
                        }
                    });
                } else {
                    var msg = parsed.error || xhr.responseText || "Server error";
                    Swal.fire({ icon: "error", title: "Save Failed", text: msg });
                }
            }
        });
    }

    /* ─────────────────────────────────────────────────────────────
       Item priority dialog — drag to reorder items per machine
       ───────────────────────────────────────────────────────────── */
    function openItemPriorityDialog(machineName) {
        // Get all items for this machine that are either:
        // 1. Allocated (Fix, Fraction, Unallocated) — always included
        // 2. Qualified with a value — received lots via reassign, effectively running
        var items = [];
        $.each(lastLoadingRows, function(i, r) {
            if (r.machineName !== machineName) { return; }
            if (!r.itemName) { return; }
            // Include: allocated rows OR qualified rows that have received value
            var isAllocated = !r.qualifiedOnly;
            var hasValue    = Number(r.monthTotalLots || 0) > 0;
            if (!isAllocated && !hasValue) { return; } // pure Qualified with no value — skip
            var exists = false;
            $.each(items, function(j, it) { if (it === r.itemName) { exists = true; return false; } });
            if (!exists) { items.push(r.itemName); }
        });

        if (!items.length) {
            Swal.fire({ text: "No active items on " + machineName + ".", icon: "info" });
            return;
        }

        // Apply existing priority order if set
        var existing = itemPriorityMap[machineName];
        if (existing && existing.length > 0) {
            var ordered = [], remaining = items.slice();
            $.each(existing, function(i, name) {
                var idx = remaining.indexOf(name);
                if (idx !== -1) { ordered.push(name); remaining.splice(idx, 1); }
            });
            // Append any items not in the saved priority (newly added items)
            items = ordered.concat(remaining);
        }

        var hasPriority = !!(existing && existing.length > 0);

        // Build the draggable list HTML
        function buildListHtml(arr) {
            var html = '<div id="priority-list" style="min-height:60px;">';
            $.each(arr, function(i, name) {
                html += '<div class="priority-item" draggable="true" data-item="' + escHtml(name) + '">'
                      + '<i class="fa-solid fa-grip-vertical drag-handle"></i>'
                      + '<span class="seq-badge">' + (i + 1) + '</span>'
                      + '<span>' + escHtml(name) + '</span>'
                      + '</div>';
            });
            html += '</div>';
            return html;
        }

        Swal.fire({
            title: '<span style="font-size:15px;"><i class="fa-solid fa-arrow-down-1-9 me-2 text-secondary"></i>Item Priority \u2014 ' + escHtml(getMachineDisplay(machineName)) + '</span>',
            width: "500px", showCancelButton: true, allowOutsideClick: false,
            confirmButtonText: '<i class="fa-solid fa-floppy-disk me-1"></i>Save Priority',
            confirmButtonColor: "#1f3b6d",
            showDenyButton:  hasPriority,
            denyButtonText:  '<i class="fa-solid fa-rotate-left me-1"></i>Reset to Allocation Order',
            denyButtonColor: "#6b7280",
            html: '<div class="text-start" style="font-size:13px;">'
                + '<div class="alert alert-light border py-2 mb-3" style="font-size:12px;">'
                + 'Drag items to set the running order for <b>' + escHtml(machineName) + '</b>. '
                + 'Item 1 runs first. This order is reflected in the Loading Plan grid.</div>'
                + buildListHtml(items)
                + '</div>',
            didOpen: function() {
                // Native HTML5 drag-and-drop for the priority list
                var list      = document.getElementById("priority-list");
                var dragging  = null;

                $(list).on("dragstart", ".priority-item", function(e) {
                    dragging = this;
                    $(this).css("opacity", "0.5");
                    e.originalEvent.dataTransfer.effectAllowed = "move";
                });

                $(list).on("dragend", ".priority-item", function() {
                    $(this).css("opacity", "");
                    $(".priority-item").removeClass("drag-over");
                    // Renumber the badges
                    $(list).find(".priority-item").each(function(i) {
                        $(this).find(".seq-badge").text(i + 1);
                    });
                });

                $(list).on("dragover", ".priority-item", function(e) {
                    e.preventDefault();
                    e.originalEvent.dataTransfer.dropEffect = "move";
                    if (this !== dragging) {
                        $(".priority-item").removeClass("drag-over");
                        $(this).addClass("drag-over");
                    }
                });

                $(list).on("dragleave", ".priority-item", function() {
                    $(this).removeClass("drag-over");
                });

                $(list).on("drop", ".priority-item", function(e) {
                    e.preventDefault();
                    if (this !== dragging) {
                        var target = this;
                        var allItems = $(list).find(".priority-item").toArray();
                        var fromIdx  = allItems.indexOf(dragging);
                        var toIdx    = allItems.indexOf(target);
                        if (fromIdx < toIdx) {
                            $(target).after(dragging);
                        } else {
                            $(target).before(dragging);
                        }
                    }
                    $(".priority-item").removeClass("drag-over");
                });
            },
            preConfirm: function() {
                // Read current order from the DOM
                var ordered = [];
                $("#priority-list .priority-item").each(function() {
                    ordered.push($(this).data("item"));
                });
                if (!ordered.length) { Swal.showValidationMessage("No items to save."); return false; }
                return ordered;
            }
        }).then(function(result) {
            if (result.isDenied) {
                // Reset to allocation order
                Swal.fire({
                    title: "Reset priority?",
                    html:  "Reverts <b>" + escHtml(machineName) + "</b> to its allocation order.",
                    icon: "warning", showCancelButton: true,
                    confirmButtonText: "Yes, reset", confirmButtonColor: "#6b7280"
                }).then(function(c) {
                    if (!c.isConfirmed) { return; }
                    $.ajax({
                        type: "DELETE",
                        url:  basePath + "/loadingplan/itempriority"
                            + "?planId="      + encodeURIComponent(planId)
                            + "&machineName=" + encodeURIComponent(machineName),
                        success: function() { loadLoadingPlan(); },
                        error:   function(xhr) { Swal.fire({ icon: "error", text: xhr.responseText || "" }); }
                    });
                });
                return;
            }
            if (!result.isConfirmed || !result.value) { return; }
            $.ajax({
                type: "POST", url: basePath + "/loadingplan/itempriority",
                contentType: "application/json",
                data: JSON.stringify({ planId: parseInt(planId, 10), machineName: machineName, orderedItems: result.value }),
                success: function() { loadLoadingPlan(); },
                error:   function(xhr) { Swal.fire({ icon: "error", title: "Save Failed", text: xhr.responseText || "" }); }
            });
        });
    }

    /* ─────────────────────────────────────────────────────────────
       Event handlers
       ───────────────────────────────────────────────────────────── */
    $(document).ready(function() {

        loadPlans();

        $("#planSelect").on("change", function () {
            setPlanFromSelection(this.value);
            if (planId) {
                loadLoadingPlan();
            } else {
                if (loadingPlanTable !== null) { loadingPlanTable.clear().draw(); }
                $("#lpReconBanner").hide();
            }
        });

        //---- WIP Tracker ----//
        $("#btnWipTracker").on("click", function() {
            window.location.href = basePath + "/wiptracker"
                + "?planId="      + encodeURIComponent(planId)
                + "&month="       + encodeURIComponent(planMonth)
                + "&year="        + encodeURIComponent(planYear)
                + "&machineCode=" + encodeURIComponent(machineCode)
                + "&monthName="   + encodeURIComponent(monthName);
        });

        //---- Recalculate ----//
        $("#recalculatePlan").on("click", function() { loadLoadingPlan(); });

        //---- Export (server-generated .xlsx — Excel '4. Loading Plan' layout + status colours) ----//
        $("#exportExcel").on("click", function() {
            if (!planId) { Swal.fire({ icon: "info", title: "No plan", text: "Open a plan first." }); return; }
            var useConv = $("#useConvertedCapa").is(":checked");
            window.location.href = basePath + "/loadingplan/export"
                + "?planId="          + encodeURIComponent(planId)
                + "&useConvertedCapa=" + (useConv ? "true" : "false");
        });

        //---- Print / PDF (PC-submit view) ----//
        $("#btnPrint").on("click", function() {
            var monthNames = ["January","February","March","April","May","June",
                              "July","August","September","October","November","December"];
            var period = (monthNames[planMonth-1] || "") + " " + planYear;
            $("#printTitle").text("Loading Plan \u2014 " + period);
            $("#printSub").text((machineCode ? "Machine type: " + machineCode + "  \u2502  " : "")
                              + "Printed " + new Date().toLocaleString());

            if (loadingPlanTable === null) { window.print(); return; }

            // Print ALL rows (not just the current page), then restore.
            var prevLen = loadingPlanTable.page.len();
            loadingPlanTable.page.len(-1).draw(false);

            // Give the browser a tick to render all rows before opening the dialog.
            setTimeout(function() {
                window.print();
                loadingPlanTable.page.len(prevLen).draw(false);
            }, 150);
        });

        //---- Fraction extended plot button ----//
        $(document).on("click", ".btn-set-fraction-plot", function(e) {
            e.stopPropagation();
            openFractionPlotDialog(
                $(this).data("machine"),
                $(this).data("item"),
                $(this).data("total"),
                $(this).data("share")
            );
        });

        //---- Item priority ----//
        $(document).on("click", ".btn-item-priority", function(e) {
            e.stopPropagation();
            openItemPriorityDialog($(this).data("machine"));
        });

        //---- Reassign ----//
        $(document).on("click", ".btn-reassign-machine", function(e) {
            e.stopPropagation();
            openReassignDialog($(this).data("machine"));
        });

        //---- Recovery ----//
        $(document).on("click", ".btn-recovery-machine", function(e) {
            e.stopPropagation();
            openRecoveryDialog($(this).data("machine"));
        });

        //---- Cell click -> manual edit ----//
        $(document).on("click", ".day-cell-editable .loading-date-value, .day-cell-editable .loading-maint-cell", function() {
            var inner   = $(this);
            var day     = Number(inner.data("day"));
            var dateStr = inner.data("date") || buildDateStr(day);
            var machine = inner.data("machine");
            var item    = inner.data("item");
            var orig    = Number(inner.data("original") || 0);
            if (!day || !machine || !item) { return; }
            var curVal = 0, curRem = "";
            $.each(lastLoadingRows, function(i, r) {
                if (r.machineName === machine && r.itemName === item) {
                    curVal = getDayValue(r, day);
                    curRem = getRemarks(r, day);
                    return false;
                }
            });
            openCellEditDialog(machine, item, dateStr, curVal, curRem, orig);
        });

    }); // end $(document).ready

</script>
</body>
</html>