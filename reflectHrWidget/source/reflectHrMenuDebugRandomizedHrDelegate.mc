using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using reflectHr.Runtime;

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
		
    	if (Runtime has :Debug) {
			Runtime.Debug.HrRandomizationEnabled = setting;
		}
    }
    
    function onBack() {
        Ui.popView(Ui.SLIDE_DOWN);
    }
}