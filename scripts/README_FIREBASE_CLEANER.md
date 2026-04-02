# 🧹 Script Intelligent de Nettoyage Firebase

Ce script analyse intelligemment tous les produits de ta collection Firebase `gifts` et complète automatiquement les champs manquants en scrapant les URLs.

## 📋 Prérequis

### 1. Télécharger le Service Account Key Firebase

1. Va sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionne ton projet **doron-b3011**
3. Va dans **⚙️ Paramètres du projet** (en haut à gauche)
4. Onglet **Comptes de service**
5. Clique sur **Générer une nouvelle clé privée**
6. Télécharge le fichier JSON
7. Renomme-le en `firebase-credentials.json`
8. Place-le dans le dossier `scripts/`

### 2. Installer les dépendances Python

```bash
cd scripts/
pip3 install -r requirements.txt
```

## 🚀 Utilisation

### Lancer le nettoyage complet

```bash
python3 intelligent_firebase_cleaner.py
```

Le script va :
- ✅ Analyser tous les produits de la collection `gifts`
- 🔍 Détecter les champs manquants (nom, prix, image, brand, etc.)
- 🌐 Scraper intelligemment les URLs Amazon pour récupérer les infos
- 💾 Mettre à jour Firebase avec les données complètes
- 📊 Afficher un rapport détaillé

## 🎯 Ce que le script vérifie et corrige

### Champs vérifiés :
- **name** / **product_title** - Nom du produit
- **brand** - Marque
- **price** / **product_price** - Prix
- **image** / **product_photo** - URL de l'image
- **description** - Description
- **categories** - Catégories (array)
- **tags** - Tags (array)
- **source** - Source (Amazon, etc.)

### Intelligence du script :
1. **Scraping intelligent** - Utilise plusieurs sélecteurs pour trouver les infos
2. **Génération de tags** - Crée automatiquement des tags (homme/femme/enfant, tech, mode, etc.)
3. **Extraction de catégories** - Récupère les catégories depuis le breadcrumb Amazon
4. **Gestion des erreurs** - Continue même si un produit échoue
5. **Rate limiting** - Pause entre chaque requête pour éviter les blocages

## 📊 Exemple de sortie

```
🧹 NETTOYAGE INTELLIGENT DE LA BASE FIREBASE
============================================================

📖 Lecture de tous les produits...
   Total: 350 produits

🔍 Analyse des produits...

[1/350] Produit ABC123
   ⚠️  Champs manquants: name, price, image
   🌐 Scraping: https://amazon.fr/dp/B0ABC123...
   ✅ Scraped: Montre connectée Samsung Galaxy Watch
   ✅ Mis à jour: name, price, image, brand, tags

[2/350] Produit XYZ456
   ✅ Complet

...

============================================================
📊 RÉSUMÉ
============================================================
Total produits:      350
Incomplets:          87
Corrigés:            82
Erreurs:             3
Skippés:             2
Taux de succès:      94.3%

✨ Nettoyage terminé!
```

## ⚠️ Notes importantes

1. Le script fait une pause de **3 secondes** entre chaque produit pour éviter d'être bloqué
2. Temps estimé : ~5-6 minutes pour 100 produits
3. Le script peut être interrompu avec Ctrl+C et repris plus tard
4. Les produits déjà complets sont skippés automatiquement

## 🛠️ Dépannage

### Erreur "Failed to initialize app"
→ Vérifie que `firebase-credentials.json` est bien dans le dossier `scripts/`

### Erreur "requests.exceptions.HTTPError: 503"
→ Amazon bloque temporairement, attends 5-10 minutes et relance

### Erreur "ModuleNotFoundError"
→ Installe les dépendances : `pip3 install -r requirements.txt`
