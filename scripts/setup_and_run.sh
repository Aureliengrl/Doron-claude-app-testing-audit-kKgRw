#!/bin/bash

# Script de setup et lancement du nettoyage Firebase

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "   🧹 SETUP NETTOYAGE INTELLIGENT FIREBASE"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Vérifier si on est dans le bon dossier
if [ ! -f "intelligent_firebase_cleaner.py" ]; then
    echo "❌ Erreur: Lance ce script depuis le dossier scripts/"
    echo "   cd scripts/"
    echo "   ./setup_and_run.sh"
    exit 1
fi

# Vérifier Python
echo "🔍 Vérification de Python..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 n'est pas installé"
    exit 1
fi
echo "✅ Python 3 trouvé: $(python3 --version)"
echo ""

# Vérifier les credentials Firebase
if [ ! -f "firebase-credentials.json" ]; then
    echo "⚠️  Le fichier firebase-credentials.json est manquant"
    echo ""
    echo "📋 Pour le télécharger:"
    echo "   1. Va sur https://console.firebase.google.com/"
    echo "   2. Sélectionne le projet 'doron-b3011'"
    echo "   3. Paramètres > Comptes de service"
    echo "   4. Clique 'Générer une nouvelle clé privée'"
    echo "   5. Renomme le fichier en 'firebase-credentials.json'"
    echo "   6. Place-le dans le dossier scripts/"
    echo ""
    read -p "Appuie sur Entrée une fois que c'est fait..."

    if [ ! -f "firebase-credentials.json" ]; then
        echo "❌ Fichier toujours manquant, arrêt."
        exit 1
    fi
fi
echo "✅ Credentials Firebase trouvés"
echo ""

# Installer les dépendances
echo "📦 Installation des dépendances Python..."
pip3 install -r requirements.txt -q

if [ $? -ne 0 ]; then
    echo "❌ Erreur lors de l'installation des dépendances"
    exit 1
fi
echo "✅ Dépendances installées"
echo ""

# Confirmer le lancement
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🚀 Prêt à lancer le nettoyage!"
echo ""
echo "Le script va:"
echo "  • Analyser tous les produits de Firebase"
echo "  • Détecter les champs manquants"
echo "  • Scraper les URLs pour compléter les infos"
echo "  • Mettre à jour Firebase"
echo ""
echo "⏱️  Temps estimé: ~5-6 min pour 100 produits"
echo ""
read -p "Continuer? (o/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Oo]$ ]]; then
    echo "❌ Annulé"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Lancer le script
python3 intelligent_firebase_cleaner.py

echo ""
echo "✨ Terminé!"
echo ""
