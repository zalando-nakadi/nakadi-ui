describe('staticFile module', function() {
    const staticMiddleware = require('../../server/staticFiles');

    it('should return one static route handler in prod mode', function() {
        const middleware = staticMiddleware(true);
        expect(middleware).toBeAny(Function);
    });

    it('should return array of functions in dev mode', function() {
        const middleware = staticMiddleware(false);
        expect(middleware).toBeAny(Array);
        expect(middleware[0]).toBeAny(Function);
        expect(middleware[1]).toBeAny(Function);
    });
});


