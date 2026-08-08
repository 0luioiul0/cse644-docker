# CSE644 Docker Assignment — Submission

## Required submission items

| Item | Value |
|---|---|
| Name | **Chi Zhang** |
| Docker Hub username | **[your-dockerhub-username]** |
| GitHub username | **0luioiul0** |
| Docker Hub profile | https://hub.docker.com/u/[your-dockerhub-username] |
| Customized Nginx image | https://hub.docker.com/r/[your-dockerhub-username]/cse644-custom-nginx |
| Python web server image | https://hub.docker.com/r/[your-dockerhub-username]/cse644-python-web |
| HAProxy + Nginx proxy project | https://github.com/0luioiul0/cse644-docker/tree/main/03-haproxy-nginx <br> images: [`.../cse644-haproxy`](https://hub.docker.com/r/[your-dockerhub-username]/cse644-haproxy) and [`.../cse644-proxy-nginx`](https://hub.docker.com/r/[your-dockerhub-username]/cse644-proxy-nginx) |
| GitHub repository | https://github.com/0luioiul0/cse644-docker |

## Required repository contents

| Required item | Where it is |
|---|---|
| README.md | [`README.md`](README.md) |
| Dockerfile for customized Nginx image | [`01-custom-nginx/Dockerfile`](01-custom-nginx/Dockerfile) |
| Custom web page file | [`01-custom-nginx/site/index.html`](01-custom-nginx/site/index.html) (+ `style.css`) |
| Dockerfile for Python web server | [`02-python-webserver/Dockerfile`](02-python-webserver/Dockerfile) |
| Python source code | [`02-python-webserver/app.py`](02-python-webserver/app.py) |
| HAProxy + Nginx project files | [`03-haproxy-nginx/`](03-haproxy-nginx/) |
| Volume demonstration evidence | [`evidence/06-persistent-volume.txt`](evidence/06-persistent-volume.txt) |
| Networking demonstration evidence | [`evidence/07-networking.txt`](evidence/07-networking.txt) |
| Docker Hub upload evidence | [`evidence/08-dockerhub-push.txt`](evidence/08-dockerhub-push.txt) |

## Required evidence checklist

| # | Evidence | File | Where in the file |
|---|---|---|---|
| 1 | Docker installation | `evidence/01-docker-install.txt` | versions, running daemon, `hello-world` |
| 2 | Docker Hub account + CLI authentication | `evidence/08-dockerhub-push.txt` | `docker info` shows the logged-in username |
| 3 | Docker image pull | `evidence/02-pull-run-exec.txt` | `docker pull ubuntu:24.04` + digest |
| 4 | Container run | `evidence/02-pull-run-exec.txt` | `docker run -d` + `docker ps` |
| 5 | Interactive exec session | `evidence/02-pull-run-exec.txt` | full PTY transcript with the container prompt |
| 6 | Customized Nginx image | `evidence/03-custom-nginx.txt` | build, run, served page, stock-page comparison |
| 7 | Python web server image | `evidence/04-python-webserver.txt` | build, run, port 8888 in use, HTTP responses |
| 8 | HAProxy proxying to Nginx | `evidence/05-haproxy-nginx.txt` | proxy headers, 10/10 round robin, stats UP, failover |
| 9 | Persistent volume behavior | `evidence/06-persistent-volume.txt` | data survives `docker rm -f` + recreate |
| 10 | Bridge network connectivity | `evidence/07-networking.txt` | section 1/3 — DNS by container name |
| 11 | Host network demonstration | `evidence/07-networking.txt` | section 2/3 — same addresses as the host, no `-p` |
| 12 | Isolated network behavior | `evidence/07-networking.txt` | section 3/3 — `--internal`, no route out |
| 13 | Docker Hub image upload | `evidence/08-dockerhub-push.txt` | 4 × `docker push` + manifest verification |
| 14 | GitHub repository upload | repository link above | this repository |

Screenshots of the running web pages are in
[`evidence/screenshots/`](evidence/screenshots/).

## Security statement

No password, Docker Hub access token, API key, private key, or environment file
containing secrets is included in this repository or in any evidence file.
Docker Hub authentication was performed interactively with a personal access
token scoped to Read & Write; the token is stored by the Docker CLI outside this
repository and is never echoed by any script here.
