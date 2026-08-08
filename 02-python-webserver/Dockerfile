# Requirement 6: simple Python web server, containerized, serving on port 8888
FROM python:3.12-alpine

LABEL org.opencontainers.image.title="cse644-python-web" \
      org.opencontainers.image.description="Standard-library Python web server on port 8888 for CSE644 Docker assignment" \
      course="CSE644 Cloud Computing"

ENV PORT=8888 \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY app.py .

# Run as a non-root user: the container never needs root to bind 8888
RUN adduser -D -u 10001 appuser && chown -R appuser /app
USER appuser

EXPOSE 8888

HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8888/health || exit 1

CMD ["python", "app.py"]
