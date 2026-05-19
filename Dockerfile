# Stage 1: Build Flutter Web
FROM debian:bookworm-slim AS build-env

# Install build dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Clone Flutter stable SDK
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter

# Configure Git safe directory for Flutter
RUN git config --global --add safe.directory /usr/local/flutter

# Add flutter to path
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Avoid tar ownership errors in rootless/user-namespace environments
ENV TAR_OPTIONS="--no-same-owner"

# Run doctor to verify setup
RUN flutter doctor -v

# Copy frontend source
WORKDIR /app
COPY frontend /app

# Generate missing platform templates
RUN flutter create .

# Build Flutter Web with production HF Spaces API URL
RUN flutter build web --release --dart-define=API_URL=https://ramsha00-kissanai.hf.space

# Stage 2: Serve Python FastAPI Backend
FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Copy backend requirements and install them
COPY backend/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the backend code into the container
COPY backend /app/backend

# Copy compiled Flutter web assets into the backend web folder
COPY --from=build-env /app/build/web /app/backend/web

# Create a non-root user for Hugging Face Spaces (recommended)
RUN useradd -m -u 1000 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

WORKDIR $HOME/app

# Copy the app again as the new user to ensure correct permissions
COPY --chown=user backend $HOME/app/backend

# Copy the compiled web folder with correct user ownership
COPY --chown=user --from=build-env /app/build/web $HOME/app/backend/web

# Copy env files if they exist
# COPY --chown=user .env* $HOME/app/ || true

EXPOSE 7860

# Run uvicorn on port 7860 as expected by Hugging Face Spaces
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "7860"]
