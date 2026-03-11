# Multi-stage build for optimized image size
FROM python:3.11-slim AS builder

# Set working directory
WORKDIR /tmp/build

# Install system dependencies for building
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .

# Install Python dependencies in a virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir -r requirements.txt


# Final runtime image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PATH="/opt/venv/bin:$PATH" \
    VIRTUAL_ENV="/opt/venv" \
    FLASK_APP=microblog.py

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    # For DNS resolution
    dnsmasq-base \
    # For curl health checks
    curl \
    # For timezone support
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Copy Python virtual environment from builder
COPY --from=builder /opt/venv /opt/venv

# Create app user (for security)
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /home/appuser

# Give appuser permission to read/execute from venv
RUN chmod -R 755 /opt/venv

# Set working directory
WORKDIR /app

# Copy application code
COPY --chown=appuser:appuser . .

# Ensure necessary directories exist and fix permissions
RUN mkdir -p logs && chown -R appuser:appuser /app logs

# Create health check script as root (before switching user)
RUN echo '#!/bin/bash\ncurl -f http://localhost:${PORT:-8080}/health || exit 1' > /app/healthcheck.sh && chmod +x /app/healthcheck.sh

# Compile translation files (as root, before switching to appuser)
RUN /opt/venv/bin/flask translate compile || true

# Switch to app user
USER appuser
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /app/healthcheck.sh

# Google Cloud Run requires the service to listen on 0.0.0.0:$PORT (default 8080)
EXPOSE 8080

# Run gunicorn with Cloud Run optimized settings
# Cloud Run sets PORT=8080 by default, bind to that port
CMD ["/opt/venv/bin/gunicorn", \
     "--bind", "0.0.0.0:8080", \
     "--workers", "2", \
     "--worker-class", "sync", \
     "--worker-tmp-dir", "/dev/shm", \
     "--max-requests", "1000", \
     "--max-requests-jitter", "50", \
     "--timeout", "30", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "--log-level", "info", \
     "microblog:app"]

