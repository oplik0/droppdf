# Docker Deployment Guide

## Building the Docker Image Locally

To build the Docker image locally:

```bash
docker build -t droppdf:latest .
```

## Running the Docker Container

### Basic Run (Development)

```bash
docker run -p 8000:8000 droppdf:latest
```

### Production Deployment

For production, you'll need to provide environment variables and external services:

```bash
docker run -d \
  --name droppdf \
  -p 8000:8000 \
  -e DJANGO_SECRET_KEY='your-secret-key' \
  -e DJANGO_DEBUG='False' \
  -e DJANGO_SERVER='prod' \
  -e DB_NAME='droppdf' \
  -e DB_USER='dduser' \
  -e DB_PASSWORD='ddpwd' \
  -e DB_HOST='postgres-host' \
  ghcr.io/oplik0/droppdf:latest
```

### Using Docker Compose

Create a `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: droppdf
      POSTGRES_USER: dduser
      POSTGRES_PASSWORD: ddpwd
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - droppdf-network

  rabbitmq:
    image: rabbitmq:3-management
    environment:
      RABBITMQ_DEFAULT_USER: guest
      RABBITMQ_DEFAULT_PASS: guest
    ports:
      - "5672:5672"
      - "15672:15672"
    networks:
      - droppdf-network

  web:
    image: ghcr.io/oplik0/droppdf:latest
    command: python manage.py runserver 0.0.0.0:8000
    ports:
      - "8000:8000"
    environment:
      DJANGO_SECRET_KEY: 'your-secret-key-here'
      DJANGO_DEBUG: 'False'
      DJANGO_SERVER: 'prod'
      DB_NAME: 'droppdf'
      DB_USER: 'dduser'
      DB_PASSWORD: 'ddpwd'
      DB_HOST: 'postgres'
      CELERY_BROKER_URL: 'amqp://guest:guest@rabbitmq:5672//'
    depends_on:
      - postgres
      - rabbitmq
    networks:
      - droppdf-network

  celery:
    image: ghcr.io/oplik0/droppdf:latest
    command: celery -A droppdf worker -l info
    environment:
      DJANGO_SECRET_KEY: 'your-secret-key-here'
      DJANGO_DEBUG: 'False'
      DJANGO_SERVER: 'prod'
      DB_NAME: 'droppdf'
      DB_USER: 'dduser'
      DB_PASSWORD: 'ddpwd'
      DB_HOST: 'postgres'
      CELERY_BROKER_URL: 'amqp://guest:guest@rabbitmq:5672//'
    depends_on:
      - postgres
      - rabbitmq
      - web
    networks:
      - droppdf-network

volumes:
  postgres_data:

networks:
  droppdf-network:
```

Then run:

```bash
docker-compose up -d
```

## GitHub Container Registry

The Docker image is automatically published to GitHub Container Registry (GHCR) when code is pushed to the main/master branch or when a version tag is created.

### Pulling the Image

```bash
docker pull ghcr.io/oplik0/droppdf:latest
```

### Available Tags

- `latest` - Latest build from the main branch
- `main` / `master` - Branch-specific builds
- `v*.*.*` - Semantic version tags (e.g., `v1.0.0`)

### Authentication (for private repositories)

If the repository is private, authenticate with GHCR:

```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
```

## Important Notes

1. **Environment Variables**: Make sure to set all required environment variables (see `.env` example in `_docs/env_sample`)
2. **Database Migrations**: Run migrations before starting the application:
   ```bash
   docker run --rm ghcr.io/oplik0/droppdf:latest python manage.py migrate
   ```
3. **Static Files**: Collect static files if needed:
   ```bash
   docker run --rm ghcr.io/oplik0/droppdf:latest python manage.py collectstatic --noinput
   ```
4. **Volumes**: Mount volumes for persistent data (uploads, static files, etc.)
5. **External Services**: The application requires PostgreSQL and RabbitMQ to function properly
6. **AWS Configuration**: Configure AWS credentials for document storage if using S3
