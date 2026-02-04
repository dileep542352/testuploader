# Use a slim Python 3.12 base image
FROM python:3.12-slim-bookworm

# Set the working directory
WORKDIR /app

# Install system dependencies (Optimized)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    cmake \
    make \
    libffi-dev \
    ffmpeg \
    aria2 \
    wget \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Build Bento4 (mp4decrypt)
# Note: Koyeb free tier has limited RAM, so we don't use -j$(nproc) to avoid OOM
RUN wget -q https://github.com/axiomatic-systems/Bento4/archive/refs/tags/v1.6.0-639.zip \
    && unzip v1.6.0-639.zip \
    && cd Bento4-1.6.0-639 && mkdir cmakebuild && cd cmakebuild \
    && cmake -DCMAKE_BUILD_TYPE=Release .. \
    && make mp4decrypt \
    && cp mp4decrypt /usr/local/bin/ \
    && cd /app && rm -rf Bento4-1.6.0-639 v1.6.0-639.zip

# Install Python dependencies
COPY itsgolubots.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir certifi \
    && pip install --no-cache-dir -r itsgolubots.txt \
    && pip install --no-cache-dir "yt-dlp[default]" gunicorn

# Copy the rest of the application
COPY . .

# Create the startup script dynamically
# Isme aria2, gunicorn (web server) aur main bot (main.py) teeno ek saath chalenge
RUN echo '#!/bin/bash\n\
aria2c --enable-rpc --rpc-listen-all --daemon=true\n\
gunicorn --bind 0.0.0.0:${PORT:-8000} --workers 1 --threads 2 --timeout 120 app:app &\n\
python3 main.py' > start.sh && chmod +x start.sh

# Final Command
CMD ["./start.sh"]




