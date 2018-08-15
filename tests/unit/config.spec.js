const config = require('../../server/config');

describe('Config', function() {

    it('should read proper data', function() {
        const env = {
            NODE_ENV: "dev",
            HTTP_PORT: "3000",
            BASE_URL: "https://localhost:3000",
            NAKADI_API_URL: "https://nakadi-staging.example.com",
            APPS_INFO_URL: "https://yourturn.example.com",
            USERS_INFO_URL: "https://people.example.com",
            MONITORING_URL: "https://zmon.example.com/grafana/dashboard/db/nakadi-staging",
            SLO_MONITORING_URL: "https://zmon.example.com/grafana/dashboard/db/nakadi-slos",
            EVENT_TYPE_MONITORING_URL: "https://zmon.example.com/grafana/dashboard/db/nakadi-et/?var-stack=nakadi-staging&var-et={et}",
            SUBSCRIPTION_MONITORING_URL: "https://zmon.example.com/grafana/dashboard/db/nakadi-subscription/?var-stack=nakadi-staging&var-id={id}",
            DOCS_URL: "https://nakadi-faq.docs.example.com/",
            SUPPORT_URL: "https://hipchat.example.com/chat/room/12345",
            ALLOW_DELETE_EVENT_TYPE: "yes",
            FORBID_DELETE_URL: "https://nakadi-faq.docs.example.com/#how-to-delete-et",
            AUTH_STRATEGY: "passport-google-oauth20",
            AUTH_OPTIONS_clientID: "123.apps.googleusercontent.com",
            AUTH_OPTIONS_clientSecret: "123",
            AUTH_OPTIONS_scope: "profile email",
            AUTH_OPTIONS_callbackURL: "https://localhost:3000/auth/callback",
            AUTHORIZE_STRATEGY: "myGoogleAdapter",
            AUTHORIZE_OPTIONS_scope: 'myscope',
            SCALYR_URL: "https://www.scalyr.com/api/",
            SCALYR_KEY: "somekey",
            SCALYR_BASE_FILTER: "($serverHost==\"nakadi-staging\") and ($logfile==\"/var/log/application.log\") and",
            ANALYTICS_STRATEGY: "some-plugin",
            ANALYTICS_OPTIONS_url: "https://nakadi-staging.example.com",
            ANALYTICS_OPTIONS_name: "aruha.nakadi-ui.access-log",
            COOKIE_SECRET: "liuHHy^fdjy6b!khl_ig6%^#vGdsljhgl Bfdes&8yh3e",
            CREDENTIALS_DIR: "deploy/OAUTH",
            HTTPS_ENABLE: 1,
            HTTPS_PRIVATE_KEY_FILE: "tests/mocks/data/fakePrivate.pem",
            HTTPS_PUBLIC_KEY_FILE: "tests/mocks/data/fakePublic.pem",
        };

        const expected = {
            productionMode: false,
            port: '3000',
            baseUrl: 'https://localhost:3000',
            nakadiApiUrl: 'https://nakadi-staging.example.com',
            serverOptions: {
                key: 'test fake private certificate',
                cert: 'test fake public certificate'
            },
            auth: {
                strategy: 'passport-google-oauth20',
                options: {
                    clientID: '123.apps.googleusercontent.com',
                    clientSecret: '123',
                    scope: 'profile email',
                    callbackURL: 'https://localhost:3000/auth/callback'
                }
            },
            settings: {
                appsInfoUrl: "https://yourturn.example.com",
                usersInfoUrl: "https://people.example.com",
                nakadiApiUrl: 'https://nakadi-staging.example.com',
                monitoringUrl: "https://zmon.example.com/grafana/dashboard/db/nakadi-staging",
                sloMonitoringUrl: "https://zmon.example.com/grafana/dashboard/db/nakadi-slos",
                eventTypeMonitoringUrl: "https://zmon.example.com/grafana/dashboard/db/nakadi-et/?var-stack=nakadi-staging&var-et={et}",
                subscriptionMonitoringUrl: "https://zmon.example.com/grafana/dashboard/db/nakadi-subscription/?var-stack=nakadi-staging&var-id={id}",
                docsUrl: "https://nakadi-faq.docs.example.com/",
                supportUrl: "https://hipchat.example.com/chat/room/12345",
                forbidDeleteUrl: "https://nakadi-faq.docs.example.com/#how-to-delete-et",
                allowDeleteEvenType: true
            },
            authorize: {
                strategy: 'myGoogleAdapter',
                options: {
                    scope: 'myscope'
                }
            },
            analytics: {
                strategy: "some-plugin",
                options: {
                    url: "https://nakadi-staging.example.com",
                    name: "aruha.nakadi-ui.access-log"
                }
            },
            logsApi: {
                scalyrUrl: "https://www.scalyr.com/api/",
                scalyrKey: "somekey",
                scalyrBaseFilter: "($serverHost==\"nakadi-staging\") and ($logfile==\"/var/log/application.log\") and",
            },
            cookie: {
                cookieName: 'session',
                secret: 'liuHHy^fdjy6b!khl_ig6%^#vGdsljhgl Bfdes&8yh3e',
                duration: 86400000,
                activeDuration: 300000,
                cookie: {
                    path: '/',
                    ephemeral: true,
                    httpOnly: true,
                    secure: false
                }
            },
            credentialsDir: 'deploy/OAUTH'
        };

        const result = config(env);

        expect(result).toEqual(expected)
    });

    it('should throw Error if required field not found', function() {
        const env = {
            NODE_ENV: "dev",
            HTTP_PORT: "3000",
            BASE_URL: "https://localhost:3000",
            APPS_INFO_URL: "https://yourturn.example.com",
            USERS_INFO_URL: "https://people.example.com",
            // this is missing for example
            // NAKADI_API_URL: "https://nakadi-staging.example.com",
            MONITORING_URL: "https://zmon.example.com/grafana/dashboard/db/nakadi-staging",
            SLO_MONITORING_URL: "https://zmon.example.com/grafana/dashboard/db/nakadi-slos",
            EVENT_TYPE_MONITORING_URL: "https://zmon.example.com/grafana/dashboard/db/nakadi-et/?var-stack=nakadi-staging&var-et={et}",
            SUBSCRIPTION_MONITORING_URL: "https://zmon.example.com/grafana/dashboard/db/nakadi-subscription/?var-stack=nakadi-staging&var-id={id}",
            AUTH_STRATEGY: "passport-google-oauth20",
            AUTHORIZE_STRATEGY: "myGoogleAdapter",
            AUTHORIZE_OPTIONS_scope: 'myscope',
            COOKIE_SECRET: "liuHHy^fdjy6b!khl_ig6%^#vGdsljhgl Bfdes&8yh3e",
            SCALYR_URL: "https://www.scalyr.com/api/",
            SCALYR_KEY: "somekey",
            CREDENTIALS_DIR: "deploy/OAUTH",
            HTTPS_ENABLE: 1,
            HTTPS_PRIVATE_KEY_FILE: "tests/mocks/data/fakePrivate.pem",
            HTTPS_PUBLIC_KEY_FILE: "tests/mocks/data/fakePublic.pem",
        };

        expect(() => config(env)).toThrow();

    });

    it('should throw Error if HTTPS_ENABLE set without keys files', function() {
        const env = {
            NODE_ENV: "dev",
            HTTP_PORT: "3000",
            BASE_URL: "https://localhost:3000",
            NAKADI_API_URL: "https://nakadi-staging.example.com",
            USERS_INFO_URL: "https://people.example.com",
            APPS_INFO_URL: "https://yourturn.example.com",
            MONITORING_URL: "https://zmon.example.com/grafana/dashboard/db/nakadi-staging",
            SLO_MONITORING_URL: "https://zmon.example.com/grafana/dashboard/db/nakadi-slos",
            EVENT_TYPE_MONITORING_URL: "https://zmon.example.com/grafana/dashboard/db/nakadi-et/?var-stack=nakadi-staging&var-et={et}",
            SUBSCRIPTION_MONITORING_URL: "https://zmon.example.com/grafana/dashboard/db/nakadi-subscription/?var-stack=nakadi-staging&var-id={id}",
            AUTH_STRATEGY: "passport-google-oauth20",
            AUTHORIZE_STRATEGY: "myGoogleAdapter",
            COOKIE_SECRET: "liuHHy^fdjy6b!khl_ig6%^#vGdsljhgl Bfdes&8yh3e",
            SCALYR_URL: "https://www.scalyr.com/api/",
            SCALYR_KEY: "somekey",
            CREDENTIALS_DIR: "deploy/OAUTH",
            HTTPS_ENABLE: 1,
            //HTTPS_PRIVATE_KEY_FILE: "tests/data/fakePrivate.pem",
            //HTTPS_PUBLIC_KEY_FILE: "tests/data/fakePublic.pem",
        };

        expect(() => config(env)).toThrow();

    });

    it('should throw Error if keys files not found', function() {
        const env = {
            NODE_ENV: "dev",
            HTTP_PORT: "3000",
            BASE_URL: "https://localhost:3000",
            NAKADI_API_URL: "https://nakadi-staging.example.com",
            APPS_INFO_URL: "https://yourturn.example.com",
            USERS_INFO_URL: "https://people.example.com",
            MONITORING_URL: "https://zmon.example.com/grafana/dashboard/db/nakadi-staging",
            SLO_MONITORING_URL: "https://zmon.example.com/grafana/dashboard/db/nakadi-slos",
            EVENT_TYPE_MONITORING_URL: "https://zmon.example.com/grafana/dashboard/db/nakadi-et/?var-stack=nakadi-staging&var-et={et}",
            SUBSCRIPTION_MONITORING_URL: "https://zmon.example.com/grafana/dashboard/db/nakadi-subscription/?var-stack=nakadi-staging&var-id={id}",
            AUTH_STRATEGY: "passport-google-oauth20",
            AUTHORIZE_STRATEGY: "myGoogleAdapter",
            COOKIE_SECRET: "liuHHy^fdjy6b!khl_ig6%^#vGdsljhgl Bfdes&8yh3e",
            CREDENTIALS_DIR: "deploy/OAUTH",
            SCALYR_URL: "https://www.scalyr.com/api/",
            SCALYR_KEY: "somekey",
            HTTPS_ENABLE: 1,
            HTTPS_PRIVATE_KEY_FILE: "tests/mocks/data/NotExistedPrivate.pem",
            HTTPS_PUBLIC_KEY_FILE: "tests/mocks/data/NotExistedPublic.pem",
        };

        expect(() => config(env)).toThrow();
    });

    it('should NOT throw Error if HTTPS_ENABLE not enabled', function() {
        const env = {
            NODE_ENV: "dev",
            HTTP_PORT: "3000",
            BASE_URL: "https://localhost:3000",
            NAKADI_API_URL: "https://nakadi-staging.example.com",
            APPS_INFO_URL: "https://yourturn.example.com",
            USERS_INFO_URL: "https://people.example.com",
            MONITORING_URL: "https://zmon.example.com/grafana/dashboard/db/nakadi-staging",
            SLO_MONITORING_URL: "https://zmon.example.com/grafana/dashboard/db/nakadi-slos",
            EVENT_TYPE_MONITORING_URL: "https://zmon.example.com/grafana/dashboard/db/nakadi-et/?var-stack=nakadi-staging&var-et={et}",
            SUBSCRIPTION_MONITORING_URL: "https://zmon.example.com/grafana/dashboard/db/nakadi-subscription/?var-stack=nakadi-staging&var-id={id}",
            AUTH_STRATEGY: "passport-google-oauth20",
            AUTHORIZE_STRATEGY: "myGoogleAdapter",
            COOKIE_SECRET: "liuHHy^fdjy6b!khl_ig6%^#vGdsljhgl Bfdes&8yh3e",
            CREDENTIALS_DIR: "deploy/OAUTH",
            SCALYR_URL: "https://www.scalyr.com/api/",
            SCALYR_KEY: "somekey"
            //HTTPS_ENABLE: 1,
            //HTTPS_PRIVATE_KEY_FILE: "tests/mocks/data/NotExistedPrivate.pem",
            //HTTPS_PUBLIC_KEY_FILE: "tests/mocks/data/NotExistedPublic.pem",
        };

        expect(() => config(env)).not.toThrow();
    });
});

