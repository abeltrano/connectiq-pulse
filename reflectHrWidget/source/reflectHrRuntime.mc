
module reflectHrRuntime {

	(:debugOnly)
	module Debug {
		var IsDebugEnabled = true;
		var IsHrRandomizationEnabled = true;
	}
	
	function IsDebugBuild() {
		return (reflectHrRuntime has :Debug) ? Debug.IsDebugEnabled : false;
	}
	
	function IsHrRandomizationEnabled() {
		return (reflectHrRuntime has :Debug) ? Debug.IsHrRandomizationEnabled : false;
	}
}