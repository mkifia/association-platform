#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOS=("association-platform-infrastructure" "association-platform-backend-apis" "association-platform-bff-services" "association-platform-frontend-apps")

echo -e "${BLUE}🚀 Setting up Association Platform Multi-Repository Architecture${NC}"
echo -e "${BLUE}================================================================${NC}"

# Function to print step
print_step() {
    echo -e "\n${BLUE}📋 Step $1: $2${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
print_step 1 "Checking prerequisites"

# Check Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi
print_success "Docker is installed"

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi
print_success "Docker Compose is installed"

# Check Node.js
if ! command -v node &> /dev/null; then
    print_warning "Node.js is not installed. Some features may not work."
else
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        print_warning "Node.js version is less than 18. Upgrade recommended."
    else
        print_success "Node.js $(node --version) is installed"
    fi
fi

# Check PHP
if ! command -v php &> /dev/null; then
    print_warning "PHP is not installed. Backend APIs will only work via Docker."
else
    print_success "PHP $(php --version | head -n1 | cut -d' ' -f2) is installed"
fi

# Setup each repository
print_step 2 "Setting up repositories"

for repo in "${REPOS[@]}"; do
    echo -e "\n${YELLOW}📁 Setting up $repo${NC}"
    
    if [ ! -d "$REPOS_DIR/$repo" ]; then
        print_error "Repository directory $repo not found"
        continue
    fi
    
    cd "$REPOS_DIR/$repo"
    
    case $repo in
        "association-platform-infrastructure")
            # Setup infrastructure
            if [ -f "scripts/setup-dev.sh" ]; then
                chmod +x scripts/setup-dev.sh
                ./scripts/setup-dev.sh
                print_success "Infrastructure setup completed"
            else
                print_warning "Infrastructure setup script not found"
            fi
            ;;
            
        "association-platform-backend-apis")
            # Setup backend APIs
            if [ -f "platform-api/composer.json" ] && command -v composer &> /dev/null; then
                echo "Installing Platform API dependencies..."
                cd platform-api && composer install --no-dev --optimize-autoloader && cd ..
                print_success "Platform API dependencies installed"
            fi
            
            if [ -f "operator-api/composer.json" ] && command -v composer &> /dev/null; then
                echo "Installing Operator API dependencies..."
                cd operator-api && composer install --no-dev --optimize-autoloader && cd ..
                print_success "Operator API dependencies installed"
            fi
            ;;
            
        "association-platform-bff-services")
            # Setup BFF services
            if [ -f "package.json" ] && command -v npm &> /dev/null; then
                echo "Installing BFF dependencies..."
                npm install
                npm run install:all
                print_success "BFF services dependencies installed"
            fi
            ;;
            
        "association-platform-frontend-apps")
            # Setup frontend apps
            if [ -f "package.json" ] && command -v npm &> /dev/null; then
                echo "Installing Frontend dependencies..."
                npm install
                npm run install:all
                print_success "Frontend apps dependencies installed"
            fi
            ;;
    esac
done

# Create main environment file
print_step 3 "Creating main environment configuration"

cd "$REPOS_DIR"
cat > .env << EOF
# Association Platform Environment Configuration
# ============================================

# Environment
NODE_ENV=development
APP_ENV=dev

# Infrastructure Services
POSTGRES_DB=association_platform
POSTGRES_USER=postgres
POSTGRES_PASSWORD=secure_password_here
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

REDIS_PASSWORD=secure_redis_password
REDIS_HOST=redis
REDIS_PORT=6379

RABBITMQ_USER=admin
RABBITMQ_PASSWORD=secure_rabbitmq_password
RABBITMQ_HOST=rabbitmq
RABBITMQ_PORT=5672
RABBITMQ_MANAGEMENT_PORT=15672

KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=secure_keycloak_password
KEYCLOAK_URL=http://keycloak:8080
KEYCLOAK_PORT=8090

# Backend APIs
PLATFORM_API_PORT=8000
OPERATOR_API_PORT=8001
APP_SECRET=change_me_in_production_please

# BFF Services
PLATFORM_BFF_PORT=3001
OPERATOR_BFF_PORT=3002
ASSOCIATION_BFF_PORT=3003
JWT_SECRET=your_jwt_secret_here_change_in_production

# Frontend Apps
MEMBER_PORTAL_PORT=3000
OPERATOR_DASHBOARD_PORT=3200
ASSOCIATION_DASHBOARD_PORT=3300
NEXTAUTH_SECRET=your_nextauth_secret_here

# API URLs (for development)
PLATFORM_API_URL=http://localhost:8000/api
OPERATOR_API_URL=http://localhost:8001/api
NEXT_PUBLIC_API_URL=http://localhost:3001

# CORS Configuration
CORS_ORIGINS=http://localhost:3000,http://localhost:3100,http://localhost:3200,http://localhost:3300
CORS_ALLOW_ORIGIN=^https?://(localhost|127\.0\.0\.1)(:[0-9]+)?$

# Logging
LOG_LEVEL=debug

# Health Check
HEALTH_CHECK_INTERVAL=30000
EOF

print_success "Main environment file created"

# Copy environment files to each repository
for repo in "${REPOS[@]}"; do
    if [ -d "$REPOS_DIR/$repo" ]; then
        cp "$REPOS_DIR/.env" "$REPOS_DIR/$repo/.env"
        print_success "Environment file copied to $repo"
    fi
done

# Create development scripts
print_step 4 "Creating development scripts"

# Start all services script
cat > "$REPOS_DIR/start-all.sh" << 'EOF'
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
EOF

# Stop all services script
cat > "$REPOS_DIR/stop-all.sh" << 'EOF'
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
EOF

# Health check script
cat > "$REPOS_DIR/health-check.sh" << 'EOF'
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
EOF

# Make scripts executable
chmod +x "$REPOS_DIR/start-all.sh"
chmod +x "$REPOS_DIR/stop-all.sh"
chmod +x "$REPOS_DIR/health-check.sh"

print_success "Development scripts created"

print_step 5 "Final setup"

# Create main README
cat > "$REPOS_DIR/README.md" << 'EOF'
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
EOF

print_success "Main README created"

echo ""
echo -e "${GREEN}🎉 Association Platform Multi-Repository Setup Complete! 🎉${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "1. Review and customize the .env file"
echo "2. Run './start-all.sh' to start all services"
echo "3. Run './health-check.sh' to verify everything works"
echo "4. Access applications at the URLs shown above"
echo ""
echo -e "${YELLOW}💡 Useful Commands:${NC}"
echo "• Start all: ./start-all.sh"
echo "• Stop all: ./stop-all.sh" 
echo "• Health check: ./health-check.sh"
echo "• View logs: docker-compose logs -f"
echo ""
echo -e "${GREEN}✅ Happy coding! 🚀${NC}"
