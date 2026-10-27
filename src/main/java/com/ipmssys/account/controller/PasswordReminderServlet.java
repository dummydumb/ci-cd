package com.ipmssys.account.controller;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

import org.quartz.CronScheduleBuilder;
import org.quartz.JobDetail;
import org.quartz.Trigger;
import org.quartz.TriggerBuilder;
import org.quartz.JobBuilder;
import org.quartz.Scheduler;
import org.quartz.SchedulerException;
import org.quartz.impl.StdSchedulerFactory;

import com.ipmssys.account.model.PasswordReminder;
@WebListener
public class PasswordReminderServlet implements ServletContextListener {

	private Scheduler scheduler;

    public void contextInitialized(ServletContextEvent arg0) {
    	try {
            // Create scheduler
            scheduler = StdSchedulerFactory.getDefaultScheduler();

            // Define job and tie it to EmployeeListJob class
            JobDetail job = JobBuilder.newJob(PasswordReminder.class)
                    .withIdentity("employeeListJob", "group1")
                    .build();

            // Trigger that fires every day at 10:00 AM
            Trigger trigger = TriggerBuilder.newTrigger()
                    .withIdentity("dailyTrigger", "group1")
                    .withSchedule(CronScheduleBuilder.dailyAtHourAndMinute(15, 11)) // 3:00 PM daily
                    .build();

            // Schedule the job
            scheduler.scheduleJob(job, trigger);

            // Start scheduler
            scheduler.start();

            System.out.println("Quartz scheduler started. Job scheduled to run daily at 10 AM.");
        } catch (SchedulerException e) {
            e.printStackTrace();
        }
    }

	@Override
	public void contextDestroyed(ServletContextEvent arg0) {
		 if (scheduler != null) {
	            try {
	                scheduler.shutdown();
	                System.out.println("Quartz scheduler shut down.");
	            } catch (SchedulerException e) {
	                e.printStackTrace();
	            }
	        }
	}
}
