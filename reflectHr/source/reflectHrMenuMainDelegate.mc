using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

class reflectHrMenuDelegate extends Ui.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
    	switch (item) {
    	case :zoneNotifications:
    		Ui.pushView(new Rez.Menus.menuZoneNotifications(), new reflectHrMenuZoneNotificationsDelegate(), Ui.SLIDE_UP);
    		break;
    		
		default:
			break;
    	}
    }
}