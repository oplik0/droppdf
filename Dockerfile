# Use Python 3.9 as base image
FROM python:3.9-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # LibreOffice for document conversion
    libreoffice \
    libreoffice-writer \
    libreoffice-calc \
    libreoffice-impress \
    # OCRmyPDF dependencies
    ocrmypdf \
    tesseract-ocr \
    tesseract-ocr-eng \
    # Image processing libraries
    ghostscript \
    img2pdf \
    libpq-dev \
    # Build tools
    gcc \
    g++ \
    # Other utilities
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create directories for static files and uploads
RUN mkdir -p /app/static /app/upload/static/drop-pdf /app/static/fingerprints /app/upload/static/fingerprints

# Expose port for Django
EXPOSE 8000

# Set the working directory to where manage.py is located
WORKDIR /app/droppdf

# Default command - can be overridden in docker-compose or at runtime
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
