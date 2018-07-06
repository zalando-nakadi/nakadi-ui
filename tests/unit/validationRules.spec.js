describe('validation module', function() {
    const validation = require('../../server/validation');

    it('should check auth and schema in ET', function() {
        const et = {
            "name": "WRONG-example-company.example-team.example-event_type_v5",
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
            "options": {"retention_time": 345600000},
            "authorization": null,
            "compatibility_mode": "forward"
        };

        const result = validation.validateEventType(et);
        expect(result).toBeAny(Object, 'It should be object');
        expect(result.name).toBe('WRONG-example-company.example-team.example-event_type_v5', 'Should return ET name');
        expect(result.issues).toBeAny(Array, 'Should return Array of issues');
        expect(result.issues.length).toBe(6, 'Should return 6 issues');
        expect(result.issues[0].id).toBe(validation.issueType.SECURITY_NOT_SET, 'Should return error code');
        expect(result.issues[1].id).toBe(validation.issueType.SCHEMA_IS_EMPTY, 'Should return error code');
    });

    it('should check schema JSON formatting ', function() {
        const et = {
            "name": "example-company.example-team.example-event_type",
            "owning_application": "search-log-enricher",
            "category": "undefined",
            "enrichment_strategies": [],
            "partition_strategy": "random",
            "partition_key_fields": [],
            "schema": {
                "type": "json_schema",
                "schema": "{ \"additionalProperties\": true }}",
                "version": "1.0.0",
                "created_at": "2017-02-02T11:12:33.230Z"
            },
            "options": {"retention_time": 345600000},
            "authorization": null,
            "compatibility_mode": "forward"
        };

        const result = validation.validateEventType(et);
        const issue = result.issues.find((issue) => issue.id === validation.issueType.SCHEMA_NOT_A_JSON);
        expect(issue).toBeTruthy('Should return issue #' + validation.issueType.SCHEMA_NOT_A_JSON);
    });

    it('should check schema properties', function() {
        const et = {
            "name": "example-company.example-team.example-event_type",
            "owning_application": "search-log-enricher",
            "category": "undefined",
            "enrichment_strategies": [],
            "partition_strategy": "random",
            "partition_key_fields": [],
            "schema": {
                "type": "json_schema",
                "schema": "{ \"crazy_field\": true }",
                "version": "1.0.0",
                "created_at": "2017-02-02T11:12:33.230Z"
            },
            "options": {"retention_time": 345600000},
            "authorization": null,
            "compatibility_mode": "forward"
        };

        const result = validation.validateEventType(et);
        const issue = result.issues.find((issue) => issue.id === validation.issueType.SCHEMA_HAS_NO_PROPERTIES);
        expect(issue).toBeTruthy('Should return issue #' + validation.issueType.SCHEMA_HAS_NO_PROPERTIES);
    });

    it('should check schema has complex properties', function() {
        const et = {
            "name": "example-company.example-team.example-event_type",
            "owning_application": "search-log-enricher",
            "category": "undefined",
            "enrichment_strategies": [],
            "partition_strategy": "random",
            "partition_key_fields": [],
            "schema": {
                "type": "json_schema",
                "schema": "{ \"anyOf\": [] }",
                "version": "1.0.0",
                "created_at": "2017-02-02T11:12:33.230Z"
            },
            "authorization": null,
            "compatibility_mode": "forward"
        };

        const result = validation.validateEventType(et);
        const issue = result.issues.find((issue) => issue.id === validation.issueType.SCHEMA_COMBINED);
        expect(issue).toBeTruthy('Should return issue #' + validation.issueType.SCHEMA_COMBINED);
    });
});


