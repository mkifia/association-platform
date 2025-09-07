#!/bin/bash

REPOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPOS_DIR"

echo "🏥 Association Platform Health Check"
echo "=================================="

# Function to check service
check_service() {
    local name=$1
    local url=$2
    local expected_code=${3:-200}
    
    echo -n "🔍 $name: "
    
    if response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 "$url" 2>/dev/null); then
        if [ "$response" = "$expected_code" ]; then
            echo "✅ UP ($response)"
        else
            echo "⚠️  DEGRADED (HTTP $response)"
        fi
    else
        echo "❌ DOWN"
    fi
}

# Infrastructure checks
echo ""
echo "📡 Infrastructure Services"
check_service "Traefik Dashboard" "http://localhost:8080"
check_service "PostgreSQL" "http://localhost:8081"
check_service "RabbitMQ Management" "http://localhost:15672"
check_service "Keycloak" "http://localhost:8090"

# Backend API checks
echo ""
echo "🔧 Backend APIs"
check_service "Platform API Health" "http://localhost:8000/api/health"
check_service "Operator API Health" "http://localhost:8001/api/health"

# BFF checks
echo ""
echo "🌐 BFF Services"
check_service "Platform BFF Health" "http://localhost:3001/health"
check_service "Operator BFF Health" "http://localhost:3002/health"
check_service "Association BFF Health" "http://localhost:3003/health"

# Frontend checks
echo ""
echo "💻 Frontend Applications"
check_service "Member Portal" "http://localhost:3000"
check_service "Operator Dashboard" "http://localhost:3200"
check_service "Association Dashboard" "http://localhost:3300"

echo ""
echo "✅ Health check completed"
