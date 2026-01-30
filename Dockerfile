# Use Python 3.9 as base image
# Note: Tested Python 3.10-3.13, but pinned dependencies (especially celery==5.0.5 
# and cryptography==3.4.6) have compatibility issues with newer Python/pip versions.
# Upgrading Python would require updating dependencies first.
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
    # XML processing libraries (for lxml)
    libxml2-dev \
    libxslt1-dev \
    # Build tools
    gcc \
    g++ \
    # Other utilities
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies (including gunicorn for production)
RUN pip install --no-cache-dir -r requirements.txt gunicorn

# Copy application code
COPY . .

# Create directories for static files and uploads
RUN mkdir -p /app/static /app/upload/static/drop-pdf /app/static/fingerprints /app/upload/static/fingerprints

# Create a non-root user to run the application
RUN useradd -m -u 1000 droppdf && \
    chown -R droppdf:droppdf /app

# Switch to non-root user
USER droppdf

# Expose port for Django
EXPOSE 8000

# Set the working directory to where manage.py is located
WORKDIR /app/droppdf

# Default command - uses gunicorn for production
# Can be overridden for development: docker run ... python manage.py runserver 0.0.0.0:8000
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "droppdf.wsgi:application"]
