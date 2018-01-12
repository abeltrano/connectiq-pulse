using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

class reflectHrMenuMainDelegate extends Ui.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
    	switch (item) {
    	case :menuItemZoneNotifications:
    		Ui.pushView(new Rez.Menus.menuZoneNotifications(), new reflectHrMenuZoneNotificationsDelegate(), Ui.SLIDE_UP);
    		break;
		
		case :menuItemDebug:
			Ui.pushView(new Rez.Menus.menuDebug(), new reflectHrMenuDebugDelegate(), Ui.SLIDE_UP);
			break;
			
		default:
			break;
    	}
    }
}