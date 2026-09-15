import 'dart:convert';
import 'package:http/http.dart' as http;
import '/utils/app_logger.dart';

class SerpLiveSearchService {
  static const String _serpApiKey = 'ee929df881bc08d5503cd04618757498c11ace09179b80fd8b0a2a20838b8ed1';
  static const String _serpApiBase = 'https://serpapi.com/search.json';

  static final List<String> _excludedBoxes = [
    'smartbox', 'wonderbox', 'dakotabox', 'dakota box', 'coffret cadeau multi'
  ];

  static final List<String> _femaleKeywords = [
    'femme', 'robe', 'jupe', 'escarpin', 'talons', 'lingerie', 'soutien-gorge', 
    'culotte', 'dentelle', 'maquillage', 'rouge à lèvres', 'mascara', 'blush', 
    'palette', 'vernis', 'dyson airwrap', 'airwrap', 'lisseur', 'sac à main', 
    'sac cabas', 'pochette soirée', 'polène', 'polene', 'jacquemus', 'chiquito', 
    'bambino', 'miss dior', 'coco mademoiselle', 'gabrielle chanel', 'black opium', 
    'la vie est belle', 'boucles d\'oreilles'
  ];

  static final List<String> _maleKeywords = [
    'homme', 'cravate', 'nœud papillon', 'tondeuse barbe', 'rasoir barbe', 'barbe', 
    'aftershave', 'costume homme', 'caleçon', 'boxer homme', 'sauvage dior', 
    'bleu de chanel', 'terre d\'hermès'
  ];

  /// Interroge Google Shopping France en temps réel pour un profil de questionnaire
  static Future<List<Map<String, dynamic>>> fetchLiveProductsForQuiz(Map<String, dynamic> userTags) async {
    try {
      final gender = (userTags['gender'] ?? userTags['personGender'] ?? userTags['recipientGender'] ?? '').toString().toLowerCase();
      final isMale = gender.contains('homme') || gender.contains('garçon') || gender.contains('masculin');
      final isFemale = gender.contains('femme') || gender.contains('fille') || gender.contains('féminin');
      final genderSuffix = isMale ? ' homme' : (isFemale ? ' femme' : '');
      final ageStr = (userTags['age'] ?? userTags['personAge'] ?? '25').toString();
      
      final recipientPersonality = (userTags['recipientPersonality'] is List)
          ? (userTags['recipientPersonality'] as List).map((p) => p.toString()).toList()
          : (userTags['recipientPersonality'] is String && (userTags['recipientPersonality'] as String).isNotEmpty
              ? [userTags['recipientPersonality'].toString()]
              : <String>[]);
      final passions = (userTags['passions'] as List?)?.map((p) => p.toString()).toList() ?? [];
      final interests = (userTags['interests'] as List?)?.map((c) => c.toString()).toList() ?? [];
      final giftTypes = (userTags['giftTypes'] as List?)?.map((g) => g.toString()).toList() ?? [];
      final occasion = (userTags['occasion'] ?? '').toString().trim();
      final voiceDesc = (userTags['voiceDescription'] ??
              userTags['vocalTranscript'] ??
              userTags['description'] ??
              (userTags['recipientPersonality'] is String ? userTags['recipientPersonality'] : ''))
          .toString()
          .trim();

      // Construire une liste de requêtes spécifiques et variées (jusqu'à 3 requêtes)
      final List<String> queries = [];

      // 1. Requête basée sur la description vocale ou texte libre
      if (voiceDesc.isNotEmpty && voiceDesc.length > 3) {
        final cleanVoice = voiceDesc
            .toLowerCase()
            .replaceAll(RegExp(r'\b(il|elle|aime|adore|passionné|passion|de|du|des|le|la|les|pour|un|une|très|beaucoup|quelqu|un|cadeau|cadeaux|veut|souhaite|cherche)\b'), ' ')
            .replaceAll(RegExp(r'[^\w\s\-]'), ' ')
            .trim();
        final rawWords = cleanVoice.split(RegExp(r'\s+')).where((w) => w.length >= 3).toList();
        if (rawWords.isNotEmpty) {
          final voiceQuery = rawWords.take(3).join(' ') + genderSuffix;
          queries.add(voiceQuery.trim());
        }
      }

      // 2. Requête basée sur les passions principales
      for (final passion in passions) {
        final cleanPassion = passion.replaceAll('cat_', '').replaceAll('subcat_', '').replaceAll('_', ' ').trim();
        if (cleanPassion.isNotEmpty) {
          queries.add('$cleanPassion$genderSuffix'.trim());
        }
      }

      // 3. Requête basée sur les centres d'intérêt
      for (final interest in interests) {
        final cleanInterest = interest.replaceAll('cat_', '').replaceAll('subcat_', '').replaceAll('_', ' ').trim();
        if (cleanInterest.isNotEmpty) {
          queries.add('$cleanInterest$genderSuffix'.trim());
        }
      }

      // 4. Requête basée sur la personnalité
      for (final perso in recipientPersonality) {
        final pLow = perso.toLowerCase();
        if (pLow.contains('explorateur') || pLow.contains('voyage') || pLow.contains('aventure')) {
          queries.add('sac voyage aventure$genderSuffix');
        } else if (pLow.contains('casanier') || pLow.contains('deco') || pLow.contains('cocooning')) {
          queries.add('deco cocooning plaid');
        } else if (pLow.contains('tech') || pLow.contains('gadget')) {
          queries.add('gadget tech insolite');
        } else if (pLow.contains('gamer') || pLow.contains('jeu')) {
          queries.add('accessoire gaming setup');
        } else if (pLow.contains('fashion') || pLow.contains('mode')) {
          queries.add(isMale ? 'accessoire mode homme tendance' : 'sac bijou femme tendance');
        } else if (pLow.contains('epicurien') || pLow.contains('gourmand')) {
          queries.add('coffret gourmand gastronomie');
        } else if (pLow.contains('sport') || pLow.contains('fitness')) {
          queries.add('accessoire sport fitness$genderSuffix');
        } else {
          final cleanP = perso.replaceAll('perso_', '').replaceAll('&', ' ').replaceAll('_', ' ').trim();
          if (cleanP.isNotEmpty) queries.add('$cleanP$genderSuffix');
        }
      }

      // 5. Requête de secours si liste vide
      if (queries.isEmpty) {
        if (occasion.toLowerCase().contains('valentin')) {
          queries.add(isMale ? 'parfum montre homme' : 'coffret bijou femme');
        } else if (occasion.toLowerCase().contains('noël') || occasion.toLowerCase().contains('noel')) {
          queries.add(isMale ? 'idee cadeau noel homme' : 'idee cadeau noel femme');
        } else {
          queries.add(isMale ? 'idee cadeau homme tendance' : (isFemale ? 'idee cadeau femme tendance' : 'cadeau tendance'));
        }
      }

      // Limiter à 3 requêtes uniques maximum
      final uniqueQueries = queries.toSet().take(3).toList();
      AppLogger.info('⚡ [SerpLiveSearch] ${uniqueQueries.length} requêtes ciblées Google Shopping: ${uniqueQueries.join(" | ")}', 'LiveSearch');

      // Exécuter les requêtes en parallèle
      final responses = await Future.wait(
        uniqueQueries.map((q) => _fetchGoogleShoppingQuery(q, isMale: isMale, isFemale: isFemale, gender: gender, ageStr: ageStr)),
      );

      // Aplatir et dédoublonner
      final List<Map<String, dynamic>> allLiveProducts = [];
      final Set<String> seenTitles = {};
      final Set<String> seenUrls = {};

      for (final productList in responses) {
        for (final product in productList) {
          final titleNorm = (product['name'] ?? '').toString().toLowerCase().trim();
          final url = (product['url'] ?? '').toString().trim();
          if (titleNorm.isNotEmpty && !seenTitles.contains(titleNorm) && !seenUrls.contains(url)) {
            seenTitles.add(titleNorm);
            if (url.isNotEmpty) seenUrls.add(url);
            allLiveProducts.add(product);
          }
        }
      }

      AppLogger.success('🎉 [SerpLiveSearch] Total de ${allLiveProducts.length} produits Google Shopping EN DIRECT récupérés !', 'LiveSearch');
      return allLiveProducts;
    } catch (e) {
      AppLogger.warning('⚠️ [SerpLiveSearch] Exception recherche en direct (fallback local fluide): $e', 'LiveSearch');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchGoogleShoppingQuery(
    String query, {
    required bool isMale,
    required bool isFemale,
    required String gender,
    required String ageStr,
  }) async {
    try {
      final uri = Uri.parse(_serpApiBase).replace(queryParameters: {
        'engine': 'google',
        'tbm': 'shop',
        'q': query,
        'gl': 'fr',
        'hl': 'fr',
        'num': '20',
        'api_key': _serpApiKey,
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) {
        AppLogger.warning('⚠️ [SerpLiveSearch] HTTP ${response.statusCode} for query "$query"', 'LiveSearch');
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawShopping = <dynamic>[];
      if (data['shopping_results'] is List) {
        rawShopping.addAll(data['shopping_results'] as List);
      }
      if (data['immersive_products'] is List) {
        rawShopping.addAll(data['immersive_products'] as List);
      }
      if (data['inline_shopping'] is List) {
        rawShopping.addAll(data['inline_shopping'] as List);
      }

      final List<Map<String, dynamic>> results = [];

      for (int i = 0; i < rawShopping.length; i++) {
        final item = rawShopping[i];
        if (item is! Map) continue;
        final title = (item['title'] ?? item['name'] ?? '').toString().trim();
        final link = (item['product_link'] ?? item['link'] ?? item['direct_link'] ?? item['serpapi_link'] ?? '').toString().trim();
        final thumbnail = (item['thumbnail'] ?? item['serpapi_thumbnail'] ?? item['image'] ?? '').toString().trim();
        final source = (item['source'] ?? item['merchant'] ?? item['seller'] ?? 'Google Shopping').toString().trim();
        final rawPrice = item['extracted_price'] ?? item['price'] ?? item['extracted_price_raw'];

        if (title.isEmpty || thumbnail.isEmpty) continue;

        // Exclusion stricte des Smartbox / Wonderbox
        final titleLower = title.toLowerCase();
        if (_excludedBoxes.any((b) => titleLower.contains(b) || source.toLowerCase().contains(b))) {
          continue;
        }

        // 🛑 VERROUILLAGE STRICT DU GENRE
        if (isMale && _femaleKeywords.any((kw) => titleLower.contains(kw))) {
          continue;
        }
        if (isFemale && _maleKeywords.any((kw) => titleLower.contains(kw))) {
          continue;
        }

        final price = _parsePrice(rawPrice);
        final brand = _extractBrand(title, source);
        final itemGender = isMale ? 'gender_homme' : (isFemale ? 'gender_femme' : 'gender_mixte');
        final docId = 'live_${DateTime.now().millisecondsSinceEpoch}_${results.length}_${i}';

        results.add({
          'id': docId,
          'name': title,
          'product_title': title,
          'brand': brand,
          'brandId': brand.toLowerCase(),
          'price': price,
          'product_price': '${price.toStringAsFixed(2)} €',
          'image': thumbnail,
          'product_photo': thumbnail,
          'imageUrl': thumbnail,
          'url': link.isNotEmpty ? link : 'https://www.google.com/search?q=${Uri.encodeComponent(title)}&tbm=shop',
          'product_url': link.isNotEmpty ? link : 'https://www.google.com/search?q=${Uri.encodeComponent(title)}&tbm=shop',
          'description': '$title — Découverte en temps réel pour $gender ($ageStr ans).',
          'category': 'cat_tendances',
          'subcategory': 'subcat_tendances_gadgets_viraux',
          'categories': ['cat_tendances', 'trending', itemGender, brand.toLowerCase(), 'live_api'],
          'tags': [itemGender, 'trending', 'live_serp_google', 'live_api', 'pour_toi'],
          'gender': itemGender,
          'popularity': 100,
          '_matchScore': 600.0,
          'match': 98,
          'active': true,
          'source': source,
          'is_live': true,
          'from_api': true,
        });
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  static double _parsePrice(dynamic val) {
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) {
      final clean = val.replaceAll(' ', '').replaceAll('€', '').replaceAll(',', '.');
      final match = RegExp(r'\d+(\.\d+)?').firstMatch(clean);
      if (match != null) {
        return double.tryParse(match.group(0)!) ?? 49.99;
      }
    }
    return 49.99;
  }

  static String _extractBrand(String title, String source) {
    final titleLow = title.toLowerCase();
    if (titleLow.contains('apple') || titleLow.contains('iphone') || titleLow.contains('airpods')) return 'Apple';
    if (titleLow.contains('dyson')) return 'Dyson';
    if (titleLow.contains('sony') || titleLow.contains('ps5')) return 'Sony';
    if (titleLow.contains('nike')) return 'Nike';
    if (titleLow.contains('adidas')) return 'Adidas';
    if (titleLow.contains('sephora')) return 'Sephora';
    if (titleLow.contains('wecandoo')) return 'Wecandoo';
    if (titleLow.contains('diptyque')) return 'Diptyque';
    if (titleLow.contains('polène') || titleLow.contains('polene')) return 'Polène';
    if (titleLow.contains('jacquemus')) return 'Jacquemus';
    if (source.isNotEmpty && !source.toLowerCase().contains('google')) return source;
    return 'DORÕN Sélection Directe';
  }
}
