describe('Reset subscription offset form', function() {

    const session = require('./helpers/session');
    beforeAll(session.startAll);

    afterAll(session.stopAll);

    it('should close on cancel click', function(done) {

        this.browser.login('#subscriptions/2151d17e-a6a2-4661-bdc8-010101010101')
        .waitForVisible('button=Change')
        .click('button=Change')
        .waitForVisible('#subscriptionEditOffset')
        .click('button=Cancel')
        .waitForVisible('span=000000000000000009')
        .catch(fail)
        .logout(done)
    });

    it('should change offset', function(done) {

        this.browser.login('#subscriptions/2151d17e-a6a2-4661-bdc8-010101010101')
        .waitForVisible('button=Change')
        .click('button=Change')
        .waitForVisible('#subscriptionEditOffset')
        .setValue('#subscriptionEditOffset', '000000000000000001')
        .waitForExist('button=Set offset')
        .click('button=Set offset')
        .waitForExist('span=000000000000000001')
        .catch(fail)
        .logout(done)
    });

    it('should display the server error message', function(done) {

        this.browser.login('#subscriptions/2151d17e-a6a2-4661-bdc8-010101010101')
        .waitForVisible('button=Change')
        .click('button=Change')
        .waitForVisible('#subscriptionEditOffset')
        .setValue('#subscriptionEditOffset','crazy')
        .waitForExist('button=Set offset')
        .click('button=Set offset')
        .waitForExist('h1=Assertion fail')
        .catch(fail)
        .logout(done)
    });
});
