# Docker Deployment Guide

## Building the Docker Image Locally

To build the Docker image locally:

```bash
docker build -t droppdf:latest .
```

## Running the Docker Container

### Basic Run (Development)

For development, you can override the default Gunicorn command to use Django's development server:

```bash
docker run -p 8000:8000 \
  -e DJANGO_DEBUG='True' \
  -e DJANGO_SECRET_KEY='dev-secret-key' \
  droppdf:latest \
  python manage.py runserver 0.0.0.0:8000
```

Note: The default CMD uses Gunicorn which is production-ready but not suitable for development with hot-reload.

### Production Deployment

For production, you'll need to provide environment variables and external services:

```bash
docker run -d \
  --name droppdf \
  -p 8000:8000 \
  -e DJANGO_SECRET_KEY='CHANGE_THIS_SECRET_KEY_TO_RANDOM_STRING' \
  -e DJANGO_DEBUG='False' \
  -e DJANGO_SERVER='prod' \
  -e DB_NAME='droppdf' \
  -e DB_USER='CHANGE_THIS_DB_USER' \
  -e DB_PASSWORD='CHANGE_THIS_DB_PASSWORD' \
  -e DB_HOST='postgres-host' \
  ghcr.io/oplik0/droppdf:latest
```

### Using Docker Compose

Create a `docker-compose.yml` file:

```yaml
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: droppdf
      POSTGRES_USER: CHANGE_THIS_DB_USER
      POSTGRES_PASSWORD: CHANGE_THIS_DB_PASSWORD
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - droppdf-network

  rabbitmq:
    image: rabbitmq:3-management
    environment:
      RABBITMQ_DEFAULT_USER: CHANGE_THIS_RABBITMQ_USER
      RABBITMQ_DEFAULT_PASS: CHANGE_THIS_RABBITMQ_PASSWORD
    ports:
      - "5672:5672"
      - "15672:15672"
    networks:
      - droppdf-network

  web:
    image: ghcr.io/oplik0/droppdf:latest
    ports:
      - "8000:8000"
    environment:
      DJANGO_SECRET_KEY: 'CHANGE_THIS_SECRET_KEY_TO_RANDOM_STRING'
      DJANGO_DEBUG: 'False'
      DJANGO_SERVER: 'prod'
      DB_NAME: 'droppdf'
      DB_USER: 'CHANGE_THIS_DB_USER'
      DB_PASSWORD: 'CHANGE_THIS_DB_PASSWORD'
      DB_HOST: 'postgres'
      CELERY_BROKER_URL: 'amqp://CHANGE_THIS_RABBITMQ_USER:CHANGE_THIS_RABBITMQ_PASSWORD@rabbitmq:5672//'
    depends_on:
      - postgres
      - rabbitmq
    networks:
      - droppdf-network

  celery:
    image: ghcr.io/oplik0/droppdf:latest
    command: celery -A droppdf worker -l info
    environment:
      DJANGO_SECRET_KEY: 'CHANGE_THIS_SECRET_KEY_TO_RANDOM_STRING'
      DJANGO_DEBUG: 'False'
      DJANGO_SERVER: 'prod'
      DB_NAME: 'droppdf'
      DB_USER: 'CHANGE_THIS_DB_USER'
      DB_PASSWORD: 'CHANGE_THIS_DB_PASSWORD'
      DB_HOST: 'postgres'
      CELERY_BROKER_URL: 'amqp://CHANGE_THIS_RABBITMQ_USER:CHANGE_THIS_RABBITMQ_PASSWORD@rabbitmq:5672//'
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

1. **Environment Variables**: Make sure to set all required environment variables (see `.env` example in `_docs/env_sample`). **IMPORTANT**: Replace all placeholder values (CHANGE_THIS_*) with actual secure values.
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
