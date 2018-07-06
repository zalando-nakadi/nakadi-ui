const issueType = {
    SECURITY_NOT_SET: 100,
    SECURITY_ADMINS_NOT_SET: 101,
    SECURITY_WRITERS_NOT_SET: 102,
    SECURITY_READERS_NOT_SET: 104,

    SCHEMA_IS_EMPTY: 200,
    SCHEMA_NOT_A_JSON: 201,
    SCHEMA_HAS_NO_PROPERTIES: 202,
    SCHEMA_COMBINED: 203,

    MISC_UNDEFINED_CATEGORY: 300,
    MISC_DATA_NOT_HASH: 301,
    MISC_SCHEMA_NOT_COMPATIBLE: 302,
    MISC_NAME_IS_NOT_LOWERCASE: 303,
    MISC_NAME_CONTAINS_VERSION: 304
};

const MANUAL = "https://nakadi.io/manual.html";

module.exports = {
    validateEventType: validateEventType,
    issueType: issueType
};

function validateEventType(eventType) {
    const name = eventType.name;
    const issues = [];

    securityChecks(eventType, issues);
    schemaChecks(eventType, issues);
    miscChecks(eventType, issues);

    return {
        name: name,
        issues: issues
    };

}


/**
 * Check all security related issues.
 *
 * @param {Object} eventType
 * @param {Array} issues;
 */
function securityChecks(eventType, issues) {

    if (!eventType.authorization) {
        issues.push({
            id: issueType.SECURITY_NOT_SET,
            title: "No authorization configured",
            message: "This event type is not secured with authorization. Everyone with a valid access token" +
            " can modify your event type configuration and access your data." +
            " Please update your event type configuration and configure proper access rights.",
            link: `${MANUAL}#using_authorization`,
            group: "security",
            severity: 100
        });

        /*critical*/
        return issues;
    }

    if (hasWildcard(eventType.authorization.admins)) {
        issues.push({
            id: issueType.SECURITY_ADMINS_NOT_SET,
            title: "Anyone can change or delete this event type configuration",
            message: "There are no entries in the admins list of this event type. Everyone with a valid" +
            " access token can modify your event type configuration and access your data.\n" +
            "Please update your event type configuration and configure proper access rights.",
            link: `${MANUAL}#using_authorization`,
            group: "security",
            severity: 60
        });
    }

    if (hasWildcard(eventType.authorization.writers)) {
        issues.push({
            id: issueType.SECURITY_WRITERS_NOT_SET,
            title: "Anyone can publish events to this event type",
            message: "There are no entries in the list of writers of this event type. Everyone with a valid" +
            " access token can publish events to this event type. This could cause data integrity problems" +
            " for the consumers or malicious data could be injected.\n" +
            "Please update your event type configuration and configure proper access rights.",
            link: `${MANUAL}#using_authorization`,
            group: "security",
            severity: 40
        });
    }

    // The severity temporary (I know :) ) set to 0
    // so we don't punish users for not having readers list
    // before we find a better solution for the Datalake read access.

    if (hasWildcard(eventType.authorization.readers)) {
        issues.push({
            id: issueType.SECURITY_READERS_NOT_SET,
            title: "Anyone can consume events from this event type",
            message: "There are no entries in the list of readers of this event type. Everyone with a valid access" +
            " token can consume events from this event type and can access potentially confidential data.\n" +
            "Please update your event type configuration and configure proper access rights.",
            link: `${MANUAL}#using_authorization`,
            group: "security",
            severity: 0
        });
    }

    return issues;
}


/**
 * Check all schema related issues.
 *
 * @param {Object} eventType
 * @param {Array} issues;
 */
function schemaChecks(eventType, issues) {

    if (isSchemaEmpty(eventType.schema)) {
        issues.push({
            id: issueType.SCHEMA_IS_EMPTY,
            title: "No schema or empty schema configured",
            message: "Please create a proper schema with a list of properties.",
            link: "http://zalando.github.io/restful-api-guidelines/#210",
            group: "schema",
            severity: 100
        });
        /*critical*/
        return issues;
    }

    if (!isSchemaJson(eventType.schema)) {
        issues.push({
            id: issueType.SCHEMA_NOT_A_JSON,
            title: "The schema is not in a valid JSON format",
            message: "Please update the schema with a valid JSON.",
            group: "schema",
            severity: 100
        });
        /*critical*/
        return issues;
    }

    const schema = JSON.parse(eventType.schema.schema);

    if (!isSchemaDescribesProperties(schema)) {
        issues.push({
            id: issueType.SCHEMA_HAS_NO_PROPERTIES,
            title: "The schema does not describe any properties",
            message: "Please update the schema with event property descriptions",
            group: "schema",
            severity: 100
        });
        /*critical*/
        return issues;
    }

    if (isSchemaCombined(schema)) {
        issues.push({
            id: issueType.SCHEMA_COMBINED,
            title: "The schema is too complex",
            message: "Please update the schema without usage of disjunctive formats (anyOf,oneOf,allOf,not)." +
            " It is easier to understand, and helps the services as the data lake to flatten the data of an event.",
            group: "schema",
            severity: 10
        });
    }

    /*
    * TODO: Post-MVP checks
    * - Not following naming conventions for attributes
    * - Wrong choice of data types (e.g."*id" should be string)
    * - Use of untyped arrays
    * - No "required" properties
    * - Partition keys not present in the schema
    * - Only one partition (discarding blue/green consumer deployment)
    *
    **/
}

/**
 * Check all uncategorised issues.
 *
 * @param {Object} eventType
 * @param {Array} issues;
 */
function miscChecks(eventType, issues) {
    if (eventType.category === "undefined") {
        issues.push({
            id: issueType.MISC_UNDEFINED_CATEGORY,
            title: "Ensure Events conform to a well-known Event Category",
            message: "The \"undefined\" category should not be used in production," +
            "it can be used only for development or in some rare exceptional use-cases." +
            " Please recreate the event type and use \"business\" or \"data\" category.",

            link: "http://zalando.github.io/restful-api-guidelines/#198",
            group: "misc",
            severity: 20
        });
    }

    if (eventType.category === "data" && eventType.partition_strategy !== "hash") {
        issues.push({
            id: issueType.MISC_DATA_NOT_HASH,
            title: "Use the hash partition strategy for Data Change Events",
            message: "This ensures data changes arrive at the same partition for a given" +
            " entity and can be consumed effectively by clients." +
            " Please update the event type and set \"hash\" partition strategy.",

            link: "http://zalando.github.io/restful-api-guidelines/#204",
            group: "misc",
            severity: 20
        });
    }

    if (eventType.compatibility_mode !== "compatible") {
        issues.push({
            id: issueType.MISC_SCHEMA_NOT_COMPATIBLE,
            title: " Use compatible for compatibility_mode",
            message:
            "Changes to events must be based around making additive and backward compatible changes." +
            " Please update the event type and change compatibility_mode to \"compatible\".",

            link: "http://zalando.github.io/restful-api-guidelines/#209",
            group: "misc",
            //"forward" is little bit better than "none"
            severity: eventType.compatibility_mode === "forward" ? 10 : 30
        });
    }

    if (eventType.name.toLowerCase() !== eventType.name) {
        issues.push({
            id: issueType.MISC_NAME_IS_NOT_LOWERCASE,
            title: "Event type name contains uppercase symbols",
            message:
            "Event type names should be lowercase words and numbers, using hyphens, underscores or periods as separators." +
            " Please re-create or clone the event type with the better name.",

            link: "http://zalando.github.io/restful-api-guidelines/#213",
            group: "misc",
            severity: 10
        });
    }

    const versionRegex = /([\.|\_|\-])(v|ver|version)([\.|\_|\-])?\d+(.(\d+)?)?$/i;
    if (versionRegex.test(eventType.name)) {

        issues.push({
            id: issueType.MISC_NAME_CONTAINS_VERSION,
            title: "Avoid Versioning",
            message: "When changing your event schema, do so in a compatible way and avoid" +
            " generating additional event types. Please re-create or clone the event type" +
            " with a compliant name and use the schema evolution.",

            link: "http://zalando.github.io/restful-api-guidelines/#113",
            group: "misc",
            severity: 10
        });
    }
}

/********************* Helpers *****************************/

/**
 * Check if the auth list contains the wildcard "*".
 *
 * @param {object[]} list of attributes object {data_type:"user", value:"lmontrieux"}
 * @returns {boolean}
 */
function hasWildcard(list) {
    return !!list.find((attribute) => attribute.value === '*')
}


/**
 * Check if schema is totally empty
 *
 * @param {object} schema
 * @param {string} schema.schema
 * @returns {boolean}
 */
function isSchemaEmpty(schema) {
    const emptySchemas = [
        '{}',
        '{"additionalProperties":true}',
        '{"type":"object"}'
    ];

    return !schema ||
        !schema.schema ||
        typeof schema.schema !== "string" ||
        emptySchemas.includes(removeWhitespaces(schema.schema))
}

/**
 * Check if schema JSON can be parsed correctly.
 *
 * @param {object} schema
 * @param {string} schema.schema
 * @returns {boolean}
 */
function isSchemaJson(schema) {
    try {
        JSON.parse(schema.schema);
        return true
    } catch (e) {
        return false
    }
}

/**
 * Check if properties are defined in any way.
 *
 * @param {object} schema - parsed JSON schema
 * @returns {boolean}
 */
function isSchemaDescribesProperties(schema) {
    //if properties exists, and it is not empty object
    if (schema.properties &&
        typeof schema.properties == "object" &&
        Object.keys(schema.properties).length) {
        return true
    }

    // Complex schema. Maybe it describes properties. Check it later.
    return isSchemaCombined(schema);
}

/**
 * Check if the schema combined from parts.
 *
 * @param {object} schema - parsed JSON schema
 * @returns {boolean}
 */
function isSchemaCombined(schema) {
    return schema.allOf || schema.anyOf || schema.oneOf || schema.not || schema.$ref;
}

/**
 * Remove all spaces, tabs and line brakes from the string.
 *
 * @param {string} str
 * @returns {string}
 */
function removeWhitespaces(str) {
    return str.replace(/\s+/g, '')
}


