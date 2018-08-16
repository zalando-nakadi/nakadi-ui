const express = require('express');
const bodyParser = require('body-parser');
const http = require('http');
const eventTypesData = require('./data/testEventTypes.json');
const partitions = require('./data/partitions.json');
const events = require('./data/events.json');
const schemas = require('./data/schemas.json');
const subscriptions = require('./data/subscriptions.json');
const stats = require('./data/stats.json');
const cursors = require('./data/cursors.json');
const error404 = require('./data/error404.json');
const error412 = require('./data/error412.json');
const error400 = require('./data/error400.json');
const error207 = require('./data/error207.json');

const app = express();
app.use(bodyParser.json()); // for parsing application/json
app.use(authorize);


app.get('/port', (req, res, done) => res.json({
    host: req.header('host')
}));

app.get('/event-types', (req, res) => {
    res.json(eventTypesData)
});

app.get('/event-types/:name', (req, res) => {
    const et = eventTypesData.find((et) => et.name === req.params.name);
    if (et) {
        return res.json(et);
    }

    return res.status(404)
});

app.post('/event-types', (req, res) => {

    const expected = {
        name: 'test.event-type_name',
        owning_application: 'stups_nakadi-ui-elm',
        category: 'business',
        partition_strategy: 'random',
        partition_key_fields: [],
        ordering_key_fields: [],
        compatibility_mode: 'forward',
        audience: 'component-internal',
        cleanup_policy: 'delete',
        schema: {
            type: 'json_schema',
            schema: '{\n    "description": "Sample event type schema. It accepts any event.",\n    "type": "object",\n    "properties": {\n        "example_item": {\n            "type": "string"\n        },\n        "example_money": {\n            "$ref": "#/definitions/Money"\n        }\n    },\n    "required": [],\n    "definitions": {\n        "Money": {\n            "type": "object",\n            "properties": {\n                "amount": {\n                    "type": "number",\n                    "format": "decimal"\n                },\n                "currency": {\n                    "type": "string",\n                    "format": "iso-4217"\n                }\n            },\n            "required": [\n                "amount",\n                "currency"\n            ]\n        }\n    }\n}'
        },
        default_statistic: {
            messages_per_minute: 100,
            message_size: 100,
            read_parallelism: 1,
            write_parallelism: 1
        },
        options: {retention_time: 345600000},
        authorization: {readers: [], writers: [], admins: []},
        enrichment_strategies: ['metadata_enrichment']
    };

    if (JSON.stringify(req.body) === JSON.stringify(expected)) {
        eventTypesData.push(req.body);
        res.sendStatus(200)
    } else {
        console.log(JSON.stringify(req.body));
        res.status(400).send(JSON.stringify(req.body));
    }

});

app.get('/event-types/:name/partitions', (req, res) => {
    res.json(partitions)
});

app.get('/event-types/:name/events', (req, res) => {

    //error handling testing for server access token
    if (req.params.name === "aruha.test-event-test3.ver_6") {
        res.sendStatus(401);
        return;
    }

    //error handling testing for user access token
    if (req.params.name === "aruha.test-event-test4.ver_6") {
        res.status(400).json(error400);
        return;
    }

    //error handling testing for warnings
    if (req.params.name === "aruha.test-event-test5.ver_6") {
        res.status(412).json(error412);
        return;
    }

    res.json(events)
});

app.post('/event-types/:name/events', (req, res) => {
    res.status(207).json(error207)
});

app.get('/event-types/:name/schemas', (req, res) => {
    res.json(schemas)
});

app.get('/subscriptions', (req, res) => {
    res.json(subscriptions)
});

app.post('/subscriptions', (req, res) => {
    const expected = {
        'consumer_group': 'test-group',
        'owning_application': 'stups_nakadi-ui-elm',
        'read_from': 'end',
        'event_types': ['aruha.test-event.ver_5']
    };

    const response = {
        'owning_application': 'stups_nakadi-ui-elm',
        'event_types': ['aruha.test-event.ver_5'],
        'consumer_group': 'test-group',
        'read_from': 'end',
        'initial_cursors': [],
        'id': '69fba92d-d0ab-422d-a2c4-311a7d937475',
        'created_at': '2017-07-04T11:07:12.958Z'
    };

    const bodyStr = JSON.stringify(req.body);
    const expectedStr = JSON.stringify(expected);
    if (bodyStr === expectedStr) {
        subscriptions.items.push(response);
        res.send(response)
    } else {
        res.status(418).send({
            type: 'https://test-message',
            status: '418',
            title: 'Assertion fail',
            detail: `Got: ${bodyStr} \nexpected: ${expectedStr}`
        })

    }
});


app.get('/subscriptions/:id/stats', (req, res) => {
    res.json(stats)
});

app.get('/subscriptions/:id/cursors', (req, res) => {
    res.json(cursors)
});


app.patch('/subscriptions/:id/cursors', (req, res) => {

    const expected = {
        items: [{
            event_type: "aruha.test-event-test2.ver_6",
            partition: "0",
            offset: "000000000000000001"
        }]
    };

    const bodyStr = JSON.stringify(req.body);
    const expectedStr = JSON.stringify(expected);

    if (bodyStr === expectedStr) {
        cursors.items[0].offset = "000000000000000001";
        res.sendStatus(200);
    } else {
        res.status(418).send({
            type: 'https://test-message',
            status: '418',
            title: 'Assertion fail',
            detail: `Got: ${bodyStr} \nexpected: ${expectedStr}`
        })
    }
});


module.exports = http.createServer(app);

function authorize(req, res, done) {
    if (req.header('Authorization') !== 'Bearer fake-access-token12345') {
        res.sendStatus(403);
        return false;
    }
    done();
}
