<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Monthly Planner</title>
    <%@include file="/Utilities/links.jsp" %>

    <style>
        :root {
            --pn-accent:#0f5a47; --pn-accent-tint:#e3efe9; --pn-accent-soft:#eef4f0;
            --pn-page:#f4f6f3; --pn-surface:#ffffff; --pn-surface-sub:#fafbf9;
            --pn-border:#dfe5e0; --pn-border-strong:#b9c7bf;
            --pn-text:#17211d; --pn-text-sub:#55635d; --pn-text-soft:#3d4a45; --pn-text-muted:#6a7771;
        }
        body { margin: 0; background: var(--pn-page); color: var(--pn-text); font-family: 'FSEmericLight', Helvetica, 'Segoe UI', sans-serif; font-size: 14px; line-height: 1.45; }
        .pn-mono { font-family: 'FSEmericLight', Helvetica, monospace; }

        /* Header is in-flow (~64px) and body has overflow:hidden, so the planner
           gets its own scroll region sized to the remaining viewport height. */
        .pn-scroll { height: calc(100vh - 65px); overflow-y: auto; overflow-x: hidden; }
        .pn-main { box-sizing: border-box; max-width: 1200px; margin: 0 auto; padding: 28px 32px 56px; display: flex; flex-direction: column; gap: 24px; }

        /* ---- Title block ---- */
        .pn-back { align-self: flex-start; min-height: 40px; display: inline-flex; align-items: center; gap: 6px; font-weight: 500; color: var(--pn-text-soft); text-decoration: none; }
        .pn-back:hover { color: var(--pn-accent); }
        .pn-titlerow { display: flex; flex-wrap: wrap; align-items: center; gap: 10px 14px; }
        .pn-title { margin: 0; font-size: 30px; font-weight: 700; letter-spacing: -0.02em; line-height: 1.15; }
        .pn-code { padding: 3px 9px; border-radius: 6px; background: var(--pn-accent-tint); color: var(--pn-accent); font-size: 13px; font-weight: 600; }
        .pn-lede { margin: 0; color: var(--pn-text-sub); font-size: 15px; }

        /* ---- Plan selector ---- */
        .pn-plan { height: 44px; min-width: 300px; padding: 0 12px; border: 1px solid #cfd8d2; border-radius: 8px; background: var(--pn-surface); font: inherit; color: var(--pn-text); }

        /* ---- Layout: sidebar + stages ---- */
        .pn-split { display: flex; flex-wrap: wrap; align-items: flex-start; gap: 24px; }
        .pn-aside { flex: 0 0 248px; box-sizing: border-box; background: var(--pn-surface); border: 1px solid var(--pn-border); border-radius: 12px; padding: 18px 18px 14px; display: flex; flex-direction: column; gap: 10px; }
        .pn-aside-title { color: var(--pn-text-sub); font-size: 12px; font-weight: 600; letter-spacing: 0.06em; text-transform: uppercase; }
        .pn-aside-nav { display: flex; flex-direction: column; gap: 2px; }
        .pn-aside-link { min-height: 44px; display: flex; align-items: center; gap: 10px; padding: 0 8px; border-radius: 8px; color: var(--pn-text); font-weight: 500; text-decoration: none; cursor: pointer; }
        .pn-aside-link.current { background: var(--pn-accent-soft); font-weight: 600; }
        .pn-aside-link.sub { padding-left: 30px; color: var(--pn-text-soft); }
        .pn-dot { width: 22px; height: 22px; border-radius: 50%; background: var(--pn-accent); display: flex; align-items: center; justify-content: center; flex: none; }
        .pn-dot svg { stroke: #fff; }
        .pn-dot-open { width: 18px; height: 18px; border-radius: 50%; border: 2px solid var(--pn-accent); box-sizing: border-box; background: transparent; flex: none; }
        .pn-dot-locked { width: 18px; height: 18px; border-radius: 50%; border: 2px solid #c6cfca; box-sizing: border-box; background: transparent; flex: none; }

        .pn-stages { flex: 1 1 560px; min-width: 0; display: flex; flex-direction: column; gap: 14px; }

        /* ---- Stage card ---- */
        .pn-card { background: var(--pn-surface); border: 1px solid var(--pn-border); border-radius: 12px; padding: 20px 22px; display: flex; flex-wrap: wrap; align-items: center; gap: 16px 24px; }
        .pn-card.locked { opacity: .72; }
        .pn-card-body { flex: 1 1 380px; min-width: 0; display: flex; flex-direction: column; gap: 8px; }
        .pn-card-meta { display: flex; flex-wrap: wrap; align-items: center; gap: 8px 12px; }
        .pn-stageno { font-size: 13px; font-weight: 600; color: var(--pn-text-sub); }
        .pn-h2 { margin: 0; font-size: 18px; font-weight: 600; letter-spacing: -0.01em; }
        .pn-h3 { margin: 0; font-size: 16px; font-weight: 600; }
        .pn-p { margin: 0; color: var(--pn-text-soft); }
        .pn-sub { color: var(--pn-text-sub); font-size: 13px; }
        .pn-lock-note { display:inline-flex; align-items:center; gap:6px; margin-top:4px; font-size:12px; font-weight:600; color:#b26a00; background:#fff4e5; border:1px solid #f3d9ad; border-radius:6px; padding:3px 9px; }
        .pn-lock-note svg { stroke:#b26a00; }

        .pn-pill { display: inline-flex; align-items: center; gap: 5px; padding: 3px 9px; border-radius: 999px; font-size: 12px; font-weight: 600; }
        .pn-pill-completed { background: var(--pn-accent-tint); color: var(--pn-accent); }
        .pn-pill-active { background: #e7f0fb; color: #1d4ed8; }
        .pn-pill-locked { background: #eef1ef; color: var(--pn-text-muted); }
        .pn-pill-soon { background: #fff4e5; color: #b26a00; }

        .pn-btn { flex: 0 0 auto; min-width: 190px; height: 44px; padding: 0 16px; border: 1px solid var(--pn-border-strong); background: var(--pn-surface); border-radius: 8px; color: var(--pn-accent); font: inherit; font-weight: 600; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 8px; text-decoration: none; }
        .pn-btn:hover { background: var(--pn-accent-soft); color: var(--pn-accent); }
        .pn-btn-go { background: var(--pn-accent); border-color: var(--pn-accent); color: #fff; }
        .pn-btn-go:hover { background: #0c4a3b; color: #fff; }
        .pn-btn.disabled { opacity: .55; cursor: not-allowed; pointer-events: none; }

        /* ---- Nested output card ---- */
        .pn-card-stacked { background: var(--pn-surface); border: 1px solid var(--pn-border); border-radius: 12px; display: flex; flex-direction: column; padding: 0; }
        .pn-card-stacked > .pn-card { border: 0; }
        .pn-output { border-top: 1px solid var(--pn-border); background: var(--pn-surface-sub); border-radius: 0 0 12px 12px; padding: 16px 22px; display: flex; flex-wrap: wrap; align-items: center; gap: 16px 24px; }
        .pn-output-body { flex: 1 1 380px; min-width: 0; display: flex; gap: 12px; }
        .pn-output-icon { flex: none; margin-top: 2px; }
        .pn-output-col { display: flex; flex-direction: column; gap: 6px; min-width: 0; }

        .pn-empty { background: var(--pn-surface); border: 1px dashed var(--pn-border); border-radius: 12px; padding: 48px 20px; text-align: center; color: var(--pn-text-muted); }
    </style>
</head>

<body>
<%@include file="/Utilities/Header.jsp" %>

<div class="pn-scroll">
<main class="pn-main">

    <a class="pn-back" href="${pageContext.request.contextPath}/monthlyplan">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 6l-6 6 6 6"></path></svg>
        Monthly Plans
    </a>

    <div style="display:flex; flex-direction:column; gap:10px;">
        <div class="pn-titlerow">
            <h1 class="pn-title" id="planTitle">Monthly Planner</h1>
            <span class="pn-code" id="planCode" style="display:none;"></span>
        </div>
        <p class="pn-lede">Sequential planning stages. Each stage unlocks once the one before it is complete.</p>
        <div><select class="pn-plan" id="planSelect" aria-label="Select plan"><option value="">Select a monthly plan</option></select></div>
    </div>

    <div id="workflow">
        <div class="pn-empty">Select a monthly plan to see its workflow.</div>
    </div>

</main>
</div>

<script>
    $(document).ready(function () {

        const contextPath = "${pageContext.request.contextPath}";
        const planListUrl = contextPath + "/monthlyplan/l";
        const preselectPlanId = "${preselectPlanId}";

        let currentPlan = null;

        /* Stage model. "output" marks the nested Precondition-output card. */
        const STAGES = [
            { id: "precondition-raw", no: "STAGE 1", title: "Pre-Condition Raw",
              desc: "Import and review raw pre-condition requirements for the selected month.",
              items: "Material Specs · Initial Setup · Raw Input",
              url: function () { return contextPath + "/precondition"; }, built: true },
            { id: "saggering", no: "STAGE 2", title: "Saggering Plan",
              desc: "Configure batch distribution and lot generation based on pre-condition raw data.",
              items: "Batch Config · Lot Generation · Saggering Matrix",
              url: function () { return contextPath + "/saggering"; }, built: true,
              output: { id: "precondition-output", title: "Precondition Output",
                        desc: "Generated monthly precondition output used for capacity and machine loading.",
                        items: "Monthly Capacity · Converted CAPA · Item CAPA",
                        url: function () { return contextPath + "/precondition/view"; }, built: true } },
            { id: "allocation", no: "STAGE 3", title: "Machine Usage / Allocation",
              desc: "Allocate qualified items to available machines and define machine share.",
              items: "Qualified Machine · Fix Allocation · Fraction Allocation",
              url: function () { return contextPath + "/machineallocation"; }, built: true },
            { id: "loading", no: "STAGE 4", title: "Loading Plan",
              desc: "Daily loading plan from machine allocation, capacity, and plotting maintenance schedules.",
              items: "Daily Loading · Plotting Impact · Adjusted CAPA",
              url: function () { return contextPath + "/loadingplan"; }, built: true }
        ];

        /* ---------- Helpers ---------- */
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
            const names = ["January","February","March","April","May","June","July","August","September","October","November","December"];
            return (p.month >= 1 && p.month <= 12 ? names[p.month-1] : p.month) + " " + p.year;
        }

        const checkSvg = '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12l5 5 9-10"></path></svg>';
        const eyeSvg = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"></path><circle cx="12" cy="12" r="3"></circle></svg>';
        const arrowSvg = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6"></path></svg>';
        const lockSvg = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="5" y="11" width="14" height="10" rx="2"></rect><path d="M8 11V7a4 4 0 018 0v4"></path></svg>';

        function pill(status) {
            if (status === "completed") { return '<span class="pn-pill pn-pill-completed">' + checkSvg + 'Completed</span>'; }
            if (status === "active") { return '<span class="pn-pill pn-pill-active">Active</span>'; }
            if (status === "soon") { return '<span class="pn-pill pn-pill-soon">Coming soon</span>'; }
            return '<span class="pn-pill pn-pill-locked">Locked</span>';
        }

        function button(stage, status) {
            if (status === "soon") { return '<button type="button" class="pn-btn disabled" disabled>' + lockSvg + ' Coming soon</button>'; }
            if (status === "locked") { return '<button type="button" class="pn-btn disabled" disabled>' + lockSvg + ' Locked</button>'; }
            const href = stage.url() + (stage.url().indexOf("?") >= 0 ? "&" : "?") + "planid=" + currentPlan.planId;
            if (status === "completed") { return '<a class="pn-btn" href="' + href + '">' + eyeSvg + ' Review</a>'; }
            return '<a class="pn-btn pn-btn-go" href="' + href + '">' + arrowSvg + ' Open</a>';
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
                    if (preselectPlanId) { sel.val(preselectPlanId); sel.trigger("change"); }
                },
                error: function (xhr) { Swal.fire({ icon:"error", title:"Failed", text: xhr.responseText, confirmButtonColor:"#0f5a47" }); }
            });
        }

        $("#planSelect").on("change", function () {
            const planId = this.value;
            if (!planId) {
                currentPlan = null;
                $("#planTitle").text("Monthly Planner");
                $("#planCode").hide();
                $("#workflow").html('<div class="pn-empty">Select a monthly plan to see its workflow.</div>');
                return;
            }
            $.ajax({ url: planListUrl, type: "GET", dataType: "json",
                success: function (plans) {
                    currentPlan = null;
                    for (let i = 0; i < (plans||[]).length; i++) { if (String(plans[i].planId) === String(planId)) { currentPlan = plans[i]; break; } }
                    if (!currentPlan) { return; }
                    $("#planTitle").text(monthLabel(currentPlan.planMonth));
                    $("#planCode").text(currentPlan.machineCode || "").show();
                    evaluate();
                }
            });
        });

        /* ---------- Status evaluation ---------- */
        function evaluate() {
            const planId = currentPlan.planId;

            const preReq = $.ajax({ url: contextPath + "/precondition/l", type: "GET", data: { planid: planId }, dataType: "json" });
            const sagReq = $.ajax({ url: contextPath + "/saggering/g", type: "GET", data: { planid: planId }, dataType: "json" });
            const allocReq = $.ajax({ url: contextPath + "/machineallocation/l", type: "GET", data: { planid: planId }, dataType: "json" });

            $.when(preReq, sagReq, allocReq).done(function (preRes, sagRes, allocRes) {
                const sag = sagRes[0];
                const alloc = allocRes[0];
                render({
                    precondition: (preRes[0] && preRes[0].length > 0),
                    saggering: (sag && sag.items && sag.items.length > 0),
                    allocation: (alloc && alloc.allocationId > 0 && alloc.groups && alloc.groups.length > 0)
                });
            }).fail(function () {
                render({ precondition: false, saggering: false, allocation: false });
            });
        }

        /* Sequential dependency chain (mirrors IPMSTEST):
           each stage is LOCKED until its prerequisite is complete.
             Pre-Condition Raw : entry point (never locked)
             Saggering         : needs raw
             Precondition Out  : needs saggering (computed from raw + saggering)
             Allocation        : needs saggering
             Loading Plan      : needs allocation */
        function statusFor(id, state) {
            if (id === "precondition-raw") {
                return state.precondition ? "completed" : "active";
            }
            if (id === "saggering") {
                if (!state.precondition) { return "locked"; }
                return state.saggering ? "completed" : "active";
            }
            if (id === "precondition-output") {
                if (!state.saggering) { return "locked"; }
                // computed output is ready once both raw + saggering exist
                return (state.precondition && state.saggering) ? "completed" : "active";
            }
            if (id === "allocation") {
                if (!state.saggering) { return "locked"; }
                return state.allocation ? "completed" : "active";
            }
            if (id === "loading") {
                return state.allocation ? "active" : "locked";
            }
            return "active";
        }

        /* ---------- Sidebar ---------- */
        function sidebarIndicator(status) {
            if (status === "completed") { return '<span class="pn-dot">' + checkSvg + '</span>'; }
            if (status === "active") { return '<span class="pn-dot-open"></span>'; }
            return '<span class="pn-dot-locked"></span>';
        }

        function render(state) {
            // Sidebar
            let aside = '<aside class="pn-aside"><div class="pn-aside-title">Stages</div><nav class="pn-aside-nav">';
            for (let i = 0; i < STAGES.length; i++) {
                const s = STAGES[i];
                const st = statusFor(s.id, state);
                aside += '<a class="pn-aside-link" href="' + stageHref(s, st) + '">' + sidebarIndicator(st) + (i + 1) + ". " + escapeHtml(s.title) + '</a>';
                if (s.output) {
                    const ost = statusFor(s.output.id, state);
                    aside += '<a class="pn-aside-link sub" href="' + stageHref(s.output, ost) + '">' + sidebarIndicator(ost) + escapeHtml(s.output.title) + '</a>';
                }
            }
            aside += '</nav></aside>';

            // Stage cards
            let cards = '<div class="pn-stages">';
            for (let i = 0; i < STAGES.length; i++) {
                const s = STAGES[i];
                const st = statusFor(s.id, state);
                if (s.output) {
                    const ost = statusFor(s.output.id, state);
                    cards += '<div class="pn-card-stacked">' + stageCard(s, st, true) + outputCard(s.output, ost) + '</div>';
                } else {
                    cards += stageCard(s, st, false);
                }
            }
            cards += '</div>';

            $("#workflow").html('<div class="pn-split">' + aside + cards + '</div>');
        }

        function stageHref(stage, status) {
            if (!currentPlan || status === "soon" || status === "locked") { return "#"; }
            return stage.url() + (stage.url().indexOf("?") >= 0 ? "&" : "?") + "planid=" + currentPlan.planId;
        }

        /* Why a stage is locked — shown as a hint so the planner knows what to do first. */
        function lockedReason(id) {
            if (id === "saggering")           { return "Complete Pre-Condition Raw first."; }
            if (id === "precondition-output") { return "Create a Saggering plan first."; }
            if (id === "allocation")          { return "Create a Saggering plan first."; }
            if (id === "loading")             { return "Save a Machine Allocation first."; }
            return "A previous stage must be completed first.";
        }

        function stageCard(stage, status, stacked) {
            const inner = ''
                + '<div class="pn-card-body">'
                +   '<div class="pn-card-meta"><span class="pn-stageno pn-mono">' + escapeHtml(stage.no) + '</span>' + pill(status) + '</div>'
                +   '<h2 class="pn-h2">' + escapeHtml(stage.title) + '</h2>'
                +   '<p class="pn-p">' + escapeHtml(stage.desc) + '</p>'
                +   '<div class="pn-sub">' + escapeHtml(stage.items) + '</div>'
                +   (status === "locked" ? '<div class="pn-lock-note">' + lockSvg + ' ' + escapeHtml(lockedReason(stage.id)) + '</div>' : '')
                + '</div>'
                + button(stage, status);
            const cls = "pn-card" + (status === "soon" || status === "locked" ? " locked" : "");
            return '<section class="' + cls + '">' + inner + '</section>';
        }

        function outputCard(output, status) {
            const flowSvg = '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#55635d" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 4v8a3 3 0 003 3h11M15 11l4 4-4 4"></path></svg>';
            return ''
                + '<div class="pn-output">'
                +   '<div class="pn-output-body">'
                +     '<span class="pn-output-icon">' + flowSvg + '</span>'
                +     '<div class="pn-output-col">'
                +       '<div class="pn-card-meta"><span class="pn-stageno pn-mono">OUTPUT</span>' + pill(status) + '</div>'
                +       '<h3 class="pn-h3">' + escapeHtml(output.title) + '</h3>'
                +       '<p class="pn-p">' + escapeHtml(output.desc) + '</p>'
                +       '<div class="pn-sub">' + escapeHtml(output.items) + '</div>'
                +     '</div>'
                +   '</div>'
                +   button(output, status)
                + '</div>';
        }

        /* ---------- Initial ---------- */
        loadPlans();

    });
</script>
</body>
</html>
