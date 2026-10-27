<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Item Maintenance</title>
    <%@include file="/Utilities/links.jsp" %>

    <style>
        /* ---- Design tokens (ipmssys canvas design) ---- */
        :root {
            --it-accent:        #0f5a47;
            --it-accent-tint:   #e3efe9;
            --it-page:          #f4f6f3;
            --it-surface:       #ffffff;
            --it-surface-sub:   #fafbf9;
            --it-border:        #dfe5e0;
            --it-border-soft:   #edf0ed;
            --it-border-input:  #cfd8d2;
            --it-text:          #17211d;
            --it-text-sub:      #55635d;
            --it-text-muted:    #6a7771;
        }

        body {
            background: var(--it-page);
            color: var(--it-text);
            font-family: 'FSEmericLight', Helvetica, 'Segoe UI', sans-serif;
            font-size: 14px;
        }

        .it-wrap {
            max-width: 1180px;
            margin: 0 auto;
            padding: 32px 24px 56px;
        }

        /* ---- Page heading ---- */
        .it-head {
            display: flex;
            flex-wrap: wrap;
            align-items: flex-end;
            justify-content: space-between;
            gap: 16px 24px;
            margin-bottom: 20px;
        }
        .it-title { margin: 0; font-size: 28px; font-weight: 700; letter-spacing: -0.02em; line-height: 1.15; }
        .it-subtitle { margin: 4px 0 0; color: var(--it-text-sub); font-size: 14px; }

        /* ---- Buttons ---- */
        .it-btn-primary {
            height: 44px; padding: 0 18px; border: 0; border-radius: 8px;
            background: var(--it-accent); color: #ffffff; font: inherit; font-weight: 600;
            cursor: pointer; display: inline-flex; align-items: center; gap: 8px;
        }
        .it-btn-primary:hover { background: #0c4a3b; color: #fff; }

        /* ---- Filter bar ---- */
        .it-toolbar { display: flex; flex-wrap: wrap; align-items: center; gap: 12px; margin-bottom: 14px; }
        .it-search {
            flex: 1 1 260px; max-width: 380px; height: 44px; box-sizing: border-box;
            display: flex; align-items: center; gap: 10px; padding: 0 14px;
            background: var(--it-surface); border: 1px solid var(--it-border-input);
            border-radius: 8px; color: var(--it-text-sub);
        }
        .it-search input { flex: 1; min-width: 0; border: 0; outline: 0; background: transparent; font: inherit; color: var(--it-text); }
        .it-count { margin-left: auto; color: var(--it-text-sub); }

        /* ---- Card + table ---- */
        .it-card { background: var(--it-surface); border: 1px solid var(--it-border); border-radius: 12px; }
        /* DataTables internal scroll: header stays, body scrolls, page never grows */
        #item_table_wrapper .dataTables_scrollBody { overflow-y: auto !important; }
        #item_table_wrapper .dataTables_scrollHead { background: var(--it-surface-sub); border-radius: 12px 12px 0 0; }
        .it-card .dataTables_scrollBody::-webkit-scrollbar { width: 10px; height: 10px; }
        .it-card .dataTables_scrollBody::-webkit-scrollbar-thumb { background: #cfd8d2; border-radius: 6px; }
        table.it-table { width: 100%; border-collapse: collapse; font-size: 14px; }
        table.it-table thead th {
            background: var(--it-surface-sub); color: var(--it-text-sub); font-size: 12px; font-weight: 600;
            letter-spacing: 0.06em; text-transform: uppercase; text-align: left; padding: 12px 20px;
            border-bottom: 1px solid var(--it-border); white-space: nowrap;
        }
        table.it-table tbody td { padding: 14px 20px; border-bottom: 1px solid var(--it-border-soft); vertical-align: middle; }
        table.it-table tbody tr:last-child td { border-bottom: 0; }
        table.it-table tbody tr:hover td { background: var(--it-surface-sub); }

        .it-name { font-weight: 600; color: var(--it-text); }
        .it-muted { color: var(--it-text-muted); }

        .it-chip {
            display: inline-block; padding: 3px 9px; border-radius: 6px; margin: 2px 3px 2px 0;
            background: var(--it-accent-tint); color: var(--it-accent);
            font-family: 'FSEmericLight', Helvetica, monospace; font-size: 12px; font-weight: 600;
        }
        .it-group-chip {
            display: inline-block; padding: 3px 10px; border-radius: 999px;
            background: #eef1ef; color: #55635d; font-size: 12px; font-weight: 600;
        }

        /* ---- Row action buttons ---- */
        .it-act {
            width: 40px; height: 40px; border-radius: 8px; background: var(--it-surface);
            cursor: pointer; display: inline-flex; align-items: center; justify-content: center; margin-left: 4px;
        }
        .it-act-edit   { border: 1px solid var(--it-border); color: #3d4a45; }
        .it-act-edit:hover   { background: var(--it-accent-tint); color: var(--it-accent); }
        .it-act-delete { border: 1px solid #f0d5d2; color: #a32a1f; }
        .it-act-delete:hover { background: #a32a1f; color: #fff; }

        .it-empty { padding: 40px 20px; text-align: center; color: var(--it-text-muted); }

        /* Hide default DataTables chrome */
        #item_table_wrapper .dataTables_filter,
        #item_table_wrapper .dataTables_length { display: none; }
        /* single compact footer: entry count on the left, pager on the right */
        #item_table_wrapper .dataTables_info { float: left; padding: 10px 20px; margin: 0; font-size: 13px; color: var(--it-text-sub, #5c6b64); }
        #item_table_wrapper .dataTables_paginate { float: right; padding: 6px 16px; margin: 0; }
        #item_table_wrapper::after { content: ""; display: table; clear: both; }

.swal2-popup .form-floating > .form-control,
        .swal2-popup .form-floating > .form-select { border-radius: 8px; }
        .swal2-popup .form-floating > label { padding-left: 1rem; }
        .swal2-popup .it-field-label { display:block; font-size:12px; font-weight:600; color:#55635d; margin-bottom:6px; text-align:left; }
        .it-asterisk { color: #c0392b; }

        /* Selectize sits inside the SweetAlert popup */
        /* Keep the modal body from clipping the first field */
        .swal2-popup .swal2-html-container { overflow: visible; margin-top: .5rem; }
        .swal2-popup { padding-top: 1.25rem; overflow: visible !important; }  /* keep Selectize dropdown unclipped */
        /* Selectize styled to match the canvas form controls */
        .swal2-popup .selectize-control { text-align: left; margin-bottom: 2px; }
        .swal2-popup .selectize-input {
            min-height: 46px;
            border: 1px solid #cfd8d2;
            border-radius: 8px;
            padding: 8px 12px;
            box-shadow: none;
            font-size: 14px;
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 4px;
        }
        .swal2-popup .selectize-input.focus {
            border-color: #0f5a47;
            box-shadow: 0 0 0 3px #e3efe9;
        }
        .swal2-popup .selectize-input > input { font-size: 14px; }
        .swal2-popup .selectize-input .item {
            background: #e3efe9;
            color: #0f5a47;
            border-radius: 6px;
            padding: 2px 8px;
            font-weight: 600;
            font-size: 13px;
        }
        .swal2-popup .selectize-input .item .remove {
            border-left: 0;
            color: #0f5a47;
            padding-left: 6px;
        }
        .swal2-popup .selectize-dropdown {
            border: 1px solid #cfd8d2;
            border-radius: 8px;
            box-shadow: 0 10px 30px -18px rgba(15,90,71,.35);
            font-size: 14px;
            z-index: 2000;
        }
        .swal2-popup .selectize-dropdown .option { padding: 9px 12px; }
        .swal2-popup .selectize-dropdown .active { background: #e3efe9; color: #0f5a47; }
    </style>
</head>

<body>
<%@include file="/Utilities/Header.jsp" %>

<div class="it-wrap">

    <div class="it-head">
        <div>
            <h1 class="it-title">Items</h1>
            <p class="it-subtitle">Manage items and the machines each one is qualified to run on.</p>
        </div>
        <button type="button" class="it-btn-primary" id="add">
            <i class="fa-solid fa-plus"></i> Add Item
        </button>
    </div>

    <div class="it-toolbar">
        <label class="it-search">
            <i class="fa-solid fa-magnifying-glass" aria-hidden="true"></i>
            <input type="search" id="it-search-input" placeholder="Search item, group, or machine" aria-label="Search items">
        </label>
        <span class="it-count" id="it-count">0 items</span>
    </div>

    <div class="it-card">
        <div class="table-responsive">
            <table id="item_table" class="it-table w-100" style="font-size:14px;">
                <thead>
                    <tr>
                        <th style="width:220px;">Item</th>
                        <th style="width:110px;">Group</th>
                        <th>Qualified Machines</th>
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
        const baseUrl = contextPath + "/item";
        const machineListUrl = contextPath + "/machine/l";

        let selectizeInstance = null;

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

        function machineChips(machines) {
            if (!machines || machines.length === 0) {
                return '<span class="it-muted">No machines</span>';
            }
            let html = "";
            for (let i = 0; i < machines.length; i++) {
                html += '<span class="it-chip">' + escapeHtml(machines[i].machineName) + '</span>';
            }
            return html;
        }

        /* The add/edit form markup. Machine select is populated after open. */
        function buildItemForm(data) {
            const d = data || {};
            return ''
                + '<form id="itemform" style="width:100%; overflow:visible;">'
                +   '<div class="row g-2 mb-2 text-start mx-auto">'
                +     '<div class="col-md-8">'
                +       '<div class="form-floating">'
                +         '<input type="text" class="form-control" id="swal-itemname" maxlength="100" placeholder="Item Name" value="' + escapeHtml(d.itemName) + '">'
                +         '<label class="ms-2" for="swal-itemname"><span class="it-asterisk">*</span> Item Name</label>'
                +       '</div>'
                +     '</div>'
                +     '<div class="col-md-4">'
                +       '<div class="form-floating">'
                +         '<input type="text" class="form-control" id="swal-groupcode" maxlength="20" placeholder="Group Code" value="' + escapeHtml(d.groupCode) + '" style="text-transform:uppercase;">'
                +         '<label class="ms-2" for="swal-groupcode">Group Code</label>'
                +       '</div>'
                +     '</div>'
                +   '</div>'
                +   '<div class="mb-1 text-start">'
                +     '<label class="it-field-label" for="swal-machines">Qualified Machines</label>'
                +     '<select id="swal-machines" multiple placeholder="Select machines..."></select>'
                +   '</div>'
                + '</form>';
        }

        /* Build the Selectize machine picker with the given preselected ids. */
        function initMachineSelect(machineList, selectedIds) {
            const $select = $("#swal-machines");
            for (let i = 0; i < machineList.length; i++) {
                const m = machineList[i];
                const typeCode = m.machineType ? m.machineType.machineCode : "";
                const label = m.machineName + (typeCode ? "  (" + typeCode + ")" : "");
                const option = new Option(label, m.machineId, false, false);
                $select.append(option);
            }
            selectizeInstance = $select.selectize({
                plugins: ["remove_button"],
                placeholder: "Select machines...",
                hideSelected: true
            })[0].selectize;

            if (selectedIds && selectedIds.length > 0) {
                selectizeInstance.setValue(selectedIds, true);
            }
        }

        function selectedMachineIds(data) {
            const ids = [];
            if (data && data.machines) {
                for (let i = 0; i < data.machines.length; i++) {
                    ids.push(String(data.machines[i].machineId));
                }
            }
            return ids;
        }

        function collectForm() {
            const machineIds = selectizeInstance ? selectizeInstance.getValue() : [];
            return {
                itemname:  $("#swal-itemname").val().trim(),
                groupcode: $("#swal-groupcode").val().trim(),
                machineids: Array.isArray(machineIds) ? machineIds.join(",") : machineIds
            };
        }

        function destroySelectize() {
            if (selectizeInstance) {
                selectizeInstance.destroy();
                selectizeInstance = null;
            }
        }

        /* Load the machine list, then run the callback with it. */
        function withMachines(onReady) {
            $.ajax({
                url: machineListUrl,
                type: "GET",
                dataType: "json",
                success: function (list) { onReady(list || []); },
                error: function (xhr) {
                    Swal.fire({ icon: "error", title: "Failed", text: "Could not load machines. " + xhr.responseText, confirmButtonColor: "#0f5a47" });
                }
            });
        }

        /* ---------- DataTable ---------- */
        const table = $("#item_table").DataTable({
            scrollY: "calc(100vh - 360px)",
            scrollX: true,
            scrollCollapse: true,
            paging: true,
            pageLength: 25,
            lengthMenu: [[25, 50, 100, -1], [25, 50, 100, "All"]],
            info: true,
            ajax: { url: baseUrl + "/l", dataSrc: "" },
            columns: [
                { data: "itemName", render: function (d) { return '<span class="it-name">' + escapeHtml(d) + '</span>'; } },
                { data: "groupCode", render: function (d) {
                    return d ? '<span class="it-group-chip">' + escapeHtml(d) + '</span>' : '<span class="it-muted">&mdash;</span>';
                }},
                { data: "machines", orderable: false, render: function (machines) { return machineChips(machines); } },
                { data: "itemId", orderable: false, className: "text-end", render: function (id) {
                    return ''
                        + '<button type="button" class="it-act it-act-edit js-edit" title="Edit" data-id="' + id + '"><i class="fa-solid fa-pen"></i></button>'
                        + '<button type="button" class="it-act it-act-delete js-delete" title="Delete" data-id="' + id + '"><i class="fa-solid fa-trash"></i></button>';
                }}
            ],
            order: [[0, "asc"]],
            language: {
                emptyTable: '<div class="it-empty">No items yet.</div>',
                zeroRecords: '<div class="it-empty">No items match your search.</div>'
            },
            drawCallback: function () {
                const count = this.api().rows({ search: "applied" }).count();
                $("#it-count").text(count + (count === 1 ? " item" : " items"));
            }
        });

        /* ---------- Search ---------- */
        $("#it-search-input").on("keyup", function () {
            table.search(this.value).draw();
        });

        /* ---------- Add ---------- */
        $("#add").on("click", function () {
            withMachines(function (machineList) {
                Swal.fire({
                    title: "Add Item",
                    html: buildItemForm({}),
                    width: 640,
                    showCancelButton: true,
                    confirmButtonText: "Save",
                    confirmButtonColor: "#0f5a47",
                    focusConfirm: false,
                    didOpen: function () {
                        initMachineSelect(machineList, []);
                    },
                    willClose: function () {
                        destroySelectize();
                    },
                    preConfirm: function () {
                        if (!validateField("#swal-itemname", "Item name is required.", 1)) { return false; }
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
        $("#item_table tbody").on("click", ".js-edit", function () {
            const itemId = $(this).data("id");
            showLoadingScreen();
            $.ajax({
                url: baseUrl + "/u",
                type: "GET",
                data: { id: itemId },
                dataType: "json",
                success: function (data) {
                    withMachines(function (machineList) {
                        Swal.fire({
                            title: "Edit Item",
                            html: buildItemForm(data),
                            width: 640,
                            showCancelButton: true,
                            confirmButtonText: "Update",
                            confirmButtonColor: "#0f5a47",
                            focusConfirm: false,
                            didOpen: function () {
                                initMachineSelect(machineList, selectedMachineIds(data));
                            },
                            willClose: function () {
                                destroySelectize();
                            },
                            preConfirm: function () {
                                if (!validateField("#swal-itemname", "Item name is required.", 1)) { return false; }
                                const form = collectForm();
                                form.id = itemId;
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
        $("#item_table tbody").on("click", ".js-delete", function () {
            const itemId = $(this).data("id");
            Swal.fire({
                title: "Delete this item?",
                text: "This permanently deletes the item and its machine links.",
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
                        data: { id: itemId },
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
