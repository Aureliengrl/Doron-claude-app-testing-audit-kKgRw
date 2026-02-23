# 📁 Vue d'ensemble des fichiers

Voici tous les fichiers du système de scraping DORON.

## 🎯 Fichiers Principaux

### `main_advanced.py` ⭐ NOUVEAU & RECOMMANDÉ
**Script ultra-robuste avec anti-détection maximale**

✨ **Fonctionnalités** :
- Anti-détection Playwright (meilleur que Selenium)
- User Agents rotatifs + JavaScript injection
- Nettoyage automatique de Firebase
- Support Amazon (extensible)
- Génération automatique de tags
- Détection des doublons
- Statistiques complètes

🚀 **Utilisation** :
```bash
python main_advanced.py
```

---

### `main.py`
**Script original avec Selenium**

✅ **Avantages** :
- Selenium plus simple à utiliser
- BeautifulSoup pour parsing HTML
- Tags et catégories auto-générés

⚠️ **Inconvénients** :
- Moins d'anti-détection
- Pas de nettoyage automatique
- Plus facile à détecter par les sites

🚀 **Utilisation** :
```bash
python main.py
```

---

### `main_simple.py`
**Version simplifiée (legacy)**

Pour débuter ou tester rapidement.

---

## 🔧 Fichiers de Configuration

### `requirements_advanced.txt` ⭐
**Dépendances pour main_advanced.py**
```
playwright==1.41.0
firebase-admin==6.4.0
beautifulsoup4==4.12.3
```

### `requirements.txt`
**Dépendances pour main.py**
```
firebase-admin==6.4.0
selenium==4.15.2
beautifulsoup4==4.12.3
```

### `requirements_simple.txt`
**Dépendances pour main_simple.py**

---

## 📊 Fichiers de Données

### `links.csv` ⭐ OBLIGATOIRE
**Liste des URLs à scraper**

Format :
```csv
url,brand,category
https://www.amazon.fr/dp/B08N5WRWNW,Golden Goose,chaussures
https://www.amazon.fr/dp/B0C9KJK8TN,Zara,vetements
```

Colonnes :
- `url` (obligatoire) : URL du produit
- `brand` (optionnel) : Marque (auto-détectée si vide)
- `category` (optionnel) : Catégorie (auto-détectée si vide)

### `links_example.csv`
**Exemple de fichier CSV**

Copiez ce fichier en `links.csv` et ajoutez vos URLs.

---

## 🔑 Fichier Secret

### `serviceAccountKey.json` ⭐ OBLIGATOIRE
**Credentials Firebase**

⚠️ **IMPORTANT** :
- À télécharger depuis Firebase Console
- Ne JAMAIS commit sur Git
- Garder secret

**Comment l'obtenir** :
1. [Firebase Console](https://console.firebase.google.com/)
2. Projet `doron-b3011`
3. Paramètres → Comptes de service
4. Générer une nouvelle clé privée
5. Télécharger et renommer en `serviceAccountKey.json`

---

## 📚 Documentation

### `README_ADVANCED.md` ⭐
**Guide complet pour main_advanced.py**

Contient :
- Installation détaillée
- Fonctionnalités
- Configuration avancée
- Troubleshooting
- Exemples de code

### `QUICKSTART.md` ⭐
**Guide de démarrage rapide (5 minutes)**

Pour lancer le script rapidement sans lire toute la doc.

### `README_REPLIT.md`
**Guide original (legacy)**

Documentation de l'ancien système.

### `GUIDE_ULTRA_RAPIDE.md`
**Guide ultra-rapide (legacy)**

### `GUIDE_TRANSFORMATION_TAGS.md`
**Guide de transformation des tags**

Explique comment les tags sont transformés et utilisés.

### `FILES_OVERVIEW.md` 📄 (ce fichier)
**Vue d'ensemble de tous les fichiers**

---

## 🛠️ Scripts Utilitaires

### `test_firebase.py` ⭐
**Teste la connexion Firebase**

🚀 **Utilisation** :
```bash
python test_firebase.py
```

✅ **Affiche** :
- Status de connexion
- Collections disponibles
- Nombre de produits
- Exemple de produit

### `setup.sh` ⭐
**Script d'installation automatique**

🚀 **Utilisation** :
```bash
bash setup.sh
```

✅ **Actions** :
- Installe toutes les dépendances
- Installe Playwright + Chromium
- Vérifie serviceAccountKey.json
- Vérifie links.csv
- Teste Firebase

### `transform_tags.py`
**Transforme les tags existants (legacy)**

Pour mettre à jour les tags de produits déjà en base.

---

## 🗂️ Structure Recommandée

```
replit_scraper/
├── 📄 main_advanced.py          ⭐ UTILISEZ CELUI-CI
├── 📄 requirements_advanced.txt ⭐
├── 📄 setup.sh                  ⭐ Pour installer
├── 📄 test_firebase.py          ⭐ Pour tester
│
├── 🔑 serviceAccountKey.json    ⭐ OBLIGATOIRE (à créer)
├── 📊 links.csv                 ⭐ OBLIGATOIRE (à créer)
│
├── 📚 README_ADVANCED.md        ⭐ Doc complète
├── 📚 QUICKSTART.md             ⭐ Démarrage rapide
├── 📚 FILES_OVERVIEW.md         📄 (ce fichier)
│
├── 📄 links_example.csv         (exemple)
├── 📄 main.py                   (legacy)
├── 📄 main_simple.py            (legacy)
└── ... (autres fichiers legacy)
```

---

## 🎯 Quel fichier utiliser ?

### Pour scraper des produits :

**Recommandé** : `main_advanced.py`
- Anti-détection maximale
- Nettoyage automatique
- Le plus robuste

**Alternative** : `main.py`
- Plus simple
- Moins de dépendances
- Mais moins robuste

### Pour installer :

**Recommandé** : `setup.sh`
```bash
bash setup.sh
```

**Manuel** :
```bash
pip install -r requirements_advanced.txt
playwright install chromium
```

### Pour tester :

```bash
python test_firebase.py
```

### Pour la doc :

- Débutant : `QUICKSTART.md`
- Détails : `README_ADVANCED.md`
- Overview : `FILES_OVERVIEW.md` (ce fichier)

---

## 📊 Workflow Complet

1. **Installation** :
   ```bash
   bash setup.sh
   ```

2. **Créer serviceAccountKey.json** :
   - Télécharger depuis Firebase Console
   - Placer à la racine

3. **Créer links.csv** :
   - Copier `links_example.csv`
   - Ajouter vos URLs

4. **Tester Firebase** :
   ```bash
   python test_firebase.py
   ```

5. **Lancer le scraping** :
   ```bash
   python main_advanced.py
   # → Option 3 (nettoyer + scraper)
   ```

6. **Vérifier dans Firebase** :
   - Console Firebase → Collection `gifts`
   - Vérifier les nouveaux produits

7. **Automatiser** (optionnel) :
   - Relancer régulièrement (quotidien/hebdomadaire)
   - Maintient la base propre et à jour

---

## ⚡ Commandes Rapides

```bash
# Installation complète
bash setup.sh

# Test Firebase
python test_firebase.py

# Nettoyer uniquement
python main_advanced.py  # → option 1

# Scraper uniquement
python main_advanced.py  # → option 2

# Les deux (recommandé)
python main_advanced.py  # → option 3

# Version legacy (Selenium)
python main.py
```

---

## 🔄 Maintenance

### Quotidienne / Hebdomadaire

```bash
python main_advanced.py  # → option 3
```

Cela :
1. Nettoie la base (supprime produits incomplets)
2. Scrape les nouveaux produits
3. Met à jour les tags automatiquement

### Mensuelle

- Mettre à jour `links.csv` avec de nouvelles URLs
- Vérifier les sélecteurs (sites peuvent changer)
- Mettre à jour les dépendances :
  ```bash
  pip install --upgrade -r requirements_advanced.txt
  ```

---

## 🆘 Support

En cas de problème :

1. **Consultez** :
   - `QUICKSTART.md` (démarrage rapide)
   - `README_ADVANCED.md` (doc complète)
   - Section "Troubleshooting" dans README

2. **Testez** :
   ```bash
   python test_firebase.py
   ```

3. **Vérifiez** :
   - serviceAccountKey.json présent
   - links.csv formaté correctement
   - Dépendances installées

4. **Logs** :
   - Le script affiche des logs détaillés
   - Regardez les messages d'erreur

---

✨ **Tous les fichiers sont prêts pour Replit !**
