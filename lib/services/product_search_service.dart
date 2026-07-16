import 'package:cloud_firestore/cloud_firestore.dart';
import '/utils/app_logger.dart';
import '/services/search_tokenizer.dart';

/// Recherche produit "plein texte" sur TOUTE la base Firestore (pas
/// seulement le lot déjà chargé pour la catégorie active).
///
/// 100% Firestore, aucun appel API externe, aucun coût supplémentaire :
/// s'appuie sur le champ `searchTokens` (préfixes de mots, voir
/// [SearchTokenizer]) écrit sur chaque produit à l'import.
class ProductSearchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Recherche des produits dont `searchTokens` contient un préfixe
  /// correspondant à [query]. Retourne une liste triée par pertinence
  /// (nombre de mots de la requête retrouvés + popularité), plafonnée à
  /// [limit].
  static Future<List<Map<String, dynamic>>> search(
    String query, {
    int limit = 60,
  }) async {
    final words = SearchTokenizer.wordsFrom(query);
    if (words.isEmpty) return [];

    // Le mot le plus long est le plus sélectif pour la requête Firestore
    // (Firestore n'autorise qu'un seul arrayContains par requête) — le
    // reste des mots sert uniquement au tri de pertinence côté client.
    final primaryWord = words.reduce((a, b) => a.length >= b.length ? a : b);

    try {
      var candidates = await _fetchByToken('gifts', primaryWord, limit * 3);
      if (candidates.isEmpty) {
        candidates = await _fetchByToken('products', primaryWord, limit * 3);
      }
      return _rankAndDedupe(candidates, words, limit);
    } catch (e) {
      AppLogger.error('ProductSearchService.search error', 'Search', e);
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchByToken(
    String collection,
    String token,
    int fetchLimit,
  ) async {
    final snap = await _firestore
        .collection(collection)
        .where('searchTokens', arrayContains: token)
        .limit(fetchLimit)
        .get(const GetOptions(source: Source.serverAndCache));

    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  static List<Map<String, dynamic>> _rankAndDedupe(
    List<Map<String, dynamic>> candidates,
    List<String> queryWords,
    int limit,
  ) {
    final seenIds = <dynamic>{};
    final scored = <MapEntry<double, Map<String, dynamic>>>[];

    for (final product in candidates) {
      final id = product['id'];
      if (seenIds.contains(id)) continue;
      seenIds.add(id);

      final haystack = SearchTokenizer.normalize(
        '${product['name'] ?? ''} ${product['brand'] ?? ''}',
      );

      double score = 0;
      for (final word in queryWords) {
        if (haystack.contains(word)) score += 10;
      }
      // Bonus si le nom commence par le premier mot tapé (résultat "évident")
      if (haystack.startsWith(queryWords.first)) score += 5;
      score += ((product['popularity'] as int?) ?? 0) * 0.05;

      scored.add(MapEntry(score, product));
    }

    scored.sort((a, b) => b.key.compareTo(a.key));
    return scored.take(limit).map((e) => e.value).toList();
  }
}
