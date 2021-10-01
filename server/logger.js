/**
 * @module
 *
 * Creates logger singleton for express application
 * logs HTTP requests and provide the log() function.
 *
 * @example
 *  const logger = require('./logger');
 *
 *  express()
 *   .use(logger.init)
 *   .use(router)
 *   .use(logger.errorHandler)
 *   .listen( config.port, function() {
 *      logger.log("info", "Server listening: ", {port: config.port})
 *   };
 *
 */

const expressWinston = require('express-winston');
const winston = require('winston');
const crypto = require('crypto');
const addRequestId = require('express-request-id')();

/**
 * Global logger instance
 *
 * @singleton
 * @type {winston.Logger}
 */
const winstonInstance = new winston.Logger({
    transports: [
        new winston.transports.Console({
            json: true,
            stringify: true,
            handleExceptions: true,
            level: "debug",
            logstash: true
        })
    ]
});

/**
 * Configuration for express-winston
 *
 * @type {Object}
 */
const loggerConf = {
    winstonInstance: winstonInstance,
    dynamicMeta: getMeta,
    msg: getSafeToLogMessage,
    requestFilter: filterSensitiveRequestFields,
    responseWhitelist: ['statusCode']
};

module.exports = {
    /**
     * Log function
     * @example
     *  log('warn','Something wrong %s', msg, {requestId: 122})
     */
    log: winstonInstance.log.bind(winstonInstance),
    info: winstonInstance.info.bind(winstonInstance),
    error: winstonInstance.error.bind(winstonInstance),
    warn: winstonInstance.warn.bind(winstonInstance),
    /**
     * Init logs in express app
     * Logs all requests and inject log function to the request
     */
    init: [
        addRequestId,
        installLogger,
        switchOnBodyLogForErrors,
        expressWinston.logger(loggerConf)
    ],
    errorHandler: expressWinston.errorLogger(loggerConf)
};

/**
 * Express middleware function
 * injects log function to the request.
 * This function also adds requestId to each log message.
 *
 * @example
 *  //in some middleware
 *  req.log('warn','Something wrong %s', msg, {metaId: 122})
 *
 * @param {Request} req Request object
 * @param {Response} res Response object
 * @param {function} next Callback function
 */
function installLogger(req, res, next) {
    req.log = res.log = function() {

        const params = Array.from(arguments);

        params.push({
            requestId: req.id
        });

        winstonInstance.log.apply(winstonInstance, params);
    };

    next()
}

/**
 * Logs errors response body if statusCodes is not ok(200)
 *
 * @param {Request} req Request object
 * @param {Response} res Response object
 * @param {function} next Callback function
 */
function switchOnBodyLogForErrors(req, res, next) {
    const end = res.end;
    res.end = function(chunk, encoding) {
        if (res.statusCode !== 200) {
            req._routeWhitelists.res.push('body')
        }
        res.end = end;
        res.end(chunk, encoding);
    };

    next();
}

/**
 * Return metadata for request.
 *
 * @param {Request} req Request object
 * @param {Response} res Response object
 * @returns {Object}
 */
function getMeta(req, res) {
    let user = {};

    if (req.user) {
        user = {
            uid: req.user.id,
            uname: req.user.name
        };
    }

   return {
       requestId: req.id,
       user: user
   }
}


const mask = "***";

/**
 * Filters out auth code in the authoriztion callback URL
 * replacing it with a placeholder
 *
 * @param {String} url
 * @returns {String}
 */
function maskAuthCallbackURL(url) {
    const callbackUri = "/auth/callback?";
    return url.startsWith(callbackUri) ? callbackUri + mask : url;
}

/**
 * Returns a message that is safe to log
 * (not exposing sensitive info in the URL)
 *
 * @param {Request} req
 * @param {Response} res
 * @returns {String}
 */
function getSafeToLogMessage(req, res) {
    const url = maskAuthCallbackURL(req.url);
    return `HTTP ${req.method} ${url}`;
}

/**
 * Filters out any request fields with sensitive information
 * replacing them with a placeholder '***' if they are set
 *
 * @param {Request} req
 * @param {String} propName
 * @returns {*}
 */
function filterSensitiveRequestFields(req, propName) {

    if (propName == "headers") {
        const keys = ["authorization", "cookie"];
        const initialHeaders = Object.assign({}, req[propName]);
        return keys.reduce(maskKey, initialHeaders);

    } else if (propName == "url" || propName == "originalUrl") {
        return maskAuthCallbackURL(req[propName]);

    } else if (propName == "query") {
        return maskKey(req[propName], 'code');

    } else {
        return req[propName];
    }

    function maskKey(map, key) {
        map[key] = map[key] ? mask : map[key];
        return map;
    }
}
