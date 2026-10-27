package com.ipmssys.configuration;

import java.sql.SQLException;
import java.util.List;

public interface GenericDAO<T> {
	
		public T get(Object id) throws SQLException;
		
		public T create(T t)  throws SQLException;
		
		public T update(T t)  throws SQLException;
		
		public T delete(T t)  throws SQLException;
		
		public List<T> listAll()  throws SQLException;
		
		public T findDuplicate(T t)  throws SQLException;

}
