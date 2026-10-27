package com.ipmssys.login.controller;

import java.io.IOException;
import java.sql.Connection;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.ipmssys.account.dao.AccountDAO;
import com.ipmssys.account.model.Account;
import com.ipmssys.connection.DBConnectionDataSource;
import com.ipmssys.configuration.GlobalVariables;

import local.password.LocalSystemPasswordPolicy;
import local.password.PasswordPolicy;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
	static final String PASSWORD_ALGORITHM = "MD5";
  
	static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("MMMM dd, yyyy");
	
    public LoginServlet() {
        super();
       
    }

		protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		    AccountDAO accountDAO = null;
		    DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);

		    try (Connection con = dbConnection.getConnection()) {
		        if (checkSession(request)) {
		            HttpSession session = request.getSession(false);
		            accountDAO = new AccountDAO(con);
		            String currentUser = (String) session.getAttribute("currentSessionUser");

		            if (accountDAO.getByEmployeeID(currentUser) != null && !currentUser.isEmpty()) {
		                response.sendRedirect(GlobalVariables.ScreenAfterLoggedIn_servlet);
		            }
		        } else {
		            RequestDispatcher rd = request.getRequestDispatcher(GlobalVariables.LoginScreen_jsp);
		            rd.forward(request, response);
		        }
		    } catch (Exception e) {
		        e.printStackTrace();
		    }
		}	
	
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		String strEmployeeid = request.getParameter("employeeid").toUpperCase();
		String strPassword = request.getParameter("password");
		String message = "Unexpected server error occured, please check your transaction";
		AccountDAO accountDAO = null;
		
		DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
		try(Connection con = dbConnection.getConnection()){
			accountDAO = new AccountDAO(con);
			
			PasswordPolicy passwordPolicy = new LocalSystemPasswordPolicy(strPassword);
			String encryptedPassword = passwordPolicy.getEncryptedPassword(PASSWORD_ALGORITHM);
			
			Account existAccount = accountDAO.LoginAccount(new Account(strEmployeeid, encryptedPassword));
			
			if(existAccount == null){
				
				message = "Login Failed. Incorrect Employee ID or Password.";
	    		request.setAttribute("message", message);
	    		request.setAttribute("failed", true);
				RequestDispatcher rd = request.getRequestDispatcher(GlobalVariables.LoginScreen_jsp);
	    		rd.forward(request, response);	
			}
			
			if (existAccount.getPwexpiration() != null &&
				(existAccount.getPwexpiration().isBefore(LocalDateTime.now()) ||
				existAccount.getPwexpiration().isEqual(LocalDateTime.now()))) {

				request.setAttribute("expired", true);
				request.setAttribute("expiredEmployeeid", existAccount.getEmployeeid().toUpperCase());
				request.setAttribute("expiredAccountid", existAccount.getAccountid());
				request.setAttribute("expiredPassword", existAccount.getPassword());
				RequestDispatcher rd = request.getRequestDispatcher(GlobalVariables.LoginScreen_jsp);
			    rd.forward(request, response);
			}else{
				
				HttpSession session = request.getSession();
				session.setAttribute("currentSessionUser",existAccount.getEmployeeid().toUpperCase());
				session.setAttribute("currentaccountid",existAccount.getAccountid());
				session.setAttribute("currentaccesslevel",existAccount.getAccesslevel());
				session.setAttribute("currentpwexpiration",existAccount.getPwexpiration().format(FORMATTER));
				response.sendRedirect(GlobalVariables.ScreenAfterLoggedIn_servlet);
			}
			
		}catch(Exception e){
			e.printStackTrace();
			response.setStatus(400);
		}
		
	}
	private boolean checkSession(HttpServletRequest request) {
	    boolean blResult = false;
	    HttpSession session = request.getSession(false);

	    if (session != null) {
	        String currentUser = (String) session.getAttribute("currentSessionUser");
	        if (currentUser != null && !currentUser.isEmpty()) {
	            blResult = true;
	        }
	    }
	    return blResult;
	}
//	private boolean checkSession(HttpServletRequest request) throws NullPointerException{
//		
//		boolean blResult = false;
//		HttpSession session = request.getSession(false);
//		
//		if(session != null){
//			if(session.getAttribute("currentSessionUser") != null && (String)session.getAttribute("currentSessionUser") != ""){
//				blResult = true;
//			}
//		}
//		return blResult;
//	}

}
