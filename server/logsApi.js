const express = require('express');
const fetch = require('node-fetch');
const querystring = require('querystring');

const DAY = 1000 * 60 * 60 * 24;
const DEFAULT_HISTORY = 4 * DAY;
const MAX_COUNT = 5000;
const MAX_COUNT_FACET = 1000;
const DEFAULT_COLUMNS = 'datestamp,app,method,url,statusCode,respTime';
const OK = 200;
const ERROR = 502;

/**
 * @module logsApi
 * Implements API for requesting Nakadi logs from scalyr.com
 *
 * @param {Object} options
 * @param {String} options.scalyrUrl
 * @param {String} options.scalyrKey
 * @param {String} options.scalyrBaseFilter
 *
 * @returns {Router}
 */
module.exports = function logsApi(options) {
    const defaults = {
        filter: options.scalyrBaseFilter,
        scalyrUrl: '',
        scalyrKey: ''
    };

    const conf = Object.assign({}, defaults, options);

    return express()
    .get('/event/:id/publishers', getEventPublishers)
    .get('/event/:id/consumers', getEventConsumers)
    .get('/event/:id/', getEventTypeLogs);


    /**
     * Return list of publishers for the selected Event Type
     *
     * @api
     *
     * @param {Request} req
     * @param {Response} res
     */
    function getEventPublishers(req, res) {
        const id = escape(req.params.id);
        const params = {
            filter: `($method=="POST") and ($eventTypeName=="${id}")`,
            field: 'app',
            endTime: req.query.toTime || ''
        };

        fetchFacetQuery(res, params);
    }

    /**
     * Return list of Consumers for the selected Event Type
     *
     * @api
     *
     * @param {Request} req
     * @param {Response} res
     */
    function getEventConsumers(req, res) {
        const id = escape(req.params.id);
        const startTime = req.query.startTime || '';
        const endTime = req.query.endTime || '';

        const params = {
            filter: `($method=="GET") and ($eventTypeName=="${id}")`,
            field: 'app',
            startTime,
            endTime
        };

        fetchFacetQuery(res, params);
    }

    /**
     * Return list of all log messages for the selected Event Type
     *
     * @api
     *
     * @param {Request} req
     * @param {Response} res
     */
    function getEventTypeLogs(req, res) {
        const id = escape(req.params.id);
        const startTime = req.query.startTime || '';
        const endTime = req.query.endTime || '';

        const params = {
            filter: ` ($eventTypeName=="${id}")`,
            startTime,
            endTime
        };

        fetchQuery(res, params);
    }

    /**
     * Fetch "Facet" logs from scalyr
     * and pipe it to the given response or
     * respond with 500 error
     *
     * @param {Response} res
     * @param {Object} options
     * @param {String} [options.filter]
     * @param {String} [options.field]
     * @param {Number} [options.startTime]
     * @param {Number} [options.endTime]
     * */
    function fetchFacetQuery(res, options) {
        const params = {
            token: conf.scalyrKey,
            queryType: 'facet',
            filter: conf.filter + options.filter,
            maxCount: MAX_COUNT_FACET,
            field: options.field || 'app',
            startTime: options.startTime || Date.now() - DEFAULT_HISTORY,
            endTime: options.endTime || Date.now(),
        };

        const query = querystring.stringify(params);

        fetch(`${conf.scalyrUrl}facetQuery?${query}`)
        .then(pipe(res))
        .catch(errorHandler(res));
    }

    /**
     * Fetch logs from scalyr
     * and pipe it to the given response or
     * respond with 500 error
     *
     * @param {Response} res
     * @param {Object} options
     * @param {String} [options.filter]
     * @param {String} [options.columns]
     * @param {Number} [options.startTime]
     * @param {Number} [options.endTime]
     */
    function fetchQuery(res, options) {

        const params = {
            token: conf.scalyrKey,
            queryType: 'log',
            filter: conf.filter + options.filter,
            startTime: options.startTime || Date.now() - DEFAULT_HISTORY,
            endTime: options.endTime || Date.now(),
            pageMode: 'tail',
            columns: options.columns || DEFAULT_COLUMNS,
            maxCount: MAX_COUNT
        };

        const query = querystring.stringify(params);
        fetch(`${conf.scalyrUrl}query?${query}`)
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
            res.log('error', 'ScalyrApi: Error requesting logs: ', err);
            res.status(ERROR).send(err);
        }
    }

    /**
     * Escape special symbols in the string ', ", \
     *
     * @param {String} str
     * @returns {String}
     */
    function escape(str) {
        return (str + "")
        .replace(/\\/g, "\\\\")
        .replace(/'/g, "\\'")
        .replace(/"/g, "\\\"");
    }
};
