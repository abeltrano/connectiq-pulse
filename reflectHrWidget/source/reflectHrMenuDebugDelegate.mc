using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

class reflectHrMenuDebugDelegate extends Ui.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item) {
    	switch (item) {
    	case :menuItemDebugRandomizedHr:
    		Ui.pushView(new Rez.Menus.menuDebugRandomizedHr(), new reflectHrMenuDebugRandomizedHrDelegate(), Ui.SLIDE_UP);
    		break;
    		
		default:
			break;
    	}
    }
    
    function onBack() {
        Ui.popView(Ui.SLIDE_DOWN);
    }
}