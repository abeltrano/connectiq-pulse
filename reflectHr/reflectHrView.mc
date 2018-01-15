
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
		Last = 1 
	}
	
	// Minimum heart rate interval.
	const MaxHrZoneCount  = 5;
	const MinHrIntervalMs = 1000;
	const OneMinuteInMs   = 1000 * 60;
	const HrZoneVibeMs    = 250;
	
	// Heart rate zone fixed information.
	var hrZones;
	var hrZoneDial;
	var hrZoneActive = -1;
	var hrZoneIndex = 0;
	var hrZoneIndexCount = MaxHrZoneCount;
	
	var hrLabel;
	var hrLabelZoneValue;
	var hrLabelZoneDescription;
	var hrLabelMhrValue;
	
	var hrValue = [0,0];
	var hrValueUpdateTime = 0;

	// Heart rate "pulsing" feature.
	var hrPulse = false;
	var hrTimerInterval = MinHrIntervalMs;
	var hrTimer;
	var scTimer;
	
    function initialize(hrPulse) {
        View.initialize();
        
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
        self.hrLabelMhrValue.setText(reflectHr.Rez.Strings.defaultMhr);
        self.hrLabelZoneValue.setText(reflectHr.Rez.Strings.defaultZoneValue);
        self.hrLabelZoneDescription.setText(reflectHr.Rez.Strings.defaultZoneDescription);
        
   		Ui.requestUpdate();
    }

    function onUpdate(dc) {
    	self.hrZoneDial.setHrData(self.hrValue[Current], self.hrZoneActive);
    	View.onUpdate(dc);
    }
    
    function getHrZone(hr) {
    	for (var zone = 0; zone < self.hrZones.count() - 1; zone++) {
    		if (hr <= self.hrZones.Properties[zone][:bound]) {
    			return zone;
    		}
    	}
    	
    	return self.hrZones.count() - 1;
    }

    function getRandomizedHr() {
		if (self.hrZoneIndexCount > 0) {
			self.hrZoneIndexCount--;
		}
		else {
			self.hrZoneIndexCount = MaxHrZoneCount;
			self.hrZoneIndex = Math.rand() % self.hrZones.count();
		}
		
		return self.hrZones.Properties[self.hrZoneIndex][:bound];
    }

    public function onHrUpdated(hrValue) {    	
    	// Check if heart rate value is valid.
    	if (Runtime.IsHrRandomizationEnabled()) {
    		hrValue = getRandomizedHr();
		} else if (hrValue == null) {
			hrValue = 0;
		}
    	
		// Check if heart rate changed.
		if (self.hrValue[Current] != hrValue) {
			self.hrValue[Last] = self.hrValue[Current];
			self.hrValue[Current] = hrValue;
			
			// If pulsing is disabled, update immediately.
			if (!self.hrPulse) {
				updateHr();
			}
			// If the new rate is 0, stop the timer.
			else if (self.hrValue[Current] <= 0) {
				self.hrTimer.stop();
				self.scTimer.stop();
				self.hrZoneActive = -1;
				updateHrDefaults();
			// If the previous rate was 0, restart the timer.
			} else if (self.hrValue[Last] <= 0) {
				updateHr();
				if (self.hrPulse) {
					self.hrTimer.start(method(:onHrTimerExpired), self.hrTimerInterval / 3 * 2 , false);
				}
			// Otherwise update hr value.
			} else {
				var now  = Sys.getTimer();
				var next = self.hrValueUpdateTime + 1000;
				if (now > next) {
					updateHr();
				} else {
					scTimer.start(method(:onScTimerExpired), next - now, false);
				}
			}
		}
    }
    
    function onHrTimerExpired() {
		self.hrLabel.setFont(Graphics.FONT_SYSTEM_NUMBER_THAI_HOT);
		self.hrTimer.start(method(:onHrTimerExpiredShort), self.hrTimerInterval / 3 * 2, false);
		Ui.requestUpdate();
	}
	
	function onHrTimerExpiredShort() {
		self.hrLabel.setFont(Graphics.FONT_SYSTEM_NUMBER_HOT);
		self.hrTimer.start(method(:onHrTimerExpired), self.hrTimerInterval / 3 * 1, false);
		Ui.requestUpdate();
	}
	
    function onScTimerExpired() {
		updateHr();
    }
    
	function updateHr() {
		var hrValue = self.hrValue[Current];
		var hrZoneActive = getHrZone(hrValue);
		var hrZoneActiveLast = self.hrZoneActive;
		
		self.hrValueUpdateTime = Sys.getTimer();
		self.hrTimerInterval = OneMinuteInMs / hrValue;
		self.hrLabel.setText(hrValue.format("%d"));
		
		if (self.hrZoneActive != hrZoneActive) {
			self.hrZoneActive = hrZoneActive;
			onHrZoneActiveChanged(hrZoneActive, hrZoneActiveLast);
		}
			   	
	   	Ui.requestUpdate();
	}
	
	function onHrZoneActiveChanged(zoneValue, zoneValueLast) {
		var zone = self.hrZones.Properties[zoneValue];
		var zoneMhr = self.hrValue[Current] * 100 / self.hrZones.maxHr();
		
		self.hrLabelZoneValue.setColor(zone[:color]);
		self.hrLabelZoneValue.setText(zoneValue.toString());
		self.hrLabelMhrValue.setColor(zone[:color]);
		self.hrLabelMhrValue.setText(zoneMhr.format("%d") + "%"); 
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