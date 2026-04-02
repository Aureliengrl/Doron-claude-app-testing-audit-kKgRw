# 🕷️ Script de Scraping DORÕN pour Replit

## 📋 Vue d'Ensemble

Ce script Python scrape automatiquement les **114 produits** depuis leurs URLs réelles et les upload directement dans Firebase Firestore.

**Ce qui est extrait :**
- ✅ Nom réel du produit
- ✅ Prix réel en euros
- ✅ Image principale du produit
- ✅ Description
- ✅ Tags générés automatiquement
- ✅ Catégories générées automatiquement

**Envoi direct vers Firebase :**
- Collection : `gifts`
- Projet : `doron-b3011`

---

## 🚀 Installation sur Replit

### Étape 1 : Créer un Nouveau Repl

1. Va sur [Replit.com](https://replit.com)
2. Clique sur **"+ Create Repl"**
3. Choisis **"Python"** comme langage
4. Nomme ton Repl : **"doron-scraper"**
5. Clique sur **"Create Repl"**

### Étape 2 : Copier les Fichiers

Tu dois copier **4 fichiers** dans ton Repl :

#### Fichier 1 : `main.py`
Copie tout le contenu du fichier `main.py` dans le fichier principal de Replit.

#### Fichier 2 : `requirements.txt`
Crée un nouveau fichier appelé `requirements.txt` et copie :
```
selenium==4.15.2
beautifulsoup4==4.12.2
firebase-admin==6.2.0
lxml==4.9.3
```

#### Fichier 3 : `links.csv`
Crée un nouveau fichier appelé `links.csv` et copie toutes les URLs (déjà fourni dans ce dossier).

#### Fichier 4 : `serviceAccountKey.json`
C'est ta clé Firebase. **TRÈS IMPORTANT !**

**Comment obtenir ta clé Firebase :**

1. Va sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionne le projet **`doron-b3011`**
3. Clique sur l'icône ⚙️ (Paramètres) > **Project Settings**
4. Va dans l'onglet **"Service Accounts"**
5. Clique sur **"Generate new private key"**
6. Télécharge le fichier JSON
7. Copie tout le contenu dans un nouveau fichier `serviceAccountKey.json` sur Replit

**⚠️ ATTENTION :** Ce fichier contient des clés privées. Ne le partage JAMAIS publiquement !

---

## 📦 Installation des Dépendances

Une fois tous les fichiers copiés, Replit devrait automatiquement installer les dépendances depuis `requirements.txt`.

Si ce n'est pas le cas, ouvre le **Shell** (dans Replit) et tape :

```bash
pip install -r requirements.txt
```

---

## ▶️ Lancer le Script

### Option 1 : Bouton Run (Recommandé)

Clique simplement sur le gros bouton vert **"Run"** en haut de Replit.

### Option 2 : Via Shell

Dans le Shell de Replit, tape :

```bash
python main.py
```

---

## 📊 Que va-t-il se passer ?

Le script va :

1. **Lire** les 114 URLs depuis `links.csv`
2. **Ouvrir** chaque page web avec un navigateur headless (Selenium)
3. **Extraire** automatiquement :
   - Le nom du produit (depuis les balises meta, titre, ou h1)
   - Le prix en euros (depuis plusieurs patterns possibles)
   - L'image principale (Open Graph ou première image produit)
   - La description
4. **Générer** tags et catégories basés sur :
   - La marque (détectée depuis l'URL)
   - Le nom du produit (analyse de mots-clés)
   - Le prix (fourchette de budget)
5. **Uploader** chaque produit dans Firebase collection `gifts`
6. **Afficher** en temps réel :
   ```
   [1/114] 🔍 Scraping: https://www.goldengoose.com/...
     ✅ HTML récupéré (45KB)
     ✅ True Star Pour Femme En Cuir Velours Noir
     💰 Prix: 560€
     🖼️ Image: OK
     🏷️ Tags: femme, luxe, mode, chaussures, budget_luxe...
     📂 Catégories: mode, chaussures
     ✅ Uploadé dans Firebase (ID: abc123...)
     ⏳ Pause 3.2s...

   [2/114] 🔍 Scraping: https://www.zara.com/...
     ...
   ```

---

## ⏱️ Durée Estimée

- **114 produits** avec délais anti-blocage (2-5 secondes entre chaque)
- **Durée totale estimée :** 15-30 minutes

⚠️ **Ne ferme pas Replit pendant l'exécution !**

---

## 📄 Fichiers de Sortie

### `scraping_log.txt`
Log détaillé de toutes les opérations :
```
============================================================
SCRAPING DÉMARRÉ: 2025-11-15 14:30:00
============================================================

[1/114] URL: https://www.goldengoose.com/...
    ✅ Nom: True Star Pour Femme
    💰 Prix: 560€
    🖼️ Image: https://cdn.goldengoose.com/...
    🏷️ Tags: femme, luxe, mode, chaussures, budget_luxe
    📂 Catégories: mode, chaussures
    ✅ UPLOADÉ DANS FIREBASE
```

Ce fichier sera disponible dans ton Repl après l'exécution.

---

## 🎯 Résultat Final

À la fin du scraping, tu verras :

```
============================================================
📊 RÉSULTATS FINAUX:
   ✅ 96 produits scrapés et uploadés avec succès
   ❌ 18 échecs
============================================================

🎉 SCRAPING TERMINÉ!
📝 Logs sauvegardés dans: scraping_log.txt
```

**Les produits sont maintenant dans Firebase !**

Tu peux les vérifier :
1. Va sur [Firebase Console](https://console.firebase.google.com/)
2. Projet : `doron-b3011`
3. Firestore Database
4. Collection : `gifts`

---

## ⚠️ Résolution des Problèmes

### Erreur 1 : `ModuleNotFoundError: No module named 'selenium'`

**Solution :**
```bash
pip install -r requirements.txt
```

### Erreur 2 : `FileNotFoundError: [Errno 2] No such file or directory: 'serviceAccountKey.json'`

**Solution :**
Tu n'as pas ajouté la clé Firebase. Retourne à **Étape 2, Fichier 4**.

### Erreur 3 : `selenium.common.exceptions.WebDriverException`

**Solution :**
Replit peut parfois avoir des problèmes avec Chrome/Selenium. Essaye de :
1. Redémarrer ton Repl (Stop > Run)
2. Si ça persiste, ajoute cette ligne au début de `main.py` :
   ```python
   import os
   os.system('apt-get update && apt-get install -y chromium-browser chromium-chromedriver')
   ```

### Erreur 4 : Certains produits ne sont pas scrapés (échecs)

**C'est normal !** Certains sites ont des protections anti-scraping fortes.

**Taux de succès estimés :**
- Zara : ~90%
- Sephora : ~85%
- Lululemon : ~80%
- Rhode : ~75%
- Maje : ~70%
- Golden Goose : ~60%
- Miu Miu : ~50%

**Les échecs sont loggés** dans `scraping_log.txt`.

### Erreur 5 : Le script s'arrête après quelques produits

**Causes possibles :**
1. **Timeout Replit** : Replit peut timeout sur les Repls gratuits après 30 minutes
   - **Solution :** Interagis avec le Repl (clique dans la console) toutes les 10 minutes
2. **Blocage IP** : Trop de requêtes depuis la même IP
   - **Solution :** Augmente les délais dans le script (ligne 390 de `main.py`)
   ```python
   delay = random.uniform(5, 10)  # Au lieu de (2, 5)
   ```

---

## 🔧 Personnalisation

### Modifier les délais entre requêtes

Dans `main.py`, ligne ~390 :

```python
# AVANT (défaut)
delay = random.uniform(2, 5)

# APRÈS (plus lent, moins de risque de blocage)
delay = random.uniform(5, 10)
```

### Scraper seulement quelques produits (pour tester)

Dans `main.py`, ligne ~272 :

```python
# AVANT (tous les produits)
with open(CSV_FILE, 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    urls = [row[0] for row in reader if row and row[0].startswith('http')]

# APRÈS (10 premiers produits seulement)
with open(CSV_FILE, 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    urls = [row[0] for row in reader if row and row[0].startswith('http')][:10]
```

---

## 📈 Suivi de Progression

### En Temps Réel (dans le Shell Replit)

```
[15/114] 🔍 Scraping: https://www.zara.com/...
  ✅ HTML récupéré (32KB)
  ✅ Sweat A Capuche Effet Neoprene
  💰 Prix: 29.99€
  🖼️ Image: OK
  🏷️ Tags: femme, mode, vetements, budget_petit...
  📂 Catégories: mode
  ✅ Uploadé dans Firebase
  ⏳ Pause 3.8s...
```

### Dans Firebase Console

Tu peux voir les produits apparaître en temps réel :
1. Ouvre [Firebase Console](https://console.firebase.google.com/)
2. Projet : `doron-b3011`
3. Firestore > Collection `gifts`
4. Rafraîchis la page régulièrement

---

## 🎁 Structure des Produits dans Firebase

Chaque produit uploadé aura cette structure :

```json
{
  "name": "True Star Pour Femme En Cuir Velours Noir",
  "brand": "Golden Goose",
  "price": 560,
  "url": "https://www.goldengoose.com/...",
  "image": "https://cdn.goldengoose.com/.../image.jpg",
  "description": "Sneakers Golden Goose True Star pour femme...",
  "categories": ["mode", "chaussures"],
  "tags": ["femme", "luxe", "sneakers", "budget_luxe", "adulte"],
  "active": true,
  "source": "real_scraping",
  "created_at": "2025-11-15T14:30:00.000Z",
  "popularity": 0,
  "product_photo": "https://cdn.goldengoose.com/.../image.jpg",
  "product_title": "True Star Pour Femme En Cuir Velours Noir",
  "product_url": "https://www.goldengoose.com/...",
  "product_price": "560"
}
```

---

## 🔐 Sécurité

⚠️ **IMPORTANT :**

1. **Ne partage JAMAIS** `serviceAccountKey.json` publiquement
2. Si tu rends ton Repl public, **supprime d'abord** `serviceAccountKey.json`
3. Firebase Admin SDK a des droits complets sur ton projet

---

## ✅ Checklist Avant de Lancer

- [ ] Fichier `main.py` copié
- [ ] Fichier `requirements.txt` copié
- [ ] Fichier `links.csv` copié (114 URLs)
- [ ] Fichier `serviceAccountKey.json` copié (clé Firebase)
- [ ] Dépendances installées (`pip install -r requirements.txt`)
- [ ] Connexion Internet stable
- [ ] Replit ouvert et prêt

**Tout est prêt ?** Clique sur **Run** ! 🚀

---

## 📞 Support

Si tu rencontres des problèmes :

1. **Vérifie les logs** dans le Shell Replit
2. **Consulte** `scraping_log.txt` après exécution
3. **Vérifie Firebase Console** pour voir si des produits sont uploadés
4. **Teste avec 10 produits d'abord** (voir section Personnalisation)

---

**Créé avec ❤️ pour DORÕN**
**Version :** 1.0.0
**Date :** Novembre 2025
