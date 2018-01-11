using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Attention;
using Toybox.Timer;
using Toybox.Math;
using Toybox.Graphics;
using Toybox.UserProfile;

class reflectHrView extends Ui.View {
	// Minimum heart rate interval.
	const MaxHrZoneCount  = 5;
	const MinHrIntervalMs = 1000;
	const OneMinuteInMs   = 1000 * 60;
	
	// Heart rate zone contants.
	const HrZoneArcWidth   = 5;	
    const HrZoneSeparation = 5;
	const HrZoneStart = 90 - (HrZoneSeparation / 2);
	const HrZoneVibeMs     = 250;
	
	enum { Current = 0, Last = 1 }
	
	// Heart rate zone fixed information.
	var hrZoneInfo = [ 
		{ :color => 0x55AA55, :description => "Rest" },
		{ :color => 0xFFFF00, :description => "Recovery" },
		{ :color => 0xFFAA00, :description => "Endurance" },
		{ :color => 0xFF5500, :description => "Aerobic" },
		{ :color => 0xAA0055, :description => "Threshold" },
		{ :color => 0xAA0000, :description => "Anaerobic" }];

	var hrZones; 
	var hrZoneAmount;
	var hrZoneActive = -1;
	var hrZoneIndex = 0;
	var hrZoneIndexCount = MaxHrZoneCount;
	
	var hrMax;
	var hrSport;
	var hrLabel;
	var hrLabelZoneValue;
	var hrLabelZoneDescription;
	var hrLabelMhrValue;
	
	var hrValue = [0,0];
	var hrTimerInterval = MinHrIntervalMs;
	var hrValueUpdateTime = 0;
	var hrTimer = new Timer.Timer();
	var scTimer = new Timer.Timer();
	
    function initialize() {
        View.initialize();
        
        self.hrSport = UserProfile.getProfile().getCurrentSport();
        self.hrZones = UserProfile.getHeartRateZones(self.hrSport);
        self.hrZoneAmount = (360 / self.hrZones.size()) - HrZoneSeparation;
        self.hrMax = self.hrZones[self.hrZones.size()-1];
        
        calculateHrZoneBounds();

        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        Sensor.enableSensorEvents(method(:onSensor));
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
        self.hrLabel = View.findDrawableById("hrLabel");
        self.hrLabelMhrValue = View.findDrawableById("hrLabelMhrValue");
        self.hrLabelZoneValue = View.findDrawableById("hrLabelZoneValue");
        self.hrLabelZoneDescription = View.findDrawableById("hrLabelZoneDescription");
        onUpdate(dc);
    }

    function onShow() {
        updateHrDefaults();
    }
    
    function updateHrDefaults() {
        self.hrLabel.setText("--");
        self.hrLabelMhrValue.setText("--");
        self.hrLabelZoneValue.setText("--");
        self.hrLabelZoneDescription.setText("Waiting");
	   	Ui.requestUpdate();
    }

    function onUpdate(dc) {
    	View.onUpdate(dc);
        drawHrZoneArcs(dc);
    }
    
    function getHrZone(hr) {
    	for (var zone = 0; zone < self.hrZones.size() - 1; zone++) {
    		if (hr < self.hrZones[zone]) {
    			return zone;
    		}
    	}
    	
    	return self.hrZones.size() - 1;
    }
    
    function getHrZoneBounds(zone) {
    	var zoneStart = HrZoneStart - (zone * (self.hrZoneAmount + HrZoneSeparation));
    	var zoneEnd   = zoneStart - self.hrZoneAmount;
    	
    	return { :start => zoneStart, :end => zoneEnd };
    }
    
    function calculateHrZoneBounds() {
    	for (var zone = 0; zone < self.hrZoneInfo.size(); zone++) {
    		var zoneBounds = getHrZoneBounds(zone);
    		self.hrZoneInfo[zone][:arcStart] = zoneBounds[:start];
    		self.hrZoneInfo[zone][:arcEnd]   = zoneBounds[:end];
    	}
    }
    
    function drawHrZoneArcs(dc) {
    	// Don't draw any zones if no value is set.
    	var hr = self.hrValue[Current];
    	if (hr == null || hr <= 0) {
    		return;
    	}
    	
    	var x = dc.getWidth() / 2;
        var y = dc.getHeight() / 2;
        var r = x - 5;

        dc.setPenWidth(HrZoneArcWidth);
        
    	for (var zone = 0; zone <= self.hrZoneActive; zone++) {
	        dc.setColor(self.hrZoneInfo[zone][:color], Graphics.COLOR_TRANSPARENT);
	        dc.drawArc(x, y, r, Graphics.ARC_CLOCKWISE, self.hrZoneInfo[zone][:arcStart], self.hrZoneInfo[zone][:arcEnd]);
    	}
    }

    function onHide() {
    	self.hrTimer.stop();
    	self.scTimer.stop();
    }
    
    function getRandomizedHr() {
		if (self.hrZoneIndexCount > 0) {
			self.hrZoneIndexCount--;
		}
		else {
			self.hrZoneIndexCount = MaxHrZoneCount;
			self.hrZoneIndex = Math.rand() % self.hrZones.size();
		}
		
		return self.hrZones[self.hrZoneIndex];
    }
    
    function onSensor(sensorInfo) {   	
    	// Check if heart rate value is valid.
    	if (sensorInfo.heartRate == null) {
    		sensorInfo.heartRate = reflectHrRuntime.IsDebugBuild()
    			? getRandomizedHr()
    			: 0;
    	}
    	
		// Check if heart rate changed.
		if (self.hrValue[Current] != sensorInfo.heartRate) {
			self.hrValue[Last] = self.hrValue[Current];
			self.hrValue[Current] = sensorInfo.heartRate;
				
			// If the new rate is 0, stop the timer.
			if (self.hrValue[Current] <= 0) {
				self.hrTimer.stop();
				self.scTimer.stop();
				self.hrZoneActive = -1;
				updateHrDefaults();
			// If the previous rate was 0, restart the timer.
			} else if (self.hrValue[Last] <= 0) {
				updateHr();
				self.hrTimer.start(method(:onHrTimerExpired), self.hrTimerInterval / 3 * 2 , false);
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
		var zone = self.hrZoneInfo[zoneValue];
		var zoneMhr = self.hrValue[Current] * 100 / self.hrMax;
		
		self.hrLabelZoneValue.setColor(zone[:color]);
		self.hrLabelZoneValue.setText(zoneValue.toString());
		self.hrLabelMhrValue.setColor(zone[:color]);
		self.hrLabelMhrValue.setText(zoneMhr.format("%d") + "%"); 
		self.hrLabelZoneDescription.setText(zone[:description]);
		
		if (Attention has :backlight) {
			Attention.backlight(true);
		}
		
		if (Attention has :vibrate) {
			var vibeDutyCycle  = (zoneValue+1) * 100 / self.hrZones.size();
			var vibeProfileOn  = new Attention.VibeProfile(vibeDutyCycle, self.HrZoneVibeMs);
			var vibeProfileOff = new Attention.VibeProfile(0, self.HrZoneVibeMs / 2);			
			Attention.vibrate([vibeProfileOn, vibeProfileOff, vibeProfileOn]);
		} else if (Attention has :playTone) {
			var tone = (zoneValue > zoneValueLast) ? Attention.TONE_ALERT_HI : Attention.TONE_ALERT_LO;
			Attention.playTone(tone);
		}
	}
}
