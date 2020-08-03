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

        this.browser = await require('./../helpers/browser').getBrowser();

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

        this.browser.login ||
          this.browser.addCommand("login",  async(url) => {
              await this.browser.url(baseUrl + (url || ''))
              const login = await this.browser.$('.login-btn')
              await login.click()
              // wait for something that is common on all pages
              const userMenu = await browser.$('.user-menu')
              await userMenu.waitForExist()
          })

        this.browser.logout ||
        this.browser.addCommand("logout", async(done) => {
            const userMenu = await this.browser.$('.user-menu')
            await userMenu.click()
            const userMenuLogout = await this.browser.$('.user-menu__logout')
            await userMenuLogout.click()
            // wait for login page to re-appear
            await this.browser.$('.login-btn')
            await this.browser.call(done)
        });

        this.browser.setWindowRect(
            x=1400,
            y=900,
            width=1400,
            height=900
        ).then(done);
    },

    stopAll: function(done) {
        this.nakadiServer.close();
        this.ipmServer.close();
        this.server.close();
        this.browser.end().call(done);
    }
};
