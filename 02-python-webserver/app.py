#!/usr/bin/env python3
"""Minimal Python web server for CSE644 Docker assignment (requirement 6).

Standard library only, so the image stays small and the build needs no package
index. Listens on port 8888 as required.

Routes
    GET /         HTML landing page
    GET /api/info JSON with container hostname, uptime and request count
    GET /health   plain-text health check used by HEALTHCHECK and HAProxy
"""

import json
import os
import platform
import socket
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(os.environ.get("PORT", "8888"))
STARTED = time.time()
REQUESTS = 0

PAGE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>CSE644 &middot; Python web server in Docker</title>
<style>
 body{{margin:0;padding:3rem 1.25rem;background:#0f1115;color:#e7e9ee;
      font:16px/1.65 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif}}
 .card{{max-width:44rem;margin:0 auto;background:#171a21;border:1px solid #262b36;
        border-radius:14px;padding:2.5rem}}
 .eyebrow{{margin:0 0 .5rem;font-size:.78rem;letter-spacing:.14em;text-transform:uppercase;color:#4aa3ff}}
 h1{{margin:0 0 1rem;font-size:1.6rem;line-height:1.3}}
 p{{color:#99a1b3}}
 table{{width:100%;border-collapse:collapse;margin-top:1.25rem}}
 td{{padding:.45rem 0;border-bottom:1px dashed #262b36;vertical-align:top}}
 td:first-child{{color:#99a1b3;width:12rem}}
 code{{font-family:ui-monospace,Menlo,Consolas,monospace;background:rgba(127,145,180,.16);
       padding:.12em .38em;border-radius:4px}}
</style>
</head>
<body>
<div class="card">
  <p class="eyebrow">Cloud Computing CSE644 &middot; Requirement 6</p>
  <h1>Python web server, containerized, listening on port 8888.</h1>
  <p>Written with the Python standard library only &mdash; no framework, no pip install
     during the image build. The values below are read at request time inside the
     container, so they change if you rebuild or restart it.</p>
  <table>
    <tr><td>Container hostname</td><td><code>{hostname}</code></td></tr>
    <tr><td>Container IP</td><td><code>{ip}</code></td></tr>
    <tr><td>Python</td><td><code>{python}</code></td></tr>
    <tr><td>Listening on</td><td><code>0.0.0.0:{port}</code></td></tr>
    <tr><td>Uptime</td><td><code>{uptime:.1f}s</code></td></tr>
    <tr><td>Requests served</td><td><code>{requests}</code></td></tr>
  </table>
  <p style="margin-top:1.5rem">Machine-readable version: <code>GET /api/info</code></p>
</div>
</body>
</html>
"""


def container_ip() -> str:
    try:
        return socket.gethostbyname(socket.gethostname())
    except OSError:
        return "unknown"


class Handler(BaseHTTPRequestHandler):
    server_version = "CSE644PyServer/1.0"
    protocol_version = "HTTP/1.1"   # every response below sets Content-Length

    def _send(self, code: int, body: bytes, content_type: str) -> None:
        self.send_response(code)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("X-Served-By", socket.gethostname())
        self.end_headers()
        if self.command != "HEAD":      # HEAD returns headers only
            self.wfile.write(body)

    def do_GET(self) -> None:  # noqa: N802 (name fixed by BaseHTTPRequestHandler)
        global REQUESTS
        REQUESTS += 1
        path = self.path.split("?", 1)[0].rstrip("/") or "/"

        if path == "/health":
            self._send(200, b"ok\n", "text/plain; charset=utf-8")
        elif path == "/api/info":
            payload = {
                "service": "cse644-python-web",
                "hostname": socket.gethostname(),
                "ip": container_ip(),
                "python": platform.python_version(),
                "port": PORT,
                "uptime_seconds": round(time.time() - STARTED, 1),
                "requests_served": REQUESTS,
            }
            body = (json.dumps(payload, indent=2) + "\n").encode()
            self._send(200, body, "application/json; charset=utf-8")
        elif path == "/":
            body = PAGE.format(
                hostname=socket.gethostname(),
                ip=container_ip(),
                python=platform.python_version(),
                port=PORT,
                uptime=time.time() - STARTED,
                requests=REQUESTS,
            ).encode()
            self._send(200, body, "text/html; charset=utf-8")
        else:
            self._send(404, b"not found\n", "text/plain; charset=utf-8")

    def do_HEAD(self) -> None:  # noqa: N802
        self.do_GET()

    def log_message(self, fmt: str, *args) -> None:
        # One tidy line per request on stdout so `docker logs` is readable evidence.
        print("[%s] %s" % (self.log_date_time_string(), fmt % args), flush=True)


def main() -> None:
    server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    print(f"cse644-python-web listening on 0.0.0.0:{PORT} "
          f"(hostname={socket.gethostname()})", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("shutting down", flush=True)
        server.shutdown()


if __name__ == "__main__":
    main()
