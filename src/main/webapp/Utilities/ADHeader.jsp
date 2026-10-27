<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<!--------Checking of Session if Expired-------------->
<c:choose>
		<c:when test="${empty currentSessionUser}">
			<script>
			$(document).ready(function(){
				Swal.fire({
            		  title:'Session Expired!',
            		  html: '<p>Note: You will be redirected to the login page. <br>Log in again to continue.</p>',
					  icon: 'info',
					  width: '30%',
					  allowOutsideClick: false,
					  confirmButtonText: 'OK',
					  backdrop: 'rgba(0,0,0,0.5)'
					}).then(function(result){   	
						window.location.href = "${pageContext.request.contextPath}/logoutad";
                	});
			});
			</script>
		</c:when>
</c:choose>

<!---------------------JAVASCRIPT-------------------->
<script>
//Reload ever back in browser 
window.addEventListener( "pageshow", function ( event ) {
	  var historyTraversal = event.persisted || 
	     ( typeof window.performance != "undefined" && window.performance.navigation.type === 2 );
	  if ( historyTraversal ) {
	    window.location.reload();
	  }
});
function showLoadingScreen() {
    Swal.fire({
        title: '<span style="color:#28282B; font-family:FSEmericLight,Helvetica; font-size:25px; font-weight:600;">Please wait...</span>',
        html: '<div class="spinner"></div><br><i style="color:#28282B; font-family:FSEmericLight,Helvetica; font-size:20px; font-weight:600;">Loading...</i>',
        allowOutsideClick: false,
        showConfirmButton: false
    });
}


//Logout swal confirmation
$(document).on('click', '#logout', function(event){
	Swal.fire({
		  title: '<h2 style="color: #28282B;">Are you sure you want to Logout?</h2>',
		  text: "You will be returned to the login screen.",
		  iconHtml: '<i class="fa-solid fa-exclamation"style="color:#28282B; font-size:3.5rem;"></i>',
		  background: 'white',
		  position: 'center',
		  width: 'auto',
		  focusConfirm: false,
		  showCancelButton: true,
		  confirmButtonText: "Log out",
		  allowOutsideClick: false,
		  cancelButtonText: 'Cancel',
		}).then((result) => {
		  if (result.isConfirmed) {
			    Swal.fire({
// 			        title: '<span style="color:#28282B; font-family:FSEmericLight,Helvetica; font-size:25px; font-weight:600;">Logging out...</span>',
			        html: '<div class="spinner"></div><br><i style="color:#28282B; font-family:FSEmericLight,Helvetica; font-size:20px; font-weight:600;">Logging out...</i>',
			        allowOutsideClick: false,
			        showConfirmButton: false
			    });
			    window.location.href = "${pageContext.request.contextPath}/logoutad";
			  
// 			  Swal.fire({
// 		      title: '<h2 style="color: #091534;">Logged out</h2>',
// 		      text: "Sign in again to continue.",
// 		      iconHtml: '<i class="fa-solid fa-check"style="color:#28282B; font-size:3.5rem;"></i>',
// 		      width: 'auto',
// 		      showConfirmButton: false,
// 		   	  timer: 1500
// 		    }).then(function (result) {
		    	
// 		    	window.location.href = "${pageContext.request.contextPath}/logout";
// 		    });
		  }
	});
});

//Export to excel swal confirmation
$(document).on("click","#exportexcel", function(event){
		Swal.fire({
			  title: '<h2 style="color:#28282B;">Export Excel</h2>',
			  text: 'Are you sure you want to export the data that shown in the table?',
			  position: 'center',
			  icon:'info',
		  	  background: '#ffffff',
		  	  focusConfirm: false,
		      showCancelButton: true,
		      allowOutsideClick: false,
		      cancelButtonText: 'Cancel',
		      confirmButtonText: 'Export',
			}).then(function(result){
           	if(result.isConfirmed){
           		$(document).ready(function() {
           		  $('.buttons-excel').trigger('click');
           		});
           	}
           	else {
               	result.dismiss;
           	}
        });
});

//For responsive navigation
$(document).ready(function(){
	 adjustDropClass();

	    $(window).on('resize', function() {
	        adjustDropClass();
	    });

	     function adjustDropClass() {
	        if (window.innerWidth < 1023) {
	            $('#drop, .user_option #drop').removeClass('dropdown');
	            $('#drop, .user_option #drop').addClass('dropstart');
	        } else { 
	              $('#drop, .user_option #drop').removeClass('dropstart'); 
	              $('#drop, .user_option #drop').addClass('dropdown'); 
	         }
	     }
	
	$(document).on('click','.burgerbutton', function(event){
		$(this).toggleClass("active");
		$('.controller').toggleClass("open");
	});
});
// Burger menu button
$(window).on("click", function(e) {
	 if (!$(e.target).is('.burgerbutton, .nav-link')) {
	    var controller = $(".controller");
	    var burgerbutton  = $(".burgerbutton");
	        
	    if (controller.hasClass('open')) {
	    	controller.removeClass('open');
	   }
	    
	    if (burgerbutton.hasClass('active')) {
	    	burgerbutton.removeClass('active');
	   }
	}
});
</script>
<!-------------------HTML--------------------->
<Header class="header">
	<div class="header_container displayflex">
		<div class="logo ps-5">
			<h2 id="systemtitle">System Title</h2>
		</div>
		<div class="controller displayflex column-gap-2">
			<div class="navigation">
				<ul class="nav nav-pills">
				  <li class="nav-item dropdown" id="drop">
				    <a class="nav-link dropdown-toggle" data-bs-toggle="dropdown" href="#" role="button" aria-expanded="false" id="navigation2">Screen List</a>
				    <ul class="dropdown-menu mt-2">
				      <li><a class="dropdown-item" href="${pageContext.request.contextPath}/maintenancead" id="navigation2.1"><i class="fa-solid fa-dog"></i> Maintenance</a></li>
						<!-- Add another dropdown item here for Screen List -->
				    </ul>
				  </li>
				  <%--Uncomment the items below if need more navigation--%>
<%-- 				  <li class="nav-item"><a class="nav-link" href="${pageContext.request.contextPath}/yourservlet" id="navigation3">navigation 2</a></li> --%> 
<%-- 				  <li class="nav-item"><a class="nav-link" href="${pageContext.request.contextPath}/yourservlet" id="navigation4">navigation 3</a></li> --%>
				  <li class="nav-item"><a class="nav-link" href="${pageContext.request.contextPath}/accountad" id="navigation4">Accounts</a></li>
				</ul>
			</div>
			<div class="user_option border-2 border-start border-dark">
				<ul class="nav nav-pills">
				<!--replace the condition to (not empty)-->
				<c:choose>
					<c:when test="${not empty currentSessionUser}">
					<li class="nav-item dropdown" id="drop">
					    <a class="nav-link dropdown-toggle py-3 px-5" data-bs-toggle="dropdown" href="#" role="button" aria-expanded="false"><i class="fas fa-user"></i> ${currentSessionUser}</a>
					    <ul class="dropdown-menu">
					      <li><a class="dropdown-item px-4" href="#" id="changepassword"><i class="fas fa-key"></i> Change Password</a></li>
					      <li><a class="dropdown-item px-4" href="#" id="logout"><i class="fas fa-sign-out-alt"></i> Logout</a></li>
					    </ul>
					  </li>
					</c:when>
					<c:otherwise>
					  <li class="nav-item w-100">
					    <a class="nav-link py-3 px-5 w-100" aria-disabled="true"><i class="fas fa-lock"></i> Log in</a>
					  </li>
					</c:otherwise>
				</c:choose>
				</ul>
			</div>
		</div>
		<div class="burgerbutton" >
			<span></span>
		</div>
	</div>
</Header>