package com.ipmssys.account.controller;

import java.io.IOException;
import java.sql.Connection;
import java.time.LocalDateTime;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.ipmssys.account.dao.AccountDAO;
import com.ipmssys.account.model.Account;
import com.ipmssys.configuration.GlobalVariables;
import com.ipmssys.connection.DBConnectionDataSource;

import local.password.LocalSystemPasswordPolicy;
import local.password.PasswordPolicy;

@WebServlet(urlPatterns = {"/accounts/cp"})
public class ChangePasswordServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
	static final String PASSWORD_ALGORITHM = "MD5";

    public ChangePasswordServlet() {
        super();
       
    }
	
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		String strOldPassword = request.getParameter("password");
		String strNewPassword = request.getParameter("newpassword");
		String message = "Unexpected server error occured, please check your transaction";
		AccountDAO accountDAO = null;
		
		DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
		try(Connection con = dbConnection.getConnection()){
			con.setAutoCommit(false);
			accountDAO = new AccountDAO(con);
			
			PasswordPolicy passwordPolicy = new LocalSystemPasswordPolicy(strOldPassword);		
			
			HttpSession session = request.getSession(false);
			Integer intAccountid = (Integer) session.getAttribute("currentaccountid");
			String strEmployeeid = (String) session.getAttribute("currentSessionUser");
			Account existAccount = accountDAO.get(intAccountid);
			System.out.println("Account: " + existAccount);
			if(existAccount != null){	
				
				 existAccount.setPassword(passwordPolicy.getEncryptedPassword(PASSWORD_ALGORITHM));
				
				if(accountDAO.checkaccountexist(existAccount)){
					
					passwordPolicy = new LocalSystemPasswordPolicy(strNewPassword);

					if(!passwordPolicy.isValid()){
						if(!passwordPolicy.isValidLength()){
							message = "Failed to update. Password does not meet the required length.";
						}else{
							message = "Failed to update. Password does not meet the required complexity.";
						}
						response.setStatus(400);
					}else{
						existAccount.setPassword(passwordPolicy.getEncryptedPassword(PASSWORD_ALGORITHM));
						existAccount.setEmployeeid(strEmployeeid);
						existAccount.setPwexpiration(LocalDateTime.now().plusDays(90));
						if (accountDAO.ChangePassword(existAccount) != null) {
							con.commit();
							message = "Password updated successfully.";
							response.setStatus(200);
						}else {
							response.setStatus(400);
						}
					}
				}else{
					message = "Incorrect old password. Please try again.";
					response.setStatus(400);
				}

			}else{
				message = "Account Does not Exist";
				response.setStatus(400);
			}
			
		}catch(Exception e){
			e.printStackTrace();
			response.setStatus(400);		
		}
		response.getOutputStream().write(message.getBytes());
}
	
}
