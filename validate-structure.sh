#!/bin/bash

set -e

REPOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPOS_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Validating Association Platform Multi-Repository Structure${NC}"
echo -e "${BLUE}=============================================================${NC}"

ERRORS=0
WARNINGS=0
SUCCESS=0

# Function to print validation result
validate_item() {
    local description=$1
    local condition=$2
    local type=${3:-"error"}  # error, warning, or info
    
    echo -n "🔍 $description: "
    
    if eval "$condition"; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((SUCCESS++))
        return 0
    else
        if [ "$type" = "warning" ]; then
            echo -e "${YELLOW}⚠️  WARNING${NC}"
            ((WARNINGS++))
        else
            echo -e "${RED}❌ FAIL${NC}"
            ((ERRORS++))
        fi
        return 1
    fi
}

# Function to validate file exists
file_exists() {
    [ -f "$1" ]
}

# Function to validate directory exists
dir_exists() {
    [ -d "$1" ]
}

# Function to validate file contains pattern
file_contains() {
    local file=$1
    local pattern=$2
    [ -f "$file" ] && grep -q "$pattern" "$file"
}

echo -e "\n${YELLOW}📁 Repository Structure Validation${NC}"
echo "=================================="

# Check main repositories exist
validate_item "Infrastructure repository exists" "dir_exists 'association-platform-infrastructure'"
validate_item "Backend APIs repository exists" "dir_exists 'association-platform-backend-apis'"
validate_item "BFF Services repository exists" "dir_exists 'association-platform-bff-services'"
validate_item "Frontend Apps repository exists" "dir_exists 'association-platform-frontend-apps'"

echo -e "\n${YELLOW}🏗️ Infrastructure Repository Validation${NC}"
echo "======================================="

if [ -d "association-platform-infrastructure" ]; then
    cd association-platform-infrastructure
    
    validate_item "Infrastructure Docker Compose exists" "file_exists 'docker-compose.infrastructure.yml'"
    validate_item "Infrastructure setup script exists" "file_exists 'scripts/setup-dev.sh'"
    validate_item "Infrastructure README exists" "file_exists 'README.md'"
    validate_item "Environment template exists" "file_exists '.env'"
    validate_item "Traefik configuration directory exists" "dir_exists 'infrastructure'"
    
    # Check Docker Compose structure
    if [ -f "docker-compose.infrastructure.yml" ]; then
        validate_item "PostgreSQL service defined" "file_contains 'docker-compose.infrastructure.yml' 'postgres:'"
        validate_item "Redis service defined" "file_contains 'docker-compose.infrastructure.yml' 'redis:'"
        validate_item "RabbitMQ service defined" "file_contains 'docker-compose.infrastructure.yml' 'rabbitmq:'"
        validate_item "Keycloak service defined" "file_contains 'docker-compose.infrastructure.yml' 'keycloak:'"
        validate_item "Traefik service defined" "file_contains 'docker-compose.infrastructure.yml' 'traefik:'"
    fi
    
    cd ..
fi

echo -e "\n${YELLOW}🔧 Backend APIs Repository Validation${NC}"
echo "===================================="

if [ -d "association-platform-backend-apis" ]; then
    cd association-platform-backend-apis
    
    validate_item "Backend APIs Docker Compose exists" "file_exists 'docker-compose.apis.yml'"
    validate_item "Platform API directory exists" "dir_exists 'platform-api'"
    validate_item "Operator API directory exists" "dir_exists 'operator-api'"
    validate_item "Shared directory exists" "dir_exists 'shared'"
    validate_item "Backend APIs README exists" "file_exists 'README.md'"
    
    # Check shared components
    validate_item "Shared entities directory exists" "dir_exists 'shared/entities'"
    validate_item "Shared services directory exists" "dir_exists 'shared/services'"
    validate_item "Association entity exists" "file_exists 'shared/entities/Association.php'"
    validate_item "API Response service exists" "file_exists 'shared/services/ApiResponseService.php'"
    
    # Check Docker Compose structure
    if [ -f "docker-compose.apis.yml" ]; then
        validate_item "Platform API service defined" "file_contains 'docker-compose.apis.yml' 'platform-api:'"
        validate_item "Operator API service defined" "file_contains 'docker-compose.apis.yml' 'operator-api:'"
        validate_item "External network referenced" "file_contains 'docker-compose.apis.yml' 'association-platform_default'"
    fi
    
    cd ..
fi

echo -e "\n${YELLOW}🌐 BFF Services Repository Validation${NC}"
echo "===================================="

if [ -d "association-platform-bff-services" ]; then
    cd association-platform-bff-services
    
    validate_item "BFF Services Docker Compose exists" "file_exists 'docker-compose.bff.yml'"
    validate_item "BFF Services package.json exists" "file_exists 'package.json'"
    validate_item "Platform BFF directory exists" "dir_exists 'platform-bff'"
    validate_item "Operator BFF directory exists" "dir_exists 'operator-bff'"
    validate_item "Association BFF directory exists" "dir_exists 'association-bff'"
    validate_item "Shared directory exists" "dir_exists 'shared'"
    
    # Check shared components
    validate_item "Shared types directory exists" "dir_exists 'shared/types'"
    validate_item "Shared services directory exists" "dir_exists 'shared/services'"
    validate_item "API response types exist" "file_exists 'shared/types/api-responses.ts'"
    validate_item "HTTP client service exists" "file_exists 'shared/services/http-client.service.ts'"
    
    # Check package.json structure
    if [ -f "package.json" ]; then
        validate_item "Workspace configuration exists" "file_contains 'package.json' 'workspaces'"
        validate_item "NestJS dependencies exist" "file_contains 'package.json' '@nestjs/common'"
        validate_item "Development scripts exist" "file_contains 'package.json' 'start:dev'"
    fi
    
    cd ..
fi

echo -e "\n${YELLOW}💻 Frontend Apps Repository Validation${NC}"
echo "===================================="

if [ -d "association-platform-frontend-apps" ]; then
    cd association-platform-frontend-apps
    
    validate_item "Frontend Apps Docker Compose exists" "file_exists 'docker-compose.frontend.yml'"
    validate_item "Frontend Apps package.json exists" "file_exists 'package.json'"
    validate_item "Member Portal directory exists" "dir_exists 'member-portal'"
    validate_item "Operator Dashboard directory exists" "dir_exists 'operator-dashboard'"
    validate_item "Association Dashboard directory exists" "dir_exists 'association-dashboard'"
    validate_item "Shared directory exists" "dir_exists 'shared'"
    
    # Check shared components
    validate_item "Shared components directory exists" "dir_exists 'shared/components'"
    validate_item "Shared hooks directory exists" "dir_exists 'shared/hooks'"
    validate_item "Layout component exists" "file_exists 'shared/components/Layout.tsx'"
    validate_item "API hook exists" "file_exists 'shared/hooks/useApi.ts'"
    
    # Check package.json structure
    if [ -f "package.json" ]; then
        validate_item "Workspace configuration exists" "file_contains 'package.json' 'workspaces'"
        validate_item "Next.js dependencies exist" "file_contains 'package.json' 'next'"
        validate_item "React dependencies exist" "file_contains 'package.json' 'react'"
    fi
    
    cd ..
fi

echo -e "\n${YELLOW}🔗 Inter-Repository Configuration Validation${NC}"
echo "==========================================="

# Check main configuration files
validate_item "Main environment file exists" "file_exists '.env'"
validate_item "Environment template exists" "file_exists '.env.template'"
validate_item "Main README exists" "file_exists 'README.md'"
validate_item "Setup script exists" "file_exists 'setup-all.sh'"
validate_item "Start script exists" "file_exists 'start-all.sh'"
validate_item "Stop script exists" "file_exists 'stop-all.sh'"
validate_item "Health check script exists" "file_exists 'health-check.sh'"
validate_item "Config sync script exists" "file_exists 'sync-configs.sh'"

# Check environment file content
if [ -f ".env" ]; then
    validate_item "PostgreSQL configuration in .env" "file_contains '.env' 'POSTGRES_DB'"
    validate_item "Redis configuration in .env" "file_contains '.env' 'REDIS_PASSWORD'"
    validate_item "API ports configured in .env" "file_contains '.env' 'PLATFORM_API_PORT'"
    validate_item "BFF ports configured in .env" "file_contains '.env' 'PLATFORM_BFF_PORT'"
    validate_item "Frontend ports configured in .env" "file_contains '.env' 'MEMBER_PORTAL_PORT'"
fi

# Check script permissions
validate_item "Setup script is executable" "[ -x 'setup-all.sh' ]"
validate_item "Start script is executable" "[ -x 'start-all.sh' ]"
validate_item "Stop script is executable" "[ -x 'stop-all.sh' ]"
validate_item "Health check script is executable" "[ -x 'health-check.sh' ]"
validate_item "Config sync script is executable" "[ -x 'sync-configs.sh' ]"

echo -e "\n${YELLOW}🧪 Test Configuration Validation${NC}"
echo "==============================="

validate_item "Test Docker Compose exists" "file_exists 'docker-compose.test.yml'"

if [ -f "docker-compose.test.yml" ]; then
    validate_item "Test PostgreSQL service defined" "file_contains 'docker-compose.test.yml' 'postgres-test:'"
    validate_item "Test Redis service defined" "file_contains 'docker-compose.test.yml' 'redis-test:'"
    validate_item "Test network defined" "file_contains 'docker-compose.test.yml' 'test-network'"
fi

# Git repository initialization check
echo -e "\n${YELLOW}📝 Git Repository Validation${NC}"
echo "============================="

for repo in association-platform-*; do
    if [ -d "$repo" ]; then
        validate_item "$repo has git repository" "[ -d '$repo/.git' ]"
    fi
done

echo -e "\n${YELLOW}📋 File Structure Completeness${NC}"
echo "============================="

# Count important files
total_repos=$(find . -maxdepth 1 -name "association-platform-*" -type d | wc -l)
total_dockerfiles=$(find . -name "docker-compose*.yml" | wc -l)
total_readmes=$(find . -name "README.md" | wc -l)
total_package_jsons=$(find . -name "package.json" | wc -l)

echo "📊 Structure Summary:"
echo "   • Repositories: $total_repos/4"
echo "   • Docker Compose files: $total_dockerfiles"
echo "   • README files: $total_readmes"  
echo "   • Package.json files: $total_package_jsons"

echo -e "\n${BLUE}🎯 Validation Summary${NC}"
echo "==================="
echo -e "${GREEN}✅ Passed: $SUCCESS${NC}"
echo -e "${YELLOW}⚠️  Warnings: $WARNINGS${NC}"
echo -e "${RED}❌ Errors: $ERRORS${NC}"

if [ $ERRORS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 Multi-Repository structure validation PASSED! 🎉${NC}"
    echo -e "${GREEN}The Association Platform is properly organized and ready for development.${NC}"
    
    if [ $WARNINGS -gt 0 ]; then
        echo -e "\n${YELLOW}⚠️  There are $WARNINGS warnings that should be addressed for optimal setup.${NC}"
    fi
    
    echo -e "\n${BLUE}📋 Next Steps:${NC}"
    echo "1. Install Docker and Docker Compose on your system"
    echo "2. Run './start-all.sh' to start all services"
    echo "3. Run './health-check.sh' to verify everything works"
    echo "4. Begin development in individual repositories"
    
    exit 0
else
    echo -e "\n${RED}❌ Multi-Repository structure validation FAILED!${NC}"
    echo -e "${RED}Please fix the $ERRORS errors before proceeding.${NC}"
    
    echo -e "\n${YELLOW}💡 Common fixes:${NC}"
    echo "• Run './sync-configs.sh' to fix configuration issues"
    echo "• Check that all required files were created properly"
    echo "• Verify directory structure matches the expected layout"
    
    exit 1
fi
