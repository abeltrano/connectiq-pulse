
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Attention;
using Toybox.Timer;
using Toybox.Math;
using Toybox.Graphics;
using Toybox.Application;
using reflectHr;

enum {
	ZoneNotificationsOff = 0,
	ZoneNotificationsVibrate = 1,
	ZoneNotificationsTone = 2,
	ZoneNotificationsBoth = 3
}

module reflectHr {

class reflectHrView extends Ui.View {
	
	enum { 
		Current = 0, 
		Last = 1,
		Random
	}
	
	// Minimum heart rate interval.
	const MinHrIntervalMs = 1000;
	const OneMinuteInMs   = 1000 * 60;
	const HrZoneVibeMs    = 250;
	const HrPulseFont 	  = [ 
		Graphics.FONT_SYSTEM_NUMBER_THAI_HOT, 
		Graphics.FONT_SYSTEM_NUMBER_HOT 
	];
	
	// Heart rate zone fixed information.
	var hrZones;
	var hrZoneDial;
	var hrZoneActive = -1;
	
	var hrLabel;
	var hrLabelZoneValue;
	var hrLabelZoneDescription;
	var hrLabelMhrValue;
	
	var hrValue = [0,0,0];
	var hrValueUpdateTime = 0;
	var hrValueRandomizedCount = 0;
	var hrValueRandomizedCountMax;

	// Heart rate "pulsing" feature.
	var hrPulse = false;
	var hrPulseFontIndex = 0;
	var hrTimerInterval = MinHrIntervalMs;
	var hrTimer;
	var scTimer;
	
    function initialize(hrPulse) {
        View.initialize();
        Math.srand(Sys.getTimer());
        
        self.hrPulse = hrPulse;
        if (hrPulse) {
        	self.hrTimer = new Timer.Timer();
        	self.scTimer = new Timer.Timer();
    	}
        self.hrZones = new reflectHr.HrZoneInfo();
    }

    function onLayout(dc) {
        setLayout(reflectHr.Rez.Layouts.MainLayout(dc));
        self.hrLabel = View.findDrawableById("hrLabel");
        self.hrLabelMhrValue = View.findDrawableById("hrLabelMhrValue");
        self.hrLabelZoneValue = View.findDrawableById("hrLabelZoneValue");
        self.hrLabelZoneDescription = View.findDrawableById("hrLabelZoneDescription");
        self.hrZoneDial = View.findDrawableById("hrZoneDial");
        self.hrZoneDial.setHrZones(self.hrZones);
        onUpdate(dc);
    }
    
    function updateHrDefaults() {
        self.hrLabel.setText(reflectHr.Rez.Strings.defaultHr);
        self.hrLabelMhrValue.setColor(Graphics.COLOR_DK_GRAY);
        self.hrLabelMhrValue.setText(reflectHr.Rez.Strings.defaultMhr);
        self.hrLabelZoneValue.setColor(Graphics.COLOR_DK_GRAY);
        self.hrLabelZoneValue.setText(reflectHr.Rez.Strings.defaultZoneValue);
        self.hrLabelZoneDescription.setText(reflectHr.Rez.Strings.defaultZoneDescription);
    }

    function onUpdate(dc) {
    	self.hrZoneDial.setHrData(self.hrValue[Current], self.hrZoneActive);
    	View.onUpdate(dc);
    }

    function getRandomizedHr() {  	    	
    	if (self.hrValueRandomizedCount == 0) {
    		var randomValue = Math.rand();
    		var randomZone = randomValue % (self.hrZones.count() - 1);
    		var randomBounds = [self.hrZones.getZoneBound(randomZone)+1, self.hrZones.getZoneBound(randomZone+1)];
    		self.hrValueRandomizedCountMax = 1 + (randomValue % 10); 
    		self.hrValueRandomizedCount = self.hrValueRandomizedCountMax;
    		self.hrValue[Random] = randomBounds[0] + randomValue % (randomBounds[1] - randomBounds[0]);
		} else {
			self.hrValueRandomizedCount--;
		}
		
    	return self.hrValue[Random];
    }

    public function onHrUpdated(hrValue) {    	
    	// Check if heart rate value is valid.
    	if (Runtime.IsHrRandomizationEnabled()) {
    		hrValue = getRandomizedHr();
		} else if (hrValue == null) {
			hrValue = 0;
		}

		var updateHrPending = !self.hrPulse;
		
		// Check if heart rate changed.
		if (self.hrValue[Current] != hrValue) {
			self.hrValue[Last] = self.hrValue[Current];
			self.hrValue[Current] = hrValue;
			
			if (self.hrPulse) {			
				// If the new rate is 0, stop the timer.
				if (self.hrValue[Current] <= 0) {
					self.hrTimer.stop();
					self.scTimer.stop();
					self.hrZoneActive = -1;
					updateHrDefaults();
				// If the previous rate was 0, restart the timer.
				} else if (self.hrValue[Last] <= 0) {
					updateHrPending = true;
					self.hrTimer.start(method(:onHrTimerExpired), self.hrTimerInterval / 3 * 2 , false);
				// Otherwise update hr value.
				} else {
					var now  = Sys.getTimer();
					var next = self.hrValueUpdateTime + 1000;
					if (now > next) {
						updateHrPending = true;
					} else {
						scTimer.start(method(:onScTimerExpired), next - now, false);
					}
				}
			}
		}
		
		if (updateHrPending) {
			updateHr();		
		}
    }
    
    function onHrTimerExpired() {
		self.hrLabel.setFont(self.HrPulseFont[0]);
		self.hrTimer.start(method(:onHrTimerExpiredShort), self.hrTimerInterval / 3 * 2, false);
		Ui.requestUpdate();
	}
	
	function onHrTimerExpiredShort() {
		self.hrLabel.setFont(self.HrPulseFont[1]);
		self.hrTimer.start(method(:onHrTimerExpired), self.hrTimerInterval / 3 * 1, false);
		Ui.requestUpdate();
	}
	
    function onScTimerExpired() {
		updateHr();
    }
    
	function updateHr() {
		var hrValue = self.hrValue[Current];
		var hrZoneActive = self.hrZones.getZone(hrValue);
		var hrZoneActiveLast = self.hrZoneActive;
		var zoneMhr = hrValue * 100 / self.hrZones.maxHr();
		
		if (self.hrPulse) {
			self.hrValueUpdateTime = Sys.getTimer();
			self.hrTimerInterval = OneMinuteInMs / max(hrValue, 1);
		} else {
			self.hrLabel.setFont(self.HrPulseFont[self.hrPulseFontIndex]);
			self.hrPulseFontIndex = (self.hrPulseFontIndex + 1) % 2;
		}

		if (self.hrZoneActive != hrZoneActive) {
			self.hrZoneActive = hrZoneActive;
			onHrZoneActiveChanged(hrZoneActive, hrZoneActiveLast);
		}
			
		self.hrLabel.setText(hrValue.format("%d"));
		self.hrLabelMhrValue.setText(zoneMhr.format("%d") + "%");
		
	   	Ui.requestUpdate();
	}
	
	function onHrZoneActiveChanged(zoneValue, zoneValueLast) {
		var zone = self.hrZones.Properties[zoneValue];

		self.hrLabelMhrValue.setColor(zone[:color]); 
		self.hrLabelZoneValue.setColor(zone[:color]);
		self.hrLabelZoneValue.setText(zoneValue.toString());
		self.hrLabelZoneDescription.setText(zone[:description]);
		
		var zoneNotificationSetting = Application.Properties.getValue("zoneNotification");
		var zoneTone 	= zoneNotificationSetting & ZoneNotificationsTone != 0;
		var zoneVibrate = zoneNotificationSetting & ZoneNotificationsVibrate != 0;
		
		// Always turn on the backlight if available.
		if (Attention has :backlight) {
			Attention.backlight(true);
		}
		
		// Set vibration if enabled and available.
		if (zoneVibrate && Attention has :vibrate) {
			var vibeDutyCycle  = (zoneValue+1) * 100 / self.hrZones.count();
			var vibeProfileOn  = new Attention.VibeProfile(vibeDutyCycle, self.HrZoneVibeMs);
			var vibeProfileOff = new Attention.VibeProfile(0, self.HrZoneVibeMs / 2);			
			Attention.vibrate([vibeProfileOn, vibeProfileOff, vibeProfileOn]);
		} 
		// Set tone if enabled and available.		
		if (zoneTone && Attention has :playTone) {
			var tone = (zoneValue > zoneValueLast) ? Attention.TONE_ALERT_HI : Attention.TONE_ALERT_LO;
			Attention.playTone(tone);
		}
	}
}

} /* module reflectHr */