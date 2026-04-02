# 🚀 Guide Rapide - Nettoyage Firebase

## ⚡ 3 étapes simples

### 1. Télécharge le fichier de credentials Firebase

1. Va sur https://console.firebase.google.com/
2. Sélectionne **doron-b3011**
3. **⚙️ Paramètres du projet** → **Comptes de service**
4. **Générer une nouvelle clé privée**
5. Renomme en `firebase-credentials.json`
6. Place dans `Doron/scripts/`

### 2. Lance le setup

```bash
cd scripts/
./setup_and_run.sh
```

### 3. C'est tout ! 🎉

Le script va automatiquement :
- ✅ Installer les dépendances
- 🔍 Analyser tous tes produits
- 🌐 Compléter les infos manquantes
- 💾 Mettre à jour Firebase

---

## 📊 Résultat attendu

Avant le script :
```
❌ 87 produits incomplets
❌ Images manquantes
❌ Prix à 0€
❌ Noms vides
```

Après le script :
```
✅ Tous les produits complets
✅ Images HD Amazon
✅ Prix corrects
✅ Noms + marques + descriptions
✅ Tags intelligents (homme/femme/tech/mode...)
```

---

## ⏱️ Combien de temps ?

- **~3-6 minutes** pour 100 produits
- **~10-20 minutes** pour 350 produits

Tu peux interrompre avec `Ctrl+C` et reprendre plus tard !

---

## 🆘 Besoin d'aide ?

Lis le `README_FIREBASE_CLEANER.md` pour plus de détails.
