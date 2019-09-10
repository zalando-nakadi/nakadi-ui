describe('DataGrid', function() {

    const session = require('./helpers/session');
    beforeAll(session.startAll);

    afterAll(session.stopAll);


    it('should change sort order on header click', function(done) {

        this.browser.login('#types')
        .waitForVisible('.grid__table-container', 1000)
        .click('th*=Event type name')
        .getText('.grid__table-container .dc-table__td').then(function(text) {
            expect(text.filter(txt => txt.startsWith('aruha.'))).toEqual([
                'aruha.test-event-test1.ver_6',
                'aruha.test-event-test2.ver_6',
                'aruha.test-event-test3.ver_6',
                'aruha.test-event-test4.ver_6',
                'aruha.test-event-test5.ver_6',
                'aruha.test-event.ver_5'
            ], 'wrong elements found');
        })
        .click('th*=Event type name')
        .getText('.grid__table-container .dc-table__td').then(function(text) {
            expect(text.filter(txt => txt.startsWith('aruha.'))).toEqual([
                'aruha.test-event.ver_5',
                'aruha.test-event-test5.ver_6',
                'aruha.test-event-test4.ver_6',
                'aruha.test-event-test3.ver_6',
                'aruha.test-event-test2.ver_6',
                'aruha.test-event-test1.ver_6'], 'wrong elements found');
        })
        .catch(fail)
        .logout(done)

    });


    it('should filter elements', function(done) {

        this.browser.login('#types')
        .waitForVisible('.grid__table-container', 1000)
        .click('#gridFilterSearch')
        .setValue('#gridFilterSearch', "ver_6")
        .getText('.grid__table-container .dc-table__td').then(function(text) {
            expect(text.filter(txt => txt.startsWith('aruha.'))).toEqual([
                'aruha.test-event-test1.ver_6',
                'aruha.test-event-test2.ver_6',
                'aruha.test-event-test3.ver_6',
                'aruha.test-event-test4.ver_6',
                'aruha.test-event-test5.ver_6'], 'wrong elements found');
        })
        .catch(fail)
        .logout(done)

    });

});
