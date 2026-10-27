<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Precondition Raw</title>
    <%@include file="/Utilities/links.jsp" %>

    <style>
        :root {
            --pc-accent:        #0f5a47;
            --pc-accent-tint:   #e3efe9;
            --pc-accent-soft:   #eef4f0;
            --pc-page:          #f4f6f3;
            --pc-surface:       #ffffff;
            --pc-surface-sub:   #fafbf9;
            --pc-border:        #dfe5e0;
            --pc-border-soft:   #edf0ed;
            --pc-border-input:  #cfd8d2;
            --pc-text:          #17211d;
            --pc-text-sub:      #55635d;
            --pc-text-muted:    #6a7771;
        }
        body { background: var(--pc-page); color: var(--pc-text); font-family: 'FSEmericLight', Helvetica, 'Segoe UI', sans-serif; font-size: 14px; }
        .pc-wrap { max-width: 100%; margin: 0 auto; padding: 24px 20px 48px; }

        .pc-head { display: flex; flex-wrap: wrap; align-items: flex-end; justify-content: space-between; gap: 16px 24px; margin-bottom: 16px; }
        .pc-title { margin: 0; font-size: 26px; font-weight: 700; letter-spacing: -0.02em; }
        .pc-subtitle { margin: 4px 0 0; color: var(--pc-text-sub); font-size: 14px; }
        .pc-actions { display: inline-flex; gap: 8px; }

        .pc-btn-primary, .pc-btn-ghost { height: 42px; padding: 0 16px; border-radius: 8px; font: inherit; font-weight: 600; cursor: pointer; display: inline-flex; align-items: center; gap: 8px; }
        .pc-btn-primary { border: 0; background: var(--pc-accent); color: #fff; }
        .pc-btn-primary:hover { background: #0c4a3b; color: #fff; }
        .pc-btn-primary:disabled, .pc-btn-ghost:disabled { opacity: .5; cursor: not-allowed; }
        .pc-btn-ghost { border: 1px solid var(--pc-border-input); background: var(--pc-surface); color: var(--pc-accent); }
        .pc-btn-ghost:hover:not(:disabled) { background: var(--pc-accent-soft); }

        .pc-toolbar { display: flex; flex-wrap: wrap; align-items: center; gap: 12px; margin-bottom: 14px; }
        .pc-plan { height: 42px; min-width: 280px; padding: 0 12px; border: 1px solid var(--pc-border-input); border-radius: 8px; background: var(--pc-surface); font: inherit; color: var(--pc-text); }
        .pc-link { height: 42px; display: inline-flex; align-items: center; gap: 6px; padding: 0 12px; border-radius: 8px; color: var(--pc-text-sub); text-decoration: none; font-weight: 600; }
        .pc-link:hover { color: var(--pc-accent); background: var(--pc-accent-soft); }
        .pc-count { margin-left: auto; color: var(--pc-text-sub); }

        .pc-card { background: var(--pc-surface); border: 1px solid var(--pc-border); border-radius: 12px; padding: 8px; }
        .pc-scroll { overflow-x: auto; max-height: 66vh; overflow-y: auto; }

        table.pc-table { width: 100%; border-collapse: collapse; font-size: 13px; }
        table.pc-table thead th { position: sticky; top: 0; z-index: 2; background: var(--pc-surface-sub); color: var(--pc-text-sub); font-size: 11px; font-weight: 600; letter-spacing: .04em; text-transform: uppercase; text-align: left; padding: 9px 12px; border-bottom: 1px solid var(--pc-border); white-space: nowrap; }
        table.pc-table tbody td { padding: 9px 12px; border-bottom: 1px solid var(--pc-border-soft); vertical-align: middle; white-space: nowrap; }
        table.pc-table tbody tr:last-child td { border-bottom: 0; }
        table.pc-table tbody tr:hover td { background: var(--pc-surface-sub); }
        table.pc-table td.num { text-align: right; font-variant-numeric: tabular-nums; }
        .pc-name { font-weight: 600; }
        .pc-muted { color: var(--pc-text-muted); }

        .pc-act { width: 34px; height: 34px; border-radius: 7px; background: var(--pc-surface); cursor: pointer; display: inline-flex; align-items: center; justify-content: center; margin-left: 3px; }
        .pc-act-edit { border: 1px solid var(--pc-border); color: #3d4a45; }
        .pc-act-edit:hover { background: var(--pc-accent-tint); color: var(--pc-accent); }
        .pc-act-delete { border: 1px solid #f0d5d2; color: #a32a1f; }
        .pc-act-delete:hover { background: #a32a1f; color: #fff; }

        .pc-empty { padding: 40px 20px; text-align: center; color: var(--pc-text-muted); }
        .pc-asterisk { color: #c0392b; }

        /* ---- Modal form: aligned grid, no label overlap ---- */
        .swal2-popup.pc-swal { width: 820px; max-width: 95vw; }
        .pc-form { width: 100%; text-align: left; }
        .pc-form .pc-fsec { font-size: 12px; font-weight: 700; letter-spacing: .04em; text-transform: uppercase; color: var(--pc-text-sub); margin: 14px 2px 8px; }
        .pc-form .pc-fsec:first-child { margin-top: 4px; }
        .pc-grid { display: grid; gap: 12px; }
        .pc-grid.cols-2 { grid-template-columns: repeat(2, 1fr); }
        .pc-grid.cols-4 { grid-template-columns: repeat(4, 1fr); }
        .pc-field { display: flex; flex-direction: column; gap: 5px; min-width: 0; }
        .pc-field label { font-size: 12px; font-weight: 600; color: var(--pc-text-sub); padding-left: 2px; }
        .pc-field input, .pc-field select { height: 42px; width: 100%; box-sizing: border-box; padding: 0 12px; border: 1px solid var(--pc-border-input); border-radius: 8px; background: var(--pc-surface); font: inherit; color: var(--pc-text); }
        .pc-field input:focus, .pc-field select:focus { outline: none; border-color: var(--pc-accent); box-shadow: 0 0 0 3px var(--pc-accent-soft); }
        @media (max-width: 640px) { .pc-grid.cols-4 { grid-template-columns: repeat(2, 1fr); } .pc-grid.cols-2 { grid-template-columns: 1fr; } }
    </style>
</head>

<body>
<%@include file="/Utilities/Header.jsp" %>

<div class="pc-wrap">

    <div class="pc-head">
        <div>
            <h1 class="pc-title">Precondition Raw</h1>
            <p class="pc-subtitle">Per-item raw inputs for a plan. The computed Precondition is derived from these plus the Saggering plan.</p>
        </div>
        <div class="pc-actions">
            <button type="button" class="pc-btn-ghost" id="import" disabled>
                <i class="fa-solid fa-file-excel"></i> Import Excel
            </button>
            <button type="button" class="pc-btn-primary" id="add" disabled>
                <i class="fa-solid fa-plus"></i> Add Raw Input
            </button>
        </div>
    </div>

    <div class="pc-toolbar">
        <select class="pc-plan" id="planSelect" aria-label="Select plan"><option value="">Select a monthly plan</option></select>
        <a class="pc-link" id="viewComputed" href="#"><i class="fa-solid fa-calculator"></i> View Computed Precondition</a>
        <span class="pc-count" id="pc-count"></span>
    </div>

    <div class="pc-card">
        <div class="pc-scroll">
            <table id="raw_table" class="pc-table w-100">
                <thead>
                    <tr>
                        <th>Item</th><th>Cap Code</th>
                        <th class="num">Lots/Batch</th><th class="num">Int. Sheet</th><th class="num">Dummy</th>
                        <th class="num">Blk/Lot</th><th class="num">kpcs/Lot</th><th class="num">sec/Sht</th>
                        <th class="num">Eff %</th><th class="num">Lots/Mo</th>
                        <th style="text-align:right;">Actions</th>
                    </tr>
                </thead>
                <tbody></tbody>
            </table>
        </div>
    </div>

</div>

<!-- hidden file input for Excel import -->
<input type="file" id="importFile" accept=".xlsx" style="display:none;">

<script>
    $(document).ready(function () {

        const contextPath = "${pageContext.request.contextPath}";
        const baseUrl = contextPath + "/precondition";      // raw CRUD: /l /n /u /d
        const importUrl = contextPath + "/preconditionraw/i";
        const planListUrl = contextPath + "/monthlyplan/l";
        const itemUrl = contextPath + "/item/l";

        let currentPlanId = "";
        let refItems = [];

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
                .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
                .replace(/"/g, "&quot;").replace(/'/g, "&#039;");
        }

        function monthLabel(planMonth) {
            if (!planMonth) { return ""; }
            let y, m;
            if (typeof planMonth === "object") {
                const src = planMonth.date ? planMonth.date : planMonth;
                y = src.year; m = (src.monthValue != null) ? src.monthValue : src.month;
            } else {
                const parts = String(planMonth).split("T")[0].split("-");
                y = parts[0]; m = parseInt(parts[1], 10);
            }
            const names = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
            return (m >= 1 && m <= 12 ? names[m - 1] : m) + " " + y;
        }

        function num(v) {
            if (v == null) { return ""; }
            const n = Number(v);
            if (isNaN(n)) { return ""; }
            return (n === Math.floor(n)) ? String(n) : n.toFixed(2);
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

        /* ---------- Plan selector ---------- */
        function loadPlans() {
            $.ajax({
                url: planListUrl, type: "GET", dataType: "json",
                success: function (plans) {
                    const sel = $("#planSelect");
                    for (let i = 0; i < (plans || []).length; i++) {
                        const pl = plans[i];
                        const label = monthLabel(pl.planMonth) + " — " + escapeHtml(pl.machineCode);
                        sel.append('<option value="' + pl.planId + '">' + label + '</option>');
                    }
                },
                error: function (xhr) {
                    Swal.fire({ icon: "error", title: "Failed", text: xhr.responseText, confirmButtonColor: "#0f5a47" });
                }
            });
        }

        $("#planSelect").on("change", function () {
            currentPlanId = this.value;
            const has = !!currentPlanId;
            $("#add").prop("disabled", !has);
            $("#import").prop("disabled", !has);
            if (has) { loadRaw(); }
            else { $("#raw_table tbody").empty(); $("#pc-count").text(""); }
        });

        $("#viewComputed").on("click", function (e) {
            e.preventDefault();
            let url = contextPath + "/precondition/view";
            if (currentPlanId) { url += "?planid=" + currentPlanId; }
            window.location.href = url;
        });

        /* ---------- Raw table ---------- */
        function loadRaw() {
            $.ajax({
                url: baseUrl + "/l", type: "GET", data: { planid: currentPlanId }, dataType: "json",
                success: function (rows) { renderRaw(rows || []); },
                error: function (xhr) { Swal.fire({ icon: "error", title: "Failed", text: xhr.responseText, confirmButtonColor: "#0f5a47" }); }
            });
        }

        function renderRaw(rows) {
            const body = $("#raw_table tbody").empty();
            $("#pc-count").text(rows.length + (rows.length === 1 ? " item" : " items"));
            if (rows.length === 0) {
                body.html('<tr><td colspan="11"><div class="pc-empty">No raw inputs for this plan yet. Add one or import from Excel.</div></td></tr>');
                return;
            }
            for (let i = 0; i < rows.length; i++) {
                const r = rows[i];
                const item = r.item || {};
                body.append('<tr>'
                    + '<td><span class="pc-name">' + escapeHtml(item.itemName) + '</span></td>'
                    + '<td>' + (r.capCode ? escapeHtml(r.capCode) : '<span class="pc-muted">&mdash;</span>') + '</td>'
                    + '<td class="num">' + num(r.lotsPerBatch) + '</td>'
                    + '<td class="num">' + num(r.internalSheet) + '</td>'
                    + '<td class="num">' + num(r.dummySheet) + '</td>'
                    + '<td class="num">' + num(r.blkPerLot) + '</td>'
                    + '<td class="num">' + num(r.kpcsPerLot) + '</td>'
                    + '<td class="num">' + num(r.secPerSht) + '</td>'
                    + '<td class="num">' + num(r.eff * 100) + '</td>'
                    + '<td class="num">' + num(r.lotsPerMonth) + '</td>'
                    + '<td style="text-align:right;">'
                    +   '<button type="button" class="pc-act pc-act-edit js-edit" title="Edit" data-id="' + r.preconditionRawId + '"><i class="fa-solid fa-pen"></i></button>'
                    +   '<button type="button" class="pc-act pc-act-delete js-delete" title="Delete" data-id="' + r.preconditionRawId + '"><i class="fa-solid fa-trash"></i></button>'
                    + '</td></tr>');
            }
        }

        /* ---------- Modal form (aligned grid) ---------- */
        function field(id, label, value, opts) {
            opts = opts || {};
            const req = opts.required ? '<span class="pc-asterisk">*</span> ' : '';
            const step = opts.step ? ' step="' + opts.step + '"' : '';
            const min = (opts.min != null) ? ' min="' + opts.min + '"' : ' min="0"';
            const max = (opts.max != null) ? ' max="' + opts.max + '"' : '';
            const type = opts.type || "number";
            const extra = (opts.maxlength ? ' maxlength="' + opts.maxlength + '"' : '');
            return '<div class="pc-field">'
                + '<label for="' + id + '">' + req + escapeHtml(label) + '</label>'
                + '<input type="' + type + '" id="' + id + '"' + min + max + step + extra
                +   ' placeholder="' + escapeHtml(label) + '" value="' + (value != null ? escapeHtml(value) : "") + '">'
                + '</div>';
        }

        function buildForm(d) {
            d = d || {};
            const item = d.item || {};
            const effPct = (d.eff != null) ? (d.eff * 100) : "";
            return ''
                + '<div class="pc-form">'
                +   '<div class="pc-fsec">Identity</div>'
                +   '<div class="pc-grid cols-2">'
                +     '<div class="pc-field">'
                +       '<label for="swal-itemid"><span class="pc-asterisk">*</span> Item</label>'
                +       '<select id="swal-itemid">' + itemOptions(item.itemId) + '</select>'
                +     '</div>'
                +     field("swal-capcode", "Cap Code", d.capCode, { type: "text", maxlength: 50 })
                +   '</div>'
                +   '<div class="pc-fsec">Sheet &amp; Lot</div>'
                +   '<div class="pc-grid cols-4">'
                +     field("swal-lotsperbatch", "Lots / Batch", d.lotsPerBatch)
                +     field("swal-internalsheet", "Internal Sheet", d.internalSheet)
                +     field("swal-dummysheet", "Dummy Sheet", d.dummySheet)
                +     field("swal-blkperlot", "Blk / Lot", d.blkPerLot)
                +   '</div>'
                +   '<div class="pc-fsec">Time, Efficiency &amp; Plan</div>'
                +   '<div class="pc-grid cols-4">'
                +     field("swal-kpcsperlot", "kpcs / Lot", d.kpcsPerLot, { step: "0.001" })
                +     field("swal-secpersht", "sec / Sheet", d.secPerSht, { step: "0.001" })
                +     field("swal-eff", "Efficiency %", effPct, { required: true, step: "0.01", max: 100 })
                +     field("swal-lotspermonth", "Lots / Month", d.lotsPerMonth)
                +   '</div>'
                + '</div>';
        }

        function collectForm() {
            return {
                planid:        currentPlanId,
                itemid:        $("#swal-itemid").val(),
                capcode:       $("#swal-capcode").val().trim(),
                lotsperbatch:  $("#swal-lotsperbatch").val(),
                internalsheet: $("#swal-internalsheet").val(),
                dummysheet:    $("#swal-dummysheet").val(),
                blkperlot:     $("#swal-blkperlot").val(),
                kpcsperlot:    $("#swal-kpcsperlot").val(),
                secpersht:     $("#swal-secpersht").val(),
                eff:           $("#swal-eff").val(),
                lotspermonth:  $("#swal-lotspermonth").val()
            };
        }

        function validateForm() {
            if (!$("#swal-itemid").val()) { Swal.showValidationMessage("Please select an item."); return false; }
            const eff = parseFloat($("#swal-eff").val());
            if (isNaN(eff) || eff < 0 || eff > 100) { Swal.showValidationMessage("Efficiency must be between 0 and 100."); return false; }
            return true;
        }

        function withItems(onReady) {
            $.ajax({
                url: itemUrl, type: "GET", dataType: "json",
                success: function (list) { refItems = list || []; onReady(); },
                error: function () { Swal.fire({ icon: "error", title: "Failed", text: "Could not load items.", confirmButtonColor: "#0f5a47" }); }
            });
        }

        /* ---------- Add ---------- */
        $("#add").on("click", function () {
            if (!currentPlanId) { return; }
            withItems(function () {
                if (refItems.length === 0) {
                    Swal.fire({ icon: "info", title: "No items", text: "Add an item first.", confirmButtonColor: "#0f5a47" });
                    return;
                }
                Swal.fire({
                    title: "Add Raw Input",
                    html: buildForm({}),
                    customClass: { popup: "pc-swal" },
                    showCancelButton: true,
                    confirmButtonText: "Save",
                    confirmButtonColor: "#0f5a47",
                    focusConfirm: false,
                    preConfirm: function () { if (!validateForm()) { return false; } return collectForm(); }
                }).then(function (result) {
                    if (result.isConfirmed) {
                        showLoadingScreen();
                        $.ajax({
                            url: baseUrl + "/n", type: "POST", data: result.value,
                            success: function (response) {
                                Swal.fire({ icon: "success", title: "Saved", text: response, confirmButtonColor: "#0f5a47" });
                                loadRaw();
                            },
                            error: function (xhr) { Swal.fire({ icon: "error", title: "Failed", text: xhr.responseText, confirmButtonColor: "#0f5a47" }); }
                        });
                    }
                });
            });
        });

        /* ---------- Edit ---------- */
        $("#raw_table tbody").on("click", ".js-edit", function () {
            const id = $(this).data("id");
            showLoadingScreen();
            $.ajax({
                url: baseUrl + "/u", type: "GET", data: { id: id }, dataType: "json",
                success: function (data) {
                    withItems(function () {
                        Swal.fire({
                            title: "Edit Raw Input",
                            html: buildForm(data),
                            customClass: { popup: "pc-swal" },
                            showCancelButton: true,
                            confirmButtonText: "Update",
                            confirmButtonColor: "#0f5a47",
                            focusConfirm: false,
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
                                        loadRaw();
                                    },
                                    error: function (xhr) { Swal.fire({ icon: "error", title: "Failed", text: xhr.responseText, confirmButtonColor: "#0f5a47" }); }
                                });
                            }
                        });
                    });
                },
                error: function (xhr) { Swal.fire({ icon: "error", title: "Failed", text: xhr.responseText, confirmButtonColor: "#0f5a47" }); }
            });
        });

        /* ---------- Delete ---------- */
        $("#raw_table tbody").on("click", ".js-delete", function () {
            const id = $(this).data("id");
            Swal.fire({
                title: "Delete this raw input?",
                text: "This permanently removes the item's inputs for this plan.",
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
                            loadRaw();
                        },
                        error: function (xhr) { Swal.fire({ icon: "error", title: "Failed", text: xhr.responseText, confirmButtonColor: "#0f5a47" }); }
                    });
                }
            });
        });

        /* ---------- Import Excel ---------- */
        $("#import").on("click", function () {
            if (!currentPlanId) { return; }
            $("#importFile").val("");
            $("#importFile").trigger("click");
        });

        $("#importFile").on("change", function () {
            const file = this.files && this.files[0];
            if (!file) { return; }

            const formData = new FormData();
            formData.append("file", file);
            formData.append("planId", currentPlanId);

            showLoadingScreen();
            $.ajax({
                url: importUrl,
                type: "POST",
                data: formData,
                processData: false,
                contentType: false,
                success: function (response) {
                    Swal.fire({ icon: "success", title: "Imported", text: response, confirmButtonColor: "#0f5a47" });
                    loadRaw();
                },
                error: function (xhr) {
                    Swal.fire({ icon: "error", title: "Import failed", text: xhr.responseText, confirmButtonColor: "#0f5a47" });
                }
            });
        });

        /* ---------- Initial ---------- */
        loadPlans();

        // Preselect a plan passed via ?planid= (from Monthly Planner stage)
        const preselect = "${preselectPlanId}";
        if (preselect) { $("#planSelect").val(preselect).trigger("change"); }

    });
</script>
</body>
</html>
