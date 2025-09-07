#!/bin/bash

set -e

REPOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPOS_DIR"

echo "🚀 Starting Association Platform Services..."

# Start infrastructure first
echo "📡 Starting infrastructure services..."
cd association-platform-infrastructure
docker-compose -f docker-compose.infrastructure.yml up -d
echo "✅ Infrastructure services started"

# Wait for infrastructure to be ready
echo "⏳ Waiting for infrastructure services to be ready..."
sleep 30

# Start backend APIs
echo "🔧 Starting backend APIs..."
cd ../association-platform-backend-apis
docker-compose -f docker-compose.apis.yml up -d
echo "✅ Backend APIs started"

# Wait for APIs to be ready
sleep 20

# Start BFF services
echo "🌐 Starting BFF services..."
cd ../association-platform-bff-services
docker-compose -f docker-compose.bff.yml up -d
echo "✅ BFF services started"

# Wait for BFF to be ready
sleep 15

# Start frontend apps
echo "💻 Starting frontend applications..."
cd ../association-platform-frontend-apps
docker-compose -f docker-compose.frontend.yml up -d
echo "✅ Frontend applications started"

echo ""
echo "🎉 All services started successfully!"
echo ""
echo "📋 Access URLs:"
echo "   • Member Portal:        http://localhost:3000"
echo "   • Operator Dashboard:   http://localhost:3200"  
echo "   • Association Dashboard: http://localhost:3300"
echo "   • Traefik Dashboard:    http://localhost:8080"
echo "   • Keycloak Admin:       http://localhost:8090"
echo "   • Database Admin:       http://localhost:8081"
echo "   • RabbitMQ Management:  http://localhost:15672"
echo ""
echo "🔍 API Endpoints:"
echo "   • Platform API:         http://localhost:8000/api"
echo "   • Operator API:         http://localhost:8001/api"
echo "   • Platform BFF:         http://localhost:3001"
echo "   • Operator BFF:         http://localhost:3002"
echo "   • Association BFF:      http://localhost:3003"
