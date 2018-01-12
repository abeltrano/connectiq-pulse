using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

class reflectHrMenuDebugRandomizedHrDelegate extends Ui.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }
    
    function onMenuItem(item) {
		var setting = null;
		
		switch (item) {
    	case :debugRandomizedHrEnabled:
    		setting = true;
    		break;
		case :debugRandomizedHrDisabled:
			setting = false;
			break;
			
		default:
			break;
		}
		
    	if (reflectHrRuntime has :Debug) {
			reflectHrRuntime.Debug.IsHrRandomizationEnabled = setting;
		}
    }
    
    function onBack() {
        Ui.popView(Ui.SLIDE_DOWN);
    }
}