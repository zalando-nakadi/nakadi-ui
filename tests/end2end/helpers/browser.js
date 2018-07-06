
const driver = require('webdriverio').remote({
    host: "127.0.0.1",
    port: 4444,
    path: '/wd/hub',
    logLevel: 'errors',
    maxInstances: 1
});

function getBrowser() {
    return driver.init({
        browserName: "chrome"
    });
}

module.exports = {
    getBrowser: getBrowser
};
