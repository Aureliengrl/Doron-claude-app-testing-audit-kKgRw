/// Service pour extraire et générer des URLs de produits
/// Priorité : buyLinks[0] → url → product_url → URL de recherche générée
class ProductUrlService {
  /// Retourne la meilleure URL disponible pour un produit.
  /// Ordre de priorité :
  ///   1. Premier buyLink valide (vraie URL directe produit)
  ///   2. Champ `url` ou `product_url` du document
  ///   3. Génération d'une URL de recherche (fallback)
  static String generateProductUrl(Map<String, dynamic> product) {
    // ── 1. buyLinks : tableau d'objets {url, site, price} ──────────────────
    final rawLinks = product['buyLinks'];
    if (rawLinks is List && rawLinks.isNotEmpty) {
      for (final link in rawLinks) {
        String? linkUrl;
        if (link is Map) {
          linkUrl = link['url'] as String?;
        } else if (link is String && link.startsWith('http')) {
          linkUrl = link; // format legacy : tableau de strings
        }
        if (linkUrl != null && linkUrl.isNotEmpty && linkUrl.startsWith('http')) {
          return linkUrl;
        }
      }
    }

    // ── 2. Champs url / product_url ─────────────────────────────────────────
    for (final key in ['url', 'product_url', 'productUrl', 'buyUrl']) {
      final v = product[key] as String?;
      if (v != null && v.isNotEmpty && v != '#' && v.startsWith('http')) {
        return v;
      }
    }

    // ── 3. Génération d'une URL de recherche intelligente (fallback) ─────────
    final name   = product['name']   as String? ?? '';
    final brand  = product['brand']  as String? ?? '';
    final source = product['source'] as String? ?? 'Amazon';
    final price  = product['price']?.toString() ?? '';
    return _generateSearchUrl(name: name, brand: brand, source: source, price: price);
  }

  /// Génère une URL de recherche optimisée pour chaque plateforme
  static String _generateSearchUrl({
    required String name,
    required String brand,
    required String source,
    required String price,
  }) {
    // Construire la requête de recherche (marque + nom pour meilleure précision)
    final searchQuery = brand.isNotEmpty ? '$brand $name' : name;
    final encodedQuery = Uri.encodeComponent(searchQuery);

    // Déterminer la plateforme et générer l'URL appropriée
    final sourceLower = source.toLowerCase();

    if (sourceLower.contains('amazon')) {
      // Amazon FR - recherche avec filtres
      return 'https://www.amazon.fr/s?k=$encodedQuery';
    } else if (sourceLower.contains('fnac')) {
      // Fnac - recherche
      return 'https://www.fnac.com/SearchResult/ResultList.aspx?Search=$encodedQuery';
    } else if (sourceLower.contains('sephora')) {
      // Sephora - recherche
      return 'https://www.sephora.fr/search/?q=$encodedQuery';
    } else if (sourceLower.contains('decathlon')) {
      // Decathlon - recherche
      return 'https://www.decathlon.fr/search?Ntt=$encodedQuery';
    } else if (sourceLower.contains('zara') || sourceLower.contains('h&m') || sourceLower.contains('mango')) {
      // Mode - fallback vers Google Shopping
      return 'https://www.google.com/search?tbm=shop&q=$encodedQuery';
    } else if (sourceLower.contains('ikea')) {
      // IKEA - recherche
      return 'https://www.ikea.com/fr/fr/search/?q=$encodedQuery';
    } else if (sourceLower.contains('apple')) {
      // Apple Store
      return 'https://www.apple.com/fr/search/$encodedQuery';
    } else if (sourceLower.contains('samsung')) {
      // Samsung
      return 'https://www.samsung.com/fr/search/?searchvalue=$encodedQuery';
    } else if (sourceLower.contains('nike') || sourceLower.contains('adidas')) {
      // Sport brands - direct to brand search
      if (sourceLower.contains('nike')) {
        return 'https://www.nike.com/fr/w?q=$encodedQuery';
      } else {
        return 'https://www.adidas.fr/search?q=$encodedQuery';
      }
    } else {
      // Fallback générique : Amazon FR (marketplace le plus complet)
      return 'https://www.amazon.fr/s?k=$encodedQuery';
    }
  }

  /// Génère une URL directe vers la marque/source si disponible
  static String getBrandUrl(String brand) {
    final brandLower = brand.toLowerCase();

    final brandUrls = {
      'apple': 'https://www.apple.com/fr/',
      'samsung': 'https://www.samsung.com/fr/',
      'sony': 'https://www.sony.fr/',
      'nike': 'https://www.nike.com/fr/',
      'adidas': 'https://www.adidas.fr/',
      'zara': 'https://www.zara.com/fr/',
      'h&m': 'https://www2.hm.com/fr_fr/',
      'sephora': 'https://www.sephora.fr/',
      'decathlon': 'https://www.decathlon.fr/',
      'ikea': 'https://www.ikea.com/fr/fr/',
      'fnac': 'https://www.fnac.com/',
    };

    for (var entry in brandUrls.entries) {
      if (brandLower.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'https://www.amazon.fr/'; // Fallback
  }
}
