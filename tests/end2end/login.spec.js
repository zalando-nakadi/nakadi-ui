describe('end2end tests', function() {
    const session = require('./helpers/session');
    beforeAll(session.startAll);
    afterAll(session.stopAll);
    const TIMEOUT = 5000;
    it('should just Login and Logout', function(done) {
        // check title
        this.browser.url(this.baseUrl)
        .getTitle().then(function(title) {
            expect(title).toContain('Nakadi UI')
        })
        .waitForVisible('section.login h3', TIMEOUT)
        // check login form
        .getText('section.login h3').then(function(text) {
            expect(text).toContain('Please log in to continue...')
        })
        .getText('section.login .login-btn').then(function(text) {
            expect(text).toContain('Login')
        })
        // Login
        .click('=Login')
        .waitForVisible('header .user-menu', TIMEOUT)
        .click('.user-menu')
        .getText('.user-menu__name').then(function(text) {
            expect(text).toContain('fake name')
        })

        // Check that initial navigation tab is Home
        .waitForVisible('.app', TIMEOUT)
        .getText('.app').then(function(text) {
            expect(text).toContain('Welcome to Nakadi, a distributed, open-source event messaging service!')
        })

        // Logout
        .click('.user-menu')
        .waitForVisible('.user-menu__logout', TIMEOUT)
        .click('.user-menu__logout')
        .waitForVisible('section.login .login-btn', TIMEOUT)
        .getText('section.login .login-btn').then(function(text) {
            expect(text).toContain('Login')
        })
        .catch(fail)
        .call(done);
    });

    it('should go to "Event Types" tab if url has hash #types', function(done) {

        this.browser.login('#types')
        // Check that initial navigation works during login
        //  if url has #types than we switching to types tab
        .waitForVisible('.main-content', TIMEOUT)
        .getText('.main-content').then(function(text) {
            expect(text).toContain('aruha.test-event-test1.ver_6')
        })
        .catch(fail)
        .logout(done)
    });

    it('should go to "Not Found" page if url has unknown hash', function(done) {

        this.browser.login('#crazystaff')
        // Check that initial navigation works during login
        //  if url has #types than we switching to types tab
        .waitForVisible('.dc-container', TIMEOUT)
        .getText('.dc-container').then(function(text) {
            expect(text).toContain('Not found')
        })
        .catch(fail)
        .logout(done)
    });
});
