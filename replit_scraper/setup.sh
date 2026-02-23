#!/bin/bash
# 🚀 Script d'installation automatique pour Replit

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                                                                   ║"
echo "║              🎁 DORON SCRAPER - INSTALLATION 🎁                   ║"
echo "║                                                                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

# Vérifier Python
echo "🐍 Vérification de Python..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 n'est pas installé!"
    exit 1
fi
PYTHON_VERSION=$(python3 --version)
echo "✅ $PYTHON_VERSION trouvé"
echo ""

# Installer les dépendances Python
echo "📦 Installation des dépendances Python..."
pip install -q -r requirements_advanced.txt
if [ $? -eq 0 ]; then
    echo "✅ Dépendances Python installées"
else
    echo "❌ Erreur installation dépendances Python"
    exit 1
fi
echo ""

# Installer Playwright
echo "🎭 Installation de Playwright..."
pip install -q playwright
if [ $? -eq 0 ]; then
    echo "✅ Playwright installé"
else
    echo "❌ Erreur installation Playwright"
    exit 1
fi
echo ""

# Installer Chromium pour Playwright
echo "🌐 Installation de Chromium (peut prendre 2-3 minutes)..."
playwright install chromium
if [ $? -eq 0 ]; then
    echo "✅ Chromium installé"
else
    echo "❌ Erreur installation Chromium"
    exit 1
fi
echo ""

# Vérifier serviceAccountKey.json
echo "🔑 Vérification de serviceAccountKey.json..."
if [ -f "serviceAccountKey.json" ]; then
    echo "✅ serviceAccountKey.json trouvé"
else
    echo "⚠️  serviceAccountKey.json NON TROUVÉ"
    echo ""
    echo "📋 Pour continuer:"
    echo "   1. Allez sur https://console.firebase.google.com/"
    echo "   2. Projet 'doron-b3011' → Paramètres → Comptes de service"
    echo "   3. Générez une nouvelle clé privée"
    echo "   4. Uploadez le fichier JSON et renommez-le 'serviceAccountKey.json'"
    echo ""
fi
echo ""

# Vérifier links.csv
echo "📄 Vérification de links.csv..."
if [ -f "links.csv" ]; then
    echo "✅ links.csv trouvé"
    LINE_COUNT=$(wc -l < links.csv)
    echo "   → $LINE_COUNT lignes"
else
    echo "⚠️  links.csv NON TROUVÉ"
    echo ""
    echo "📋 Créez links.csv avec ce format:"
    echo "   url,brand,category"
    echo "   https://www.amazon.fr/dp/B08N5WRWNW,Golden Goose,chaussures"
    echo ""
fi
echo ""

# Tester Firebase
if [ -f "serviceAccountKey.json" ]; then
    echo "🔥 Test de connexion Firebase..."
    python3 test_firebase.py
    if [ $? -eq 0 ]; then
        echo ""
        echo "╔═══════════════════════════════════════════════════════════════════╗"
        echo "║                                                                   ║"
        echo "║                  ✅ INSTALLATION RÉUSSIE ! ✅                      ║"
        echo "║                                                                   ║"
        echo "║  Vous pouvez maintenant lancer le script:                        ║"
        echo "║                                                                   ║"
        echo "║      python3 main_advanced.py                                     ║"
        echo "║                                                                   ║"
        echo "╚═══════════════════════════════════════════════════════════════════╝"
        echo ""
    else
        echo ""
        echo "⚠️  Test Firebase échoué - Vérifiez serviceAccountKey.json"
    fi
else
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                                                                   ║"
    echo "║              ⚠️  INSTALLATION PARTIELLEMENT RÉUSSIE              ║"
    echo "║                                                                   ║"
    echo "║  Dépendances installées, mais fichiers manquants:                ║"
    echo "║                                                                   ║"
    echo "║  - serviceAccountKey.json (OBLIGATOIRE)                           ║"
    echo "║  - links.csv (OBLIGATOIRE pour scraping)                          ║"
    echo "║                                                                   ║"
    echo "║  Consultez QUICKSTART.md pour les instructions.                  ║"
    echo "║                                                                   ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo ""
fi
