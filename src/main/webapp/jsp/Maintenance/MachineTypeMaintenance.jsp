<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Machine Type Maintenance</title>
    <%@include file="/Utilities/links.jsp" %>

    <style>
        /* ---- Design tokens (from the ipmssys canvas design) ---- */
        :root {
            --mt-accent:        #0f5a47;
            --mt-accent-tint:   #e3efe9;
            --mt-page:          #f4f6f3;
            --mt-surface:       #ffffff;
            --mt-surface-sub:   #fafbf9;
            --mt-border:        #dfe5e0;
            --mt-border-soft:   #edf0ed;
            --mt-border-input:  #cfd8d2;
            --mt-text:          #17211d;
            --mt-text-sub:      #55635d;
            --mt-text-muted:    #6a7771;
        }

        body {
            background: var(--mt-page);
            color: var(--mt-text);
            font-family: 'FSEmericLight', Helvetica, 'Segoe UI', sans-serif;
            font-size: 14px;
        }

        .mt-wrap {
            max-width: 1100px;
            margin: 0 auto;
            padding: 32px 24px 56px;
        }

        /* ---- Page heading ---- */
        .mt-head {
            display: flex;
            flex-wrap: wrap;
            align-items: flex-end;
            justify-content: space-between;
            gap: 16px 24px;
            margin-bottom: 20px;
        }
        .mt-title {
            margin: 0;
            font-size: 28px;
            font-weight: 700;
            letter-spacing: -0.02em;
            line-height: 1.15;
        }
        .mt-subtitle {
            margin: 4px 0 0;
            color: var(--mt-text-sub);
            font-size: 14px;
        }

        /* ---- Buttons ---- */
        .mt-btn-primary {
            height: 44px;
            padding: 0 18px;
            border: 0;
            border-radius: 8px;
            background: var(--mt-accent);
            color: #ffffff;
            font: inherit;
            font-weight: 600;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        .mt-btn-primary:hover { background: #0c4a3b; color: #fff; }

        /* ---- Filter bar ---- */
        .mt-toolbar {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 12px;
            margin-bottom: 14px;
        }
        .mt-search {
            flex: 1 1 260px;
            max-width: 360px;
            height: 44px;
            box-sizing: border-box;
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 0 14px;
            background: var(--mt-surface);
            border: 1px solid var(--mt-border-input);
            border-radius: 8px;
            color: var(--mt-text-sub);
        }
        .mt-search input {
            flex: 1;
            min-width: 0;
            border: 0;
            outline: 0;
            background: transparent;
            font: inherit;
            color: var(--mt-text);
        }
        .mt-filter-select {
            height: 44px;
            padding: 0 12px;
            border: 1px solid var(--mt-border-input);
            border-radius: 8px;
            background: var(--mt-surface);
            font: inherit;
            color: var(--mt-text);
        }
        .mt-count { margin-left: auto; color: var(--mt-text-sub); }

        /* ---- Card + table ---- */
        .mt-card {
            background: var(--mt-surface);
            border: 1px solid var(--mt-border);
            border-radius: 12px;
        }
        #machine_type_table_wrapper .dataTables_scrollBody { overflow-y: auto !important; }
        #machine_type_table_wrapper .dataTables_scrollHead { background: var(--mt-surface-sub, #fafbf9); border-radius: 12px 12px 0 0; }
        .mt-card .dataTables_scrollBody::-webkit-scrollbar { width: 10px; height: 10px; }
        .mt-card .dataTables_scrollBody::-webkit-scrollbar-thumb { background: #cfd8d2; border-radius: 6px; }
        table.mt-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }
        table.mt-table thead th {
            background: var(--mt-surface-sub);
            color: var(--mt-text-sub);
            font-size: 12px;
            font-weight: 600;
            letter-spacing: 0.06em;
            text-transform: uppercase;
            text-align: left;
            padding: 12px 20px;
            border-bottom: 1px solid var(--mt-border);
            white-space: nowrap;
        }
        table.mt-table tbody td {
            padding: 14px 20px;
            border-bottom: 1px solid var(--mt-border-soft);
            vertical-align: middle;
        }
        table.mt-table tbody tr:last-child td { border-bottom: 0; }
        table.mt-table tbody tr:hover td { background: var(--mt-surface-sub); }

        .mt-code {
            font-family: 'FSEmericLight', Helvetica, monospace;
            font-weight: 600;
            color: var(--mt-text);
        }
        .mt-code-chip {
            display: inline-block;
            padding: 3px 9px;
            border-radius: 6px;
            background: var(--mt-accent-tint);
            color: var(--mt-accent);
            font-family: 'FSEmericLight', Helvetica, monospace;
            font-size: 13px;
            font-weight: 600;
        }

        /* ---- Status pills ---- */
        .mt-pill {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 10px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 600;
        }
        .mt-pill-dot { width: 7px; height: 7px; border-radius: 50%; }
        .mt-pill-active   { background: var(--mt-accent-tint); color: var(--mt-accent); }
        .mt-pill-active   .mt-pill-dot { background: var(--mt-accent); }
        .mt-pill-inactive { background: #f1f3f2; color: #6a7771; }
        .mt-pill-inactive .mt-pill-dot { background: #9aa6a0; }

        /* ---- Row action buttons ---- */
        .mt-act {
            width: 40px;
            height: 40px;
            border-radius: 8px;
            background: var(--mt-surface);
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            justify-content: center;
        }
        .mt-act-edit   { border: 1px solid var(--mt-border); color: #3d4a45; }
        .mt-act-edit:hover   { background: var(--mt-accent-tint); color: var(--mt-accent); }
        .mt-act-delete { border: 1px solid #f0d5d2; color: #a32a1f; }
        .mt-act-delete:hover { background: #a32a1f; color: #fff; }

        .mt-empty { padding: 40px 20px; text-align: center; color: var(--mt-text-muted); }

        /* Hide the default DataTables chrome — we drive search/length ourselves */
        #machine_type_table_wrapper .dataTables_filter,
        #machine_type_table_wrapper .dataTables_length { display: none; }
        /* single compact footer: entry count on the left, pager on the right */
        #machine_type_table_wrapper .dataTables_info { float: left; padding: 10px 20px; margin: 0; font-size: 13px; color: var(--it-text-sub, #5c6b64); }
        #machine_type_table_wrapper .dataTables_paginate { float: right; padding: 6px 16px; margin: 0; }
        #machine_type_table_wrapper::after { content: ""; display: table; clear: both; }

        /* SweetAlert2 form fields in the design language */
        .swal2-popup .form-floating > .form-control { border-radius: 8px; }
        .mt-asterisk { color: #c0392b; }
    </style>
</head>

<body>
<%@include file="/Utilities/Header.jsp" %>

<div class="mt-wrap">

    <div class="mt-head">
        <div>
            <h1 class="mt-title">Machine Types</h1>
            <p class="mt-subtitle">Manage the machine types (processes) used across monthly plans.</p>
        </div>
        <button type="button" class="mt-btn-primary" id="add">
            <i class="fa-solid fa-plus"></i> Add Machine Type
        </button>
    </div>

    <div class="mt-toolbar">
        <label class="mt-search">
            <i class="fa-solid fa-magnifying-glass" aria-hidden="true"></i>
            <input type="search" id="mt-search-input" placeholder="Search code or name" aria-label="Search machine types">
        </label>
        <select class="mt-filter-select" id="mt-filter-status" aria-label="Filter by status">
            <option value="">All statuses</option>
            <option value="ACTIVE">Active</option>
            <option value="INACTIVE">Inactive</option>
        </select>
        <span class="mt-count" id="mt-count">0 types</span>
    </div>

    <div class="mt-card">
        <div class="table-responsive">
            <table id="machine_type_table" class="mt-table w-100" style="font-size:14px;">
                <thead>
                    <tr>
                        <th style="width:140px;">Code</th>
                        <th>Name</th>
                        <th style="width:130px;">Status</th>
                        <th style="width:110px; text-align:right;">Actions</th>
                    </tr>
                </thead>
                <tbody></tbody>
            </table>
        </div>
    </div>

</div>

<script>
    const contextPath = "${pageContext.request.contextPath}";
    const baseUrl = contextPath + "/machinetype";

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

    function bindEnterToConfirm() {
        $(document).off("keypress.swalenter").on("keypress.swalenter", function(e) {
            if (e.key === "Enter") {
                e.preventDefault();
                Swal.clickConfirm();
            }
        });
    }
    function unbindEnterToConfirm() {
        $(document).off("keypress.swalenter");
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

    function statusPill(status) {
        if (status === "ACTIVE") {
            return '<span class="mt-pill mt-pill-active"><span class="mt-pill-dot"></span>Active</span>';
        }
        return '<span class="mt-pill mt-pill-inactive"><span class="mt-pill-dot"></span>Inactive</span>';
    }

    /* The status <select> for the modal, with the given value preselected. */
    function buildStatusOptions(selected) {
        const active   = selected === "INACTIVE" ? "" : "selected";
        const inactive = selected === "INACTIVE" ? "selected" : "";
        return '<option value="ACTIVE" '   + active   + '>Active</option>' +
               '<option value="INACTIVE" ' + inactive + '>Inactive</option>';
    }

    $(document).ready(function() {
        let machine_type_table;

        /* ---------- DataTable ---------- */
        machine_type_table = $("#machine_type_table").DataTable({
            scrollY: "calc(100vh - 360px)",
            scrollX: true,
            scrollCollapse: true,
            paging: true,
            pageLength: 25,
            lengthMenu: [[25, 50, 100, -1], [25, 50, 100, "All"]],
            info: true,
            ordering: false,
            fixedHeader: false,
            deferRender: true,
            responsive: true,
            serverSide: false,
            processing: false,
            ajax: {
                url: baseUrl + "/l",
                dataSrc: function(json) {
                    $("#mt-count").text(json.length + (json.length === 1 ? " type" : " types"));
                    return json;
                },
                error: function(response) {
                    console.log(response.responseText);
                }
            },
            columnDefs: [{ targets: "_all", defaultContent: "" }],
            columns: [
                {
                    title: "Code",
                    data: "machineCode",
                    render: function(code) {
                        return '<span class="mt-code-chip">' + escapeHtml(code) + '</span>';
                    }
                },
                {
                    title: "Name",
                    data: "machineName",
                    render: function(name) {
                        return escapeHtml(name);
                    }
                },
                {
                    title: "Status",
                    data: "status",
                    render: function(status) {
                        return statusPill(status);
                    }
                },
                {
                    title: "Actions",
                    data: "machineTypeId",
                    className: "text-end",
                    render: function(id) {
                        return '<button class="mt-act mt-act-edit btn-edit me-1" title="Edit" value="' + id + '">' +
                                   '<i class="fa-regular fa-pen-to-square"></i></button>' +
                               '<button class="mt-act mt-act-delete btn-delete" title="Delete" value="' + id + '">' +
                                   '<i class="fa-regular fa-trash-can"></i></button>';
                    }
                }
            ]
        });

        /* ---------- Filters (client-side over the loaded list) ---------- */
        $("#mt-search-input").on("keyup search", function() {
            machine_type_table.search($(this).val()).draw();
        });

        $("#mt-filter-status").on("change", function() {
            const value = $(this).val();
            // Column 2 is Status. Exact-ish match on the raw value via a custom search.
            machine_type_table.column(2).search(value, false, false).draw();
        });

        /* ---------- Add ---------- */
        $("#add").on("click", function() {
            Swal.fire({
                title: '<h2 style="color:#17211d; font-size:20px;">Add Machine Type</h2>',
                position: "center",
                focusConfirm: false,
                showCancelButton: true,
                allowOutsideClick: false,
                cancelButtonText: "Cancel",
                confirmButtonText: "Save",
                confirmButtonColor: "#0f5a47",
                html:
                    '<form id="maintenanceform" style="width:100%; overflow:visible;">' +
                        '<div class="row mt-1 mb-2 text-start mx-auto">' +
                            '<div class="form-floating">' +
                                '<input type="text" class="form-control" id="swal-machinecode" name="machinecode" placeholder="Code" maxlength="20">' +
                                '<label class="ms-2" for="swal-machinecode"><span class="mt-asterisk">*</span> Code</label>' +
                            '</div>' +
                        '</div>' +
                        '<div class="row mb-2 text-start mx-auto">' +
                            '<div class="form-floating">' +
                                '<input type="text" class="form-control" id="swal-machinename" name="machinename" placeholder="Name" maxlength="100">' +
                                '<label class="ms-2" for="swal-machinename"><span class="mt-asterisk">*</span> Name</label>' +
                            '</div>' +
                        '</div>' +
                        '<div class="row mb-1 text-start mx-auto">' +
                            '<div class="form-floating">' +
                                '<select class="form-select" id="swal-status" name="status">' +
                                    buildStatusOptions("ACTIVE") +
                                '</select>' +
                                '<label class="ms-2" for="swal-status">Status</label>' +
                            '</div>' +
                        '</div>' +
                    '</form>',
                didOpen: function() {
                    bindEnterToConfirm();
                },
                willClose: function() {
                    unbindEnterToConfirm();
                },
                preConfirm: function() {
                    if (!validateField("#swal-machinecode", "Please input a code.")) return false;
                    if (!validateField("#swal-machinename", "Please input a name.")) return false;
                    return $("#maintenanceform").serialize();
                }
            }).then(function(result) {
                if (result.isConfirmed) {
                    showLoadingScreen();
                    $.ajax({
                        type: "POST",
                        url: baseUrl + "/n",
                        data: result.value,
                        cache: false,
                        success: function(response) {
                            Swal.fire({ text: response, icon: "success", confirmButtonText: "OK", confirmButtonColor: "#0f5a47" });
                            machine_type_table.ajax.reload();
                        },
                        error: function(response) {
                            Swal.fire({ text: response.responseText, icon: "error", confirmButtonText: "OK", confirmButtonColor: "#0f5a47" });
                        }
                    });
                }
            });
        });

        /* ---------- Edit ---------- */
        $("#machine_type_table").on("click", ".btn-edit", function() {
            const id = $(this).val();
            Swal.fire({
                title: '<h2 style="color:#17211d; font-size:20px;">Edit Machine Type</h2>',
                position: "center",
                focusConfirm: false,
                showCancelButton: true,
                allowOutsideClick: false,
                cancelButtonText: "Cancel",
                confirmButtonText: "Save",
                confirmButtonColor: "#0f5a47",
                html:
                    '<form id="maintenanceform" style="width:100%; overflow:visible;">' +
                        '<input type="hidden" name="id" id="swal-id">' +
                        '<div class="row mt-1 mb-2 text-start mx-auto">' +
                            '<div class="form-floating">' +
                                '<input type="text" class="form-control" id="swal-machinecode" name="machinecode" placeholder="Code" maxlength="20">' +
                                '<label class="ms-2" for="swal-machinecode"><span class="mt-asterisk">*</span> Code</label>' +
                            '</div>' +
                        '</div>' +
                        '<div class="row mb-2 text-start mx-auto">' +
                            '<div class="form-floating">' +
                                '<input type="text" class="form-control" id="swal-machinename" name="machinename" placeholder="Name" maxlength="100">' +
                                '<label class="ms-2" for="swal-machinename"><span class="mt-asterisk">*</span> Name</label>' +
                            '</div>' +
                        '</div>' +
                        '<div class="row mb-1 text-start mx-auto">' +
                            '<div class="form-floating">' +
                                '<select class="form-select" id="swal-status" name="status">' +
                                    '<option value="ACTIVE">Active</option>' +
                                    '<option value="INACTIVE">Inactive</option>' +
                                '</select>' +
                                '<label class="ms-2" for="swal-status">Status</label>' +
                            '</div>' +
                        '</div>' +
                    '</form>',
                didOpen: function() {
                    bindEnterToConfirm();
                    Swal.showLoading();
                    $.ajax({
                        type: "GET",
                        url: baseUrl + "/u",
                        data: { "id": id },
                        dataType: "json",
                        cache: false,
                        success: function(machineType) {
                            Swal.hideLoading();
                            $("#swal-id").val(machineType.machineTypeId);
                            $("#swal-machinecode").val(machineType.machineCode);
                            $("#swal-machinename").val(machineType.machineName);
                            $("#swal-status").val(machineType.status);
                        },
                        error: function(response) {
                            Swal.hideLoading();
                            Swal.showValidationMessage(response.responseText || "Failed to load data.");
                        }
                    });
                },
                willClose: function() {
                    unbindEnterToConfirm();
                },
                preConfirm: function() {
                    if (!validateField("#swal-machinecode", "Please input a code.")) return false;
                    if (!validateField("#swal-machinename", "Please input a name.")) return false;
                    return $("#maintenanceform").serialize();
                }
            }).then(function(result) {
                if (result.isConfirmed) {
                    showLoadingScreen();
                    $.ajax({
                        type: "POST",
                        url: baseUrl + "/u",
                        data: result.value,
                        cache: false,
                        success: function(response) {
                            Swal.fire({ text: response, icon: "success", confirmButtonText: "OK", confirmButtonColor: "#0f5a47" });
                            machine_type_table.ajax.reload();
                        },
                        error: function(response) {
                            Swal.fire({ text: response.responseText, icon: "error", confirmButtonText: "OK", confirmButtonColor: "#0f5a47" });
                        }
                    });
                }
            });
        });

        /* ---------- Delete ---------- */
        $("#machine_type_table").on("click", ".btn-delete", function() {
            const id = $(this).val();
            Swal.fire({
                title: '<h2 style="color:#17211d; font-size:20px;">Delete this machine type?</h2>',
                text: "This cannot be undone. If it is used by any plan, set it to Inactive instead.",
                icon: "warning",
                position: "center",
                focusConfirm: true,
                showCancelButton: true,
                allowOutsideClick: false,
                cancelButtonText: "No",
                confirmButtonText: "Yes, delete",
                confirmButtonColor: "#a32a1f",
                didOpen: function() {
                    bindEnterToConfirm();
                },
                willClose: function() {
                    unbindEnterToConfirm();
                }
            }).then(function(result) {
                if (result.isConfirmed) {
                    showLoadingScreen();
                    $.ajax({
                        type: "POST",
                        url: baseUrl + "/d",
                        data: { "id": id },
                        cache: false,
                        success: function(response) {
                            Swal.fire({ text: response, icon: "success", showConfirmButton: false, timer: 2000 });
                            machine_type_table.ajax.reload();
                        },
                        error: function(response) {
                            Swal.fire({ text: response.responseText, icon: "error", confirmButtonText: "OK", confirmButtonColor: "#0f5a47" });
                        }
                    });
                }
            });
        });
    });
</script>

</body>
</html>
