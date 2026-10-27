<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Plotting Summary</title>
    <%@include file="/Utilities/links.jsp" %>

    <style>
        :root {
            --pl-accent:        #0f5a47;
            --pl-accent-tint:   #e3efe9;
            --pl-page:          #f4f6f3;
            --pl-surface:       #ffffff;
            --pl-surface-sub:   #fafbf9;
            --pl-border:        #dfe5e0;
            --pl-border-soft:   #edf0ed;
            --pl-border-input:  #cfd8d2;
            --pl-text:          #17211d;
            --pl-text-sub:      #55635d;
            --pl-text-muted:    #6a7771;
            /* Type colors (carry planning meaning) */
            --pl-type-me:       #B78DE1;
            --pl-type-eval:     #66FF66;
            --pl-type-other:    #FFE24D;
        }

        body { background: var(--pl-page); color: var(--pl-text); font-family: 'FSEmericLight', Helvetica, 'Segoe UI', sans-serif; font-size: 14px; }
        .pl-wrap { max-width: 100%; margin: 0 auto; padding: 24px 20px 48px; }

        .pl-head { display: flex; flex-wrap: wrap; align-items: flex-end; justify-content: space-between; gap: 16px 24px; margin-bottom: 16px; }
        .pl-title { margin: 0; font-size: 26px; font-weight: 700; letter-spacing: -0.02em; line-height: 1.15; }
        .pl-subtitle { margin: 4px 0 0; color: var(--pl-text-sub); font-size: 14px; }

        .pl-btn-primary { height: 42px; padding: 0 16px; border: 0; border-radius: 8px; background: var(--pl-accent); color: #fff; font: inherit; font-weight: 600; cursor: pointer; display: inline-flex; align-items: center; gap: 8px; }
        .pl-btn-primary:hover { background: #0c4a3b; color: #fff; }
        .pl-btn-ghost { height: 42px; padding: 0 14px; border: 1px solid var(--pl-border-input); border-radius: 8px; background: var(--pl-surface); color: var(--pl-text); font: inherit; font-weight: 600; cursor: pointer; display: inline-flex; align-items: center; gap: 8px; }
        .pl-btn-ghost:hover { background: var(--pl-surface-sub); }

        .pl-toolbar { display: flex; flex-wrap: wrap; align-items: center; gap: 12px; margin-bottom: 14px; }
        .pl-month { height: 42px; padding: 0 12px; border: 1px solid var(--pl-border-input); border-radius: 8px; background: var(--pl-surface); font: inherit; color: var(--pl-text); }
        .pl-legend { display: flex; align-items: center; gap: 14px; margin-left: auto; color: var(--pl-text-sub); font-size: 13px; }
        .pl-legend .dot { display: inline-block; width: 12px; height: 12px; border-radius: 3px; margin-right: 5px; vertical-align: -1px; }

        .pl-card { background: var(--pl-surface); border: 1px solid var(--pl-border); border-radius: 12px; padding: 8px; }

        table.pl-matrix { width: 100%; border-collapse: collapse; font-size: 13px; }
        table.pl-matrix thead th {
            background: var(--pl-surface-sub); color: var(--pl-text-sub); font-size: 11px; font-weight: 600;
            letter-spacing: 0.04em; text-transform: uppercase; text-align: left; padding: 8px 10px;
            border-bottom: 1px solid var(--pl-border); white-space: nowrap; position: sticky; top: 0; z-index: 2;
        }
        table.pl-matrix tbody td { padding: 7px 10px; border-bottom: 1px solid var(--pl-border-soft); vertical-align: middle; white-space: nowrap; }
        table.pl-matrix tbody tr:hover td { background: var(--pl-surface-sub); }

        .pl-day-head { text-align: center; min-width: 54px; }
        .pl-day-head.weekend { background: #eef1ef; }
        .pl-day-head .dow { display: block; font-size: 10px; color: var(--pl-text-muted); }
        .pl-day-cell { text-align: center; padding: 2px !important; }
        .pl-day-cell.weekend { background: #f3f5f3; }
        .pl-plot { display: block; border-radius: 4px; padding: 5px 2px; font-weight: 700; color: #17211d; font-size: 12px; }

        .pl-chip { display: inline-block; padding: 2px 8px; border-radius: 6px; background: var(--pl-accent-tint); color: var(--pl-accent); font-family: 'FSEmericLight', Helvetica, monospace; font-size: 12px; font-weight: 600; }
        .pl-muted { color: var(--pl-text-muted); }

        .pl-act { width: 34px; height: 34px; border-radius: 7px; background: var(--pl-surface); cursor: pointer; display: inline-flex; align-items: center; justify-content: center; margin-left: 3px; }
        .pl-act-edit { border: 1px solid var(--pl-border); color: #3d4a45; }
        .pl-act-edit:hover { background: var(--pl-accent-tint); color: var(--pl-accent); }
        .pl-act-delete { border: 1px solid #f0d5d2; color: #a32a1f; }
        .pl-act-delete:hover { background: #a32a1f; color: #fff; }

        .pl-empty { padding: 40px 20px; text-align: center; color: var(--pl-text-muted); }
        .pl-scroll { overflow-x: auto; max-height: 68vh; overflow-y: auto; }

        .pl-asterisk { color: #c0392b; }

        /* SweetAlert form */
        .swal2-popup .form-floating > .form-control,
        .swal2-popup .form-floating > .form-select { border-radius: 8px; }
        .swal2-popup .form-floating > label { padding-left: 1rem; }
        .pl-section-label { display:block; font-size:12px; font-weight:700; letter-spacing:.04em; text-transform:uppercase; color:#55635d; margin:8px 0 6px; text-align:left; }

        .pl-detail-table { width: 100%; border-collapse: collapse; font-size: 13px; }
        .pl-detail-table th { text-align: left; font-size: 11px; font-weight: 600; letter-spacing: .05em; text-transform: uppercase; color: #6a7771; padding: 4px 6px; }
        .pl-detail-table td { padding: 3px 6px; }
        .pl-detail-table .form-control { height: 38px; }
        .pl-row-del { width: 34px; height: 34px; border: 1px solid #f0d5d2; border-radius: 6px; background: #fff; color: #a32a1f; cursor: pointer; }
        .pl-row-del:hover { background: #a32a1f; color: #fff; }
        .pl-detail-foot { display: flex; align-items: center; justify-content: space-between; margin-top: 8px; }
        .pl-add-row { border: 1px solid var(--pl-accent); background: var(--pl-accent-tint); color: var(--pl-accent); border-radius: 8px; height: 36px; padding: 0 12px; font: inherit; font-weight: 600; cursor: pointer; }
        .pl-total { font-weight: 700; color: var(--pl-text); }
    </style>
</head>

<body>
<%@include file="/Utilities/Header.jsp" %>

<div class="pl-wrap">

    <div class="pl-head">
        <div>
            <h1 class="pl-title">Plotting Summary</h1>
            <p class="pl-subtitle">Monthly calendar of evaluations and maintenance (PM / ME Improvement) that affect operation.</p>
        </div>
        <button type="button" class="pl-btn-primary" id="add">
            <i class="fa-solid fa-plus"></i> Add Plotting
        </button>
    </div>

    <div class="pl-toolbar">
        <input type="month" class="pl-month" id="monthYearFilter" aria-label="Select month">
        <button type="button" class="pl-btn-ghost" id="exportExcel"><i class="fa-solid fa-file-excel"></i> Export</button>
        <span class="pl-legend">
            <span><span class="dot" style="background:var(--pl-type-me);"></span>ME Improvement</span>
            <span><span class="dot" style="background:var(--pl-type-eval);"></span>Evaluation</span>
            <span><span class="dot" style="background:var(--pl-type-other);"></span>PM / Other</span>
        </span>
    </div>

    <div class="pl-card">
        <div class="pl-scroll">
            <table id="plotting_table" class="pl-matrix w-100">
                <thead></thead>
                <tbody></tbody>
            </table>
        </div>
    </div>

</div>

<script>
    $(document).ready(function () {

        const contextPath = "${pageContext.request.contextPath}";
        const baseUrl = contextPath + "/plottingsummary";
        const itemUrl = contextPath + "/item/l";
        const machineTypeUrl = contextPath + "/machinetype/la";
        const machineUrl = contextPath + "/machine/l";

        const DOW = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        const MON = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

        const CATEGORIES = ["PM", "ILT-Improvement", "Evaluation", "Evaluation-IPC Running", "Complete Evaluation"];
        const TYPES = ["PM", "ME Improvement", "Evaluation"];
        const ITEM_TYPES = ["N/A", "Existing"];
        const WOS_TYPES = ["N/A", "Mass Pro", "Evaluation"];

        let refItems = [];
        let refTypes = [];
        let refMachines = [];
        let currentRows = [];

        /* ---------- Helpers ---------- */
        function showLoadingScreen() {
            Swal.fire({
                title: '<span style="color:#17211d; font-size:22px; font-weight:600;">Please wait...</span>',
                html: '<div class="spinner"></div>',
                allowOutsideClick: false,
                showConfirmButton: false
            });
        }

        function escapeHtml(value) {
            if (value == null) { return ""; }
            return String(value)
                .replace(/&/g, "&amp;")
                .replace(/</g, "&lt;")
                .replace(/>/g, "&gt;")
                .replace(/"/g, "&quot;")
                .replace(/'/g, "&#039;");
        }

        function pad2(n) { return (n < 10 ? "0" : "") + n; }

        /* Gson may serialize LocalDate as an object; handle both shapes. */
        function toIsoDate(value) {
            if (!value) { return ""; }
            if (typeof value === "object") {
                // Gson: LocalDate -> {year, month, day}; LocalDateTime -> {year, monthValue, dayOfMonth};
                // some versions nest under "date". Handle all.
                const src = value.date ? value.date : value;
                const y = src.year;
                const m = (src.monthValue != null) ? src.monthValue : src.month;
                const d = (src.dayOfMonth != null) ? src.dayOfMonth : src.day;
                if (y && m && d) { return y + "-" + pad2(m) + "-" + pad2(d); }
                return "";
            }
            return String(value).split("T")[0];
        }

        function trimNum(v) {
            if (v == null) { return ""; }
            const n = Number(v);
            if (isNaN(n) || n === 0) { return ""; }
            return (n === Math.floor(n)) ? String(n) : n.toFixed(1);
        }

        function typeColor(type) {
            if (type === "ME Improvement") { return "var(--pl-type-me)"; }
            if (type === "Evaluation") { return "var(--pl-type-eval)"; }
            return "var(--pl-type-other)";
        }

        function getSelectedMonthYear() {
            const val = $("#monthYearFilter").val();
            if (!val) {
                const now = new Date();
                return { year: now.getFullYear(), month: now.getMonth() + 1 };
            }
            const parts = val.split("-");
            return { year: Number(parts[0]), month: Number(parts[1]) };
        }

        /* Build a date -> hours map for a row from its detail rows. */
        function hoursByDate(row) {
            const map = {};
            const details = row.details || [];
            for (let i = 0; i < details.length; i++) {
                const iso = toIsoDate(details[i].scheduleDate);
                if (iso) { map[iso] = details[i].hours; }
            }
            return map;
        }

        /* ---------- Matrix render ---------- */
        function renderMatrix(rows) {
            const my = getSelectedMonthYear();
            const daysInMonth = new Date(my.year, my.month, 0).getDate();

            // Header
            let head = '<tr>'
                + '<th>Evaluation &amp; PM Schedule</th>'
                + '<th>Category</th>'
                + '<th>Type</th>'
                + '<th>Item</th>'
                + '<th>Item Type</th>'
                + '<th>Plan</th>'
                + '<th>Lots</th>'
                + '<th>WOS</th>'
                + '<th>Machine Type</th>'
                + '<th>Stacking M/C</th>'
                + '<th>PIC</th>';
            for (let d = 1; d <= daysInMonth; d++) {
                const dt = new Date(my.year, my.month - 1, d);
                const weekend = (dt.getDay() === 0 || dt.getDay() === 6) ? " weekend" : "";
                head += '<th class="pl-day-head' + weekend + '"><span class="dow">' + DOW[dt.getDay()] + '</span>'
                      + pad2(d) + '</th>';
            }
            head += '<th style="text-align:right;">Actions</th></tr>';
            $("#plotting_table thead").html(head);

            // Body
            const body = $("#plotting_table tbody").empty();
            if (!rows || rows.length === 0) {
                const span = 11 + daysInMonth + 1;
                body.html('<tr><td colspan="' + span + '"><div class="pl-empty">No plotting entries for this month.</div></td></tr>');
                return;
            }

            for (let r = 0; r < rows.length; r++) {
                const row = rows[r];
                const item = row.item || {};
                const mt = row.machineType || {};
                const sm = row.stackingMachine || {};
                const map = hoursByDate(row);
                const color = typeColor(row.type);

                let tr = '<tr>'
                    + '<td>' + escapeHtml(row.evaluation) + '</td>'
                    + '<td>' + escapeHtml(row.category) + '</td>'
                    + '<td>' + escapeHtml(row.type) + '</td>'
                    + '<td><span class="pl-chip">' + escapeHtml(item.itemName) + '</span></td>'
                    + '<td>' + escapeHtml(row.itemType) + '</td>'
                    + '<td>' + escapeHtml(row.plan) + '</td>'
                    + '<td style="text-align:right;">' + (row.noOfLots != null ? row.noOfLots : "") + '</td>'
                    + '<td>' + escapeHtml(row.wosType) + '</td>'
                    + '<td>' + escapeHtml(mt.machineCode) + '</td>'
                    + '<td>' + (sm.machineName ? escapeHtml(sm.machineName) : '<span class="pl-muted">&mdash;</span>') + '</td>'
                    + '<td>' + escapeHtml(row.pic) + '</td>';

                for (let d = 1; d <= daysInMonth; d++) {
                    const dt = new Date(my.year, my.month - 1, d);
                    const weekend = (dt.getDay() === 0 || dt.getDay() === 6) ? " weekend" : "";
                    const iso = my.year + "-" + pad2(my.month) + "-" + pad2(d);
                    const h = trimNum(map[iso]);
                    if (h !== "") {
                        tr += '<td class="pl-day-cell' + weekend + '"><span class="pl-plot" style="background:' + color + ';">' + h + '</span></td>';
                    } else {
                        tr += '<td class="pl-day-cell' + weekend + '"></td>';
                    }
                }

                tr += '<td style="text-align:right;">'
                    + '<button type="button" class="pl-act pl-act-edit js-edit" title="Edit" data-id="' + row.plottingId + '"><i class="fa-solid fa-pen"></i></button>'
                    + '<button type="button" class="pl-act pl-act-delete js-delete" title="Delete" data-id="' + row.plottingId + '"><i class="fa-solid fa-trash"></i></button>'
                    + '</td></tr>';
                body.append(tr);
            }
        }

        function loadMatrix() {
            const my = getSelectedMonthYear();
            $.ajax({
                url: baseUrl + "/l",
                type: "GET",
                data: { month: my.month, year: my.year },
                dataType: "json",
                success: function (rows) {
                    currentRows = rows || [];
                    renderMatrix(currentRows);
                },
                error: function (xhr) {
                    Swal.fire({ icon: "error", title: "Failed", text: xhr.responseText, confirmButtonColor: "#0f5a47" });
                }
            });
        }

        /* ---------- Reference dropdowns ---------- */
        function optionList(values, selected) {
            let html = '<option value="">- Select -</option>';
            for (let i = 0; i < values.length; i++) {
                const sel = values[i] === selected ? "selected" : "";
                html += '<option value="' + escapeHtml(values[i]) + '" ' + sel + '>' + escapeHtml(values[i]) + '</option>';
            }
            return html;
        }
        function itemOptions(selectedId) {
            let html = '<option value="">Select item</option>';
            for (let i = 0; i < refItems.length; i++) {
                const it = refItems[i];
                const sel = String(it.itemId) === String(selectedId) ? "selected" : "";
                html += '<option value="' + it.itemId + '" ' + sel + '>' + escapeHtml(it.itemName) + '</option>';
            }
            return html;
        }
        function typeOptions(selectedId) {
            let html = '<option value="">Select machine type</option>';
            for (let i = 0; i < refTypes.length; i++) {
                const t = refTypes[i];
                const sel = String(t.machineTypeId) === String(selectedId) ? "selected" : "";
                html += '<option value="' + t.machineTypeId + '" ' + sel + '>' + escapeHtml(t.machineCode) + " — " + escapeHtml(t.machineName) + '</option>';
            }
            return html;
        }
        function machineOptions(selectedId) {
            let html = '<option value="">None</option>';
            for (let i = 0; i < refMachines.length; i++) {
                const m = refMachines[i];
                const sel = String(m.machineId) === String(selectedId) ? "selected" : "";
                html += '<option value="' + m.machineId + '" ' + sel + '>' + escapeHtml(m.machineName) + '</option>';
            }
            return html;
        }

        /* ---------- Modal form ---------- */
        function selectFloat(id, label, optionsHtml, required) {
            const star = required ? '<span class="pl-asterisk">*</span> ' : '';
            return '<div class="col-md-4 mb-2"><div class="form-floating">'
                + '<select class="form-select" id="' + id + '">' + optionsHtml + '</select>'
                + '<label class="ms-2" for="' + id + '">' + star + escapeHtml(label) + '</label>'
                + '</div></div>';
        }
        function textFloat(id, label, value, required) {
            const star = required ? '<span class="pl-asterisk">*</span> ' : '';
            return '<div class="col-md-4 mb-2"><div class="form-floating">'
                + '<input type="text" class="form-control" id="' + id + '" placeholder="' + escapeHtml(label) + '" value="' + escapeHtml(value) + '">'
                + '<label class="ms-2" for="' + id + '">' + star + escapeHtml(label) + '</label>'
                + '</div></div>';
        }

        function buildForm(d) {
            d = d || {};
            const item = d.item || {};
            const mt = d.machineType || {};
            const sm = d.stackingMachine || {};
            return ''
                + '<form id="plottingform" style="width:100%; overflow:visible;">'
                +   '<span class="pl-section-label">Classification</span>'
                +   '<div class="row g-2 mx-auto">'
                +     selectFloat("swal-itemid", "Item", itemOptions(item.itemId), true)
                +     selectFloat("swal-category", "Category", optionList(CATEGORIES, d.category), true)
                +     selectFloat("swal-type", "Type", optionList(TYPES, d.type), true)
                +   '</div>'
                +   '<div class="row g-2 mx-auto">'
                +     selectFloat("swal-itemtype", "Item Type", optionList(ITEM_TYPES, d.itemType), false)
                +     selectFloat("swal-wostype", "WOS Type", optionList(WOS_TYPES, d.wosType), false)
                +     textFloat("swal-plan", "Plan", d.plan, false)
                +   '</div>'
                +   '<div class="row g-2 mx-auto">'
                +     selectFloat("swal-machinetypeid", "Machine Type", typeOptions(mt.machineTypeId), true)
                +     selectFloat("swal-stackingmachineid", "Stacking Machine", machineOptions(sm.machineId), false)
                +     '<div class="col-md-4 mb-2"><div class="form-floating">'
                +       '<input type="number" class="form-control" id="swal-nooflots" min="0" placeholder="No. of Lots" value="' + (d.noOfLots != null ? d.noOfLots : "") + '">'
                +       '<label class="ms-2" for="swal-nooflots">No. of Lots</label>'
                +     '</div></div>'
                +   '</div>'
                +   '<div class="row g-2 mx-auto">'
                +     '<div class="col-md-12 mb-2"><div class="form-floating">'
                +       '<input type="text" class="form-control" id="swal-evaluation" placeholder="Evaluation & PM Schedule" value="' + escapeHtml(d.evaluation) + '">'
                +       '<label class="ms-2" for="swal-evaluation">Evaluation &amp; PM Schedule</label>'
                +     '</div></div>'
                +   '</div>'
                +   '<span class="pl-section-label">Schedule Range</span>'
                +   '<div class="row g-2 mx-auto">'
                +     '<div class="col-md-4 mb-2"><div class="form-floating">'
                +       '<input type="date" class="form-control" id="swal-datepreferred" placeholder="Preferred From" value="' + toIsoDate(d.datePreferred) + '">'
                +       '<label class="ms-2" for="swal-datepreferred"><span class="pl-asterisk">*</span> Date Preferred From</label>'
                +     '</div></div>'
                +     '<div class="col-md-4 mb-2"><div class="form-floating">'
                +       '<input type="date" class="form-control" id="swal-datepreferredto" placeholder="Preferred To" value="' + toIsoDate(d.datePreferredTo) + '">'
                +       '<label class="ms-2" for="swal-datepreferredto"><span class="pl-asterisk">*</span> Date Preferred To</label>'
                +     '</div></div>'
                +     textFloat("swal-pic", "PIC", d.pic, false)
                +   '</div>'
                +   '<div class="row g-2 mx-auto">'
                +     '<div class="col-md-4 mb-2"><div class="form-floating">'
                +       '<input type="text" class="form-control" id="swal-preferredrange" readonly placeholder="Preferred Range">'
                +       '<label class="ms-2" for="swal-preferredrange">Preferred Range Preview</label>'
                +     '</div></div>'
                +     '<div class="col-md-4 mb-2"><div class="form-floating">'
                +       '<input type="text" class="form-control" id="swal-totalduration" readonly placeholder="Total Duration">'
                +       '<label class="ms-2" for="swal-totalduration">Total Duration (Hours)</label>'
                +     '</div></div>'
                +   '</div>'
                +   '<div class="row g-2 mx-auto">'
                +     '<div class="col-md-4 mb-2"><div class="form-floating">'
                +       '<input type="date" class="form-control" id="swal-confirmeddate" placeholder="Confirmed From" value="' + toIsoDate(d.confirmedDate) + '">'
                +       '<label class="ms-2" for="swal-confirmeddate">Confirmed Date From (optional)</label>'
                +     '</div></div>'
                +     '<div class="col-md-8 mb-2"><div class="form-floating">'
                +       '<input type="text" class="form-control" id="swal-confirmedrange" readonly placeholder="Confirmed Range">'
                +       '<label class="ms-2" for="swal-confirmedrange">Confirmed Range Preview</label>'
                +     '</div></div>'
                +   '</div>'
                +   '<span class="pl-section-label">Hours per Day (max 24)</span>'
                +   '<div class="row g-2 mx-auto" id="pl-daily-container"></div>'
                + '</form>';
        }

        /* ---- Date range helpers ---- */
        const MONTHS_FULL = ["January","February","March","April","May","June","July","August","September","October","November","December"];
        function parseIsoInput(v) {
            if (!v) { return null; }
            const parts = String(v).split("-");
            if (parts.length < 3) { return null; }
            return { year: Number(parts[0]), month: Number(parts[1]), day: Number(parts[2]) };
        }
        function toIsoParsed(p) { return p.year + "-" + pad2(p.month) + "-" + pad2(p.day); }
        function addDaysParsed(p, n) {
            const dt = new Date(p.year, p.month - 1, p.day);
            dt.setDate(dt.getDate() + n);
            return { year: dt.getFullYear(), month: dt.getMonth() + 1, day: dt.getDate() };
        }
        function daysBetweenParsed(a, b) {
            const da = new Date(a.year, a.month - 1, a.day);
            const db = new Date(b.year, b.month - 1, b.day);
            return Math.round((db - da) / 86400000);
        }
        function rangeDays(fromV, toV) {
            const a = parseIsoInput(fromV), b = parseIsoInput(toV);
            if (!a || !b) { return 0; }
            const d = daysBetweenParsed(a, b);
            return d < 0 ? 0 : d + 1;
        }
        function rangePreview(a, b) {
            if (!a || !b) { return ""; }
            const sm = MONTHS_FULL[a.month - 1], em = MONTHS_FULL[b.month - 1];
            if (a.year === b.year && a.month === b.month) {
                return a.day === b.day ? (sm + " " + a.day) : (sm + " " + a.day + "-" + b.day);
            }
            return sm + " " + a.day + " - " + em + " " + b.day;
        }

        /* ---- Build the per-day hour inputs for the preferred range ---- */
        function buildDailyInputs() {
            const fromV = $("#swal-datepreferred").val();
            const toV   = $("#swal-datepreferredto").val();
            const a = parseIsoInput(fromV), b = parseIsoInput(toV);
            const container = $("#pl-daily-container").empty();
            $("#swal-preferredrange").val("");
            $("#swal-totalduration").val("");

            if (!a || !b || rangeDays(fromV, toV) <= 0) { updateConfirmedPreview(); return; }

            $("#swal-preferredrange").val(rangePreview(a, b));
            const n = rangeDays(fromV, toV);
            for (let i = 0; i < n; i++) {
                const cur = addDaysParsed(a, i);
                const iso = toIsoParsed(cur);
                const label = MONTHS_FULL[cur.month - 1] + " " + cur.day;
                container.append(''
                    + '<div class="col-md-3 mb-2"><div class="form-floating">'
                    +   '<input type="number" class="form-control pl-day-hours" data-date="' + iso + '" '
                    +     'min="0" max="24" step="0.5" placeholder="' + label + '" '
                    +     'oninput="if(Number(this.value)>24){this.value=24;}">'
                    +   '<label class="ms-2">' + label + ' (h)</label>'
                    + '</div></div>');
            }
            $("#pl-daily-container").off("input", ".pl-day-hours").on("input", ".pl-day-hours", recalcTotals);
            recalcTotals();
            updateConfirmedPreview();
        }

        function recalcTotals() {
            let total = 0;
            $(".pl-day-hours").each(function () {
                let h = parseFloat($(this).val());
                if (!isNaN(h) && h > 24) { h = 24; $(this).val(24); }
                if (!isNaN(h) && h > 0) { total += h; }
            });
            $("#swal-totalduration").val(total > 0 ? (total % 1 === 0 ? total : total.toFixed(1)) : "");
        }

        function updateConfirmedPreview() {
            const confFrom = $("#swal-confirmeddate").val();
            const days = rangeDays($("#swal-datepreferred").val(), $("#swal-datepreferredto").val());
            const a = parseIsoInput(confFrom);
            if (!a || days <= 0) { $("#swal-confirmedrange").val(""); return; }
            const b = addDaysParsed(a, days - 1);
            $("#swal-confirmedrange").val(rangePreview(a, b));
        }

        function populateHoursFromDetails(details) {
            const map = {};
            for (let i = 0; i < (details || []).length; i++) {
                const iso = toIsoDate(details[i].scheduleDate);
                if (iso) { map[iso] = details[i].hours; }
            }
            $(".pl-day-hours").each(function () {
                const key = $(this).attr("data-date");
                if (key && map[key] != null) { $(this).val(map[key]); }
            });
            recalcTotals();
        }

        /* Seed the "Preferred To" from saved details (last scheduled day) on edit. */
        function wireRangeGrid(initialDetails) {
            // On edit: derive the preferred-to from the saved details span.
            if (initialDetails && initialDetails.length > 0) {
                let maxIso = null;
                for (let i = 0; i < initialDetails.length; i++) {
                    const iso = toIsoDate(initialDetails[i].scheduleDate);
                    if (iso && (maxIso == null || iso > maxIso)) { maxIso = iso; }
                }
                if (maxIso && !$("#swal-datepreferredto").val()) { $("#swal-datepreferredto").val(maxIso); }
            }
            $("#swal-datepreferred, #swal-datepreferredto").off("change").on("change", function () {
                buildDailyInputs();
                if (initialDetails && initialDetails.length > 0) { populateHoursFromDetails(initialDetails); }
            });
            $("#swal-confirmeddate").off("change").on("change", updateConfirmedPreview);

            buildDailyInputs();
            if (initialDetails && initialDetails.length > 0) { populateHoursFromDetails(initialDetails); }
        }

        function collectDetails() {
            const rows = [];
            $(".pl-day-hours").each(function () {
                const date = $(this).attr("data-date");
                const hours = parseFloat($(this).val());
                if (date && !isNaN(hours) && hours > 0) {
                    rows.push({ scheduleDate: date, hours: hours });
                }
            });
            return rows;
        }

        function collectForm() {
            return {
                itemid:            $("#swal-itemid").val(),
                category:          $("#swal-category").val(),
                type:              $("#swal-type").val(),
                itemtype:          $("#swal-itemtype").val(),
                wostype:           $("#swal-wostype").val(),
                plan:              $("#swal-plan").val().trim(),
                machinetypeid:     $("#swal-machinetypeid").val(),
                stackingmachineid: $("#swal-stackingmachineid").val(),
                nooflots:          $("#swal-nooflots").val(),
                evaluation:        $("#swal-evaluation").val().trim(),
                datepreferred:     $("#swal-datepreferred").val(),
                confirmeddate:     $("#swal-confirmeddate").val(),
                pic:               $("#swal-pic").val().trim(),
                details:           JSON.stringify(collectDetails())
            };
        }

        function validateForm() {
            if (!$("#swal-itemid").val()) { Swal.showValidationMessage("Please select an item."); return false; }
            if (!$("#swal-category").val()) { Swal.showValidationMessage("Please select a category."); return false; }
            if (!$("#swal-type").val()) { Swal.showValidationMessage("Please select a type."); return false; }
            if (!$("#swal-machinetypeid").val()) { Swal.showValidationMessage("Please select a machine type."); return false; }
            if (!$("#swal-datepreferred").val()) { Swal.showValidationMessage("Please select the Date Preferred From."); return false; }
            if (!$("#swal-datepreferredto").val()) { Swal.showValidationMessage("Please select the Date Preferred To."); return false; }
            if (rangeDays($("#swal-datepreferred").val(), $("#swal-datepreferredto").val()) <= 0) {
                Swal.showValidationMessage("Date Preferred To must be on or after the From date.");
                return false;
            }
            if (collectDetails().length === 0) {
                Swal.showValidationMessage("Enter the hours for at least one day in the range (max 24 per day).");
                return false;
            }
            return true;
        }

        function withReferenceData(onReady) {
            $.when(
                $.ajax({ url: itemUrl, type: "GET", dataType: "json" }),
                $.ajax({ url: machineTypeUrl, type: "GET", dataType: "json" }),
                $.ajax({ url: machineUrl, type: "GET", dataType: "json" })
            ).done(function (itemsRes, typesRes, machinesRes) {
                refItems = itemsRes[0] || [];
                refTypes = typesRes[0] || [];
                refMachines = machinesRes[0] || [];
                onReady();
            }).fail(function () {
                Swal.fire({ icon: "error", title: "Failed", text: "Could not load reference data.", confirmButtonColor: "#0f5a47" });
            });
        }

        /* ---------- Month filter ---------- */
        (function initMonth() {
            const now = new Date();
            $("#monthYearFilter").val(now.getFullYear() + "-" + pad2(now.getMonth() + 1));
        })();

        $("#monthYearFilter").on("change", loadMatrix);

        /* ---------- Export (simple CSV of the current matrix) ---------- */
        $("#exportExcel").on("click", function () {
            if (!currentRows || currentRows.length === 0) {
                Swal.fire({ icon: "info", title: "Nothing to export", text: "No entries for this month.", confirmButtonColor: "#0f5a47" });
                return;
            }
            const my = getSelectedMonthYear();
            const daysInMonth = new Date(my.year, my.month, 0).getDate();
            let csv = "Evaluation,Category,Type,Item,ItemType,Plan,Lots,WOS,MachineType,StackingMachine,PIC";
            for (let d = 1; d <= daysInMonth; d++) { csv += "," + pad2(d); }
            csv += "\n";
            for (let r = 0; r < currentRows.length; r++) {
                const row = currentRows[r];
                const item = row.item || {};
                const mt = row.machineType || {};
                const sm = row.stackingMachine || {};
                const map = hoursByDate(row);
                const cells = [
                    row.evaluation, row.category, row.type, item.itemName, row.itemType,
                    row.plan, row.noOfLots, row.wosType, mt.machineCode, sm.machineName, row.pic
                ];
                let line = cells.map(csvCell).join(",");
                for (let d = 1; d <= daysInMonth; d++) {
                    const iso = my.year + "-" + pad2(my.month) + "-" + pad2(d);
                    line += "," + (map[iso] != null ? map[iso] : "");
                }
                csv += line + "\n";
            }
            const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
            const link = document.createElement("a");
            link.href = URL.createObjectURL(blob);
            link.download = "PlottingSummary_" + my.year + "-" + pad2(my.month) + ".csv";
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        });

        function csvCell(v) {
            if (v == null) { return ""; }
            const s = String(v);
            return (s.indexOf(",") >= 0 || s.indexOf('"') >= 0) ? '"' + s.replace(/"/g, '""') + '"' : s;
        }

        /* ---------- Add ---------- */
        $("#add").on("click", function () {
            withReferenceData(function () {
                if (refItems.length === 0) {
                    Swal.fire({ icon: "info", title: "No items", text: "Add an item first.", confirmButtonColor: "#0f5a47" });
                    return;
                }
                Swal.fire({
                    title: "Add Plotting Summary",
                    html: buildForm({}),
                    width: 860,
                    showCancelButton: true,
                    confirmButtonText: "Save",
                    confirmButtonColor: "#0f5a47",
                    focusConfirm: false,
                    didOpen: function () { wireRangeGrid([]); },
                    preConfirm: function () {
                        if (!validateForm()) { return false; }
                        return collectForm();
                    }
                }).then(function (result) {
                    if (result.isConfirmed) {
                        showLoadingScreen();
                        $.ajax({
                            url: baseUrl + "/n", type: "POST", data: result.value,
                            success: function (response) {
                                Swal.fire({ icon: "success", title: "Saved", text: response, confirmButtonColor: "#0f5a47" });
                                loadMatrix();
                            },
                            error: function (xhr) {
                                Swal.fire({ icon: "error", title: "Failed", text: xhr.responseText, confirmButtonColor: "#0f5a47" });
                            }
                        });
                    }
                });
            });
        });

        /* ---------- Edit ---------- */
        $("#plotting_table tbody").on("click", ".js-edit", function () {
            const id = $(this).data("id");
            showLoadingScreen();
            $.ajax({
                url: baseUrl + "/u", type: "GET", data: { id: id }, dataType: "json",
                success: function (data) {
                    withReferenceData(function () {
                        Swal.fire({
                            title: "Edit Plotting Summary",
                            html: buildForm(data),
                            width: 860,
                            showCancelButton: true,
                            confirmButtonText: "Update",
                            confirmButtonColor: "#0f5a47",
                            focusConfirm: false,
                            didOpen: function () { wireRangeGrid(data.details || []); },
                            preConfirm: function () {
                                if (!validateForm()) { return false; }
                                const form = collectForm();
                                form.id = id;
                                return form;
                            }
                        }).then(function (result) {
                            if (result.isConfirmed) {
                                showLoadingScreen();
                                $.ajax({
                                    url: baseUrl + "/u", type: "POST", data: result.value,
                                    success: function (response) {
                                        Swal.fire({ icon: "success", title: "Updated", text: response, confirmButtonColor: "#0f5a47" });
                                        loadMatrix();
                                    },
                                    error: function (xhr) {
                                        Swal.fire({ icon: "error", title: "Failed", text: xhr.responseText, confirmButtonColor: "#0f5a47" });
                                    }
                                });
                            }
                        });
                    });
                },
                error: function (xhr) {
                    Swal.fire({ icon: "error", title: "Failed", text: xhr.responseText, confirmButtonColor: "#0f5a47" });
                }
            });
        });

        /* ---------- Delete ---------- */
        $("#plotting_table tbody").on("click", ".js-delete", function () {
            const id = $(this).data("id");
            Swal.fire({
                title: "Delete this entry?",
                text: "This permanently deletes the plotting summary and its daily schedule.",
                icon: "warning",
                showCancelButton: true,
                confirmButtonText: "Delete",
                confirmButtonColor: "#a32a1f"
            }).then(function (result) {
                if (result.isConfirmed) {
                    showLoadingScreen();
                    $.ajax({
                        url: baseUrl + "/d", type: "POST", data: { id: id },
                        success: function (response) {
                            Swal.fire({ icon: "success", title: "Deleted", text: response, confirmButtonColor: "#0f5a47" });
                            loadMatrix();
                        },
                        error: function (xhr) {
                            Swal.fire({ icon: "error", title: "Failed", text: xhr.responseText, confirmButtonColor: "#0f5a47" });
                        }
                    });
                }
            });
        });

        /* ---------- Initial load ---------- */
        loadMatrix();

    });
</script>
</body>
</html>
