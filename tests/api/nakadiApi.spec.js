describe('Nakadi proxy', function() {
    const App = require('../../server/App');
    const nakadiMock = require('../mocks/testNakadi');
    const request = require('supertest');
    const conf = require('../mocks/data/appConf.json');

    const app = App(conf);
    const agent = request.agent(app);


    // for self-signed certificates
    process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

    it('should reject unauthorised users', function(done) {

        agent
        .get('/api/nakadi/event-types')
        .set('Accept', 'application/json')
        .expect(401, (err) =>
            (err) ? done.fail(err) : done()
        );

    });

    it('should reject unauthorised users', function(done) {
        const nakadi = nakadiMock.listen(5341);
        const expectContent = require('../mocks/data/testEventTypes.json');
        agent
        .get('/auth/callback?code=111').end(loginEnd);


        function loginEnd(err, res) {
            if (err) return err;

            agent
            .get('/api/nakadi/event-types')
            .set('Accept', 'application/json')
            //.set('Accept', 'text/html')
            .expect(200, expectContent, function(err, res) {
                nakadiMock.close();
                if (err) done.fail(err);
                done()
            });
        }
    });
});
