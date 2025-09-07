#!/bin/bash

set -e

REPOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPOS_DIR"

echo "🔄 Synchronizing configurations between repositories..."

# Function to update BFF package.json with correct API URLs
update_bff_configs() {
    local bff_dir=$1
    local api_url=$2
    
    if [ -f "$bff_dir/src/config/configuration.ts" ]; then
        echo "Updating $bff_dir configuration..."
        cat > "$bff_dir/src/config/configuration.ts" << EOF
export default () => ({
  port: parseInt(process.env.PORT, 10) || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  
  // API Configuration
  apiUrl: process.env.PLATFORM_API_URL || '$api_url',
  operatorApiUrl: process.env.OPERATOR_API_URL || 'http://localhost:8001/api',
  
  // Redis Configuration
  redis: {
    url: process.env.REDIS_URL || 'redis://localhost:6379',
    password: process.env.REDIS_PASSWORD || '',
  },
  
  // CORS Configuration
  cors: {
    origins: process.env.CORS_ORIGINS?.split(',') || ['http://localhost:3000'],
    credentials: true,
  },
  
  // JWT Configuration
  jwt: {
    secret: process.env.JWT_SECRET || 'development-secret-key',
    expiresIn: '24h',
  },
  
  // Logging
  logging: {
    level: process.env.LOG_LEVEL || 'debug',
  },
});
EOF
    fi
}

# Function to update Frontend Next.js configs
update_frontend_configs() {
    local frontend_dir=$1
    local api_url=$2
    local app_name=$3
    
    if [ -f "$frontend_dir/next.config.js" ]; then
        echo "Updating $frontend_dir Next.js configuration..."
        cat > "$frontend_dir/next.config.js" << EOF
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    appDir: true,
  },
  
  // API rewrites to BFF
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: '$api_url/:path*',
      },
    ];
  },
  
  // Environment variables
  env: {
    NEXT_PUBLIC_APP_NAME: '$app_name',
    NEXT_PUBLIC_API_URL: '$api_url',
  },
  
  // Production optimizations
  compiler: {
    removeConsole: process.env.NODE_ENV === 'production',
  },
  
  // Output configuration for Docker
  output: 'standalone',
  
  // Image optimization
  images: {
    domains: ['localhost', '127.0.0.1'],
  },
};

module.exports = nextConfig;
EOF
    fi
}

# Update BFF configurations
echo "📡 Updating BFF service configurations..."
update_bff_configs "association-platform-bff-services/platform-bff" "http://localhost:8000/api"
update_bff_configs "association-platform-bff-services/operator-bff" "http://localhost:8001/api"  
update_bff_configs "association-platform-bff-services/association-bff" "http://localhost:8000/api"

# Update Frontend configurations
echo "💻 Updating Frontend application configurations..."
update_frontend_configs "association-platform-frontend-apps/member-portal" "http://localhost:3001" "Member Portal"
update_frontend_configs "association-platform-frontend-apps/operator-dashboard" "http://localhost:3002" "Operator Dashboard"
update_frontend_configs "association-platform-frontend-apps/association-dashboard" "http://localhost:3003" "Association Dashboard"

# Update Docker Compose service dependencies
echo "🐳 Updating Docker Compose dependencies..."

# Backend APIs - ensure they reference the external network
cd association-platform-backend-apis
if [ -f "docker-compose.apis.yml" ]; then
    # Make sure external services are properly referenced
    sed -i.bak 's/postgres:/association-platform-postgres:/g' docker-compose.apis.yml
    sed -i.bak 's/redis:/association-platform-redis:/g' docker-compose.apis.yml
    sed -i.bak 's/rabbitmq:/association-platform-rabbitmq:/g' docker-compose.apis.yml
    rm -f docker-compose.apis.yml.bak 2>/dev/null || true
fi

# BFF Services - update service references
cd ../association-platform-bff-services
if [ -f "docker-compose.bff.yml" ]; then
    sed -i.bak 's/redis:/association-platform-redis:/g' docker-compose.bff.yml
    sed -i.bak 's/platform-api:/association-platform-api:/g' docker-compose.bff.yml
    sed -i.bak 's/operator-api:/association-operator-api:/g' docker-compose.bff.yml
    rm -f docker-compose.bff.yml.bak 2>/dev/null || true
fi

cd ..

# Create shared environment template
echo "🔧 Creating shared environment template..."
cat > .env.template << 'EOF'
# Association Platform Environment Template
# Copy this file to .env and customize as needed

# Environment
NODE_ENV=development
APP_ENV=dev

# Infrastructure Services
POSTGRES_DB=association_platform
POSTGRES_USER=postgres
POSTGRES_PASSWORD=CHANGE_ME_SECURE_PASSWORD
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

REDIS_PASSWORD=CHANGE_ME_SECURE_REDIS_PASSWORD
REDIS_HOST=redis
REDIS_PORT=6379

RABBITMQ_USER=admin
RABBITMQ_PASSWORD=CHANGE_ME_SECURE_RABBITMQ_PASSWORD
RABBITMQ_HOST=rabbitmq
RABBITMQ_PORT=5672
RABBITMQ_MANAGEMENT_PORT=15672

KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=CHANGE_ME_SECURE_KEYCLOAK_PASSWORD
KEYCLOAK_URL=http://keycloak:8080
KEYCLOAK_HOSTNAME=localhost
KEYCLOAK_PORT=8090

# Backend APIs
PLATFORM_API_PORT=8000
OPERATOR_API_PORT=8001
APP_SECRET=CHANGE_ME_IN_PRODUCTION_PLEASE_VERY_SECURE

# BFF Services
PLATFORM_BFF_PORT=3001
OPERATOR_BFF_PORT=3002
ASSOCIATION_BFF_PORT=3003
JWT_SECRET=CHANGE_ME_JWT_SECRET_VERY_SECURE

# Frontend Apps
MEMBER_PORTAL_PORT=3000
OPERATOR_DASHBOARD_PORT=3200
ASSOCIATION_DASHBOARD_PORT=3300
NEXTAUTH_SECRET=CHANGE_ME_NEXTAUTH_SECRET_VERY_SECURE

# API URLs (Docker internal networking)
PLATFORM_API_URL=http://association-platform-api/api
OPERATOR_API_URL=http://association-operator-api/api
REDIS_URL=redis://:${REDIS_PASSWORD}@association-platform-redis:6379

# API URLs (for development - external access)
NEXT_PUBLIC_API_URL=http://localhost:3001

# CORS Configuration
CORS_ORIGINS=http://localhost:3000,http://localhost:3200,http://localhost:3300
CORS_ALLOW_ORIGIN=^https?://(localhost|127\.0\.0\.1)(:[0-9]+)?$

# Logging
LOG_LEVEL=debug

# Health Check
HEALTH_CHECK_INTERVAL=30000

# Adminer
ADMINER_PORT=8081
EOF

# Create development environment from template if .env doesn't exist
if [ ! -f ".env" ]; then
    echo "Creating development .env file..."
    cp .env.template .env
    # Replace CHANGE_ME values with development defaults
    sed -i.bak 's/CHANGE_ME_SECURE_PASSWORD/dev_password_123/g' .env
    sed -i.bak 's/CHANGE_ME_SECURE_REDIS_PASSWORD/dev_redis_123/g' .env
    sed -i.bak 's/CHANGE_ME_SECURE_RABBITMQ_PASSWORD/dev_rabbit_123/g' .env
    sed -i.bak 's/CHANGE_ME_SECURE_KEYCLOAK_PASSWORD/dev_keycloak_123/g' .env
    sed -i.bak 's/CHANGE_ME_IN_PRODUCTION_PLEASE_VERY_SECURE/dev_app_secret_12345678/g' .env
    sed -i.bak 's/CHANGE_ME_JWT_SECRET_VERY_SECURE/dev_jwt_secret_12345678/g' .env
    sed -i.bak 's/CHANGE_ME_NEXTAUTH_SECRET_VERY_SECURE/dev_nextauth_secret_12345678/g' .env
    rm -f .env.bak 2>/dev/null || true
fi

# Sync .env to all repositories
echo "🔄 Syncing environment files to all repositories..."
for repo in association-platform-*; do
    if [ -d "$repo" ]; then
        cp .env "$repo/"
        echo "✅ Environment synced to $repo"
    fi
done

# Create integration test configuration
echo "🧪 Creating integration test configuration..."
cat > docker-compose.test.yml << 'EOF'
# Integration Testing Docker Compose
# This file is used for running integration tests across all services

version: '3.8'

services:
  # Use lightweight test databases
  postgres-test:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: association_platform_test
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: test_password
    tmpfs:
      - /var/lib/postgresql/data
    networks:
      - test-network

  redis-test:
    image: redis:7-alpine
    command: redis-server --save ""
    tmpfs:
      - /data
    networks:
      - test-network

  # Test services with minimal resources
  platform-api-test:
    build: ./association-platform-backend-apis/platform-api
    environment:
      - APP_ENV=test
      - DATABASE_URL=postgresql://postgres:test_password@postgres-test:5432/association_platform_test
      - REDIS_URL=redis://redis-test:6379
    depends_on:
      - postgres-test
      - redis-test
    networks:
      - test-network

  platform-bff-test:
    build: ./association-platform-bff-services/platform-bff
    environment:
      - NODE_ENV=test
      - PLATFORM_API_URL=http://platform-api-test/api
      - REDIS_URL=redis://redis-test:6379
    depends_on:
      - platform-api-test
      - redis-test
    networks:
      - test-network

networks:
  test-network:
    driver: bridge

volumes: {}
EOF

echo "✅ Configuration synchronization completed!"
echo ""
echo "📋 Next steps:"
echo "1. Review and customize .env file if needed"
echo "2. Run './setup-all.sh' to initialize all repositories" 
echo "3. Run './start-all.sh' to start all services"
echo "4. Run './health-check.sh' to verify everything works"
