describe('Create Event type form', function() {

    const session = require('./helpers/session');
    beforeAll(session.startAll);

    afterAll(session.stopAll);

    it('should submit default data (happy scenario)', function(done) {

        const eventTypeName = 'test.event-type_name';

        this.browser.login('')
        .waitForVisible('h4=Welcome to Nakadi, a distributed, open-source event messaging service!', 1000)
        .click('button=Create')
        .click('a=Event Type')
        .waitForVisible('h4=Create Event Type', 1000)
        .isEnabled('button=Create Event Type').then(function(enabled) {
            expect(enabled).toBeFalsy('Submit btn should be disabled by default')
        })
        .setValue('#eventTypeCreateFormFieldName', eventTypeName)
        .isEnabled('button=Create Event Type').then(function(enabled) {
            expect(enabled).toBeFalsy('Submit btn should be still disabled if name is set but no Audience selected')
        })
        .selectByValue("#eventTypeCreateFormFieldAudience", 'component-internal')
        .isEnabled('button=Create Event Type').then(function(enabled) {
            expect(enabled).toBeFalsy('Submit btn should be disabled if owning application is not set')
        })
        .setValue('#eventTypeCreateFormFieldOwningApplication', 'some-owning-app')
        .isEnabled('button=Create Event Type').then(function(enabled) {
            expect(enabled).toBeTruthy('Submit btn should be enabled if name and owning app are set')
        })
        .click('button=Create Event Type')
        .waitForVisible(`span*=${eventTypeName}`, 10000)
        .getUrl().then(function(url) {
            const hash = url.split('#')[1];
            expect(hash).toBe(`types/${eventTypeName}`)
        })
        .catch(fail)
        .logout(done)
    });

    it('should check for required fields', function(done) {

        this.browser.login('#createtype')
        .setValue('#eventTypeCreateFormFieldOwningApplication', ' ')
        .isVisible('.form-create__field-fieldname .dc--text-error').then(function(visible) {
            expect(visible).toBeTruthy('Should show error if the name is empty.');
        })
        .isVisible('.form-create__field-fieldowningapplication .dc--text-error').then(function(visible) {
            expect(visible).toBeTruthy('Should show error if the owning app field is empty.');
        })
        .isEnabled('button=Create Event Type').then(function(enabled) {
            expect(enabled).toBeFalsy('Submit btn should be disabled if error.')
        })
        .catch(fail)
        .logout(done)
    });

    it('should check for unique name', function(done) {

        const eventTypeName = 'aruha.test-event.ver_5';

        this.browser.login('#createtype')
        .setValue('#eventTypeCreateFormFieldName', eventTypeName)
        .isEnabled('button=Create Event Type').then(function(enabled) {
            expect(enabled).toBeFalsy('Submit btn should be disabled if error.')
        })
        .isVisible('div=Name is already used.').then(function(visible) {
            expect(visible).toBeTruthy('Should show error if the name already taken.');
        })
        .catch(fail)
        .logout(done)
    });

    it('should show additional field if "hash" strategy is selected', function(done) {
        const strategyInput = '#eventTypeCreateFormFieldPartitionStrategy';
        const keyInput = '#eventTypeCreateFormFieldPartitionKeyFields';

        this.browser.login('#createtype')
        .waitForVisible(strategyInput)
        .selectByValue(strategyInput, 'hash')
        .waitForExist(keyInput)
        .then(function(visible) {
            expect(visible).toBeTruthy('The partition key field should be visible if the strategy is "hash".');
        })
        .selectByValue(strategyInput, 'random')
        .isExisting(keyInput).then(function(visible) {
            expect(visible).toBeFalsy('The partition key field should NOT be visible if the strategy is "random".');
        })
        .selectByValue(strategyInput, 'user_defined')
        .isExisting(keyInput).then(function(visible) {
            expect(visible).toBeFalsy('The partition key field should NOT be visible if the strategy is "user_defined".');
        })
        .catch(fail)
        .logout(done)
    });
});
