# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Architecture Overview

This is a **multi-repository microservices platform** for association management, organized into four main components:

### Repository Structure
```
association-platform/
├── association-platform-infrastructure/    # Infrastructure services (Docker, Traefik, databases)
├── association-platform-backend-apis/      # Symfony APIs (platform-api, operator-api) 
├── association-platform-bff-services/      # NestJS Backend-for-Frontend services
├── association-platform-frontend-apps/     # Next.js frontend applications
├── setup-all.sh                           # Complete platform setup
├── start-all.sh                           # Start all services
├── stop-all.sh                            # Stop all services
└── health-check.sh                        # Verify service health
```

### Service Architecture

**Data Flow**: Frontend Apps → BFF Services → Backend APIs → Infrastructure Services

1. **Frontend Layer** (Next.js 14 + TypeScript)
   - Member Portal (`:3000`) - Public member interface
   - Association Dashboard (`:3300`) - Association management
   - Operator Dashboard (`:3200`) - Platform administration

2. **BFF Layer** (NestJS 10 + TypeScript)
   - Platform BFF (`:3001`) - Serves Member Portal
   - Association BFF (`:3003`) - Serves Association Dashboard  
   - Operator BFF (`:3002`) - Serves Operator Dashboard

3. **API Layer** (Symfony 7 + API Platform)
   - Platform API (`:8000`) - Core business logic (associations, members, contributions)
   - Operator API (`:8001`) - Multi-tenant administration and SaaS management

4. **Infrastructure Layer**
   - PostgreSQL (`:5432`) - Primary database
   - Redis (`:6379`) - Caching and sessions
   - RabbitMQ (`:5672`) - Message queuing
   - Keycloak (`:8090`) - Identity and access management
   - Traefik (`:8080`) - Reverse proxy and load balancer

### Core Domain Entities
- **Association**: Multi-tenant organizations with settings, branding, and configuration
- **Member**: Association members with profiles, membership types, and status tracking
- **Contribution**: Financial contributions (fees, donations, payments) with status workflows
- **Event**: Association events with participant management
- **MembershipType**: Configurable membership categories per association

## Common Development Commands

### Full Platform Operations
```bash
# Complete setup (first time only)
./setup-all.sh

# Start all services in correct order
./start-all.sh

# Stop all services
./stop-all.sh

# Check health of all services
./health-check.sh

# Synchronize environment configurations
./sync-configs.sh
```

### Backend APIs Development
```bash
cd association-platform-backend-apis

# Run tests
composer test                    # Platform API tests
cd operator-api && composer test # Operator API tests

# Code quality
composer phpstan                 # Static analysis
composer cs-fixer               # Check code style
composer cs-fixer-fix           # Fix code style

# Database operations  
php platform-api/bin/console doctrine:migrations:migrate
php operator-api/bin/console doctrine:fixtures:load

# Start APIs via Docker
docker-compose -f docker-compose.apis.yml up -d

# View API logs
docker-compose -f docker-compose.apis.yml logs -f
```

### BFF Services Development
```bash
cd association-platform-bff-services

# Install dependencies
npm run install:all

# Development mode (all services)
npm run start:dev

# Individual service development
npm run start:dev -w platform-bff
npm run start:dev -w operator-bff
npm run start:dev -w association-bff

# Testing
npm run test              # All services
npm run test -w platform-bff  # Specific service

# Production build
npm run build
npm run start

# Docker operations
npm run build:docker
npm run start:docker
npm run stop:docker
```

### Frontend Applications Development
```bash
cd association-platform-frontend-apps

# Install dependencies
npm run install:all

# Development mode (all apps)
npm run dev

# Individual app development  
npm run dev -w member-portal
npm run dev -w association-dashboard
npm run dev -w operator-dashboard

# Production build
npm run build
npm run start

# Testing and quality
npm run test
npm run lint
npm run type-check

# Docker operations
npm run build:docker
npm run start:docker
```

### Infrastructure Management
```bash
cd association-platform-infrastructure

# Setup development environment
./scripts/setup-dev.sh

# Start infrastructure services
docker-compose -f docker-compose.infrastructure.yml up -d

# View infrastructure logs
docker-compose -f docker-compose.infrastructure.yml logs -f

# Stop infrastructure
docker-compose -f docker-compose.infrastructure.yml down
```

### Single Test Execution
```bash
# Backend API single test
cd association-platform-backend-apis/platform-api
./vendor/bin/phpunit tests/Unit/Entity/AssociationTest.php

# BFF service single test  
cd association-platform-bff-services/platform-bff
npm test -- --testNamePattern="AssociationService"

# Frontend single test
cd association-platform-frontend-apps/member-portal
npm test -- components/LoginForm.test.tsx
```

### Profiler Maintenance
```bash
# Clean profiler cache if memory issues occur
cd association-platform-backend-apis
./cleanup-profiler.sh

# Manual profiler cache cleanup
docker-compose -f docker-compose.apis.yml exec platform-api rm -rf var/cache/dev/profiler/*
docker-compose -f docker-compose.apis.yml exec operator-api rm -rf var/cache/dev/profiler/*
```

## Development Workflow

### Working on a Feature
1. **Start infrastructure**: `cd association-platform-infrastructure && docker-compose -f docker-compose.infrastructure.yml up -d`
2. **Start relevant services** only (not the full platform)
3. **Make changes** in the appropriate repository
4. **Test changes** using the specific repository's test commands
5. **Health check** before committing: `./health-check.sh`

### Environment Configuration
- Main environment file: `.env` in project root
- Environment synced automatically to all repositories
- Modify `.env` and run `./sync-configs.sh` to propagate changes

### Service URLs
- **Frontend**: Member Portal (3000), Association Dashboard (3300), Operator Dashboard (3200)
- **BFF**: Platform BFF (3001), Operator BFF (3002), Association BFF (3003)  
- **APIs**: Platform API (8000), Operator API (8001)
- **Infrastructure**: Traefik Dashboard (8080), Keycloak (8090), DB Admin (8081), RabbitMQ (15672)

### Development URLs (Profiler)
- **Platform API Profiler**: http://localhost:8000/_profiler or http://api.localhost/_profiler
- **Operator API Profiler**: http://localhost:8001/_profiler or http://operator-api.localhost/_profiler
- **API Profiler Home**: Access via `X-Debug-Token-Link` header in API responses

### Debugging Services
```bash
# Check specific service logs
docker-compose logs -f [service-name]

# Check port conflicts
lsof -i :3000  # Member Portal
lsof -i :8000  # Platform API
lsof -i :5432  # PostgreSQL

# Reset everything if issues
./stop-all.sh
docker system prune -af
docker volume prune -f
./start-all.sh
```

### Technology Stack per Layer
- **Frontend**: Next.js 14, React 18, TypeScript, Tailwind CSS, React Query, React Hook Form
- **BFF**: NestJS 10, TypeScript, Axios, Redis client, Joi validation
- **Backend**: Symfony 7, API Platform 4, Doctrine ORM 3, PHP 8.2+, PostgreSQL
- **Infrastructure**: Docker Compose, Traefik v3, PostgreSQL 15, Redis 7, RabbitMQ 3, Keycloak 22

### Shared Components Architecture
Each layer has a `shared/` directory containing reusable code:
- **Backend**: `shared/entities/` and `shared/services/` for common domain logic
- **BFF**: `shared/types/` and `shared/services/` for TypeScript definitions and HTTP clients
- **Frontend**: `shared/components/` and `shared/hooks/` for UI components and React hooks

## Development Context

This platform uses a **multi-tenant SaaS architecture** where:
- The **Operator** manages multiple associations (tenants)
- Each **Association** has its own members, events, and contributions
- **Multi-repository structure** enables independent development and deployment
- **BFF pattern** provides tailored APIs for each frontend application
- **API Platform** generates REST APIs automatically from Symfony entities
- **Workspace configuration** allows monorepo-style development within each repository

The codebase follows **domain-driven design principles** with clear separation between business logic (Backend APIs), application logic (BFF Services), and presentation logic (Frontend Apps).
