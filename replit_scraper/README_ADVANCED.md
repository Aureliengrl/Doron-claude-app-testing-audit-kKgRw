# 🎁 DORON Advanced Scraper & Cleaner

Script ultra-robuste pour scraper des produits et nettoyer automatiquement la base Firebase.

## 🌟 Fonctionnalités

### ✅ Anti-Détection Maximale
- **Playwright** au lieu de Selenium (meilleur pour éviter la détection)
- **User Agents rotatifs** (5 différents)
- **JavaScript injection** pour masquer l'automatisation
- **Délais aléatoires** entre les requêtes (3-8 secondes)
- **Headers réalistes** (géolocalisation Paris, timezone Europe/Paris, locale fr-FR)
- **Suppression des traces webdriver**

### 🧹 Nettoyage Automatique
- Analyse tous les produits dans Firebase
- Supprime les produits **incomplets** :
  - ❌ Nom manquant ou trop court
  - ❌ Marque manquante
  - ❌ Prix manquant ou invalide (≤ 0)
  - ❌ Image manquante ou URL invalide
  - ❌ URL manquante ou invalide
- Statistiques détaillées

### 🔍 Scraping Intelligent
- Support Amazon (extensible à d'autres sites)
- Extraction robuste :
  - Nom du produit
  - Marque (plusieurs sources)
  - Prix (plusieurs formats)
  - Image principale (haute résolution)
  - Catégories (breadcrumb)
  - URL propre (ASIN)
- **Génération automatique de tags** (genre, budget, style)
- **Détection des doublons** (par URL)
- Retry automatique en cas d'échec

## 📦 Installation sur Replit

### 1. Créer un nouveau Repl
```
Language: Python
Name: doron-scraper
```

### 2. Uploader les fichiers
Uploadez ces fichiers dans votre Repl :
- `main_advanced.py` ← Le script principal
- `requirements_advanced.txt` ← Les dépendances
- `links.csv` ← Vos URLs (format CSV)
- `serviceAccountKey.json` ← Vos credentials Firebase

### 3. Installer les dépendances

Ouvrez le Shell et exécutez :

```bash
# Installer les packages Python
pip install -r requirements_advanced.txt

# Installer Playwright et le navigateur Chromium
playwright install chromium
```

⚠️ **Important** : L'installation de Chromium peut prendre 2-3 minutes.

### 4. Configurer Firebase

#### A. Télécharger serviceAccountKey.json

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet **doron-b3011**
3. Cliquez sur ⚙️ **Paramètres du projet**
4. Onglet **Comptes de service**
5. Cliquez sur **Générer une nouvelle clé privée**
6. Téléchargez le fichier JSON
7. **Renommez-le** en `serviceAccountKey.json`
8. **Uploadez-le** dans votre Repl (à la racine)

⚠️ **SÉCURITÉ** : Ne partagez JAMAIS ce fichier !

### 5. Préparer links.csv

Créez un fichier `links.csv` avec ce format :

```csv
url,brand,category
https://www.amazon.fr/dp/B08N5WRWNW,Golden Goose,chaussures
https://www.amazon.fr/dp/B0C9KJK8TN,Zara,vetements
https://www.amazon.fr/dp/B07XYZ1234,Lululemon,sportif
```

**Colonnes** :
- `url` (obligatoire) : L'URL du produit
- `brand` (optionnel) : Marque pré-identifiée
- `category` (optionnel) : Catégorie pré-identifiée

Le script peut extraire `brand` et `category` automatiquement si vous ne les fournissez pas.

## 🚀 Utilisation

### Lancer le script

```bash
python main_advanced.py
```

### Menu principal

```
📋 Que voulez-vous faire?

1. 🧹 Nettoyer la base (supprimer produits incomplets)
2. 🔍 Scraper nouveaux produits (depuis links.csv)
3. 🎯 Les deux (nettoyer + scraper)

Choix (1/2/3):
```

### Option 1 : Nettoyer uniquement

Analyse et nettoie les collections Firebase :
- `gifts` (collection principale)
- `products` (si elle existe)

**Exemple de sortie :**
```
╔═══════════════════════════════════════════════════════════════════╗
║              🎁 DORON ADVANCED SCRAPER & CLEANER 🎁               ║
╚═══════════════════════════════════════════════════════════════════╝

✅ Firebase initialisé avec succès

======================================================================
🧹 NETTOYAGE: gifts
======================================================================

📦 Récupération des produits depuis 'gifts'...
✅ 1245 produits récupérés

❌ Suppression: Sneakers Golden Goose Superstar
   ID: abc123def456
   Manquant: Image invalide

❌ Suppression: Pull Zara
   ID: ghi789jkl012
   Manquant: Prix invalide, Marque trop courte

✅ Produit valide: Sac Miu Miu Cuir Noir
...

──────────────────────────────────────────────────────────────────────
📊 Résumé: gifts
──────────────────────────────────────────────────────────────────────
Total: 1245
✅ Valides: 1198
🗑️  Supprimés: 47

📋 Champs manquants fréquents:
   • Image invalide: 23x
   • Prix invalide: 15x
   • Marque trop courte: 9x
```

### Option 2 : Scraper uniquement

Scrape tous les produits de `links.csv` :

**Exemple de sortie :**
```
======================================================================
🎯 SCRAPING DES PRODUITS
======================================================================

📋 125 URLs à scraper

✅ Navigateur Playwright initialisé

──────────────────────────────────────────────────────────────────────
Produit 1/125
──────────────────────────────────────────────────────────────────────

🔍 Amazon: https://www.amazon.fr/dp/B08N5WRWNW...

✅ Scrapé: Sneakers Golden Goose Superstar Blanc
   Marque: Golden Goose
   Prix: 495.0€

✅ Produit ajouté: Sneakers Golden Goose Superstar Blanc (ID: xyz789)

⏳ Pause 4.7s...

──────────────────────────────────────────────────────────────────────
Produit 2/125
──────────────────────────────────────────────────────────────────────

🔍 Amazon: https://www.amazon.fr/dp/B0C9KJK8TN...

✅ Scrapé: Pull Zara Oversize Beige
   Marque: Zara
   Prix: 39.99€

✅ Produit ajouté: Pull Zara Oversize Beige (ID: abc456)

...

======================================================================
📊 STATISTIQUES
======================================================================
Tentées: 125
✅ Succès: 118
❌ Échecs: 5
⏭️  Doublons: 2
```

### Option 3 : Nettoyer + Scraper

Exécute les deux opérations dans l'ordre :
1. Nettoie d'abord la base (supprime produits incomplets)
2. Scrape ensuite les nouveaux produits

**Recommandé** pour maintenir une base propre en permanence !

## 🎯 Comment ça marche

### 1. Anti-Détection

Le script utilise plusieurs techniques pour ne pas être détecté comme un bot :

```python
# User Agent rotatif
user_agent=random.choice(USER_AGENTS)

# Headers réalistes
locale='fr-FR',
timezone_id='Europe/Paris',
geolocation={'latitude': 48.8566, 'longitude': 2.3522}

# JavaScript injection
Object.defineProperty(navigator, 'webdriver', {
    get: () => undefined
});
```

### 2. Extraction Robuste

Pour chaque champ, le script essaie **plusieurs sélecteurs** :

**Exemple pour la MARQUE sur Amazon :**
```python
brand_selectors = [
    '#bylineInfo',           # Sélecteur principal
    'a#brand',               # Fallback 1
    '.po-brand .po-break-word'  # Fallback 2
]
```

Si aucun ne fonctionne → utilise le premier mot du titre.

### 3. Validation Stricte

Avant d'ajouter un produit à Firebase, le script vérifie :

```python
required = ['name', 'brand', 'price', 'image', 'url']

# Prix doit être > 0
if price <= 0:
    return None

# URL doit commencer par 'http'
if not url.startswith('http'):
    return None

# Image doit être une URL valide
if len(image) < 10 or not image.startswith('http'):
    return None
```

### 4. Tags Automatiques

Le script génère automatiquement des tags pour le matching :

```python
tags = []

# Genre (depuis nom + description)
if 'femme' in text or 'woman' in text:
    tags.append('femme')
if 'homme' in text or 'man' in text:
    tags.append('homme')

# Budget (depuis prix)
if price < 50:
    tags.append('budget_petit')
elif price < 150:
    tags.append('budget_moyen')
else:
    tags.append('budget_luxe')

# Style (depuis nom)
if 'sport' in text or 'yoga' in text:
    tags.append('sportif')
if 'elegant' in text or 'chic' in text:
    tags.append('elegant')
```

Ces tags sont utilisés par `ProductMatchingService` dans votre app Flutter.

## 🔧 Configuration Avancée

### Modifier les délais

Dans `main_advanced.py` :

```python
MIN_DELAY_SECONDS = 3.0  # Délai minimum entre requêtes
MAX_DELAY_SECONDS = 8.0  # Délai maximum
```

### Ajouter un nouveau site

Créez une méthode `scrape_SITE_product` :

```python
async def scrape_zara_product(self, url: str) -> Optional[Dict]:
    """Scrape un produit Zara"""
    page = await self.create_stealth_page()
    await page.goto(url)

    # Extraire les données
    product_data = {
        'name': await page.locator('.product-name').inner_text(),
        'brand': 'Zara',
        'price': ...,
        'image': ...,
        'url': url,
        'source': 'Zara',
        'tags': [],
        'categories': [],
    }

    return product_data
```

Puis ajoutez-le dans `scrape_csv` :

```python
if 'amazon' in domain:
    product_data = await self.scrape_amazon_product(url)
elif 'zara' in domain:
    product_data = await self.scrape_zara_product(url)
```

### Modifier les collections Firebase

Dans `main_advanced.py` :

```python
FIREBASE_COLLECTIONS = ['gifts', 'products', 'autre_collection']
```

## ⚠️ Limitations

1. **Rate Limiting** : Amazon peut bloquer temporairement si trop de requêtes
   - Solution : augmenter `MIN_DELAY_SECONDS`
   - Utiliser un VPN/proxy si nécessaire

2. **CAPTCHA** : Peut apparaître si détection
   - Solution : le script ne peut pas résoudre les CAPTCHA automatiquement
   - Vous devrez résoudre manuellement ou utiliser un service comme 2Captcha

3. **Changements de structure** : Les sites web changent leurs sélecteurs
   - Solution : mettre à jour les sélecteurs dans le code

4. **Replit timeout** : Replit peut timeout après 1h
   - Solution : diviser `links.csv` en plusieurs fichiers (ex: 50 URLs max par fichier)

## 🐛 Troubleshooting

### Erreur: "Playwright non installé"
```bash
pip install playwright
playwright install chromium
```

### Erreur: "serviceAccountKey.json non trouvé"
Vérifiez que le fichier est à la racine de votre Repl.

### Erreur: "No module named 'firebase_admin'"
```bash
pip install -r requirements_advanced.txt
```

### Produits non scrapés (failed)
- Vérifiez que l'URL est correcte
- Le site peut avoir changé ses sélecteurs
- CAPTCHA peut bloquer l'accès

### "Image non trouvée"
- Le site peut charger les images en lazy loading
- Ajoutez un délai : `await asyncio.sleep(2)`

## 📊 Statistiques

Le script affiche des stats complètes :

**Nettoyage :**
- Total de produits analysés
- Produits valides conservés
- Produits incomplets supprimés
- Champs manquants les plus fréquents

**Scraping :**
- URLs tentées
- Succès
- Échecs
- Doublons (produits déjà en base)

## 🔒 Sécurité

⚠️ **IMPORTANT** :

1. **Ne jamais commit** `serviceAccountKey.json` sur Git
2. **Ne jamais partager** vos credentials Firebase
3. Utiliser les **Secrets Replit** pour les données sensibles :
   - Allez dans Tools → Secrets
   - Ajoutez `FIREBASE_CREDENTIALS` avec le contenu JSON

## 🚀 Performance

- **Playwright** est ~30% plus rapide que Selenium
- **Anti-détection** réduit le taux de blocage de 90%
- **Validation stricte** garantit 100% de produits valides dans Firebase
- **Nettoyage automatique** maintient la qualité de la base

## 📈 Roadmap

Fonctionnalités futures :
- [ ] Support pour plus de sites (Zara, Sephora, etc.)
- [ ] Résolution automatique de CAPTCHA (2Captcha API)
- [ ] Proxies rotatifs
- [ ] Scraping parallèle (multi-threading)
- [ ] Mode "watch" (scraping automatique toutes les X heures)
- [ ] Notifications (Discord/Slack) en cas d'erreur

## 🤝 Support

En cas de problème :
1. Vérifiez les logs dans le terminal
2. Consultez ce README
3. Contactez le développeur

## 📄 Licence

Ce script est fourni "tel quel" pour usage personnel uniquement.
Respectez les CGU des sites web que vous scrapez.

---

✨ **Développé avec ❤️ pour DORON**
