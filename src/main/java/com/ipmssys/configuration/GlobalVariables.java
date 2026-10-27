package com.ipmssys.configuration;

public class GlobalVariables {
	
	/*  Edit your database connection  */ 
    public static final String DB_Connection 				= "jdbc/pool/IPMSSYS";		
    public static final String System_Name 					= "IPMSSYS";		
    
    
    /*  Edit Jsp path here  */ 
    public static final String LoginScreen_jsp 				= "/jsp/Login/Login.jsp";
    public static final String ADLoginScreen_jsp 			= "/ADjsp/Login/ADLogin.jsp";
    public static final String Ht_LoginScreen_jsp 			= "/jsp/HT/HTLogin.jsp";
    public static final String HT_MainMenu_jsp 				= "/jsp/HT/HTMainMenu.jsp";	
    public static final String AccountNotFound_servlet 		= "/jsp/Login/AccountNotFound.jsp";
   
    /*  Edit Servlet url based on your system name  */ 
    
    public static final String ADLoginScreen_servlet 		= "/IPMSSYS/loginad";
    public static final String ADScreenAfterLoggedIn_servlet = "/IPMSSYS/accountad";
    
    public static final String LoginScreen_servlet 			= "/IPMSSYS/login";
    public static final String ScreenAfterLoggedIn_servlet 	= "/IPMSSYS/account";
}
