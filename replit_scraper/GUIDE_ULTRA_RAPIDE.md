# 🚀 GUIDE ULTRA-RAPIDE POUR REPLIT

## ⚡ Version SIMPLIFIÉE (SANS Selenium)

Cette version fonctionne à 100% sur Replit et est BEAUCOUP plus rapide à lancer !

---

## 📱 ÉTAPE 1 : Créer le Repl (2 minutes)

1. **Va sur https://replit.com**
2. **Clique sur "Create Repl"**
3. **Choisis "Python"**
4. **Nomme-le "doron-scraper"**
5. **Clique "Create"**

---

## 📄 ÉTAPE 2 : Copier les Fichiers (5 minutes)

### Fichier 1 : `main.py`

1. **Clique sur le fichier `main.py`** qui existe déjà dans ton Repl
2. **SUPPRIME tout** ce qu'il y a dedans
3. **Copie-colle** TOUT le contenu du fichier **`main_simple.py`** (celui-ci !)

### Fichier 2 : `requirements.txt`

1. **Clique sur "+"** (nouveau fichier) en haut à gauche
2. **Nomme-le** exactement : `requirements.txt`
3. **Copie-colle** ça dedans :

```
requests==2.31.0
beautifulsoup4==4.12.2
firebase-admin==6.2.0
```

### Fichier 3 : `links.csv`

1. **Clique sur "+"** (nouveau fichier)
2. **Nomme-le** exactement : `links.csv`
3. **Copie-colle** toutes les URLs (fichier links.csv du dossier)

### Fichier 4 : `serviceAccountKey.json` ⚠️ IMPORTANT

C'est ta clé Firebase secrète !

#### Comment l'obtenir :

1. **Va sur https://console.firebase.google.com/**
2. **Clique sur ton projet** : `doron-b3011`
3. **Clique sur l'icône ⚙️** (roue dentée) en haut à gauche
4. **Clique sur "Project settings"**
5. **Va dans l'onglet "Service accounts"**
6. **Clique sur "Generate new private key"**
7. **Clique "Generate key"** → Un fichier JSON se télécharge
8. **Ouvre ce fichier** avec un éditeur de texte
9. **Copie TOUT** le contenu

#### Dans Replit :

1. **Clique sur "+"** (nouveau fichier)
2. **Nomme-le** exactement : `serviceAccountKey.json`
3. **Colle** tout le contenu du fichier JSON que tu as téléchargé

---

## ▶️ ÉTAPE 3 : Lancer le Script (1 clic !)

1. **Clique sur le gros bouton vert "Run"** en haut

C'est tout ! 🎉

---

## 📊 Que va-t-il se passer ?

Tu vas voir ça dans la console :

```
============================================================
🕷️  SCRAPING SIMPLIFIÉ DES PRODUITS DORÕN
============================================================

✅ Firebase initialisé avec succès!
📋 114 URLs à scraper

[1/114] 🔍 Scraping: https://www.goldengoose.com/...
    🏷️  Marque: Golden Goose
    ⏳ Pause 3.2s...
    ✅ HTML récupéré (45KB)
    ✅ True Star Pour Femme En Cuir Velours Noir...
    💰 Prix: 560€
    🖼️  Image: OK
    🏷️  Tags: femme, luxe, sneakers, budget_premium, adulte...
    📂 Catégories: mode, chaussures
    ✅ Uploadé dans Firebase (ID: abc123xyz)

[2/114] 🔍 Scraping: https://www.zara.com/...
    ...
```

---

## ⏱️ Durée

- **10-20 minutes** pour scraper les 114 produits
- **NE FERME PAS Replit** pendant ce temps !

---

## ⚠️ Si ça ne fonctionne pas

### Erreur 1 : `No module named 'requests'`

**Solution :**
1. Ouvre le **Shell** (onglet en bas de Replit)
2. Tape :
```bash
pip install requests beautifulsoup4 firebase-admin
```
3. Appuie sur Entrée
4. Attends que ça finisse
5. Relance avec le bouton "Run"

### Erreur 2 : `FileNotFoundError: 'serviceAccountKey.json'`

**Solution :**
Tu as oublié le fichier Firebase ! Retourne à **ÉTAPE 2, Fichier 4**.

### Erreur 3 : Certains produits sont marqués ❌

**C'est normal !** Certains sites bloquent le scraping.

**Taux de succès attendu :** 60-80% des produits

---

## ✅ Vérifier que ça a marché

1. **Va sur https://console.firebase.google.com/**
2. **Ouvre ton projet** : `doron-b3011`
3. **Va dans "Firestore Database"**
4. **Clique sur la collection "gifts"**
5. **Tu dois voir les produits** apparaître ! 🎁

---

## 🎯 Résultat Final

À la fin tu verras :

```
============================================================
📊 RÉSULTATS FINAUX:
   ✅ 87 produits scrapés et uploadés avec succès
   ❌ 27 échecs
============================================================

🎉 SCRAPING TERMINÉ!
📝 Logs sauvegardés dans: scraping_log.txt
```

**C'est bon ! Tes produits sont dans Firebase !** 🎉

---

## 💡 Conseils

1. **Garde Replit ouvert** pendant tout le scraping
2. **Si ça s'arrête**, relance juste avec "Run"
3. **Les doublons ne sont pas un problème** (Firebase accepte)
4. **60-80% de succès est excellent !**

---

## 🆘 Besoin d'aide ?

Si vraiment ça ne marche pas sur Replit, utilise **Google Colab** (alternative) :

1. **Va sur https://colab.research.google.com/**
2. **Nouveau notebook**
3. **Colle le code de `main_simple.py`**
4. **Lance**

---

**Créé pour DORÕN** 🎁
**Version Simplifiée Ultra-Rapide**
