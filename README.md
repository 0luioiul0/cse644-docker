# CSE644 Cloud Computing — Docker Assignment

Everything in this repository was built and run on a real Docker engine; the files
under [`evidence/`](evidence/) are unedited transcripts of those runs, not
hand-written examples. Each transcript prints the exact command before its output,
so any line can be copied and re-run.

| | |
|---|---|
| Student | **Chi Zhang** |
| Docker Hub username | **luioiul** |
| GitHub username | **0luioiul0** |
| Docker engine used | 29.1.3 on Ubuntu 22.04 (WSL2) |

---

## Quick start

```bash
git clone https://github.com/0luioiul0/cse644-docker.git
cd cse644-docker
bash scripts/run_all.sh          # runs demos 1-9, writes evidence/*.txt
```

Then open:

| URL | What it is |
|---|---|
| <http://localhost:8081/> | customized Nginx image (requirement 5) |
| <http://localhost:8888/> | Python web server image (requirement 6) |
| <http://localhost:8082/> | HAProxy → Nginx project (requirement 7) |
| <http://localhost:8404/> | HAProxy stats page, both backends UP |

Tear everything down with `bash scripts/cleanup.sh`. That script only removes
objects named `cse644-*`, so it is safe to run on a Docker host with other
containers on it — it never calls `docker system prune`.

---

## Requirement → evidence map

| # | Requirement | Files | Evidence |
|---|---|---|---|
| 1 | Install Docker | — | [`evidence/01-docker-install.txt`](evidence/01-docker-install.txt) |
| 2 | Docker Hub account | — | username above; profile link in [`SUBMISSION.md`](SUBMISSION.md) |
| 3 | Credentials for image upload | [`scripts/08_dockerhub_push.sh`](scripts/08_dockerhub_push.sh) | [`evidence/08-dockerhub-push.txt`](evidence/08-dockerhub-push.txt) |
| 4 | Pull, run, exec into an image | [`scripts/02_pull_run_exec.sh`](scripts/02_pull_run_exec.sh) | [`evidence/02-pull-run-exec.txt`](evidence/02-pull-run-exec.txt) |
| 5 | Customize a web server image | [`01-custom-nginx/`](01-custom-nginx/) | [`evidence/03-custom-nginx.txt`](evidence/03-custom-nginx.txt) |
| 6 | Python web server on port 8888 | [`02-python-webserver/`](02-python-webserver/) | [`evidence/04-python-webserver.txt`](evidence/04-python-webserver.txt) |
| 7 | HAProxy proxying to Nginx | [`03-haproxy-nginx/`](03-haproxy-nginx/) | [`evidence/05-haproxy-nginx.txt`](evidence/05-haproxy-nginx.txt) |
| 8 | Persistent volume | [`scripts/06_volume_demo.sh`](scripts/06_volume_demo.sh) | [`evidence/06-persistent-volume.txt`](evidence/06-persistent-volume.txt) |
| 9 | Bridge / host / isolated networking | [`scripts/07_network_demo.sh`](scripts/07_network_demo.sh) | [`evidence/07-networking.txt`](evidence/07-networking.txt) |
| 10 | Upload images to Docker Hub | [`scripts/08_dockerhub_push.sh`](scripts/08_dockerhub_push.sh) | [`evidence/08-dockerhub-push.txt`](evidence/08-dockerhub-push.txt) |
| 11–13 | GitHub account, repo, links | this repository | [`SUBMISSION.md`](SUBMISSION.md) |

---

## 1. Docker installation (requirement 1)

`scripts/01_install_evidence.sh` records the client and server versions, confirms
the `dockerd` daemon process is alive, prints engine details (storage driver, CPU,
memory, image count) and finishes by running the official `hello-world` image
end to end — which only succeeds if the client, the daemon, the registry and the
container runtime all work.

## 2. Pull, run, exec (requirement 4)

`scripts/02_pull_run_exec.sh` pulls `ubuntu:24.04`, records its digest, starts it
as a detached container, and then opens a **real interactive shell** inside it.
The transcript shows the container's own prompt (`root@<container-id>:/#`), the
commands typed at it and their output, because the session runs under a
pseudo-terminal allocated by `script(1)`. A file written during that session is
then read back from outside to prove the session really was inside the container.

## 3. Customized Nginx image (requirement 5)

[`01-custom-nginx/Dockerfile`](01-custom-nginx/Dockerfile) starts from
`nginx:1.27-alpine`, deletes the stock welcome page, copies in the hand-written
site under [`01-custom-nginx/site/`](01-custom-nginx/site/), and adds a server
block that exposes two extra endpoints:

* `/whoami` — prints the container hostname
* `/health` — used by the image's `HEALTHCHECK`

The build runs `nginx -t` as a build step, so a broken configuration fails the
build instead of failing at runtime. The evidence file proves the customization
took effect by counting occurrences of the stock "Welcome to nginx" text in the
response (0) and then starting the unmodified base image side by side to show
that it *does* return that text.

```bash
docker build -t cse644-custom-nginx:1.0 01-custom-nginx
docker run -d --name cse644-custom-nginx -p 8081:80 cse644-custom-nginx:1.0
curl -s http://localhost:8081/whoami
```

## 4. Python web server on port 8888 (requirement 6)

[`02-python-webserver/app.py`](02-python-webserver/app.py) is a standard-library
HTTP server — no framework, so the image build never needs a package index. It
serves an HTML page at `/`, JSON at `/api/info` (container hostname, IP, Python
version, uptime, request count) and `ok` at `/health`.

The image runs as a non-root user (`uid 10001`), which the evidence shows with
`docker exec … id`. Port 8888 is proven in use three ways: `docker port`, `ss -ltn`
on the host, and `netstat` inside the container.

```bash
docker build -t cse644-python-web:1.0 02-python-webserver
docker run -d --name cse644-python-web -p 8888:8888 cse644-python-web:1.0
curl -s http://localhost:8888/api/info
```

## 5. HAProxy in front of Nginx (requirement 7)

```
client ──▶ localhost:8082 ──▶ cse644-haproxy:80 ──┬──▶ web1:80  (Nginx)
                                                  └──▶ web2:80  (Nginx)
```

Two Nginx backends are used instead of one, so the evidence shows real proxy
behaviour rather than a single forwarded request:

* **Forwarding** — one response carries both `X-Proxied-By` (added by HAProxy) and
  `X-Served-By` (added by Nginx). Both headers in one response means the request
  passed through both hops.
* **Load balancing** — 20 consecutive requests to `/whoami` come back exactly
  10 × `web1` and 10 × `web2`.
* **Health checking** — the HAProxy stats CSV reports both servers `UP`; the
  checks hit the `/health` endpoint the Nginx image exposes.
* **Failover** — stopping `web1` moves all traffic to `web2` with no failed
  requests (`option redispatch` retries on a different server), the stats page
  flips `web1` to `DOWN`, and starting it again restores round-robin.
* **Real client IP** — the Nginx access log prints the `X-Forwarded-For` value
  HAProxy inserted, not just HAProxy's own container address.

The Nginx containers publish **no host ports at all**; only HAProxy does. From
outside this host, the proxy is the only way in.

```bash
docker compose -f 03-haproxy-nginx/docker-compose.yml up -d --build
for i in $(seq 10); do curl -s http://localhost:8082/whoami; done
```

## 6. Persistent volume (requirement 8)

`scripts/06_volume_demo.sh` proves persistence by destroying the container, not
just restarting it:

1. Create the named volume `cse644-data`.
2. Container #1 mounts it at `/data`, writes two lines there, and also writes a
   file to `/tmp` (**not** on the volume) as a control.
3. `docker rm -f` the container, then confirm 0 containers remain with that name.
4. A brand-new container with a different container ID mounts the same volume:
   the `/data` file is intact, and reading the `/tmp` file fails.
5. Container #2 appends a third line, is destroyed in turn, and a third container
   reads all three lines back.

The control case matters: it shows the data survived *because of the volume*,
not because the container was still around somewhere.

## 7. Docker networking (requirement 9)

`scripts/07_network_demo.sh` covers all three modes with a positive and a
negative test for each.

**Bridge** — a user-defined bridge `cse644-bridge` on `172.30.0.0/24`. Two
containers get addresses on that subnet and reach each other **by container name**,
because user-defined bridges run Docker's embedded DNS. The contrast case starts a
container on the legacy default bridge and shows the same lookup failing with
`bad address`.

**Host** — `--network host` puts the container in the host's network namespace.
The evidence prints the host's addresses and then the identical list from inside
the container. An Nginx container started with `--network host` and **no `-p`
flag** answers on host port 80, because there is no NAT layer to publish through.

**Isolated** — a bridge created with `--internal`. Containers on it still ping each
other, but `ping 1.1.1.1` fails with `Network unreachable` and `ip route` shows no
default gateway. A container on the normal bridge also cannot reach the isolated
subnet. Here the failures *are* the evidence, so the script marks those commands as
expected-to-fail rather than hiding the exit status.

## 8. Docker Hub upload (requirements 3 and 10)

Four images are published:

| Local image | Docker Hub repository |
|---|---|
| `cse644-custom-nginx:1.0` | `luioiul/cse644-custom-nginx` |
| `cse644-python-web:1.0` | `luioiul/cse644-python-web` |
| `cse644-haproxy:1.0` | `luioiul/cse644-haproxy` |
| `cse644-proxy-nginx:1.0` | `luioiul/cse644-proxy-nginx` |

Authentication uses a **Docker Hub personal access token**, not the account
password — generate it at Docker Hub → Account settings → Personal access tokens
with *Read & Write* scope. Log in interactively, then run the push script:

```bash
docker login -u luioiul      # paste the access token at the prompt
bash scripts/08_dockerhub_push.sh luioiul
```

The script refuses to run if the CLI is not authenticated, and it never prints,
echoes, or stores the token — it only reads the username back from
`docker info`.

---

## Security

No password, access token, API key, private key, or `.env` file is committed to
this repository. [`.gitignore`](.gitignore) blocks the usual credential paths, and
`docker login` stores its credential outside the repository in `~/.docker/`. If a
secret is ever committed, revoke it on Docker Hub immediately and generate a new
one — rotating is the fix, deleting the commit is not.

## Repository layout

```
.
├── 01-custom-nginx/          # requirement 5: customized Nginx image
│   ├── Dockerfile
│   ├── default.conf
│   └── site/                 # the custom web page (index.html + style.css)
├── 02-python-webserver/      # requirement 6: Python web server on port 8888
│   ├── Dockerfile
│   └── app.py
├── 03-haproxy-nginx/         # requirement 7: HAProxy → Nginx project
│   ├── docker-compose.yml
│   ├── haproxy/{Dockerfile,haproxy.cfg}
│   └── nginx/{Dockerfile,default.conf,html/}
├── scripts/                  # one script per requirement, all writing to evidence/
├── evidence/                 # captured terminal transcripts
├── SUBMISSION.md             # the links to hand in
└── README.md
```
