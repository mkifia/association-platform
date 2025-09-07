# Association Platform - Main Makefile
# Multi-repository development commands

.DEFAULT_GOAL := help
.PHONY: help setup start stop restart status health logs clean test lint format build deploy

# Colors for output
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
BLUE := \033[34m
RESET := \033[0m

## Show this help message
help:
	@echo "$(BLUE)Association Platform - Development Commands$(RESET)"
	@echo "=============================================="
	@echo ""
	@echo "$(GREEN)Setup & Installation:$(RESET)"
	@echo "  setup           Setup entire platform (first time)"
	@echo "  install         Install dependencies for all services"
	@echo ""
	@echo "$(GREEN)Service Management:$(RESET)"
	@echo "  start           Start all services"
	@echo "  stop            Stop all services"
	@echo "  restart         Restart all services"
	@echo "  status          Show running services status"
	@echo "  health          Check health of all services"
	@echo ""
	@echo "$(GREEN)Development:$(RESET)"
	@echo "  logs            Show logs from all services"
	@echo "  logs-follow     Follow logs from all services"
	@echo "  shell-api       Open shell in platform API container"
	@echo "  shell-operator  Open shell in operator API container"
	@echo ""
	@echo "$(GREEN)Testing & Quality:$(RESET)"
	@echo "  test            Run tests for all services"
	@echo "  test-api        Run backend API tests"
	@echo "  test-bff        Run BFF service tests"
	@echo "  test-frontend   Run frontend tests"
	@echo "  lint            Run linting for all services"
	@echo "  format          Format code for all services"
	@echo ""
	@echo "$(GREEN)Database & Cache:$(RESET)"
	@echo "  db-migrate      Run database migrations"
	@echo "  db-fixtures     Load database fixtures"
	@echo "  cache-clear     Clear all caches"
	@echo "  profiler-clean  Clean profiler cache files"
	@echo ""
	@echo "$(GREEN)Build & Deploy:$(RESET)"
	@echo "  build           Build all Docker images"
	@echo "  clean           Clean up Docker resources"
	@echo "  reset           Complete reset (stop, clean, start)"
	@echo ""

## Setup entire platform (first time)
setup:
	@echo "$(GREEN)🚀 Setting up Association Platform...$(RESET)"
	./setup-all.sh

## Install dependencies for all services
install:
	@echo "$(GREEN)📦 Installing dependencies...$(RESET)"
	@cd association-platform-backend-apis && $(MAKE) install
	@cd association-platform-bff-services && npm run install:all
	@cd association-platform-frontend-apps && npm run install:all

## Start all services
start:
	@echo "$(GREEN)▶️  Starting all services...$(RESET)"
	./start-all.sh

## Stop all services
stop:
	@echo "$(RED)⏹️  Stopping all services...$(RESET)"
	./stop-all.sh

## Restart all services
restart:
	@echo "$(YELLOW)🔄 Restarting all services...$(RESET)"
	@$(MAKE) stop
	@$(MAKE) start

## Show running services status
status:
	@echo "$(BLUE)📊 Service Status:$(RESET)"
	@echo ""
	@echo "$(YELLOW)Infrastructure:$(RESET)"
	@cd association-platform-infrastructure && docker-compose -f docker-compose.infrastructure.yml ps
	@echo ""
	@echo "$(YELLOW)Backend APIs:$(RESET)"
	@cd association-platform-backend-apis && docker-compose -f docker-compose.apis.yml ps
	@echo ""
	@echo "$(YELLOW)BFF Services:$(RESET)"
	@cd association-platform-bff-services && docker-compose -f docker-compose.bff.yml ps
	@echo ""
	@echo "$(YELLOW)Frontend Apps:$(RESET)"
	@cd association-platform-frontend-apps && docker-compose -f docker-compose.frontend.yml ps

## Check health of all services
health:
	@echo "$(GREEN)🏥 Running health checks...$(RESET)"
	./health-check.sh

## Show logs from all services
logs:
	@echo "$(BLUE)📋 Recent logs from all services:$(RESET)"
	@cd association-platform-infrastructure && docker-compose -f docker-compose.infrastructure.yml logs --tail=50
	@cd association-platform-backend-apis && docker-compose -f docker-compose.apis.yml logs --tail=50
	@cd association-platform-bff-services && docker-compose -f docker-compose.bff.yml logs --tail=50
	@cd association-platform-frontend-apps && docker-compose -f docker-compose.frontend.yml logs --tail=50

## Follow logs from all services
logs-follow:
	@echo "$(BLUE)📋 Following logs from all services...$(RESET)"
	@echo "$(YELLOW)Press Ctrl+C to stop$(RESET)"
	@cd association-platform-infrastructure && docker-compose -f docker-compose.infrastructure.yml logs -f &
	@cd association-platform-backend-apis && docker-compose -f docker-compose.apis.yml logs -f &
	@cd association-platform-bff-services && docker-compose -f docker-compose.bff.yml logs -f &
	@cd association-platform-frontend-apps && docker-compose -f docker-compose.frontend.yml logs -f &
	@wait

## Open shell in platform API container
shell-api:
	@echo "$(GREEN)🐚 Opening shell in Platform API...$(RESET)"
	@cd association-platform-backend-apis && docker-compose -f docker-compose.apis.yml exec platform-api bash

## Open shell in operator API container
shell-operator:
	@echo "$(GREEN)🐚 Opening shell in Operator API...$(RESET)"
	@cd association-platform-backend-apis && docker-compose -f docker-compose.apis.yml exec operator-api bash

## Run tests for all services
test:
	@echo "$(GREEN)🧪 Running tests for all services...$(RESET)"
	@$(MAKE) test-api
	@$(MAKE) test-bff
	@$(MAKE) test-frontend

## Run backend API tests
test-api:
	@echo "$(GREEN)🧪 Running backend API tests...$(RESET)"
	@cd association-platform-backend-apis && $(MAKE) test

## Run BFF service tests
test-bff:
	@echo "$(GREEN)🧪 Running BFF service tests...$(RESET)"
	@cd association-platform-bff-services && npm run test

## Run frontend tests
test-frontend:
	@echo "$(GREEN)🧪 Running frontend tests...$(RESET)"
	@cd association-platform-frontend-apps && npm run test

## Run linting for all services
lint:
	@echo "$(GREEN)🔍 Running linting for all services...$(RESET)"
	@cd association-platform-backend-apis && $(MAKE) lint
	@cd association-platform-bff-services && npm run lint
	@cd association-platform-frontend-apps && npm run lint

## Format code for all services
format:
	@echo "$(GREEN)✨ Formatting code for all services...$(RESET)"
	@cd association-platform-backend-apis && $(MAKE) format
	@cd association-platform-bff-services && npm run format
	@cd association-platform-frontend-apps && npm run format || true

## Run database migrations
db-migrate:
	@echo "$(GREEN)🗄️  Running database migrations...$(RESET)"
	@cd association-platform-backend-apis && $(MAKE) db-migrate

## Load database fixtures
db-fixtures:
	@echo "$(GREEN)📊 Loading database fixtures...$(RESET)"
	@cd association-platform-backend-apis && $(MAKE) db-fixtures

## Clear all caches
cache-clear:
	@echo "$(GREEN)🧹 Clearing all caches...$(RESET)"
	@cd association-platform-backend-apis && $(MAKE) cache-clear
	@cd association-platform-bff-services && npm run clean || true
	@cd association-platform-frontend-apps && npm run clean || true

## Clean profiler cache files
profiler-clean:
	@echo "$(GREEN)🧹 Cleaning profiler cache...$(RESET)"
	@cd association-platform-backend-apis && ./cleanup-profiler.sh

## Build all Docker images
build:
	@echo "$(GREEN)🔨 Building all Docker images...$(RESET)"
	@cd association-platform-infrastructure && docker-compose -f docker-compose.infrastructure.yml build
	@cd association-platform-backend-apis && docker-compose -f docker-compose.apis.yml build
	@cd association-platform-bff-services && docker-compose -f docker-compose.bff.yml build
	@cd association-platform-frontend-apps && docker-compose -f docker-compose.frontend.yml build

## Clean up Docker resources
clean:
	@echo "$(YELLOW)🧽 Cleaning up Docker resources...$(RESET)"
	docker system prune -f
	docker volume prune -f

## Complete reset (stop, clean, start)
reset:
	@echo "$(RED)🔄 Performing complete platform reset...$(RESET)"
	@$(MAKE) stop
	@$(MAKE) clean
	@$(MAKE) start

## Development shortcuts
dev-api:
	@echo "$(GREEN)🚀 Starting API development mode...$(RESET)"
	@cd association-platform-infrastructure && docker-compose -f docker-compose.infrastructure.yml up -d
	@cd association-platform-backend-apis && docker-compose -f docker-compose.apis.yml up -d

dev-bff:
	@echo "$(GREEN)🚀 Starting BFF development mode...$(RESET)"
	@$(MAKE) dev-api
	@cd association-platform-bff-services && npm run start:dev

dev-frontend:
	@echo "$(GREEN)🚀 Starting Frontend development mode...$(RESET)"
	@$(MAKE) dev-api
	@$(MAKE) dev-bff &
	@cd association-platform-frontend-apps && npm run dev

## Quick development commands
dev: dev-api
	@echo "$(GREEN)✅ Development environment ready!$(RESET)"
	@echo ""
	@echo "$(BLUE)Access URLs:$(RESET)"
	@echo "  • Platform API:     http://localhost:8000/api"
	@echo "  • Operator API:     http://localhost:8001/api"
	@echo "  • API Profiler:     http://localhost:8000/_profiler"
	@echo "  • Traefik Dashboard: http://localhost:8080"
	@echo "  • Database Admin:   http://localhost:8081"
