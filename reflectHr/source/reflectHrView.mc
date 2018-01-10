using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Timer;
using Toybox.Math;
using Toybox.Graphics;

class reflectHrView extends Ui.View {

	// Minimum heart rate interval.
	const MinHrIntervalMs = 1000;
	const OneMinuteInMs   = 1000 * 60;
	
	enum { Current = 0, Last = 1 }
    	
	var hrLabel;
	var hrValue = [0,0];
	var hrTimerInterval = MinHrIntervalMs;
	var hrTimer = new Timer.Timer();
	var scTimer = new Timer.Timer();

    function initialize() {
        View.initialize();

        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        Sensor.enableSensorEvents(method(:onSensor));
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
        self.hrLabel = View.findDrawableById("hrLabel");
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
        self.hrTimer.start(method(:onHrTimerExpired), MinHrIntervalMs, true);
    }

    // Update the view
    function onUpdate(dc) {      
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    	self.hrTimer.stop();
    }
    
    function onSensor(sensorInfo) {   	
    	// Check if heart rate value is valid.
    	if (sensorInfo.heartRate != null) {
    		self.hrValue[Last] = self.hrValue[Current];
    		self.hrValue[Current] = sensorInfo.heartRate;
    		
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
    }
    
    function onHrTimerExpired() {
    	if (self.hrValue[Current] > 0) {
    		self.hrLabel.setFont(Graphics.FONT_SYSTEM_NUMBER_THAI_HOT);
    		self.scTimer.start(method(:onScTimerExpired), self.hrTimerInterval / 2, false);
		}
		Ui.requestUpdate();
    }
    
    function onScTimerExpired() {
    	self.hrLabel.setFont(Graphics.FONT_SYSTEM_NUMBER_HOT);
    	Ui.requestUpdate();
    }
}
