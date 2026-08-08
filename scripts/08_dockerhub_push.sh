#!/usr/bin/env bash
# Requirement 10: tag and upload the images built here to Docker Hub.
#
# This script never asks for, stores, or prints a password or access token.
# Log in first, in your own terminal, with the access token you generated on
# Docker Hub (Account settings -> Personal access tokens):
#
#     docker login -u <your-dockerhub-username>
#     # paste the access token at the Password prompt
#
# Then run:
#
#     bash scripts/08_dockerhub_push.sh <your-dockerhub-username>
#
set -uo pipefail
source "$(dirname "$0")/lib.sh"

USER_NAME="${1:-${DOCKERHUB_USER:-}}"
if [ -z "$USER_NAME" ]; then
    echo "usage: bash scripts/08_dockerhub_push.sh <your-dockerhub-username>"
    exit 2
fi

start_log "08-dockerhub-push"

step "Confirm the CLI is authenticated to Docker Hub"
run "docker info --format 'Logged in as: {{.Username}}'"
LOGGED_IN=$(docker info --format '{{.Username}}' 2>/dev/null)
if [ -z "$LOGGED_IN" ]; then
    echo
    echo "Not logged in. Run 'docker login -u $USER_NAME' first (use a Docker Hub"
    echo "access token as the password), then re-run this script."
    exit 1
fi
echo "(The credential itself is stored by the Docker CLI and is never printed here.)"

IMAGES=(
    "${PREFIX}-custom-nginx:1.0"
    "${PREFIX}-python-web:1.0"
    "${PREFIX}-haproxy:1.0"
    "${PREFIX}-proxy-nginx:1.0"
)

step "Tag the locally built images for Docker Hub"
for img in "${IMAGES[@]}"; do
    run "docker tag $img ${USER_NAME}/${img}"
done
run "docker images --filter reference='${USER_NAME}/*' --format 'table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}'"

step "Push the images"
for img in "${IMAGES[@]}"; do
    run "docker push ${USER_NAME}/${img}"
done

step "Verify each image can be pulled back from Docker Hub"
for img in "${IMAGES[@]}"; do
    run "docker manifest inspect ${USER_NAME}/${img} > /dev/null && echo 'present on Docker Hub: ${USER_NAME}/${img}'"
done

step "Docker Hub links for the submission"
for img in "${IMAGES[@]}"; do
    repo="${img%%:*}"
    echo "  https://hub.docker.com/r/${USER_NAME}/${repo}"
done

finish
