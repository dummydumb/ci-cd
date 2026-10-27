package com.ipmssys.account.model;

import java.sql.Connection;
import java.time.LocalDate;
import java.util.List;
import java.time.format.DateTimeFormatter;

import org.quartz.Job;
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;

import com.ipmssys.account.dao.AccountDAO;
import com.ipmssys.configuration.GlobalVariables;
import com.ipmssys.connection.DBConnectionDataSource;
import com.mail.service.MailSenderService;

public class PasswordReminder implements Job {
	static final DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MMMM d, yyyy");
	
	@Override
	public void execute(JobExecutionContext context) throws JobExecutionException {
		String sender 			= "pmmlocaldev@murata.com";
		String strCc 			= "";
		String strBcc 			= "";
		String strSubject 		= "["+GlobalVariables.System_Name+"] - Password expiration notice.";
		String host = "172.24.128.80";
		int port = 25;
		
		DBConnectionDataSource dbConnection = new DBConnectionDataSource(GlobalVariables.DB_Connection);
	
		try(Connection con = dbConnection.getConnection()){
			AccountDAO accountDAO = new AccountDAO(con);
			
			List<Account> listAccount = accountDAO.listAll();
			
			for (Account account : listAccount) {
			    LocalDate beforeExpiry = account.getPwexpiration().minusDays(1).toLocalDate();
			    
			    if(LocalDate.now().equals(beforeExpiry)){
			    	String strBody = "<html>"
						            + "<body style=\"font-family: Arial, sans-serif; line-height: 1.5; color: #333;\">"
							            + "<h5 style=\"margin: 0 0 10px 0; font-weight: 600; color: #222;\">Dear Mr./Ms. "+ account.getFirstname() + "</h5>"
							            + "<p style=\"margin: 0 0 5px 0; font-size: 16px;\">This is a friendly reminder that your current password will expire on <strong>"+ account.getPwexpiration().toLocalDate().format(formatter) + ".</strong> <br>To ensure uninterrupted access to your account, please update your password before this date.</p>"  
							            + "<a style=\"font-size: 16px;\" href=\"http://localhost:8080/LocalSystemStandardTemplate/login\">Local System Template</a>"
							            + "<h5 style=\"margin: 20px 0 10px 0; font-weight: 600; color: #222;\">Why change your password?</h5>"
							            + "<p style=\"margin: 0 0 20px 0; font-size: 16px;\">Regularly updating your password helps protect your account and keeps your information secure.</p>\n"  
							            + "<p style=\"color: #d32f2f; font-weight: bold; font-size: 14px; margin-top: 30px;\">** Note: This is a system generated email. Do not reply. **</p>"  	
						            + "</body>"
					            + "</html>";
			    	
					try {
						MailSenderService mailSenderService = new MailSenderService(host, port);
						mailSenderService.sendEmail(sender, account.getEmail(), strCc, strBcc, strSubject, strBody);
							System.out.println("Password expired: " + account.getFirstname());
						} catch (Exception e) {
								e.printStackTrace();
					}
			    }
			}
			
		}catch (Exception e){
			e.printStackTrace(); 
		}

	}
}
