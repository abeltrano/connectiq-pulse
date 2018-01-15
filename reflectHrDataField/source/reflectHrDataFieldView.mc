using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using reflectHr;

class reflectHrDataFieldView extends Ui.DataField {

    var view;
    var hrValue = 0;

    function initialize() {
        DataField.initialize();
		self.view = new reflectHr.reflectHrView(false);
    }

    function onLayout(dc) {
		self.view.onLayout(dc);
        return true;
    }

    function compute(info) {
		self.hrValue = info.currentHeartRate;
    }

    function onUpdate(dc) {
    	self.view.onHrUpdated(self.hrValue);
    	self.view.onUpdate(dc);
    }
}
