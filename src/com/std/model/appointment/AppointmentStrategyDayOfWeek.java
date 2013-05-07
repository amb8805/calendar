/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.std.model.appointment;

/**
 *
 * @author obasekiidemudia
 */
import java.text.SimpleDateFormat;

import com.std.model.pattern.DayOfWeekPattern;
import com.std.model.pattern.RecurrencePattern;

public class AppointmentStrategyDayOfWeek implements AppointmentStrategy {
	
	private static final SimpleDateFormat FORMAT = new SimpleDateFormat("EEE, d MMM yyyy 'at' h:mm aa");
	private static final String[] dayNames = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"};

	public String getPatternDescription(RecurrencePattern pattern) {
		String text = "";
		
		// generate the description string for DayOfWeekPattern
		DayOfWeekPattern ptt = (DayOfWeekPattern)pattern;
		boolean[] days = ptt.getDays();
		
		for(int i = 0; i < days.length; i++){
			if(days[i])
				text += ", " + dayNames[i];
		}
		
		if(text.length() > 0){
			text = text.substring(2); // Cuts off the first ", " from the string
			text = "recurs on " + text;
			
			// append the RecurrencePattern dateRange data
			text += " from " + FORMAT.format(pattern.getRange().getStartDate())
					+ " to " + FORMAT.format(pattern.getRange().getEndDate());
		}			
		
		return text;
	}

}