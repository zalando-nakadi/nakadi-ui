# Install

## Prerequisites
To run this web server, you need to have [Node.js](https://nodejs.org/) version 6.4 or newer
installed.
Also it is better to have [Elm](http://elm-lang.org/) v0.18 installed globally for an easy use later.

```bash
npm install elm@0.18 -g
```

## Get the source code

Download source code using [Git](https://git-scm.com/)

```bash
git clone git@github.bus.zalan.do:zalando-nakadi/nakadi-ui.git
```

or as [zip archive](https://github.com/zalando-nakadi/nakadi-ui/archive/master.zip)


## Build

Go to this project root and install all dependencies.

```bash
cd nakadi-ui
npm install
```

Install one of the [Passport.js](http://passportjs.org/) auth strategies you plan to use
(see AUTH_STRATEGY configuration variable).
For example [Google OAuth 2.0 API](https://github.com/jaredhanson/passport-google-oauth2).

```bash
npm install passport-google-oauth20
```

To build production ready app you need to run.

```bash
npm run build
```

After the build, the resulting client files will be stored in `dist` folder.


## Configuration
All the configuration parameters are in the environment variables.
To make it simpler, you can put them in the `.env` file in the project root folder.
The real environment variable if set will override values from this file.

You can copy the example configuration and edit it.

```bash
cp .env.example .env
editor .env
```

Follow the comments in `.env.example`

*WARNING*: You MUST change `COOKIE_SECRET`! Use this command to generate new secret: `openssl rand -base64 100`

```bash
# Bind and listen this TCP port.
# Required
HTTP_PORT="3000"

# Base URL of the app visible to the end user.
# Required
BASE_URL="https://localhost:3000"

# Nakadi API URL.
# Required
NAKADI_API_URL="https://nakadi-staging.exmaple.com"

# Base link to apps info register. ie https://yourturn.stups.example.com/application/detail/{some_app_name}
# Optional
APPS_INFO_URL="https://yourturn.stups.example.com/application/detail/"

# Base link to user info register. e.g  https://people.example.com/details/{uid}
# Optional
USERS_INFO_URL="https://people.example.com/details/"

# Link to company internal documentation related to Nakadi service
# Optional
DOCS_URL=https://nakadi-faq.docs.example.com/

# Link to company internal Nakadi support (chat room, support request form etc.)
# Optional
SUPPORT_URL=https://hipchat.example.com/chat/room/12345

# URL of Scalyr API. Used to extract list of producers and consumers from the access logs
# Required
SCALYR_URL="https://www.scalyr.com/api/"
SCALYR_KEY="YOUR-SCALYR-API-KEY-3c9f8h3e8b3d07e-"
SCALYR_BASE_FILTER=($serverHost=="nakadi") and ($logfile=="/var/log/application.log") and

# Feature flags.
# Optional, default "No"
ALLOW_DELETE_EVENT_TYPE=yes

# Link to the description of why the event type deletion is disabled
# Only needed if ALLOW_DELETE_EVENT_TYPE is false
# Optional
FORBID_DELETE_URL=https://nakadi-faq.docs.example.com/#how-to-delete-et

# Module name and configuration of Passport.js auth plugin (see /server/auth.js).
# Required
AUTH_STRATEGY="passport-google-oauth20"
AUTH_OPTIONS_clientID="YOUR client id.apps.googleusercontent.com"
AUTH_OPTIONS_clientSecret="YOUR client secret"
AUTH_OPTIONS_scope="profile email"
AUTH_OPTIONS_callbackURL="https://localhost:3000/auth/callback"

# Module name and configuration of custom authorization plugin (see /server/nakadiApi.js).
# Optional
AUTHORIZE_STRATEGY="myGoogleAdapter"
AUTHORIZE_OPTIONS=myscope

# Module name and configuration of custom analytics plugin (see /server/App.js#analytics)
# Can be used for collecting user statistic (KPI, AUDIT etc)
# Optional
#ANALYTICS_STRATEGY="./nakadi-ui-analytics-plugin"
#ANALYTICS_OPTIONS_url="https://nakadi-staging.example.com"
#ANALYTICS_OPTIONS_name="example-team.nakadi-ui.access-log"

# Nakadi SQL Support
# If "yes" shows create SQL Query menu item and the SQL Query tab
# for query output event types
SHOW_NAKADI_SQL=no
NAKADI_SQL_API_URL="http://nakadi-sql.example.com"
QUERY_MONITORING_URL="https://zmon.example.com/grafana/dashboard/db/nakadi-et/?var-stack=live&var-$queryId={query}"

# The key used to encode/decode user session.
# Required
COOKIE_SECRET="!!! CHANGE THIS!!! ksdgi98NNliuHHy^fdjy6b!khl_ig6%^#vGdsljhgl Bfdes&8yh3e"

# Run as HTTPS server. If disabled then run as HTTP server.
# Optional, default "No"
HTTPS_ENABLE=1
HTTPS_PRIVATE_KEY_FILE="deploy/certs/privkey.pem"
HTTPS_PUBLIC_KEY_FILE="deploy/certs/cert.pem"
```

*HINT*: [Create self-signed SSL certificates](http://www.akadia.com/services/ssh_test_certificate.html)
Copy SSL keys `privkey.pem` and `cert.pem` to `deploy/certs` folder.

## Run
You can now run server in the production mode.

```bash
npm run start:prod
```

or in development mode with watch and Hot Module Replacement.

```bash
npm run start
```

Now you can go to `https://localhost:3000` and look at the Nakadi UI interface.
