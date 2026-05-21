FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the repository contents into the container
COPY . /app

# Install Python dependencies (requirements.txt is inside backend/)
RUN pip install --no-cache-dir -r backend/requirements.txt

# Hugging Face Spaces expects port 7860 for Docker SDK
EXPOSE 7860

# Run the FastAPI app with uvicorn on port 7860
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "7860"]
