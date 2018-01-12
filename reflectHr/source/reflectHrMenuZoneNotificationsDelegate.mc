using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Application;

class reflectHrMenuZoneNotificationsDelegate extends Ui.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }
    
    function onMenuItem(item) {
		var setting = null;
		switch (item) {
    	case :zoneNotificationsOff:
    		setting = ZoneNotificationsOff;
    		break;
    	case :zoneNotificationsVibrate:
    		setting = ZoneNotificationsVibrate;
    		break;
    	case :zoneNotificationsTone:
    		setting = ZoneNotificationsTone;
    		break;
    	case :zoneNotificationsBoth:
    		setting = ZoneNotificationsBoth;
    		break;
    	default: 
    		break;
    	}
    	
    	if (setting != null) {
			Application.Properties.setValue("zoneNotification", setting);
		}
    }
    
    function onBack() {
        Ui.popView(Ui.SLIDE_DOWN);
    }
}