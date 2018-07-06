const express = require('express');
const validateEventType = require('./validation').validateEventType;
const fetch = require('node-fetch');

/**
 * @module
 * This is a event type validation (linter) endpoints.
 *
 *
 * @param {object} settings

 * @returns {function[]}
 */
module.exports = (settings) => {
    const port = settings.port;
    const protocol = settings.serverOptions.key ? 'https' : 'http';

    return express()

    .get('/:name', validateExitingEventType)
    .get('/', validateAllExitingEventType)
    .post('/', validateNewEventType);


    /**
     * Validate all Event Types in Nakadi and return a full list of issues.
     *
     * @param {Request} req
     * @param {Response} res
     * @param {function} next
     */
    function validateAllExitingEventType(req, res, next) {
        // Call myself to get the body of all event types.
        // (It can be a separate service in the future)
        const url = `${protocol}://127.0.0.1:${port}/api/nakadi/event-types/`;

        fetch(url, {headers: req.headers})
        .then(getBody)
        .then(eventType => makeResponseAll(eventType, res))
        .catch(function(err) {
            res.status(400).json(`Error fetching event types. ${err.message}.`);
        });
    }

    /**
     * Validate given Event Type json and returns list of issues.
     *
     * @param {Request} req
     * @param {Response} res
     * @param {function} next
     */
    function validateExitingEventType(req, res, next) {
        const eventTypeName = req.params.name || '';

        //Call myself to get the body of the event type.
        //(It can be a separate service in the future)
        const url = `${protocol}://127.0.0.1:${port}/api/nakadi/event-types/${eventTypeName}`;

        fetch(url, {headers: req.headers})
        .then(getBody)
        .then(eventType => makeResponse(eventType, res))
        .catch(function(err) {
            res.status(400).json(`Error fetching event type. ${err.message}.`);
        });
    }

    function getBody(nakadiResponse) {

        if (nakadiResponse.status !== 200) {
            return nakadiResponse.text()
            .then(function(errText) {
                const errMessage = `Status:${nakadiResponse.status}, ${nakadiResponse.statusText}. Nakadi: ${errText}`
                throw new Error(errMessage)
            });
        }

        return nakadiResponse.json();
    }

    /**
     * Validate given Event Type json and returns list of issues.
     *
     * @param {Request} req
     * @param {Response} res
     * @param {function} next
     */
    function validateNewEventType(req, res, next) {
        const eventType = req.body;

        if (!eventType || !eventType.name) {
            return res.status(400).json('Wrong input. No event type found in the request body.');
        }

        makeResponse(eventType, res)
    }

    /**
     * Run validation of Event type and put results to the response,
     * or put the error response if validation crashed.
     *
     * @param eventType
     * @param res
     */
    function makeResponse(eventType, res) {
        try {
            const result = validateEventType(eventType);
            res.json(result);
        } catch (error) {
            res.log('error', 'Internal server error during validation of the event type.', error);
            res.status(500).json('Internal server error during validation of the event type.');
        }
    }

    /**
     * Run validation of Event type list and put results to the response,
     * or put the error response if validation crashed.
     *
     * @param eventTypes
     * @param res
     */
    function makeResponseAll(eventTypes, res) {
        try {

            const result = eventTypes.map(validateEventType);
            res.json(result);
        } catch (error) {
            res.log('error', 'Internal server error during validation of the event type.', error);
            res.status(500).json('Internal server error during validation of the event type.');
        }
    }

};

