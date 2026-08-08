# Requirement 5: customize an existing web server image (Nginx)
FROM nginx:1.27-alpine

LABEL org.opencontainers.image.title="cse644-custom-nginx" \
      org.opencontainers.image.description="Nginx customized with a hand-written landing page for CSE644 Docker assignment" \
      course="CSE644 Cloud Computing"

# Replace the stock nginx welcome page with our own static site
RUN rm -rf /usr/share/nginx/html/*
COPY site/ /usr/share/nginx/html/

# Small server-side customization so the page can prove which container served it
COPY default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

# Fail the build early if the config is invalid
RUN nginx -t

HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1/health || exit 1
