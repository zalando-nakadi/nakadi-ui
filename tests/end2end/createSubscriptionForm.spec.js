describe('Create Subscription form', function() {

    const session = require('./helpers/session');
    beforeAll(session.startAll);

    afterAll(session.stopAll);

    it('should submit default data (happy scenario)', function(done) {

        const eventTypeName = 'aruha.test-event.ver_5';
        const id = '69fba92d-d0ab-422d-a2c4-311a7d937475';

        this.browser.login('')
        .waitForVisible('h4=Welcome to Nakadi, a distributed, open-source event messaging service!', 1000)
        .click('button=Create')
        .sleep(300) //waiting for the menu animation to finish
        .click('a=Subscription')
        .waitForVisible('h4=Create Subscription', 10000)
        .isEnabled('button=Create Subscription').then(function(enabled) {
            expect(enabled).toBeFalsy('Submit btn should be disabled by default')
        })
        .setValue('#subscriptionCreateFormFieldConsumerGroup', 'test-group')
        .setValue('#subscriptionCreateFormFieldEventTypes', eventTypeName)
        .isEnabled('button=Create Subscription').then(function(enabled) {
            expect(enabled).toBeTruthy('Submit btn should be enabled if name is set')
        })
        .click('button=Create Subscription')
        .waitForVisible(`span*=${id}`, 10000)
        .getUrl().then(function(url) {
            const hash = url.split('#')[1];
            expect(hash).toBe(`subscriptions/${id}`)
        })
        .catch(fail)
        .logout(done)
    });

    it('should check for required fields', function(done) {

        this.browser.login('#createsubscription')
        .setValue('#subscriptionCreateFormFieldOwningApplication', ' ')
        .isVisible('.form-create__field-fieldeventtypes .dc--text-error').then(function(visible) {
            expect(visible).toBeTruthy('Should show error if the event type name is empty.');
        })
        .isVisible('.form-create__field-fieldowningapplication .dc--text-error').then(function(visible) {
            expect(visible).toBeTruthy('Should show error if the owning app field is empty.');
        })
        .isEnabled('button=Create Subscription').then(function(enabled) {
            expect(enabled).toBeFalsy('Submit btn should be disabled if error.')
        })
        .catch(fail)
        .logout(done)
    });

    it('should find and add ET using the search field', function(done) {

        const eventTypeName = 'aruha.test-event.ver_5';
        const eventTypeName2 = 'aruha.test-event-test5.ver_6';

        this.browser.login('#createsubscription')
        .setValue('#addEventType-input', eventTypeName)
        .waitForVisible('#addEventType-dropdown .multi-search__item--selected')
        .click('b=aruha.test-event.ver_5')
        .setValue('#addEventType-input', eventTypeName2)
        .waitForVisible('#addEventType-dropdown .multi-search__item--selected')
        .click('b=aruha.test-event-test5.ver_6')
        .sleep()
        .getValue('#subscriptionCreateFormFieldEventTypes').then(function(value) {
            const expected = `${eventTypeName}\n${eventTypeName2}`;
            expect(value).toBe(expected, 'Should be newline-separated names');
        })
        .catch(fail)
        .logout(done)
    });

    it('should show additional field if "cursors" is selected in "read from" field', function(done) {
        const readFromInput = '#subscriptionCreateFormFieldReadFrom';
        const cursorsInput = '#subscriptionCreateFormFieldCursors';

        this.browser.login('#createsubscription')
        .sleep(500) //waiting for data load from api
        .selectByValue(readFromInput, 'cursors')
        .isVisible(cursorsInput).then(function(visible) {
            expect(visible).toBeTruthy('The cursors field should be visible if the "read from" is "cursors".');
        })
        .selectByValue(readFromInput, 'end')
        .isVisible(cursorsInput).then(function(visible) {
            expect(visible).toBeFalsy('The cursors field should NOT be visible if the "read from" is "end".');
        })
        .selectByValue(readFromInput, 'begin')
        .isVisible(cursorsInput).then(function(visible) {
            expect(visible).toBeFalsy('The cursors field should NOT be visible if the "read from" is "begin".');
        })

        .catch(fail)
        .logout(done)
    });

    it('should show error if type is not found', function(done) {

        const eventTypeName = 'crazy-type';

        this.browser.login('#createsubscription')
        .setValue('#subscriptionCreateFormFieldEventTypes', eventTypeName)
        .isVisible('.form-create__field-fieldeventtypes .dc--text-error').then(function(visible) {
            expect(visible).toBeTruthy('Should show error if the event type name is empty.');
        })
        .getText('.form-create__field-fieldeventtypes .dc--text-error').then(function(text) {
            expect(text).toBe(`Event Type(s) not found: ${eventTypeName}`, 'Error text is wrong.');
        })
        .catch(fail)
        .logout(done)
    });

    it('should show error if cursors format is wrong', function(done) {
        const readFromInput = '#subscriptionCreateFormFieldReadFrom';
        const cursorsCorrect = '[{"event_type":"shop.updater.changed", "partition":"0", "offset":"00000000000123456"}]';
        const cursorsIncorrect = '[{"event_type_crazy":"shop.updater.changed", "partition":"0", "offset":"00000000000123456"}]';

        this.browser.login('#createsubscription')
        .selectByValue(readFromInput, 'cursors')
        .setValue('#subscriptionCreateFormFieldCursors', cursorsCorrect)
        .isVisible('.form-create__field-fieldcursors .dc--text-error').then(function(visible) {
            expect(visible).toBeFalsy('Should NOT show error for correct format.');
        })
        .setValue('#subscriptionCreateFormFieldCursors', cursorsIncorrect)
        .isVisible('.form-create__field-fieldcursors .dc--text-error').then(function(visible) {
            expect(visible).toBeTruthy('Should NOT show error for correct format.');
        })

        .catch(fail)
        .logout(done)
    });
});
