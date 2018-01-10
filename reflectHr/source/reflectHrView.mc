using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
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
	var hrZoneActive = [0,0];
	var hrZoneIndex = 0;
	var hrZoneIndexCount = MaxHrZoneCount;
	
	var hrSport;
	var hrLabel;
	var hrLabelZoneValue;
	var hrLabelZoneDescription;
	var hrLabelMhrValue;
	
	var hrValue = [0,0];
	var hrTimerInterval = [MinHrIntervalMs, MinHrIntervalMs];
	var hrValueUpdated  = false;
	var hrValueUpdateTime = 0;
	var hrTimer = new Timer.Timer();
	var scTimer = new Timer.Timer();
	
    function initialize() {
        View.initialize();
        
        self.hrSport = UserProfile.getProfile().getCurrentSport();
        self.hrZones = UserProfile.getHeartRateZones(self.hrSport);
        self.hrZoneAmount = (360 / self.hrZones.size()) - HrZoneSeparation;
        calculateHrZoneBounds();

        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        Sensor.enableSensorEvents(method(:onSensor));
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
        self.hrLabel = View.findDrawableById("hrLabel");
        self.hrLabelMhrValue = View.findDrawableById("hrLabelMhrValue");
        self.hrLabelZoneValue = View.findDrawableById("hrLabelZoneValue");
        self.hrLabelZoneDescription = View.findDrawableById("hrLabelZoneDescription");
        onUpdate(dc);
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
        self.hrTimer.start(method(:onHrTimerExpired), MinHrIntervalMs, true);
        self.hrLabel.setText("--");
        self.hrLabelMhrValue.setText("--");
        self.hrLabelZoneValue.setText("--");
    }

    // Update the view
    function onUpdate(dc) {      
        // Call the parent onUpdate function to redraw the layout
    	View.onUpdate(dc);
        drawHrZoneArcs(dc);
    }
    
    function getHrZoneActive(hr) {
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
    	
    	return { 
    		:start => zoneStart,
    		:end   => zoneEnd
		};
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
    	if (hr == null || hr == 0) {
    		return;
    	}
    	
    	var x = dc.getWidth() / 2;
        var y = dc.getHeight() / 2;
        var r = x - 5;

        dc.setPenWidth(HrZoneArcWidth);
        
    	for (var zone = 0; zone <= self.hrZoneActive[Current]; zone++) {
	        dc.setColor(self.hrZoneInfo[zone][:color], Graphics.COLOR_TRANSPARENT);
	        dc.drawArc(x, y, r, Graphics.ARC_CLOCKWISE, hrZoneInfo[zone][:arcStart], hrZoneInfo[zone][:arcEnd]);
    	}
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
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
    		if (!reflectHrRuntime.IsDebugBuild()) {
    			self.hrTimer.stop();
    			self.scTimer.stop();
				self.hrLabel.setText("--");
				return;
    		}
    		
    		sensorInfo.heartRate = getRandomizedHr();
    	}
    	
    	// Process heart rate value.
		self.hrValue[Last] = self.hrValue[Current];
		self.hrValue[Current] = sensorInfo.heartRate;
		self.hrZoneActive[Last] = self.hrZoneActive[Current];
		self.hrZoneActive[Current] = getHrZoneActive(self.hrValue[Current]);
		
		var zoneActive = self.hrZoneActive[Current];
		var zoneColor  = self.hrZoneInfo[zoneActive][:color];
		var zoneDescription = self.hrZoneInfo[zoneActive][:description];
		var zoneMhr = self.hrValue[Current] * 100 / self.hrZones[self.hrZones.size()-1];
		
		self.hrLabelZoneValue.setColor(zoneColor);
		self.hrLabelZoneValue.setText(zoneActive.toString());
		self.hrLabelMhrValue.setColor(zoneColor);
		self.hrLabelMhrValue.setText(zoneMhr.format("%d") + "%"); 
		self.hrLabelZoneDescription.setText(zoneDescription);

		// Check if heart rate changed.
		if (self.hrValue[Current] != self.hrValue[Last]) {
			self.hrTimerInterval[Last] = hrTimerInterval[Current];
			self.hrTimerInterval[Current] = OneMinuteInMs / self.hrValue[Current];
			if (self.hrTimerInterval[Current] <= 0) {
				self.hrTimerInterval[Current] = MinHrIntervalMs;
			}
			
			self.hrValueUpdated = true;
		}
    }
    
    function onHrTimerExpired() {
		self.hrLabel.setFont(Graphics.FONT_SYSTEM_NUMBER_THAI_HOT);
		self.scTimer.start(method(:onScTimerExpired), self.hrTimerInterval[Current] / 2, false);
		Ui.requestUpdate();
    }
    
    function onScTimerExpired() {
    	self.hrLabel.setFont(Graphics.FONT_SYSTEM_NUMBER_HOT);
     	
    	var now = Sys.getTimer();
    	
    	// Only update the hr value if the previous interval has run at least once.
    	if (self.hrValueUpdated && (now - self.hrValueUpdateTime) > self.hrTimerInterval[Last]) {
    		self.hrValueUpdated = false;
			self.hrValueUpdateTime = now;
			self.hrTimer.stop();
			self.hrTimer.start(method(:onHrTimerExpired), self.hrTimerInterval[Current], true);
			self.hrLabel.setText(self.hrValue[Current].format("%d"));
    	}
    	
	   	Ui.requestUpdate();
    }
}
