FROM node:latest as builder
WORKDIR /src

COPY . .
RUN npm install
RUN npm run build


FROM node:latest
MAINTAINER Sergii Kamenskyi <sergukam@sergukam.com>
LABEL Description="This Nakadi UI do not check auth by default. Please use Auth plugins for use in production."

WORKDIR /app
COPY --from=builder /src/dist dist
COPY --from=builder /src/server server
COPY --from=builder /src/package.json .
RUN npm install --only=production

EXPOSE 3000/tcp

ENV HTTP_PORT="3000"
ENV NODE_ENV="prod"
ENV BASE_URL="http://localhost:3000"
ENV NAKADI_API_URL="http://localhost:8080"
ENV APPS_INFO_URL="https://yourturn.example.com/application/detail/"
ENV USERS_INFO_URL="https://people.example.com/details/"
ENV SCALYR_URL="https://eu.scalyr.com/api/"
ENV SCALYR_KEY="022222200000000000000-"
ENV EVENT_TYPE_MONITORING_URL="https://zmon.example.com/grafana/dashboard/db/nakadi-et/?var-stack=nakadi-staging&var-et={et}"
ENV SUBSCRIPTION_MONITORING_URL="https://zmon.example.com/grafana/dashboard/db/nakadi-subscription/?var-stack=nakadi-staging&var-id={id}"
ENV MONITORING_URL="https://zmon.example.com/grafana/dashboard/db/nakadi-live"
ENV SLO_MONITORING_URL="https://zmon.example.com/grafana/dashboard/db/nakadi-slos"
ENV DOCS_URL=https://nakadi-faq.docs.example.com/
ENV SUPPORT_URL=https://hipchat.example.com/chat/room/12345
ENV ALLOW_DELETE_EVENT_TYPE=yes
ENV DISALLOW_DELETE_URL=https://nakadi-faq.docs.example.com/#how-to-delete-et
ENV AUTH_STRATEGY="./nullPassportStrategy.js"
ENV COOKIE_SECRET="1lzz-jskjdfsd78bnc*&0$765"
ENV CREDENTIALS_DIR="deploy/OAUTH"
ENV HTTPS_ENABLE=0
ENV NODE_TLS_REJECT_UNAUTHORIZED=0

ENTRYPOINT npm run start:prod
