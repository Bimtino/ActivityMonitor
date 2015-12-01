using Toybox.WatchUi as Ui;
using Toybox.Graphics as Graphics;
using Toybox.System as System;

class ActivityMonitorView extends Ui.DataField {

    hidden const CENTER = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
    hidden const LEFT = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
    hidden const RIGHT = Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER;
    hidden const HEADER_FONT = Graphics.FONT_XTINY;
    hidden const VALUE_FONT = Graphics.FONT_NUMBER_MEDIUM;
    hidden const HOT_FONT = Graphics.FONT_NUMBER_HOT;
    hidden const ZERO_TIME = "0:00";
    hidden const ZERO_DISTANCE = "0.0";
    hidden const RELEASE = "1.0.3";
    
    hidden var kmOrMileInMeters = 1000;
    hidden var is24Hour = true;
    hidden var distanceUnits = System.UNIT_METRIC;
    hidden var textColor = Graphics.COLOR_BLACK;
    hidden var inverseTextColor = Graphics.COLOR_WHITE;
    hidden var backgroundColor = Graphics.COLOR_WHITE;
    hidden var inverseBackgroundColor = Graphics.COLOR_BLACK;
    hidden var inactiveGpsBackground = Graphics.COLOR_LT_GRAY;
    hidden var batteryBackground = Graphics.COLOR_WHITE;
    hidden var statusColorGood = Graphics.COLOR_GREEN;
    hidden var hrColor = Graphics.COLOR_RED;
    hidden var cadColor = Graphics.COLOR_DK_GREEN;
    hidden var headerColor = Graphics.COLOR_DK_GRAY;
    hidden var outlineColor = Graphics.COLOR_DK_GRAY;
        
    hidden var paceStr = "", avgPaceStr = "", hrStr = "", distanceStr = "", durationStr = "m:ss", cadenceStr = "", avgSignStr = "";
    
    hidden var paceData = new DataQueue(10);
    hidden var avgSpeed= 0;
    hidden var hr = 0;
    hidden var distance = 0;
    hidden var elapsedTime = 0;
    hidden var gpsSignal = 0;
    hidden var cadence = 0;
    
    hidden var hasBackgroundColorOption = false;

    //! Set the label of the data field here.
    function initialize() {
        DataField.initialize();
    }

    //! The given info object contains all the current workout
    //! information. Calculate a value and return it in this method.
    function compute(info) {
        if (info.currentSpeed != null) {
            paceData.add(info.currentSpeed);
        } else {
            paceData.reset();
        }
        
        avgSpeed = info.averageSpeed != null ? info.averageSpeed : 0;
        elapsedTime = info.elapsedTime != null ? info.elapsedTime : 0;        
        hr = info.currentHeartRate != null ? info.currentHeartRate : 0;
        distance = info.elapsedDistance != null ? info.elapsedDistance : 0;
        cadence = info.currentCadence != null ? info.currentCadence : 0;
        gpsSignal = info.currentLocationAccuracy;
    }
    
    function onLayout(dc) {
        setDeviceSettingsDependentVariables();
        dc.setColor(headerColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(170, 169, HEADER_FONT, durationStr, CENTER);
        onUpdate(dc);
    }
    
    function onUpdate(dc) {
        setColors();
        // reset background
        dc.setColor(backgroundColor, backgroundColor);
        dc.fillRectangle(0, 0, 218, 218);
        
        drawValues(dc);
    }

    function setDeviceSettingsDependentVariables() {
        hasBackgroundColorOption = (self has :getBackgroundColor);
        
        distanceUnits = System.getDeviceSettings().distanceUnits;
        if (distanceUnits == System.UNIT_METRIC) {
            kmOrMileInMeters = 1000;
        } else {
            kmOrMileInMeters = 1610;
        }
        is24Hour = System.getDeviceSettings().is24Hour;
        
        //paceStr = Ui.loadResource(Rez.Strings.pace);
        //avgPaceStr = Ui.loadResource(Rez.Strings.avgpace);
        //hrStr = Ui.loadResource(Rez.Strings.hr);
        //distanceStr = Ui.loadResource(Rez.Strings.distance);
        //durationStr = Ui.loadResource(Rez.Strings.duration);
        //cadenceStr = Ui.loadResource(Rez.Strings.cadence);
        avgSignStr = Ui.loadResource(Rez.Strings.avgSign);
    }
    
    function setColors() {
        if (hasBackgroundColorOption) {
            backgroundColor = getBackgroundColor();
            textColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
            inverseTextColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_WHITE : Graphics.COLOR_WHITE;
            inverseBackgroundColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_DK_GRAY: Graphics.COLOR_BLACK;
            hrColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_RED : Graphics.COLOR_RED;
            headerColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_LT_GRAY: Graphics.COLOR_DK_GRAY;
            statusColorGood = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_DK_GREEN : Graphics.COLOR_GREEN;
            outlineColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        }
    }
        
    function drawValues(dc) {
        //time
        var clockTime = System.getClockTime();
        var time, ampm;
        if (is24Hour) {
            time = Lang.format("$1$:$2$", [clockTime.hour, clockTime.min.format("%.2d")]);
            ampm = "";
        } else {
            time = Lang.format("$1$:$2$", [computeHour(clockTime.hour), clockTime.min.format("%.2d")]);
            ampm = (clockTime.hour < 12) ? "am" : "pm";
        }
        //dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        //dc.fillRectangle(0,0,218,25);
        //dc.setColor(inverseTextColor, Graphics.COLOR_TRANSPARENT);
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(109, 12, Graphics.FONT_MEDIUM, time, CENTER);
        dc.drawText(148, 15, HEADER_FONT, ampm, CENTER);
        
        //speed
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(13, 72, VALUE_FONT, getSpeed(paceData.getAverageData()), LEFT);
        
        //hr
		drawOutlineText(107, 70, HOT_FONT, hr.format("%d"), CENTER, hrColor, dc, 1);
        //dc.setColor(hrColor, Graphics.COLOR_TRANSPARENT);
        //dc.drawText(107, 70, HOT_FONT, hr.format("%d"), CENTER);
        
        //avg speed
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(205 , 72, VALUE_FONT, getSpeed(avgSpeed), RIGHT);
        
        //distance
        var distStr;
        if (distance > 0) {
            var distanceKmOrMiles = distance / kmOrMileInMeters;
            if (distanceKmOrMiles < 100) {
                distStr = distanceKmOrMiles.format("%.2f");
            } else {
                distStr = distanceKmOrMiles.format("%.1f");
            }
        } else {
            distStr = ZERO_DISTANCE;
        }
        dc.drawText(13, 134, VALUE_FONT, distStr, LEFT);
        
        //cad
		drawOutlineText(107, 134, VALUE_FONT, cadence.format("%d"), CENTER, cadColor, dc, 1);
        
        //duration
        var duration;
        if (elapsedTime != null && elapsedTime > 0) {
            var hours = null;
            var minutes = elapsedTime / 1000 / 60;
            var seconds = elapsedTime / 1000 % 60;
            
            if (minutes >= 60) {
                hours = minutes / 60;
                minutes = minutes % 60;
            }
            
            if (hours == null) {
                duration = minutes.format("%d") + ":" + seconds.format("%02d");
        		durationStr = "m:ss";
            } else {
                duration = hours.format("%d") + ":" + minutes.format("%02d");
        		durationStr = "h:mm";
            }
        } else {
            duration = ZERO_TIME;
        } 
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(205, 134, VALUE_FONT, duration, RIGHT);

        //signs background
        dc.setColor(inverseBackgroundColor, inverseBackgroundColor);
        dc.fillRectangle(0,185,218,33);
        
		// battery
        drawBattery(System.getSystemStats().battery, dc, 69, 191, 25, 15);
        
        // gps 
		drawGps(dc, 125, 185);
       
        // headers:
        dc.setColor(headerColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(30, 40, HEADER_FONT, distanceUnits == System.UNIT_METRIC ? "km/h" : "mph", LEFT);
        dc.drawText(109, 32, HEADER_FONT, "bpm", CENTER); 
        dc.drawText(188, 40, HEADER_FONT, avgSignStr + (distanceUnits == System.UNIT_METRIC ? " km/h" : " mph"), RIGHT);
        dc.drawText(30, 169, HEADER_FONT, distanceUnits == System.UNIT_METRIC ? "km" : "mi", LEFT);
        dc.drawText(109, 169, HEADER_FONT, "rpm", CENTER);
        dc.drawText(188, 169, HEADER_FONT, durationStr, RIGHT);
        dc.drawText(109, 212, HEADER_FONT, RELEASE, CENTER);
        
        //grid
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, 109, dc.getWidth(), 109);
    }
    
    function drawBattery(battery, dc, xStart, yStart, width, height) {                
        dc.setColor(batteryBackground, inactiveGpsBackground);
        dc.fillRectangle(xStart, yStart, width, height);
        if (battery < 10) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(xStart+3 + width / 2, yStart + 6, HEADER_FONT, format("$1$%", [battery.format("%d")]), CENTER);
        }
        
        if (battery < 10) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        } else if (battery < 30) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(statusColorGood, Graphics.COLOR_TRANSPARENT);
        }
        dc.fillRectangle(xStart + 1, yStart + 1, (width-2) * battery / 100, height - 2);
            
        dc.setColor(batteryBackground, batteryBackground);
        dc.fillRectangle(xStart + width - 1, yStart + 3, 4, height - 6);
    }
    
    function drawGps(dc, xStart, yStart) {
        if (gpsSignal < 2) {
            drawGpsSign(dc, xStart, yStart, inactiveGpsBackground, inactiveGpsBackground, inactiveGpsBackground);
        } else if (gpsSignal == 2) {
            drawGpsSign(dc, xStart, yStart, statusColorGood, inactiveGpsBackground, inactiveGpsBackground);
        } else if (gpsSignal == 3) {          
            drawGpsSign(dc, xStart, yStart, statusColorGood, statusColorGood, inactiveGpsBackground);
        } else {
            drawGpsSign(dc, xStart, yStart, statusColorGood, statusColorGood, statusColorGood);
        }
    }
    
    
    function drawGpsSign(dc, xStart, yStart, color1, color2, color3) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(xStart - 1, yStart + 11, 8, 10);
        dc.setColor(color1, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(xStart, yStart + 12, 6, 8);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(xStart + 6, yStart + 7, 8, 14);
        dc.setColor(color2, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(xStart + 7, yStart + 8, 6, 12);
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(xStart + 13, yStart + 3, 8, 18);
        dc.setColor(color3, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(xStart + 14, yStart + 4, 6, 16);
    }
    
    function computeHour(hour) {
        if (hour < 1) {
            return hour + 12;
        }
        if (hour >  12) {
            return hour - 12;
        }
        return hour;      
    }
    
    //! convert to integer - round ceiling 
    function toNumberCeil(float) {
        var floor = float.toNumber();
        if (float - floor > 0) {
            return floor + 1;
        }
        return floor;
    }
    
    function getSpeed(speedMetersPerSecond) {
        if (speedMetersPerSecond != null && speedMetersPerSecond > 0.2) {
            var kmOrMilesPerHour = speedMetersPerSecond * 60.0 * 60.0 / kmOrMileInMeters;
            return kmOrMilesPerHour.format("%.1f");
        }
        return ZERO_TIME; 
    }
     
    function drawOutlineText(x, y, font, text, pos, color, dc, delta) {
     	dc.setColor(outlineColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + delta, y, font, text, pos);
        dc.drawText(x - delta, y, font, text, pos);
        dc.drawText(x, y + delta, font, text, pos);
        dc.drawText(x, y - delta, font, text, pos);
      	dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text, pos);
    }

}

//! A circular queue implementation.
class DataQueue {

    //! the data array.
    hidden var data;
    hidden var maxSize = 0;
    hidden var pos = 0;

    //! precondition: size has to be >= 2
    function initialize(arraySize) {
        data = new[arraySize];
        maxSize = arraySize;
    }
    
    //! Add an element to the queue.
    function add(element) {
        data[pos] = element;
        pos = (pos + 1) % maxSize;
    }
    
    //! Reset the queue to its initial state.
    function reset() {
        for (var i = 0; i < data.size(); i++) {
            data[i] = null;
        }
        pos = 0;
    }
    
    //! Get the underlying data array.
    function getData() {
        return data;
    }

	// calculate the avarage of the data
    function getAverageData() {
        var size = 0;
        var sumOfData = 0.0;
        for (var i = 0; i < data.size(); i++) {
            if (data[i] != null) {
                sumOfData = sumOfData + data[i];
                size++;
            }
        }
        if (sumOfData > 0) {
            return sumOfData / size;
        }
        return 0.0;
    }
    
}