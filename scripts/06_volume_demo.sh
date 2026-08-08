#!/usr/bin/env bash
# Requirement 8: persistent storage with a Docker volume — prove that data
# survives removal and recreation of the container.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
start_log "06-persistent-volume"

VOL="${PREFIX}-data"
CT="${PREFIX}-vol-demo"

docker rm -f "$CT" >/dev/null 2>&1
docker volume rm "$VOL" >/dev/null 2>&1

step "Create a named volume"
run "docker volume create $VOL"
run "docker volume ls --filter name=$VOL"
run "docker volume inspect $VOL"

step "Container #1: mount the volume at /data and write to it"
run "docker run -d --name $CT -v ${VOL}:/data alpine:3.20 sleep 3600"
run "docker exec $CT sh -c 'echo \"line 1 written by container #1 at \$(date -u +%H:%M:%S), hostname \$(hostname)\" >> /data/persistent.log'"
run "docker exec $CT sh -c 'echo \"line 2 written by container #1\" >> /data/persistent.log'"
run "docker exec $CT sh -c 'echo \"this file is NOT on the volume\" > /tmp/ephemeral.txt'"
run "docker exec $CT cat /data/persistent.log"
run "docker exec $CT cat /tmp/ephemeral.txt"
run "docker exec $CT df -h /data | tail -1"
run "docker inspect $CT --format 'mount: {{range .Mounts}}{{.Type}} {{.Name}} -> {{.Destination}}{{end}}'"

step "DESTROY the container completely"
run "docker rm -f $CT"
run "docker ps -a --filter name=$CT --format '{{.Names}}' | wc -l"
echo "(0 containers left with that name — the container no longer exists)"

step "The volume still exists on its own"
run "docker volume ls --filter name=$VOL"

step "Container #2: brand new container, same volume"
run "docker run -d --name $CT -v ${VOL}:/data alpine:3.20 sleep 3600"
run "docker inspect $CT --format 'container id: {{.Id}}'"

step "The data written by container #1 is still there"
run "docker exec $CT cat /data/persistent.log"
echo
echo "^ written by the container that was deleted. Data survived."

step "The non-volume file did NOT survive — this is the control case"
run_expect_fail "docker exec $CT cat /tmp/ephemeral.txt"
echo "/tmp was part of the container's writable layer, which was destroyed with it."

step "Container #2 appends to the same volume"
run "docker exec $CT sh -c 'echo \"line 3 written by container #2 at \$(date -u +%H:%M:%S), hostname \$(hostname)\" >> /data/persistent.log'"
run "docker exec $CT cat /data/persistent.log"

step "Recreate once more to show the accumulated history persists"
run "docker rm -f $CT"
run "docker run --rm -v ${VOL}:/data alpine:3.20 cat /data/persistent.log"

step "Where the volume actually lives on the host"
run "docker volume inspect $VOL --format 'mountpoint: {{.Mountpoint}}'"
run "sudo -n ls -l \$(docker volume inspect $VOL --format '{{.Mountpoint}}') 2>/dev/null || echo '(host path is root-owned; contents shown through a container above)'"

finish
