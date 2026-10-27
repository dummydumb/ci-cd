<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
  <title>Idle Detection with Reload</title>
</head>
<body>
  <h1>Idle Detection Demo</h1>
  <p id="status">Active</p>

  <script>
    let idleTimeout;       // Tracks idle state (10s)
    let reloadTimeout;     // Tracks reload countdown (60s)
    const idleDelay = 3000;   // 10 seconds
    const reloadDelay = 10000; // 60 seconds

    function resetTimers() {
      document.getElementById('status').textContent = 'Active';
      clearTimeout(idleTimeout);
      clearTimeout(reloadTimeout);

      // Start idle detection again
      idleTimeout = setTimeout(startReloadTimer, idleDelay);
    }

    function startReloadTimer() {
      document.getElementById('status').textContent = 'Idle detected. Reload in 60s if no activity.';
      reloadTimeout = setTimeout(() => {
        location.reload();
      }, reloadDelay);
    }

    // Events that indicate activity
    const events = ['mousemove', 'keydown', 'mousedown', 'touchstart', 'scroll'];
    events.forEach(event => {
      document.addEventListener(event, resetTimers, true);
    });

    // Initialize
    resetTimers();
  </script>
</body>
</html>
