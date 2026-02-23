# 📋 GUIDE COMPLET: Uploader les produits dans Firebase

## 🎯 Méthode Simple (Node.js - 10 minutes)

### **Étape 1: Télécharge ta clé de service Firebase**

1. Va sur https://console.firebase.google.com
2. Sélectionne ton projet **Doron**
3. Clique sur l'⚙️ à côté de "Vue d'ensemble du projet"
4. Clique sur **"Paramètres du projet"**
5. Va dans l'onglet **"Comptes de service"**
6. Clique sur **"Générer une nouvelle clé privée"**
7. Télécharge le fichier JSON
8. **Renomme-le** en `serviceAccountKey.json`
9. **Place-le à la racine** de ton projet Doron (à côté de pubspec.yaml)

⚠️ **IMPORTANT**: Ne commit JAMAIS ce fichier sur Git! Il est déjà dans .gitignore.

---

### **Étape 2: Installe les dépendances**

Ouvre ton **Terminal** et va dans le dossier du projet:

```bash
cd /chemin/vers/Doron
```

Installe firebase-admin:

```bash
npm install firebase-admin
```

---

### **Étape 3: Lance le script**

Dans le même terminal:

```bash
node scripts/convert_and_upload.js
```

---

### **Étape 4: Attends que ça se termine**

Tu verras:

```
🚀 Démarrage de l'upload des produits...
📖 Lecture du fichier...
✅ 2143 produits chargés

📤 Upload des produits...
   Batch size: 500 produits

📦 Batch 1: Produits 1 à 500...
   ✅ Batch 1 uploadé (500 produits)
📦 Batch 2: Produits 501 à 1000...
   ✅ Batch 2 uploadé (500 produits)
...

✅ UPLOAD TERMINÉ!
📊 Statistiques:
   - Produits uploadés: 2143
   - Erreurs: 0

✨ Firebase est maintenant peuplé!
```

**Durée**: ~5-10 minutes

---

### **Étape 5: Vérifie dans Firebase**

1. Retourne sur https://console.firebase.google.com
2. Ouvre ton projet Doron
3. Va dans **Firestore Database**
4. Tu devrais voir la collection **`products`** avec 2000+ documents!

---

### **Étape 6: Rebuild et teste l'app**

1. Build une nouvelle version
2. Upload sur TestFlight
3. Télécharge sur ton téléphone
4. Ouvre l'app → Page d'accueil devrait afficher des **produits variés**!

---

## ❓ En cas de problème

### **Erreur: "Fichier de clé de service non trouvé"**

→ Tu n'as pas placé `serviceAccountKey.json` à la racine du projet.

### **Erreur: "Cannot find module 'firebase-admin'"**

→ Tu n'as pas lancé `npm install firebase-admin`.

### **Erreur: "Permission denied"**

→ Ta clé de service n'a pas les droits d'écriture dans Firestore.
   Va dans Firebase Console → Firestore → Règles → Assure-toi que les règles permettent l'écriture.

---

## ✅ Résultat attendu

Après l'upload:

- ✨ **2000+ produits** dans Firebase
- 🎨 **Tags variés**: homme, femme, tech, beauty, fashion, etc.
- 🏷️ **Marques variées**: Apple, Sony, Samsung, etc.
- 📦 **Catégories variées**: tech, beauty, home, sport, etc.

L'app affichera des produits variés au lieu des 3 hardcodés!
