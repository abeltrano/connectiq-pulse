
module reflectHr {

module Runtime {

    (:debugOnly)
    module Debug {
        var HrRandomizationEnabled = false;
    }

    function IsDebugBuild() {
        return (Runtime has :Debug);
    }

    function IsHrRandomizationEnabled() {
        return IsDebugBuild() ? Debug.HrRandomizationEnabled : false;
    }

} /* module Runtime */

} /* module reflectHr */