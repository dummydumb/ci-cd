<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<!--------Checking of Session if Expired-------------->
<c:choose>
		<c:when test="${empty currentSessionUser and empty viewOnly}">
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
						window.location.href = "${pageContext.request.contextPath}/logout";
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
        title: '<span style="color:#17211d; font-family:FSEmericLight,Helvetica; font-size:22px; font-weight:600;">Please wait...</span>',
        html: '<div class="spinner"></div><br><i style="color:#55635d; font-family:FSEmericLight,Helvetica; font-size:16px; font-weight:600;">Loading...</i>',
        allowOutsideClick: false,
        showConfirmButton: false
    });
}
//Change password swal inputs
$(document).on('click', '#changepassword', function(event){
	Swal.fire({
		  title: '<h2 style="color: #28282B;">Change Password</h2>',
		  iconHtml: '<i class="fa-solid fa-user-lock"style="color:#28282B; font-size:2.5rem;"></i>',
		  background: '#ffffff',
		  focusConfirm: false,
		  width: '30rem',
		  showCancelButton: true,
		  confirmButtonText: "Confirm",
		  allowOutsideClick: false,
		  
		  preConfirm: () => {
       		let swalinput2 = $("#swal-input2");
       		let swalinput3 = $("#swal-input3");
       		let swalinput4 = $("#swal-input4");
       		
       		if(swalinput2.val().length <= 0 && swalinput3.val().length <= 0){
      			Swal.showValidationMessage("Please fill out all the required fields.");
      			swalinput2.focus();
      			return false;
			}else if(swalinput2.val().length <= 0 && swalinput3 != null){
	      		Swal.showValidationMessage("Please input current password.");
	      		swalinput2.focus();
	      		return false;
    		}else if(swalinput3.val().length <= 0 && swalinput2 != null){
	      		Swal.showValidationMessage("Please input new password.");
	      		swalinput3.focus();
	      		return false;
    		}else if(swalinput3.val() != swalinput4.val()){
    			Swal.showValidationMessage("Password confirmation does not match with the new password.");
    			swalinput4.focus();
    			return false;
    		}
       		
       	},
		  
		  html: 
	      		'<form id="changepasswordform" class="px-0">' + 
	      		'<input type="hidden" name="id" id="swal-hidden-input1" value = "${currentaccountid}">' +
	      		'<input type="hidden" name="type" id="swal-hidden-input2" value = "notexpired">' +
	      		'<p class="mb-2"><strong>${currentSessionUser}</strong></p>' +
	     			
	      		'<div class="row mb-2 text-start mx-auto">' + 
					'<div class="form-floating">' +
	 					'<input type="password" class="form-control" id="swal-input2" style="font-size: 13px;" name="password" placeholder="" maxlength="50">' +
	 					'<label class="ms-3" for="swal-input2"><span class="asterisk">*</span>Enter Current Password</label>' +
					'</div>' +
				'</div>'+
					'<div class="row mb-2 text-start mx-auto">' + 
					'<div class="form-floating">' +
						'<input type="password" class="form-control" id="swal-input3" style="font-size: 13px;" name="newpassword" placeholder="" maxlength="50">' +
						'<label class="ms-3" for="swal-input3"><span class="asterisk">*</span>Enter New Password</label>' +
					'</div>' +
				'</div>'+
				'<div class="row mb-2 text-start mx-auto">' + 
					'<div class="form-floating">' +
						'<input type="password" class="form-control" id="swal-input4" style="font-size: 13px;" placeholder="" maxlength="50">' +
						'<label class="ms-3" for="swal-input4"><span class="asterisk">*</span>Confirm New Password</label>' +
					'</div>' +
				'</div>'+
	      		
// 	      			'<div class="form-group mx-auto text-start">' + 
// 	      				'<label for="swal-input2" class="my-2 " style="font-size: 13px;">Enter Current Password: </label>' + 
// 	      				'<input type="password" required class="form-control py-2" id="swal-input2" name="password">' + 
// 	     			'</div>' +
// 	     			'<div class="form-group mx-auto text-start">' + 
// 	  					'<label for="swal-input3" class="my-2" style="font-size: 13px;">Enter New Password: </label>' + 
// 	  					'<input type="password" required class="form-control py-2" id="swal-input3" name="newpassword">' + 
// 	 				'</div>' +
// 	 				'<div class="form-group mx-auto text-start">' + 
// 						'<label for="swal-input4" class="my-2" style="font-size: 13px;">Confirm New Password: </label>' + 
// 						'<input type="password" required class="form-control py-2" id="swal-input4">' + 
// 					'</div>' +
					'<div class="form-group mx-auto text-center pt-3">' + 
						'<p for="swal-input4" class="mb-1" style="font-size: 13px;"><a id="forgotpassword" style="cursor:pointer;"><u>Forgot password?</u></a></p>' + 
					'</div>' +
	      		'</form>'
      		
      		
		}).then((result) => {
		  if (result.isConfirmed) {
			  $.ajax({
                  type: "POST",
                  url: "${pageContext.request.contextPath}/accounts/cp",
                  data: $("#changepasswordform").serialize(),
                  cache: false,
                  success: function(response) {
                  	Swal.fire({
    					  text: response,
    					  width:'30%',
    					  iconHtml: '<i class="fa-solid fa-check"style="color:#28282B; font-size:3.5rem;"></i>',
    					  showConfirmButton: true,
					  	
    					});
                  	maintenance_table.ajax.reload();
                  },
                  error: function(response){
                  	Swal.fire({
    					  text: response.responseText,
    					  width:'30%',
    					  iconHtml: '<i class="fa-solid fa-x"style="color:#28282B; font-size:3.5rem;"></i>',
    					  confirmButtonText: 'OK'
                  	});
                  }
          	});
			  showLoadingScreen(); 
		  }
		});
});

// Forgot Password
$(document).on("click", "#forgotpassword", function(event){
	var employeeid = "${currentSessionUser}";
	var accountid = "${currentaccountid}";
	var email;
	var verificationcode;
		console.log(employeeid);
	
	Swal.fire({
    	title: '<h4 style="color:#28282B">Forgot Password?</h4>',
    	position: 'center',
    	background: '#ffffff',
    	focusConfirm: true,
    	heightAuto: false,
    	showCancelButton: true,
    	allowOutsideClick: false,
    	confirmButtonText: 'Confirm',
		didOpen: (event) => {
       		$(document).on('keypress', function (e) {
       			if(e.key === 'Enter'){
       				e.preventDefault()
       				Swal.clickConfirm();
       			}
           	});
         },
        preConfirm: () => {
       		
       		if( verificationcode !=  $("#vcode").val()){
       			Swal.showValidationMessage("Invalid verification code.");
       			$("#vcode").focus();
      			return false;
       		}
        },
        
         willOpen: () => {
 		   		$.ajax({
                    type: "GET",
                    url: "${pageContext.request.contextPath}/account/g",
                    data: {"employeeid" : employeeid},
                    cache: false,
                    success: function(listEmployeeinfo) {
                    	if(listEmployeeinfo){
                    		$('#email').val(listEmployeeinfo.email);
                    		email = listEmployeeinfo.email;
                    		
                    		// ******* Generate and send verification code to email *******
                        	$("#sendcode").click(function(event){
                        		Swal.resetValidationMessage();
                        		function generateCode(length) {
                        	       var characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
                        	       var code = '';
                        	       for (var i = 0; i < length; i++) {
                        	           var randomIndex = Math.floor(Math.random() * characters.length);
                        	           code += characters[randomIndex];
                        	       }
                        	       return code;
                        	   }
                        		 	var code = generateCode(6); // Generate a 6-digit code
                        		    $('#verificationcode').val(code);
                        		    $('#vcode').prop("disabled",false);
                        		    $('#sendcode').addClass("disabled");
                        		    $('#vcode').focus();
                        		    resendCountdown();
                        		    verificationcode = code;
                            		$.ajax({
                                        type: "POST",
                                        url: "${pageContext.request.contextPath}/accounts/sm", 
                                        data: { "employeeid": employeeid, "to": email, "verificationcode" : verificationcode },
                                        cache: false,
                                        success: function(response) {
                                        },
                                        error: function(response){
                                        	Swal.fire({
                          					  text: response.responseText,
                          					  icon: 'error',
                          					  heightAuto: false,
                          					  confirmButtonText: 'OK'
                                        	});
                                        }
                                	});
                        	});
                        	function resendCountdown(){
                        		let countdownTime = 60; // 60 seconds
                            	const countdownInterval = setInterval(() => {
                            		$('#resendtimer').text("Resend in: "+ countdownTime +"s");
                            		$('#sendcode').text("Resend");
                            	    countdownTime--;
                            	    if (countdownTime < 0) {
                            	        clearInterval(countdownInterval);
                            	        $('#resendtimer').text("");
                            	        $('#sendcode').removeClass("disabled");
                            	    }
                            	}, 1000);
                        	}
                        	//***************************************************************
                    	}
                    },
                    error: function(response){
                    	Swal.fire({
      					  text: response.responseText,
      					  icon: 'error',
      					  confirmButtonText: 'OK',
                    	});
                    }
           		});
        },
	  	html: 
		'<form id="forgotpasswordform" class="px-4 py-2">' + 
	      		'<div class="form-group mx-auto text-start">' + 
					'<label for="email" class="my-2" style="font-size: 13px;">Click "Get Code" to send a verification code to your Murata email.</label>' + 
					'<input type="text" style="border:none;" class="form-control py-2"  id="email" readonly>' + 
				'</div>' +
				'<div class="form-group mx-auto text-start d-flex align-items-end justify-content-between">' + 
					'<div class="form-group mx-0 text-start col-8">' + 
						'<label for="vcode" class="my-2" style="font-size: 13px;">Enter your verification code:</label>' + 
						'<input type="text" required class="form-control py-2"  id="vcode"  disabled maxlength="6">' + 
					'</div>' +
					'<div class="form-group mx-0 text-center col-4 ">' + 
							'<label id="resendtimer" class="my-2 text-start" style="font-size: 13px;"></label>' + 
							'<a class="btn btn-primary py-2"  id="sendcode" >Get Code</a>' + 
					'</div>' +
				'</div>' +
   		'</form>'
           	
    }).then(function(result){
       	if(result.isConfirmed){
       		Swal.fire({
  			  title: '<h2 style="color: #28282B;">Change Forgotten Password</h2>',
  			  iconHtml: '<i class="fa-solid fa-user-lock"style="color:#28282B; font-size:2.5rem;"></i>',
  			  background: '#ffffff',
  			  focusConfirm: false,
  			  width: '30rem',
  			  heightAuto: false,
  			  showCancelButton: true,
  			  confirmButtonText: "Confirm",
  			  allowOutsideClick: false,
  			  
  			  preConfirm: () => {
  	       		let swalinput1 = $("#swal-input1");
  	       		let swalinput2 = $("#swal-input2");
  	       		
  	       		if(swalinput1.val().length < 8){
  	       			Swal.showValidationMessage("Minimum of 8 characters is required.");
  	      			swalinput1.focus();
  	      			return false;
  	       		}
  	       		if(swalinput1.val() != swalinput2.val()){
  	       			Swal.showValidationMessage("Password confirmation does not match with the new password.");
  	      			swalinput2.focus();
  	      			return false;
  	       		}
  	       	},
  	      willOpen: () => {
  	    	  
  	      },
  			  html: 
  	      		'<form id="changepasswordform" class="px-4 py-2">' + 
  	      		'<p class="mb-2"><strong>'+ employeeid +'</strong></p>' +
  	     			'<div class="form-group mx-auto text-start">' + 
  	  					'<label for="swal-input2" class="my-2" style="font-size: 13px;">Enter New Password: </label>' + 
  	  					'<input type="password" required class="form-control py-2" id="swal-input1" name="newpassword">' + 
  	 				'</div>' +
  	 				'<div class="form-group mx-auto text-start">' + 
  						'<label for="swal-input3" class="my-2" style="font-size: 13px;">Confirm New Password: </label>' + 
  						'<input type="password" required class="form-control py-2" id="swal-input2">' + 
  					'</div>' +
  	      		'</form>'
  	      		
  			}).then((result) => {
  			  	if (result.isConfirmed) {
  				  	$.ajax({
  	                  	type: "POST",
	  	           		url: "${pageContext.request.contextPath}/accounts/cep",
	  	         		data: $("#changepasswordform").serialize(),
	  	             	cache: false,
	  	               	success: function(response) {
	  	                	Swal.fire({
	  	    					  text: response,
	  	    					  width:'30%',
	  	    					  heightAuto: false,
	  	    					  iconHtml: '<i class="fa-solid fa-check"style="color:#28282B; font-size:3.5rem;"></i>',
	  	    					  showConfirmButton: true,
	  	    					});
	  	                  },
	  	             	error: function(response){
	  	                  	Swal.fire({
	  	    					  text: response.responseText,
	  	    					  width:'30%',
	  	    					  heightAuto: false,
	  	    					  iconHtml: '<i class="fa-solid fa-x"style="color:#28282B; font-size:3.5rem;"></i>',
	  	    					  confirmButtonText: 'OK'
	  	                  	});
	  	                  }
	  	          	});
  				  showLoadingScreen(); 
  			  	}else{
        			result.dismiss;
    			}
    		});//end swal
    	}
	});
});


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
			        html: '<div class="spinner"></div><br><i style="color:#55635d; font-family:FSEmericLight,Helvetica; font-size:16px; font-weight:600;">Logging out...</i>',
			        allowOutsideClick: false,
			        showConfirmButton: false
			    });
			    window.location.href = "${pageContext.request.contextPath}/logout";
			  
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


// Notification Modal
$(document).on('click', '.notificationbell', function(event){
	Swal.fire({
		  title: '<h5 class="m-0" style="color: #28282B;">Notifications</h5>',
		  background: 'white',
		  position: 'top-right',
		  width: 'auto',
		  focusConfirm: false,
		  showCancelButton: false,
		  showConfirmButton: false,
		  allowOutsideClick: true,
		  backdrop:true,
        	willOpen: () => {
        		checkForNotifications();        		
        		litsnotificationitems();
        	 	$(".swal2-container").css({"padding-top":"2rem","padding-right":"1.5rem"});
	        	$(".swal2-popup").css({"width":"21rem" , "padding-bottom":"0.6em"});
	        	$("#swal2-title").css("padding",".5em .5em 0");
	        	$("#swal2-html-container").css("margin","0.1em 1em 0px");
        	},
		  html: 
			  '<div class="notificationbox">' +
					'<div class="notifbox_container d-flex align flex-column overflow-hidden">' +
					
						'<div class="notification_list p-2">' +
							'<div class="notification_item d-none justify-content-between align-items-center py-1">' +
								'<p class="mb-0 text-start"></p>' +
								'<i class="fa-solid fa-eraser" id="deletenotif"></i>' +
							'</div>' +
							'<p class="text-center d-none m-0" id="emptynotif" style="font-size: .8rem;" >You do not have any notification.</p>' +
						'</div>' +
						'<div class="d-flex justify-content-between align-items-center px-2">' +
							'<a id="clearall">Clear all</a>' +
						'</div>' +
					'</div>' +
				'</div> ',
		  
		});
	});

</script>
<!-------------------HTML--------------------->
<Header class="header">
	<div class="header_container displayflex">
		<div class="logo ps-5">
			<h2 id="systemtitle">Input Plan Management System</h2>
		</div>
		<div class="controller displayflex column-gap-2">
			<div class="navigation">
				<ul class="nav nav-pills">
				  <li class="nav-item"><a class="nav-link" href="${pageContext.request.contextPath}/monthlyplan" id="navigation1">Monthly Plan</a></li>
				  <li class="nav-item"><a class="nav-link" href="${pageContext.request.contextPath}/monthlyplanner" id="navigation1b">Monthly Planner</a></li>
				  <li class="nav-item dropdown" id="drop">
				    <a class="nav-link dropdown-toggle" data-bs-toggle="dropdown" href="#" role="button" aria-expanded="false" id="navigation2">Maintenance</a>
				    <ul class="dropdown-menu mt-2">
				      <li><a class="dropdown-item" href="${pageContext.request.contextPath}/machinetype" id="navigation0.1"><i class="fa-solid fa-gears"></i> Machine Type</a></li>
				      <li><a class="dropdown-item" href="${pageContext.request.contextPath}/machine" id="navigation1.1"><i class="fa-solid fa-hard-drive"></i> Machine</a></li>
				      <li><a class="dropdown-item" href="${pageContext.request.contextPath}/item" id="navigation2.1"><i class="fa-solid fa-microchip"></i> Item</a></li>
				      <li><a class="dropdown-item" href="${pageContext.request.contextPath}/plottingsummary" id="navigation3.1"><i class="fa-solid fa-calendar-day"></i> Plotting Summary</a></li>

						<!-- Add another dropdown item here for Screen List -->
				    </ul>
				  </li>
				  
				  <%--Uncomment the items below if need more navigation--%>
<%-- 				  <li class="nav-item"><a class="nav-link" href="${pageContext.request.contextPath}/yourservlet" id="navigation3">navigation 2</a></li> --%> 
<%-- 				  <li class="nav-item"><a class="nav-link" href="${pageContext.request.contextPath}/yourservlet" id="navigation4">navigation 3</a></li> --%>
				  <li class="nav-item"><a class="nav-link" href="${pageContext.request.contextPath}/account" id="navigation3">Accounts</a></li>
				</ul>
			</div>
			<div class="notificationbell">
				<a class="bell p-3 text-dark" style="cursor: pointer;"><i class="fa-solid fa-bell"></i><span id="notif" hidden>0</span></a>
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