#!/usr/bin/env bash
# Optional: capture browser screenshots of the three web pages using headless
# Chromium in a container, so the submission has images as well as transcripts.
#
# Requires 03, 04 and 05 to be running (bash scripts/run_all.sh does that).
set -uo pipefail
source "$(dirname "$0")/lib.sh"

SHOTS="$EVIDENCE/screenshots"
mkdir -p "$SHOTS"

shoot() {
    local name="$1" url="$2"
    echo "  capturing $url -> evidence/screenshots/${name}.png"
    docker run --rm --network host \
        -v "$SHOTS:/out" --entrypoint chromium-browser \
        zenika/alpine-chrome \
        --headless --disable-gpu --no-sandbox --hide-scrollbars \
        --window-size=1280,900 --virtual-time-budget=3000 \
        --screenshot=/out/${name}.png "$url" >/dev/null 2>&1
}

echo "Capturing screenshots of the running services..."
shoot "05-custom-nginx-8081"   "http://localhost:8081/"
shoot "06-python-web-8888"     "http://localhost:8888/"
shoot "07-haproxy-nginx-8082"  "http://localhost:8082/"
shoot "07-haproxy-stats-8404"  "http://localhost:8404/"

echo
ls -l "$SHOTS"
