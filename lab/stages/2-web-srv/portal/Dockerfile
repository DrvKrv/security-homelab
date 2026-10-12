# Acme employee portal - small Flask app served by gunicorn.
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY templates/ templates/

# Run as a non-root user (defensive baseline).
RUN useradd --create-home --uid 10001 appuser \
    && mkdir -p /data /var/log/acme-portal \
    && chown -R appuser:appuser /data /var/log/acme-portal
USER appuser

EXPOSE 8000
# 2 workers is plenty for a lab; access log to stdout so the web layer is visible too.
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "--access-logfile", "-", "app:app"]
