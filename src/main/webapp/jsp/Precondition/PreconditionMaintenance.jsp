<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Precondition Output</title>
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

        .pc-toolbar { display: flex; flex-wrap: wrap; align-items: center; gap: 12px; margin-bottom: 14px; }
        .pc-plan { height: 42px; min-width: 280px; padding: 0 12px; border: 1px solid var(--pc-border-input); border-radius: 8px; background: var(--pc-surface); font: inherit; color: var(--pc-text); }
        .pc-link { height: 42px; display: inline-flex; align-items: center; gap: 6px; padding: 0 12px; border-radius: 8px; color: var(--pc-text-sub); text-decoration: none; font-weight: 600; }
        .pc-link:hover { color: var(--pc-accent); background: var(--pc-accent-soft); }
        .pc-count { margin-left: auto; color: var(--pc-text-sub); }

        .pc-card { background: var(--pc-surface); border: 1px solid var(--pc-border); border-radius: 12px; padding: 8px; }
        .pc-scroll { overflow-x: auto; }

        table.pc-table { width: 100%; border-collapse: collapse; font-size: 13px; }
        table.pc-table thead th { background: var(--pc-surface-sub); color: var(--pc-text-sub); font-size: 11px; font-weight: 600; letter-spacing: .04em; text-transform: uppercase; text-align: left; padding: 9px 12px; border-bottom: 1px solid var(--pc-border); white-space: nowrap; }
        table.pc-table tbody td { padding: 9px 12px; border-bottom: 1px solid var(--pc-border-soft); vertical-align: middle; white-space: nowrap; }
        table.pc-table tbody tr:last-child td { border-bottom: 0; }
        table.pc-table tbody tr:hover td { background: var(--pc-surface-sub); }
        table.pc-table td.num { text-align: right; font-variant-numeric: tabular-nums; }
        .pc-name { font-weight: 600; }
        .pc-muted { color: var(--pc-text-muted); }
        .pc-hl { background: var(--pc-accent-tint); font-weight: 700; }

        .pc-empty { padding: 40px 20px; text-align: center; color: var(--pc-text-muted); }
    </style>
</head>

<body>
<%@include file="/Utilities/Header.jsp" %>

<div class="pc-wrap">

    <div class="pc-head">
        <div>
            <h1 class="pc-title">Precondition Output</h1>
            <p class="pc-subtitle">Derived capacity per item (converted capa, machine requirement). Computed from the Raw inputs and the Saggering plan.</p>
        </div>
    </div>

    <div class="pc-toolbar">
        <select class="pc-plan" id="planSelect" aria-label="Select plan"><option value="">Select a monthly plan</option></select>
        <a class="pc-link" id="editRaw" href="#"><i class="fa-solid fa-pen-to-square"></i> Edit Raw Inputs</a>
        <span class="pc-count" id="pc-count"></span>
    </div>

    <div class="pc-card">
        <div class="pc-scroll">
            <table id="computed_table" class="pc-table w-100">
                <thead>
                    <tr>
                        <th>Item</th><th>Cap Code</th>
                        <th class="num">Ttl Sht</th><th class="num">Sht/Lot</th>
                        <th class="num">Min/Blk</th><th class="num">Min/Lot</th>
                        <th class="num">Mins/kSht</th><th class="num">Conv Eff %</th><th class="num">Conv Mins/kSht</th>
                        <th class="num">Capa Sht/Day</th><th class="num">Capa Lots/Day</th>
                        <th class="num">ConvCapa Sht/Day</th><th class="num">ConvCapa Lots/Day</th>
                        <th class="num">MPCS/Mo</th><th class="num">MPCS/Day</th>
                        <th class="num">InputPlan Lots/Day</th><th class="num">M/C Reqt</th>
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
        const computeUrl = contextPath + "/precondition/compute";
        const planListUrl = contextPath + "/monthlyplan/l";

        let currentPlanId = "";

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
                    const preselect = "${preselectPlanId}";
                    if (preselect) { sel.val(preselect).trigger("change"); }
                },
                error: function (xhr) {
                    Swal.fire({ icon: "error", title: "Failed", text: xhr.responseText, confirmButtonColor: "#0f5a47" });
                }
            });
        }

        $("#planSelect").on("change", function () {
            currentPlanId = this.value;
            if (currentPlanId) { loadComputed(); }
            else { $("#computed_table tbody").empty(); $("#pc-count").text(""); }
        });

        $("#editRaw").on("click", function (e) {
            e.preventDefault();
            let url = contextPath + "/precondition";
            if (currentPlanId) { url += "?planid=" + currentPlanId; }
            window.location.href = url;
        });

        /* ---------- Computed table ---------- */
        function loadComputed() {
            $.ajax({
                url: computeUrl, type: "GET", data: { planid: currentPlanId }, dataType: "json",
                success: function (rows) { renderComputed(rows || []); },
                error: function (xhr) { Swal.fire({ icon: "error", title: "Failed", text: xhr.responseText, confirmButtonColor: "#0f5a47" }); }
            });
        }

        function renderComputed(rows) {
            const body = $("#computed_table tbody").empty();
            $("#pc-count").text(rows.length + (rows.length === 1 ? " item" : " items"));
            if (rows.length === 0) {
                body.html('<tr><td colspan="17"><div class="pc-empty">Nothing to compute. Add raw inputs and a saggering plan first.</div></td></tr>');
                return;
            }
            for (let i = 0; i < rows.length; i++) {
                const p = rows[i];
                body.append('<tr>'
                    + '<td><span class="pc-name">' + escapeHtml(p.itemName) + '</span></td>'
                    + '<td>' + (p.capCode ? escapeHtml(p.capCode) : '<span class="pc-muted">&mdash;</span>') + '</td>'
                    + '<td class="num">' + num(p.ttlSheet) + '</td>'
                    + '<td class="num">' + num(p.shtPerLot) + '</td>'
                    + '<td class="num">' + num(p.minPerBlk) + '</td>'
                    + '<td class="num">' + num(p.minPerLot) + '</td>'
                    + '<td class="num">' + num(p.minsPerKsht) + '</td>'
                    + '<td class="num">' + num(p.convPreconEff) + '</td>'
                    + '<td class="num">' + num(p.convPreconMinsPerKsht) + '</td>'
                    + '<td class="num">' + num(p.capaShtPerDay) + '</td>'
                    + '<td class="num">' + num(p.capaLotsPerDay) + '</td>'
                    + '<td class="num pc-hl">' + num(p.convCapaShtPerDay) + '</td>'
                    + '<td class="num pc-hl">' + num(p.convCapaLotsPerDay) + '</td>'
                    + '<td class="num">' + num(p.mpcsPerMonth) + '</td>'
                    + '<td class="num">' + num(p.mpcsPerDay) + '</td>'
                    + '<td class="num">' + num(p.inputPlanLotsPerDay) + '</td>'
                    + '<td class="num pc-hl">' + num(p.mcReqtMcPerMos) + '</td>'
                    + '</tr>');
            }
        }

        /* ---------- Initial ---------- */
        loadPlans();

    });
</script>
</body>
</html>
