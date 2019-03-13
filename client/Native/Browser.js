const _zalando_nakadi$nakadi_ui$Native_Browser = function() {


    function setLocation(url) {
        window.document.location.href = url;
        return _elm_lang$core$Platform_Cmd$none
    }

    function getLocation(dummy) {
        return window.document.location.href
    }

    function pushState(url) {
        return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
            history.pushState({}, '', url);
            callback(_elm_lang$core$Native_Scheduler.succeed(getLocation()));
        });
    }

    function replaceState(url) {
        return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
            history.replaceState({}, '', url);
            callback(_elm_lang$core$Native_Scheduler.succeed(getLocation()));
        });
    }


    return {
        setLocation: setLocation,
        getLocation: getLocation,
        pushState: pushState,
        replaceState: replaceState
    };

}();
