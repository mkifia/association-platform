# Association Platform - Multi-Repository Architecture

This is the main directory containing all Association Platform repositories organized in a multi-repository structure for better scalability, maintainability, and team collaboration.

## 🏗️ Repository Structure

```
association-platform/
├── association-platform-infrastructure/    # Docker, Traefik, infrastructure configs
├── association-platform-backend-apis/      # Symfony APIs (platform-api, operator-api)
├── association-platform-bff-services/      # NestJS BFF services
├── association-platform-frontend-apps/     # Next.js frontend applications
├── start-all.sh                           # Start all services
├── stop-all.sh                            # Stop all services  
├── health-check.sh                        # Check services health
└── .env                                   # Main environment configuration
```

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- Node.js 18+ (optional, for local development)
- PHP 8.2+ & Composer (optional, for local API development)

### Setup
```bash
# Run the setup script
./setup-all.sh

# Start all services
./start-all.sh

# Check services health
./health-check.sh
```

### Access URLs
- **Member Portal**: http://localhost:3000
- **Association Dashboard**: http://localhost:3300
- **Operator Dashboard**: http://localhost:3200
- **Traefik Dashboard**: http://localhost:8080
- **Keycloak Admin**: http://localhost:8090
- **Database Admin**: http://localhost:8081

## 📋 Repository Details

### Infrastructure
Contains Docker Compose files, Traefik configuration, and shared infrastructure components.
- PostgreSQL, Redis, RabbitMQ, Keycloak
- Reverse proxy and load balancing
- Development environment setup

### Backend APIs  
Symfony-based REST APIs with shared components.
- **Platform API**: Main business logic
- **Operator API**: Admin and SaaS management
- **Shared**: Common entities and services

### BFF Services
NestJS Backend-for-Frontend services with shared utilities.
- **Platform BFF**: Serves Member Portal
- **Operator BFF**: Serves Operator Dashboard  
- **Association BFF**: Serves Association Dashboard
- **Shared**: Common types and HTTP client

### Frontend Apps
Next.js applications with shared components.
- **Member Portal**: Public member interface
- **Association Dashboard**: Association management
- **Operator Dashboard**: Platform administration
- **Shared**: Common UI components and hooks

## 🔧 Development

### Individual Repository Development
```bash
# Work on specific repository
cd association-platform-infrastructure
./scripts/setup-dev.sh

cd ../association-platform-backend-apis
composer install
docker-compose -f docker-compose.apis.yml up -d

cd ../association-platform-bff-services  
npm install && npm run start:dev

cd ../association-platform-frontend-apps
npm install && npm run dev
```

### Environment Configuration
Edit `.env` file in the root directory. Changes will be synced to all repositories.

### Logs
```bash
# View logs from all services
docker-compose logs -f

# Specific service logs
cd association-platform-infrastructure
docker-compose -f docker-compose.infrastructure.yml logs -f postgres
```

## 🧪 Testing

```bash
# Run health checks
./health-check.sh

# Test individual repositories
cd association-platform-backend-apis
./scripts/test-apis.sh

cd ../association-platform-bff-services
npm run test

cd ../association-platform-frontend-apps
npm run test
```

## 🚨 Troubleshooting

### Port Conflicts
Check if ports are in use:
```bash
lsof -i :3000  # Member Portal
lsof -i :8000  # Platform API
lsof -i :5432  # PostgreSQL
```

### Docker Issues
```bash
# Clean up Docker
docker system prune -f
docker volume prune -f

# Restart services
./stop-all.sh && ./start-all.sh
```

### Reset Everything
```bash
./stop-all.sh
docker system prune -af
docker volume prune -f
./start-all.sh
```

## 📦 Production Deployment

Each repository contains its own Docker Compose production configuration:

```bash
# Build production images
cd association-platform-backend-apis
docker-compose -f docker-compose.apis.yml -f docker-compose.prod.yml build

cd ../association-platform-bff-services  
docker-compose -f docker-compose.bff.yml -f docker-compose.prod.yml build

cd ../association-platform-frontend-apps
docker-compose -f docker-compose.frontend.yml -f docker-compose.prod.yml build
```

## 🤝 Contributing

1. Each repository follows its own development workflow
2. Make changes in feature branches
3. Test locally with `./health-check.sh`
4. Submit pull requests to individual repositories

## 📄 License

This project is licensed under the MIT License - see individual repository LICENSE files for details.
