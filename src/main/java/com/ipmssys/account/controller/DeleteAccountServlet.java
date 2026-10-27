package com.ipmssys.account.controller;

import java.io.IOException;
import java.sql.Connection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.ipmssys.configuration.GlobalVariables;
import com.ipmssys.connection.DBConnectionDataSource;
import com.ipmssys.account.dao.AccountDAO;
import com.ipmssys.account.model.Account;

@WebServlet("/account/d")
public class DeleteAccountServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
       
    public DeleteAccountServlet() {
        super();
    }
    
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		Integer intAccountid = request.getParameter("id") != null ? Integer.parseInt(request.getParameter("id")) : 0;
		String message = "Unexpected server error occured, please check your transaction";
		boolean blResult = true;
		
		DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
		try(Connection con = dbConnection.getConnection()){
			con.setAutoCommit(false);
			
			AccountDAO 			maintenanceDAO 		= new AccountDAO(con);
			Account existaccount = maintenanceDAO.get(intAccountid);
			
			if (existaccount == null) {
				response.setStatus(400);
				message = "Data does not exist!";
				System.out.println("MESSAGE: Data does not exist.");
				blResult = false;
			}
			if (blResult) {
				/*--- Use this if NO NEED for notification ---*/
				if (maintenanceDAO.delete(existaccount) != null) {
					con.commit();
					response.setStatus(200);
					message = existaccount.getEmployeeid() + " has been deleted.";
				}else {
					response.setStatus(400);
				}
				
				/*--- Use this if notification is NEEDED in the system ---*/
//				NotificationDAO 	notificationDAO 	= new NotificationDAO(con);
//				String strNotifDescription 		= existaccount.getEmployeeid() + " has been deleted.";
//				Notification newNotification 	= new Notification(strNotifDescription);
//				if ((maintenanceDAO.delete(existaccount) != null) && (notificationDAO.create(newNotification) != null)) {
//					con.commit();
//					response.setStatus(200);
//					message = existaccount.getEmployeeid() + " has been deleted.";
//				}else {
//					response.setStatus(400);
//				}
				
			}
		}catch(Exception e){
			e.printStackTrace();
			response.setStatus(400);
		}
		response.getOutputStream().write(message.getBytes());
	}

}
