using Toybox.UserProfile;

module reflectHr {

class HrZoneInfo {

	public var Properties = [ 
		{ :color => 0x55AA55, :description => Rez.Strings.zoneRest },
		{ :color => 0xFFFF00, :description => Rez.Strings.zoneRecovery },
		{ :color => 0xFFAA00, :description => Rez.Strings.zoneEndurance },
		{ :color => 0xFF5500, :description => Rez.Strings.zoneAerobic },
		{ :color => 0xAA0055, :description => Rez.Strings.zoneThreshold },
		{ :color => 0xAA0000, :description => Rez.Strings.zoneAnaerobic }
	];
	
	var sport;
	
	function initialize() {
        self.setSport(UserProfile.getProfile().getCurrentSport());
	}
	
	function setSport(sport) {
		self.sport = sport;
		setZoneBounds();
	}
	
	function setZoneBounds() {
        var bounds = UserProfile.getHeartRateZones(self.sport);
        for (var zone = 0; zone < bounds.size(); zone++) {
        	self.Properties[zone][:bound] = bounds[zone];
        }
	}
	
	function count() {
		return self.Properties.size();
	}
	
	function maxHr() {
		return self.Properties[self.count()-1][:bound];
	}
}

} /* module reflectHr */