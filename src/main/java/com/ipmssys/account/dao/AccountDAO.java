package com.ipmssys.account.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

import com.ipmssys.account.model.Account;
import com.ipmssys.configuration.GenericDAO;

public class AccountDAO implements GenericDAO<Account> {

	public Connection con;

	public AccountDAO(Connection con) {
		super();
		this.con = con;
	}

	@Override
	public Account get(Object accountid) throws SQLException {		// used in getting data for edit

		String sql = "SELECT "
						+ "account_id, employee_id, password, first_name, last_name, access_level, email "
					+ "FROM "
						+ "account "
					+ "WHERE "
						+ "account_id = ? ";

		try(PreparedStatement pstmt = con.prepareStatement(sql)){
			pstmt.setInt(1, (Integer)accountid);

			try(ResultSet rs = pstmt.executeQuery()){
				if(rs.next()){
					Account account = new Account();
					account.setAccountid(rs.getInt("ACCOUNT_ID"));
					account.setEmployeeid(rs.getString("EMPLOYEE_ID"));
					account.setPassword(rs.getString("PASSWORD"));
					account.setFirstname(rs.getString("FIRST_NAME"));
					account.setLastname(rs.getString("LAST_NAME"));
					account.setAccesslevel(rs.getInt("ACCESS_LEVEL"));
					account.setEmail(rs.getString("EMAIL"));
					return account;
				}
			}
		}
		return null;
	}

	public Account getByEmployeeID(String employeeid) throws SQLException {

		String sql = "SELECT "
						+ "account_id, employee_id, password, first_name, last_name, access_level, email "
					+ "FROM "
						+ "account "
					+ "WHERE "
						+ "employee_id = ? ";

		try(PreparedStatement pstmt = con.prepareStatement(sql)){
			pstmt.setString(1, employeeid);

			try(ResultSet rs = pstmt.executeQuery()){
				if(rs.next()){
					Account account = new Account();
					account.setAccountid(rs.getInt("ACCOUNT_ID"));
					account.setEmployeeid(rs.getString("EMPLOYEE_ID"));
					account.setPassword(rs.getString("PASSWORD"));
					account.setFirstname(rs.getString("FIRST_NAME"));
					account.setLastname(rs.getString("LAST_NAME"));
					account.setAccesslevel(rs.getInt("ACCESS_LEVEL"));
					account.setEmail(rs.getString("EMAIL"));
					return account;
				}
			}
		}
		return null;
	}

	@Override
	public Account create(Account account) throws SQLException {		// registering new account

		String sql = "INSERT INTO "
						+ "account "
						+ "(account_id, employee_id, password, first_name, last_name, access_level, email, pw_expiration ) "
					+ "VALUES "
						+ "(account_seq.NEXTVAL, ?, ?, ?, ?, ?, ?, ?) " ;

		try(PreparedStatement pstmt = con.prepareStatement(sql)){
			pstmt.setString(1, account.getEmployeeid());
			pstmt.setString(2, account.getPassword());
			pstmt.setString(3, account.getFirstname());
			pstmt.setString(4, account.getLastname());
			pstmt.setInt(5, account.getAccesslevel());
			pstmt.setString(6, account.getEmail());
			pstmt.setTimestamp(7, Timestamp.valueOf(account.getPwexpiration()));
			if(pstmt.executeUpdate() > 0 ){
				return account;
			}
		}
		return null;
	}


	@Override
	public Account update(Account account) throws SQLException {		// updating existing account

		String sql = "UPDATE "
						+ "account "
					+ "SET "
						+ "employee_id = ?, first_name = ?, last_name = ?, access_level = ?, email = ? "
					+ "WHERE "
						+ "account_id = ? ";

		try(PreparedStatement pstmt = con.prepareStatement(sql)){
			pstmt.setString(1, account.getEmployeeid());
			pstmt.setString(2, account.getFirstname());
			pstmt.setString(3, account.getLastname());
			pstmt.setInt(4, account.getAccesslevel());
			pstmt.setString(5, account.getEmail());
			pstmt.setInt(6, account.getAccountid());

			if(pstmt.executeUpdate() > 0){
				return account;
			}
		}
		return null;
	}

	public Account resetpass(Account account) throws SQLException {		// resetting password

		String sql = "UPDATE "
						+ "account "
					+ "SET "
						+ "password = ?, pw_expiration = ? "
					+ "WHERE "
						+ "account_id = ? ";

		try(PreparedStatement pstmt = con.prepareStatement(sql)){

			pstmt.setString(1, account.getPassword());
			pstmt.setTimestamp(2, Timestamp.valueOf(account.getPwexpiration()));
			pstmt.setInt(3, account.getAccountid());

			if(pstmt.executeUpdate() > 0){
				return account;
			}
		}
		return null;
	}

	@Override
	public Account delete(Account account) throws SQLException {		// deleting of account *admin only*
		String sql = "DELETE FROM account WHERE account_id = ? ";

		try(PreparedStatement pstmt = con.prepareStatement(sql)){
			pstmt.setInt(1, account.getAccountid());
			if(pstmt.executeUpdate() > 0){
				return account;
			}
		}
		return null;
	}

	@Override
	public List<Account> listAll() throws SQLException {				// list all data

	List<Account> listAccount = new ArrayList<Account>();

		String sql = "SELECT "
						+ "account_id, employee_id, password, first_name, last_name, access_level, email, pw_expiration "
					+ "FROM "
						+ "account a "
					+ "ORDER BY "
						+ "employee_id ASC ";

		try(PreparedStatement pstmt = con.prepareStatement(sql)){
			try(ResultSet rs = pstmt.executeQuery()){
				while(rs.next()){
					Account account = new Account();
					account.setAccountid(rs.getInt("ACCOUNT_ID"));
					account.setEmployeeid(rs.getString("EMPLOYEE_ID"));
					account.setPassword(rs.getString("PASSWORD"));
					account.setFirstname(rs.getString("FIRST_NAME"));
					account.setLastname(rs.getString("LAST_NAME"));
					account.setAccesslevel(rs.getInt("ACCESS_LEVEL"));
					account.setEmail(rs.getString("EMAIL"));
					Timestamp pwExp = rs.getTimestamp("PW_EXPIRATION");
					account.setPwexpiration(pwExp != null ? pwExp.toLocalDateTime() : null);
					listAccount.add(account);
				}
			}
		}
		return listAccount;
	}
	public List<Account> listAllEmployeeId() throws SQLException {				// list all Employee account data

	List<Account> listAccount = new ArrayList<Account>();

		String sql = "SELECT "
						+ "account_id, employee_id, password, first_name, last_name, access_level, email, pw_expiration "
					+ "FROM "
						+ "account "
					+ "WHERE "
						+ "account_id != 0 "
					+ "ORDER BY "
						+ "employee_id ASC ";

		try(PreparedStatement pstmt = con.prepareStatement(sql)){
			try(ResultSet rs = pstmt.executeQuery()){
				while(rs.next()){
					Account account = new Account();
					account.setAccountid(rs.getInt("ACCOUNT_ID"));
					account.setEmployeeid(rs.getString("EMPLOYEE_ID"));
					account.setPassword(rs.getString("PASSWORD"));
					account.setFirstname(rs.getString("FIRST_NAME"));
					account.setLastname(rs.getString("LAST_NAME"));
					account.setAccesslevel(rs.getInt("ACCESS_LEVEL"));
					account.setEmail(rs.getString("EMAIL"));
					Timestamp pwExp = rs.getTimestamp("PW_EXPIRATION");
					account.setPwexpiration(pwExp != null ? pwExp.toLocalDateTime() : null);
					listAccount.add(account);
				}
			}
		}
		return listAccount;
	}
	@Override
	public Account findDuplicate(Account account) throws SQLException {			// for checking duplicate entry of employee id

		String sql = "SELECT "
						+ "account_id, employee_id, password, first_name, last_name, email "
					+ "FROM "
						+ "account "
					+ "WHERE "
						+ "employee_id = ? ";

		try(PreparedStatement pstmt = con.prepareStatement(sql)){
			pstmt.setString(1, account.getEmployeeid());

			try(ResultSet rs = pstmt.executeQuery()){
				if(rs.next()){

					account.setAccountid(rs.getInt("ACCOUNT_ID"));
					account.setEmployeeid(rs.getString("EMPLOYEE_ID"));
					account.setPassword(rs.getString("PASSWORD"));
					account.setFirstname(rs.getString("FIRST_NAME"));
					account.setLastname(rs.getString("LAST_NAME"));
					account.setEmail(rs.getString("EMAIL"));
					return account;
				}
			}
		}

		return null;
	}

	public Account LoginAccount(Account account) throws SQLException {					// logging in of account

		String sql = "SELECT "
						+ "account_id, employee_id, password, first_name, last_name, access_level, email, pw_expiration "
					+ "FROM "
						+ "account "
					+ "WHERE "
						+ "employee_id = ? AND password = ? ";

		try(PreparedStatement pstmt = con.prepareStatement(sql)){
			pstmt.setString(1, account.getEmployeeid());
			pstmt.setString(2, account.getPassword());
			try(ResultSet rs = pstmt.executeQuery()){
				if(rs.next()){

					account.setAccountid(rs.getInt("ACCOUNT_ID"));
					account.setEmployeeid(rs.getString("EMPLOYEE_ID"));
					account.setPassword(rs.getString("PASSWORD"));
					account.setFirstname(rs.getString("FIRST_NAME"));
					account.setLastname(rs.getString("LAST_NAME"));
					account.setAccesslevel(rs.getInt("ACCESS_LEVEL"));
					account.setEmail(rs.getString("EMAIL"));
					Timestamp pwExp = rs.getTimestamp("PW_EXPIRATION");
					account.setPwexpiration(pwExp != null ? pwExp.toLocalDateTime() : null);
					return account;
				}
			}
		}

		return null;
	}
	public Account findExpiration(Account account) throws SQLException {			// finding expiration date

		String sql = "SELECT "
						+ "account_id, employee_id, password, first_name, last_name, access_level, email, pw_expiration "
					+ "FROM "
						+ "account "
					+ "WHERE "
						+ "employee_id = ? ";

		try(PreparedStatement pstmt = con.prepareStatement(sql)){
			pstmt.setString(1, account.getEmployeeid());

			try(ResultSet rs = pstmt.executeQuery()){
				if(rs.next()){

					account.setAccountid(rs.getInt("ACCOUNT_ID"));
					account.setEmployeeid(rs.getString("EMPLOYEE_ID"));
					account.setPassword(rs.getString("PASSWORD"));
					account.setFirstname(rs.getString("FIRST_NAME"));
					account.setLastname(rs.getString("LAST_NAME"));
					account.setAccesslevel(rs.getInt("ACCESS_LEVEL"));
					account.setEmail(rs.getString("EMAIL"));
					Timestamp pwExp = rs.getTimestamp("PW_EXPIRATION");
					account.setPwexpiration(pwExp != null ? pwExp.toLocalDateTime() : null);
					return account;
				}
			}
		}

		return null;
	}

	public Account findDuplicateUpdate(Account account) throws SQLException {				// find duplicate for update

		String sql = "SELECT "
						+ "account_id, employee_id, first_name, last_name, access_level, email "
					+ "FROM "
						+ "account "
					+ "WHERE "
						+ "employee_id = ? AND first_name = ? AND last_name = ? AND access_level = ? AND email = ? ";

		try(PreparedStatement pstmt = con.prepareStatement(sql)){
			pstmt.setString(1, account.getEmployeeid());
			pstmt.setString(2, account.getFirstname());
			pstmt.setString(3, account.getLastname());
			pstmt.setInt(4, account.getAccesslevel());
			pstmt.setString(5, account.getEmail());
			try(ResultSet rs = pstmt.executeQuery()){
				if(rs.next()){

					account.setAccountid(rs.getInt("ACCOUNT_ID"));
					account.setEmployeeid(rs.getString("EMPLOYEE_ID"));
					account.setFirstname(rs.getString("FIRST_NAME"));
					account.setLastname(rs.getString("LAST_NAME"));
					account.setAccesslevel(rs.getInt("ACCESS_LEVEL"));
					account.setEmail(rs.getString("EMAIL"));
					return account;
				}
			}
		}

		return null;
	}
	public boolean checkaccountexist(Account account) throws SQLException {						// checking account if registered

		String sql = "SELECT "
						+ "1 "
					+ "FROM "
						+ "account "
					+ "WHERE "
						+ "employee_id = ? AND password = ? ";

		try(PreparedStatement pstmt = con.prepareStatement(sql)){
			pstmt.setString(1, account.getEmployeeid());
			pstmt.setString(2, account.getPassword());
			try(ResultSet rs = pstmt.executeQuery()){
				if(rs.next()){
					return true;
				}
			}
		}

		return false;
	}

	public Account ChangePassword(Account account) throws SQLException {						// change password

			String sql = "UPDATE "
							+ "account "
						+ "SET "
							+ "password = ?, pw_expiration = ? "
						+ "WHERE "
							+ "employee_id = ? ";

				try(PreparedStatement pstmt = con.prepareStatement(sql)){
				pstmt.setString(1, account.getPassword());
				pstmt.setTimestamp(2, Timestamp.valueOf(account.getPwexpiration()));
				pstmt.setString(3, account.getEmployeeid());
				if(pstmt.executeUpdate() > 0){
					return account;
				}
			}
		return null;
	}

	public Account ChangeExpiredPassword(Account account) throws SQLException {						// change expired password

		String sql = "UPDATE "
						+ "account "
					+ "SET "
						+ "password = ?, pw_expiration = ? "
					+ "WHERE "
						+ "account_id = ? ";

			try(PreparedStatement pstmt = con.prepareStatement(sql)){
			pstmt.setString(1, account.getPassword());
			pstmt.setTimestamp(2, Timestamp.valueOf(account.getPwexpiration()));
			pstmt.setInt(3, account.getAccountid());
			if(pstmt.executeUpdate() > 0){
				return account;
			}
		}
	return null;
}
}
