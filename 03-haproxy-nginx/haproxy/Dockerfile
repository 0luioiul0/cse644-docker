# Requirement 7: HAProxy image, configuration baked in so it is portable
FROM haproxy:3.0-alpine

LABEL org.opencontainers.image.title="cse644-haproxy" \
      org.opencontainers.image.description="HAProxy fronting two Nginx backends for CSE644 Docker assignment" \
      course="CSE644 Cloud Computing"

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

# Fail the build if the config does not parse
USER root
RUN haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg
USER haproxy

EXPOSE 80 8404
