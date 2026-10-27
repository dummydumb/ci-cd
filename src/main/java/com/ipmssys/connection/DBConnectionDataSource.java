package com.ipmssys.connection;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.sql.DataSource;


public class DBConnectionDataSource {

	Logger log = Logger.getLogger(DBConnectionDataSource.class.getCanonicalName());
	
    private Connection con;
    private DataSource ds;
    private Context ctx;
    
    public DBConnectionDataSource(String name){
        try{
            ctx = new InitialContext();
            ds = (DataSource)ctx.lookup("java:comp/env/" + name);
        }catch(NamingException ne){
            log.log(Level.SEVERE, "Connection configuration not properly set. DS:{0}", ds);
            ne.printStackTrace();
        }
    }
    
    public Connection getConnection(){
        try{
            con = ds.getConnection();
        }catch(SQLException sqle){
            log.log(Level.SEVERE, "Failed to create database connection. CON:{0}", con);
            sqle.printStackTrace();
        }
        return con;
    }
}
