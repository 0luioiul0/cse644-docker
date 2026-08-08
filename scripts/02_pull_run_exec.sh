#!/usr/bin/env bash
# Requirement 4: pull a public image, run it as a container, and open an
# interactive shell session inside the running container.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
start_log "02-pull-run-exec"

CT="${PREFIX}-exec-demo"
IMG="ubuntu:24.04"

docker rm -f "$CT" >/dev/null 2>&1

step "Pull a public image from Docker Hub"
run "docker pull $IMG"
run "docker images $IMG"
run "docker image inspect $IMG --format 'digest: {{index .RepoDigests 0}}'"

step "Run the image as a container"
run "docker run -d --name $CT $IMG sleep 3600"
run "docker ps --filter name=$CT --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Command}}'"

step "Open an interactive shell session inside the running container"
echo
echo "A pseudo-terminal is allocated with script(1) so the transcript below is a"
echo "real interactive bash session: the prompt, the typed commands and their"
echo "output all come from inside the container."
echo

SESSION_INPUT="$(mktemp)"
cat > "$SESSION_INPUT" <<'EOS'
echo "--- I am inside the container now ---"
hostname
whoami
cat /etc/os-release | head -2
ls /
echo "written from the interactive session" > /tmp/proof.txt
cat /tmp/proof.txt
exit
EOS

# strip terminal colour / bracketed-paste escapes so the transcript is readable
strip_ansi() { sed -r 's/\x1B\][^\x07]*(\x07|\x1B\\)//g; s/\x1B\[[0-9;?]*[a-zA-Z]//g'; }

EXEC_CMD="docker exec -it -e TERM=dumb $CT bash --noediting"
echo "\$ $EXEC_CMD"
echo "  (--noediting and TERM=dumb only keep the saved transcript free of terminal"
echo "   redraw escapes; 'docker exec -it $CT bash' behaves the same at a keyboard.)"
echo
if command -v script >/dev/null 2>&1; then
    # Feed the commands one line at a time so the pty echo interleaves the way
    # it would if a person were typing them.
    { sleep 2; while IFS= read -r line; do printf '%s\n' "$line"; sleep 1; done < "$SESSION_INPUT"; } \
        | script -qec "$EXEC_CMD" /dev/null | strip_ansi
else
    echo "(script(1) unavailable — no PTY, commands piped instead)"
    docker exec -i "$CT" bash < "$SESSION_INPUT"
fi
rm -f "$SESSION_INPUT"

step "The file written during the session lives only inside that container"
run "docker exec $CT cat /tmp/proof.txt"
run "docker exec $CT ls -l /tmp/proof.txt"

step "Container is still running after the interactive session ended"
run "docker ps --filter name=$CT --format 'table {{.Names}}\t{{.Status}}'"

step "Clean up this demo container"
run "docker rm -f $CT"

finish
