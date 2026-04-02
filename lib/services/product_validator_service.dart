/// Service de validation et nettoyage local des données produits.
/// Exécuté au chargement des produits pour corriger les problèmes courants.
class ProductValidatorService {

  /// Valide et normalise un produit avant affichage.
  /// Retourne le produit corrigé.
  static Map<String, dynamic> normalize(Map<String, dynamic> product) {
    final normalized = Map<String, dynamic>.from(product);

    // 1. Normaliser le nom
    normalized['name'] = _normalizeName(product);

    // 2. Normaliser le prix
    normalized['price'] = _normalizePrice(product);

    // 3. Normaliser l'image
    normalized['image'] = _normalizeImage(product);

    // 4. Normaliser l'URL
    normalized['url'] = _normalizeUrl(product);

    // 5. Normaliser la marque
    normalized['brand'] = _normalizeBrand(product);

    return normalized;
  }

  /// Extrait le meilleur nom disponible.
  static String _normalizeName(Map<String, dynamic> p) {
    final candidates = [
      p['name'],
      p['product_title'],
      p['title'],
      p['product_name'],
    ];
    for (final c in candidates) {
      if (c is String && c.trim().isNotEmpty && c != 'Produit' && c.length > 3) {
        return c.trim();
      }
    }
    return 'Produit';
  }

  /// Normalise le prix en String propre.
  static String _normalizePrice(Map<String, dynamic> p) {
    final candidates = [
      p['price'],
      p['product_price'],
    ];
    for (final c in candidates) {
      if (c == null) continue;
      final str = c.toString().trim();
      if (str.isEmpty || str == '0' || str == 'null') continue;

      // Extraire le nombre du prix
      final numMatch = RegExp(r'[\d]+[.,]?\d*').firstMatch(str);
      if (numMatch != null) {
        return '${numMatch.group(0)!.replaceAll(',', '.')} €';
      }
      return str.contains('€') ? str : '$str €';
    }
    return '';
  }

  /// Retourne la meilleure URL d'image ou vide si aucune valide.
  static String _normalizeImage(Map<String, dynamic> p) {
    final candidates = [
      p['image'],
      p['product_photo'],
      p['imageUrl'],
      p['image_url'],
      p['photo'],
      p['thumbnail'],
      p['mainImage'],
      p['cover'],
    ];

    for (final c in candidates) {
      if (c is String && c.trim().isNotEmpty && c.startsWith('http')) {
        final url = c.trim();
        // Rejeter les Unsplash generiques (pas les vraies photos produit)
        if (url.contains('unsplash.com/photo-') && !url.contains('product')) {
          continue;
        }
        return url;
      }
    }
    return '';
  }

  /// Retourne la meilleure URL produit.
  static String _normalizeUrl(Map<String, dynamic> p) {
    final candidates = [
      p['url'],
      p['product_url'],
      p['link'],
    ];

    for (final c in candidates) {
      if (c is String && c.trim().isNotEmpty && c != '#' && c.startsWith('http')) {
        return c.trim();
      }
    }

    // Générer une URL de recherche
    final name = _normalizeName(p);
    final brand = _normalizeBrand(p);
    final query = Uri.encodeComponent('$brand $name'.trim());
    return 'https://www.amazon.fr/s?k=$query';
  }

  /// Normalise le nom de marque.
  static String _normalizeBrand(Map<String, dynamic> p) {
    final candidates = [
      p['brand'],
      p['source'],
      p['platform'],
    ];
    for (final c in candidates) {
      if (c is String && c.trim().isNotEmpty) {
        // Capitalize first letter
        final brand = c.trim();
        if (brand.length <= 1) return brand.toUpperCase();
        return brand[0].toUpperCase() + brand.substring(1);
      }
    }
    return '';
  }

  /// Vérifie la qualité d'un produit et retourne un score 0-100.
  static int qualityScore(Map<String, dynamic> product) {
    int score = 0;

    final name = _normalizeName(product);
    if (name != 'Produit' && name.length > 5) score += 20;
    if (name.length > 15) score += 10; // Nom spécifique

    final price = _normalizePrice(product);
    if (price.isNotEmpty) score += 20;

    final image = _normalizeImage(product);
    if (image.isNotEmpty) score += 25;

    final url = product['url'] as String? ?? '';
    if (url.isNotEmpty && url != '#' && !url.contains('/s?k=')) score += 15; // URL directe

    final brand = _normalizeBrand(product);
    if (brand.isNotEmpty) score += 10;

    return score;
  }
}
