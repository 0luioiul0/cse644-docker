#!/usr/bin/env bash
# Shared helpers for the CSE644 Docker assignment demo scripts.
#
# Every script prints the exact command it is about to run, prefixed with "$",
# followed by that command's real output. The transcript in evidence/ is
# therefore reproducible: anything in it can be re-run by copying the line.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVIDENCE="$ROOT/evidence"
mkdir -p "$EVIDENCE"

# Everything created by these scripts is prefixed cse644- so cleanup.sh can
# remove it without touching anything else running on this Docker host.
PREFIX="cse644"

start_log() {
    local name="$1"
    exec > >(tee "$EVIDENCE/${name}.txt") 2>&1
    echo "==============================================================="
    echo " CSE644 Docker Assignment — ${name}"
    echo " host date : $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo " docker    : $(docker --version)"
    echo "==============================================================="
}

step() {
    echo
    echo "---------------------------------------------------------------"
    echo "STEP: $*"
    echo "---------------------------------------------------------------"
}

run() {
    echo
    echo "\$ $*"
    eval "$*"
    local rc=$?
    [ $rc -ne 0 ] && echo "[exit status: $rc]"
    return 0
}

# Same as run(), but for commands we expect to fail (used by the isolated
# network demo, where a failure IS the evidence).
run_expect_fail() {
    echo
    echo "\$ $*"
    if eval "$*"; then
        echo "[UNEXPECTED: command succeeded]"
    else
        echo "[exit status: $? — failure expected here, this is the evidence]"
    fi
    return 0
}

wait_http() {
    local url="$1" tries="${2:-30}"
    for _ in $(seq "$tries"); do
        curl -fs -o /dev/null "$url" 2>/dev/null && return 0
        sleep 1
    done
    echo "[warning: $url did not become ready]"
    return 1
}

finish() {
    echo
    echo "==============================================================="
    echo " done: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "==============================================================="
}
