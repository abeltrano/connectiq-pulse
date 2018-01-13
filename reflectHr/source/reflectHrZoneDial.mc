using Toybox.WatchUi as Ui;

class reflectHrZoneDial extends Ui.Drawable {

	// Heart rate zone contants.
	const HrZoneArcWidth   = 5;	
    const HrZoneSeparation = 5;
	const HrZoneStart = 90 - (HrZoneSeparation / 2);
	
	var hrZones = null;
	var hrValue = null;
	var hrZoneActive = -1;
	var hrZoneAmount = 0;
	
    function initialize(params) {
        Drawable.initialize(params);
    }
    
    function setHrData(hrValue, hrZoneActive) {
    	self.hrValue = hrValue;
    	self.hrZoneActive = hrZoneActive;
    }
    
    function setHrZones(hrZones) {
    	self.hrZones = hrZones;
        self.hrZoneAmount = (360 / hrZones.count()) - HrZoneSeparation;
        calculateHrZoneBounds();
    }
    
    function calculateHrZoneBounds() {
    	for (var zone = 0; zone < self.hrZones.count(); zone++) {
			self.hrZones.Properties[zone][:arcStart] = HrZoneStart - (zone * (self.hrZoneAmount + HrZoneSeparation));
    		self.hrZones.Properties[zone][:arcEnd]   = self.hrZones.Properties[zone][:arcStart] - self.hrZoneAmount;
    	}
    }
    
    function draw(dc) {
    	// Don't draw any zones if no value is set.
    	if (self.hrValue == null || self.hrValue <= 0) {
    		return;
    	}
    	
    	var x = dc.getWidth() / 2;
        var y = dc.getHeight() / 2;
        var r = x - 5;

        dc.setPenWidth(HrZoneArcWidth);
        
    	for (var zone = 0; zone <= self.hrZoneActive; zone++) {
	        dc.setColor(self.hrZones.Properties[zone][:color], Graphics.COLOR_TRANSPARENT);
	        dc.drawArc(x, y, r, Graphics.ARC_CLOCKWISE, self.hrZones.Properties[zone][:arcStart], self.hrZones.Properties[zone][:arcEnd]);
    	}
    }
}