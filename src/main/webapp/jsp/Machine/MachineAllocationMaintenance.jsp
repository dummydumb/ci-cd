<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Machine Allocation</title>
    <%@include file="/Utilities/links.jsp" %>

    <style>
        body { font-family: 'FSEmericLight', Helvetica, 'Segoe UI', sans-serif; background: #f4f6f3; }
        .btn-primary { background:#0f5a47; border-color:#0f5a47; }
        .btn-primary:hover { background:#0c4a3b; border-color:#0c4a3b; }
        .btn-dark { background:#17211d; border-color:#17211d; }
        .pl-plan { height: 40px; min-width: 260px; padding: 0 12px; border: 1px solid #cfd8d2; border-radius: 8px; background:#fff; font: inherit; }
        /* Active nav indicator */
        .navigation .nav .nav-item:nth-child(1) { font-weight: 600; position: relative; }
        .navigation .nav .nav-item:nth-child(1)::after {
            bottom: 0; content: ""; display: block; height: 0.2rem;
            left: 0; opacity: 1; position: absolute; background: #28282B; width: 100%;
        }

        .content_table {
            background: #ffffff;
            border-radius: 12px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.05);
            padding-bottom: 20px;
        }

        /* Summary cards */
        .allocation-summary-card {
            background: #fff;
            border: 1px solid #e5e7eb;
            border-radius: 12px;
            padding: 14px 16px;
            box-shadow: 0 4px 12px rgba(15,23,42,0.04);
        }
        .allocation-summary-label {
            color: #64748b;
            font-size: 11px;
            text-transform: uppercase;
            font-weight: 700;
            letter-spacing: .05em;
        }
        .allocation-summary-value {
            color: #111827;
            font-size: 24px;
            font-weight: 800;
        }
        .allocation-record-id { color: #64748b; font-size: 11px; font-weight: 700; }

        /* Reconciliation banner (Excel "SAME / NOT SAME" check) */
        .recon-banner { display:flex; align-items:center; gap:10px; border-radius:10px; padding:10px 16px; margin:0 1.5rem 14px; font-weight:600; font-size:13px; }
        .recon-ok   { background:#e3efe9; color:#0f5a47; border:1px solid #b9d6c8; }
        .recon-warn { background:#fff4e5; color:#b26a00; border:1px solid #f3d9ad; }
        .recon-bad  { background:#fdecea; color:#a32a1f; border:1px solid #f0c9c3; }
        .recon-banner .recon-detail { font-weight:500; opacity:.9; }

        /* Table cell styles */
        th {
            background-color: #f8f9fa;
            color: #64748b;
            font-weight: 600;
            text-transform: uppercase;
            font-size: 11px;
            letter-spacing: 0.05em;
            border: none;
            border-bottom: 2px solid #edf2f7;
        }
        table.dataTable tbody td { font-size: 13px; padding: 7px; vertical-align: middle; }

        .allocation-table th,
        .allocation-table td { border: 1px solid #cdd8d1 !important; text-align: center; vertical-align: middle; white-space: nowrap; }

        .td-mc       { background: #e3efe9 !important; }
        .td-grouping { background: #eef4f0 !important; }
        .td-group    { background: #d7e8e0 !important; font-weight: 800; }
        .td-item     { background: #fafbf9 !important; text-align: left !important; font-weight: 700; }
        .td-zero-fix      { background: #cfe6da !important; font-weight: 900; }
        .td-zero-fraction { background: #f1f4f1 !important; font-weight: 800; }
        .td-allocation    { background: #f3f8f5 !important; }

        .merged-cell { vertical-align: middle !important; font-weight: 800; }
        .group-section-start td { border-top: 5px solid #0f5a47 !important; }
        .group-label-a { background: #e3efe9 !important; color: #0f5a47; }
        .group-label-b { background: #e7f0fb !important; color: #1d4ed8; }
        .empty-value { color: #9ca3af; font-weight: 700; }
        .warning-text { color: #b91c1c; font-weight: 800; }

        .machine-edit-select { min-width: 90px; margin: 2px 0; font-size: 11px; font-weight: 700; }
        .form-select-sm.machine-edit-select { padding-top: 2px; padding-bottom: 2px; }

        /* Multi-fraction row: machine select + share input side-by-side */
        .frac-entry          { display:flex; align-items:center; gap:3px; margin-bottom:3px; }
        .frac-machine-select { min-width:80px; font-size:11px; font-weight:700; }
        .frac-share-input    { width:58px; font-size:11px; font-weight:700; text-align:right; }
        .frac-remove-btn     { font-size:10px; padding:1px 5px; line-height:1.2; color:#dc2626; background:transparent; border:1px solid #dc2626; border-radius:3px; cursor:pointer; }
        .frac-remove-btn:hover { background:#fee2e2; }
        .frac-add-btn        { font-size:10px; padding:1px 7px; line-height:1.2; color:#065f46; background:transparent; border:1px solid #065f46; border-radius:3px; cursor:pointer; margin-top:3px; }
        .frac-add-btn:hover  { background:#d1fae5; }
        .frac-total-label    { font-size:10px; font-weight:800; margin-top:3px; }

        .swal2-html-container { overflow: unset; }
        .swal2-actions { z-index: 0; }

        .btn-emerald-outline { color: #065f46; background: #fff; border: 1px solid #d1fae5; }

        /* ── Machine type badges ── */
        .badge-machine-type    { font-size:0.68rem; font-weight:800; text-transform:uppercase; letter-spacing:0.04em; padding:2px 9px; border-radius:6px; line-height:1.3; }
        .badge-machine-frst    { background-color:rgba(16,185,129,0.15); color:#065f46; border:1px solid rgba(16,185,129,0.35); }
        .badge-machine-gsx     { background-color:rgba(59,130,246,0.15);  color:#1d4ed8; border:1px solid rgba(59,130,246,0.35); }
        .badge-machine-default { background-color:rgba(100,116,139,0.12); color:#475569; border:1px solid rgba(100,116,139,0.25); }
    </style>
</head>

<body>
<%@include file="/Utilities/Header.jsp" %>

<div class="content">

    <!-- Back button -->
    <div class="d-flex align-items-center mx-2 mb-2 gap-3">
        <a id="btnBack"
           href="${pageContext.request.contextPath}/monthlyplanner"
           class="btn btn-emerald-outline d-flex align-items-center gap-2 fw-semibold shadow-sm text-decoration-none">
            <i class="fa-solid fa-arrow-left"></i> Back
        </a>
    </div>

    <div class="content_container container-fluid">
        <div class="content_table pb-4">

            <div class="row text-center pt-3">
                <h2><b id="pageTitle">Machine Allocation</b></h2>
            </div>

            <!-- Plan selector -->
            <div class="row mb-2 mx-0 px-4">
                <div class="col d-flex align-items-center gap-2">
                    <label for="planSelect" class="fw-semibold" style="color:#55635d;">Plan:</label>
                    <select class="pl-plan" id="planSelect"><option value="">Select a monthly plan</option></select>
                </div>
            </div>

            <!-- Toolbar -->
            <div class="row mb-3 mx-0 px-4">
                <div class="col d-flex justify-content-end align-items-end gap-2">
                    <button class="btn btn-sm btn-dark" id="exportExcel">
                        <i class="fa-solid fa-file-export"></i> Export
                    </button>
                    <button class="btn btn-sm btn-dark" id="validateAllocation">
                        <i class="fa-solid fa-check"></i> Validate
                    </button>
                    <button class="btn btn-sm btn-primary" id="saveAllocation">
                        <i class="fa-solid fa-floppy-disk"></i> Save Final
                    </button>
                </div>
            </div>

            <!-- Reconciliation banner (mirrors Excel 3.Allocation row 38 / AB50 check) -->
            <div id="reconBanner" class="recon-banner recon-ok" style="display:none;"></div>

            <!-- Summary cards -->
            <div class="row mb-3 mx-0 px-4 g-2">
                <div class="col-md">
                    <div class="allocation-summary-card">
                        <div class="allocation-summary-label">Registered Items</div>
                        <div class="allocation-summary-value" id="totalItems">0</div>
                    </div>
                </div>
                <div class="col-md">
                    <div class="allocation-summary-card">
                        <div class="allocation-summary-label">Item Groups</div>
                        <div class="allocation-summary-value" id="totalGroups">0</div>
                    </div>
                </div>
                <div class="col-md">
                    <div class="allocation-summary-card">
                        <div class="allocation-summary-label">Total MC/Day</div>
                        <div class="allocation-summary-value" id="totalMcday">0.00</div>
                    </div>
                </div>
                <div class="col-md">
                    <div class="allocation-summary-card">
                        <div class="allocation-summary-label">FIX Used / Limit</div>
                        <div class="allocation-summary-value" id="fixUsed">0 / 30</div>
                    </div>
                </div>
                <div class="col-md">
                    <div class="allocation-summary-card">
                        <div class="allocation-summary-label">Machines Used</div>
                        <div class="allocation-summary-value" id="machinesUsed">0</div>
                    </div>
                </div>
                <div class="col-md">
                    <div class="allocation-summary-card">
                        <div class="allocation-summary-label">Record Mode</div>
                        <div class="allocation-summary-value" id="allocationMode">NEW</div>
                        <div class="allocation-record-id" id="allocationRecordId">No saved record</div>
                    </div>
                </div>
            </div>

            <!-- Allocation table -->
            <div class="table-responsive px-4">
                <table id="allocation_table" class="table hover w-100 text-nowrap allocation-table">
                    <thead>
                        <tr>
                            <th>ITEM</th>
                            <th>MC REQT<br>mc/day</th>
                            <th>Groupings</th>
                            <th>FIX</th>
                            <th>FRACTION 1</th>
                            <th>Fix Machines</th>
                            <th>FRACTION 1 Machine</th>
                            <th>FRACTION 1 REQT</th>
                            <th>GROUP</th>
                            <th>STATUS</th>
                        </tr>
                    </thead>
                    <tbody></tbody>
                </table>
            </div>

        </div>
    </div>
</div>

<script>

    /* ─────────────────────────────────────────────────────────────
       Plan context
       ───────────────────────────────────────────────────────────── */

    var basePath    = '${pageContext.request.contextPath}';
    var preselect   = '${preselectPlanId}';
    var planId      = "";
    var planMonth   = "";
    var planYear    = "";
    var machineCode = "";
    var monthName   = "";
    var PLAN_MONTHS = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];

    var MAX_ITEMS_PER_COMBINATION = 3;
    var GLOBAL_MAX_FIX_MACHINES   = 30;

    // Refactored machine usage values — no longer magic numbers
    var MACHINE_USAGE_AVAILABLE    = "AVAILABLE";
    var MACHINE_USAGE_DISQUALIFIED = "DISQUALIFIED";

    var allocationTable = null;
    var currentSavedAllocationId = "";
    var currentSavedAllocation   = null;

    /* ─────────────────────────────────────────────────────────────
       Helpers
       ───────────────────────────────────────────────────────────── */

    function showLoadingScreen() {
        Swal.fire({
            title: '<span style="color:#28282B;font-family:FSEmericLight,Helvetica;font-size:25px;font-weight:600;">Please wait...</span>',
            html:  '<div class="spinner"></div><br><i style="color:#28282B;font-family:FSEmericLight,Helvetica;font-size:20px;font-weight:600;">Loading...</i>',
            allowOutsideClick: false,
            showConfirmButton:  false
        });
    }

    function round2(v)         { return Math.round((toNum(v) + Number.EPSILON) * 100) / 100; }
    function toNum(v)          { if (v === null || v === undefined || v === "") { return 0; } var n = Number(v); return isNaN(n) ? 0 : n; }
    function fmtNum(v)         { if (v === null || v === undefined || v === "") { return ""; } return toNum(v).toFixed(2); }
    function isBlank(v)        { return !v || String(v).trim() === ""; }
    function safe(v)           { return v == null ? "" : v; }
    function normalizeKey(v)   { return String(v || "").trim().toUpperCase(); }
    function normalizeGroup(v) { return String(v || "").trim().toUpperCase(); }
    function normMaterial(v)   { return String(v || "").trim().toUpperCase(); }

    // Builds a human-readable label for a group row — used in validation error
    // messages instead of the raw mergeKey (which is an internal grouping ID
    // like "A__NO_MATERIAL__21HKV106__REQ5__F01|F02|...__BATCH__1").
    // Example output: "Group A (Material 21HKV106) — Items: ITEM1, ITEM2"
    function buildGroupLabel(row) {
        var parts = [];

        var gc = normalizeGroup(row.groupCode);
        if (gc && gc !== "NO_GROUP") { parts.push("Group " + gc); }

        var mat = normMaterial(row.material);
        if (mat && mat !== "NO_MATERIAL") { parts.push("Material " + mat); }

        var label = parts.length > 0 ? parts.join(" — ") : "Group " + (toNum(row.displayIndex) + 1);

        var itemNames = $.map(row.items || [], function(itm) { return itm.itemName || ""; })
                          .filter(Boolean);

        if (itemNames.length > 0) {
            label += " (Items: " + itemNames.join(", ") + ")";
        }

        return label;
    }

    function escapeHtml(v) {
        return String(v).replace(/&/g,"&amp;").replace(/</g,"&lt;")
            .replace(/>/g,"&gt;").replace(/"/g,"&quot;").replace(/'/g,"&#039;");
    }
    function escAttr(v) { return escapeHtml(v); }

    function isMachineAvailable(machine) {
        var usage = String(machine.machineUsage || "").trim();
        // Refactored values: "AVAILABLE" or "DISQUALIFIED"
        if (usage === MACHINE_USAGE_DISQUALIFIED) { return false; }
        if (usage === "")                         { return true;  }
        return usage === MACHINE_USAGE_AVAILABLE;
    }

    function getMachineKey(machine) {
        // machineId not meaningful for display — use machineName (refactored field)
        return String(machine.machineName || machine.machine || "").trim();
    }

    function getRequiredMachineCount(totalMcday) {
        var v = toNum(totalMcday);
        if (v <= 0) { return 0; }
        var whole    = Math.floor(v);
        var fraction = round2(v - whole);
        return fraction > 0 ? whole + 1 : whole;
    }

    function buildItemNameKeys(itemName) {
        var firstWord = String(itemName || "").trim().split(/\s+/)[0].toUpperCase();
        var itemCode  = firstWord.substring(0, 11);
        return {
            original:   itemName,
            firstWord:  firstWord,
            itemCode:   itemCode,
            first3:     itemCode.substring(0, 3),
            afterFirst3: itemCode.length > 3 ? itemCode.substring(3) : itemCode
        };
    }

    /* ─────────────────────────────────────────────────────────────
       Data loading
       ───────────────────────────────────────────────────────────── */

    var PLAN_CACHE = [];

    function planMonthParts(pm) {
        if (!pm) { return null; }
        var y, m;
        if (typeof pm === "object") {
            var src = pm.date ? pm.date : pm;
            y = src.year; m = (src.monthValue != null) ? src.monthValue : src.month;
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
                    var parts = planMonthParts(pl.planMonth);
                    var label = (parts ? (PLAN_MONTHS[parts.month - 1] + " " + parts.year) : "")
                              + " \u2014 " + (pl.machineCode || "");
                    sel.append('<option value="' + pl.planId + '">' + label + '</option>');
                });
                if (preselect) { sel.val(preselect).trigger("change"); }
            },
            error: function (xhr) {
                Swal.fire({ text: xhr.responseText || "Could not load plans.", icon: "error" });
            }
        });
    }

    function setPlanFromSelection(value) {
        planId = value || "";
        planMonth = ""; planYear = ""; machineCode = ""; monthName = "";
        if (!planId) { $("#pageTitle").html("Machine Allocation"); return; }
        var plan = null;
        for (var i = 0; i < PLAN_CACHE.length; i++) {
            if (String(PLAN_CACHE[i].planId) === String(planId)) { plan = PLAN_CACHE[i]; break; }
        }
        if (plan) {
            var parts = planMonthParts(plan.planMonth);
            if (parts) { planMonth = parts.month; planYear = parts.year; monthName = PLAN_MONTHS[parts.month - 1]; }
            machineCode = plan.machineCode || "";
        }
        $("#pageTitle").html("Machine Allocation &mdash; " + monthName + " " + planYear + buildMachineTypeBadge(machineCode));
    }

    function loadAllocation() {
        showLoadingScreen();

        // 1. Saggered items with qualified machines — scoped to this plan only
        var itemReq = $.ajax({
            type: "GET", url: basePath + "/item/l",
            dataType: "json"
        });

        // 2. MC requirements per item — from precondition computed results
        var mcReqtReq = $.ajax({
            type: "GET", url: basePath + "/precondition/compute",
            data: { planid: planId }, dataType: "json"
        });

        // 3. Existing saved allocation
        var savedReq = $.ajax({
            type: "GET", url: basePath + "/machineallocation/l",
            data: { planid: planId }, dataType: "json"
        });

        $.when(itemReq, mcReqtReq, savedReq)
            .done(function(itemRes, mcReqtRes, savedRes) {
                var rawItems        = itemRes[0]   || [];
                var preconditions   = mcReqtRes[0] || [];
                var savedAllocation = savedRes[0];

                // Build item reference map from /item/saggered/l (machineName is the field)
        // Only items present in the Saggering Plan are included
                var referenceMap = buildReferenceMap(rawItems);

                // Build mc/day map from precondition results
                var mcMap = buildMcMap(preconditions);

                // Merge: items from precondition that have mc requirements
                var monthlyItems = buildMonthlyItems(mcMap, referenceMap);

                var result = buildAllocationRows(monthlyItems);

                if (savedAllocation && savedAllocation.allocationId > 0
                        && savedAllocation.groups && savedAllocation.groups.length > 0) {
                    applySavedAllocation(result.rows, savedAllocation);
                    setSavedMode(savedAllocation);
                } else {
                    clearSavedMode();
                }

                allocationTable.clear().rows.add(result.rows).draw();
                updateSummaryCards(monthlyItems, result.rows);
                Swal.close();

                if (savedAllocation && savedAllocation.allocationId > 0) {
                    Swal.fire({
                        text: "Saved allocation loaded. You can update and re-save.",
                        icon: "info", timer: 1800, showConfirmButton: false
                    });
                    return;
                }

                if (result.warnings.length > 0) {
                    Swal.fire({
                        text: "Generated with " + result.warnings.length + " warning(s). Check STATUS column.",
                        icon: "warning"
                    });
                }
            })
            .fail(function(xhr) {
                Swal.close();
                Swal.fire({ text: xhr.responseText || "Error loading allocation data.", icon: "error" });
            });
    }

    // Build reference map: itemName → { groupCode, materialCode, machines[] }
    // Reads machineName (refactored field, not machine.machine)
    function buildReferenceMap(rawItems) {
        var map = new Map();

        $.each(rawItems || [], function(i, raw) {
            var itemName  = String(raw.itemName || "").trim();
            var groupCode = normalizeGroup(raw.groupCode || "");
            var material  = normMaterial(raw.materialCode || "");

            // Build qualified machine list — filter to AVAILABLE only
            var machines = [];
            $.each(raw.machines || [], function(j, m) {
                if (isMachineAvailable(m)) {
                    machines.push({
                        machineName:  m.machineName || "",
                        machineUsage: m.machineUsage || MACHINE_USAGE_AVAILABLE,
                        isAvailable:  true
                    });
                }
            });

            if (!itemName) { return; }

            var ref = { itemName: itemName, groupCode: groupCode, material: material, machines: machines };
            map.set(normalizeKey(itemName), ref);
        });

        return map;
    }

    // Build mc/day map from precondition list: itemName → mcReqtMcPerMos
    function buildMcMap(preconditions) {
        var map = {};
        $.each(preconditions || [], function(i, pr) {
            var itemName = String(pr.itemName || "").trim();
            if (itemName) {
                map[normalizeKey(itemName)] = toNum(pr.mcReqtMcPerMos);
            }
        });
        return map;
    }

    // Merge precondition mc values with item master machine data
    function buildMonthlyItems(mcMap, referenceMap) {
        var items = [];

        $.each(Object.keys(mcMap), function(i, key) {
            var mcday = mcMap[key];
            var ref   = referenceMap.get(key);

            items.push({
                itemName:     ref ? ref.itemName : key,
                groupCode:    ref ? ref.groupCode : "",
                material:     ref ? ref.material  : "",
                mcday:        mcday,
                hasMcReqt:    true,
                hasReference: !!ref,
                machines:     ref ? ref.machines : [],
                itemKeys:     buildItemNameKeys(ref ? ref.itemName : key)
            });
        });

        return items;
    }

    /* ─────────────────────────────────────────────────────────────
       Allocation algorithm — unchanged from original, adapted to
       new field names (machineName instead of machine)
       ───────────────────────────────────────────────────────────── */

    function buildAllocationRows(items) {
        var warnings  = [];
        var rows      = [];

        var machineState  = buildMachineState(items);
        var groupedItems  = groupItemsForAllocation(items);
        var allocGroups   = buildAllocationGroupObjects(groupedItems, machineState);

        calcMachineQualificationCount(allocGroups, machineState);

        var optimized = optimizeFixAllocationGroups(allocGroups, machineState);

        $.each(optimized, function(idx, group) {
            $.each(group.warnings, function(wi, w) { warnings.push(w); });

            $.each(group.items, function(ii, item) {
                rows.push({
                    item:               item.itemName,
                    mcday:              toNum(item.mcday),
                    grouping:           toNum(group.totalMcday),
                    fixRequirement:     toNum(group.fixRequirement),
                    fraction1Requirement: toNum(group.fraction1Requirement),
                    fixMachineKeys:     group.fixMachineKeys.slice(),
                    fraction1MachineKey: group.fractionMachines.length > 0 ? (group.fractionMachines[0].machine || "") : "",
                    fraction1Reqt:      toNum(group.fraction1Requirement),
                    fractionMachines:   group.fractionMachines ? group.fractionMachines.slice() : [],
                    groupCode:          group.groupCode,
                    material:           group.material,
                    status:             group.status,
                    mergeKey:           group.mergeKey,
                    sectionStart:       false,
                    commonMachineOptions: group.commonMachineOptions,
                    commonMachineKeys:    group.commonMachineKeys
                });
            });
        });

        markGroupSectionStarts(rows);
        return { rows: rows, warnings: warnings };
    }

    function buildMachineState(items) {
        var state = new Map();
        $.each(items, function(ii, item) {
            $.each(item.machines, function(mi, machine) {
                if (!machine.isAvailable) { return; }
                var key = getMachineKey(machine);
                if (!key) { return; }
                if (!state.has(key)) {
                    state.set(key, {
                        key: key, machine: machine.machineName,
                        capacity: 1, remaining: 1, usedLoad: 0, fractionLoad: 0,
                        usedAsFix: false, qualifiedGroupCount: 0, isAvailable: true
                    });
                }
            });
        });
        return state;
    }

    function groupItemsForAllocation(items) {
        var buckets = {};

        var sorted = items.slice().sort(function(a, b) {
            var gc = compareGroupCode(a.groupCode, b.groupCode);
            if (gc !== 0) { return gc; }
            var mc = normMaterial(a.material).localeCompare(normMaterial(b.material));
            if (mc !== 0) { return mc; }
            return a.itemKeys.itemCode.localeCompare(b.itemKeys.itemCode);
        });

        $.each(sorted, function(i, item) {
            var gc      = normalizeGroup(item.groupCode);
            var mat     = normMaterial(item.material) || "NO_MATERIAL";
            var bucketKey = gc + "__" + mat + "__" + item.itemKeys.afterFirst3;
            if (!buckets[bucketKey]) { buckets[bucketKey] = []; }
            buckets[bucketKey].push({ itemData: item, itemKeys: item.itemKeys, groupCode: gc, material: mat });
        });

        var finalGroups = {};

        Object.keys(buckets).sort(sortBucketKeysByGroup).forEach(function(bk) {
            var batchItems = buckets[bk];
            var batches    = createItemCombinationBatches(batchItems);
            $.each(batches, function(bi, batch) {
                var batchItemData    = $.map(batch, function(e) { return e.itemData; });
                var commonMachineKeys = getCommonMachineKeys(batchItemData);
                var totalMcday       = round2(batch.reduce(function(s, e) { return s + toNum(e.itemData.mcday); }, 0));
                var requiredMachineCount = getRequiredMachineCount(totalMcday);
                var commonPart       = commonMachineKeys.length > 0 ? commonMachineKeys.join("|") : "NO_COMMON";
                var mergeKey         = [batch[0].groupCode || "NO_GROUP", batch[0].material || "NO_MATERIAL",
                                        batch[0].itemKeys.afterFirst3, "REQ" + requiredMachineCount,
                                        commonPart, "BATCH", bi + 1].join("__");
                finalGroups[mergeKey] = batchItemData;
            });
        });

        return finalGroups;
    }

    function buildAllocationGroupObjects(groupedItems, machineState) {
        var groups = [];
        $.each(groupedItems, function(mergeKey, groupItems) {
            var idx              = groups.length;
            var commonMachineKeys = getCommonMachineKeys(groupItems);
            var commonMachineOptions = buildMachineOptions(commonMachineKeys, machineState);
            var totalMcday       = round2(groupItems.reduce(function(s, i) { return s + toNum(i.mcday); }, 0));
            // fixRequirement = sum of Math.floor(mcday) per item, NOT Math.floor(sum).
            // Using floor(sum) gives wrong results when two fraction-only items are
            // grouped together — e.g. mcday=0.654 + mcday=0.5 = 1.154 → floor=1,
            // which incorrectly assigns a Fix machine to both pure-fraction items.
            // The correct approach: floor per item, then sum.
            //   mcday=0.654 → floor=0, mcday=0.5 → floor=0, sum=0 (no Fix needed) ✓
            var fixReq  = round2(groupItems.reduce(function(s, i) { return s + Math.floor(toNum(i.mcday)); }, 0));
            var frac1Req = round2(totalMcday - fixReq);
            var noRef  = $.grep(groupItems, function(i) { return !i.hasReference; });
            var noMach = $.grep(groupItems, function(i) { return !i.machines || i.machines.length === 0; });
            groups.push({
                displayIndex: idx, mergeKey: mergeKey, items: groupItems,
                groupCode: normalizeGroup(groupItems[0].groupCode), material: normMaterial(groupItems[0].material),
                totalMcday: totalMcday, fixRequirement: fixReq, fraction1Requirement: frac1Req,
                requiredMachineCount: getRequiredMachineCount(totalMcday),
                commonMachineKeys: commonMachineKeys, commonMachineOptions: commonMachineOptions,
                noReferenceItems: noRef, noMachineItems: noMach,
                selectedForFix: false, fixMachineKeys: [], fractionMachineKeys: [],
                fractionMachines: [], warnings: [], status: "OK"
            });
        });
        return groups;
    }

    function calcMachineQualificationCount(groups, machineState) {
        $.each(groups, function(gi, group) {
            $.each(group.commonMachineKeys, function(i, key) {
                var m = machineState.get(key);
                if (m) { m.qualifiedGroupCount = toNum(m.qualifiedGroupCount) + 1; }
            });
        });
    }

    function optimizeFixAllocationGroups(groups, machineState) {
        var selectedFixKeys = chooseGroupsForMaxFix(groups, GLOBAL_MAX_FIX_MACHINES);
        var order = groups.slice().sort(function(a, b) {
            var as = selectedFixKeys.has(a.mergeKey) ? 0 : 1;
            var bs = selectedFixKeys.has(b.mergeKey) ? 0 : 1;
            if (as !== bs) { return as - bs; }
            if (a.commonMachineKeys.length !== b.commonMachineKeys.length) { return a.commonMachineKeys.length - b.commonMachineKeys.length; }
            if (b.requiredMachineCount !== a.requiredMachineCount) { return b.requiredMachineCount - a.requiredMachineCount; }
            if (b.totalMcday !== a.totalMcday) { return b.totalMcday - a.totalMcday; }
            return a.displayIndex - b.displayIndex;
        });
        var globalFixUsed = 0;
        $.each(order, function(i, group) {
            group.selectedForFix = selectedFixKeys.has(group.mergeKey) || group.fixRequirement === 0;
            var fr = allocateFixMachines(group, machineState, group.selectedForFix, globalFixUsed);
            group.fixMachineKeys = fr.fixMachineKeys;
            globalFixUsed += group.fixMachineKeys.length;
            $.each(fr.warnings, function(wi, w) { group.warnings.push(w); });
        });
        $.each(order, function(i, group) {
            var fr = allocateFractionMachine(group, machineState);
            group.fractionMachineKeys = fr.fractionMachineKeys;
            // Convert auto-assigned key to fractionMachines array with full fraction share
            group.fractionMachines = [];
            $.each(fr.fractionMachineKeys, function(i, k) {
                if (k) { group.fractionMachines.push({ machine: k, share: toNum(group.fraction1Requirement) }); }
            });
            $.each(fr.warnings, function(wi, w) { group.warnings.push(w); });
        });
        $.each(groups, function(i, group) { group.status = buildGroupStatus(group); });
        return groups.sort(function(a, b) { return a.displayIndex - b.displayIndex; });
    }

    function allocateFixMachines(group, machineState, selectedForFix, currentGlobalFixUsed) {
        var warnings = [], fixMachineKeys = [];
        if (!selectedForFix || group.fixRequirement <= 0) { return { fixMachineKeys: fixMachineKeys, warnings: warnings }; }
        if (GLOBAL_MAX_FIX_MACHINES - currentGlobalFixUsed < group.fixRequirement) {
            warnings.push("FIX LIMIT");
            return { fixMachineKeys: fixMachineKeys, warnings: warnings };
        }
        if (group.commonMachineKeys.length < group.requiredMachineCount) {
            warnings.push("COMMON AVAILABLE MACHINE " + group.commonMachineKeys.length + "/" + group.requiredMachineCount);
            return { fixMachineKeys: fixMachineKeys, warnings: warnings };
        }
        var candidates = $.grep($.map(group.commonMachineKeys, function(k) { return machineState.get(k); }),
            function(m) { return m && m.isAvailable && !m.usedAsFix && toNum(m.remaining) >= 1; });
        candidates.sort(function(a, b) {
            var aq = toNum(a.qualifiedGroupCount), bq = toNum(b.qualifiedGroupCount);
            if (aq !== bq) { return aq - bq; }
            return String(a.machine).localeCompare(String(b.machine));
        });
        var fixNeeded = toNum(group.fixRequirement);
        for (var i = 0; i < candidates.length && fixNeeded > 0; i++) {
            var m = candidates[i];
            m.usedAsFix = true; m.usedLoad = 1; m.fractionLoad = 0; m.remaining = 0;
            fixMachineKeys.push(m.key); fixNeeded--;
        }
        if (fixNeeded > 0) { warnings.push("UNALLOCATED FIX " + fixNeeded); }
        return { fixMachineKeys: fixMachineKeys, warnings: warnings };
    }

    function allocateFractionMachine(group, machineState) {
        var warnings = [], fractionMachineKeys = [];
        if (group.fraction1Requirement <= 0) { return { fractionMachineKeys: fractionMachineKeys, warnings: warnings }; }
        if (group.commonMachineKeys.length < group.requiredMachineCount) {
            warnings.push("COMMON AVAILABLE MACHINE " + group.commonMachineKeys.length + "/" + group.requiredMachineCount);
            return { fractionMachineKeys: fractionMachineKeys, warnings: warnings };
        }
        var fr = toNum(group.fraction1Requirement);
        var candidates = $.grep($.map(group.commonMachineKeys, function(k) { return machineState.get(k); }),
            function(m) { return m && m.isAvailable && !m.usedAsFix && toNum(m.remaining) >= fr; });
        candidates.sort(function(a, b) {
            var af = toNum(a.fractionLoad), bf = toNum(b.fractionLoad);
            if (af !== bf) { return bf - af; }
            var aq = toNum(a.qualifiedGroupCount), bq = toNum(b.qualifiedGroupCount);
            if (aq !== bq) { return aq - bq; }
            return String(a.machine).localeCompare(String(b.machine));
        });
        var m = candidates[0];
        if (m) {
            m.fractionLoad = round2(toNum(m.fractionLoad) + fr);
            m.usedLoad     = round2(toNum(m.usedLoad) + fr);
            m.remaining    = round2(toNum(m.capacity || 1) - toNum(m.usedLoad));
            fractionMachineKeys.push(m.key);
        } else {
            warnings.push("UNALLOCATED FRACTION " + fmtNum(fr));
        }
        return { fractionMachineKeys: fractionMachineKeys, warnings: warnings };
    }

    function buildGroupStatus(group) {
        var s = [];
        if (!group.selectedForFix && group.fixRequirement > 0)         { s.push("FIX LIMIT"); }
        if (group.noReferenceItems.length > 0)                         { s.push("NO ITEM/L REF: " + $.map(group.noReferenceItems, function(i) { return i.itemName; }).join(", ")); }
        if (group.noMachineItems.length > 0)                           { s.push("NO AVAILABLE QUALIFIED MACHINE: " + $.map(group.noMachineItems, function(i) { return i.itemName; }).join(", ")); }
        if (group.commonMachineKeys.length < group.requiredMachineCount) { s.push("COMMON AVAILABLE MACHINE " + group.commonMachineKeys.length + "/" + group.requiredMachineCount); }
        $.each(group.warnings, function(i, w) { s.push(w); });
        return s.length > 0 ? s.join(" | ") : "OK";
    }

    function chooseGroupsForMaxFix(groups, maxFix) {
        var candidates = $.grep(groups, function(g) {
            return g.fixRequirement > 0 && g.fixRequirement <= maxFix && g.commonMachineKeys.length >= g.requiredMachineCount;
        });
        var dp = [];
        for (var i = 0; i <= maxFix; i++) { dp[i] = { fix: 0, mcday: 0, selected: [] }; }
        $.each(candidates, function(ci, group) {
            var w = toNum(group.fixRequirement);
            for (var cap = maxFix; cap >= w; cap--) {
                var prev = dp[cap - w];
                var cFix = prev.fix + w, cMcd = prev.mcday + group.totalMcday, cur = dp[cap];
                if (cFix > cur.fix || (cFix === cur.fix && cMcd > cur.mcday)) {
                    dp[cap] = { fix: cFix, mcday: cMcd, selected: prev.selected.concat([group.mergeKey]) };
                }
            }
        });
        var best = dp[0];
        for (var j = 1; j <= maxFix; j++) {
            if (dp[j].fix > best.fix || (dp[j].fix === best.fix && dp[j].mcday > best.mcday)) { best = dp[j]; }
        }
        return new Set(best.selected);
    }

    function getCommonMachineKeys(items) {
        if (!items || items.length === 0) { return []; }
        var commonSet = null;
        $.each(items, function(i, item) {
            var itemSet = getItemMachineKeySet(item);
            commonSet = commonSet === null ? itemSet : new Set(Array.from(commonSet).filter(function(k) { return itemSet.has(k); }));
        });
        return !commonSet ? [] : Array.from(commonSet).sort();
    }

    function getItemMachineKeySet(item) {
        var set = new Set();
        $.each(item.machines || [], function(i, m) {
            if (m.isAvailable) { var k = getMachineKey(m); if (k) { set.add(k); } }
        });
        return set;
    }

    function buildMachineOptions(machineKeys, machineState) {
        return $.map(machineKeys, function(key) {
            var m = machineState.get(key);
            return (m && m.isAvailable) ? { key: key, name: m.machine || key, capacity: m.capacity || 1 } : null;
        });
    }

    function compareGroupCode(a, b) {
        var order = { "A": 1, "B": 2 };
        var ao = order[normalizeGroup(a)] || 99, bo = order[normalizeGroup(b)] || 99;
        if (ao !== bo) { return ao - bo; }
        return normalizeGroup(a).localeCompare(normalizeGroup(b));
    }

    function sortBucketKeysByGroup(a, b) {
        var ga = a.split("__")[0], gb = b.split("__")[0];
        var gc = compareGroupCode(ga, gb);
        return gc !== 0 ? gc : a.localeCompare(b);
    }

    function createItemCombinationBatches(bucketItems) {
        var prefixPriority = { "LRM": 1, "LCM": 2, "LRT": 3, "LCJ": 4 };
        function compareItems(a, b) {
            var ap = prefixPriority[a.itemKeys.first3] || 99, bp = prefixPriority[b.itemKeys.first3] || 99;
            if (ap !== bp) { return ap - bp; }
            return a.itemKeys.itemCode.localeCompare(b.itemKeys.itemCode);
        }
        var unassigned = bucketItems.slice().sort(compareItems);
        var batches = [];
        while (unassigned.length > 0) {
            var base  = unassigned.shift();
            var batch = [base];
            var usedFirstWords = new Set([base.itemKeys.firstWord]);
            for (var i = unassigned.length - 1; i >= 0; i--) {
                var cand = unassigned[i];
                if (batch.length >= MAX_ITEMS_PER_COMBINATION) { break; }
                if (cand.itemKeys.afterFirst3 !== base.itemKeys.afterFirst3) { continue; }
                if (usedFirstWords.has(cand.itemKeys.firstWord)) { continue; }
                if (!canCandidateJoinBatch(batch, cand)) { continue; }
                batch.push(cand);
                usedFirstWords.add(cand.itemKeys.firstWord);
                unassigned.splice(i, 1);
            }
            batch.sort(compareItems);
            batches.push(batch);
        }
        return batches;
    }

    function canCandidateJoinBatch(batch, candidate) {
        if (batch.length >= MAX_ITEMS_PER_COMBINATION) { return false; }
        var base = batch[0];
        if (normalizeGroup(base.groupCode) !== normalizeGroup(candidate.groupCode)) { return false; }
        if (normMaterial(base.material) !== normMaterial(candidate.material)) { return false; }
        if (base.itemKeys.afterFirst3 !== candidate.itemKeys.afterFirst3) { return false; }
        var proposed = batch.concat([candidate]);
        var items    = $.map(proposed, function(e) { return e.itemData; });
        var ck       = getCommonMachineKeys(items);
        var total    = round2(proposed.reduce(function(s, e) { return s + toNum(e.itemData.mcday); }, 0));
        return ck.length >= getRequiredMachineCount(total);
    }

    function markGroupSectionStarts(rows) {
        var prevGC = null;
        $.each(rows, function(i, row) {
            row.sectionStart = i > 0 && row.groupCode !== prevGC;
            prevGC = row.groupCode;
        });
    }

    /* ─────────────────────────────────────────────────────────────
       Saved allocation restore
       ───────────────────────────────────────────────────────────── */

    function applySavedAllocation(rows, saved) {
        var groupMap = {}, signatureMap = {};
        $.each(rows, function(i, row) {
            if (!groupMap[row.mergeKey]) { groupMap[row.mergeKey] = []; }
            groupMap[row.mergeKey].push(row);
        });
        $.each(groupMap, function(mk, gRows) {
            var sig = $.map(gRows, function(r) { return normalizeKey(r.item); }).sort().join("|");
            if (!signatureMap[sig]) { signatureMap[sig] = mk; }
        });
        $.each(saved.groups || [], function(i, sg) {
            var targetMk = (sg.mergeKey && groupMap[sg.mergeKey]) ? sg.mergeKey : "";
            if (!targetMk) {
                // Try to match by item signature
                var sig = $.map(sg.items || [], function(itm) { return normalizeKey(itm.itemName || itm.item || ""); })
                    .filter(Boolean).sort().join("|");
                if (sig && signatureMap[sig]) { targetMk = signatureMap[sig]; }
            }
            if (!targetMk || !groupMap[targetMk]) { return; }

            // Restore machine assignments from saved group
            var fixKeys      = [];
            var fracMachines = [];
            $.each(sg.machines || [], function(j, m) {
                if (m.machineRole === "FIX")      { fixKeys.push(m.machineName || ""); }
                if (m.machineRole === "FRACTION1") { fracMachines.push({ machine: m.machineName || "", share: toNum(m.requirementValue) }); }
            });
            // Prefer fractionMachines convenience array from DAO if present
            if (sg.fractionMachines && sg.fractionMachines.length > 0) {
                fracMachines = sg.fractionMachines.slice();
            }
            if (sg.fixMachineKeys && sg.fixMachineKeys.length > 0) { fixKeys = sg.fixMachineKeys.slice(); }

            $.each(groupMap[targetMk], function(j, row) {
                row.fixMachineKeys      = fixKeys.slice();
                row.fraction1MachineKey = fracMachines.length > 0 ? (fracMachines[0].machine || "") : "";
                row.fractionMachines    = fracMachines.slice();
                if (sg.status)          { row.status = sg.status; }
            });
        });
    }

    function setSavedMode(saved) {
        currentSavedAllocation   = saved;
        currentSavedAllocationId = saved.allocationId || "";
        $("#allocationMode").text("UPDATE");
        $("#allocationRecordId").text("ID: " + currentSavedAllocationId);
        $("#saveAllocation").html('<i class="fa-solid fa-floppy-disk"></i> Update Final');
    }

    function clearSavedMode() {
        currentSavedAllocation   = null;
        currentSavedAllocationId = "";
        $("#allocationMode").text("NEW");
        $("#allocationRecordId").text("No saved record");
        $("#saveAllocation").html('<i class="fa-solid fa-floppy-disk"></i> Save Final');
    }

    /* ─────────────────────────────────────────────────────────────
       Table render helpers
       ───────────────────────────────────────────────────────────── */

    function renderEditableMachineSelects(row, machineType) {
        var options    = row.commonMachineOptions || [];
        if (options.length === 0) { return '<span class="empty-value">-</span>'; }

        // FIX branch — unchanged
        if (machineType === "fix") {
            var fixValues = $.isArray(row.fixMachineKeys) ? row.fixMachineKeys.slice() : [];
            var selectCount = toNum(row.fixRequirement);
            if (selectCount <= 0) { return '<span class="empty-value">-</span>'; }

            var html = "";
            for (var i = 0; i < selectCount; i++) {
                var selected = fixValues[i] || "";
                html += '<select class="form-select form-select-sm machine-edit-select" '
                      + 'data-merge-key="' + escAttr(row.mergeKey) + '" '
                      + 'data-machine-type="fix" '
                      + 'data-index="' + i + '">'
                      + '<option value="">-</option>';
                var foundSelected = false;
                $.each(options, function(oi, opt) {
                    var sel = opt.key === selected ? "selected" : "";
                    if (opt.key === selected) { foundSelected = true; }
                    html += '<option value="' + escAttr(opt.key) + '" ' + sel + '>' + escapeHtml(opt.name) + '</option>';
                });
                if (selected && !foundSelected) {
                    html += '<option value="' + escAttr(selected) + '" selected>' + escapeHtml(selected + " - not qualified") + '</option>';
                }
                html += '</select>';
            }
            return html;
        }

        // FRACTION branch — multi-machine split
        return renderFractionMachines(row);
    }

    // Renders fraction assignments as a vertical list of machine+share pairs.
    // Each pair has: [machine select] [share input] [✕ remove button]
    // Below the list: [+ Add] button (if total share < fraction1Requirement)
    // and a running total label.
    function renderFractionMachines(row) {
        var options  = row.commonMachineOptions || [];
        var totalReq = toNum(row.fraction1Requirement);

        if (totalReq <= 0) { return '<span class="empty-value">-</span>'; }
        if (options.length === 0) { return '<span class="empty-value">No qualified machines</span>'; }

        var entries = $.isArray(row.fractionMachines) ? row.fractionMachines : [];
        var usedShare = round2(entries.reduce(function(s, e) { return s + toNum(e.share); }, 0));
        var remaining = round2(totalReq - usedShare);
        var mk        = escAttr(row.mergeKey);

        var html = '<div class="frac-container" data-merge-key="' + mk + '">';

        $.each(entries, function(idx, entry) {
            var machineKey = entry.machine || "";
            var shareVal   = toNum(entry.share);

            html += '<div class="frac-entry">';

            // Machine select
            html += '<select class="form-select form-select-sm frac-machine-select" '
                  + 'data-merge-key="' + mk + '" data-frac-index="' + idx + '">'
                  + '<option value="">-</option>';
            var found = false;
            $.each(options, function(oi, opt) {
                var sel = opt.key === machineKey ? "selected" : "";
                if (opt.key === machineKey) { found = true; }
                html += '<option value="' + escAttr(opt.key) + '" ' + sel + '>' + escapeHtml(opt.name) + '</option>';
            });
            if (machineKey && !found) {
                html += '<option value="' + escAttr(machineKey) + '" selected>' + escapeHtml(machineKey + " - not qualified") + '</option>';
            }
            html += '</select>';

            // Share input
            html += '<input type="number" class="form-control form-control-sm frac-share-input" '
                  + 'data-merge-key="' + mk + '" data-frac-index="' + idx + '" '
                  + 'value="' + shareVal + '" min="0" max="1" step="0.01" placeholder="0.00">';

            // Remove button
            html += '<button type="button" class="frac-remove-btn" '
                  + 'data-merge-key="' + mk + '" data-frac-index="' + idx + '">&#10005;</button>';

            html += '</div>';
        });

        // Add button — only if there is remaining share to allocate
        if (remaining > 0.0009) {
            html += '<button type="button" class="frac-add-btn" data-merge-key="' + mk + '">'
                  + '+ Add (' + fmtNum(remaining) + ' rem.)</button>';
        }

        // Running total
        var totalColor = Math.abs(usedShare - totalReq) < 0.001 ? "#065f46" : "#b91c1c";
        html += '<div class="frac-total-label" style="color:' + totalColor + ';">'
              + 'Total: ' + fmtNum(usedShare) + ' / ' + fmtNum(totalReq)
              + '</div>';

        html += '</div>';
        return html;
    }

    /* ─────────────────────────────────────────────────────────────
       Summary cards
       ───────────────────────────────────────────────────────────── */

    // Reconciliation — total machines used should cover the total MC requirement,
    // and every group must be OK. Mirrors the Excel's "SAME / NOT SAME" guard.
    function renderReconciliation(totalMcday, machinesUsed, rows) {
        var banner = $("#reconBanner");
        var required = Math.ceil(round2(totalMcday) - 0.0001);   // whole machines needed
        if (required < 0) { required = 0; }

        // Count groups with a non-OK status (unallocated fix/fraction, missing qual, etc.)
        var seen = {}, badGroups = 0;
        $.each(rows || [], function(i, row) {
            var mk = row.mergeKey;
            if (mk == null || seen[mk]) { return; }
            seen[mk] = true;
            var st = row.status || "OK";
            if (st !== "OK" && String(st).trim() !== "") { badGroups++; }
        });

        banner.removeClass("recon-ok recon-warn recon-bad").show();

        if (machinesUsed < required) {
            var short = required - machinesUsed;
            banner.addClass("recon-bad").html(
                '<i class="fa-solid fa-triangle-exclamation"></i> NOT RECONCILED'
                + ' <span class="recon-detail">&mdash; ' + machinesUsed + ' machine(s) assigned but '
                + required + ' required (' + fmtNum(totalMcday) + ' mc/day). '
                + 'Short by ' + short + ' machine(s). Assign more before saving.</span>');
        } else if (badGroups > 0) {
            banner.addClass("recon-warn").html(
                '<i class="fa-solid fa-circle-exclamation"></i> CHECK WARNINGS'
                + ' <span class="recon-detail">&mdash; ' + machinesUsed + ' / ' + required
                + ' machine(s) covered, but ' + badGroups + ' group(s) have warnings in the STATUS column.</span>');
        } else {
            banner.addClass("recon-ok").html(
                '<i class="fa-solid fa-circle-check"></i> RECONCILED'
                + ' <span class="recon-detail">&mdash; ' + machinesUsed + ' machine(s) cover '
                + fmtNum(totalMcday) + ' mc/day requirement (' + required + ' needed). All groups OK.</span>');
        }
    }

    function updateSummaryCards(items, rows) {
        var groupSet = new Set(), machineSet = new Set(), processedGroups = new Set();
        var totalMcday = 0, fixUsed = 0;
        $.each(items, function(i, item) { totalMcday += toNum(item.mcday); });
        $.each(rows, function(i, row) {
            groupSet.add(row.mergeKey);
            if (!processedGroups.has(row.mergeKey)) {
                processedGroups.add(row.mergeKey);
                fixUsed += $.isArray(row.fixMachineKeys) ? row.fixMachineKeys.filter(Boolean).length : 0;
                $.each(row.fixMachineKeys || [],         function(j, k) { if (k) { machineSet.add(k); } });
                if (row.fraction1MachineKey)              { machineSet.add(row.fraction1MachineKey); }
                $.each(row.fractionMachines || [],        function(j, e) { if (e.machine) { machineSet.add(e.machine); } });
            }
        });
        $("#totalItems").text(items.length);
        $("#totalGroups").text(groupSet.size);
        $("#totalMcday").text(fmtNum(totalMcday));
        $("#machinesUsed").text(machineSet.size);
        $("#fixUsed").text(fixUsed + " / " + GLOBAL_MAX_FIX_MACHINES);
        renderReconciliation(totalMcday, machineSet.size, rows);
    }

    function updateSummaryCardsFromTable() {
        var rows = allocationTable.rows().data().toArray();
        var groupSet = new Set(), machineSet = new Set(), processedItems = new Set(), processedGroups = new Set();
        var totalMcday = 0, fixUsed = 0;
        $.each(rows, function(i, row) {
            var ik = row.mergeKey + "__" + row.item;
            if (!processedItems.has(ik)) { processedItems.add(ik); totalMcday += toNum(row.mcday); }
            groupSet.add(row.mergeKey);
            if (!processedGroups.has(row.mergeKey)) {
                processedGroups.add(row.mergeKey);
                fixUsed += $.isArray(row.fixMachineKeys) ? row.fixMachineKeys.filter(Boolean).length : 0;
                $.each(row.fixMachineKeys || [], function(j, k) { if (k) { machineSet.add(k); } });
                if (row.fraction1MachineKey) { machineSet.add(row.fraction1MachineKey); }
                $.each(row.fractionMachines || [], function(j, e) { if (e.machine) { machineSet.add(e.machine); } });
            }
        });
        $("#totalItems").text(processedItems.size);
        $("#totalGroups").text(groupSet.size);
        $("#totalMcday").text(fmtNum(totalMcday));
        $("#machinesUsed").text(machineSet.size);
        $("#fixUsed").text(fixUsed + " / " + GLOBAL_MAX_FIX_MACHINES);
        renderReconciliation(totalMcday, machineSet.size, rows);
    }

    /* ─────────────────────────────────────────────────────────────
       Validation
       ───────────────────────────────────────────────────────────── */

    function validateFinalAllocation() {
        var errors = [], processedGroups = new Set();
        var totalFix = 0, globalFixMap = {}, globalFixMapLabel = {}, globalFractionMap = {};

        allocationTable.rows().every(function() {
            var row = this.data();
            if (processedGroups.has(row.mergeKey)) { return; }
            processedGroups.add(row.mergeKey);

            var label    = buildGroupLabel(row);
            var fixKeys  = $.isArray(row.fixMachineKeys) ? row.fixMachineKeys.filter(Boolean) : [];
            var fracEntries = $.isArray(row.fractionMachines) ? row.fractionMachines : [];
            var fracKeys = $.map(fracEntries, function(e) { return e.machine || ""; }).filter(Boolean);
            var allKeys  = fixKeys.concat(fracKeys);

            if (fixKeys.length !== toNum(row.fixRequirement)) {
                errors.push(label + ": needs " + row.fixRequirement + " FIX machine(s), but "
                          + fixKeys.length + " selected.");
            }
            if (toNum(row.fraction1Reqt) > 0 && fracKeys.length === 0) {
                errors.push(label + ": a FRACTION machine is required.");
            }
            if (toNum(row.fraction1Reqt) > 0 && fracKeys.length > 0) {
                var totalFracShare = round2(fracEntries.reduce(function(s, e) { return s + toNum(e.share); }, 0));
                if (Math.abs(totalFracShare - toNum(row.fraction1Reqt)) > 0.001) {
                    errors.push(label + ": FRACTION shares must sum to " + fmtNum(toNum(row.fraction1Reqt))
                              + " — current total is " + fmtNum(totalFracShare) + ".");
                }
            }

            // Detect a machine used in more than one role WITHIN this same group —
            // covers both "same FIX machine picked twice" and "same machine used
            // as both FIX and FRACTION" with one clear message per machine.
            var seenInGroup = {};
            $.each(allKeys, function(i, k) {
                if (!k) { return; }
                seenInGroup[k] = (seenInGroup[k] || 0) + 1;
            });
            $.each(seenInGroup, function(k, count) {
                if (count > 1) {
                    var isFixAndFrac = fixKeys.indexOf(k) !== -1 && fracKeys.indexOf(k) !== -1;
                    if (isFixAndFrac) {
                        errors.push(label + ": Machine " + k + " is selected as both FIX and FRACTION — "
                                  + "choose a different machine for one of these roles.");
                    } else {
                        errors.push(label + ": Machine " + k + " is selected more than once — "
                                  + "each FIX slot must use a different machine.");
                    }
                }
            });

            $.each(allKeys, function(i, k) {
                if ($.inArray(k, row.commonMachineKeys) === -1) {
                    errors.push(label + ": Machine " + k + " is not qualified for every item in this group.");
                }
            });
            $.each(fixKeys, function(i, k) {
                totalFix++;
                if (globalFixMap[k] && globalFixMap[k] !== row.mergeKey) {
                    errors.push("Machine " + k + " is used as FIX in both \"" + globalFixMapLabel[globalFixMap[k]]
                              + "\" and \"" + label + "\" — a FIX machine can only be assigned to one group.");
                } else {
                    globalFixMap[k] = row.mergeKey;
                    globalFixMapLabel[row.mergeKey] = label;
                }
            });
            $.each(fracEntries, function(i, e) {
                var k = e.machine || "";
                if (!k) { return; }
                if (!globalFractionMap[k]) { globalFractionMap[k] = 0; }
                globalFractionMap[k] = round2(globalFractionMap[k] + toNum(e.share));
            });
        });

        if (totalFix > GLOBAL_MAX_FIX_MACHINES) {
            errors.push("Too many FIX machines selected overall: " + totalFix
                      + " used, but only " + GLOBAL_MAX_FIX_MACHINES + " are allowed.");
        }
        $.each(globalFractionMap, function(k, load) {
            // Skip — "used as both FIX and FRACTION" within the same group is
            // already reported above with a clearer, per-group message.
            if (round2(load) > 1.0) {
                errors.push("Machine " + k + " is overloaded as FRACTION: total share "
                          + fmtNum(load) + " exceeds the maximum of 1.00 — "
                          + "reduce the FRACTION share in one of its groups.");
            }
        });

        return errors;
    }

    /* ─────────────────────────────────────────────────────────────
       Save payload
       ───────────────────────────────────────────────────────────── */

    function buildSavePayload() {
        var processedGroups = new Set();
        var groups = [];

        allocationTable.rows().every(function() {
            var row = this.data();
            if (processedGroups.has(row.mergeKey)) { return; }
            processedGroups.add(row.mergeKey);

            // Collect all items for this mergeKey
            var items = [];
            allocationTable.rows().every(function() {
                var r = this.data();
                if (r.mergeKey === row.mergeKey) {
                    items.push({ itemName: r.item, mcPerDay: toNum(r.mcday), groupCode: r.groupCode, materialCode: r.material });
                }
            });

            // Build machine list — FIX machines + ALL fraction machines with individual shares
            var machines = [];
            var fixSeq   = 1;
            $.each(row.fixMachineKeys || [], function(i, k) {
                if (k) { machines.push({ machineRole: "FIX", machineSeq: fixSeq++, machineName: k, requirementValue: 1 }); }
            });
            var fracSeq = 1;
            $.each(row.fractionMachines || [], function(i, e) {
                if (e.machine && toNum(e.share) > 0) {
                    machines.push({ machineRole: "FRACTION1", machineSeq: fracSeq++, machineName: e.machine, requirementValue: toNum(e.share) });
                }
            });

            groups.push({
                mergeKey:             row.mergeKey || "",
                groupCode:            row.groupCode || "",
                materialCode:         row.material  || "",
                status:               row.status    || "OK",
                groupingMcPerDay:     toNum(row.grouping),
                fixRequirement:       toNum(row.fixRequirement),
                fraction1Requirement: toNum(row.fraction1Requirement),
                fixMachineKeys:       $.isArray(row.fixMachineKeys) ? row.fixMachineKeys : [],
                fraction1MachineKey:  row.fractionMachines && row.fractionMachines.length > 0 ? (row.fractionMachines[0].machine || "") : "",
                fractionMachines:     $.isArray(row.fractionMachines) ? row.fractionMachines : [],
                items:    items,
                machines: machines
            });
        });

        return { planId: parseInt(planId, 10), fixLimit: GLOBAL_MAX_FIX_MACHINES, groups: groups };
    }

    /* ─────────────────────────────────────────────────────────────
       mergeRowsByKey — visual row merging for combined items
       ───────────────────────────────────────────────────────────── */

    function mergeRowsByKey(api, keyField, columnIndexes) {
        var rows = api.rows({ page: "current" }).nodes();
        var data = api.rows({ page: "current" }).data().toArray();

        $(rows).each(function() {
            var tr = $(this);
            $.each(columnIndexes, function(i, ci) {
                tr.find("td").eq(ci).removeAttr("rowspan").removeClass("merged-cell").show();
            });
        });

        var startRow = 0;
        while (startRow < data.length) {
            var currentKey = data[startRow][keyField];
            var rowspan    = 1;
            while (startRow + rowspan < data.length && data[startRow + rowspan][keyField] === currentKey) { rowspan++; }
            if (currentKey && rowspan > 1) {
                $.each(columnIndexes, function(i, ci) {
                    var firstCell = $(rows[startRow]).find("td").eq(ci);
                    firstCell.attr("rowspan", rowspan).addClass("merged-cell").show();
                    for (var r = 1; r < rowspan; r++) { $(rows[startRow + r]).find("td").eq(ci).hide(); }
                });
            }
            startRow += rowspan;
        }
    }

    /* ─────────────────────────────────────────────────────────────
       Event handlers — all inside $(document).ready()
       ───────────────────────────────────────────────────────────── */

    $(document).ready(function() {

        //---- Plan selector ----//
        loadPlans();

        $("#planSelect").on("change", function () {
            setPlanFromSelection(this.value);
            if (planId) {
                loadAllocation();
            } else {
                if (allocationTable) { allocationTable.clear().draw(); }
                clearSavedMode();
                $("#reconBanner").hide();
            }
        });

        //---- DataTable ----//

        allocationTable = $("#allocation_table").DataTable({
            ordering: false, fixedHeader: true, scrollX: true, scrollY: "54vh",
            pageLength: 50, deferRender: true, responsive: false, serverSide: false,
            processing: false, searching: false, lengthChange: false,
            data: [],
            buttons: [{ extend: "excelHtml5", className: "excelButton",
                text: "Export to Excel", title: "Machine_Allocation_" + new Date().getTime(),
                exportOptions: { columns: ":visible" } }],
            columns: [
                { title: "ITEM",       data: "item",       className: "td-item",        render: function(d) { return escapeHtml(d || ""); } },
                { title: "MC/Day",     data: "mcday",      className: "td-mc",          render: fmtNum },
                { title: "Groupings",  data: "grouping",   className: "td-grouping",    render: fmtNum },
                { title: "FIX Reqt",   data: "fixRequirement",      className: "td-zero-fix",      render: fmtNum },
                { title: "FRAC1 Reqt", data: "fraction1Requirement", className: "td-zero-fraction", render: fmtNum },
                { title: "Fix Machines", data: "fixMachineKeys", className: "td-allocation",
                    render: function(data, type, row) {
                        if (type !== "display") { return $.isArray(data) ? data.join(",") : ""; }
                        return renderEditableMachineSelects(row, "fix");
                    }
                },
                { title: "FRACTION1 Machine", data: "fraction1MachineKey", className: "td-allocation",
                    render: function(data, type, row) {
                        if (type !== "display") { return data || ""; }
                        return renderEditableMachineSelects(row, "fraction1");
                    }
                },
                { title: "FRAC1 REQT", data: "fraction1Reqt", className: "td-allocation", render: fmtNum },
                { title: "GROUP", data: "groupCode", className: "td-group",
                    render: function(data, type) {
                        if (type !== "display") { return data; }
                        var gc  = normalizeGroup(data);
                        var cls = gc === "A" ? "group-label-a" : gc === "B" ? "group-label-b" : "";
                        return '<span class="badge rounded-pill ' + cls + '">' + escapeHtml(gc || "-") + '</span>';
                    }
                },
                { title: "STATUS", data: "status", className: "td-group",
                    render: function(data, type) {
                        if (type !== "display") { return data; }
                        if (!data || data === "OK") { return "OK"; }
                        return '<span class="warning-text">' + escapeHtml(data) + '</span>';
                    }
                }
            ],
            columnDefs: [{ targets: "_all", defaultContent: "", className: "text-center" }],
            createdRow: function(row, data) {
                if (data.sectionStart) { $(row).addClass("group-section-start"); }
            },
            drawCallback: function() {
                mergeRowsByKey(this.api(), "mergeKey", [2, 3, 4, 5, 6, 7]);
            }
        });

        allocationTable.buttons().container().hide();

        //---- Export ----//

        $("#exportExcel").on("click", function() {
            allocationTable.button(".excelButton").trigger();
        });

        //---- Validate ----//

        $("#validateAllocation").on("click", function() {
            var errors = validateFinalAllocation();
            if (errors.length > 0) {
                Swal.fire({ title: "Validation Errors", html: errors.join("<br>"), icon: "error" });
                return;
            }
            Swal.fire({ text: "Allocation is valid.", icon: "success" });
        });

        //---- Save ----//

        $("#saveAllocation").on("click", function() {
            var errors = validateFinalAllocation();
            if (errors.length > 0) {
                Swal.fire({ title: "Validation Errors", html: errors.join("<br>"), icon: "error" });
                return;
            }

            showLoadingScreen();

            $.ajax({
                type:        "POST",
                url:         basePath + "/machineallocation/n",
                contentType: "application/json",
                data:        JSON.stringify(buildSavePayload()),
                success: function(response) {
                    Swal.fire({ text: response, icon: "success" }).then(function() { loadAllocation(); });
                },
                error: function(xhr) {
                    Swal.close();
                    Swal.fire({ text: xhr.responseText || "Error saving allocation.", icon: "error" });
                }
            });
        });

        //---- Machine select change ----//

        //---- Fraction: add new machine+share pair ----//
        $(document).on("click", ".frac-add-btn", function() {
            var mergeKey = String($(this).attr("data-merge-key"));
            allocationTable.rows().every(function() {
                var rowData = this.data();
                if (rowData.mergeKey !== mergeKey) { return; }
                if (!$.isArray(rowData.fractionMachines)) { rowData.fractionMachines = []; }
                rowData.fractionMachines.push({ machine: "", share: 0 });
                this.data(rowData);
            });
            allocationTable.draw(false);
        });

        //---- Fraction: remove a machine+share pair ----//
        $(document).on("click", ".frac-remove-btn", function() {
            var mergeKey = String($(this).attr("data-merge-key"));
            var idx      = parseInt($(this).attr("data-frac-index"), 10);
            allocationTable.rows().every(function() {
                var rowData = this.data();
                if (rowData.mergeKey !== mergeKey) { return; }
                if (!$.isArray(rowData.fractionMachines)) { return; }
                rowData.fractionMachines.splice(idx, 1);
                this.data(rowData);
            });
            allocationTable.draw(false);
            updateSummaryCardsFromTable();
        });

        //---- Fraction: machine selection changed ----//
        $(document).on("change", ".frac-machine-select", function() {
            var mergeKey = String($(this).attr("data-merge-key"));
            var idx      = parseInt($(this).attr("data-frac-index"), 10);
            var newVal   = $(this).val();

            // Prevent duplicate machine selection within the same group
            var isDupe = false;
            allocationTable.rows().every(function() {
                var rowData = this.data();
                if (rowData.mergeKey !== mergeKey) { return; }
                $.each(rowData.fractionMachines || [], function(i, e) {
                    if (i !== idx && e.machine === newVal && newVal !== "") { isDupe = true; }
                });
            });
            if (isDupe) {
                Swal.fire({ text: "Machine " + newVal + " is already assigned to this group.", icon: "error" });
                allocationTable.draw(false);
                return;
            }

            allocationTable.rows().every(function() {
                var rowData = this.data();
                if (rowData.mergeKey !== mergeKey) { return; }
                if (!$.isArray(rowData.fractionMachines) || !rowData.fractionMachines[idx]) { return; }
                rowData.fractionMachines[idx].machine = newVal;
                // Keep fraction1MachineKey in sync for backward compat
                if (idx === 0) { rowData.fraction1MachineKey = newVal; }
                this.data(rowData);
            });
            allocationTable.draw(false);
            updateSummaryCardsFromTable();
        });

        //---- Fraction: share value changed ----//
        $(document).on("change", ".frac-share-input", function() {
            var mergeKey = String($(this).attr("data-merge-key"));
            var idx      = parseInt($(this).attr("data-frac-index"), 10);
            var newShare = round2(parseFloat($(this).val()) || 0);

            allocationTable.rows().every(function() {
                var rowData = this.data();
                if (rowData.mergeKey !== mergeKey) { return; }
                if (!$.isArray(rowData.fractionMachines) || !rowData.fractionMachines[idx]) { return; }
                rowData.fractionMachines[idx].share = newShare;
                this.data(rowData);
            });
            allocationTable.draw(false);
        });

        //---- machine-edit-select (FIX machines only) ----//
        $(document).on("change", ".machine-edit-select", function() {
            var mergeKey    = String($(this).attr("data-merge-key"));
            var machineType = String($(this).attr("data-machine-type"));

            if (machineType !== "fix") { return; } // fraction handled by frac-machine-select

            var selectedKeys = [];
            $(".machine-edit-select").each(function() {
                var sel = $(this);
                if (String(sel.attr("data-merge-key")) === mergeKey
                        && String(sel.attr("data-machine-type")) === "fix"
                        && sel.closest("td").is(":visible")) {
                    var v = sel.val();
                    if (v) { selectedKeys.push(v); }
                }
            });

            if (new Set(selectedKeys).size !== selectedKeys.length) {
                Swal.fire({ text: "Duplicate machine is not allowed in the same allocation group.", icon: "error" });
                allocationTable.draw(false);
                return;
            }

            allocationTable.rows().every(function() {
                var rowData = this.data();
                if (rowData.mergeKey === mergeKey) {
                    rowData.fixMachineKeys = selectedKeys.slice();
                    this.data(rowData);
                }
            });

            allocationTable.draw(false);
            updateSummaryCardsFromTable();
        });

        //--------------------------------------------------------------------------//

    }); // end $(document).ready


    /* ── Machine type badge helper ── */
    function buildMachineTypeBadge(code) {
        if (!code) { return ""; }
        var cls = "badge-machine-default";
        var upper = String(code).toUpperCase();
        if (upper === "FRST") { cls = "badge-machine-frst"; }
        if (upper === "GSX")  { cls = "badge-machine-gsx";  }
        return ' <span class="badge-machine-type ' + cls + '" '
             + 'style="font-size:0.65rem;vertical-align:middle;">'
             + upper + '</span>';
    }

</script>
</body>
</html>
