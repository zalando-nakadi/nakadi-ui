describe('Event Type validation', function() {
    const App = require('../../server/App');
    const nakadiMock = require('../mocks/testNakadi');
    const request = require('supertest');
    const conf = require('../mocks/data/appConf.json');

    const app = App(conf);
    const agent = request.agent(app);


    // for self-signed certificates
    process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

    it('should reject unauthorised users', function(done) {

        agent
        .post('/api/validation')
        .set('Accept', 'application/json')
        .expect(401, (err) =>
            (err) ? done.fail(err) : done()
        );

    });

    it('should reject malformed event type', function(done) {
        agent
        .get('/auth/callback?code=111').end(loginEnd);


        function loginEnd(err, res) {
            if (err) return err;

            agent
            .post('/api/validation')
            .set('Accept', 'application/json')
            .send({})
            .expect(400, function(err, res) {
                nakadiMock.close();
                if (err) done.fail(err);
                done()
            });
        }
    });

    it('should return correct response', function(done) {

        const et = {
            "name": "WRONG-example-company.example-team.example-event_type.v5",
            "owning_application": "search-log-enricher",
            "category": "undefined",
            "enrichment_strategies": [],
            "partition_strategy": "random",
            "partition_key_fields": [],
            "schema": {
                "type": "json_schema",
                "schema": "{ \"additionalProperties\": true }",
                "version": "1.0.0",
                "created_at": "2017-02-02T11:12:33.230Z"
            },
            "default_statistic": {
                "messages_per_minute": 5000,
                "message_size": 20000,
                "read_parallelism": 8,
                "write_parallelism": 8
            },
            "options": {"retention_time": 345600000},
            "authorization": null,
            "compatibility_mode": "forward",
            "updated_at": "2017-02-02T11:12:33.230Z",
            "created_at": "2017-02-02T11:12:33.230Z"
        };

        const expectContent = {
                name: 'WRONG-example-company.example-team.example-event_type.v5',
                issues:
                    [{
                        id: 100,
                        title: 'No authorization configured',
                        message: 'This event type is not secured with authorization. Everyone with a valid access token can modify your event type configuration and access your data. Please update your event type configuration and configure proper access rights.',
                        link: 'https://nakadi.io/manual.html#using_authorization',
                        group: 'security',
                        severity: 100
                    },
                        {
                            id: 200,
                            title: 'No schema or empty schema configured',
                            message: 'Please create a proper schema with a list of properties.',
                            link: 'http://zalando.github.io/restful-api-guidelines/#210',
                            group: 'schema',
                            severity: 100
                        },
                        {
                            id: 300,
                            title: 'Ensure Events conform to a well-known Event Category',
                            message: 'The "undefined" category should not be used in production,it can be used only for development or in some rare exceptional use-cases. Please recreate the event type and use "business" or "data" category.',
                            link: 'http://zalando.github.io/restful-api-guidelines/#198',
                            group: 'misc',
                            severity: 20
                        },
                        {
                            id: 302,
                            title: ' Use compatible for compatibility_mode',
                            message: 'Changes to events must be based around making additive and backward compatible changes. Please update the event type and change compatibility_mode to "compatible".',
                            link: 'http://zalando.github.io/restful-api-guidelines/#209',
                            group: 'misc',
                            severity: 10
                        },
                        {
                            id: 303,
                            title: 'Event type name contains uppercase symbols',
                            message: 'Event type names should be lowercase words and numbers, using hyphens, underscores or periods as separators. Please re-create or clone the event type with the better name.',
                            link: 'http://zalando.github.io/restful-api-guidelines/#213',
                            group: 'misc',
                            severity: 10
                        },
                        {
                            id: 304,
                            title: 'Avoid Versioning',
                            message: 'When changing your event schema, do so in a compatible way and avoid generating additional event types. Please re-create or clone the event type with a compliant name and use the schema evolution.',
                            link: 'http://zalando.github.io/restful-api-guidelines/#113',
                            group: 'misc',
                            severity: 10
                        }]
            }
        ;

        agent
        .get('/auth/callback?code=111').end(loginEnd);


        function loginEnd(err, res) {
            if (err) return err;

            agent
            .post('/api/validation')
            .set('Accept', 'application/json')
            .send(et)
            .expect(200, expectContent, function(err, res) {
                nakadiMock.close();
                if (err) done.fail(err);
                done();
            });
        }
    });
});
