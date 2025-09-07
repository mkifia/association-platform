# Guide de Migration : Monorepo vers Multi-Repository

## 🎯 **Vue d'ensemble**

Ce guide détaille la migration du monorepo actuel vers une architecture multi-repository pour une meilleure scalabilité et une gestion d'équipe optimisée.

## 📊 **État Actuel vs État Cible**

### **AVANT : Monorepo Structure**
```
association-platform/
├── backend/
│   ├── operator-api/         # Symfony
│   └── platform-api/         # Symfony
├── bff/
│   ├── operator-bff/         # NestJS
│   ├── platform-bff/         # NestJS
│   └── association-bff/      # NestJS
├── web/
│   ├── member-portal/        # Next.js
│   ├── operator-dashboard/   # Next.js
│   └── association-dashboard/ # Next.js
├── docker-compose.yml
├── traefik/
└── docs/
```

### **APRÈS : Multi-Repository Structure**
```
association-platform-infrastructure/
├── docker-compose*.yml
├── traefik/
├── scripts/
└── docs/

association-platform-backend-apis/
├── operator-api/
├── platform-api/
└── shared/

association-platform-bff-services/
├── operator-bff/
├── platform-bff/
├── association-bff/
└── shared/

association-platform-frontend-apps/
├── member-portal/
├── operator-dashboard/
├── association-dashboard/
└── shared/

association-platform-releases/
├── releases/
└── scripts/
```

## 🚀 **Plan de Migration**

### **Phase 1: Préparation (1-2 jours)**

#### 1.1 **Analyse des Dépendances**
```bash
# Identifier les fichiers partagés
find . -name "*.shared.*" -o -name "common*" -o -name "utils*"

# Analyser les imports inter-services
grep -r "import.*\.\./\.\." --include="*.ts" --include="*.js"

# Détecter les configurations communes
find . -name "docker-compose*" -o -name "*.env*" -o -name "traefik*"
```

#### 1.2 **Documentation des Interfaces**
```bash
# Backend APIs endpoints
./scripts/document-apis.sh > API-INTERFACES.md

# BFF contracts
./scripts/document-bff-contracts.sh > BFF-INTERFACES.md

# Frontend API calls  
./scripts/document-frontend-apis.sh > FRONTEND-APIS.md
```

#### 1.3 **Tests de Régression**
```bash
# Créer suite de tests complète avant migration
./scripts/create-migration-tests.sh

# Baseline performance
./scripts/benchmark-current-setup.sh > BASELINE-METRICS.md
```

### **Phase 2: Création des Repositories (2-3 jours)**

#### 2.1 **Setup GitLab/GitHub Organization**
```bash
# Créer groupe/organisation "association-platform"
# Configurer permissions et accès équipes
# Setup CI/CD runners et variables
```

#### 2.2 **Repository Infrastructure**
```bash
# 1. Créer repository
git init association-platform-infrastructure
cd association-platform-infrastructure

# 2. Extraire fichiers infrastructure
git subtree split --prefix=docker-compose.yml -b infra-branch
git subtree split --prefix=traefik/ -b traefik-branch  

# 3. Structure finale
mkdir -p scripts docs
cp ../docker-compose*.yml .
cp -r ../traefik/ .
cp -r ../docs/infrastructure/ ./docs/

# 4. Créer scripts utilitaires
cat > scripts/setup-dev.sh << 'EOF'
#!/bin/bash
echo "Setting up development environment..."
cp .env.example .env
docker network create association-platform_default 2>/dev/null || true
echo "✅ Infrastructure setup complete"
EOF

chmod +x scripts/*.sh
```

#### 2.3 **Repository Backend APIs**
```bash
git init association-platform-backend-apis
cd association-platform-backend-apis

# Extraire services backend
mkdir -p operator-api platform-api shared

# Copier code Symfony
cp -r ../backend/operator-api/ ./operator-api/
cp -r ../backend/platform-api/ ./platform-api/

# Créer dossier shared pour code commun
mkdir -p shared/{entities,services,utils}

# Docker compose spécifique aux APIs
cat > docker-compose.apis.yml << 'EOF'
version: '3.8'
services:
  operator-api:
    build: ./operator-api
    ports:
      - "8001:80"
    environment:
      - DATABASE_URL=postgresql://user:password@postgres:5432/operator_db
    depends_on:
      - postgres

  platform-api:
    build: ./platform-api  
    ports:
      - "8000:80"
    environment:
      - DATABASE_URL=postgresql://user:password@postgres:5432/platform_db
    depends_on:
      - postgres

  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: association_platform
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
EOF
```

#### 2.4 **Repository BFF Services**
```bash
git init association-platform-bff-services
cd association-platform-bff-services

# Structure BFF
mkdir -p platform-bff operator-bff association-bff shared

# Copier services NestJS
cp -r ../bff/platform-bff/ ./platform-bff/
cp -r ../bff/operator-bff/ ./operator-bff/  
cp -r ../bff/association-bff/ ./association-bff/

# Shared types et utils
mkdir -p shared/{types,utils,middlewares}

# Types partagés
cat > shared/types/api-responses.ts << 'EOF'
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  metadata?: {
    total?: number;
    page?: number;
    limit?: number;
  };
}

export interface Association {
  id: string;
  name: string;
  description?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Member {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  associationId: string;
}
EOF

# Configuration partagée
cat > shared/utils/http-client.ts << 'EOF'
import axios, { AxiosInstance, AxiosRequestConfig } from 'axios';

export class HttpClient {
  private client: AxiosInstance;

  constructor(baseURL: string) {
    this.client = axios.create({
      baseURL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });
  }

  async get<T>(url: string, config?: AxiosRequestConfig): Promise<T> {
    const response = await this.client.get(url, config);
    return response.data;
  }

  async post<T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T> {
    const response = await this.client.post(url, data, config);
    return response.data;
  }
}
EOF
```

#### 2.5 **Repository Frontend Apps**
```bash
git init association-platform-frontend-apps  
cd association-platform-frontend-apps

# Structure frontend
mkdir -p member-portal operator-dashboard association-dashboard shared

# Copier applications Next.js
cp -r ../web/member-portal/ ./member-portal/
cp -r ../web/operator-dashboard/ ./operator-dashboard/
cp -r ../web/association-dashboard/ ./association-dashboard/

# Shared UI components
mkdir -p shared/{components,hooks,utils,types}

# Composants partagés
cat > shared/components/Layout.tsx << 'EOF'
import React from 'react';
import { Header } from './Header';
import { Sidebar } from './Sidebar';

interface LayoutProps {
  children: React.ReactNode;
  title?: string;
  showSidebar?: boolean;
}

export const Layout: React.FC<LayoutProps> = ({ 
  children, 
  title = 'Association Platform',
  showSidebar = true 
}) => {
  return (
    <div className="min-h-screen bg-gray-50">
      <Header title={title} />
      <div className="flex">
        {showSidebar && <Sidebar />}
        <main className="flex-1 p-6">
          {children}
        </main>
      </div>
    </div>
  );
};
EOF

# Hooks partagés
cat > shared/hooks/useApi.ts << 'EOF'
import { useState, useEffect } from 'react';
import { useQuery, useMutation, QueryClient } from '@tanstack/react-query';

export const useApi = (baseUrl: string) => {
  const queryClient = new QueryClient();

  const get = <T>(endpoint: string) => 
    useQuery<T>({
      queryKey: [endpoint],
      queryFn: () => fetch(`${baseUrl}${endpoint}`).then(res => res.json()),
    });

  const post = <T>(endpoint: string) =>
    useMutation<T, Error, any>({
      mutationFn: (data) =>
        fetch(`${baseUrl}${endpoint}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(data),
        }).then(res => res.json()),
    });

  return { get, post, queryClient };
};
EOF
```

### **Phase 3: Migration des Services (3-4 jours)**

#### 3.1 **Script de Migration Automatisée**
```bash
#!/bin/bash
# migrate-services.sh

set -e

# Configuration
GITLAB_GROUP="association-platform"
REPOS=("infrastructure" "backend-apis" "bff-services" "frontend-apps" "releases")

echo "🚀 Starting migration to multi-repository..."

# 1. Créer repositories distants
for repo in "${REPOS[@]}"; do
    echo "📁 Creating repository: $repo"
    
    # GitLab API pour créer le projet
    curl --request POST \
         --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
         --header "Content-Type: application/json" \
         --data "{
             \"name\": \"association-platform-$repo\",
             \"namespace_id\": \"$GITLAB_GROUP_ID\",
             \"visibility\": \"private\",
             \"description\": \"Association Platform - $repo component\"
         }" \
         "$GITLAB_API_URL/projects"
done

# 2. Migration des fichiers
echo "📦 Migrating files..."

# Infrastructure
cd association-platform-infrastructure
git add .
git commit -m "feat: initial infrastructure setup"
git remote add origin $GITLAB_URL/association-platform/association-platform-infrastructure.git
git push -u origin main

# Backend APIs  
cd ../association-platform-backend-apis
git add .
git commit -m "feat: initial backend APIs setup"
git remote add origin $GITLAB_URL/association-platform/association-platform-backend-apis.git
git push -u origin main

# BFF Services
cd ../association-platform-bff-services  
git add .
git commit -m "feat: initial BFF services setup"
git remote add origin $GITLAB_URL/association-platform/association-platform-bff-services.git
git push -u origin main

# Frontend Apps
cd ../association-platform-frontend-apps
git add .
git commit -m "feat: initial frontend apps setup"  
git remote add origin $GITLAB_URL/association-platform/association-platform-frontend-apps.git
git push -u origin main

echo "✅ Migration complete!"
```

#### 3.2 **Update des Configurations**

##### **Backend APIs - Mise à jour composer.json**
```bash
# Dans chaque API backend
cd operator-api
cat > composer.json << 'EOF'
{
    "name": "association-platform/operator-api",
    "description": "Association Platform - Operator Management API",
    "type": "project",
    "license": "MIT",
    "require": {
        "php": ">=8.1",
        "symfony/framework-bundle": "^7.0",
        "doctrine/orm": "^3.0",
        "association-platform/shared": "^1.0"
    },
    "repositories": [
        {
            "type": "path",
            "url": "../shared"
        }
    ],
    "autoload": {
        "psr-4": {
            "App\\": "src/"
        }
    }
}
EOF
```

##### **BFF Services - package.json updates**
```bash
# Dans chaque service BFF
cd platform-bff
cat > package.json << 'EOF'
{
  "name": "@association-platform/platform-bff",
  "version": "1.4.2",
  "description": "Association Platform - Platform BFF Service",
  "main": "dist/main.js",
  "scripts": {
    "build": "nest build",
    "start": "node dist/main",
    "start:dev": "nest start --watch",
    "test": "jest",
    "lint": "eslint \"{src,apps,libs,test}/**/*.ts\""
  },
  "dependencies": {
    "@nestjs/common": "^10.0.0",
    "@nestjs/core": "^10.0.0",
    "@association-platform/bff-shared": "file:../shared"
  },
  "devDependencies": {
    "@nestjs/cli": "^10.0.0",
    "typescript": "^5.0.0"
  }
}
EOF
```

##### **Frontend Apps - package.json updates**
```bash
# Dans chaque app frontend
cd member-portal
cat > package.json << 'EOF'
{
  "name": "@association-platform/member-portal",
  "version": "3.0.1",
  "description": "Association Platform - Member Portal",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "14.0.0",
    "react": "^18.0.0",
    "@association-platform/frontend-shared": "file:../shared"
  }
}
EOF
```

### **Phase 4: Configuration CI/CD (2-3 jours)**

#### 4.1 **Pipeline Infrastructure (.gitlab-ci.yml)**
```yaml
stages:
  - validate
  - build
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"

validate_compose:
  stage: validate
  image: docker/compose:latest
  script:
    - docker-compose config
    - echo "✅ Docker Compose configuration is valid"
  only:
    - merge_requests
    - main

deploy_infrastructure:
  stage: deploy
  image: alpine:latest
  before_script:
    - apk add --no-cache openssh-client rsync
    - eval $(ssh-agent -s)
    - echo "$DEPLOY_SSH_KEY" | tr -d '\r' | ssh-add -
  script:
    - rsync -avz --exclude='.git' ./ deploy@$SERVER_HOST:/opt/association-platform/
    - ssh deploy@$SERVER_HOST "cd /opt/association-platform && docker-compose up -d --build"
  only:
    - main
  when: manual
```

#### 4.2 **Pipeline Backend APIs**
```yaml
stages:
  - test
  - security
  - build
  - deploy

test_operator_api:
  stage: test
  image: php:8.2-cli
  before_script:
    - apt-get update && apt-get install -y git unzip
    - curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
  script:
    - cd operator-api
    - composer install --prefer-dist --no-progress
    - php bin/phpunit --coverage-text
  coverage: '/^\s*Lines:\s*\d+.\d+\%/'

security_check:
  stage: security  
  image: php:8.2-cli
  script:
    - cd operator-api
    - composer audit
    - cd ../platform-api  
    - composer audit

build_images:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $CI_REGISTRY_IMAGE/operator-api:$CI_COMMIT_SHA ./operator-api
    - docker build -t $CI_REGISTRY_IMAGE/platform-api:$CI_COMMIT_SHA ./platform-api
    - docker push $CI_REGISTRY_IMAGE/operator-api:$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE/platform-api:$CI_COMMIT_SHA
  only:
    - main
```

#### 4.3 **Pipeline BFF Services**
```yaml
stages:
  - lint
  - test
  - build
  - deploy

lint:
  stage: lint
  image: node:18
  script:
    - npm ci
    - npm run lint:platform-bff
    - npm run lint:operator-bff
    - npm run lint:association-bff
  cache:
    key: $CI_COMMIT_REF_SLUG
    paths:
      - node_modules/

test:
  stage: test
  image: node:18
  script:
    - npm ci
    - npm run test:platform-bff
    - npm run test:operator-bff  
    - npm run test:association-bff
  coverage: '/All files[^|]*\|[^|]*\s+([\d\.]+)/'

build_images:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  parallel:
    matrix:
      - SERVICE: platform-bff
      - SERVICE: operator-bff
      - SERVICE: association-bff
  script:
    - docker build -t $CI_REGISTRY_IMAGE/$SERVICE:$CI_COMMIT_SHA ./$SERVICE
    - docker push $CI_REGISTRY_IMAGE/$SERVICE:$CI_COMMIT_SHA
  only:
    - main
```

### **Phase 5: Tests et Validation (2-3 jours)**

#### 5.1 **Tests d'Intégration Inter-Services**
```bash
#!/bin/bash
# test-integration.sh

echo "🧪 Starting integration tests..."

# 1. Démarrer tous les services
docker-compose -f infrastructure/docker-compose.full.yml up -d

# 2. Attendre que tous les services soient prêts  
./scripts/wait-for-services.sh

# 3. Tests API Backend
echo "Testing Backend APIs..."
curl -f http://localhost:8000/api/health || exit 1
curl -f http://localhost:8001/api/health || exit 1

# 4. Tests BFF Services
echo "Testing BFF Services..."
curl -f http://localhost:3001/health || exit 1
curl -f http://localhost:3002/health || exit 1
curl -f http://localhost:3003/health || exit 1

# 5. Tests Frontend Apps
echo "Testing Frontend Apps..."
curl -f http://localhost:3000/ || exit 1
curl -f http://localhost:3100/ || exit 1  
curl -f http://localhost:3200/ || exit 1

# 6. Tests de bout en bout
echo "Testing end-to-end workflows..."
./tests/e2e/member-registration.sh
./tests/e2e/association-management.sh
./tests/e2e/operator-dashboard.sh

echo "✅ All integration tests passed!"
```

#### 5.2 **Script de Validation Performance**
```bash
#!/bin/bash
# performance-validation.sh

echo "📊 Performance validation..."

# Benchmark avant migration (baseline)
BASELINE_FILE="BASELINE-METRICS.md"

# Tests de charge
echo "Load testing..."
ab -n 1000 -c 10 http://localhost:3001/api/associations > load-test-bff.log
ab -n 1000 -c 10 http://localhost:8000/api/associations > load-test-api.log

# Métriques Docker
echo "Docker metrics..."
docker stats --no-stream > docker-metrics.log

# Comparaison avec baseline
./scripts/compare-metrics.sh $BASELINE_FILE

echo "✅ Performance validation complete"
```

### **Phase 6: Documentation et Formation (1-2 jours)**

#### 6.1 **Documentation Développeurs**
```bash
# Créer documentation complète pour chaque repo
cat > DEVELOPER-GUIDE.md << 'EOF'
# Guide Développeur - Multi-Repository

## 🛠️ Setup Développement Local

### 1. Clonage des Repositories
```bash
mkdir association-platform && cd association-platform

# Cloner tous les repositories
git clone git@gitlab.com:association-platform/infrastructure.git
git clone git@gitlab.com:association-platform/backend-apis.git  
git clone git@gitlab.com:association-platform/bff-services.git
git clone git@gitlab.com:association-platform/frontend-apps.git
```

### 2. Configuration Environnement
```bash
cd infrastructure
./scripts/setup-dev.sh

# Variables d'environnement
cp .env.example .env
```

### 3. Démarrage Services
```bash  
# Infrastructure
docker-compose up -d postgres redis rabbitmq keycloak

# Backend APIs
cd ../backend-apis
docker-compose -f docker-compose.apis.yml up -d

# BFF Services  
cd ../bff-services
npm run start:all:dev

# Frontend Apps
cd ../frontend-apps  
npm run dev:all
```

## 📝 Workflow de Développement

### Nouvelle Feature Cross-Services
1. Créer branches dans repositories concernés
2. Développer en parallèle avec interfaces stables
3. Tests d'intégration locaux
4. PR/MR dans chaque repository
5. Tests d'intégration automatisés
6. Merge coordonné

### Hotfix Critique
1. Créer hotfix branch dans repository concerné
2. Fix + tests
3. Release emergency
4. Déploiement immédiat
5. Backport si nécessaire

## 🧪 Tests

### Locaux
```bash
# Tests unitaires
npm run test

# Tests d'intégration
./scripts/test-integration-local.sh
```

### CI/CD
- Tests automatiques sur chaque PR/MR
- Tests inter-services sur merge vers develop
- Tests complets avant release
EOF
```

#### 6.2 **Formation Équipe**
```markdown
# Session Formation - Migration Multi-Repository

## 📅 Planning Formation (4h)

### 1h - Présentation Architecture (30min + 30min Q&A)
- Pourquoi multi-repository ?
- Nouvelle structure
- Impacts sur workflow quotidien

### 1h - Hands-on Setup (45min + 15min)
- Clone et configuration
- Premier développement
- Tests locaux

### 1h - Workflow Git (45min + 15min)  
- Branches strategy
- PR/MR process
- Hotfix workflow

### 1h - CI/CD & Déploiements (45min + 15min)
- Pipelines par repository
- Release coordination
- Monitoring multi-services

## 📋 Checklist Post-Formation
- [ ] Chaque dev a cloné tous les repos
- [ ] Environment de dev fonctionnel  
- [ ] Premier commit dans nouveau workflow
- [ ] Tests d'intégration réussis
```

### **Phase 7: Go-Live et Monitoring (1 jour)**

#### 7.1 **Switch Production**
```bash
#!/bin/bash
# production-switch.sh

echo "🚀 Switching to multi-repository production..."

# 1. Backup current state
./scripts/backup-current-production.sh

# 2. Deploy new infrastructure
cd infrastructure
docker-compose -f docker-compose.prod.yml up -d

# 3. Deploy services in order
cd ../backend-apis
./scripts/deploy-production.sh

cd ../bff-services  
./scripts/deploy-production.sh

cd ../frontend-apps
./scripts/deploy-production.sh

# 4. Health checks
./scripts/production-health-check.sh

# 5. Smoke tests
./scripts/production-smoke-tests.sh

echo "✅ Production switch complete!"
```

#### 7.2 **Monitoring Multi-Repository**
```bash
#!/bin/bash
# monitoring-setup.sh

# Dashboard services status
cat > scripts/services-status.sh << 'EOF'
#!/bin/bash

echo "📊 Services Status Dashboard"
echo "==========================="

services=("infrastructure" "backend-apis" "bff-services" "frontend-apps")

for service in "${services[@]}"; do
    echo "🔍 $service:"
    
    # Version déployée
    version=$(curl -s http://$service.local/version 2>/dev/null || echo "N/A")
    echo "  Version: $version"
    
    # Health status
    health=$(curl -s http://$service.local/health 2>/dev/null | jq -r '.status' 2>/dev/null || echo "DOWN")
    if [ "$health" = "OK" ]; then
        echo "  Status: ✅ $health"
    else
        echo "  Status: ❌ $health"  
    fi
    
    echo ""
done
EOF

chmod +x scripts/services-status.sh
```

## 📋 **Checklist de Migration**

### **Pré-Migration**
- [ ] Backup complet du monorepo actuel
- [ ] Tests de régression baseline 
- [ ] Documentation interfaces actuelles
- [ ] Plan de rollback défini
- [ ] Équipe formée sur nouveau workflow

### **Pendant Migration**
- [ ] Repositories créés et configurés
- [ ] Code migré avec historique Git préservé
- [ ] Shared libraries configurées
- [ ] CI/CD pipelines opérationnels  
- [ ] Tests d'intégration validés

### **Post-Migration**  
- [ ] Production switchée avec succès
- [ ] Monitoring multi-services actif
- [ ] Documentation développeurs à jour
- [ ] Équipe autonome sur nouveau workflow
- [ ] Métriques performance validées

### **Rollback Plan** 
- [ ] Backup infrastructure accessible
- [ ] Script de retour au monorepo
- [ ] Plan de communication équipe
- [ ] Timeline de rollback < 4h

## 🎯 **Métriques de Succès**

### **Techniques**
- Performance ≥ baseline monorepo
- Temps de build par service réduit de 60%
- Tests d'intégration < 10 minutes
- Zero downtime pendant migration

### **Équipe**
- 100% des développeurs formés
- Nouveau workflow adopté en < 1 semaine  
- Satisfaction équipe ≥ 8/10
- Productivité maintenue post-migration

### **Business**
- Zero impact utilisateur final
- CI/CD deployment time réduit de 50%
- Capacité de release indépendante par service
- Scalabilité équipe améliorée

Cette migration vous permettra d'avoir une architecture moderne, scalable et adaptée à la croissance de votre équipe ! 🚀
