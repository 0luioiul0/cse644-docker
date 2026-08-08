#!/usr/bin/env bash
# Requirement 5: build a customized Nginx image that serves our own web page.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
start_log "03-custom-nginx"

CT="${PREFIX}-custom-nginx"
IMG="${PREFIX}-custom-nginx:1.0"
PORT=8081

docker rm -f "$CT" >/dev/null 2>&1

step "The Dockerfile and the custom page that go into the image"
run "cat $ROOT/01-custom-nginx/Dockerfile"
run "ls -R $ROOT/01-custom-nginx"

step "Build the customized image"
run "docker build -t $IMG $ROOT/01-custom-nginx"
run "docker images $IMG"
run "docker history $IMG --format 'table {{.CreatedBy}}\t{{.Size}}' | head -8"

step "Run the customized image as a container"
run "docker run -d --name $CT -p ${PORT}:80 $IMG"
wait_http "http://localhost:${PORT}/health"
run "docker ps --filter name=$CT --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'"

step "The custom page is being served (not the stock nginx welcome page)"
run "curl -sI http://localhost:${PORT}/"
run "curl -s http://localhost:${PORT}/ | head -20"
run "curl -s http://localhost:${PORT}/whoami"
run "curl -s http://localhost:${PORT}/health"

step "Proof the stock page is gone: the base image would return 'Welcome to nginx!'"
run "echo \"occurrences of the stock 'Welcome to nginx' text in the response: \$(curl -s http://localhost:${PORT}/ | grep -c 'Welcome to nginx')\""
run "docker run --rm -d --name ${PREFIX}-stock-nginx -p 8091:80 nginx:1.27-alpine >/dev/null && sleep 2 && echo 'base image says:' && curl -s http://localhost:8091/ | grep -o 'Welcome to nginx!' && docker rm -f ${PREFIX}-stock-nginx >/dev/null"
run "curl -s http://localhost:${PORT}/ | grep -o 'customized Nginx image' | head -1"

step "Nginx access log from inside the container"
run "docker logs $CT 2>&1 | tail -5"

echo
echo "Container left running on http://localhost:${PORT}/ for the browser screenshot."
finish
