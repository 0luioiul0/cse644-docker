#!/usr/bin/env bash
# Remove everything this assignment created — and nothing else.
#
# Deliberately does NOT use `docker system prune`: this Docker host may be
# running unrelated containers. Only objects whose name starts with cse644-
# are touched.
set -uo pipefail
PREFIX="cse644"
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "== containers"
docker ps -a --filter "name=${PREFIX}-" --format '{{.Names}}' | while read -r c; do
    [ -n "$c" ] && docker rm -f "$c"
done

echo "== compose project"
docker compose -f "$HERE/../03-haproxy-nginx/docker-compose.yml" down --remove-orphans 2>/dev/null

echo "== networks"
docker network ls --filter "name=${PREFIX}-" --format '{{.Name}}' | while read -r n; do
    [ -n "$n" ] && docker network rm "$n"
done

echo "== volumes"
docker volume ls --filter "name=${PREFIX}-" --format '{{.Name}}' | while read -r v; do
    [ -n "$v" ] && docker volume rm "$v"
done

echo "== images (built locally by this assignment)"
docker images --format '{{.Repository}}:{{.Tag}}' | grep "^${PREFIX}-" | while read -r i; do
    docker rmi "$i"
done

echo
echo "Remaining cse644 objects (should be none):"
docker ps -a --filter "name=${PREFIX}-" --format '{{.Names}}'
docker network ls --filter "name=${PREFIX}-" --format '{{.Name}}'
docker volume ls --filter "name=${PREFIX}-" --format '{{.Name}}'
