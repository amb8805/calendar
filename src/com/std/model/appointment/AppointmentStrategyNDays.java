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

import com.std.model.pattern.NDaysPattern;
import com.std.model.pattern.RecurrencePattern;

public class AppointmentStrategyNDays implements AppointmentStrategy {
	
	private static final SimpleDateFormat FORMAT = new SimpleDateFormat("EEE, d MMM yyyy 'at' h:mm aa");

	public String getPatternDescription(RecurrencePattern pattern) {
		String text = "";
		
		// generate the description string for NDaysPattern
		NDaysPattern ptt = (NDaysPattern)pattern;
		if(ptt.getinstanceEvery() == 1)
			text = "recurs every day";
		else if(ptt.getinstanceEvery() > 1)
			text = "recurs every " + ptt.getinstanceEvery() + " days ";
		
		// append the RecurrencePattern dateRange data
		if(text.length() > 0)
			text += " from " + FORMAT.format(pattern.getRange().getStartDate())
				+ " to " + FORMAT.format(pattern.getRange().getEndDate());
		
		return text;
	}

}