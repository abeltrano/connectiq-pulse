using Toybox.WatchUi as Ui;

class reflectHrDelegate extends Ui.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() {
    	var view = (reflectHrRuntime has :Debug) 
    		? new Rez.Menus.menuMainWithDebug()
    		: new Rez.Menus.menuMain();
    		
        Ui.pushView(view, new reflectHrMenuMainDelegate(), Ui.SLIDE_UP);
        return true;
    }
}