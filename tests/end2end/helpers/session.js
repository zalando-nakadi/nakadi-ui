module.exports = {

    startAll: async function(done) {
        //time needed to re-compile Elm code 5 minutes
        const COMPILE_TIMEOUT = 5 * 60 * 60 * 1000;
        //browser redraw TIMEOUT 3 seconds
        const TIMEOUT = 30000;
        //small input delay 100 milliseconds
        const DELAY = 100;

        jasmine.DEFAULT_TIMEOUT_INTERVAL = COMPILE_TIMEOUT;

        // run Identity Provider mock
        const ipm = require('../../mocks/testIPM');
        this.ipmServer = ipm.listen(5000);

        // run nakadi mock
        const nakadi = require('../../mocks/testNakadi');
        this.nakadiServer = nakadi.listen(5341);


        const App = require('../../../server/App');
        const conf = require('../../mocks/data/appConf.json');
        this.baseUrl = conf.baseUrl;
        const baseUrl = this.baseUrl;

        const app = App(conf);
        this.server = app.listen(conf.port);

        this.browser = await require('./../helpers/browser').getBrowser().catch(err => console.log("Hello", err));

        console.log("hello", this.browser)
        this.browser.sleep ||
        this.browser.addCommand("sleep", function async(time) {
            //default 100 ms
            time = time || DELAY;
            let p = new Promise(function(resolve) {
                setTimeout(function() {
                    resolve(true)
                }, time)
            }, false);

            return this.waitUntil(function() {
                return p;
            })
        });

        this.browser.login ||
        this.browser.addCommand("login", function async(url) {
            return this.url(baseUrl + (url || ''))
            .waitForVisible('=Login', COMPILE_TIMEOUT)
            .click('=Login')
            .waitForVisible('.user-menu', TIMEOUT)
            .catch(fail)
        }, false);

        this.browser.logout ||
        this.browser.addCommand("logout", function async(done) {
            return this.click('.user-menu')
            .waitForVisible('.user-menu__logout', TIMEOUT)
            .click('.user-menu__logout')
            .waitForVisible('section.login .login-btn', TIMEOUT)
            .catch(fail)
            .call(done);
        }, false);

        this.browser.setViewportSize({
            width: 1400,
            height: 900
        }).then(done);
    },

    stopAll: function(done) {
        this.nakadiServer.close();
        this.ipmServer.close();
        this.server.close();
        this.browser.end().call(done);
    }
};
