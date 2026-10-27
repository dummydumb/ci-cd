<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>WIP Tracker</title>
    <%@include file="/Utilities/links.jsp" %>
    <style>
        :root {
            --wip-accent:       #0f5a47;
            --wip-accent-tint:  #e3efe9;
            --wip-page:         #f4f6f3;
            --wip-surface:      #ffffff;
            --wip-surface-sub:  #fafbf9;
            --wip-border:       #dfe5e0;
            --wip-border-soft:  #edf0ed;
            --wip-text:         #17211d;
            --wip-text-sub:     #55635d;
            --wip-text-muted:   #6a7771;
        }

        body { background: var(--wip-page); color: var(--wip-text); }

        .wip-wrap { padding: 20px 20px 24px; }

        .wip-head { display: flex; flex-wrap: wrap; align-items: center; gap: 12px; margin-bottom: 14px; }
        .wip-title { margin: 0; font-size: 22px; font-weight: 700; letter-spacing: -0.02em; }
        .wip-back {
            display: inline-flex; align-items: center; gap: 8px;
            background: var(--wip-surface); border: 1px solid var(--wip-border);
            color: var(--wip-accent); border-radius: 8px; padding: 7px 14px;
            font-weight: 600; text-decoration: none; font-size: 14px;
        }
        .wip-back:hover { background: var(--wip-accent-tint); }

        .wip-note {
            font-size: 12px; background: var(--wip-accent-tint);
            border: 1px solid #bcd9cd; border-radius: 8px;
            padding: 7px 12px; color: var(--wip-accent); font-weight: 600;
        }

        .wip-card {
            background: var(--wip-surface); border: 1px solid var(--wip-border);
            border-radius: 12px; padding: 14px 14px 10px;
        }

        .wip-toolbar { display: flex; flex-wrap: wrap; align-items: center; gap: 10px; margin: 2px 4px 10px; }
        .wip-period { color: var(--wip-text-sub); font-size: 13px; }
        .wip-btn {
            display: inline-flex; align-items: center; gap: 7px; font: inherit; font-size: 13px;
            font-weight: 600; border-radius: 8px; padding: 6px 12px; cursor: pointer;
            border: 1px solid var(--wip-border); background: var(--wip-surface); color: var(--wip-text-sub);
        }
        .wip-btn:hover { background: var(--wip-surface-sub); }
        .wip-btn-accent { background: var(--wip-accent); border-color: var(--wip-accent); color: #fff; }
        .wip-btn-accent:hover { background: #0c4a3b; }

        /* Summary cards */
        .wip-summary { display: flex; flex-wrap: wrap; gap: 10px; margin: 2px 4px 12px; }
        .wip-summary-card {
            flex: 1 1 150px; background: var(--wip-surface-sub);
            border: 1px solid var(--wip-border); border-radius: 10px; padding: 9px 12px;
        }
        .wip-summary-label { color: var(--wip-text-muted); font-size: 10px; text-transform: uppercase; font-weight: 800; letter-spacing: .04em; }
        .wip-summary-value { color: var(--wip-text); font-size: 18px; font-weight: 800; line-height: 1.2; }

        /* Legend */
        .wip-legend {
            display: flex; flex-wrap: wrap; gap: 14px; align-items: center;
            padding: 8px 12px; margin: 0 4px 12px; border: 1px solid var(--wip-border);
            border-radius: 8px; background: var(--wip-surface-sub); font-size: 12px; color: var(--wip-text-sub);
        }
        .legend-dot { display: inline-block; width: 13px; height: 13px; border-radius: 3px; margin-right: 4px; vertical-align: middle; }

        /* Table */
        .wip-table th, .wip-table td {
            border: 1px solid var(--wip-border) !important; text-align: center;
            vertical-align: middle; white-space: nowrap;
        }
        .wip-table th {
            background: var(--wip-accent) !important; color: #fff !important;
            font-weight: 700; text-transform: uppercase; font-size: 10px;
            letter-spacing: 0.02em; padding: 6px 4px !important;
        }
        .wip-table th.wip-weekend { background: #0c4a3b !important; }
        .wip-table tbody td { font-size: 11px; padding: 3px 5px !important; }

        .wip-item-name {
            text-align: left !important; font-weight: 700;
            font-size: 11px; padding-left: 9px !important; min-width: 160px;
        }
        .wip-col-total   { background: #fef3c7 !important; font-weight: 800; }
        .wip-col-current { background: var(--wip-accent-tint) !important; font-weight: 800; }
        .wip-col-var     { font-weight: 800; }

        .wip-day-cell  { min-width: 50px; max-width: 64px; font-weight: 600; font-size: 11px; }
        .wip-positive  { background: #d6efe4 !important; color: #0f5a47; }
        .wip-no-data   { background: #f3f4f3 !important; color: #b4bcb7; }

        /* Variance colouring */
        .var-match { background: #eef2f0 !important; color: var(--wip-text-muted); }
        .var-over  { background: #fef9c3 !important; color: #713f12; }
        .var-short { background: #fde2e1 !important; color: #991b1b; }

        /* Internal scroll so the page itself doesn't grow */
        #wip_table_wrapper .dataTables_filter,
        #wip_table_wrapper .dataTables_length,
        #wip_table_wrapper .dataTables_info,
        #wip_table_wrapper .dataTables_paginate { display: none; }
        .wip-scroll { max-height: calc(100vh - 360px); overflow: auto; border-radius: 8px; }
        .wip-scroll::-webkit-scrollbar { width: 10px; height: 10px; }
        .wip-scroll::-webkit-scrollbar-thumb { background: #cfd8d2; border-radius: 6px; }
    </style>
</head>
<body>
<%@include file="/Utilities/Header.jsp" %>

<div class="wip-wrap">

    <div class="wip-head">
        <a id="btnBack" class="wip-back"
           href="${pageContext.request.contextPath}/loadingplan?planId=${planId}&month=${month}&year=${year}&machineCode=${machineCode}&monthName=${monthName}">
            <i class="fa-solid fa-arrow-left"></i> Loading Plan
        </a>
        <h1 class="wip-title" id="pageTitle">WIP Tracker</h1>
        <span class="wip-note">
            <i class="fa-solid fa-lock me-1"></i>
            Based on the <b>original computed plan</b> &mdash; planner edits (reassign, recovery, conversion) do not change this view.
        </span>
    </div>

    <div class="wip-card">

        <!-- Summary cards -->
        <div class="wip-summary">
            <div class="wip-summary-card"><div class="wip-summary-label">Period</div><div class="wip-summary-value" id="sumPeriod">-</div></div>
            <div class="wip-summary-card"><div class="wip-summary-label">Items Tracked</div><div class="wip-summary-value" id="sumItems">-</div></div>
            <div class="wip-summary-card"><div class="wip-summary-label">Original Lots</div><div class="wip-summary-value" id="sumOriginal">-</div></div>
            <div class="wip-summary-card"><div class="wip-summary-label">Current Lots</div><div class="wip-summary-value" id="sumCurrent">-</div></div>
            <div class="wip-summary-card"><div class="wip-summary-label">Net Variance</div><div class="wip-summary-value" id="sumVariance">-</div></div>
        </div>

        <!-- Toolbar -->
        <div class="wip-toolbar">
            <span class="wip-period">Original plan plot by item &mdash; <b id="lblPeriod"></b></span>
            <div class="ms-auto d-flex gap-2">
                <button class="wip-btn" id="btnExport"><i class="fa-solid fa-file-export"></i> Export CSV</button>
                <button class="wip-btn wip-btn-accent" id="btnRefresh"><i class="fa-solid fa-rotate-right"></i> Refresh</button>
            </div>
        </div>

        <!-- Legend -->
        <div class="wip-legend">
            <b>Daily cells:</b>
            <span><span class="legend-dot" style="background:#d6efe4;border:1px solid #9fd3bf;"></span>Lots produced (original plan)</span>
            <span><span class="legend-dot" style="background:#f3f4f3;border:1px solid #dfe5e0;"></span>No production</span>
            <span class="ms-2"><b>Variance:</b></span>
            <span><span class="legend-dot" style="background:#eef2f0;border:1px solid #dfe5e0;"></span>Matches original</span>
            <span><span class="legend-dot" style="background:#fef9c3;border:1px solid #fcd34d;"></span>Over (current &gt; original)</span>
            <span><span class="legend-dot" style="background:#fde2e1;border:1px solid #fca5a5;"></span>Short (current &lt; original)</span>
        </div>

        <!-- Table -->
        <div class="wip-scroll">
            <table id="wip_table" class="table w-100 text-nowrap wip-table">
                <thead></thead>
                <tbody></tbody>
            </table>
        </div>

    </div>
</div>

<script>
    /* ── Plan context — injected by WipTrackerServlet ── */
    var planId      = '${planId}';
    var planMonth   = parseInt('${month}', 10);
    var planYear    = parseInt('${year}',  10);
    var basePath    = '${pageContext.request.contextPath}';
    var machineCode = '${machineCode}';
    var monthName   = '${monthName}';

    var daysInMonth = new Date(planYear, planMonth, 0).getDate();
    var MONTH_SHORT = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
    var monthShort  = MONTH_SHORT[planMonth - 1];

    /* State */
    var planRows = [];   // raw loading plan rows (useConvertedCapa=false)
    var itemData = [];   // computed per-item array

    function pad2(n) { return n < 10 ? "0" + n : "" + n; }
    function fmtWhole(v) { var n = Number(v); return isNaN(n) ? "0" : n.toFixed(0); }
    function fmtSigned(v) {
        var n = Math.round(Number(v) || 0);
        return (n > 0 ? "+" : "") + n;
    }
    function escHtml(v) {
        return String(v).replace(/&/g, "&amp;").replace(/</g, "&lt;")
                        .replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;");
    }

    function showLoading() {
        Swal.fire({
            title: '<span style="color:#17211d;font-size:18px;font-weight:600;">Please wait...</span>',
            html: '<div class="spinner-border text-success" role="status"></div>',
            allowOutsideClick: false, showConfirmButton: false
        });
    }

    /* Item family colour, canvas-toned */
    var _colorCache = {};
    var FAMILY_COLORS = [
        "#e3efe9","#e8f3ee","#eef2f0","#e6f0ec","#edf5f1",
        "#e9f1ed","#e4efe8","#eaf2ee","#e7f0eb","#ecf3ef"
    ];
    function getItemColor(itemName) {
        var family = String(itemName || "").replace(/\s+\S+$/, "").substring(0, 10);
        if (!_colorCache[family]) {
            var len = Object.keys(_colorCache).length;
            _colorCache[family] = FAMILY_COLORS[len % FAMILY_COLORS.length];
        }
        return _colorCache[family];
    }

    /* ── ORIGINAL computed day value (before any override) ──
     * The WIP Tracker is locked to the initial plot: reassign/recovery/conversion
     * overrides never change what we count as "produced".
     */
    function getOriginalDayValue(row, day) {
        if (row.originalDayValues && row.originalDayValues[day] !== undefined) {
            return Number(row.originalDayValues[day]);
        }
        if (row.dayValues && row.dayValues[day] !== undefined) {
            return Number(row.dayValues[day]);
        }
        return 0;
    }

    /* ── CURRENT (live) day value — after overrides. Used only for variance ── */
    function getCurrentDayValue(row, day) {
        if (row.dayValues && row.dayValues[day] !== undefined) {
            return Number(row.dayValues[day]);
        }
        return 0;
    }

    /* ── Load Loading Plan rows (original computed values) ── */
    function loadAll() {
        showLoading();
        $.ajax({
            type: "GET", url: basePath + "/loadingplan/l",
            data: { planId: planId, useConvertedCapa: false }, dataType: "json",
            success: function(rows) {
                planRows = rows || [];
                computeItemData();
                renderTable();
                updateSummary();
                Swal.close();
            },
            error: function(xhr) {
                Swal.close();
                Swal.fire({ icon: "error", title: "Error", text: xhr.responseText || "Error loading plan." });
            }
        });
    }

    /* ── Aggregate rows by item → daily ORIGINAL lots + CURRENT totals ── */
    function computeItemData() {
        var produced   = {};   // itemName → original lots per day [1..31]
        var origTotal  = {};   // itemName → total original lots
        var currTotal  = {};   // itemName → total current (live) lots

        $.each(planRows, function(i, r) {
            if (!r.itemName)                     { return; }
            if (r.qualifiedOnly)                 { return; }
            if (r.machineRole === "Unallocated") { return; }

            if (!produced[r.itemName]) {
                produced[r.itemName]  = [];
                origTotal[r.itemName] = 0;
                currTotal[r.itemName] = 0;
                for (var x = 0; x <= 31; x++) { produced[r.itemName][x] = 0; }
            }

            for (var d = 1; d <= daysInMonth; d++) {
                var orig = getOriginalDayValue(r, d);
                var curr = getCurrentDayValue(r, d);
                produced[r.itemName][d] += orig;
                origTotal[r.itemName]   += orig;
                currTotal[r.itemName]   += curr;
            }
        });

        itemData = [];
        var itemNames = Object.keys(produced).sort();

        $.each(itemNames, function(i, name) {
            var oTotal = Math.round(origTotal[name] || 0);
            var cTotal = Math.round(currTotal[name] || 0);
            var dailyProduced = [];
            for (var d = 1; d <= daysInMonth; d++) {
                dailyProduced.push(produced[name][d] || 0);
            }
            itemData.push({
                itemName:      name,
                totalOriginal: oTotal,
                totalCurrent:  cTotal,
                variance:      cTotal - oTotal,
                dailyProduced: dailyProduced
            });
        });
    }

    function varClass(v) {
        if (v > 0) { return "var-over"; }
        if (v < 0) { return "var-short"; }
        return "var-match";
    }

    /* ── Render the table ── */
    function renderTable() {
        var thead = document.querySelector("#wip_table thead");
        var tbody = document.querySelector("#wip_table tbody");
        thead.innerHTML = "";
        tbody.innerHTML = "";

        /* Header */
        var tr1 = document.createElement("tr");
        var fixedCols = [
            { h: "Item",     cls: "wip-item-name", style: "min-width:160px;text-align:left;" },
            { h: "Original", cls: "", style: "" },
            { h: "Current",  cls: "", style: "" },
            { h: "Variance", cls: "", style: "" }
        ];
        $.each(fixedCols, function(i, col) {
            var th = document.createElement("th");
            th.innerHTML = col.h;
            if (col.style) { th.style.cssText = col.style; }
            tr1.appendChild(th);
        });
        for (var d = 1; d <= daysInMonth; d++) {
            var dt    = new Date(planYear, planMonth - 1, d);
            var dName = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"][dt.getDay()];
            var isWk  = dt.getDay() === 0 || dt.getDay() === 6;
            var th    = document.createElement("th");
            th.innerHTML = dName + "<br>" + d + "-" + monthShort;
            th.className = "wip-day-cell" + (isWk ? " wip-weekend" : "");
            th.style.fontSize = "9px";
            tr1.appendChild(th);
        }
        thead.appendChild(tr1);

        /* Body */
        $.each(itemData, function(i, item) {
            var tr = document.createElement("tr");

            var tdName = document.createElement("td");
            tdName.className = "wip-item-name";
            tdName.style.background = getItemColor(item.itemName);
            tdName.textContent = item.itemName;
            tr.appendChild(tdName);

            var tdOrig = document.createElement("td");
            tdOrig.className = "wip-col-total";
            tdOrig.textContent = fmtWhole(item.totalOriginal);
            tdOrig.title = "Original computed lots for " + item.itemName;
            tr.appendChild(tdOrig);

            var tdCurr = document.createElement("td");
            tdCurr.className = "wip-col-current";
            tdCurr.textContent = fmtWhole(item.totalCurrent);
            tdCurr.title = "Current (live) lots after planner edits";
            tr.appendChild(tdCurr);

            var tdVar = document.createElement("td");
            tdVar.className = "wip-col-var " + varClass(item.variance);
            tdVar.textContent = (item.variance === 0) ? "0" : fmtSigned(item.variance);
            tdVar.title = "Current minus Original";
            tr.appendChild(tdVar);

            for (var d = 0; d < daysInMonth; d++) {
                var tdDay = document.createElement("td");
                tdDay.className = "wip-day-cell";
                var lotsToday = item.dailyProduced[d] || 0;
                if (lotsToday > 0) {
                    tdDay.className += " wip-positive";
                    tdDay.textContent = lotsToday;
                } else {
                    tdDay.className += " wip-no-data";
                    tdDay.textContent = "—";
                }
                tdDay.title = "Day " + (d + 1) + " — " + item.itemName + ": " + lotsToday + " lots (original plan)";
                tr.appendChild(tdDay);
            }

            tbody.appendChild(tr);
        });

        if (itemData.length === 0) {
            var emptyRow = document.createElement("tr");
            var emptyTd  = document.createElement("td");
            emptyTd.colSpan   = 4 + daysInMonth;
            emptyTd.innerHTML = '<span class="text-muted">No allocated items found. Make sure the Loading Plan has been computed.</span>';
            emptyTd.style.cssText = "text-align:center;padding:20px;";
            emptyRow.appendChild(emptyTd);
            tbody.appendChild(emptyRow);
        }
    }

    /* ── Summary cards ── */
    function updateSummary() {
        var monthNames = ["January","February","March","April","May","June",
                          "July","August","September","October","November","December"];
        var label = (monthNames[planMonth - 1] || "") + " " + planYear;
        document.getElementById("lblPeriod").textContent = label;
        document.getElementById("sumPeriod").textContent = label;
        document.getElementById("sumItems").textContent  = itemData.length;

        var totOrig = 0, totCurr = 0;
        $.each(itemData, function(i, item) {
            totOrig += item.totalOriginal;
            totCurr += item.totalCurrent;
        });
        var net = totCurr - totOrig;

        document.getElementById("sumOriginal").textContent = fmtWhole(totOrig);
        document.getElementById("sumCurrent").textContent  = fmtWhole(totCurr);

        var vEl = document.getElementById("sumVariance");
        vEl.textContent = (net === 0) ? "0" : fmtSigned(net);
        vEl.style.color = net > 0 ? "#713f12" : (net < 0 ? "#991b1b" : "#6a7771");
    }

    /* ── CSV Export ── */
    function exportCsv() {
        var header = ["Item","Original","Current","Variance"];
        for (var d = 1; d <= daysInMonth; d++) { header.push(d + "-" + monthShort); }
        var rows = [header];

        $.each(itemData, function(i, item) {
            var row = [item.itemName, fmtWhole(item.totalOriginal), fmtWhole(item.totalCurrent), fmtSigned(item.variance)];
            $.each(item.dailyProduced, function(j, lots) { row.push(lots); });
            rows.push(row);
        });

        var csv = rows.map(function(r) {
            return r.map(function(c) { return '"' + String(c).replace(/"/g, '""') + '"'; }).join(",");
        }).join("\n");

        var blob = new Blob([csv], { type: "text/csv" });
        var url  = URL.createObjectURL(blob);
        var a    = document.createElement("a");
        a.href   = url;
        a.download = "WIP_Tracker_" + planYear + "_" + pad2(planMonth) + ".csv";
        a.click();
        URL.revokeObjectURL(url);
    }

    /* ── Event handlers ── */
    $(document).ready(function() {
        var monthNames = ["January","February","March","April","May","June",
                          "July","August","September","October","November","December"];
        document.getElementById("pageTitle").textContent =
            "WIP Tracker — " + (monthNames[planMonth - 1] || "") + " " + planYear;

        loadAll();

        $("#btnRefresh").on("click", function() { loadAll(); });
        $("#btnExport").on("click",  function() { exportCsv(); });
    });
</script>
</body>
</html>
