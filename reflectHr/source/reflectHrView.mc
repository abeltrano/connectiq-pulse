using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Timer;
using Toybox.Math;
using Toybox.Graphics;
using Toybox.UserProfile;

class reflectHrView extends Ui.View {

	// Minimum heart rate interval.
	const MinHrIntervalMs = 1000;
	const OneMinuteInMs   = 1000 * 60;
	const MaxHrZoneCount  = 5;
	const Debug 		  = true;
	
	enum { Current = 0, Last = 1 }

	var hrZoneIndex = 0;
	var hrZoneIndexCount = MaxHrZoneCount;
	var hrZones; 	
	var hrZoneAmount;
	var hrZoneActive = [0, 0];
	var hrZoneColors = [0x55AA55, 0xFFFF00, 0xFFAA00, 0xFF5500, 0xAA0055, 0xAA0000];
	var hrZoneDescriptions = ["Rest", "Recovery", "Endurance", "Aerobic", "Threshold", "Anaerobic" ];
	var hrLabel;
	var hrLabelZoneValue;
	var hrLabelZoneDescription;
	var hrSport;
	var hrValue = [0,0];
	var hrTimerInterval = MinHrIntervalMs;
	var hrTimer = new Timer.Timer();
	var scTimer = new Timer.Timer();
	
	const HrZoneArcWidth = 5;	
    const HrZoneSeparation = 5;
	const HrZoneStart = 90 - (HrZoneSeparation / 2);

    function initialize() {
        View.initialize();
        
        self.hrSport = UserProfile.getProfile().getCurrentSport();
        self.hrZones = UserProfile.getHeartRateZones(self.hrSport);
        self.hrZoneAmount = (360 / self.hrZones.size()) - HrZoneSeparation;

        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        Sensor.enableSensorEvents(method(:onSensor));
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
        self.hrLabel = View.findDrawableById("hrLabel");
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
    
    function drawHrZoneArcs(dc) {
    	var x = dc.getWidth() / 2;
        var y = dc.getHeight() / 2;
        var r = x - 5;

		dc.clear();
        dc.setPenWidth(HrZoneArcWidth);
        
    	for (var zone = 0; zone <= self.hrZoneActive[Current]; zone++) {
    		var hrZoneBounds = getHrZoneBounds(zone);
	        dc.setColor(self.hrZoneColors[zone], Graphics.COLOR_TRANSPARENT);
	        dc.drawArc(x, y, r, Graphics.ARC_CLOCKWISE, hrZoneBounds[:start], hrZoneBounds[:end]);
	        // TODO: draw circle with radius 1/2 pen width at start+end of arc to create rounded ends.
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
		
		return self.hrZones[self.hrZoneIndex]-1;
    }
    
    function onSensor(sensorInfo) {   	
    	// Check if heart rate value is valid.
    	if (sensorInfo.heartRate == null) {
    		if (!Debug) {
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
		self.hrLabelZoneValue.setColor(self.hrZoneColors[self.hrZoneActive[Current]]);
		self.hrLabelZoneValue.setText((self.hrZoneActive[Current]+1).toString());
		self.hrLabelZoneDescription.setText(self.hrZoneDescriptions[self.hrZoneActive[Current]]);

		// Check if heart rate changed.
		if (self.hrValue[Current] != self.hrValue[Last]) {
			self.hrTimerInterval = OneMinuteInMs / hrValue[Current];
			if (self.hrTimerInterval <= 0) {
				self.hrTimerInterval = MinHrIntervalMs;
			}
			
			self.hrTimer.stop();
			self.hrTimer.start(method(:onHrTimerExpired), self.hrTimerInterval, true);
			self.hrLabel.setText(self.hrValue[Current].format("%d"));
			// don't need to request update since scTimer will pick this up.
		}
    }
    
    function onHrTimerExpired() {
    	if (self.hrValue[Current] > 0) {
    		self.hrLabel.setFont(Graphics.FONT_SYSTEM_NUMBER_THAI_HOT);
    		self.scTimer.start(method(:onScTimerExpired), self.hrTimerInterval / 2, false);
			Ui.requestUpdate();
		}
    }
    
    function onScTimerExpired() {
    	self.hrLabel.setFont(Graphics.FONT_SYSTEM_NUMBER_HOT);
    	Ui.requestUpdate();
    }
}
