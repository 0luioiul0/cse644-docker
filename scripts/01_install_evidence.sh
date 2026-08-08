#!/usr/bin/env bash
# Requirement 1: evidence that Docker is installed and running.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
start_log "01-docker-install"

step "Host and kernel"
run "uname -a"
run "cat /etc/os-release | head -3"

step "Docker client and server versions"
run "docker --version"
run "docker compose version"
run "docker version"

step "Docker daemon is running"
run "pgrep -a dockerd | head -2"
run "systemctl is-active docker 2>/dev/null || service docker status 2>&1 | head -3"

step "Docker engine information"
run "docker info --format 'Server version : {{.ServerVersion}}'"
run "docker info --format 'Storage driver : {{.Driver}}'"
run "docker info --format 'Operating sys  : {{.OperatingSystem}}'"
run "docker info --format 'CPUs / Memory  : {{.NCPU}} / {{.MemTotal}}'"
run "docker info --format 'Containers     : {{.Containers}} (running {{.ContainersRunning}})'"
run "docker info --format 'Images         : {{.Images}}'"

step "End-to-end check: run the official hello-world image"
run "docker run --rm hello-world"

finish
