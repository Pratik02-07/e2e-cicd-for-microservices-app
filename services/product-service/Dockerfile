# -------------------------------------
# builder stage: install dependencies
# -------------------------------------
FROM python:3.11-slim AS builder

WORKDIR /build

COPY requirements.txt .

RUN pip install --user --no-cache-dir -r requirements.txt

# -------------------------------------
# runtime stage: run the application
# -------------------------------------
FROM python:3.11-slim

# Security: install OS security patches
RUN apt-get update && apt-get upgrade -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Security: create non-root user
RUN groupadd -r appuser && useradd -r -g appuser -d /app -s /sbin/nologin appuser

WORKDIR /app

COPY --from=builder /root/.local /root/.local

COPY app.py .

ENV PATH=/root/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1
ENV FLASK_ENV=production

# Security: drop to non-root user
USER appuser

EXPOSE 5001
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5001/health')" || exit 1
ENTRYPOINT ["gunicorn", "--bind", "0.0.0.0:5001", "--workers", "2", "app:app"]