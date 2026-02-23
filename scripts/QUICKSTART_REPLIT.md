# 🚀 Guide Express Replit (5 minutes)

## ⚡ Installation Ultra-Rapide

### 1️⃣ Créer le Repl (30 secondes)
1. Allez sur [replit.com](https://replit.com)
2. Cliquez sur **+ Create Repl**
3. Choisissez **Node.js**
4. Nommez-le "fix-firebase-doron"
5. Cliquez sur **Create Repl**

### 2️⃣ Copier le code (1 minute)
1. Dans Replit, ouvrez le fichier `index.js`
2. Supprimez tout le contenu
3. Copiez-collez tout le contenu de `scripts/fix_firebase_tags.js` (depuis GitHub)
4. Créez un fichier `package.json` et copiez son contenu depuis GitHub

### 3️⃣ Ajouter votre clé Firebase (2 minutes)

#### Option A: Via Secrets (recommandé) 🔒
1. Allez sur [Firebase Console](https://console.firebase.google.com/project/_/settings/serviceaccounts/adminsdk)
2. Cliquez sur **Générer une nouvelle clé privée**
3. Téléchargez le fichier JSON
4. Dans Replit, cliquez sur l'icône 🔒 **Secrets** (panneau gauche)
5. Créez un secret:
   - Key: `FIREBASE_KEY`
   - Value: Collez TOUT le contenu du fichier JSON téléchargé
6. Dans `index.js`, ligne 18, remplacez:
   ```javascript
   const serviceAccount = require('./serviceAccountKey.json');
   ```
   par:
   ```javascript
   const serviceAccount = JSON.parse(process.env.FIREBASE_KEY);
   ```

#### Option B: Via fichier 📄
1. Dans Replit, créez un fichier `serviceAccountKey.json`
2. Copiez-collez le contenu de votre clé Firebase dedans
3. ⚠️ **Ne partagez JAMAIS ce Repl !**

### 4️⃣ Exécuter (30 secondes)
1. Cliquez sur le bouton **Run** ▶️ en haut
2. Attendez que le script termine
3. Vérifiez les statistiques affichées

### 5️⃣ Tester l'app (1 minute)
1. Ouvrez votre app Doron
2. Allez dans **Recherche**
3. Cliquez sur **+ Ajouter une personne**
4. Remplissez le formulaire (choisissez "Homme" par exemple)
5. ✅ Vous devriez voir des produits !

---

## 📊 Ce que vous devriez voir

```bash
🔧 Script de correction des tags Firebase
=========================================

📦 Chargement des produits depuis Firebase...
✅ 150 produits chargés

🔄 Traitement des produits...

  👤 "Montre connectée..." → gender_mixte
  📁 "Montre connectée..." → cat_tech
  💰 "Montre connectée..." → budget_50_100 (79€)

   Progress: 50/150 produits traités...
   Progress: 100/150 produits traités...
   Progress: 150/150 produits traités...

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

✨ Votre base Firebase est maintenant prête !
```

---

## ❓ Questions fréquentes

### Le script ne fait rien
→ Vérifiez que vous avez bien cliqué sur **Run** ▶️

### "Cannot find module 'firebase-admin'"
→ Replit devrait installer automatiquement. Si non, tapez dans le Shell:
```bash
npm install firebase-admin
```

### "Could not load the default credentials"
→ Votre clé Firebase n'est pas correctement configurée. Recommencez l'étape 3️⃣

### "Permission denied"
→ Vérifiez les règles Firestore dans Firebase Console

### Le script s'arrête au milieu
→ C'est normal si vous avez beaucoup de produits. Relancez-le, il ne modifiera que les produits qui n'ont pas encore les tags.

---

## 🎉 C'est tout !

Votre base Firebase est maintenant correctement taguée.

**Test final :**
1. Ouvrez l'app
2. Ajoutez une personne "Homme"
3. Vous devriez voir uniquement des produits homme/mixte
4. Ajoutez une personne "Femme"
5. Vous devriez voir uniquement des produits femme/mixte

**Si ça fonctionne : Félicitations ! 🎊**

**Si ça ne fonctionne pas :**
- Vérifiez les logs du script
- Vérifiez que tous les produits ont bien été mis à jour
- Redémarrez l'app (kill et relancer)
- Vérifiez dans Firebase Console que les tags sont bien ajoutés

---

*Temps total : 5 minutes ⏱️*
