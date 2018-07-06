describe('auth module', function() {
    const staticMiddleware = require('../../server/auth');

    it('should return one static route handler in prod mode', function() {
        const middleware = staticMiddleware({
            strategy: '../tests/mocks/testPassportStrategy'
        });

        expect(middleware).toBeAny(Array);
    });

    it('should pass in same object async', function(done) {
        const testData = {a: 1};
        staticMiddleware.__private.pass(testData, function(err, data) {
            expect(err).toBeFalsy();
            expect(data).toBe(testData);
            done()
        });
    });

    it('should pass in same object async', function(done) {
        const testData = {a: 1};
        staticMiddleware.__private.pass(testData, function(err, data) {
            expect(err).toBeFalsy();
            expect(data).toBe(testData);
            done()
        });
    });

    it('should return user object from user profile with name', function(done) {
        const profile = {
            id: '123',
            name: 'serg',
            someThingElse: 1
        };

        const accessToken = '111';
        const refreshToken = '1234';


        staticMiddleware.__private.profileToUser(accessToken, refreshToken, profile, function(err, data) {
            expect(err).toBeFalsy();
            expect(data).toEqual({
                id: '123',
                name: 'serg',
                accessToken: '111',
                refreshToken: '1234'
            });
            done()
        });
    });

    it('should return user object from user profile with displayName', function(done) {
        const profile = {
            id: '123',
            displayName: 'serg',
            someThingElse: 1
        };

        const accessToken = '111';
        const refreshToken = '1234';


        staticMiddleware.__private.profileToUser(accessToken, refreshToken, profile, function(err, data) {
            expect(err).toBeFalsy();
            expect(data).toEqual({
                id: '123',
                name: 'serg',
                accessToken: '111',
                refreshToken: '1234'
            });
            done()
        });
    })
});
