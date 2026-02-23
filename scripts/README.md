# Script de population de produits

## ⚡ Solution au problème de lenteur

Au lieu d'appeler l'API OpenAI à chaque fois (lent, coûteux, timeout), nous utilisons maintenant un système de **matching local instantané**.

## Architecture

1. **Base de produits Firebase** : 500+ produits pré-générés avec tags
2. **Matching intelligent** : Algorithme de scoring qui matche les tags utilisateur avec les tags produits
3. **Résultat instantané** : Plus besoin d'attendre OpenAI, réponse < 1 seconde

## Comment peupler la base de produits

### Option 1 : Via script Dart (Recommandé)

```bash
# 1. Assurer que Firebase est configuré
flutter pub get

# 2. Lancer le script
dart run scripts/populate_products.dart
```

### Option 2 : Manuellement via Firebase Console

1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionner votre projet
3. Aller dans Firestore Database
4. Créer une collection `products`
5. Importer les produits depuis `scripts/sample_products.json`

## Structure d'un produit

```json
{
  "name": "AirPods Pro 2ème génération",
  "brand": "Apple",
  "price": 279,
  "description": "Écouteurs sans fil avec réduction de bruit active",
  "image": "https://...",
  "url": "https://...",
  "source": "Apple",
  "tags": ["tech", "audio", "homme", "femme", "premium", "20-30ans"],
  "categories": ["tech"],
  "popularity": 95
}
```

## Tags importants

### Âge
- `enfant`, `jeune`, `ado`
- `jeune-adulte`, `20-30ans`
- `adulte`, `30-50ans`
- `senior`, `50+`

### Genre
- `homme`
- `femme`
- `unisexe`

### Catégories
- `tech`, `gaming`
- `mode`, `fashion`
- `beauté`, `beauty`
- `maison`, `home`
- `sport`, `fitness`
- `food`, `gourmet`

### Budget
- `budget_0-50` (< 50€)
- `budget_50-100` (50-100€)
- `budget_100-200` (100-200€)
- `budget_200+` (> 200€)

### Style
- `moderne`, `classique`, `luxe`, `premium`
- `rock`, `élégant`, `sportif`

## Fonctionnement du matching

1. L'utilisateur répond aux questions d'onboarding
2. Ses réponses sont converties en tags de recherche
3. Le système score tous les produits selon leur pertinence
4. Les meilleurs produits sont retournés instantanément

**Score de matching** :
- Tag exact : +10 points
- Budget correspondant : +15 points
- Popularité : +0.5 par point
- Aléatoire : +0-2 points (pour varier)

## Basculer entre modes

Dans les fichiers :
- `lib/services/openai_home_service.dart`
- `lib/services/openai_onboarding_service.dart`

Modifier la constante `_mode` :
```dart
static const String _mode = 'matching'; // Mode rapide (recommandé)
// ou
static const String _mode = 'openai'; // Mode legacy (lent)
```

## Avantages du matching local

✅ **Instantané** : < 1 seconde au lieu de 10-30 secondes
✅ **Fiable** : Pas de timeout API
✅ **Gratuit** : Pas de coût OpenAI récurrent
✅ **Personnalisé** : Scoring intelligent basé sur les tags
✅ **Scalable** : Fonctionne avec des milliers de produits

## Maintenance

Pour rafraîchir la base de produits :
1. Modifier `scripts/populate_products.dart` avec de nouveaux produits
2. Relancer le script
3. Les nouveaux produits remplacent les anciens

## Notes

- La base contient environ 500 produits au départ
- Vous pouvez en ajouter autant que vous voulez
- Plus il y a de produits, plus le matching est précis
- Les produits peuvent avoir plusieurs tags pour meilleur matching
