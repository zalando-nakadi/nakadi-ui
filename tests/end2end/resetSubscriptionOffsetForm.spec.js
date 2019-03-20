describe('Reset subscription offset form', function() {

    const session = require('./helpers/session');
    beforeAll(session.startAll);

    afterAll(session.stopAll);

    it('should close on cancel click', function(done) {

        this.browser.login('#subscriptions/2151d17e-a6a2-4661-bdc8-010101010101')
        .waitForVisible('button=Change',1000)
        .click('button=Change')
        .waitForVisible('#subscriptionEditOffset',1000)
        .click('button=Cancel')
        .waitForVisible('span=000000000000000009',1000)
        .catch(fail)
        .logout(done)
    });

    it('should change offset', function(done) {

        this.browser.login('#subscriptions/2151d17e-a6a2-4661-bdc8-010101010101')
        .waitForVisible('button=Change',1000)
        .click('button=Change')
        .waitForVisible('#subscriptionEditOffset',1000)
        .input('#subscriptionEditOffset', '000000000000000001')
        .click('button=Set offset')
        .waitForVisible('span=000000000000000001', 5000)
        .catch(fail)
        .logout(done)
    });

    it('should display the server error message', function(done) {

        this.browser.login('#subscriptions/2151d17e-a6a2-4661-bdc8-010101010101')
        .waitForVisible('button=Change',1000)
        .click('button=Change')
        .waitForVisible('#subscriptionEditOffset',1000)
        .input('#subscriptionEditOffset','crazy')
        .click('button=Set offset')
        .waitForVisible('h1=Assertion fail', 5000)
        .catch(fail)
        .logout(done)
    });
});
