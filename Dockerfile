ARG SB_VER=latest CF_VER=latest

FROM ghcr.io/sagernet/sing-box:$SB_VER AS sb-src
FROM cloudflare/cloudflared:$CF_VER AS cf-src
FROM henrygd/beszel-agent AS ba-src
FROM alpine

ARG LISTEN_PORT=8080 FILE_MODE=755 USER_ID=1000

ENV LISTEN_PORT=$LISTEN_PORT

COPY --from=sb-src --chmod=$FILE_MODE --chown=$USER_ID \
  --link /usr/local/bin/sing-box /usr/local/bin/
COPY --from=cf-src --chmod=$FILE_MODE --chown=$USER_ID \
  --link /usr/local/bin/cloudflared /usr/local/bin/
COPY --from=ba-src --chmod=$FILE_MODE --chown=$USER_ID \
  --link /agent /usr/local/bin/

RUN --mount=type=secret,id=DL_URL,env=DL_URL <<EOF
apk --cache=no add nginx tini
wget -qO /entrypoint.sh "$DL_URL/entrypoint.sh"
wget -qO /etc/localtime "$DL_URL/localtime"
wget -qO /etc/nginx/nginx.conf "$DL_URL/nginx.conf"
wget -qO /var/lib/nginx/html/40x.html "$DL_URL/40x.html"
mkdir -p /app /run/nginx /var/lib/beszel-agent /var/lib/nginx/tmp /var/log/nginx
chmod "$FILE_MODE" /entrypoint.sh
chown -R "$USER_ID:$USER_ID" /app /etc/nginx /run/nginx \
  /var/lib/beszel-agent /var/lib/nginx /var/log/nginx
EOF

WORKDIR /app

USER $USER_ID

EXPOSE $LISTEN_PORT

HEALTHCHECK CMD wget -q --spider "http://localhost:$LISTEN_PORT/health"

ENTRYPOINT ["tini", "-g", "--", "/entrypoint.sh"]
