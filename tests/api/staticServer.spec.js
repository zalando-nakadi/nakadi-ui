describe('Server functionality', function() {
    const App = require('../../server/App');
    const request = require('supertest');
    const conf = require('../mocks/data/appConf.json');
    const app = App(conf);
    const agent = request.agent(app);

    function testDone(done) {
        return (err) =>
            (err) ? done.fail(err) : done()
    }

    jasmine.DEFAULT_TIMEOUT_INTERVAL = 30000;

    it('should return status 200', function(done) {
        agent
        .get('')
        .set('Accept', 'text/html')
        .expect('Content-Type', /text\/html/)
        .expect(200, testDone(done))
    });

    it('should return status 200', function(done) {
        agent
        .get('/')
        .set('Accept', 'text/html')
        .expect('Content-Type', /text\/html/)
        .expect(200, testDone(done));
    });

    it('should return status 200', function(done) {
        agent
        .get('/index.html')
        .set('Accept', 'text/html')
        .expect('Content-Type', /text\/html/)
        .expect(200, testDone(done));
    });

    xit('should return dotfiles', function(done) {
        agent
        .get('/.well-known/schema-discovery')
        .expect(200, testDone(done));
    });


    it('should return status 404 for unknown url', function(done) {
        agent
        .get('/crazy')
        .expect('Content-Type', /text\/html/)
        .expect(404, testDone(done));
    });
});
