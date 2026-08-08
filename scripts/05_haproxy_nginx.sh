#!/usr/bin/env bash
# Requirement 7: HAProxy acting as a proxy in front of Nginx.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
start_log "05-haproxy-nginx"

PROJ="$ROOT/03-haproxy-nginx"
PORT=8082
STATS=8404

step "Project files: HAProxy configuration, Nginx configuration, compose file"
run "cat $PROJ/haproxy/haproxy.cfg"
run "cat $PROJ/nginx/default.conf"
run "cat $PROJ/docker-compose.yml"

step "Build and start the project"
run "docker compose -f $PROJ/docker-compose.yml up -d --build"
run "docker compose -f $PROJ/docker-compose.yml ps"

wait_http "http://localhost:${PORT}/health"

step "Both services are running"
run "docker ps --filter name=${PREFIX}- --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'"

step "Only HAProxy publishes host ports — the Nginx backends publish none"
run "docker port ${PREFIX}-haproxy"
run "docker port ${PREFIX}-web1 || echo '(no published ports — reachable only through the proxy from outside this host)'"
run "docker port ${PREFIX}-web2 || echo '(no published ports — reachable only through the proxy from outside this host)'"

step "A request to HAProxy is forwarded to Nginx"
run "curl -sI http://localhost:${PORT}/"
echo
echo "X-Proxied-By is added by HAProxy, X-Served-By is added by Nginx."
echo "Both headers present in one response = the request passed through both."

step "Round-robin proof: ten requests alternate between the two Nginx backends"
run "for i in \$(seq 10); do printf '  request %2d -> ' \$i; curl -s http://localhost:${PORT}/whoami; done"

step "Backend distribution counted"
run "for i in \$(seq 20); do curl -s http://localhost:${PORT}/whoami; done | sort | uniq -c"

step "The proxied page itself names the backend that served it"
run "curl -s http://localhost:${PORT}/ | grep -A1 'class=\"backend\"'"

step "HAProxy health checks see both Nginx servers as UP"
run "curl -s 'http://localhost:${STATS}/;csv' | awk -F, 'NR==1||\$1==\"nginx_pool\" {print \$1\",\"\$2\",\"\$18\",\"\$5}' | column -s, -t"

step "Nginx access log shows the forwarded client address (X-Forwarded-For)"
run "docker logs ${PREFIX}-web1 2>&1 | tail -4"
run "docker logs ${PREFIX}-web2 2>&1 | tail -4"

step "Failover: stop web1 and confirm HAProxy keeps serving from web2"
run "docker stop ${PREFIX}-web1"
run "sleep 12"
run "for i in \$(seq 6); do printf '  request %d -> ' \$i; curl -s http://localhost:${PORT}/whoami; done"
run "curl -s 'http://localhost:${STATS}/;csv' | awk -F, '\$1==\"nginx_pool\" {print \$2\" = \"\$18}'"
run "docker start ${PREFIX}-web1"
run "sleep 12"
run "for i in \$(seq 6); do printf '  request %d -> ' \$i; curl -s http://localhost:${PORT}/whoami; done"

echo
echo "Project left running: http://localhost:${PORT}/ (site) and http://localhost:${STATS}/ (stats)."
finish
