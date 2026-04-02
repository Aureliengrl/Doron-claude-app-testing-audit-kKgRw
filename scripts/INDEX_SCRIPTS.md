# 📚 Index des Scripts - Projet DORON

## 🆕 NOUVEAUX SCRIPTS (Nettoyage Firebase)

### 🚀 Scripts principaux

| Script | Description | Usage |
|--------|-------------|-------|
| `setup_and_run.sh` | **Setup automatique** - Installe tout et lance le nettoyage | `./setup_and_run.sh` |
| `intelligent_firebase_cleaner.py` | **Nettoyage intelligent** - Analyse et répare tous les produits | `python3 intelligent_firebase_cleaner.py` |
| `analyze_only.py` | **Analyse seulement** - Affiche un rapport sans modifier | `python3 analyze_only.py` |

### 📖 Documentation

| Fichier | Contenu |
|---------|---------|
| `QUICK_START.md` | ⚡ Guide rapide en 3 étapes |
| `README_FIREBASE_CLEANER.md` | 📖 Documentation complète |
| `requirements.txt` | 📦 Dépendances Python |

---

## 🎯 Workflow recommandé

### Option 1 : Setup automatique (recommandé)
```bash
cd scripts/
./setup_and_run.sh
```
Le script fait tout pour toi !

### Option 2 : Manuel

1. **Analyser d'abord**
```bash
python3 analyze_only.py
```
→ Affiche un rapport détaillé sans rien modifier

2. **Nettoyer ensuite**
```bash
python3 intelligent_firebase_cleaner.py
```
→ Répare tous les produits incomplets

---

## 🛠️ Scripts existants (anciens)

### Génération de produits
- `generate_real_products.py` - Génère des produits réels
- `generate_all_brands.py` - Génère pour toutes les marques
- `mega_real_database.py` - Mega base de données
- `final_real_products.py` - Version finale

### Scraping
- `real_scraper.py` - Scraper de base
- `advanced_real_scraper.py` - Scraper avancé
- `ultimate_scraper.py` - Scraper ultime
- `scrape_and_generate.py` - Scrape + génération

### Firebase
- `upload_real_products_to_firebase.py` - Upload vers Firebase
- `upload_with_correct_fields.py` - Upload avec bons champs
- `convert_and_upload.js` - Conversion JS + upload
- `delete_all_products.js` - Supprime tous les produits

### Utilitaires
- `fix_product_images.py` - Corrige les images
- `transform_for_flutter.js` - Transformation pour Flutter

---

## ❓ Quel script utiliser ?

### Tu veux nettoyer ta base Firebase ?
→ `./setup_and_run.sh` ✅

### Tu veux juste voir l'état de ta base ?
→ `python3 analyze_only.py` 📊

### Tu veux ajouter de nouveaux produits ?
→ Utilise les anciens scripts de génération

---

## 🆘 Problème ?

1. Lis `QUICK_START.md` pour le guide rapide
2. Lis `README_FIREBASE_CLEANER.md` pour le guide complet
3. Vérifie que `firebase-credentials.json` est bien placé

---

## 📝 Notes importantes

- **Temps de nettoyage** : ~5-6 min pour 100 produits
- **Pause entre produits** : 3 secondes (évite les blocages)
- **Interruption** : Ctrl+C pour arrêter, relance plus tard
- **Credentials** : Télécharge depuis Firebase Console

---

✨ **Astuce** : Commence par `analyze_only.py` pour voir l'état de ta base avant de nettoyer !
