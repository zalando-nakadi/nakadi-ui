/**
 * @module
 * Proxy all request to /api/nakadi-sql to real Nakadi SQL server endpoint
 * adding authorization token
 *
 * @param {object} config
 * @param {object} [config.authorize] authorization parameters
 * @param {object} config.nakadiApiSqlUrl Nakadi API URL
 *
 * @returns {function[]} list of expressjs middleware functions
 */

const proxy = require('express-http-proxy');
const logger = require('./logger');

module.exports = function NakadiSqlProxyRoute(config) {
    return [
        authorization(config.authorize),
        proxy(config.nakadiApiSqlUrl, {
            proxyReqOptDecorator: function(proxyReq, origReq) {
                if (!origReq.authorizationToken) {
                    origReq.log('warn', 'No nakadi authorizationToken(server to server) in the request object.');
                    return;
                }

                // Workaround for https://github.com/zalando/nakadi/issues/792
                // Nakadi doesn't accept fake tokens even with NAKADI_OAUTH2_MODE=OFF
                if (origReq.authorizationToken === '__NONE__') {
                    return proxyReq;
                }

                proxyReq.headers['Authorization'] = 'Bearer ' + origReq.authorizationToken;
                return proxyReq;
            }
        })
    ]
};

/**
 * Select the authorization strategy
 * @param {object} conf
 * @param {string} [conf.strategy] Node module name, should export middleware function
 * @param {object} [conf.options] Options object for module
 * @returns {function(req, res, next)}
 */
function authorization(conf) {
    return (conf && conf.strategy) ?
        require(conf.strategy)(logger, conf.options) :
        defaultAuthorization
}

/**
 * Default authorization just uses user accessToken as a Nakadi access token
 *
 * @param {Request} req
 * @param {Response} res
 * @param {function} next
 */
function defaultAuthorization(req, res, next) {
    req.authorizationToken = req.user.accessToken;
    next();
}
