const express = require('express');
const fetch = require('node-fetch');
const OK = 200;

/**
 * @module logsApi
 * Implements API for requesting teams from Teams API https://apis.zalando.net/apis/teams-api/ui
 *
 * @param {Object} options
 * @param {String} options.scalyrUrl
 * @param {String} options.scalyrKey
 * @param {String} options.scalyrBaseFilter
 *
 * @returns {Router}
 */
module.exports = function TeamApiRoute(config) {
    return [
        authorization(config.authorize),
        logsApi(config)
    ]
};

function logsApi(options) {
    const defaults = {
        teamInfoUrl: '',
    };

    const conf = Object.assign({}, defaults, options);

    return express()
        .get('/', listTeams);
        //.get('/:id', getTeam);

    /**
     * Return list of teams at Zalando
     *
     * @api
     *
     * @param {Request} req
     * @param {Response} res
     */
    function listTeams(req, res) {
        fetch('https://teams.auth.zalando.com/api/teams', {
                method: 'get',
                headers: { 'Authorization': 'Bearer ' + req.authorizationToken }
            })
            .then(pipe(res))
            .catch(errorHandler(res));
    }

    /**
     *  Return response handler
     *  Check the response status and if OK
     *  pipes all received data to response.
     *
     * @param {Response} browserRes
     * @returns {Function}
     */
    function pipe(browserRes) {
        return function(scalyrRes) {
            if (scalyrRes.status === OK) {
                scalyrRes.body.pipe(browserRes);
                return;
            }

            scalyrRes.text()
                .then(errorHandler(browserRes))
                .catch(errorHandler(browserRes));
        }
    }

    /**
     * Return error handler
     *
     * @param {Response} res
     * @returns {Function(*)}
     */
    function errorHandler(res) {
        return function(err) {
            res.log('error', 'TeamsApi: Error requesting teams: ', err);
            res.status(ERROR).send(err);
        }
    }
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
