
using Toybox.Sensor;
using reflectHr;

class reflectHrWidgetView extends reflectHr.reflectHrView {
	
    function initialize() {
        reflectHr.reflectHrView.initialize();
			
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        Sensor.enableSensorEvents(method(:onSensor));
    }
    
    function onSensor(sensorInfo) {
    	onHrUpdated(sensorInfo.heartRate);
	}
}
