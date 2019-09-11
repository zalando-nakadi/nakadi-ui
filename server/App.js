/**
 * @module
 * Main Nakadi UI App module
 * exports express app
 */
const os = require('os');
const express = require('express');
const sessions = require('client-sessions');
const bodyParser = require('body-parser');

const logger = require('./logger');
const auth = require('./auth');
const nakadiApi = require('./nakadiApi');
const nakadiSqlApi = require('./nakadiSqlApi');
const teamsApi = require('./teamsApi');
const logsApi = require('./logsApi');
const validationApi = require('./validationApi');
const staticFiles = require('./staticFiles');
/**
 * @typedef  function(req, res, next) App
 */

/**
 * Creates App as an Express router function
 *
 * @param {object} config
 * @returns {App}
 */
module.exports = function App(config) {

    const app = express()
    .get('/health', getHealth)
    .use(logger.init)
    .use(sessions(config.cookie))
    .use(bodyParser.json({limit: '50mb'}))
    .use(auth(config.auth, config.settings))
    .use(analytics(config.analytics, logger))
    .use('/api/teams', authentication, teamsApi(config))
    .use('/api/logs', authentication, logsApi(config.logsApi))
    .use('/api/nakadi', authentication, nakadiApi(config))
    .use('/api/nakadi-sql', authentication, nakadiSqlApi(config))
    .use('/api/validation', authentication,validationApi(config))
    .use(staticFiles(config.productionMode))
    .use(logger.errorHandler);

    checkSsl(app, config.serverOptions);
    return app;
};

/**
 * Set https listener to app if config contains ssl keys
 * if not, http listener
 * @example
 * var server = app.listen(3000);
 * ...
 * server.close()
 *
 * @param {App} app
 * @param {object} sslOptions
 * @param {string} sslOptions.key
 * @returns {App}
 */
function checkSsl(app, sslOptions) {
    if (!sslOptions.key) {

        const http = require('http');
        app.listen = function() {
            const server = http.createServer(app);
            server.listen.apply(server, arguments);
            return server;
        };

    } else {

        const https = require('https');
        app.listen = function() {
            const server = https.createServer(sslOptions, app);
            server.listen.apply(server, arguments);
            return server;
        };
    }

    return app;
}

/**
 * Collects and exposes memory statistics (in megabytes)
 * for /health check and ZMON
 *
 * @param {Request} req Request object
 * @param {Response} res Response object
 */
function getHealth(req, res) {

    function inMb(n) {
        const Mb = 1024 * 1024;
        return Math.ceil(n / Mb);
    }

    const mem = process.memoryUsage();

    const stats = {
        free: inMb(os.freemem()),
        total: inMb(os.totalmem()),
        rss: inMb(mem.rss),
        heapTotal: inMb(mem.heapTotal),
        heapUsed: inMb(mem.heapUsed)
    };

    return res.json(stats);
}


/**
 * Check is the user is Authenticated
 * pass or deny future action
 * Only authenticated user allowed
 *
 * @param {Request} req
 * @param {Response} res
 * @param {function} next
 */
function authentication(req, res, next) {
    req.isAuthenticated() ? next() : res.sendStatus(401)
}


/**
 * Check if analytics strategy exists then load and initiate it.
 *
 * @param {object} config
 * @param {string} config.strategy
 * @param {object} config.options
 * @param {Logger} logger
 * @returns {function(req, res, next)}
 */
function analytics(config, logger) {

    if (!config.strategy) {
        return function(req, res, next) {
            next()
        };
    }

    const strategy = require(config.strategy);

    return strategy(config.options, logger)
}
