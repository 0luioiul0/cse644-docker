#!/usr/bin/env bash
# Run every demonstration in order and write the transcripts to evidence/.
#
#   bash scripts/run_all.sh
#
# Docker Hub upload (08) is intentionally NOT part of this run: it requires
# your own `docker login` first. See scripts/08_dockerhub_push.sh.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

for s in 01_install_evidence 02_pull_run_exec 03_custom_nginx \
         04_python_webserver 05_haproxy_nginx 06_volume_demo 07_network_demo; do
    echo
    echo "###############################################################"
    echo "# running ${s}.sh"
    echo "###############################################################"
    bash "$HERE/${s}.sh"
done

echo
echo "All transcripts written to $(cd "$HERE/.." && pwd)/evidence/"
ls -l "$(cd "$HERE/.." && pwd)/evidence/"
