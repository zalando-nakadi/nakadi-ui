const passport = require('passport-strategy');
const util = require('util');
const querystring = require('querystring');

const testState = {};

module.exports.Strategy = Strategy;
//exposes last test strategy instance
module.exports.testState = testState;

/**
 *
 * @param {object} options
 * @param {function(accessToken, refreshToken, profile, done):object} verify
 * @constructor
 */
function Strategy(options, verify) {
    //console.log('new Strategy:');
    //console.log(options);
    //console.log(verify);
    testState.stategyInstance = this;
    passport.Strategy.call(this);
    this.options = options;
    this.verify = verify;
}

// Inherit from `passport.Strategy`.
util.inherits(Strategy, passport.Strategy);

Strategy.prototype.authenticate = function(req, options) {
    //console.log('authenticate');
    //console.log(req);
    //console.log(options);

    if (req.query.code) {
        const profile = {
            id: 'fakeuser',
            name: 'fake name'
        };

        this.verify('fake-access-token12345', 'fake-refresh-token12345', profile, (err, user) => {
            req.login(user, () => {
                this.redirect(req.session.returnTo || '/')
            });
        });
    } else {
        this.redirect('http://localhost:5000?' + querystring.stringify(this.options));
    }
};
