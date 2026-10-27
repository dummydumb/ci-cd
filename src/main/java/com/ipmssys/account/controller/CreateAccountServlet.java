package com.ipmssys.account.controller;

import java.io.IOException;
import java.sql.Connection;
import java.time.LocalDateTime;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.ipmssys.account.dao.AccountDAO;
import com.ipmssys.account.model.Account;
import com.ipmssys.configuration.GlobalVariables;
import com.ipmssys.connection.DBConnectionDataSource;

import local.password.LocalSystemPasswordPolicy;
import local.password.PasswordPolicy;

@WebServlet(urlPatterns = { "/account/n" })
public class CreateAccountServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
	static final String PASSWORD_ALGORITHM = "MD5";
	
    public CreateAccountServlet() {
        super();
        // TODO Auto-generated constructor stub
    }
    
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		String strEmployeeid 		= request.getParameter("employeeid").toUpperCase();
		StringBuilder strPassword 	= new StringBuilder();
		String strFirstname 		= request.getParameter("firstname");
		String strLastname 			= request.getParameter("lastname");
		Integer intAccesslevel 		= request.getParameter("accesslevel") != null ? Integer.parseInt(request.getParameter("accesslevel")) : 0;
		String strEmail 			= request.getParameter("email").toLowerCase();
		String message 				= "Unexpected server error occured, please check your transaction";
		boolean blResult = true;
		
		DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);

		//User Employee Number as Password
		strPassword.append(strEmployeeid.toLowerCase() + ".");
		strPassword.replace(0, 1, strEmployeeid.substring(0, 1));
				
		try(Connection con = dbConnection.getConnection()){
			con.setAutoCommit(false);
			
			AccountDAO accountDAO = new AccountDAO(con);
			Account existAccount = accountDAO.findDuplicate(new Account(strEmployeeid));
			
			if(existAccount != null){
				System.out.println("MESSAGE: Account already exist.");
				response.setStatus(400);
				message = "Failed to Create. The Account already exist";
				blResult = false;
			}
			
			if (blResult) {
				
				PasswordPolicy passwordPolicy = new LocalSystemPasswordPolicy(strPassword.toString());
				String strAccountPassword = passwordPolicy.getEncryptedPassword(PASSWORD_ALGORITHM);
				LocalDateTime strPasswordExpiration = LocalDateTime.now().plusDays(90);
				Account newAccount = new Account(strEmployeeid,strAccountPassword,strFirstname,strLastname,intAccesslevel,strEmail,strPasswordExpiration); 
				
				/*--- Use this if NO NEED for notification ---*/
//				if (accountDAO.create(newAccount) != null){																
//					con.commit();
//					System.out.println("MESSAGE: New Account was created successfully.");
//					message = strEmployeeid + " was registered successfully.  The default password is capitalized first letter of your employee number with a dot at the end. (e.g. Pmm12345.)";
//					response.setStatus(200);
//				}else {
//					response.setStatus(400);
//				}
				
				/*--- Use this if notification is NEEDED in the system ---*/	
				if ((accountDAO.create(newAccount) != null)){		
					con.commit();
					message = strEmployeeid + " was registered successfully.  The default password is capitalized first letter of your employee number with a dot at the end. (e.g. Pmm12345.)";
					response.setStatus(200);
				}else {
					response.setStatus(400);
				}
				
				
			}
		}catch(Exception e){
			e.printStackTrace();
			response.setStatus(400);
		}
		response.getOutputStream().write(message.getBytes());
	}
}
