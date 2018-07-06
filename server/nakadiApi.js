/**
 * @module
 * Proxy all request to /api/nakadi to real Nakadi server endpoint
 * adding authorization token
 *
 * @param {object} config
 * @param {object} [config.authorize] authorization parameters
 * @param {object} config.nakadiApiUrl Nakadi API URL
 *
 * @returns {function[]} list of expressjs middleware functions
 */

const proxy = require('express-http-proxy');
const logger = require('./logger');

module.exports = function NakadiProxyRoute(config) {
    return [
        authorization(config.authorize),
        proxy(config.nakadiApiUrl, {
            proxyReqOptDecorator: function(proxyReq, origReq) {
                if (!origReq.authorizationToken) {
                    origReq.log('warn', 'No nakadi authorizationToken(server to server) in the request object.');
                    return;
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
