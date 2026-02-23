# DORÕN - Nouvelles Pages Flutter

Ce dossier contient 4 nouvelles pages Flutter créées pour l'application DORÕN, converties depuis des prototypes React.

## 📱 Pages Créées

### 1. **Onboarding Avancé** (`onboarding_advanced/`)
Page d'onboarding interactive avec questions conditionnelles.

**Caractéristiques:**
- Questions à choix unique et multiple
- Sliders pour la sélection de budget
- Logique conditionnelle (questions différentes selon le destinataire)
- Animations de particules en arrière-plan
- Barre de progression dynamique
- Transitions fluides entre les étapes

**Sections:**
- **Partie "Toi"**: Âge, genre, centres d'intérêt, style, types de cadeaux préférés
- **Partie "Cadeau"**: Destinataire, budget, passions, personnalité, occasion, etc.

**Navigation:**
```dart
Navigator.pushNamed(context, '/onboarding-advanced');
```

---

### 2. **Home Pinterest** (`home_pinterest/`)
Page d'accueil avec grille de produits style Pinterest (2 colonnes décalées).

**Caractéristiques:**
- Grille masonry 2 colonnes avec décalage
- Header violet arrondi avec effet de lumière
- Catégories horizontales filtrables
- Cartes produits avec bouton "like"
- Modal détaillé pour chaque produit
- Navigation bottom bar

**Fonctionnalités:**
- Système de favoris
- Filtrage par catégorie (Pour toi, Tendances, Tech, Mode, etc.)
- Affichage du prix et de la source
- Match percentage pour chaque produit

**Navigation:**
```dart
Navigator.pushNamed(context, '/home-pinterest');
```

---

### 3. **Page Recherche** (`search_page/`)
Page de recherche de cadeaux par profil/personne.

**Caractéristiques:**
- Sélection de profils en scroll horizontal
- Bouton "+" pour ajouter une nouvelle personne
- Grille de produits filtrée par profil sélectionné
- Info-card du profil sélectionné (relation, occasion)
- Bouton flottant "Ajouter une nouvelle personne"

**Fonctionnalités:**
- Gestion de plusieurs profils (Maman, Papa, Ami, etc.)
- Produits personnalisés par profil
- Système de favoris par produit
- Navigation vers l'onboarding pour créer un nouveau profil

**Navigation:**
```dart
Navigator.pushNamed(context, '/search-page');
```

---

### 4. **Résultats Cadeaux** (`gift_results/`)
Page de résultats avec recommandations IA après l'onboarding.

**Caractéristiques:**
- Header avec résumé du destinataire et budget
- Message IA personnalisé avec nombre de résultats
- Filtres (Tous, Meilleur match, Prix croissant/décroissant)
- Liste de cadeaux avec score de match (%)
- Animations d'entrée progressives (fade + slide)

**Fonctionnalités:**
- Badge de match coloré selon le pourcentage (vert ≥90%, bleu ≥80%, orange <80%)
- Raison du match IA pour chaque produit
- Modal détaillé avec explication du choix
- Liens vers les sites marchands (Amazon, Fnac, Sephora, etc.)

**Navigation:**
```dart
Navigator.pushNamed(context, '/gift-results');
```

---

## 🎨 Charte Graphique

### Couleurs
- **Violet principal**: `#9D4EDD` (rgb(157, 78, 221))
- **Rose accent**: `#EC4899`
- **Jaune étoile**: `#FBBF24`
- **Gris texte**: `#4B5563`, `#6B7280`, `#9CA3AF`
- **Fond**: `#F9FAFB`

### Typographie
- **Police**: Poppins (via `google_fonts`)
- **Tailles**:
  - Titres: 28-32px
  - Sous-titres: 18-22px
  - Corps: 14-16px
  - Small: 12-13px

### Coins arrondis
- Cartes: 20-24px
- Boutons: 12-16px
- Modals: 24-32px
- Pills/Badges: 8-20px

---

## 🛠 Intégration dans le Projet

### 1. Ajouter les routes dans `lib/flutter_flow/nav/nav.dart`

```dart
'/onboarding-advanced': (context, params) => OnboardingAdvancedWidget(),
'/home-pinterest': (context, params) => HomePinterestWidget(),
'/search-page': (context, params) => SearchPageWidget(),
'/gift-results': (context, params) => GiftResultsWidget(),
```

### 2. Imports nécessaires

Les pages utilisent déjà les packages disponibles dans le projet:
- `flutter/material.dart`
- `google_fonts` (déjà dans `pubspec.yaml`)
- Pas de dépendances supplémentaires requises

### 3. Polices

La police **Poppins** est automatiquement chargée via `google_fonts`.
Aucune configuration supplémentaire n'est nécessaire.

---

## 📦 Structure des Fichiers

```
lib/pages/new_pages/
├── onboarding_advanced/
│   ├── onboarding_advanced_widget.dart
│   └── onboarding_advanced_model.dart
├── home_pinterest/
│   ├── home_pinterest_widget.dart
│   └── home_pinterest_model.dart
├── search_page/
│   ├── search_page_widget.dart
│   └── search_page_model.dart
├── gift_results/
│   ├── gift_results_widget.dart
│   └── gift_results_model.dart
└── README.md (ce fichier)
```

Chaque page suit l'architecture **Widget/Model** de FlutterFlow:
- **Widget**: Interface utilisateur et interactions
- **Model**: Logique métier, données et états

---

## 🔄 Flux Utilisateur Recommandé

1. **Onboarding** (`/onboarding-advanced`)
   - L'utilisateur répond aux questions
   - À la fin → Navigation vers `/gift-results`

2. **Résultats** (`/gift-results`)
   - Affichage des recommandations IA
   - Possibilité de liker et voir les détails

3. **Home Pinterest** (`/home-pinterest`)
   - Parcours de tous les produits disponibles
   - Navigation bottom bar vers Favoris, Recherche, Profil

4. **Recherche** (`/search-page`)
   - Sélection d'un profil existant
   - Ajout de nouvelles personnes → Retour à l'onboarding

---

## 🎯 Fonctionnalités à Implémenter (Prochaines Étapes)

- [ ] Connexion à Firebase pour sauvegarder les réponses d'onboarding
- [ ] Intégration API pour récupérer les vrais produits
- [ ] Système de favoris persistant
- [ ] Liens réels vers les sites marchands
- [ ] Partage de produits
- [ ] Notifications push pour les occasions importantes
- [ ] Mode sombre

---

## 🐛 Notes de Développement

### Animations
Toutes les animations utilisent les `AnimationController` natifs de Flutter.
Aucune bibliothèque tierce n'est requise.

### Images
Les images utilisent actuellement Unsplash pour le prototype.
À remplacer par les vraies images produits via votre API.

### Responsiveness
Les pages sont optimisées pour mobile (iOS/Android).
Pour le web/desktop, ajuster les `maxWidth` dans les containers.

---

## 📞 Support

Pour toute question ou modification, contactez l'équipe de développement DORÕN.

**Bonne intégration ! 🎁✨**
