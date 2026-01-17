#!/bin/sh

if [ -z "$SERVICE_URL" ]; then
    exit 1
fi

wget -qO service.sh "$SERVICE_URL"

if [ $? -ne 0 ]; then
    exit 1
fi

chmod +x service.sh

exec /app/service.sh
