<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Monthly Plan</title>
    <%@include file="/Utilities/links.jsp" %>

    <style>
        /* ---- Design tokens (ipmssys canvas design) ---- */
        :root {
            --mp-accent:        #0f5a47;
            --mp-accent-tint:   #e3efe9;
            --mp-page:          #f4f6f3;
            --mp-surface:       #ffffff;
            --mp-surface-sub:   #fafbf9;
            --mp-border:        #dfe5e0;
            --mp-border-soft:   #edf0ed;
            --mp-border-input:  #cfd8d2;
            --mp-text:          #17211d;
            --mp-text-sub:      #55635d;
            --mp-text-muted:    #6a7771;
        }

        body {
            background: var(--mp-page);
            color: var(--mp-text);
            font-family: 'FSEmericLight', Helvetica, 'Segoe UI', sans-serif;
            font-size: 14px;
        }

        .mp-wrap {
            max-width: 1280px;
            margin: 0 auto;
            padding: 32px 24px 56px;
        }

        /* ---- Page heading ---- */
        .mp-head {
            display: flex;
            flex-wrap: wrap;
            align-items: flex-end;
            justify-content: space-between;
            gap: 16px 24px;
            margin-bottom: 20px;
        }
        .mp-title {
            margin: 0;
            font-size: 28px;
            font-weight: 700;
            letter-spacing: -0.02em;
            line-height: 1.15;
        }
        .mp-subtitle {
            margin: 4px 0 0;
            color: var(--mp-text-sub);
            font-size: 14px;
        }

        /* ---- Buttons ---- */
        .mp-btn-primary {
            height: 44px;
            padding: 0 18px;
            border: 0;
            border-radius: 8px;
            background: var(--mp-accent);
            color: #ffffff;
            font: inherit;
            font-weight: 600;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        .mp-btn-primary:hover { background: #0c4a3b; color: #fff; }

        /* ---- Filter bar ---- */
        .mp-toolbar {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 12px;
            margin-bottom: 14px;
        }
        .mp-search {
            flex: 1 1 260px;
            max-width: 380px;
            height: 44px;
            box-sizing: border-box;
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 0 14px;
            background: var(--mp-surface);
            border: 1px solid var(--mp-border-input);
            border-radius: 8px;
            color: var(--mp-text-sub);
        }
        .mp-search input {
            flex: 1;
            min-width: 0;
            border: 0;
            outline: 0;
            background: transparent;
            font: inherit;
            color: var(--mp-text);
        }
        .mp-filter-select {
            height: 44px;
            padding: 0 12px;
            border: 1px solid var(--mp-border-input);
            border-radius: 8px;
            background: var(--mp-surface);
            font: inherit;
            color: var(--mp-text);
        }
        .mp-count { margin-left: auto; color: var(--mp-text-sub); }

        /* ---- Card + table ---- */
        .mp-card {
            background: var(--mp-surface);
            border: 1px solid var(--mp-border);
            border-radius: 12px;
        }
        #monthly_plan_table_wrapper .dataTables_scrollBody { overflow-y: auto !important; }
        #monthly_plan_table_wrapper .dataTables_scrollHead { background: var(--mp-surface-sub, #fafbf9); border-radius: 12px 12px 0 0; }
        .mp-card .dataTables_scrollBody::-webkit-scrollbar { width: 10px; height: 10px; }
        .mp-card .dataTables_scrollBody::-webkit-scrollbar-thumb { background: #cfd8d2; border-radius: 6px; }
        table.mp-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }
        table.mp-table thead th {
            background: var(--mp-surface-sub);
            color: var(--mp-text-sub);
            font-size: 12px;
            font-weight: 600;
            letter-spacing: 0.06em;
            text-transform: uppercase;
            text-align: left;
            padding: 12px 20px;
            border-bottom: 1px solid var(--mp-border);
            white-space: nowrap;
        }
        table.mp-table tbody td {
            padding: 14px 20px;
            border-bottom: 1px solid var(--mp-border-soft);
            vertical-align: middle;
        }
        table.mp-table tbody tr:last-child td { border-bottom: 0; }
        table.mp-table tbody tr:hover td { background: var(--mp-surface-sub); }
        table.mp-table tbody tr.mp-clickable { cursor: pointer; }
        table.mp-table td.mp-num { text-align: right; font-variant-numeric: tabular-nums; }

        .mp-code-chip {
            display: inline-block;
            padding: 3px 9px;
            border-radius: 6px;
            background: var(--mp-accent-tint);
            color: var(--mp-accent);
            font-family: 'FSEmericLight', Helvetica, monospace;
            font-size: 13px;
            font-weight: 600;
        }
        .mp-muted { color: var(--mp-text-muted); }
        .mp-month { font-weight: 600; }

        /* ---- Status pills ---- */
        .mp-pill {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 10px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 600;
        }
        .mp-pill-dot { width: 7px; height: 7px; border-radius: 50%; }
        .mp-pill-draft  { background: #f1f3f2; color: #6a7771; }
        .mp-pill-draft  .mp-pill-dot { background: #9aa6a0; }
        .mp-pill-active { background: var(--mp-accent-tint); color: var(--mp-accent); }
        .mp-pill-active .mp-pill-dot { background: var(--mp-accent); }
        .mp-pill-closed { background: #fbe9e7; color: #a32a1f; }
        .mp-pill-closed .mp-pill-dot { background: #a32a1f; }

        /* ---- Row action buttons ---- */
        .mp-act {
            width: 40px;
            height: 40px;
            border-radius: 8px;
            background: var(--mp-surface);
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            margin-left: 4px;
        }
        .mp-act-edit   { border: 1px solid var(--mp-border); color: #3d4a45; }
        .mp-act-edit:hover   { background: var(--mp-accent-tint); color: var(--mp-accent); }
        .mp-act-clone  { border: 1px solid var(--mp-border); color: #0f5a47; }
        .mp-act-clone:hover  { background: var(--mp-accent); color: #fff; }
        .mp-act-delete { border: 1px solid #f0d5d2; color: #a32a1f; }
        .mp-act-delete:hover { background: #a32a1f; color: #fff; }

        .mp-empty { padding: 40px 20px; text-align: center; color: var(--mp-text-muted); }

        /* Hide default DataTables chrome — we drive search ourselves */
        #monthly_plan_table_wrapper .dataTables_filter,
        #monthly_plan_table_wrapper .dataTables_length { display: none; }
        /* single compact footer: entry count on the left, pager on the right */
        #monthly_plan_table_wrapper .dataTables_info { float: left; padding: 10px 20px; margin: 0; font-size: 13px; color: var(--it-text-sub, #5c6b64); }
        #monthly_plan_table_wrapper .dataTables_paginate { float: right; padding: 6px 16px; margin: 0; }
        #monthly_plan_table_wrapper::after { content: ""; display: table; clear: both; }

.swal2-popup .form-floating > .form-control,
        .swal2-popup .form-floating > .form-select { border-radius: 8px; }
        .swal2-popup .form-floating > label { padding-left: 1rem; }
        .mp-asterisk { color: #c0392b; }
    </style>
</head>

<body>
<%@include file="/Utilities/Header.jsp" %>

<div class="mp-wrap">

    <div class="mp-head">
        <div>
            <h1 class="mp-title">Monthly Plan</h1>
            <p class="mp-subtitle">Create and manage the monthly production plan per machine type.</p>
        </div>
        <button type="button" class="mp-btn-primary" id="add">
            <i class="fa-solid fa-plus"></i> Add Monthly Plan
        </button>
    </div>

    <div class="mp-toolbar">
        <label class="mp-search">
            <i class="fa-solid fa-magnifying-glass" aria-hidden="true"></i>
            <input type="search" id="mp-search-input" placeholder="Search month, machine type, or description" aria-label="Search monthly plans">
        </label>
        <select class="mp-filter-select" id="mp-filter-status" aria-label="Filter by status">
            <option value="">All statuses</option>
            <option value="DRAFT">Draft</option>
            <option value="ACTIVE">Active</option>
            <option value="CLOSED">Closed</option>
        </select>
        <span class="mp-count" id="mp-count">0 plans</span>
    </div>

    <div class="mp-card">
        <div class="table-responsive">
            <table id="monthly_plan_table" class="mp-table w-100" style="font-size:14px;">
                <thead>
                    <tr>
                        <th style="width:120px;">Month</th>
                        <th style="width:150px;">Machine Type</th>
                        <th>Description</th>
                        <th style="width:110px; text-align:right;">Prod. Time</th>
                        <th style="width:90px; text-align:right;">Eff. %</th>
                        <th style="width:110px; text-align:right;">Machines</th>
                        <th style="width:130px;">Last Day</th>
                        <th style="width:120px;">Status</th>
                        <th style="width:110px; text-align:right;">Actions</th>
                    </tr>
                </thead>
                <tbody></tbody>
            </table>
        </div>
    </div>

</div>

<script>
    $(document).ready(function () {

        const contextPath = "${pageContext.request.contextPath}";
        const baseUrl = contextPath + "/monthlyplan";
        const machineTypeUrl = contextPath + "/machinetype/la";

        const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

        /* ---------- Helpers ---------- */
        function showLoadingScreen() {
            Swal.fire({
                title: '<span style="color:#17211d; font-size:22px; font-weight:600;">Please wait...</span>',
                html: '<div class="spinner"></div>',
                allowOutsideClick: false,
                showConfirmButton: false
            });
        }

        function validateField(selector, message, minLength, pattern) {
            const field = $(selector);
            const value = String(field.val() == null ? "" : field.val()).trim();
            const requiredLength = minLength || 1;
            if (value.length < requiredLength || (pattern && !pattern.test(value))) {
                Swal.showValidationMessage(message);
                field.focus().addClass("is-invalid");
                return false;
            }
            field.removeClass("is-invalid");
            return true;
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

        /* "2026-08-01" (or ISO datetime) -> "Aug 2026" */
        function formatMonth(value) {
            if (!value) { return '<span class="mp-muted">&mdash;</span>'; }
            let year, monthNum;
            if (typeof value === "object") {
                const src = value.date ? value.date : value;
                year = src.year;
                monthNum = (src.monthValue != null) ? src.monthValue : src.month;
            } else {
                const parts = String(value).split("T")[0].split("-");
                if (parts.length < 2) { return escapeHtml(value); }
                year = parts[0];
                monthNum = parseInt(parts[1], 10);
            }
            const monthIndex = monthNum - 1;
            const label = (monthIndex >= 0 && monthIndex < 12) ? MONTHS[monthIndex] : monthNum;
            return '<span class="mp-month">' + label + " " + year + '</span>';
        }

        /* ISO date -> "YYYY-MM-DD" for display / date input */
        function pad2(n) {
            return (n < 10 ? "0" : "") + n;
        }

        function toIsoDate(value) {
            if (!value) { return ""; }
            if (typeof value === "object") {
                const src = value.date ? value.date : value;
                const y = src.year;
                const m = (src.monthValue != null) ? src.monthValue : src.month;
                const d = (src.dayOfMonth != null) ? src.dayOfMonth : src.day;
                if (y && m && d) { return y + "-" + pad2(m) + "-" + pad2(d); }
                return "";
            }
            return String(value).split("T")[0];
        }

        /* ISO date -> "YYYY-MM" for the month input */
        function toIsoMonth(value) {
            const iso = toIsoDate(value);
            if (!iso) { return ""; }
            const parts = iso.split("-");
            return parts.length >= 2 ? parts[0] + "-" + parts[1] : "";
        }

        function statusPill(status) {
            if (status === "ACTIVE") {
                return '<span class="mp-pill mp-pill-active"><span class="mp-pill-dot"></span>Active</span>';
            }
            if (status === "CLOSED") {
                return '<span class="mp-pill mp-pill-closed"><span class="mp-pill-dot"></span>Closed</span>';
            }
            return '<span class="mp-pill mp-pill-draft"><span class="mp-pill-dot"></span>Draft</span>';
        }

        function buildStatusOptions(selected) {
            const values = ["DRAFT", "ACTIVE", "CLOSED"];
            const labels = ["Draft", "Active", "Closed"];
            let html = "";
            for (let i = 0; i < values.length; i++) {
                const isSelected = values[i] === selected ? "selected" : "";
                html += '<option value="' + values[i] + '" ' + isSelected + '>' + labels[i] + '</option>';
            }
            return html;
        }

        /* Machine-type <select> options built from the active list. */
        function buildMachineTypeOptions(list, selectedId) {
            let html = '<option value="">Select machine type</option>';
            for (let i = 0; i < list.length; i++) {
                const item = list[i];
                const isSelected = String(item.machineTypeId) === String(selectedId) ? "selected" : "";
                html += '<option value="' + item.machineTypeId + '" ' + isSelected + '>'
                      + escapeHtml(item.machineCode) + " — " + escapeHtml(item.machineName)
                      + '</option>';
            }
            return html;
        }

        /* The add/edit form markup. */
        function buildPlanForm(data, machineTypes) {
            const d = data || {};
            return ''
                + '<form id="planform" style="width:100%; overflow:visible;">'
                +   '<div class="row g-2 mb-2 text-start mx-auto">'
                +     '<div class="col-md-6">'
                +       '<div class="form-floating">'
                +         '<input type="month" class="form-control" id="swal-planmonth" placeholder="Plan Month" value="' + toIsoMonth(d.planMonth) + '">'
                +         '<label class="ms-2" for="swal-planmonth"><span class="mp-asterisk">*</span> Plan Month</label>'
                +       '</div>'
                +     '</div>'
                +     '<div class="col-md-6">'
                +       '<div class="form-floating">'
                +         '<select class="form-select" id="swal-machinetypeid">' + buildMachineTypeOptions(machineTypes, d.machineTypeId) + '</select>'
                +         '<label class="ms-2" for="swal-machinetypeid"><span class="mp-asterisk">*</span> Machine Type</label>'
                +       '</div>'
                +     '</div>'
                +   '</div>'
                +   '<div class="row mb-2 text-start mx-auto">'
                +     '<div class="form-floating">'
                +       '<input type="text" class="form-control" id="swal-description" maxlength="500" placeholder="Description" value="' + escapeHtml(d.description) + '">'
                +       '<label class="ms-2" for="swal-description">Description</label>'
                +     '</div>'
                +   '</div>'
                +   '<div class="row g-2 mb-2 text-start mx-auto">'
                +     '<div class="col-6 col-md-3">'
                +       '<div class="form-floating">'
                +         '<input type="number" class="form-control" id="swal-productiontime" min="0" placeholder="Production Time" value="' + numberValue(d.productionTime) + '">'
                +         '<label class="ms-2" for="swal-productiontime"><span class="mp-asterisk">*</span> Production Time</label>'
                +       '</div>'
                +     '</div>'
                +     '<div class="col-6 col-md-3">'
                +       '<div class="form-floating">'
                +         '<input type="number" class="form-control" id="swal-efficiency" min="0" max="100" placeholder="Efficiency" value="' + numberValue(d.efficiency) + '">'
                +         '<label class="ms-2" for="swal-efficiency"><span class="mp-asterisk">*</span> Efficiency %</label>'
                +       '</div>'
                +     '</div>'
                +     '<div class="col-6 col-md-3">'
                +       '<div class="form-floating">'
                +         '<input type="number" class="form-control" id="swal-workingdays" min="0" max="31" placeholder="Working Days" value="' + numberValue(d.workingDays) + '">'
                +         '<label class="ms-2" for="swal-workingdays"><span class="mp-asterisk">*</span> Working Days</label>'
                +       '</div>'
                +     '</div>'
                +     '<div class="col-6 col-md-3">'
                +       '<div class="form-floating">'
                +         '<input type="number" class="form-control" id="swal-availablemachine" min="0" placeholder="Available Machine" value="' + numberValue(d.availableMachine) + '">'
                +         '<label class="ms-2" for="swal-availablemachine"><span class="mp-asterisk">*</span> Available Machine</label>'
                +       '</div>'
                +     '</div>'
                +   '</div>'
                +   '<div class="row g-2 mb-1 text-start mx-auto">'
                +     '<div class="col-md-6">'
                +       '<div class="form-floating">'
                +         '<input type="date" class="form-control" id="swal-lastdayproduction" placeholder="Last Day of Production" value="' + toIsoDate(d.lastDayProduction) + '">'
                +         '<label class="ms-2" for="swal-lastdayproduction"><span class="mp-asterisk">*</span> Last Day of Production</label>'
                +       '</div>'
                +     '</div>'
                +     '<div class="col-md-6">'
                +       '<div class="form-floating">'
                +         '<select class="form-select" id="swal-status">' + buildStatusOptions(d.status || "DRAFT") + '</select>'
                +         '<label class="ms-2" for="swal-status"><span class="mp-asterisk">*</span> Status</label>'
                +       '</div>'
                +     '</div>'
                +   '</div>'
                + '</form>';
        }

        function numberValue(value) {
            return (value === null || value === undefined) ? "" : value;
        }

        function collectForm() {
            return {
                planmonth:        $("#swal-planmonth").val(),
                machinetypeid:    $("#swal-machinetypeid").val(),
                description:      $("#swal-description").val().trim(),
                productiontime:   $("#swal-productiontime").val(),
                efficiency:       $("#swal-efficiency").val(),
                workingdays:      $("#swal-workingdays").val(),
                availablemachine: $("#swal-availablemachine").val(),
                lastdayproduction: $("#swal-lastdayproduction").val(),
                status:           $("#swal-status").val()
            };
        }

        function validatePlanForm() {
            if (!validateField("#swal-planmonth", "Plan month is required.", 1)) { return false; }
            if (!validateField("#swal-machinetypeid", "Please select a machine type.", 1)) { return false; }
            if (!validateField("#swal-productiontime", "Production time is required.", 1)) { return false; }
            if (!validateField("#swal-efficiency", "Efficiency is required.", 1)) { return false; }
            if (!validateField("#swal-workingdays", "Working days is required.", 1)) { return false; }
            if (!validateField("#swal-availablemachine", "Available machine is required.", 1)) { return false; }
            if (!validateField("#swal-lastdayproduction", "Last day of production is required.", 1)) { return false; }

            const eff = parseInt($("#swal-efficiency").val(), 10);
            if (isNaN(eff) || eff < 0 || eff > 100) {
                Swal.showValidationMessage("Efficiency must be between 0 and 100.");
                $("#swal-efficiency").focus();
                return false;
            }
            return true;
        }

        /* Load the active machine-type list, then run the callback with it. */
        function withMachineTypes(onReady) {
            $.ajax({
                url: machineTypeUrl,
                type: "GET",
                dataType: "json",
                success: function (list) {
                    onReady(list || []);
                },
                error: function (xhr) {
                    Swal.fire({ icon: "error", title: "Failed", text: "Could not load machine types. " + xhr.responseText, confirmButtonColor: "#0f5a47" });
                }
            });
        }

        /* ---------- DataTable ---------- */
        const table = $("#monthly_plan_table").DataTable({
            scrollY: "calc(100vh - 360px)",
            scrollX: true,
            scrollCollapse: true,
            paging: true,
            pageLength: 25,
            lengthMenu: [[25, 50, 100, -1], [25, 50, 100, "All"]],
            info: true,
            ajax: {
                url: baseUrl + "/l",
                dataSrc: ""
            },
            columns: [
                { data: "planMonth", render: function (d) { return formatMonth(d); } },
                { data: "machineCode", render: function (d) {
                    return '<span class="mp-code-chip">' + escapeHtml(d) + '</span>';
                }},
                { data: "description", render: function (d) {
                    return d ? escapeHtml(d) : '<span class="mp-muted">&mdash;</span>';
                }},
                { data: "productionTime", className: "mp-num" },
                { data: "efficiency", className: "mp-num" },
                { data: "availableMachine", className: "mp-num" },
                { data: "lastDayProduction", render: function (d) {
                    return d ? escapeHtml(toIsoDate(d)) : '<span class="mp-muted">&mdash;</span>';
                }},
                { data: "status", render: function (d, type) {
                    if (type === "display") { return statusPill(d); }
                    return d; // filter/sort on the raw status text
                }},
                { data: "planId", orderable: false, className: "text-end", render: function (id, type, row) {
                    var period = formatMonth(row.planMonth);
                    return ''
                        + '<button type="button" class="mp-act mp-act-edit js-edit" title="Edit" data-id="' + id + '"><i class="fa-solid fa-pen"></i></button>'
                        + '<button type="button" class="mp-act mp-act-clone js-clone" title="Duplicate to a new month" data-id="' + id + '" data-period="' + escapeHtml(period) + '"><i class="fa-solid fa-copy"></i></button>'
                        + '<button type="button" class="mp-act mp-act-delete js-delete" title="Delete" data-id="' + id + '"><i class="fa-solid fa-trash"></i></button>';
                }}
            ],
            order: [[0, "desc"]],
            language: {
                emptyTable: '<div class="mp-empty">No monthly plans yet.</div>',
                zeroRecords: '<div class="mp-empty">No plans match your search.</div>'
            },
            createdRow: function (row, data) {
                $(row).addClass("mp-clickable").attr("data-planid", data.planId);
            },
            drawCallback: function () {
                const count = this.api().rows({ search: "applied" }).count();
                $("#mp-count").text(count + (count === 1 ? " plan" : " plans"));
            }
        });

        /* ---------- Row click -> Monthly Planner ---------- */
        $("#monthly_plan_table tbody").on("click", ".mp-clickable", function (event) {
            if ($(event.target).closest(".mp-act").length > 0) { return; }
            const planId = $(this).attr("data-planid");
            if (planId) {
                window.location.href = contextPath + "/monthlyplanner?planid=" + planId;
            }
        });

                /* ---------- Search + status filter ---------- */
        $("#mp-search-input").on("keyup", function () {
            table.search(this.value).draw();
        });

        $("#mp-filter-status").on("change", function () {
            const value = this.value;
            // Status is column index 7; its filter data is the raw status text
            // (DRAFT/ACTIVE/CLOSED) via the orthogonal render above. Exact match.
            const term = value ? "^" + value + "$" : "";
            table.column(7).search(term, true, false).draw();
        });

        /* ---------- Add ---------- */
        $("#add").on("click", function () {
            withMachineTypes(function (machineTypes) {
                if (machineTypes.length === 0) {
                    Swal.fire({ icon: "info", title: "No machine types", text: "Add an active machine type first.", confirmButtonColor: "#0f5a47" });
                    return;
                }
                Swal.fire({
                    title: "Add Monthly Plan",
                    html: buildPlanForm({}, machineTypes),
                    width: 820,
                    showCancelButton: true,
                    confirmButtonText: "Save",
                    confirmButtonColor: "#0f5a47",
                    focusConfirm: false,
                    preConfirm: function () {
                        if (!validatePlanForm()) { return false; }
                        return collectForm();
                    }
                }).then(function (result) {
                    if (result.isConfirmed) {
                        showLoadingScreen();
                        $.ajax({
                            url: baseUrl + "/n",
                            type: "POST",
                            data: result.value,
                            success: function (response) {
                                Swal.fire({ icon: "success", title: "Saved", text: response, confirmButtonColor: "#0f5a47" });
                                table.ajax.reload(null, false);
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
        $("#monthly_plan_table tbody").on("click", ".js-edit", function () {
            const planId = $(this).data("id");
            showLoadingScreen();
            $.ajax({
                url: baseUrl + "/u",
                type: "GET",
                data: { id: planId },
                dataType: "json",
                success: function (data) {
                    withMachineTypes(function (machineTypes) {
                        Swal.fire({
                            title: "Edit Monthly Plan",
                            html: buildPlanForm(data, machineTypes),
                            width: 820,
                            showCancelButton: true,
                            confirmButtonText: "Update",
                            confirmButtonColor: "#0f5a47",
                            focusConfirm: false,
                            preConfirm: function () {
                                if (!validatePlanForm()) { return false; }
                                const form = collectForm();
                                form.id = planId;
                                return form;
                            }
                        }).then(function (result) {
                            if (result.isConfirmed) {
                                showLoadingScreen();
                                $.ajax({
                                    url: baseUrl + "/u",
                                    type: "POST",
                                    data: result.value,
                                    success: function (response) {
                                        Swal.fire({ icon: "success", title: "Updated", text: response, confirmButtonColor: "#0f5a47" });
                                        table.ajax.reload(null, false);
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
        $("#monthly_plan_table tbody").on("click", ".js-delete", function () {
            const planId = $(this).data("id");
            Swal.fire({
                title: "Delete this plan?",
                text: "This permanently deletes the monthly plan.",
                icon: "warning",
                showCancelButton: true,
                confirmButtonText: "Delete",
                confirmButtonColor: "#a32a1f"
            }).then(function (result) {
                if (result.isConfirmed) {
                    showLoadingScreen();
                    $.ajax({
                        url: baseUrl + "/d",
                        type: "POST",
                        data: { id: planId },
                        success: function (response) {
                            Swal.fire({ icon: "success", title: "Deleted", text: response, confirmButtonColor: "#0f5a47" });
                            table.ajax.reload(null, false);
                        },
                        error: function (xhr) {
                            Swal.fire({ icon: "error", title: "Failed", text: xhr.responseText, confirmButtonColor: "#0f5a47" });
                        }
                    });
                }
            });
        });

        //---- Clone (Duplicate to a new month — inputs only) ----//
        $("#monthly_plan_table tbody").on("click", ".js-clone", function () {
            var planId = $(this).data("id");
            var period = $(this).data("period") || "";

            // Default target = next month from today (month input is YYYY-MM).
            var now = new Date();
            var dflt = now.getFullYear() + "-" + ("0" + (now.getMonth() + 2)).slice(-2);
            if (now.getMonth() === 11) { dflt = (now.getFullYear() + 1) + "-01"; }

            Swal.fire({
                title: "Duplicate monthly plan",
                html: '<div class="text-start" style="font-size:13px;">'
                    + '<p class="mb-2">Copies <b>Precondition Raw</b> and the <b>Saggering</b> pattern from '
                    + '<b>' + escapeHtml(period) + '</b> into a new month. '
                    + 'Machine Allocation and the Loading Plan are recomputed fresh.</p>'
                    + '<div class="form-floating">'
                    + '<input type="month" id="swal-clone-month" class="form-control" value="' + dflt + '">'
                    + '<label>New plan month</label></div></div>',
                showCancelButton: true,
                confirmButtonText: '<i class="fa-solid fa-copy me-1"></i>Duplicate',
                confirmButtonColor: "#0f5a47",
                preConfirm: function () {
                    var m = $("#swal-clone-month").val();
                    if (!m) { Swal.showValidationMessage("Pick a target month."); return false; }
                    return m;
                }
            }).then(function (result) {
                if (!result.isConfirmed) { return; }
                showLoadingScreen();
                $.ajax({
                    url: baseUrl + "/clone",
                    type: "POST",
                    data: { sourcePlanId: planId, targetMonth: result.value },
                    success: function (response) {
                        Swal.fire({ icon: "success", title: "Duplicated",
                            text: response, confirmButtonColor: "#0f5a47" });
                        table.ajax.reload(null, false);
                    },
                    error: function (xhr) {
                        Swal.fire({ icon: "error", title: "Could not duplicate",
                            text: xhr.responseText || "Server error", confirmButtonColor: "#0f5a47" });
                    }
                });
            });
        });

    });
</script>
</body>
</html>
