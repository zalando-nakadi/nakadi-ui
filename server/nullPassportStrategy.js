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
  testState.stategyInstance = this;
  passport.Strategy.call(this);
  this.options = options;
  this.verify = verify;
}

// Inherit from `passport.Strategy`.
util.inherits(Strategy, passport.Strategy);

Strategy.prototype.authenticate = function(req, options) {
  if (req.query.code) {
    const profile = {
      id: 'some user',
      name: 'some name'
    };

      this.verify('__NONE__', 'fake-refresh-token12345', profile, (err, user) => {
        req.login(user, () => {
          this.redirect(req.session.returnTo || '/')
        })
      })
  } else {
    this.redirect('/auth/callback?' + querystring.stringify({code:123,...this.options}))
  }
};
