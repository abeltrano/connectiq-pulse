
module reflectHr {

module Runtime {
	
	(:debugOnly)
	module Debug {
		var IsDebugEnabled = true;
		var IsHrRandomizationEnabled = true;
	}
	
	function IsDebugBuild() {
		return (Runtime has :Debug) ? Debug.IsDebugEnabled : false;
	}
	
	function IsHrRandomizationEnabled() {
		return (Runtime has :Debug) ? Debug.IsHrRandomizationEnabled : false;
	}
	
	(:debugOnly)
	function setHrRandomizationEnabled(isHrRandomizationEnabled) {
		Debug.IsHrRandomizationEnabled = isHrRandomizationEnabled;
	}
	
} /* module Runtime */

} /* module reflectHr */