<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Machine Maintenance</title>
    <%@include file="/Utilities/links.jsp" %>

    <style>
        /* ---- Design tokens (ipmssys canvas design) ---- */
        :root {
            --mc-accent:        #0f5a47;
            --mc-accent-tint:   #e3efe9;
            --mc-page:          #f4f6f3;
            --mc-surface:       #ffffff;
            --mc-surface-sub:   #fafbf9;
            --mc-border:        #dfe5e0;
            --mc-border-soft:   #edf0ed;
            --mc-border-input:  #cfd8d2;
            --mc-text:          #17211d;
            --mc-text-sub:      #55635d;
            --mc-text-muted:    #6a7771;
        }

        body {
            background: var(--mc-page);
            color: var(--mc-text);
            font-family: 'FSEmericLight', Helvetica, 'Segoe UI', sans-serif;
            font-size: 14px;
        }

        .mc-wrap {
            max-width: 1120px;
            margin: 0 auto;
            padding: 32px 24px 56px;
        }

        /* ---- Page heading ---- */
        .mc-head {
            display: flex;
            flex-wrap: wrap;
            align-items: flex-end;
            justify-content: space-between;
            gap: 16px 24px;
            margin-bottom: 20px;
        }
        .mc-title {
            margin: 0;
            font-size: 28px;
            font-weight: 700;
            letter-spacing: -0.02em;
            line-height: 1.15;
        }
        .mc-subtitle {
            margin: 4px 0 0;
            color: var(--mc-text-sub);
            font-size: 14px;
        }

        /* ---- Buttons ---- */
        .mc-btn-primary {
            height: 44px;
            padding: 0 18px;
            border: 0;
            border-radius: 8px;
            background: var(--mc-accent);
            color: #ffffff;
            font: inherit;
            font-weight: 600;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        .mc-btn-primary:hover { background: #0c4a3b; color: #fff; }

        /* ---- Filter bar ---- */
        .mc-toolbar {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 12px;
            margin-bottom: 14px;
        }
        .mc-search {
            flex: 1 1 260px;
            max-width: 360px;
            height: 44px;
            box-sizing: border-box;
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 0 14px;
            background: var(--mc-surface);
            border: 1px solid var(--mc-border-input);
            border-radius: 8px;
            color: var(--mc-text-sub);
        }
        .mc-search input {
            flex: 1;
            min-width: 0;
            border: 0;
            outline: 0;
            background: transparent;
            font: inherit;
            color: var(--mc-text);
        }
        .mc-filter-select {
            height: 44px;
            padding: 0 12px;
            border: 1px solid var(--mc-border-input);
            border-radius: 8px;
            background: var(--mc-surface);
            font: inherit;
            color: var(--mc-text);
        }
        .mc-count { margin-left: auto; color: var(--mc-text-sub); }

        /* ---- Card + table ---- */
        .mc-card {
            background: var(--mc-surface);
            border: 1px solid var(--mc-border);
            border-radius: 12px;
        }
        #machine_table_wrapper .dataTables_scrollBody { overflow-y: auto !important; }
        #machine_table_wrapper .dataTables_scrollHead { background: var(--mc-surface-sub, #fafbf9); border-radius: 12px 12px 0 0; }
        .mc-card .dataTables_scrollBody::-webkit-scrollbar { width: 10px; height: 10px; }
        .mc-card .dataTables_scrollBody::-webkit-scrollbar-thumb { background: #cfd8d2; border-radius: 6px; }
        table.mc-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }
        table.mc-table thead th {
            background: var(--mc-surface-sub);
            color: var(--mc-text-sub);
            font-size: 12px;
            font-weight: 600;
            letter-spacing: 0.06em;
            text-transform: uppercase;
            text-align: left;
            padding: 12px 20px;
            border-bottom: 1px solid var(--mc-border);
            white-space: nowrap;
        }
        table.mc-table tbody td {
            padding: 14px 20px;
            border-bottom: 1px solid var(--mc-border-soft);
            vertical-align: middle;
        }
        table.mc-table tbody tr:last-child td { border-bottom: 0; }
        table.mc-table tbody tr:hover td { background: var(--mc-surface-sub); }

        .mc-code-chip {
            display: inline-block;
            padding: 3px 9px;
            border-radius: 6px;
            background: var(--mc-accent-tint);
            color: var(--mc-accent);
            font-family: 'FSEmericLight', Helvetica, monospace;
            font-size: 13px;
            font-weight: 600;
        }
        .mc-name { font-weight: 600; color: var(--mc-text); }
        .mc-muted { color: var(--mc-text-muted); }

        /* ---- Usage pills ---- */
        .mc-pill {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 10px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 600;
        }
        .mc-pill-dot { width: 7px; height: 7px; border-radius: 50%; }
        .mc-pill-available   { background: var(--mc-accent-tint); color: var(--mc-accent); }
        .mc-pill-available   .mc-pill-dot { background: var(--mc-accent); }
        .mc-pill-unavailable { background: #f1f3f2; color: #6a7771; }
        .mc-pill-unavailable .mc-pill-dot { background: #9aa6a0; }

        /* ---- Row action buttons ---- */
        .mc-act {
            width: 40px;
            height: 40px;
            border-radius: 8px;
            background: var(--mc-surface);
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            margin-left: 4px;
        }
        .mc-act-edit   { border: 1px solid var(--mc-border); color: #3d4a45; }
        .mc-act-edit:hover   { background: var(--mc-accent-tint); color: var(--mc-accent); }
        .mc-act-delete { border: 1px solid #f0d5d2; color: #a32a1f; }
        .mc-act-delete:hover { background: #a32a1f; color: #fff; }

        .mc-empty { padding: 40px 20px; text-align: center; color: var(--mc-text-muted); }

        /* Hide default DataTables chrome — we drive search ourselves */
        #machine_table_wrapper .dataTables_filter,
        #machine_table_wrapper .dataTables_length { display: none; }
        /* single compact footer: entry count on the left, pager on the right */
        #machine_table_wrapper .dataTables_info { float: left; padding: 10px 20px; margin: 0; font-size: 13px; color: var(--it-text-sub, #5c6b64); }
        #machine_table_wrapper .dataTables_paginate { float: right; padding: 6px 16px; margin: 0; }
        #machine_table_wrapper::after { content: ""; display: table; clear: both; }

.swal2-popup .form-floating > .form-control,
        .swal2-popup .form-floating > .form-select { border-radius: 8px; }
        .swal2-popup .form-floating > label { padding-left: 1rem; }
        .mc-asterisk { color: #c0392b; }
    </style>
</head>

<body>
<%@include file="/Utilities/Header.jsp" %>

<div class="mc-wrap">

    <div class="mc-head">
        <div>
            <h1 class="mc-title">Machines</h1>
            <p class="mc-subtitle">Register the physical machines and the process (machine type) each belongs to.</p>
        </div>
        <button type="button" class="mc-btn-primary" id="add">
            <i class="fa-solid fa-plus"></i> Add Machine
        </button>
    </div>

    <div class="mc-toolbar">
        <label class="mc-search">
            <i class="fa-solid fa-magnifying-glass" aria-hidden="true"></i>
            <input type="search" id="mc-search-input" placeholder="Search machine or type" aria-label="Search machines">
        </label>
        <select class="mc-filter-select" id="mc-filter-usage" aria-label="Filter by usage">
            <option value="">All usage</option>
            <option value="AVAILABLE">Available</option>
            <option value="UNAVAILABLE">Unavailable</option>
        </select>
        <span class="mc-count" id="mc-count">0 machines</span>
    </div>

    <div class="mc-card">
        <div class="table-responsive">
            <table id="machine_table" class="mc-table w-100" style="font-size:14px;">
                <thead>
                    <tr>
                        <th style="width:220px;">Machine</th>
                        <th>Machine Type</th>
                        <th style="width:150px;">Usage</th>
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
        const baseUrl = contextPath + "/machine";
        const machineTypeUrl = contextPath + "/machinetype/la";

        /* ---------- Helpers ---------- */
        function showLoadingScreen() {
            Swal.fire({
                title: '<span style="color:#17211d; font-size:22px; font-weight:600;">Please wait...</span>',
                html: '<div class="spinner"></div>',
                allowOutsideClick: false,
                showConfirmButton: false
            });
        }

        function validateField(selector, message, minLength) {
            const field = $(selector);
            const value = String(field.val() == null ? "" : field.val()).trim();
            const requiredLength = minLength || 1;
            if (value.length < requiredLength) {
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

        function usagePill(usage) {
            if (usage === "AVAILABLE") {
                return '<span class="mc-pill mc-pill-available"><span class="mc-pill-dot"></span>Available</span>';
            }
            return '<span class="mc-pill mc-pill-unavailable"><span class="mc-pill-dot"></span>Unavailable</span>';
        }

        function buildUsageOptions(selected) {
            const values = ["AVAILABLE", "UNAVAILABLE"];
            const labels = ["Available", "Unavailable"];
            let html = "";
            for (let i = 0; i < values.length; i++) {
                const isSelected = values[i] === selected ? "selected" : "";
                html += '<option value="' + values[i] + '" ' + isSelected + '>' + labels[i] + '</option>';
            }
            return html;
        }

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

        function buildMachineForm(data, machineTypes) {
            const d = data || {};
            const typeId = d.machineType ? d.machineType.machineTypeId : "";
            return ''
                + '<form id="machineform" style="width:100%; overflow:visible;">'
                +   '<div class="row mb-2 text-start mx-auto">'
                +     '<div class="form-floating">'
                +       '<input type="text" class="form-control" id="swal-machinename" maxlength="60" placeholder="Machine Name" value="' + escapeHtml(d.machineName) + '">'
                +       '<label class="ms-2" for="swal-machinename"><span class="mc-asterisk">*</span> Machine Name</label>'
                +     '</div>'
                +   '</div>'
                +   '<div class="row g-2 mb-1 text-start mx-auto">'
                +     '<div class="col-md-7">'
                +       '<div class="form-floating">'
                +         '<select class="form-select" id="swal-machinetypeid">' + buildMachineTypeOptions(machineTypes, typeId) + '</select>'
                +         '<label class="ms-2" for="swal-machinetypeid"><span class="mc-asterisk">*</span> Machine Type</label>'
                +       '</div>'
                +     '</div>'
                +     '<div class="col-md-5">'
                +       '<div class="form-floating">'
                +         '<select class="form-select" id="swal-machineusage">' + buildUsageOptions(d.machineUsage || "AVAILABLE") + '</select>'
                +         '<label class="ms-2" for="swal-machineusage"><span class="mc-asterisk">*</span> Usage</label>'
                +       '</div>'
                +     '</div>'
                +   '</div>'
                + '</form>';
        }

        function collectForm() {
            return {
                machinename:   $("#swal-machinename").val().trim(),
                machinetypeid: $("#swal-machinetypeid").val(),
                machineusage:  $("#swal-machineusage").val()
            };
        }

        function validateMachineForm() {
            if (!validateField("#swal-machinename", "Machine name is required.", 1)) { return false; }
            if (!validateField("#swal-machinetypeid", "Please select a machine type.", 1)) { return false; }
            return true;
        }

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
        const table = $("#machine_table").DataTable({
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
                { data: "machineName", render: function (d) {
                    return '<span class="mc-name">' + escapeHtml(d) + '</span>';
                }},
                { data: "machineType", render: function (type) {
                    if (!type) { return '<span class="mc-muted">&mdash;</span>'; }
                    return '<span class="mc-code-chip">' + escapeHtml(type.machineCode) + '</span> '
                         + escapeHtml(type.machineName);
                }},
                { data: "machineUsage", render: function (d, dataType) {
                    if (dataType === "display") { return usagePill(d); }
                    return d;
                }},
                { data: "machineId", orderable: false, className: "text-end", render: function (id) {
                    return ''
                        + '<button type="button" class="mc-act mc-act-edit js-edit" title="Edit" data-id="' + id + '"><i class="fa-solid fa-pen"></i></button>'
                        + '<button type="button" class="mc-act mc-act-delete js-delete" title="Delete" data-id="' + id + '"><i class="fa-solid fa-trash"></i></button>';
                }}
            ],
            order: [[0, "asc"]],
            language: {
                emptyTable: '<div class="mc-empty">No machines yet.</div>',
                zeroRecords: '<div class="mc-empty">No machines match your search.</div>'
            },
            drawCallback: function () {
                const count = this.api().rows({ search: "applied" }).count();
                $("#mc-count").text(count + (count === 1 ? " machine" : " machines"));
            }
        });

        /* ---------- Search + usage filter ---------- */
        $("#mc-search-input").on("keyup", function () {
            table.search(this.value).draw();
        });

        $("#mc-filter-usage").on("change", function () {
            const value = this.value;
            const term = value ? "^" + value + "$" : "";
            table.column(2).search(term, true, false).draw();
        });

        /* ---------- Add ---------- */
        $("#add").on("click", function () {
            withMachineTypes(function (machineTypes) {
                if (machineTypes.length === 0) {
                    Swal.fire({ icon: "info", title: "No machine types", text: "Add an active machine type first.", confirmButtonColor: "#0f5a47" });
                    return;
                }
                Swal.fire({
                    title: "Add Machine",
                    html: buildMachineForm({}, machineTypes),
                    width: 560,
                    showCancelButton: true,
                    confirmButtonText: "Save",
                    confirmButtonColor: "#0f5a47",
                    focusConfirm: false,
                    preConfirm: function () {
                        if (!validateMachineForm()) { return false; }
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
        $("#machine_table tbody").on("click", ".js-edit", function () {
            const machineId = $(this).data("id");
            showLoadingScreen();
            $.ajax({
                url: baseUrl + "/u",
                type: "GET",
                data: { id: machineId },
                dataType: "json",
                success: function (data) {
                    withMachineTypes(function (machineTypes) {
                        Swal.fire({
                            title: "Edit Machine",
                            html: buildMachineForm(data, machineTypes),
                            width: 560,
                            showCancelButton: true,
                            confirmButtonText: "Update",
                            confirmButtonColor: "#0f5a47",
                            focusConfirm: false,
                            preConfirm: function () {
                                if (!validateMachineForm()) { return false; }
                                const form = collectForm();
                                form.id = machineId;
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
        $("#machine_table tbody").on("click", ".js-delete", function () {
            const machineId = $(this).data("id");
            Swal.fire({
                title: "Delete this machine?",
                text: "This permanently deletes the machine.",
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
                        data: { id: machineId },
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
