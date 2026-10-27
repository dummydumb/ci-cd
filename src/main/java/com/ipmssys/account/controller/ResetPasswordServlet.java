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

@WebServlet(urlPatterns = {"/accounts/rp"})
public class ResetPasswordServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
	static final String PASSWORD_ALGORITHM = "MD5";
	
    public ResetPasswordServlet() {
        super();
        // TODO Auto-generated constructor stub
    }

	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		Integer intAccountId = request.getParameter("id") != null ? Integer.parseInt(request.getParameter("id")) : 0;
		String message = "Unexpected server error occured, please check your transaction.";
		
		
		DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
		try(Connection con = dbConnection.getConnection()){
			con.setAutoCommit(false);
			AccountDAO accountDAO = new AccountDAO(con);
			Account existAccount = accountDAO.get(intAccountId);
		
			if(existAccount != null){
				
				//User Employee Number as Password
				StringBuilder strPassword = new StringBuilder(existAccount.getEmployeeid().toLowerCase() + ".");
				strPassword.replace(0, 1, existAccount.getEmployeeid().substring(0, 1));
		
				PasswordPolicy passwordPolicy = new LocalSystemPasswordPolicy(strPassword.toString());
				String strAccountPassword = passwordPolicy.getEncryptedPassword(PASSWORD_ALGORITHM);
				LocalDateTime strPasswordExpiration = LocalDateTime.now().plusDays(90);
				
				Account resetPassword = new Account(intAccountId,strAccountPassword,strPasswordExpiration);
		
				if(accountDAO.resetpass(resetPassword) != null){
					con.commit();
					message = "Password reset was proceeded successfully. The new password is capitalized first letter of employee number with a dot at the end. (e.g. Pmm12345.)";
					response.setStatus(200);
				}
				
			}else{
				message = "No account was found.";
				response.setStatus(400);
			}

		}catch (Exception e) {
			e.printStackTrace();
		}
		response.getOutputStream().write(message.getBytes());		
	}
}
