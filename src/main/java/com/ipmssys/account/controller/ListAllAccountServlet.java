package com.ipmssys.account.controller;

import java.io.IOException;
import java.sql.Connection;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.gson.Gson;
import com.ipmssys.account.dao.AccountDAO;
import com.ipmssys.account.model.Account;
import com.ipmssys.configuration.GlobalVariables;
import com.ipmssys.connection.DBConnectionDataSource;

@WebServlet("/account/l")
public class ListAllAccountServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
    public ListAllAccountServlet() {
        super();
    }
		
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		
		String message = "Unexpected error occured, please check your transaction.";
		
		DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
		
		try(Connection con = dbConnection.getConnection()){
			
//			HttpSession session = request.getSession(false);
			
			AccountDAO accountDAO = new AccountDAO(con);
			
				List<Account> listAccount = accountDAO.listAll();
				
				Gson gson = new Gson();
				gson.serializeNulls();
				message = gson.toJson(listAccount);
				response.setContentType("application.json");
				
			
		}catch (Exception e){
			System.out.println("LocalDateTime.now().format(FORMATTER)" + " " + request.getRequestURI());
			e.printStackTrace(); 
		}
		
		response.setCharacterEncoding("UTF-8");
		response.getWriter().write(message);
	}
}