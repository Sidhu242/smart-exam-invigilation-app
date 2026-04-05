# Use official Python lightweight image
FROM python:3.9-slim

# Set working directory inside the container
WORKDIR /app

# Install system dependencies required by OpenCV and sounddevice
RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    portaudio19-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements.txt first (leverage Docker cache)
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the backend files
COPY . .

# Expose Hugging Face Spaces default port
ENV PORT=7860
EXPOSE 7860

# Start application using Gunicorn with threads to support WebSockets (flask-sock)
CMD gunicorn -w 1 --threads 100 -b 0.0.0.0:7860 server:app
