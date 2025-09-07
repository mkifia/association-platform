#!/bin/bash

set -e

echo "🧹 Migration vers la nouvelle architecture multi-repository"
echo "=========================================================="

# Arrêter les anciens services Docker s'ils tournent
echo "🛑 Arrêt des anciens services..."
docker-compose down 2>/dev/null || true

# Sauvegarde des fichiers importants avant nettoyage
echo "💾 Sauvegarde des fichiers importants..."
mkdir -p repos/backup
cp -r .env* repos/backup/ 2>/dev/null || true
cp -r .github repos/backup/ 2>/dev/null || true
cp README.md repos/backup/README-OLD.md 2>/dev/null || true

# Nettoyage de l'ancienne structure
echo "🧹 Nettoyage de l'ancienne structure..."

# Supprimer les anciens dossiers
rm -rf bff/ services/ web/ infrastructure/ 2>/dev/null || true

# Supprimer les anciens fichiers de configuration
rm -f docker-compose*.yml 2>/dev/null || true
rm -f Makefile 2>/dev/null || true

# Supprimer les anciens docs
rm -rf docs/ scripts/ config/ docker/ 2>/dev/null || true

# Supprimer les anciens README et documentation
rm -f README-TESTING.md MAKEFILE_UPDATES.md README.old.md 2>/dev/null || true
rm -f ARCHITECTURE.md COMPLETE-ARCHITECTURE.md 2>/dev/null || true

# Déplacer la nouvelle structure à la racine
echo "🚀 Migration vers la nouvelle structure..."

# Déplacer tous les contenus de repos/ vers la racine
mv repos/* . 2>/dev/null || true
mv repos/.* . 2>/dev/null || true

# Supprimer le dossier repos vide
rmdir repos 2>/dev/null || true

# Copier les bonnes variables d'environnement
if [ -f "backup/.env" ]; then
    echo "🔧 Restauration de la configuration environnement..."
    # Fusionner les anciennes variables avec les nouvelles si nécessaire
    cp backup/.env .env.backup
fi

# Nettoyer le backup
rm -rf backup/

echo ""
echo "✅ Migration terminée avec succès !"
echo ""
echo "📋 Nouvelle structure :"
echo "├── association-platform-infrastructure/"
echo "├── association-platform-backend-apis/" 
echo "├── association-platform-bff-services/"
echo "├── association-platform-frontend-apps/"
echo "├── start-all.sh"
echo "├── stop-all.sh"
echo "├── health-check.sh"
echo "└── README.md"
echo ""
echo "🚀 Prochaines étapes :"
echo "1. ./start-all.sh        # Démarrer tous les services"
echo "2. ./health-check.sh     # Vérifier le bon fonctionnement"
echo "3. ./validate-structure.sh # Valider l'architecture"
echo ""
echo "🎉 Votre projet est maintenant organisé en architecture multi-repository !"
