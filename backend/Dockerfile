# Use official Python lightweight image
FROM python:3.9-slim

# Set working directory inside the container
WORKDIR /app

# Install system dependencies required by OpenCV and sounddevice
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
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

# Expose Render's default port (and make it flexible)
ENV PORT=5000
EXPOSE $PORT

# Start application using Gunicorn with threads to support WebSockets (flask-sock)
CMD gunicorn -w 1 --threads 100 -b 0.0.0.0:$PORT server:app
