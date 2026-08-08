# Requirement 7: the Nginx backend that sits behind HAProxy
FROM nginx:1.27-alpine

LABEL org.opencontainers.image.title="cse644-proxy-nginx" \
      org.opencontainers.image.description="Nginx backend served through HAProxy for CSE644 Docker assignment" \
      course="CSE644 Cloud Computing"

RUN rm -rf /usr/share/nginx/html/*
COPY html/ /usr/share/nginx/html/
COPY default.conf /etc/nginx/conf.d/default.conf

RUN nginx -t

EXPOSE 80

HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1/health || exit 1
