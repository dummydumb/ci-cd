package com.ipmssys.account.model;

import java.io.Serializable;
import java.time.LocalDateTime;

public class Account implements Serializable {
	
	private static final long serialVersionUID = 1L;
	
	public Account (){
		
	}
	// *add more if needed
	private Integer accountid;
	private String employeeid;
	private String password;
	private String firstname;
	private String lastname;
	private Integer accesslevel;
	private String email;
	private LocalDateTime pwexpiration;

	
	
	
	public Account(String employeeid, String password, String firstname,
			String lastname, Integer accesslevel, String email,
			LocalDateTime pwexpiration) {
		super();
		this.employeeid = employeeid;
		this.password = password;
		this.firstname = firstname;
		this.lastname = lastname;
		this.accesslevel = accesslevel;
		this.email = email;
		this.pwexpiration = pwexpiration;
	}

	public Account(Integer accountid) {
		super();
		this.accountid = accountid;
	}

	public Account(String employeeid, String password) {	
		super();
		this.employeeid = employeeid;
		this.password = password;
	}

	
	public Account(Integer accountid, String firstname) {
		super();
		this.accountid = accountid;
		this.firstname = firstname;
	}

	public Account(String employeeid, String firstname, String lastname, Integer accesslevel, String email) {
		super();
		this.employeeid = employeeid;
		this.firstname = firstname;
		this.lastname = lastname;
		this.accesslevel = accesslevel;
		this.email = email;
	}
	
	public Account(String employeeid) {
		super();
		this.employeeid = employeeid;
	}
	
	public Account(String employeeid, String password, String firstname,
			String lastname, LocalDateTime pwexpiration) {
		super();
		this.employeeid = employeeid;
		this.password = password;
		this.firstname = firstname;
		this.lastname = lastname;
		this.pwexpiration = pwexpiration;
	}
	
	public Account(Integer accountid, String password,
			LocalDateTime pwexpiration) {
		super();
		this.accountid = accountid;
		this.password = password;
		this.pwexpiration = pwexpiration;
	}
	
	// Getters and Setters 
	
	public Integer getAccountid() {
		return accountid;
	}
	public void setAccountid(Integer accountid) {
		this.accountid = accountid;
	}
	public String getEmployeeid() {
		return employeeid;
	}
	public void setEmployeeid(String employeeid) {
		this.employeeid = employeeid;
	}
	public String getPassword() {
		return password;
	}
	public void setPassword(String password) {
		this.password = password;
	}
	public String getFirstname() {
		return firstname;
	}
	public void setFirstname(String firstname) {
		this.firstname = firstname;
	}
	public String getLastname() {
		return lastname;
	}
	public void setLastname(String lastname) {
		this.lastname = lastname;
	}
	public Integer getAccesslevel() {
		return accesslevel;
	}
	public void setAccesslevel(Integer accesslevel) {
		this.accesslevel = accesslevel;
	}
	public String getEmail() {
		return email;
	}
	public void setEmail(String email) {
		this.email = email;
	}
	public LocalDateTime getPwexpiration() {
		return pwexpiration;
	}
	public void setPwexpiration(LocalDateTime pwexpiration) {
		this.pwexpiration = pwexpiration;
	}
	public static long getSerialversionuid() {
		return serialVersionUID;
	}	
	
	
}
