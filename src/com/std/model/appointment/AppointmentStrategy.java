/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.std.model.appointment;

/**
 *
 * @author obasekiidemudia
 */

import com.std.model.pattern.RecurrencePattern;

public interface AppointmentStrategy {	
	
	public String getPatternDescription(RecurrencePattern pattern);

}