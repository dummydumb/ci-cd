<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Account Maintenance</title>
    <%@include file="/Utilities/links.jsp" %>

    <style>
        /* ---- Design tokens (ipmssys canvas design) ---- */
        :root {
            --ac-accent:        #0f5a47;
            --ac-accent-tint:   #e3efe9;
            --ac-page:          #f4f6f3;
            --ac-surface:       #ffffff;
            --ac-surface-sub:   #fafbf9;
            --ac-border:        #dfe5e0;
            --ac-border-soft:   #edf0ed;
            --ac-border-input:  #cfd8d2;
            --ac-text:          #17211d;
            --ac-text-sub:      #55635d;
            --ac-text-muted:    #6a7771;
        }

        body {
            background: var(--ac-page);
            color: var(--ac-text);
            font-family: 'FSEmericLight', Helvetica, 'Segoe UI', sans-serif;
            font-size: 14px;
        }

        .ac-wrap {
            max-width: 1180px;
            margin: 0 auto;
            padding: 32px 24px 56px;
        }

        /* ---- Page heading ---- */
        .ac-head {
            display: flex;
            flex-wrap: wrap;
            align-items: flex-end;
            justify-content: space-between;
            gap: 16px 24px;
            margin-bottom: 20px;
        }
        .ac-title {
            margin: 0;
            font-size: 28px;
            font-weight: 700;
            letter-spacing: -0.02em;
            line-height: 1.15;
        }
        .ac-subtitle {
            margin: 4px 0 0;
            color: var(--ac-text-sub);
            font-size: 14px;
        }

        /* ---- Buttons ---- */
        .ac-btn-primary {
            height: 44px;
            padding: 0 18px;
            border: 0;
            border-radius: 8px;
            background: var(--ac-accent);
            color: #ffffff;
            font: inherit;
            font-weight: 600;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        .ac-btn-primary:hover { background: #0c4a3b; color: #fff; }

        /* ---- Filter bar ---- */
        .ac-toolbar {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 12px;
            margin-bottom: 14px;
        }
        .ac-search {
            flex: 1 1 260px;
            max-width: 380px;
            height: 44px;
            box-sizing: border-box;
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 0 14px;
            background: var(--ac-surface);
            border: 1px solid var(--ac-border-input);
            border-radius: 8px;
            color: var(--ac-text-sub);
        }
        .ac-search input {
            flex: 1;
            min-width: 0;
            border: 0;
            outline: 0;
            background: transparent;
            font: inherit;
            color: var(--ac-text);
        }
        .ac-count { margin-left: auto; color: var(--ac-text-sub); }

        /* ---- Card + table ---- */
        .ac-card {
            background: var(--ac-surface);
            border: 1px solid var(--ac-border);
            border-radius: 12px;
        }
        #account_table_wrapper .dataTables_scrollBody { overflow-y: auto !important; }
        #account_table_wrapper .dataTables_scrollHead { background: var(--ac-surface-sub, #fafbf9); border-radius: 12px 12px 0 0; }
        .ac-card .dataTables_scrollBody::-webkit-scrollbar { width: 10px; height: 10px; }
        .ac-card .dataTables_scrollBody::-webkit-scrollbar-thumb { background: #cfd8d2; border-radius: 6px; }
        table.ac-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }
        table.ac-table thead th {
            background: var(--ac-surface-sub);
            color: var(--ac-text-sub);
            font-size: 12px;
            font-weight: 600;
            letter-spacing: 0.06em;
            text-transform: uppercase;
            text-align: left;
            padding: 12px 20px;
            border-bottom: 1px solid var(--ac-border);
            white-space: nowrap;
        }
        table.ac-table tbody td {
            padding: 14px 20px;
            border-bottom: 1px solid var(--ac-border-soft);
            vertical-align: middle;
        }
        table.ac-table tbody tr:last-child td { border-bottom: 0; }
        table.ac-table tbody tr:hover td { background: var(--ac-surface-sub); }

        .ac-code-chip {
            display: inline-block;
            padding: 3px 9px;
            border-radius: 6px;
            background: var(--ac-accent-tint);
            color: var(--ac-accent);
            font-family: 'FSEmericLight', Helvetica, monospace;
            font-size: 13px;
            font-weight: 600;
        }
        .ac-muted { color: var(--ac-text-muted); }

        /* ---- Access-level pill ---- */
        .ac-pill {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 10px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 600;
            background: var(--ac-accent-tint);
            color: var(--ac-accent);
        }

        /* ---- Row action buttons ---- */
        .ac-act {
            width: 40px;
            height: 40px;
            border-radius: 8px;
            background: var(--ac-surface);
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            margin-left: 4px;
        }
        .ac-act-edit   { border: 1px solid var(--ac-border); color: #3d4a45; }
        .ac-act-edit:hover   { background: var(--ac-accent-tint); color: var(--ac-accent); }
        .ac-act-reset  { border: 1px solid var(--ac-border); color: #3d4a45; }
        .ac-act-reset:hover  { background: #fff4e5; color: #b26a00; border-color: #f0dcc0; }
        .ac-act-delete { border: 1px solid #f0d5d2; color: #a32a1f; }
        .ac-act-delete:hover { background: #a32a1f; color: #fff; }

        .ac-empty { padding: 40px 20px; text-align: center; color: var(--ac-text-muted); }

        /* Hide default DataTables chrome — we drive search ourselves */
        #account_table_wrapper .dataTables_filter,
        #account_table_wrapper .dataTables_length { display: none; }
        /* single compact footer: entry count on the left, pager on the right */
        #account_table_wrapper .dataTables_info { float: left; padding: 10px 20px; margin: 0; font-size: 13px; color: var(--it-text-sub, #5c6b64); }
        #account_table_wrapper .dataTables_paginate { float: right; padding: 6px 16px; margin: 0; }
        #account_table_wrapper::after { content: ""; display: table; clear: both; }

.swal2-popup .form-floating > .form-control,
        .swal2-popup .form-floating > .form-select { border-radius: 8px; }
        .swal2-popup .form-floating > label { padding-left: 1rem; }
        .ac-asterisk { color: #c0392b; }
    </style>
</head>

<body>
<%@include file="/Utilities/Header.jsp" %>

<div class="ac-wrap">

    <div class="ac-head">
        <div>
            <h1 class="ac-title">Accounts</h1>
            <p class="ac-subtitle">Manage user accounts, access levels, and password resets.</p>
        </div>
        <button type="button" class="ac-btn-primary" id="add">
            <i class="fa-solid fa-plus"></i> Add Account
        </button>
    </div>

    <div class="ac-toolbar">
        <label class="ac-search">
            <i class="fa-solid fa-magnifying-glass" aria-hidden="true"></i>
            <input type="search" id="ac-search-input" placeholder="Search employee ID, name, or email" aria-label="Search accounts">
        </label>
        <span class="ac-count" id="ac-count">0 accounts</span>
    </div>

    <div class="ac-card">
        <div class="table-responsive">
            <table id="account_table" class="ac-table w-100" style="font-size:14px;">
                <thead>
                    <tr>
                        <th style="width:140px;">Employee ID</th>
                        <th>Name</th>
                        <th>Email</th>
                        <th style="width:120px;">Access</th>
                        <th style="width:160px;">PW Expires</th>
                        <th style="width:170px; text-align:right;">Actions</th>
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
        const baseUrl = contextPath + "/account";

        /* ---------- Helpers ---------- */
        function showLoadingScreen() {
            Swal.fire({
                title: '<span style="color:#17211d; font-size:22px; font-weight:600;">Please wait...</span>',
                html: '<div class="spinner-border" style="color:#0f5a47;" role="status"></div>',
                allowOutsideClick: false,
                showConfirmButton: false
            });
        }

        function validateField(selector, message, minLength, pattern) {
            const field = $(selector);
            const value = field.val().trim();
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

        function accessPill(level) {
            return '<span class="ac-pill">Level ' + escapeHtml(level) + '</span>';
        }

        function pad2(n) {
            return (n < 10 ? "0" : "") + n;
        }

        // Pull {year, month(Value), day(OfMonth)} from however Gson shaped the date.
        function extractYmd(value) {
            if (!value || typeof value !== "object") { return null; }
            // Some gson versions nest the date under a "date" object.
            const src = value.date ? value.date : value;
            const y = src.year;
            const m = (src.monthValue != null) ? src.monthValue : src.month;
            const d = (src.dayOfMonth != null) ? src.dayOfMonth : src.day;
            if (y && m && d) { return y + "-" + pad2(m) + "-" + pad2(d); }
            return null;
        }

        function formatExpiration(value) {
            if (!value) { return '<span class="ac-muted">&mdash;</span>'; }
            if (typeof value === "object") {
                const ymd = extractYmd(value);
                return ymd ? escapeHtml(ymd) : '<span class="ac-muted">&mdash;</span>';
            }
            // ISO string, e.g. 2026-01-20T00:00:00
            const datePart = String(value).split("T")[0];
            return escapeHtml(datePart);
        }

        /* The access-level <select> for the modal, with the given value preselected. */
        function buildAccessOptions(selected) {
            const levels = [1, 2, 3, 99];
            let html = "";
            for (let i = 0; i < levels.length; i++) {
                const value = levels[i];
                const label = value === 99 ? "99 — Administrator" : "Level " + value;
                const isSelected = String(value) === String(selected) ? "selected" : "";
                html += '<option value="' + value + '" ' + isSelected + '>' + label + '</option>';
            }
            return html;
        }

        /* The add/edit form markup. employeeReadOnly=true for edit (id is fixed). */
        function buildAccountForm(data) {
            const d = data || {};
            const empDisabled = d.employeeReadOnly ? "disabled" : "";
            const empValue = escapeHtml(d.employeeid);
            return ''
                + '<form id="accountform" style="width:100%; overflow:visible;">'
                +   '<div class="row mb-2 text-start mx-auto">'
                +     '<div class="form-floating">'
                +       '<input type="text" class="form-control" id="swal-employeeid" maxlength="8" placeholder="Employee ID" value="' + empValue + '" ' + empDisabled + ' style="text-transform:uppercase;">'
                +       '<label class="ms-2" for="swal-employeeid"><span class="ac-asterisk">*</span> Employee ID</label>'
                +     '</div>'
                +   '</div>'
                +   '<div class="row g-2 mb-2 text-start mx-auto">'
                +     '<div class="col-md-6">'
                +       '<div class="form-floating">'
                +         '<input type="text" class="form-control" id="swal-firstname" maxlength="60" placeholder="First Name" value="' + escapeHtml(d.firstname) + '">'
                +         '<label class="ms-2" for="swal-firstname"><span class="ac-asterisk">*</span> First Name</label>'
                +       '</div>'
                +     '</div>'
                +     '<div class="col-md-6">'
                +       '<div class="form-floating">'
                +         '<input type="text" class="form-control" id="swal-lastname" maxlength="60" placeholder="Last Name" value="' + escapeHtml(d.lastname) + '">'
                +         '<label class="ms-2" for="swal-lastname"><span class="ac-asterisk">*</span> Last Name</label>'
                +       '</div>'
                +     '</div>'
                +   '</div>'
                +   '<div class="row g-2 mb-1 text-start mx-auto">'
                +     '<div class="col-md-6">'
                +       '<div class="form-floating">'
                +         '<select class="form-select" id="swal-accesslevel">' + buildAccessOptions(d.accesslevel) + '</select>'
                +         '<label class="ms-2" for="swal-accesslevel"><span class="ac-asterisk">*</span> Access Level</label>'
                +       '</div>'
                +     '</div>'
                +     '<div class="col-md-6">'
                +       '<div class="form-floating">'
                +         '<input type="email" class="form-control" id="swal-email" maxlength="120" placeholder="Email" value="' + escapeHtml(d.email) + '">'
                +         '<label class="ms-2" for="swal-email">Email</label>'
                +       '</div>'
                +     '</div>'
                +   '</div>'
                + '</form>';
        }

        function collectForm() {
            return {
                employeeid:  $("#swal-employeeid").val().trim(),
                firstname:   $("#swal-firstname").val().trim(),
                lastname:    $("#swal-lastname").val().trim(),
                accesslevel: $("#swal-accesslevel").val(),
                email:       $("#swal-email").val().trim()
            };
        }

        function validateAccountForm(requireEmployee) {
            if (requireEmployee && !validateField("#swal-employeeid", "Employee ID is required.", 1)) { return false; }
            if (!validateField("#swal-firstname", "First name is required.", 1)) { return false; }
            if (!validateField("#swal-lastname", "Last name is required.", 1)) { return false; }
            return true;
        }

        /* ---------- DataTable ---------- */
        const table = $("#account_table").DataTable({
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
                { data: "employeeid", render: function (d) {
                    return '<span class="ac-code-chip">' + escapeHtml(d) + '</span>';
                }},
                { data: null, render: function (row) {
                    return escapeHtml(row.firstname) + " " + escapeHtml(row.lastname);
                }},
                { data: "email", render: function (d) {
                    return d ? escapeHtml(d) : '<span class="ac-muted">&mdash;</span>';
                }},
                { data: "accesslevel", render: function (d) {
                    return accessPill(d);
                }},
                { data: "pwexpiration", render: function (d) {
                    return formatExpiration(d);
                }},
                { data: "accountid", orderable: false, className: "text-end", render: function (id, type, row) {
                    return ''
                        + '<button type="button" class="ac-act ac-act-edit js-edit" title="Edit" data-id="' + id + '"><i class="fa-solid fa-pen"></i></button>'
                        + '<button type="button" class="ac-act ac-act-reset js-reset" title="Reset password" data-id="' + id + '" data-emp="' + escapeHtml(row.employeeid) + '"><i class="fa-solid fa-key"></i></button>'
                        + '<button type="button" class="ac-act ac-act-delete js-delete" title="Delete" data-id="' + id + '" data-emp="' + escapeHtml(row.employeeid) + '"><i class="fa-solid fa-trash"></i></button>';
                }}
            ],
            order: [[0, "asc"]],
            language: {
                emptyTable: '<div class="ac-empty">No accounts yet.</div>',
                zeroRecords: '<div class="ac-empty">No accounts match your search.</div>'
            },
            drawCallback: function () {
                const count = this.api().rows({ search: "applied" }).count();
                $("#ac-count").text(count + (count === 1 ? " account" : " accounts"));
            }
        });

        /* ---------- Search ---------- */
        $("#ac-search-input").on("keyup", function () {
            table.search(this.value).draw();
        });

        /* ---------- Add ---------- */
        $("#add").on("click", function () {
            Swal.fire({
                title: "Add Account",
                html: buildAccountForm({}),
                width: 620,
                showCancelButton: true,
                confirmButtonText: "Save",
                confirmButtonColor: "#0f5a47",
                focusConfirm: false,
                preConfirm: function () {
                    if (!validateAccountForm(true)) { return false; }
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

        /* ---------- Edit ---------- */
        $("#account_table tbody").on("click", ".js-edit", function () {
            const accountId = $(this).data("id");
            showLoadingScreen();
            $.ajax({
                url: baseUrl + "/u",
                type: "GET",
                data: { id: accountId },
                dataType: "json",
                success: function (data) {
                    data.employeeReadOnly = true;
                    Swal.fire({
                        title: "Edit Account",
                        html: buildAccountForm(data),
                        width: 620,
                        showCancelButton: true,
                        confirmButtonText: "Update",
                        confirmButtonColor: "#0f5a47",
                        focusConfirm: false,
                        preConfirm: function () {
                            if (!validateAccountForm(false)) { return false; }
                            const form = collectForm();
                            form.id = accountId;
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
                },
                error: function (xhr) {
                    Swal.fire({ icon: "error", title: "Failed", text: xhr.responseText, confirmButtonColor: "#0f5a47" });
                }
            });
        });

        /* ---------- Reset password ---------- */
        $("#account_table tbody").on("click", ".js-reset", function () {
            const accountId = $(this).data("id");
            const employeeId = $(this).data("emp");
            Swal.fire({
                title: "Reset password?",
                html: "This resets <strong>" + escapeHtml(employeeId) + "</strong> to the default password "
                    + "(capitalized first letter of the employee number with a dot, e.g. Pmm12345.).",
                icon: "warning",
                showCancelButton: true,
                confirmButtonText: "Reset",
                confirmButtonColor: "#0f5a47"
            }).then(function (result) {
                if (result.isConfirmed) {
                    showLoadingScreen();
                    $.ajax({
                        url: contextPath + "/accounts/rp",
                        type: "POST",
                        data: { id: accountId },
                        success: function (response) {
                            Swal.fire({ icon: "success", title: "Done", text: response, confirmButtonColor: "#0f5a47" });
                        },
                        error: function (xhr) {
                            Swal.fire({ icon: "error", title: "Failed", text: xhr.responseText, confirmButtonColor: "#0f5a47" });
                        }
                    });
                }
            });
        });

        /* ---------- Delete ---------- */
        $("#account_table tbody").on("click", ".js-delete", function () {
            const accountId = $(this).data("id");
            const employeeId = $(this).data("emp");
            Swal.fire({
                title: "Delete account?",
                html: "This permanently deletes <strong>" + escapeHtml(employeeId) + "</strong>.",
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
                        data: { id: accountId },
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

    });
</script>
</body>
</html>
