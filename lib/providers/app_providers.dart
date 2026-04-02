import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/services/firebase_data_service.dart';
import '/services/product_matching_service.dart';
export '/providers/notifiers.dart'; // FeedNotifier, PeopleNotifier, FavoritesNotifier


// ─────────────────────────────────────────────────────────────────────────────
// RIVERPOD PROVIDERS — ARCHITECTURE PROGRESSIVE
//
// Ces providers peuvent être utilisés immédiatement dans les nouveaux widgets
// tout en coexistant avec le Provider/FFAppState hérité.
//
// Migration progressive :
// 1. Nouveau widget → utilise ConsumerWidget + ces providers
// 2. Widget hérité → continue d'utiliser context.watch<FFAppState>() (OK)
//
// Usage :
//   class MyWidget extends ConsumerWidget {
//     @override
//     Widget build(BuildContext context, WidgetRef ref) {
//       final favorites = ref.watch(favoritesProvider);
//       ...
//     }
//   }
// ─────────────────────────────────────────────────────────────────────────────

// ── Profil utilisateur ────────────────────────────────────────────────────────

/// Tags de profil de l'utilisateur courant (intérêts, style, genre…).
/// Chargé une fois, mis en cache, rechargé uniquement quand nécessaire.
final userProfileTagsProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return FirebaseDataService.loadUserProfileTags();
});

/// Réponses d'onboarding de l'utilisateur courant.
final onboardingAnswersProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return FirebaseDataService.loadOnboardingAnswers();
});

// ── Favoris ───────────────────────────────────────────────────────────────────

/// Liste des produits favoris de l'utilisateur.
/// Utiliser `ref.refresh(favoritesProvider)` pour forcer un rechargement.
final favoritesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return FirebaseDataService.loadFavorites();
});

// ── Destinataires (People) ────────────────────────────────────────────────────

/// Tous les destinataires de l'utilisateur (Maman, Papa, etc.)
final peopleProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return FirebaseDataService.loadPeople();
});

/// Destinataire actuellement actif (contexte de recherche).
final currentPersonContextProvider = FutureProvider<String?>((ref) async {
  return FirebaseDataService.getCurrentPersonContext();
});

// ── Produits personnalisés ────────────────────────────────────────────────────

/// Paramètres de la requête de produits personnalisés.
class ProductQueryParams {
  final Map<String, dynamic> userTags;
  final String category;
  final int count;
  final String filteringMode;

  const ProductQueryParams({
    required this.userTags,
    this.category = 'all',
    this.count = 20,
    this.filteringMode = 'discovery',
  });
}

/// Provider de produits personnalisés basé sur des paramètres.
/// Usage : `ref.watch(personalizedProductsProvider(params))`
final personalizedProductsProvider = FutureProvider.family<
    List<Map<String, dynamic>>, ProductQueryParams>((ref, params) async {
  return ProductMatchingService.getPersonalizedProducts(
    userTags: params.userTags,
    count: params.count,
    category: params.category,
    filteringMode: params.filteringMode,
  );
});

// ── Wishlists ─────────────────────────────────────────────────────────────────

/// Toutes les wishlists de l'utilisateur.
final wishlistsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return FirebaseDataService.loadWishlists();
});
