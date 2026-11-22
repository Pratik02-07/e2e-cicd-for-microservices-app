# Multi-stage build: smaller final image
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

WORKDIR /app

COPY --from=builder /root/.local /root/.local

COPY app.py .

ENV PATH=/root/.local/bin:$PATH

ENV PYTHONUNBUFFERED=1

EXPOSE 5002

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5002/health')" || exit 1

ENTRYPOINT ["gunicorn", "--bind", "0.0.0.0:5002", "--workers", "2", "app:app"]
