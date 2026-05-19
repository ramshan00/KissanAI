FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Copy backend requirements and install them
COPY backend/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the backend code into the container
COPY backend /app/backend

# Create a non-root user for Hugging Face Spaces (recommended)
RUN useradd -m -u 1000 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

WORKDIR $HOME/app

# Copy the app again as the new user to ensure correct permissions
COPY --chown=user backend $HOME/app/backend

# We also copy any top-level env files if they exist, though HF Secrets are preferred
COPY --chown=user .env* $HOME/app/ || true

EXPOSE 7860

# Run uvicorn on port 7860 as expected by Hugging Face Spaces
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "7860"]
