using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

class reflectHrMenuZoneNotificationsDelegate extends Ui.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
    	switch (item) {
    	case :zoneNotificationsOff:
    		break;
    		
    	case :zoneNotificationsVibrate:
    		break;
    		
    	case :zoneNotificationsTone:
    		break;
    			
		case :zoneNotificationsBoth:
			break;
				
		default:
			break;
    	}
    }
    
    function onBack() {
        Ui.popView(Ui.SLIDE_DOWN);
    }
}