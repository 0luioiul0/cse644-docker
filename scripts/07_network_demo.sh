#!/usr/bin/env bash
# Requirement 9: Docker networking — bridge network, host network, isolated network.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
start_log "07-networking"

BR="${PREFIX}-bridge"
INT="${PREFIX}-internal"
IMG="alpine:3.20"

cleanup_net() {
    for c in ${PREFIX}-net-a ${PREFIX}-net-b ${PREFIX}-net-host ${PREFIX}-iso-a ${PREFIX}-iso-b ${PREFIX}-default-a; do
        docker rm -f "$c" >/dev/null 2>&1
    done
    docker network rm "$BR" "$INT" >/dev/null 2>&1
}
cleanup_net

step "Networks that exist before we start"
run "docker network ls"

#=====================================================================
# 1. BRIDGE NETWORK
#=====================================================================
step "1/3 BRIDGE NETWORK — create a user-defined bridge"
run "docker network create --driver bridge --subnet 172.30.0.0/24 $BR"
run "docker network inspect $BR --format 'name={{.Name}} driver={{.Driver}} subnet={{range .IPAM.Config}}{{.Subnet}}{{end}} internal={{.Internal}}'"

step "Attach two containers to the bridge network"
run "docker run -d --name ${PREFIX}-net-a --network $BR $IMG sleep 3600"
run "docker run -d --name ${PREFIX}-net-b --network $BR $IMG sleep 3600"
run "docker network inspect $BR --format '{{range .Containers}}{{.Name}} = {{.IPv4Address}}{{println}}{{end}}'"

step "Each container has an address on the bridge subnet"
run "docker exec ${PREFIX}-net-a ip -4 addr show eth0 | grep inet"
run "docker exec ${PREFIX}-net-b ip -4 addr show eth0 | grep inet"

step "Containers reach each other BY NAME (built-in DNS on user-defined bridges)"
run "docker exec ${PREFIX}-net-a ping -c 3 ${PREFIX}-net-b"
run "docker exec ${PREFIX}-net-b ping -c 3 ${PREFIX}-net-a"
run "docker exec ${PREFIX}-net-a nslookup ${PREFIX}-net-b 2>&1 | tail -4"

step "Containers on the bridge can also reach the outside world (NAT via the host)"
run "docker exec ${PREFIX}-net-a ping -c 2 1.1.1.1"

step "Name resolution does NOT work on the legacy default bridge — the contrast"
run "docker run -d --name ${PREFIX}-default-a $IMG sleep 3600"
run_expect_fail "docker exec ${PREFIX}-default-a ping -c 2 -W 2 ${PREFIX}-net-b"
echo "The default bridge has no embedded DNS server, and the two containers are"
echo "on different networks anyway. That is why user-defined bridges are preferred."
run "docker rm -f ${PREFIX}-default-a"

#=====================================================================
# 2. HOST NETWORK
#=====================================================================
step "2/3 HOST NETWORK — the container shares the host network namespace"
run "ip -4 addr show | grep -E 'inet ' | head -5"
echo "^ addresses on the HOST"
run "docker run --rm --network host $IMG ip -4 addr show | grep -E 'inet ' | head -5"
echo "^ the same addresses seen from INSIDE a --network host container"

step "The host-network container has no separate eth0 and no NAT"
run "docker run --rm --network host $IMG hostname -i"
run "docker run --rm --network host $IMG sh -c 'ip route | head -3'"

step "A server on the host network needs no -p publishing"
run "docker run -d --name ${PREFIX}-net-host --network host ${PREFIX}-custom-nginx:1.0 2>/dev/null || docker run -d --name ${PREFIX}-net-host --network host nginx:1.27-alpine"
run "sleep 2"
run "docker inspect ${PREFIX}-net-host --format 'NetworkMode={{.HostConfig.NetworkMode}}  PublishedPorts={{.NetworkSettings.Ports}}'"
run "curl -sI http://localhost:80/ | head -3"
echo "No -p flag was used, yet port 80 answers on the host: the container is"
echo "listening directly in the host's network namespace."
run "docker rm -f ${PREFIX}-net-host"

#=====================================================================
# 3. ISOLATED NETWORK
#=====================================================================
step "3/3 ISOLATED NETWORK — created with --internal (no route to the outside)"
run "docker network create --driver bridge --internal --subnet 172.31.0.0/24 $INT"
run "docker network inspect $INT --format 'name={{.Name}} internal={{.Internal}} subnet={{range .IPAM.Config}}{{.Subnet}}{{end}}'"

run "docker run -d --name ${PREFIX}-iso-a --network $INT $IMG sleep 3600"
run "docker run -d --name ${PREFIX}-iso-b --network $INT $IMG sleep 3600"

step "Inside the isolated network, containers still talk to each other"
run "docker exec ${PREFIX}-iso-a ping -c 3 ${PREFIX}-iso-b"

step "But they CANNOT reach the internet — this failure is the evidence"
run_expect_fail "docker exec ${PREFIX}-iso-a ping -c 2 -W 3 1.1.1.1"
run_expect_fail "docker exec ${PREFIX}-iso-a wget -T 5 -qO- http://example.com"
run "docker exec ${PREFIX}-iso-a ip route"
echo "^ no default gateway to the outside: --internal removed the NAT route."

step "A container on the normal bridge cannot reach the isolated containers either"
ISO_IP=$(docker inspect ${PREFIX}-iso-b --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
echo "isolated container IP: $ISO_IP"
run_expect_fail "docker exec ${PREFIX}-net-a ping -c 2 -W 3 $ISO_IP"

step "Summary of the three network modes used"
run "docker network ls --filter name=${PREFIX} --format 'table {{.Name}}\t{{.Driver}}\t{{.Scope}}'"
run "docker network inspect $BR $INT --format '{{.Name}}: internal={{.Internal}} containers={{len .Containers}}'"

step "Tear down the networking demo containers and networks"
cleanup_net
run "docker network ls --filter name=${PREFIX} --format '{{.Name}}' | wc -l"

finish
