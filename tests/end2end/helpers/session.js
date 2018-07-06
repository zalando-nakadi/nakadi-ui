module.exports = {

    startAll: function(done) {
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

        this.browser = require('./../helpers/browser').getBrowser();

        this.browser.sleep ||
        this.browser.addCommand("sleep", function async(time) {
            //default 100 ms
            time = time || DELAY;
            let p = new Promise(function(resolve) {
                setTimeout(function() {
                    resolve(true)
                }, time)
            });

            return this.waitUntil(function() {
                return p;
            })
        });

        // workaround for chromedriver loosing some chars
        // similar to this issue https://github.com/angular/protractor/issues/698
        this.browser.input ||
        this.browser.addCommand("input", function async(selector, value) {
            let chars = value.split('');
            return chars.reduce((res, char) => {
                return res.keys(char).sleep(50);
            }, this.setValue(selector, ''))
        });

        this.browser.login ||
        this.browser.addCommand("login", function async(url) {
            return this.url(baseUrl + (url || ''))
            .waitForVisible('=Login', COMPILE_TIMEOUT)
            .click('=Login')
            .waitForVisible('.user-menu', TIMEOUT)
            .catch(fail)
        });

        this.browser.logout ||
        this.browser.addCommand("logout", function async(done) {
            return this.click('.user-menu')
            .waitForVisible('.user-menu__logout', TIMEOUT)
            .click('.user-menu__logout')
            .waitForVisible('section.login .login-btn', TIMEOUT)
            .catch(fail)
            .call(done);
        });

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
