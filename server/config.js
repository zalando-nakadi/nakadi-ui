const fs = require('fs');

/**
 * @module
 * @type Function
 * createConfiguration
 * @param {object} env - plain key/value object
 * @returns
 */
exports = module.exports = function createConfiguration(env) {
    const config = {
        productionMode: required('NODE_ENV', env) === 'production',
        port: env.HTTP_PORT || 3000,
        baseUrl: required('BASE_URL', env),
        nakadiApiUrl: required('NAKADI_API_URL', env),
        nakadiApiSqlUrl: optional('NAKADI_SQL_API_URL', env, ''),
        serverOptions: envToBool(env.HTTPS_ENABLE) ? {
            key: fs.readFileSync(required('HTTPS_PRIVATE_KEY_FILE', env), 'utf8'),
            cert: fs.readFileSync(required('HTTPS_PUBLIC_KEY_FILE', env), 'utf8')
        } : {},


        auth: {
            strategy: required('AUTH_STRATEGY', env),
            options: readOptions('AUTH_OPTIONS_', env)
        },

        settings: {
            appsInfoUrl: optional('APPS_INFO_URL', env, ''),
            usersInfoUrl: optional('USERS_INFO_URL', env, ''),
            nakadiApiUrl: required('NAKADI_API_URL', env),
            monitoringUrl: optional('MONITORING_URL', env, ''),
            sloMonitoringUrl: optional('SLO_MONITORING_URL', env, ''),
            eventTypeMonitoringUrl: optional('EVENT_TYPE_MONITORING_URL', env, ''),
            subscriptionMonitoringUrl: optional('SUBSCRIPTION_MONITORING_URL', env, ''),
            docsUrl: optional('DOCS_URL', env, ''),
            supportUrl: optional('SUPPORT_URL', env, ''),
            allowDeleteEvenType: envToBool(env.ALLOW_DELETE_EVENT_TYPE),
            deleteSubscriptionWarning: optional('DELETE_SUBSCRIPTION_WARN', env,
                'Notify all consumers; the following subscriptions will be deleted!'),
            forbidDeleteUrl: optional('FORBID_DELETE_URL', env, ''),
            showNakadiSql: envToBool(env.SHOW_NAKADI_SQL),
            queryMonitoringUrl: optional('QUERY_MONITORING_URL', env, ''),
            retentionTimeDaysDefault: optional('RETENTION_TIME_DAYS_DEFAULT', env, '3'),
            retentionTimeDaysValues: optional('RETENTION_TIME_DAYS_VALUES', env, '1 2 3 4 5 6 7'),
        },

        authorize: {
            strategy: env.AUTHORIZE_STRATEGY || '',
            options: readOptions('AUTHORIZE_OPTIONS_', env)
        },

        analytics: {
            strategy: env.ANALYTICS_STRATEGY || '',
            options: readOptions('ANALYTICS_OPTIONS_', env)
        },

        logsApi: {
            scalyrUrl: required('SCALYR_URL', env),
            scalyrKey: required('SCALYR_KEY', env),
            scalyrBaseFilter: optional('SCALYR_BASE_FILTER', env, '($serverHost=="nakadi") and ($logfile=="/var/log/application.log") and ')
        },
        cookie: {
            cookieName: 'session', // cookie name dictates the key name added to the request object
            secret: required('COOKIE_SECRET', env), // should be a large unguessable string
            duration: 24 * 60 * 60 * 1000, // how long the session will stay valid in ms
            activeDuration: 1000 * 60 * 5, // if expiresIn < activeDuration, the session will be extended by activeDuration milliseconds
            cookie: {
                path: '/', // cookie will only be sent to requests under '/api'
                //maxAge: 60000, // duration of the cookie in milliseconds, defaults to duration above (cannot be used if 'ephemeral: true')
                ephemeral: true, // when true, cookie expires when the browser closes (cannot be used with 'maxAge')
                httpOnly: true, // when true, cookie is not accessible from javascript
                secure: false // when true, cookie will only be sent over SSL. use key 'secureProxy' instead if you handle SSL not in your node process
            }
        },

        credentialsDir: required('CREDENTIALS_DIR', env)
    };
    return config;
};

/**
 * Throws error if key is not found
 *
 * @param {string} name
 * @param {object} env
 * @returns {*}
 */
function required(name, env) {
    if (!env[name])
        throw new Error(`Required configuration environment variable ${name} is empty`);
    return env[name];
}

/**
 * Set optional if value not found
 *
 * @param {string} name
 * @param {object} env
 * @param {object} defaultValue
 *
 * @returns {*}
 */
function optional(name, env, defaultValue) {
    if (env[name] === undefined)
        return defaultValue;
    return env[name];
}

/**
 * Return object with all the keys/values from the `options` param
 * where key starts with prefix
 * @example
 *  readOptions('AUTH_OPTIONS_', {
 *      AUTH_OPTIONS_someParam: 123,
 *      AUTH_OPTIONS_someParam2: 456,
 *      someOther: 987
 *  })
 *   will return
 *  {
 *      someParam: 123,
 *      someParam2: 456
 *  }
 *
 * @param {string} prefix
 * @param {object} options
 * @returns object
 */
function readOptions(prefix, options) {

    return Object.keys(options).filter(
        (key) =>
            !key.lastIndexOf(prefix, 0)
    ).reduce(
        (result, key) => {
            const newKey = key.replace(prefix, '');
            result[newKey] = options[key];
            return result;
        }, {})
}

/**
 * Convert string to Boolean.
 * True if "true", "True", "TRUE", "1", "yes","Yes", "YES"
 * False everything else.
 * @param {string} val
 */
function envToBool(val) {
    if (!val) {
        return false
    }

    const value = val.toString().toLowerCase();
    return value === "true" || value === "yes" || value === "1"
}
