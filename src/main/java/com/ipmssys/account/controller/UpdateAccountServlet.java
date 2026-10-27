package com.ipmssys.account.controller;

import java.io.IOException;
import java.sql.Connection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.ipmssys.account.dao.AccountDAO;
import com.ipmssys.account.model.Account;
import com.ipmssys.configuration.GlobalVariables;
import com.ipmssys.connection.DBConnectionDataSource;

@WebServlet("/account/u")
public class UpdateAccountServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
    public UpdateAccountServlet() {
        super();
        // TODO Auto-generated constructor stub
    }
    
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		Integer intAccountid = request.getParameter("id") != null ? Integer.parseInt(request.getParameter("id")) : 0;
		DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
		
		try(Connection con =dbConnection.getConnection()){
			AccountDAO accountDAO = new AccountDAO(con);
			Account existAccount = accountDAO.get(intAccountid);
			
			if(existAccount != null){
				GsonBuilder gsonBuilder = new GsonBuilder();
				gsonBuilder.serializeNulls();
		     	Gson gson = gsonBuilder.create();
				String json = gson.toJson(existAccount);
				response.setContentType("application/json");
				response.setCharacterEncoding("UTF-8");
				response.getWriter().write(json);
			}else{
				response.setStatus(400);
				response.getOutputStream().write("Data does not exist!".getBytes());
			}
			
		}catch(Exception e){
			e.printStackTrace();
			response.setStatus(400);
			response.getOutputStream().write("An error was encountered during processing.".getBytes());
		}
	}

	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		Integer intAccountid	= request.getParameter("id")  != null ? Integer.parseInt(request.getParameter("id")) : 0;
		String strEmployeeid 	= request.getParameter("employeeid").toUpperCase();
		String strFirstname 	= request.getParameter("firstname");
		String strLastname 		= request.getParameter("lastname");
		Integer intAccesslevel	= request.getParameter("accesslevel")  != null ? Integer.parseInt(request.getParameter("accesslevel")) : 0;
		String strEmail 		= request.getParameter("email").toLowerCase();
		String message 			= "Unexpected server error occured, please check your transaction";
		boolean blResult = true;
		
		System.out.println(intAccountid + " " + strEmployeeid + " " + strFirstname + " " + strLastname + " " + intAccesslevel + " " + strEmail);
		
		DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
		try(Connection con = dbConnection.getConnection()){
			con.setAutoCommit(false);
			
			AccountDAO accountDAO 	= new AccountDAO(con);
			Account account 		= accountDAO.get(intAccountid);
			Account existAccount 	= accountDAO.findDuplicateUpdate(new Account(strEmployeeid,strFirstname,strLastname, intAccesslevel, strEmail));
			
			if(account == null){
				System.out.println("MESSAGE: Data does not exist.");
				response.setStatus(400);
				message = "Failed to update. The item does not exist. It might have been deleted by other user.";	
				blResult =  false;
			}
			
			if (existAccount != null) {
				System.out.println("MESSAGE: Account already exist.");
				response.setStatus(400);
				message = "Failed to update. The Account already exist";
				blResult = false;
			}
			
			if (blResult){
				account.setFirstname(strFirstname);
				account.setLastname(strLastname);
				account.setEmail(strEmail);
				account.setAccesslevel(intAccesslevel);
				if (accountDAO.update(account) != null) {
					con.commit();
					response.setStatus(200);
					message = account.getEmployeeid() +" was updated successfully.";
				}else {
					response.setStatus(400);
				}
			}
		}catch(Exception e){
			e.printStackTrace();
		}
		response.getOutputStream().write(message.getBytes());
	}
}
