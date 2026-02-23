# 🔧 Script de Correction des Tags Firebase

Ce script corrige automatiquement tous les tags manquants dans votre collection Firebase `gifts`.

## 🎯 Problème résolu

Sans les bons tags, l'application ne peut pas :
- Filtrer les produits par genre (homme/femme/mixte)
- Afficher des produits lors de l'ajout d'une nouvelle personne
- Calculer les scores de matching correctement

## 📋 Tags ajoutés automatiquement

### Genre (CRITIQUE pour le filtrage)
- `gender_homme` - Produits masculins
- `gender_femme` - Produits féminins
- `gender_mixte` - Produits universels (par défaut)

### Catégories
- `cat_tech` - Électronique, gadgets
- `cat_mode` - Vêtements, chaussures
- `cat_beaute` - Maquillage, parfums
- `cat_maison` - Déco, maison
- `cat_sport` - Fitness, sport
- `cat_food` - Gastronomie, cuisine
- `cat_tendances` - Par défaut

### Budget (basé sur le prix)
- `budget_0_50` - Moins de 50€
- `budget_50_100` - 50-100€
- `budget_100_200` - 100-200€
- `budget_200_500` - 200-500€
- `budget_500_plus` - Plus de 500€

### Âge
- `age_adulte` - Par défaut (18-50 ans)
- `age_jeune` - Ados (détecté par mots-clés)
- `age_enfant` - Enfants (détecté par mots-clés)
- `age_senior` - Seniors (détecté par mots-clés)

## 🚀 Utilisation sur Replit

### 1. Récupérer votre clé Firebase

1. Allez sur [Firebase Console](https://console.firebase.google.com)
2. Sélectionnez votre projet
3. Allez dans **Paramètres du projet** (roue crantée) → **Comptes de service**
4. Cliquez sur **Générer une nouvelle clé privée**
5. Téléchargez le fichier JSON (c'est votre `serviceAccountKey.json`)

### 2. Configurer Replit

1. Créez un nouveau Repl **Node.js** sur [Replit](https://replit.com)

2. Importez les fichiers :
   - Copiez le contenu de `fix_firebase_tags.js` dans `index.js`
   - Créez un fichier `package.json` avec :
   ```json
   {
     "name": "fix-firebase-tags",
     "version": "1.0.0",
     "main": "index.js",
     "dependencies": {
       "firebase-admin": "^12.0.0"
     }
   }
   ```

3. Ajoutez votre clé Firebase :
   - Ouvrez l'onglet **Secrets** (🔒) dans Replit
   - OU créez un fichier `serviceAccountKey.json` et collez le contenu de votre clé Firebase

4. Si vous utilisez Secrets, modifiez la ligne 18 du script :
   ```javascript
   // Avant
   const serviceAccount = require('./serviceAccountKey.json');

   // Après (si vous utilisez Secrets)
   const serviceAccount = JSON.parse(process.env.FIREBASE_KEY);
   ```

### 3. Exécuter le script

1. Dans Replit, cliquez sur **Run** (ou tapez `node index.js` dans le Shell)

2. Le script va :
   - Charger tous les produits de votre collection `gifts`
   - Analyser chaque produit
   - Ajouter les tags manquants
   - Afficher les statistiques en temps réel

3. Attendez que le script termine (quelques secondes à quelques minutes selon le nombre de produits)

### 4. Vérifier les résultats

Le script affichera :
```
✅ TERMINÉ !
═══════════════════════════════════════
📊 Total produits: 150
✅ Produits mis à jour: 147
❌ Erreurs: 0

📈 Tags ajoutés par type:
  👤 Genre: 147
  📁 Catégorie: 145
  💰 Budget: 140
  🎂 Âge: 147
```

## ✅ Vérification dans l'app

Après avoir exécuté le script, testez votre app :

1. **Page d'accueil** : Devrait afficher des produits
2. **Ajouter une personne** (homme) : Devrait afficher uniquement des produits homme/mixte
3. **Ajouter une personne** (femme) : Devrait afficher uniquement des produits femme/mixte
4. **Scoring** : Les produits sont triés par pertinence (âge, catégorie, budget, etc.)

## 🔍 Détection intelligente

Le script utilise des mots-clés pour détecter automatiquement :

### Genre Féminin
- robe, jupe, lingerie, maquillage, rouge à lèvres, mascara, vernis, sac à main, femme, pour elle, etc.

### Genre Masculin
- cravate, rasoir électrique, tondeuse barbe, after shave, costume homme, homme, pour lui, barbe, etc.

### Catégories
- **Tech** : gadget, bluetooth, écouteurs, smartphone, etc.
- **Mode** : vêtement, t-shirt, chaussure, basket, etc.
- **Beauté** : parfum, crème, soin, cosmétique, etc.
- **Sport** : fitness, yoga, running, musculation, etc.
- Et bien plus...

## ⚠️ Important

- **Backup recommandé** : Firebase garde un historique, mais faites un export si vous voulez être prudent
- **Temps d'exécution** : ~0.5 seconde par produit (150 produits = ~75 secondes)
- **Sécurité** : Ne commitez JAMAIS votre `serviceAccountKey.json` sur GitHub !
- **Une seule fois** : Vous n'avez besoin d'exécuter ce script qu'une seule fois

## 🐛 Problèmes courants

### "Cannot find module 'firebase-admin'"
→ Exécutez `npm install` dans le Shell de Replit

### "Error: Could not load the default credentials"
→ Vérifiez que votre `serviceAccountKey.json` est correct et au bon endroit

### "Permission denied"
→ Vérifiez les règles Firestore de votre projet Firebase

### Aucun produit trouvé
→ Vérifiez que votre collection s'appelle bien `gifts` (pas `products`)

## 📞 Support

Si vous rencontrez des problèmes :
1. Vérifiez que Firebase Admin SDK est bien installé
2. Vérifiez que votre clé de service est valide
3. Vérifiez les logs dans Replit Console
4. Vérifiez les règles Firestore (lecture/écriture autorisées pour admin)

---

**Temps estimé : 5 minutes de configuration + quelques minutes d'exécution**

Bonne correction ! 🚀
