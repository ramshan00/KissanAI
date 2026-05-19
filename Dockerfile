# Stage 1: Build Flutter Web
FROM debian:bookworm-slim AS build-env

RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter

RUN git config --global --add safe.directory /usr/local/flutter

ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN flutter doctor -v

WORKDIR /app

COPY frontend /app

RUN flutter build web --release --dart-define=API_URL=https://ramsha00-kissanai.hf.space

# =========================
# Stage 2: FastAPI Backend
# =========================

FROM python:3.10-slim

WORKDIR /app

COPY backend/requirements.txt requirements.txt

RUN pip install --no-cache-dir -r requirements.txt

COPY backend /app/backend

COPY --from=build-env /app/build/web /app/backend/web

EXPOSE 7860

CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "7860"]