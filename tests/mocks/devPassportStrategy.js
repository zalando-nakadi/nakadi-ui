const exec = require('child_process').exec
const passport = require('passport-strategy')
const util = require('util')
const querystring = require('querystring')

const testState = {}

module.exports.Strategy = Strategy
//exposes last test strategy instance
module.exports.testState = testState

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
  testState.stategyInstance = this
  passport.Strategy.call(this)
  this.options = options
  this.verify = verify
}

// Inherit from `passport.Strategy`.
util.inherits(Strategy, passport.Strategy)

Strategy.prototype.authenticate = function(req, options) {
  //console.log('authenticate');
  //console.log(req);
  //console.log(options);

  if (req.query.code) {
    const profile = {
      id: 'fakeuser',
      name: 'fake name'
    }

    exec('ztoken', (error, stdout, stderr) => {
      if (error || stderr) {
        console.log('ZTOKEN ERROR', error, stderr)
        this.error(error)
      }

      this.verify(stdout.trim(), 'fake-refresh-token12345', profile, (err, user) => {
        req.login(user, () => {
          this.redirect(req.session.returnTo || '/')
        })
      })
    })
  } else {
    this.redirect('https://localhost:3000/auth/callback?' + querystring.stringify({code:123,...this.options}))
  }
}
