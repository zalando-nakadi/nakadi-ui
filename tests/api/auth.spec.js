describe('User auth module', function() {
    const App = require('../../server/App');
    const request = require('supertest');
    const conf = require('../mocks/data/appConf.json');
    const app = App(conf);
    const agent = request.agent(app);

    function testDone(done) {
        return (err) =>
            (err) ? done.fail(err) : done()
    }

    // for self-signed certificates
    process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

    it('should return empty object by default on /auth/user', function(done) {

        agent
        .get('/auth/user')
        .set('Accept', 'application/json')
        .expect('Content-Type', /json/)
        .expect(200, {}, testDone(done));

    });

    it('should redirect to IAM on /auth/login', function(done) {
        const target = 'http://localhost:5000?' +
            'clientID=123.apps.googleusercontent.com&' +
            'clientSecret=123&' +
            'scope=profile%20email&' +
            'callbackURL=http%3A%2F%2Flocalhost%3A3000%2Fauth%2Fcallback';

        agent
        .get('/auth/login?returnTo=some')
        .set('Accept', 'application/json')
        .expect(302)
        .expect('Location', target)
        .expect('set-cookie', /session/)
        .end(testDone(done))
    });

    it('should redirect back on /auth/callback', function(done) {

        agent
        .get('/auth/callback?code=123')
        .set('Accept', 'application/json')
        .expect(302)
        .expect('Location', 'some')
        .end(testDone(done))
    });

    it('should return user data after login on /auth/user', function(done) {

        const expectUser = {id: 'fakeuser', name: 'fake name'};

        agent
        .get('/auth/user')
        .set('Accept', 'application/json')
        .expect('Content-Type', /json/)
        .expect(200, expectUser, done);
    });

    it('should return redirect after logout on /auth/logout', function(done) {

        agent
        .get('/auth/logout?returnTo=someOther')
        .set('Accept', 'application/json')
        .expect(302)
        .expect('Location', 'someOther')
        .end(testDone(done))
    });

    it('should return empty object after logout on /auth/user', function(done) {

        agent
        .get('/auth/user')
        .set('Accept', 'application/json')
        .expect(200, {}, testDone(done));

    });
});


