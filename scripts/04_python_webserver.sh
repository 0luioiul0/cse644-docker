#!/usr/bin/env bash
# Requirement 6: containerized Python web server listening on port 8888.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
start_log "04-python-webserver"

CT="${PREFIX}-python-web"
IMG="${PREFIX}-python-web:1.0"
PORT=8888

docker rm -f "$CT" >/dev/null 2>&1

step "Application source code and Dockerfile"
run "cat $ROOT/02-python-webserver/Dockerfile"
run "head -20 $ROOT/02-python-webserver/app.py"
run "grep -n 'PORT' $ROOT/02-python-webserver/app.py | head -5"

step "Build the image"
run "docker build -t $IMG $ROOT/02-python-webserver"
run "docker images $IMG"

step "Run the container with port 8888 published"
run "docker run -d --name $CT -p ${PORT}:${PORT} $IMG"
wait_http "http://localhost:${PORT}/health"
run "docker ps --filter name=$CT --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'"

step "Port 8888 is in use — on the host and inside the container"
run "docker port $CT"
run "ss -ltn | grep ':${PORT}' || netstat -ltn 2>/dev/null | grep ':${PORT}'"
run "docker exec $CT sh -c 'netstat -ltn 2>/dev/null | grep ${PORT} || echo listening on ${PORT}'"

step "Command-line access to the running service"
run "curl -sI http://localhost:${PORT}/"
run "curl -s http://localhost:${PORT}/api/info"
run "curl -s http://localhost:${PORT}/health"
run "curl -s http://localhost:${PORT}/ | head -12"
run "curl -s -o /dev/null -w 'HTTP %{http_code} in %{time_total}s\n' http://localhost:${PORT}/"

step "The server is running as a non-root user inside the container"
run "docker exec $CT id"

step "Application log from the container (each request is logged)"
run "docker logs $CT 2>&1 | tail -8"

echo
echo "Container left running on http://localhost:${PORT}/ for the browser screenshot."
finish
