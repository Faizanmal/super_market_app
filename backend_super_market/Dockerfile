# Multi-stage Dockerfile for SuperMart Pro Backend
# Optimized for production with security best practices

# Stage 1: Build stage
FROM python:3.11-slim as builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Create and set work directory
WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt


# Stage 2: Production stage
FROM python:3.11-slim as production

# Labels
LABEL maintainer="SuperMart Pro Team <dev@supermart.pro>" \
      version="2.0.0" \
      description="SuperMart Pro Backend API"

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DJANGO_ENV=production \
    APP_HOME=/app

# Create non-root user for security
RUN groupadd --gid 1000 appgroup && \
    useradd --uid 1000 --gid appgroup --shell /bin/bash --create-home appuser

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create app directory
WORKDIR $APP_HOME

# Copy wheels from builder and install
COPY --from=builder /app/wheels /wheels
RUN pip install --no-cache /wheels/* && rm -rf /wheels

# Copy application code
COPY --chown=appuser:appgroup . .

# Create necessary directories
RUN mkdir -p $APP_HOME/staticfiles \
    $APP_HOME/media \
    $APP_HOME/logs && \
    chown -R appuser:appgroup $APP_HOME

# Collect static files
RUN python manage.py collectstatic --noinput

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/api/health/ || exit 1

# Default command
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "--threads", "2", \
     "--worker-class", "gthread", "--worker-tmp-dir", "/dev/shm", \
     "--access-logfile", "-", "--error-logfile", "-", \
     "--capture-output", "--enable-stdio-inheritance", \
     "backend_super_market.wsgi:application"]
