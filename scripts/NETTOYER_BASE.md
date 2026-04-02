# 🧹 Nettoyer ta base Firebase

## ⚡ 2 étapes rapides

### Étape 1 : Télécharger les credentials Firebase (1 minute)

1. Va sur **https://console.firebase.google.com/**
2. Sélectionne le projet **doron-b3011**
3. Clique sur **⚙️ Paramètres du projet** (roue crantée en haut à gauche)
4. Onglet **Comptes de service**
5. Clique sur **Générer une nouvelle clé privée**
6. Un fichier JSON se télécharge
7. **Renomme-le en `serviceAccountKey.json`**
8. **Place-le dans le dossier `Doron/scripts/`**

### Étape 2 : Lancer le nettoyage

```bash
cd scripts/
npm install firebase-admin  # Seulement la première fois
node clean_incomplete_products.js
```

## ✨ Ce qui va se passer

Le script va :
1. ✅ Analyser TOUS les 300 produits
2. ✅ Identifier les produits incomplets (manque nom, marque, prix, image, etc.)
3. ✅ Les **supprimer automatiquement**
4. ✅ Garder SEULEMENT les produits 100% complets

## 📊 Résultat attendu

**Avant :**
- 300 produits
- 184 incomplets (61%)
- 116 complets (39%)

**Après :**
- 116 produits complets (100%)
- Base propre et stable
- Plus aucun produit avec données manquantes

---

## ⏱️ Temps estimé

**~30 secondes** pour tout nettoyer !

---

C'est parti ! 🚀
