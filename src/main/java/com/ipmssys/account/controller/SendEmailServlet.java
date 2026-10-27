package com.ipmssys.account.controller;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.ipmssys.configuration.GlobalVariables;
import com.mail.service.MailSenderService;


@WebServlet(urlPatterns = {"/accounts/sm"})
@MultipartConfig
public class SendEmailServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
	static final String PASSWORD_ALGORITHM = "MD5";
	
    public SendEmailServlet() {
        super();
    }

	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		
		String strEmployeeid 	= request.getParameter("employeeid");
		String message 			= "Unexpected server error occured, please check your transaction.";

		/* Mail Variables */
		String vcode			= request.getParameter("verificationcode");
		String sender 			= "pmmlocaldev@murata.com";
		String strTo 			= request.getParameter("to");
		String strCc 			= "";
		String strBcc 			= "";
		String strSubject 		= "["+GlobalVariables.System_Name+"] - Forgot Password Verification Code: [" + strEmployeeid+ "]";
	    String strBody 			= "<html>"
						            + "<body>"
							            + "<p>We received a request to reset the password for your account. To proceed, please use the verification code below: </p>"
							            + "<p><h2><strong>" + vcode + "</strong></h2></p>"  				
							            + "<p>Enter this code on the password reset modal to verify your identity and set a new password.</p>"  
							            + "<p>If you did not request a password reset, please disregard this email.</p>\n" 
							            + "<p style=\"color: red;font-weight:bold; font-size: 14px;\">** Note: This is a system generated email. Do not reply. **</p>"  	
						            + "</body>"
					            + "</html>";
		String host = "172.24.128.80";
		int port = 25;
				
				try {
					MailSenderService mailSenderService = new MailSenderService(host, port);

					if (mailSenderService.sendEmail(sender, strTo, strCc, strBcc, strSubject, strBody)) {
						message = "The verification code has been sent to your Murata email.";
						System.out.println(message);
					}else {
						message = "Mail sending failed!";
						System.out.println(message);
						response.setStatus(400);
					}
					
				} catch (Exception e) {
					e.printStackTrace();
				}
		
		response.getOutputStream().write(message.getBytes());		
	}
}
