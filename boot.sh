#!/bin/bash
# this script is used to boot a Docker container
# If RUN_MIGRATIONS is set to "true" the container will run DB migrations
# then it will exec the command passed by the Dockerfile / docker-compose.

set -e

if [ "${RUN_MIGRATIONS:-false}" = "true" ]; then
    while true; do
        flask db upgrade && break
        echo "Deploy command failed, retrying in 5 secs..."
        sleep 5
    done
fi

# Execute the container command (from docker-compose `command:`)
exec "$@"
