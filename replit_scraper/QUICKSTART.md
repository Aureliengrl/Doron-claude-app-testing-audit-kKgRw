# 🚀 Quick Start - Démarrage Rapide

Guide ultra-rapide pour lancer le scraper en 5 minutes.

## ⚡ En 5 minutes

### 1. Setup Replit (2 min)

```bash
# Installer les dépendances
pip install -r requirements_advanced.txt

# Installer Playwright + Chromium
playwright install chromium
```

### 2. Préparer les fichiers (1 min)

**A. Firebase credentials**
- Téléchargez `serviceAccountKey.json` depuis [Firebase Console](https://console.firebase.google.com/)
- Uploadez-le à la racine de votre Repl

**B. Liste d'URLs**
- Créez `links.csv` avec vos URLs :
```csv
url,brand,category
https://www.amazon.fr/dp/B08N5WRWNW,Golden Goose,chaussures
https://www.amazon.fr/dp/B0C9KJK8TN,Zara,vetements
```

### 3. Tester Firebase (30 sec)

```bash
python test_firebase.py
```

Si vous voyez "✅ TEST RÉUSSI" → C'est bon !

### 4. Lancer le script (1 min)

```bash
python main_advanced.py
```

Choisissez l'option **3** (nettoyer + scraper).

### 5. Vérifier dans Firebase (30 sec)

Allez dans [Firebase Console](https://console.firebase.google.com/) → Collection `gifts`

Vous devez voir vos nouveaux produits avec :
- ✅ Nom complet
- ✅ Marque identifiée
- ✅ Prix correct
- ✅ Image URL valide
- ✅ Tags auto-générés

## 📋 Checklist

Avant de lancer :

- [ ] Python 3.8+ installé
- [ ] `requirements_advanced.txt` installé
- [ ] Playwright + Chromium installés
- [ ] `serviceAccountKey.json` présent
- [ ] `links.csv` créé avec URLs valides
- [ ] Firebase testé avec `test_firebase.py`

## 🎯 Commandes Essentielles

```bash
# Tester Firebase
python test_firebase.py

# Nettoyer UNIQUEMENT la base
python main_advanced.py
# → Choisir option 1

# Scraper UNIQUEMENT
python main_advanced.py
# → Choisir option 2

# Les DEUX (recommandé)
python main_advanced.py
# → Choisir option 3
```

## ⚠️ Erreurs Courantes

### "Playwright non installé"
```bash
pip install playwright
playwright install chromium
```

### "serviceAccountKey.json non trouvé"
Le fichier doit être à la **racine** de votre Repl (même niveau que `main_advanced.py`).

### "No module named 'firebase_admin'"
```bash
pip install -r requirements_advanced.txt
```

### Produits non scrapés
- Vérifiez que les URLs dans `links.csv` sont correctes
- Amazon peut avoir changé sa structure HTML
- Augmentez les délais dans le code si timeout

## 📊 Résultats Attendus

Après le scraping, vous devriez voir dans Firebase :

```json
{
  "name": "Sneakers Golden Goose Superstar",
  "brand": "Golden Goose",
  "price": 495,
  "image": "https://m.media-amazon.com/images/I/...",
  "url": "https://www.amazon.fr/dp/B08N5WRWNW",
  "source": "Amazon",
  "tags": ["femme", "budget_luxe", "elegant"],
  "categories": ["Chaussures", "Mode"],
  "scrapedAt": "2025-01-15T10:30:45.123Z",
  "lastUpdated": "2025-01-15T10:30:45.123Z"
}
```

## 🎉 Vous avez terminé !

Votre base Firebase est maintenant :
- ✅ **Propre** (produits incomplets supprimés)
- ✅ **À jour** (nouveaux produits ajoutés)
- ✅ **Optimisée** (tags auto-générés pour le matching)

Votre app Flutter DORON peut maintenant utiliser ces produits de qualité !

## 🔄 Maintenance

Relancez le script régulièrement :
```bash
# Tous les jours/semaines
python main_advanced.py
# → Option 3 (nettoyer + scraper)
```

Cela garantit que votre base reste propre et à jour.

## 📚 Aller Plus Loin

- Lisez `README_ADVANCED.md` pour les détails complets
- Modifiez `main_advanced.py` pour ajouter de nouveaux sites
- Ajustez les tags dans `generate_tags()` pour votre use case

---

🎁 **Bon scraping !**
