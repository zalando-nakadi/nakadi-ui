describe('MultiSearch', function() {

    const session = require('./helpers/session');
    beforeAll(session.startAll);

    afterAll(session.stopAll);


    it('should open popup and show search result', function(done) {

        this.browser.login()
        .click('#multiSearch-input')
        //empty filter message
        .waitForVisible('#multiSearch-dropdown', 1000)
        .getText('#multiSearch-dropdown').then(function(text) {
            expect(text).toContain('Start typing to search event type')
        })
        //Normal search result

        .setValue('#multiSearch-input', 'ver_6')
        .getText('#multiSearch-dropdown .multi-search__item-name').then(function(items) {
            expect(items).toEqual([
                'aruha.test-event-test1.ver_6',
                'aruha.test-event-test2.ver_6',
                'aruha.test-event-test3.ver_6',
                'aruha.test-event-test4.ver_6',
                'aruha.test-event-test5.ver_6'
            ], 'wrong elements found');
        })
        .catch(fail)
        .logout(done)
    });

    it('should open popup and show not found message', function(done) {

        this.browser.login()
        .click('#multiSearch-input')
        .waitForVisible('#multiSearch-dropdown', 1000)
        .setValue('#multiSearch-input','crazy-input')
        .getText('#multiSearch-dropdown').then(function(text) {
            expect(text).toContain('Nothing found for: crazy-input')
        })
        .catch(fail)
        .logout(done)
    });

    it('should redirect to details page after mouse click on result', function(done) {

        this.browser.login()
        .click('#multiSearch-input')
        .setValue('#multiSearch-input', 'ver_6')
        .click('#multiSearch-dropdown', '=aruha.test-event-test3.ver_6')
        .getUrl().then(function(url) {
            expect(url).toContain('#types/aruha.test-event-test3.ver_6')
        })
        .catch(fail)
        .logout(done)
    });

    it('should redirect to first details page after hitting Enter', function(done) {

        this.browser.login()
        .click('#multiSearch-input')
        .setValue('#multiSearch-input', 'ver_6')

        .addValue('#multiSearch-input', 'Enter')

        .getUrl().then(function(url) {
            expect(url).toContain('#types/aruha.test-event-test1.ver_6')
        })
        .catch(fail)
        .logout(done)
    });

    it('should redirect to details page after hitting Up/Down and Enter', function(done) {

        this.browser.login()
        .click('#multiSearch-input')
        .setValue('#multiSearch-input', '_6')

        .addValue('#multiSearch-input', 'ArrowDown')
        .addValue('#multiSearch-input', 'ArrowDown')
        .addValue('#multiSearch-input', 'ArrowDown')

        .addValue('#multiSearch-input', 'ArrowUp')
        .addValue('#multiSearch-input', 'ArrowDown')
        .addValue('#multiSearch-input', 'Enter')

        .getUrl().then(function(url) {
            expect(url).toContain('#types/aruha.test-event-test4.ver_6')
        })
        .catch(fail)
        .logout(done)
    });

    it('should redirect to details page after hitting PageDown and Enter', function(done) {

        this.browser.login()
        .click('#multiSearch-input')
        .setValue('#multiSearch-input', '_6')

        .addValue('#multiSearch-input', 'PageDown')
        .addValue('#multiSearch-input', 'Enter')
        .getUrl().then(function(url) {
            expect(url).toContain('#types/aruha.test-event-test5.ver_6')
        })
        .catch(fail)
        .logout(done)
    });


    it('should redirect to details page after hitting PageUp and Enter', function(done) {

        this.browser.login()
        .click('#multiSearch-input')
        .setValue('#multiSearch-input', 'ver_6')
        .addValue('#multiSearch-input', 'ArrowDown')
        .addValue('#multiSearch-input', 'ArrowDown')
        .addValue('#multiSearch-input', 'PageUp')
        .addValue('#multiSearch-input', 'Enter')
        .getUrl().then(function(url) {
            expect(url).toContain('#types/aruha.test-event-test1.ver_6')
        })
        .catch(fail)
        .logout(done)
    });
});
