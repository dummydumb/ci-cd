<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sign in — ipmssys</title>
    <%@include file="/Utilities/links.jsp" %>

    <style>
        /* ---- Design tokens (ipmssys canvas design) ---- */
        :root {
            --lg-accent:        #0f5a47;
            --lg-accent-dark:   #0b4536;
            --lg-accent-tint:   #e3efe9;
            --lg-page:          #f4f6f3;
            --lg-surface:       #ffffff;
            --lg-border:        #dfe5e0;
            --lg-border-input:  #cfd8d2;
            --lg-text:          #17211d;
            --lg-text-sub:      #55635d;
            --lg-text-muted:    #6a7771;
        }

        html, body {
            height: 100%;
        }
        body {
            margin: 0;
            background: var(--lg-page);
            color: var(--lg-text);
            font-family: 'FSEmericLight', Helvetica, 'Segoe UI', sans-serif;
            font-size: 14px;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px;
        }

        .lg-card {
            width: 100%;
            max-width: 420px;
            background: var(--lg-surface);
            border: 1px solid var(--lg-border);
            border-radius: 12px;
            box-shadow: 0 10px 30px -18px rgba(15, 90, 71, 0.35);
            padding: 36px 32px 32px;
        }

        /* ---- Clock ---- */
        .lg-clock {
            text-align: center;
            margin-bottom: 18px;
        }
        .lg-time {
            font-size: 40px;
            font-weight: 700;
            letter-spacing: -0.02em;
            line-height: 1.1;
            color: var(--lg-accent);
            margin: 0;
        }
        .lg-date {
            font-size: 13px;
            color: var(--lg-text-muted);
            margin: 4px 0 0;
            letter-spacing: 0.04em;
        }

        /* ---- Heading ---- */
        .lg-title {
            text-align: center;
            font-size: 22px;
            font-weight: 700;
            margin: 6px 0 2px;
        }
        .lg-subtitle {
            text-align: center;
            font-size: 13px;
            color: var(--lg-text-sub);
            margin: 0 0 24px;
        }

        /* ---- Fields ---- */
        .lg-field {
            margin-bottom: 16px;
        }
        .lg-label {
            display: block;
            font-size: 12px;
            font-weight: 600;
            color: var(--lg-text-sub);
            margin-bottom: 6px;
            letter-spacing: 0.02em;
        }
        .lg-input {
            width: 100%;
            height: 44px;
            padding: 0 14px;
            border: 1px solid var(--lg-border-input);
            border-radius: 8px;
            background: var(--lg-surface);
            color: var(--lg-text);
            font-size: 14px;
            font-family: inherit;
            box-sizing: border-box;
            transition: border-color 0.15s ease, box-shadow 0.15s ease;
        }
        .lg-input:focus {
            outline: none;
            border-color: var(--lg-accent);
            box-shadow: 0 0 0 3px var(--lg-accent-tint);
        }
        #employeeid {
            text-transform: uppercase;
        }

        .lg-show {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-top: -4px;
            margin-bottom: 20px;
        }
        .lg-show input {
            width: 15px;
            height: 15px;
            accent-color: var(--lg-accent);
        }
        .lg-show label {
            font-size: 13px;
            color: var(--lg-text-sub);
            cursor: pointer;
        }

        /* ---- Button ---- */
        .lg-btn {
            width: 100%;
            height: 46px;
            border: 0;
            border-radius: 8px;
            background: var(--lg-accent);
            color: #ffffff;
            font-size: 15px;
            font-weight: 600;
            font-family: inherit;
            cursor: pointer;
            transition: background-color 0.15s ease;
        }
        .lg-btn:hover {
            background: var(--lg-accent-dark);
        }
    </style>
</head>

<body id="body">

    <div class="lg-card">
        <div class="lg-clock">
            <p id="time" class="lg-time">--:--:--</p>
            <p id="date" class="lg-date"></p>
        </div>

        <h1 class="lg-title">ipmssys</h1>
        <p class="lg-subtitle">Please enter your Employee ID and Password</p>

        <form action="${pageContext.request.contextPath}/login" method="post">
            <div class="lg-field">
                <label class="lg-label" for="employeeid">Employee ID</label>
                <input required type="text" class="lg-input" id="employeeid" name="employeeid"
                       maxlength="8" autocomplete="username" placeholder="e.g. PMM12345">
            </div>

            <div class="lg-field">
                <label class="lg-label" for="password">Password</label>
                <input required type="password" class="lg-input" id="password" name="password"
                       maxlength="50" autocomplete="current-password" placeholder="Password">
            </div>

            <div class="lg-show">
                <input type="checkbox" id="cbshowpassword">
                <label for="cbshowpassword">Show password</label>
            </div>

            <button type="submit" class="lg-btn" id="login">Sign in</button>
        </form>
    </div>

    <!-- Server-side flags passed from LoginServlet -->
    <input type="hidden" id="loginFailed"   value="${failed}">
    <input type="hidden" id="loginMessage"  value="${message}">
    <input type="hidden" id="pwExpired"     value="${expired}">
    <input type="hidden" id="expiredId"     value="${expiredAccountid}">
    <input type="hidden" id="expiredEmp"    value="${expiredEmployeeid}">

    <script>
        $(document).ready(function () {

            const contextPath = "${pageContext.request.contextPath}";
            const week = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];

            // ---- Live clock ----
            function zeroPad(num, digits) {
                return String(num).padStart(digits, "0");
            }

            function updateClock() {
                const now = new Date();
                $("#time").text(
                    zeroPad(now.getHours(), 2) + ":" +
                    zeroPad(now.getMinutes(), 2) + ":" +
                    zeroPad(now.getSeconds(), 2)
                );
                $("#date").text(
                    now.getFullYear() + " - " +
                    zeroPad(now.getMonth() + 1, 2) + " - " +
                    zeroPad(now.getDate(), 2) + "  " +
                    week[now.getDay()]
                );
            }
            updateClock();
            setInterval(updateClock, 1000);

            // ---- Show / hide password ----
            $("#cbshowpassword").on("click", function () {
                const field = document.getElementById("password");
                field.type = this.checked ? "text" : "password";
            });

            // ---- Failed login toast ----
            if ($("#loginFailed").val() === "true") {
                const message = $("#loginMessage").val();
                const Toast = Swal.mixin({
                    toast: true,
                    position: "top",
                    showConfirmButton: false,
                    timer: 3000,
                    timerProgressBar: true,
                    didOpen: function (toast) {
                        toast.onmouseenter = Swal.stopTimer;
                        toast.onmouseleave = Swal.resumeTimer;
                    }
                });
                Toast.fire({
                    icon: "error",
                    title: message
                });
            }

            // ---- Expired password flow ----
            if ($("#pwExpired").val() === "true") {
                const accountId = $("#expiredId").val();
                const employeeId = $("#expiredEmp").val();

                Swal.fire({
                    title: "Your password has expired",
                    html: "Hi " + escapeHtml(employeeId) + ", please set a new password to continue.",
                    input: "password",
                    inputLabel: "New password",
                    inputPlaceholder: "Enter a new password",
                    inputAttributes: {
                        maxlength: "50",
                        autocapitalize: "off",
                        autocorrect: "off"
                    },
                    confirmButtonText: "Update password",
                    confirmButtonColor: "#0f5a47",
                    showCancelButton: true,
                    allowOutsideClick: false,
                    preConfirm: function (newPassword) {
                        if (!newPassword) {
                            Swal.showValidationMessage("Please enter a new password.");
                        }
                        return newPassword;
                    }
                }).then(function (result) {
                    if (result.isConfirmed) {
                        showLoadingScreen();
                        $.ajax({
                            url: contextPath + "/accounts/cep",
                            type: "POST",
                            data: {
                                id: accountId,
                                newpassword: result.value
                            },
                            success: function (response) {
                                Swal.fire({
                                    icon: "success",
                                    title: "Done",
                                    text: response,
                                    confirmButtonColor: "#0f5a47"
                                });
                            },
                            error: function (xhr) {
                                Swal.fire({
                                    icon: "error",
                                    title: "Failed",
                                    text: xhr.responseText,
                                    confirmButtonColor: "#0f5a47"
                                });
                            }
                        });
                    }
                });
            }

            // ---- Helpers ----
            function showLoadingScreen() {
                Swal.fire({
                    title: "Please wait...",
                    html: "<i>Processing...</i>",
                    allowOutsideClick: false,
                    allowEscapeKey: false,
                    didOpen: function () {
                        Swal.showLoading();
                    }
                });
            }

            function escapeHtml(value) {
                if (value === null || value === undefined) {
                    return "";
                }
                return String(value)
                    .replace(/&/g, "&amp;")
                    .replace(/</g, "&lt;")
                    .replace(/>/g, "&gt;")
                    .replace(/"/g, "&quot;")
                    .replace(/'/g, "&#39;");
            }
        });
    </script>
</body>
</html>
