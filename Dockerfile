# =========================
# Stage 1: Build Flutter Web
# =========================
FROM debian:bookworm-slim AS build-env

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Clone Flutter stable SDK
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter

# Configure Git safe directory
RUN git config --global --add safe.directory /usr/local/flutter

# Add Flutter to PATH
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Disable analytics
RUN flutter config --no-analytics

# FIX: Pre-download Flutter dependencies safely
RUN mkdir -p /usr/local/flutter/bin/cache/artifacts/gradle_wrapper

# FIX: Download gradle wrapper manually
RUN curl -L https://storage.googleapis.com/flutter_infra_release/gradle-wrapper/fd5c1f2c013565a3bea56ada6df9d2b8e96d56aa/gradle-wrapper.tgz \
    -o /tmp/gradle-wrapper.tgz

# FIX: Extract without ownership issues
RUN tar --no-same-owner -xzf /tmp/gradle-wrapper.tgz \
    -C /usr/local/flutter/bin/cache/artifacts/gradle_wrapper

# Run flutter doctor safely
RUN flutter doctor

# Set working directory
WORKDIR /app

# Copy frontend source
COPY frontend /app

# Clean old build cache
RUN flutter clean

# Get dependencies
RUN flutter pub get

# Generate missing platform folders if needed
RUN flutter create .

# Build Flutter Web
RUN flutter build web --release \
    --dart-define=API_URL=https://ramsha00-kissanai.hf.space

# =========================
# Stage 2: FastAPI Backend
# =========================
FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Install backend dependencies
COPY backend/requirements.txt /app/requirements.txt

RUN pip install --no-cache-dir -r requirements.txt

# Copy backend
COPY backend /app/backend

# Copy Flutter Web build
COPY --from=build-env /app/build/web /app/backend/web

# Create non-root user
RUN useradd -m -u 1000 user

USER user

ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

WORKDIR $HOME/app

# Copy backend with permissions
COPY --chown=user backend $HOME/app/backend

# Copy frontend web assets
COPY --chown=user --from=build-env /app/build/web $HOME/app/backend/web

EXPOSE 7860

# Run FastAPI
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "7860"]