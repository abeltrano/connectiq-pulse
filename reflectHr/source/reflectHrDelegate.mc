using Toybox.WatchUi as Ui;

class reflectHrDelegate extends Ui.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() {
        Ui.pushView(new Rez.Menus.menuMain(), new reflectHrMenuMainDelegate(), Ui.SLIDE_UP);
        return true;
    }
}