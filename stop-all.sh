#!/bin/bash

set -e

REPOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPOS_DIR"

echo "🛑 Stopping Association Platform Services..."

# Stop frontend apps
echo "💻 Stopping frontend applications..."
cd association-platform-frontend-apps
docker-compose -f docker-compose.frontend.yml down

# Stop BFF services
echo "🌐 Stopping BFF services..."
cd ../association-platform-bff-services
docker-compose -f docker-compose.bff.yml down

# Stop backend APIs
echo "🔧 Stopping backend APIs..."
cd ../association-platform-backend-apis
docker-compose -f docker-compose.apis.yml down

# Stop infrastructure
echo "📡 Stopping infrastructure services..."
cd ../association-platform-infrastructure
docker-compose -f docker-compose.infrastructure.yml down

echo "✅ All services stopped"
