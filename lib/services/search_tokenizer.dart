/// Tokenizer partagé pour la recherche produit "full text" 100% Firestore
/// (pas d'Algolia/Typesense — cf. décision coût).
///
/// Principe : à l'indexation (import), chaque produit reçoit un champ
/// `searchTokens` contenant, pour chaque mot significatif de son nom/marque/
/// catégories, TOUS ses préfixes (ex: "casquette" → "ca","cas","casq",...).
/// À la recherche, on tape "casq" et Firestore fait un `arrayContains: "casq"`
/// qui matche directement un de ces préfixes stockés — équivalent d'une
/// recherche "commence par" gratuite et sans dépendance externe.
class SearchTokenizer {
  static const int minWordLength = 2;
  static const int maxWordLengthIndexed = 24; // évite les URLs/ids géants
  static const int maxTokensPerProduct = 200;

  static const Map<String, String> _accentMap = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a',
    'ç': 'c',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i', 'í': 'i', 'ì': 'i',
    'ô': 'o', 'ö': 'o', 'ó': 'o', 'ò': 'o', 'õ': 'o',
    'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
    'ÿ': 'y', 'ñ': 'n',
    'œ': 'oe', 'æ': 'ae',
  };

  /// Retire les accents et met en minuscules.
  static String normalize(String input) {
    final lower = input.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_accentMap[char] ?? char);
    }
    return buffer.toString();
  }

  /// Découpe un texte en mots normalisés (alphanumériques, longueur >= [minWordLength]).
  static List<String> wordsFrom(String text) {
    final normalized = normalize(text);
    final raw = normalized.split(RegExp(r'[^a-z0-9]+'));
    return raw
        .where((w) => w.length >= minWordLength && w.length <= maxWordLengthIndexed)
        .toList();
  }

  /// Génère l'ensemble des tokens (préfixes de chaque mot) à stocker sur un
  /// document produit, à partir de plusieurs champs texte (nom, marque,
  /// catégories lisibles, etc.). Résultat plafonné à [maxTokensPerProduct]
  /// pour ne pas gonfler inutilement la taille du document Firestore.
  static Set<String> tokensForIndexing(List<String?> texts) {
    final tokens = <String>{};
    for (final text in texts) {
      if (text == null || text.isEmpty) continue;
      for (final word in wordsFrom(text)) {
        for (var end = minWordLength; end <= word.length; end++) {
          tokens.add(word.substring(0, end));
          if (tokens.length >= maxTokensPerProduct) return tokens;
        }
      }
    }
    return tokens;
  }
}
