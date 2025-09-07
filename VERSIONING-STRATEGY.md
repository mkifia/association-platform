# Stratégie de Versioning - Association Platform

## 🏗️ **Multi-Repository Strategy (Recommandé)**

### 📁 **Repositories Structure**

#### 1. **association-platform-infrastructure**
```
├── docker-compose*.yml
├── traefik/
├── docs/
├── .env.example
├── README.md
└── scripts/
    ├── setup.sh
    ├── deploy.sh
    └── backup.sh
```
- **Version**: `v1.0.0` (infrastructure stable)
- **Déclencheurs**: Changements d'infrastructure, ajout de services

#### 2. **association-platform-backend-apis** 
```
├── operator-api/          # Symfony API
├── platform-api/          # Symfony API  
├── shared/                # Code partagé (entités communes)
├── docker-compose.apis.yml
└── README.md
```
- **Version**: `v2.1.3` (APIs métier)
- **Déclencheurs**: Nouvelles features API, corrections bugs

#### 3. **association-platform-bff-services**
```
├── platform-bff/          # NestJS BFF
├── operator-bff/           # NestJS BFF
├── association-bff/        # NestJS BFF
├── shared/                 # Types communs, utils
├── docker-compose.bff.yml
└── README.md
```
- **Version**: `v1.4.2` (BFF Services)
- **Déclencheurs**: Nouvelles features BFF, optimisations

#### 4. **association-platform-frontend-apps**
```
├── member-portal/          # Next.js App
├── operator-dashboard/     # Next.js App
├── association-dashboard/  # Next.js App
├── shared/                 # Composants UI communs
├── docker-compose.frontend.yml
└── README.md
```
- **Version**: `v3.0.1` (Frontend Applications)
- **Déclencheurs**: Nouvelles features UI, améliorations UX

#### 5. **association-platform-releases**
```
├── releases/
│   ├── v1.0.0/
│   │   ├── release-notes.md
│   │   ├── compatibility-matrix.md
│   │   └── docker-compose.full.yml
│   └── v1.1.0/
├── scripts/
│   ├── release.sh
│   └── deploy-env.sh
└── README.md
```
- **Version**: `v1.1.0` (Release globale)
- **Déclencheurs**: Release majeure, coordination services

## 🏷️ **Semantic Versioning par Service**

### **Backend APIs**
```bash
v2.1.3
│ │ └── Patch: Bug fixes, sécurité
│ └──── Minor: Nouvelles API endpoints, features
└────── Major: Breaking changes, architecture

Exemples:
v2.0.0 - Nouvelle architecture multi-tenant
v2.1.0 - Ajout API contributions
v2.1.1 - Fix sécurité JWT
```

### **BFF Services**
```bash
v1.4.2
│ │ └── Patch: Corrections, optimisations
│ └──── Minor: Nouveaux endpoints, middlewares
└────── Major: Breaking changes contrat API

Exemples:
v1.0.0 - BFF initial
v1.4.0 - Nouveau module dashboard
v1.4.2 - Fix CORS configuration
```

### **Frontend Apps**
```bash
v3.0.1
│ │ └── Patch: Bug fixes UI, performance
│ └──── Minor: Nouvelles features, composants
└────── Major: Refonte UI, breaking changes

Exemples:
v3.0.0 - Migration vers Next.js 14
v3.0.1 - Fix responsive design
```

## 🔄 **Git Flow par Repository**

### **Branches Strategy**
```
main/master          # Production stable
├── develop          # Intégration continue
├── feature/*        # Nouvelles fonctionnalités
│   ├── feature/member-crud
│   └── feature/event-management
├── hotfix/*         # Corrections critiques
└── release/*        # Préparation releases
```

### **Workflow Example**
```bash
# Nouvelle feature
git checkout develop
git checkout -b feature/member-dashboard
# ... développement
git push origin feature/member-dashboard
# PR/MR vers develop

# Release
git checkout -b release/v1.4.0 develop
# ... tests, corrections
git checkout main
git merge release/v1.4.0
git tag v1.4.0
```

## 🚀 **CI/CD Pipeline par Repository**

### **1. Backend APIs Pipeline (.gitlab-ci.yml)**
```yaml
stages:
  - test
  - security
  - build
  - deploy

variables:
  IMAGE_TAG: $CI_COMMIT_REF_SLUG-$CI_COMMIT_SHORT_SHA

test:
  stage: test
  script:
    - composer install
    - php bin/phpunit
  only:
    - merge_requests
    - develop

security:
  stage: security
  script:
    - symfony security:check
  only:
    - merge_requests

build:
  stage: build
  script:
    - docker build -t $CI_REGISTRY_IMAGE/operator-api:$IMAGE_TAG ./operator-api
    - docker build -t $CI_REGISTRY_IMAGE/platform-api:$IMAGE_TAG ./platform-api
    - docker push $CI_REGISTRY_IMAGE/operator-api:$IMAGE_TAG
    - docker push $CI_REGISTRY_IMAGE/platform-api:$IMAGE_TAG
  only:
    - main
    - develop

deploy_staging:
  stage: deploy
  script:
    - ./scripts/deploy-staging.sh $IMAGE_TAG
  only:
    - develop

deploy_production:
  stage: deploy
  script:
    - ./scripts/deploy-production.sh $IMAGE_TAG
  only:
    - main
  when: manual
```

### **2. Frontend Apps Pipeline**
```yaml
stages:
  - test
  - build
  - deploy

test:
  stage: test
  script:
    - npm ci
    - npm run lint
    - npm run type-check
    - npm run test
  only:
    - merge_requests

build:
  stage: build
  script:
    - npm run build
    - docker build -t $CI_REGISTRY_IMAGE/member-portal:$IMAGE_TAG ./member-portal
    - docker build -t $CI_REGISTRY_IMAGE/operator-dashboard:$IMAGE_TAG ./operator-dashboard
    - docker build -t $CI_REGISTRY_IMAGE/association-dashboard:$IMAGE_TAG ./association-dashboard
  only:
    - main
```

## 📋 **Compatibility Matrix**

### **Services Compatibility (v1.1.0)**
| Service | Version | Compatible With |
|---------|---------|-----------------|
| Infrastructure | v1.0.0 | All services |
| Backend APIs | v2.1.3 | BFF v1.4.x, Frontend v3.0.x |
| BFF Services | v1.4.2 | Backend v2.1.x, Frontend v3.0.x |
| Frontend Apps | v3.0.1 | BFF v1.4.x |

### **Breaking Changes Matrix**
```yaml
v2.0.0: # Backend APIs Major
  breaking_changes:
    - Authentication endpoints changed
    - JSON schema updates
  affected_services:
    - BFF Services: requires v1.3.0+
    - Frontend Apps: requires v2.8.0+
```

## 🏅 **Release Management**

### **Global Release Process**
1. **Planning Phase**
   ```bash
   # Créer milestone dans GitLab/GitHub
   # Identifier services impactés
   # Définir matrice de compatibilité
   ```

2. **Development Phase**
   ```bash
   # Feature branches dans chaque repo
   # Tests d'intégration inter-services
   # Validation compatibility matrix
   ```

3. **Release Phase**
   ```bash
   # Tag chaque service
   # Créer release notes globales
   # Déploiement coordonné
   # Smoke tests complets
   ```

### **Release Notes Template**
```markdown
# Association Platform v1.1.0

## 🚀 New Features
- Association Dashboard: Member management interface
- Platform BFF: New contribution endpoints
- Infrastructure: Traefik v3 migration

## 🐛 Bug Fixes
- Fixed CORS issues in all BFF services
- Resolved Docker volumes synchronization

## 🔧 Technical Updates
- Updated Node.js to v18 in all frontends
- Symfony 7.3.3 security patches

## 📋 Compatibility
- Requires Infrastructure v1.0.0+
- Backend APIs v2.1.3 compatible
- All frontend apps updated to v3.0.1

## 🔄 Migration Guide
1. Update infrastructure: `git pull infrastructure`
2. Restart services: `docker compose up --build`
3. Run migrations: `./scripts/migrate-v1.1.0.sh`

## 🧪 Testing
- [ ] Member Portal functionality
- [ ] Association Dashboard features  
- [ ] Operator Dashboard admin functions
- [ ] Cross-service integration
```

## 🛠️ **Development Workflow**

### **Inter-Service Development**
```bash
# 1. Setup développement local
git clone git@gitlab.com:association-platform/infrastructure.git
git clone git@gitlab.com:association-platform/backend-apis.git
git clone git@gitlab.com:association-platform/bff-services.git
git clone git@gitlab.com:association-platform/frontend-apps.git

# 2. Configuration environnement
cd infrastructure
./scripts/setup-dev.sh

# 3. Lancement services
docker compose -f docker-compose.dev.yml up
```

### **Testing Inter-Services**
```bash
# Tests d'intégration
./scripts/test-integration.sh

# Tests end-to-end
./scripts/test-e2e.sh

# Tests performance
./scripts/test-performance.sh
```

## 📊 **Monitoring & Metrics**

### **Version Tracking Dashboard**
```yaml
services:
  - name: operator-api
    current_version: "v2.1.3"
    target_version: "v2.2.0"
    status: "in_development"
    
  - name: platform-api  
    current_version: "v2.1.3"
    target_version: "v2.1.4"
    status: "stable"
```

### **Deployment Tracking**
```bash
# Script de monitoring des versions déployées
./scripts/version-status.sh

Output:
Production Environment:
- Infrastructure: v1.0.0 ✅
- Backend APIs: v2.1.3 ✅  
- BFF Services: v1.4.2 ✅
- Frontend Apps: v3.0.1 ✅

Staging Environment:
- Infrastructure: v1.0.1 🚧
- Backend APIs: v2.2.0-rc1 🧪
- BFF Services: v1.5.0-beta 🧪  
- Frontend Apps: v3.1.0-alpha 🧪
```

## 🎯 **Best Practices**

### **Commit Messages Convention**
```bash
# Format: <type>(<scope>): <description>
feat(member-portal): add contribution tracking interface
fix(platform-bff): resolve CORS policy issue  
refactor(operator-api): optimize database queries
docs(readme): update installation instructions
```

### **Tag Naming Convention**
```bash
# Services individuels
backend-apis/v2.1.3
bff-services/v1.4.2
frontend-apps/v3.0.1

# Release globale
platform/v1.1.0
```

### **Hotfix Process**
```bash
# Hotfix critique sur production
git checkout main
git checkout -b hotfix/security-fix
# ... fix
git checkout main
git merge hotfix/security-fix
git tag v2.1.4
# Déploiement immédiat
```

Cette stratégie permet une gestion professionnelle et scalable du versioning pour votre architecture microservices complexe ! 🚀
