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

@WebServlet(urlPatterns = {"/accounts/cep"})
public class ChangeExpiredPasswordServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
	static final String PASSWORD_ALGORITHM = "MD5";

    public ChangeExpiredPasswordServlet() {
        super();
       
    }
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
			String message = "Unexpected server error occured, please check your transaction";
			AccountDAO accountDAO = null;
			
			DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
			try(Connection con = dbConnection.getConnection()){
				con.setAutoCommit(false);
				accountDAO = new AccountDAO(con);
				
					Integer intAccountid 	= request.getParameter("id") != null ? Integer.parseInt(request.getParameter("id")) : 0;
					String strNewPassword 	= request.getParameter("newpassword");
					Account existAccount 	= accountDAO.get(intAccountid);
					System.out.println("Exist Account id: " + existAccount.getAccountid());
						
							PasswordPolicy passwordPolicy = new LocalSystemPasswordPolicy(strNewPassword);
							if(!passwordPolicy.isValid()){
								if(!passwordPolicy.isValidLength()){
									message = "Failed to update. Password does not meet the required length.";
								}else{
									message = "Failed to update. Password does not meet the required complexity.";
								}
								response.setStatus(400);
							}else{
								existAccount.setPassword(passwordPolicy.getEncryptedPassword(PASSWORD_ALGORITHM));
								existAccount.setPwexpiration(LocalDateTime.now().plusDays(90));
								existAccount.setAccountid(intAccountid);
								System.out.println("Employee id: " + existAccount.getEmployeeid());
								if (accountDAO.ChangeExpiredPassword(existAccount) != null) {
									con.commit();
									message = "Password for "+ existAccount.getEmployeeid() +" has been successfully updated.";
									response.setStatus(200);
								}
								else {
									message = "Password not updated. Unexpected server error occured, please check your transaction.";
									response.setStatus(400);
								}
							}
					System.out.println("Expired Exist Account: " 	+ existAccount.getAccountid());
					System.out.println("strNewPassword : " 			+ strNewPassword);
			
					System.out.println("Encrypted Old Password: " 	+ existAccount.getPassword());
					System.out.println("Encrypted New Password: " 	+ passwordPolicy.getEncryptedPassword(PASSWORD_ALGORITHM));
				
			}catch(Exception e){
				e.printStackTrace();
				response.setStatus(400);		
			}
			response.getOutputStream().write(message.getBytes());
	}
	
}
