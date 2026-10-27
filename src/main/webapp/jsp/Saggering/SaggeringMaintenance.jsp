<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Saggering</title>
    <%@include file="/Utilities/links.jsp" %>

    <style>
        :root {
            --sg-accent:#0f5a47; --sg-accent-tint:#e3efe9; --sg-page:#f4f6f3; --sg-surface:#ffffff;
            --sg-surface-sub:#fafbf9; --sg-border:#dfe5e0; --sg-border-soft:#edf0ed; --sg-border-input:#cfd8d2;
            --sg-text:#17211d; --sg-text-sub:#55635d; --sg-text-muted:#6a7771;
        }
        body { background: var(--sg-page); color: var(--sg-text); font-family: 'FSEmericLight', Helvetica, 'Segoe UI', sans-serif; font-size: 14px; }
        .sg-wrap { max-width: 100%; margin: 0 auto; padding: 24px 20px 48px; }

        .sg-head { display: flex; flex-wrap: wrap; align-items: flex-end; justify-content: space-between; gap: 16px 24px; margin-bottom: 16px; }
        .sg-title { margin: 0; font-size: 26px; font-weight: 700; letter-spacing: -0.02em; }
        .sg-subtitle { margin: 4px 0 0; color: var(--sg-text-sub); font-size: 14px; }

        .sg-toolbar { display: flex; flex-wrap: wrap; align-items: center; gap: 12px; margin-bottom: 14px; }
        .sg-plan { height: 42px; min-width: 300px; padding: 0 12px; border: 1px solid var(--sg-border-input); border-radius: 8px; background: var(--sg-surface); font: inherit; color: var(--sg-text); }
        .sg-btn { height: 42px; padding: 0 16px; border-radius: 8px; border: 1px solid var(--sg-accent); background: var(--sg-accent); color: #fff; font: inherit; font-weight: 600; cursor: pointer; display: inline-flex; align-items: center; gap: 8px; }
        .sg-btn:hover { background: #0c4a3b; }
        .sg-btn:disabled { opacity: .5; cursor: not-allowed; }
        .sg-btn-ghost { background: var(--sg-surface); color: var(--sg-accent); }
        .sg-btn-ghost:hover { background: var(--sg-accent-tint); }
        .sg-btn-danger { border-color: #f0d5d2; background: #fff; color: #a32a1f; }
        .sg-btn-danger:hover { background: #a32a1f; color: #fff; }
        .sg-spacer { margin-left: auto; }

        .sg-card { background: var(--sg-surface); border: 1px solid var(--sg-border); border-radius: 12px; padding: 8px; }
        .sg-scroll { overflow-x: auto; max-height: 66vh; overflow-y: auto; }

        table.sg-matrix { width: 100%; border-collapse: collapse; font-size: 13px; }
        table.sg-matrix thead th { background: var(--sg-surface-sub); color: var(--sg-text-sub); font-size: 11px; font-weight: 600; letter-spacing: .04em; text-transform: uppercase; text-align: left; padding: 8px 10px; border-bottom: 1px solid var(--sg-border); white-space: nowrap; position: sticky; top: 0; z-index: 2; }
        table.sg-matrix tbody td { padding: 5px 8px; border-bottom: 1px solid var(--sg-border-soft); vertical-align: middle; white-space: nowrap; }
        table.sg-matrix tbody tr:hover td { background: var(--sg-surface-sub); }
        .sg-day-head { text-align: center; min-width: 46px; }
        .sg-day-head.weekend { background: #eef1ef; }
        .sg-day-head .dow { display:block; font-size:10px; color: var(--sg-text-muted); }
        .sg-day-cell { padding: 2px !important; }
        .sg-day-cell.weekend { background: #f3f5f3; }
        .sg-day-input { width: 44px; height: 32px; text-align: center; border: 1px solid transparent; border-radius: 6px; background: transparent; font: inherit; }
        .sg-day-input:focus { outline: none; border-color: var(--sg-accent); background: #fff; }
        .sg-chip { display: inline-block; padding: 2px 8px; border-radius: 6px; background: var(--sg-accent-tint); color: var(--sg-accent); font-family: 'FSEmericLight', Helvetica, monospace; font-size: 12px; font-weight: 600; }
        .sg-name { font-weight: 600; }
        .sg-num { text-align: right; font-variant-numeric: tabular-nums; }
        .sg-row-del { width: 30px; height: 30px; border: 1px solid #f0d5d2; border-radius: 6px; background: #fff; color: #a32a1f; cursor: pointer; }
        .sg-row-del:hover { background: #a32a1f; color: #fff; }
        .sg-empty { padding: 44px 20px; text-align: center; color: var(--sg-text-muted); }
        .sg-warn { color: #b26a00; font-size: 12px; }

        .sg-asterisk { color: #c0392b; }
        .swal2-popup .form-floating > .form-control,
        .swal2-popup .form-floating > .form-select { border-radius: 8px; }
        .swal2-popup .form-floating > label { padding-left: 1rem; }
    </style>
</head>

<body>
<%@include file="/Utilities/Header.jsp" %>

<div class="sg-wrap">

    <div class="sg-head">
        <div>
            <h1 class="sg-title">Saggering</h1>
            <p class="sg-subtitle">Per-item daily saggering values for a monthly plan. Import from Excel or edit in the grid.</p>
        </div>
    </div>

    <div class="sg-toolbar">
        <select class="sg-plan" id="planSelect" aria-label="Select plan"><option value="">Select a monthly plan</option></select>
        <button type="button" class="sg-btn sg-btn-ghost" id="addItem" disabled><i class="fa-solid fa-plus"></i> Add Item</button>
        <button type="button" class="sg-btn sg-btn-ghost" id="importBtn" disabled><i class="fa-solid fa-file-import"></i> Import Excel</button>
        <input type="file" id="importFile" accept=".xlsx" style="display:none;">
        <span class="sg-spacer"></span>
        <button type="button" class="sg-btn sg-btn-danger" id="deleteBtn" disabled><i class="fa-solid fa-trash"></i> Delete</button>
        <button type="button" class="sg-btn" id="saveBtn" disabled><i class="fa-solid fa-floppy-disk"></i> Save</button>
    </div>

    <div class="sg-card">
        <div class="sg-scroll">
            <table id="sag_table" class="sg-matrix w-100">
                <thead></thead>
                <tbody></tbody>
            </table>
        </div>
    </div>

</div>

<script>
    $(document).ready(function () {

        const contextPath = "${pageContext.request.contextPath}";
        const planListUrl = contextPath + "/monthlyplan/l";
        const itemUrl = contextPath + "/item/l";
        const baseUrl = contextPath + "/saggering";

        const DOW = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];

        let currentPlan = null;
        let planMonth = null;   // { year, month }
        let daysInMonth = 0;
        let rows = [];          // [{ itemId, itemName, capCode, lotsPerBatch, days:{day->value} }]
        let refItems = [];

        /* ---------- Helpers ---------- */
        function showLoadingScreen() {
            Swal.fire({ title: '<span style="color:#17211d; font-size:22px; font-weight:600;">Please wait...</span>', html: '<div class="spinner"></div>', allowOutsideClick: false, showConfirmButton: false });
        }
        function escapeHtml(v) {
            if (v == null) { return ""; }
            return String(v).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;").replace(/'/g,"&#039;");
        }
        function pad2(n) { return (n < 10 ? "0" : "") + n; }

        function monthParts(pm) {
            if (!pm) { return null; }
            let y, m;
            if (typeof pm === "object") {
                const src = pm.date ? pm.date : pm;
                y = src.year; m = (src.monthValue != null) ? src.monthValue : src.month;
            } else {
                const p = String(pm).split("T")[0].split("-");
                y = Number(p[0]); m = parseInt(p[1], 10);
            }
            return { year: y, month: m };
        }
        function monthLabel(pm) {
            const p = monthParts(pm);
            if (!p) { return ""; }
            const names = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
            return (p.month >= 1 && p.month <= 12 ? names[p.month-1] : p.month) + " " + p.year;
        }
        function isoFor(day) {
            return planMonth.year + "-" + pad2(planMonth.month) + "-" + pad2(day);
        }
        function dayFromIso(iso) {
            const p = String(iso).split("T")[0].split("-");
            return parseInt(p[2], 10);
        }

        /* ---------- Plan selector ---------- */
        function loadPlans() {
            $.ajax({ url: planListUrl, type: "GET", dataType: "json",
                success: function (plans) {
                    const sel = $("#planSelect");
                    for (let i = 0; i < (plans || []).length; i++) {
                        const pl = plans[i];
                        sel.append('<option value="' + pl.planId + '">' + monthLabel(pl.planMonth) + " — " + escapeHtml(pl.machineCode) + '</option>');
                    }
                },
                error: function (xhr) { Swal.fire({ icon:"error", title:"Failed", text: xhr.responseText, confirmButtonColor:"#0f5a47" }); }
            });
        }

        $("#planSelect").on("change", function () {
            const planId = this.value;
            if (!planId) { resetScreen(); return; }
            $.ajax({ url: planListUrl, type: "GET", dataType: "json",
                success: function (plans) {
                    currentPlan = null;
                    for (let i = 0; i < (plans||[]).length; i++) { if (String(plans[i].planId) === String(planId)) { currentPlan = plans[i]; break; } }
                    if (!currentPlan) { resetScreen(); return; }
                    planMonth = monthParts(currentPlan.planMonth);
                    daysInMonth = new Date(planMonth.year, planMonth.month, 0).getDate();
                    toggleButtons(true);
                    loadSaggering();
                }
            });
        });

        function resetScreen() {
            currentPlan = null; planMonth = null; daysInMonth = 0; rows = [];
            $("#sag_table thead").empty();
            $("#sag_table tbody").html('<tr><td><div class="sg-empty">Select a monthly plan to begin.</div></td></tr>');
            toggleButtons(false);
        }
        function toggleButtons(on) {
            $("#addItem, #importBtn, #saveBtn, #deleteBtn").prop("disabled", !on);
        }

        /* ---------- Load existing ---------- */
        function loadSaggering() {
            $.ajax({ url: baseUrl + "/g", type: "GET", data: { planid: currentPlan.planId }, dataType: "json",
                success: function (sag) {
                    rows = [];
                    if (sag && sag.items) {
                        for (let i = 0; i < sag.items.length; i++) {
                            const it = sag.items[i];
                            const item = it.item || {};
                            const dayMap = {};
                            const days = it.days || [];
                            for (let j = 0; j < days.length; j++) {
                                const d = dayFromIso(toIso(days[j].planDate));
                                if (d) { dayMap[d] = days[j].value; }
                            }
                            rows.push({ itemId: item.itemId, itemName: item.itemName, capCode: it.capCode || "", lotsPerBatch: it.lotsPerBatch || 0, days: dayMap });
                        }
                    }
                    renderMatrix();
                },
                error: function (xhr) { Swal.fire({ icon:"error", title:"Failed", text: xhr.responseText, confirmButtonColor:"#0f5a47" }); }
            });
        }

        function toIso(planDate) {
            if (!planDate) { return ""; }
            if (typeof planDate === "object") {
                const src = planDate.date ? planDate.date : planDate;
                const y = src.year; const m = (src.monthValue != null) ? src.monthValue : src.month; const d = (src.dayOfMonth != null) ? src.dayOfMonth : src.day;
                if (y && m && d) { return y + "-" + pad2(m) + "-" + pad2(d); }
                return "";
            }
            return String(planDate).split("T")[0];
        }

        /* ---------- Render matrix ---------- */
        function renderMatrix() {
            let head = '<tr><th style="min-width:160px;">Item</th><th>Cap Code</th><th class="sg-num">Lots/Batch</th>';
            for (let d = 1; d <= daysInMonth; d++) {
                const dt = new Date(planMonth.year, planMonth.month - 1, d);
                const weekend = (dt.getDay() === 0 || dt.getDay() === 6) ? " weekend" : "";
                head += '<th class="sg-day-head' + weekend + '"><span class="dow">' + DOW[dt.getDay()] + '</span>' + pad2(d) + '</th>';
            }
            head += '<th></th></tr>';
            $("#sag_table thead").html(head);

            const body = $("#sag_table tbody").empty();
            if (rows.length === 0) {
                body.html('<tr><td colspan="' + (3 + daysInMonth + 1) + '"><div class="sg-empty">No saggering items. Add an item or import an Excel file.</div></td></tr>');
                return;
            }
            for (let r = 0; r < rows.length; r++) {
                const row = rows[r];
                let tr = '<tr data-idx="' + r + '">'
                    + '<td><span class="sg-name">' + escapeHtml(row.itemName) + '</span></td>'
                    + '<td>' + (row.capCode ? escapeHtml(row.capCode) : '<span class="sg-warn">no precon</span>') + '</td>'
                    + '<td class="sg-num">' + (row.lotsPerBatch || 0) + '</td>';
                for (let d = 1; d <= daysInMonth; d++) {
                    const dt = new Date(planMonth.year, planMonth.month - 1, d);
                    const weekend = (dt.getDay() === 0 || dt.getDay() === 6) ? " weekend" : "";
                    const val = (row.days[d] != null && row.days[d] !== 0) ? row.days[d] : "";
                    tr += '<td class="sg-day-cell' + weekend + '"><input type="number" class="sg-day-input" data-day="' + d + '" value="' + val + '"></td>';
                }
                tr += '<td><button type="button" class="sg-row-del" title="Remove item"><i class="fa-solid fa-xmark"></i></button></td></tr>';
                body.append(tr);
            }
        }

        /* Sync a cell edit into the model. */
        $("#sag_table tbody").on("input", ".sg-day-input", function () {
            const idx = $(this).closest("tr").data("idx");
            const day = $(this).data("day");
            const v = parseInt($(this).val(), 10);
            rows[idx].days[day] = isNaN(v) ? 0 : v;
        });

        /* Remove item row. */
        $("#sag_table tbody").on("click", ".sg-row-del", function () {
            const idx = $(this).closest("tr").data("idx");
            rows.splice(idx, 1);
            renderMatrix();
        });

        /* ---------- Add item ---------- */
        function withItems(onReady) {
            $.ajax({ url: itemUrl, type: "GET", dataType: "json",
                success: function (list) { refItems = list || []; onReady(); },
                error: function () { Swal.fire({ icon:"error", title:"Failed", text:"Could not load items.", confirmButtonColor:"#0f5a47" }); }
            });
        }
        function itemOptions() {
            let html = '<option value="">Select item</option>';
            for (let i = 0; i < refItems.length; i++) {
                const it = refItems[i];
                html += '<option value="' + it.itemId + '">' + escapeHtml(it.itemName) + '</option>';
            }
            return html;
        }

        $("#addItem").on("click", function () {
            withItems(function () {
                if (refItems.length === 0) { Swal.fire({ icon:"info", title:"No items", text:"Add an item first.", confirmButtonColor:"#0f5a47" }); return; }
                Swal.fire({
                    title: "Add Item",
                    html: '<div class="form-floating text-start">'
                        + '<select class="form-select" id="swal-itemid">' + itemOptions() + '</select>'
                        + '<label class="ms-2" for="swal-itemid"><span class="sg-asterisk">*</span> Item</label></div>',
                    showCancelButton: true, confirmButtonText: "Add", confirmButtonColor: "#0f5a47", focusConfirm: false,
                    preConfirm: function () {
                        const id = $("#swal-itemid").val();
                        if (!id) { Swal.showValidationMessage("Please select an item."); return false; }
                        return id;
                    }
                }).then(function (result) {
                    if (result.isConfirmed) {
                        const itemId = parseInt(result.value, 10);
                        for (let i = 0; i < rows.length; i++) { if (rows[i].itemId === itemId) { Swal.fire({ icon:"info", title:"Already added", confirmButtonColor:"#0f5a47" }); return; } }
                        let name = "";
                        for (let i = 0; i < refItems.length; i++) { if (refItems[i].itemId === itemId) { name = refItems[i].itemName; break; } }
                        rows.push({ itemId: itemId, itemName: name, capCode: "", lotsPerBatch: 0, days: {} });
                        renderMatrix();
                    }
                });
            });
        });

        /* ---------- Import Excel ---------- */
        $("#importBtn").on("click", function () { $("#importFile").trigger("click"); });

        $("#importFile").on("change", function () {
            const file = this.files && this.files[0];
            if (!file) { return; }
            const fd = new FormData();
            fd.append("file", file);
            fd.append("planid", currentPlan.planId);
            showLoadingScreen();
            $.ajax({
                url: baseUrl + "/i", type: "POST", data: fd, processData: false, contentType: false, dataType: "json",
                success: function (res) {
                    const items = res.items || [];
                    let added = 0;
                    for (let i = 0; i < items.length; i++) {
                        const it = items[i];
                        if (it.unknownItem || it.itemId == null) { continue; }
                        const dayMap = {};
                        const arr = it.days || [];
                        for (let d = 0; d < arr.length; d++) { if (arr[d]) { dayMap[d + 1] = arr[d]; } }
                        // Replace if already present, else add.
                        let found = false;
                        for (let r = 0; r < rows.length; r++) { if (rows[r].itemId === it.itemId) { rows[r] = { itemId: it.itemId, itemName: it.itemName, capCode: it.capCode || "", lotsPerBatch: it.lotsPerBatch || 0, days: dayMap }; found = true; break; } }
                        if (!found) { rows.push({ itemId: it.itemId, itemName: it.itemName, capCode: it.capCode || "", lotsPerBatch: it.lotsPerBatch || 0, days: dayMap }); }
                        added++;
                    }
                    renderMatrix();
                    const skipped = res.skipped || [];
                    let msg = "Imported " + added + " item(s).";
                    if (skipped.length > 0) { msg += " Skipped (unknown item or no precondition): " + skipped.join(", "); }
                    Swal.fire({ icon: "success", title: "Import complete", text: msg, confirmButtonColor: "#0f5a47" });
                },
                error: function (xhr) { Swal.fire({ icon:"error", title:"Import failed", text: xhr.responseText, confirmButtonColor:"#0f5a47" }); }
            });
            $(this).val("");
        });

        /* ---------- Save ---------- */
        $("#saveBtn").on("click", function () {
            if (!currentPlan) { return; }

            // ---- Client-side validation (matches IPMSTEST) ----
            if (rows.length === 0) {
                Swal.fire({ icon:"warning", title:"Empty table", text:"Please add at least one item before saving.", confirmButtonColor:"#0f5a47" });
                return;
            }
            const seen = {};
            const missing = [];
            const dupes = [];
            for (let r = 0; r < rows.length; r++) {
                const row = rows[r];
                const key = String(row.itemId);
                if (seen[key]) { dupes.push(row.itemName); } else { seen[key] = true; }
                const lpb = parseFloat(row.lotsPerBatch) || 0;
                if (!row.capCode || String(row.capCode).trim() === "" || lpb <= 0) {
                    missing.push(row.itemName);
                }
            }
            if (dupes.length > 0) {
                Swal.fire({ icon:"error", title:"Duplicate items", text:"Remove duplicate item(s): " + dupes.join(", "), confirmButtonColor:"#0f5a47" });
                return;
            }
            if (missing.length > 0) {
                Swal.fire({ icon:"error", title:"Missing Cap Code / Lots per Batch",
                    text:"Each item needs a Cap Code and Lots per Batch greater than 0. Please check: " + missing.join(", "),
                    confirmButtonColor:"#0f5a47" });
                return;
            }

            const payload = [];
            for (let r = 0; r < rows.length; r++) {
                const row = rows[r];
                const days = [];
                for (const d in row.days) {
                    if (row.days.hasOwnProperty(d) && row.days[d]) {
                        days.push({ planDate: isoFor(parseInt(d, 10)), value: row.days[d] });
                    }
                }
                payload.push({ itemId: row.itemId, capCode: row.capCode, lotsPerBatch: row.lotsPerBatch, days: days });
            }
            showLoadingScreen();
            $.ajax({
                url: baseUrl + "/s", type: "POST",
                data: { planid: currentPlan.planId, items: JSON.stringify(payload) },
                success: function (response) {
                    Swal.fire({ icon:"success", title:"Saved", text: response, confirmButtonColor:"#0f5a47" });
                    loadSaggering();
                },
                error: function (xhr) { Swal.fire({ icon:"error", title:"Failed", text: xhr.responseText, confirmButtonColor:"#0f5a47" }); }
            });
        });

        /* ---------- Delete ---------- */
        $("#deleteBtn").on("click", function () {
            if (!currentPlan) { return; }
            Swal.fire({ title: "Delete saggering?", text: "This removes all saggering items and days for this plan.", icon: "warning",
                showCancelButton: true, confirmButtonText: "Delete", confirmButtonColor: "#a32a1f" })
                .then(function (result) {
                    if (result.isConfirmed) {
                        showLoadingScreen();
                        $.ajax({ url: baseUrl + "/d", type: "POST", data: { planid: currentPlan.planId },
                            success: function (response) {
                                Swal.fire({ icon:"success", title:"Deleted", text: response, confirmButtonColor:"#0f5a47" });
                                rows = []; renderMatrix();
                            },
                            error: function (xhr) { Swal.fire({ icon:"error", title:"Failed", text: xhr.responseText, confirmButtonColor:"#0f5a47" }); }
                        });
                    }
                });
        });

        /* ---------- Initial ---------- */
        resetScreen();
        loadPlans();

    });
</script>
</body>
</html>
