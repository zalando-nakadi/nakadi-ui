const _skamenskyi_fake$nakadi_ui$Native_Browser = function() {


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

    function getLoacalStoreValue(key) {
        return window.localStorage.getItem(key);
    }

    function setLoacalStoreValue(key, value) {
        return window.localStorage.setItem(key, value);
        return _elm_lang$core$Platform_Cmd$none
    }


    function startDebugger(dummy) {
        debugger;
        return dummy
    }

    function getElementWidth(id) {
        const el = window.document.getElementById(id);
        if (!el) {
            console.warn("Element not found. id=" + id);
            return 0;
        }

        return el.clientWidth
    }

    function getElementHeight(id) {
        const el = window.document.getElementById(id);
        if (!el) {
            console.warn("Element not found. id=" + id);
            return 0;
        }

        return el.clientHeight
    }

    function copyToClipboard(str) {
        const el = document.createElement('textarea')
        el.value = str
        el.setAttribute('readonly', '')
        el.style.position = 'absolute'
        el.style.left = '-9999px'
        document.body.appendChild(el)
        el.select()
        document.execCommand('copy')
        document.body.removeChild(el)
        return _elm_lang$core$Platform_Cmd$none
    }

    let getTime = null;

    try {
        performance.now();
        getTime = function() {
            return (performance.now() / 1000).toFixed(4);
        }
    }
    catch (e) {
        getTime = function() {
            const time = new Date();
            return time.getSeconds() + "." + time.getMilliseconds();
        }
    }

    function log(value, dummy) {
        console.log(getTime(), value);
        return dummy;
    }

    return {
        setLocation: setLocation,
        getLocation: getLocation,
        pushState: pushState,
        replaceState: replaceState,
        startDebugger: startDebugger,
        getElementWidth: getElementWidth,
        getElementHeight: getElementHeight,
        copyToClipboard: copyToClipboard,
        log: F2(log)
    };

}();
