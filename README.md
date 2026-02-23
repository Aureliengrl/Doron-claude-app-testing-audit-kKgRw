# DORÕN — Application de Suggestion de Cadeaux

> **Application Flutter** de recommandation de cadeaux personnalisée, propulsée par Firebase et MatchingEngine IA.

## Stack Technique

| Couche | Technologie |
|--------|-------------|
| Mobile | Flutter 3.x / Dart 3.x |
| Backend | Firebase (Auth, Firestore) |
| State | Riverpod 2.x (migration progressive depuis Provider) |
| Navigation | GoRouter 12.x |
| Matching IA | MatchingEngine (pure Dart, zéro OpenAI en prod) |
| Voice | speech_to_text + OpenAI Whisper (analyse intent) |
| Theme | Material 3 — DoronTheme (light + dark) |

---

## Architecture du Projet

```
lib/
├── domain/                   # Logique métier pure (0 Firebase)
│   └── matching/
│       ├── matching_engine.dart  # Scoring produit/profil
│       └── tag_converter.dart    # Profil → tags Doron
│
├── repositories/             # Couche d'accès données
│   ├── repositories.dart     # Barrel file
│   └── src/
│       ├── onboarding_repository.dart
│       ├── person_repository.dart
│       ├── favorites_repository.dart
│       ├── wishlist_repository.dart
│       └── catalog_repository.dart
│
├── providers/                # State management Riverpod
│   ├── app_providers.dart    # FutureProviders (profile, favorites, etc.)
│   └── notifiers.dart        # StateNotifiers (feed, people, favorites)
│
├── services/                 # Services applicatifs
│   ├── firebase_data_service.dart    # DAO central Firebase
│   ├── product_matching_service.dart # Orchestration matching + Firebase
│   ├── openai_home_service.dart      # Delegate → ProductMatchingService
│   ├── openai_onboarding_service.dart
│   └── openai_voice_analysis_service.dart
│
├── theme/
│   └── doron_theme.dart      # Material 3 (light + dark)
│
├── pages/
│   ├── new_pages/            # Pages principales (Pinterest, Search, Results)
│   ├── voice_assistant/      # Module voice (listening, analysis, results)
│   ├── authentification/     # Auth (login, register)
│   └── ...
│
└── utils/
    └── app_logger.dart       # Logging structuré (désactivé en prod)
```

---

## Démarrer

```bash
flutter pub get
flutter run
```

### Variables d'environnement

Les clés API sont stockées dans `assets/environment_values/` (exclu de git via `.gitignore`) :
- `openAiApiKey` — Pour voice analysis uniquement (optionnel)
- Configuration Firebase dans `google-services.json` / `GoogleService-Info.plist`

---

## Tests

```bash
# Tests unitaires (domain logic — aucune dépendance Firebase)
flutter test test/domain/

# Tous les tests
flutter test
```

Les tests couvrent :
- `TagConverter` — conversion profil → tags (10 tests)
- `MatchingEngine` — scoring + exclusions par mode (11 tests)

---

## Firestore

### Déployer les indexes

```bash
firebase deploy --only firestore:indexes
```

Les indexes sont définis dans `firestore.indexes.json` (gifts/tags, gifts/categories, favorites, people).

### Collections principales

| Collection | Contenu |
|-----------|---------|
| `users/{uid}/onboarding/latest` | Profil onboarding utilisateur |
| `users/{uid}/people/{id}` | Destinataires + tags |
| `users/{uid}/people/{id}/giftLists/{id}` | Listes de cadeaux générées |
| `users/{uid}/favorites/{id}` | Produits likés |
| `gifts/{id}` | Catalogue produits (tags, prix, images) |

---

## Logging

En **debug** : logs actifs via `AppLogger.debug/info/error/...`  
En **release** : tous les logs sont désactivés (`kDebugMode` check).

```dart
// ✅ Utiliser AppLogger (jamais print())
AppLogger.debug('message', 'Tag');
AppLogger.info('info message', 'Tag');
AppLogger.error('error message', 'Tag', exception);
```

---

## Roadmap

- [x] Security — API keys sécurisées, .gitignore hardened
- [x] Performance — Pagination Firestore, filtrage serveur
- [x] Architecture — Repository pattern, domain layer
- [x] State — Riverpod StateNotifiers (feed, people, favorites)
- [x] Theme — Material 3 DoronTheme (light + dark)
- [x] Voice — Module vocal intégré dans GoRouter
- [x] Tests — 21 tests unitaires (TagConverter + MatchingEngine)
- [ ] Riverpod — Migration progressive des widgets existants
- [ ] Firestore — Normalisation du champ `image` (script migration)
- [ ] CI/CD — GitHub Actions (flutter test + flutter build)
