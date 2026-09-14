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
      final gender = (userTags['gender'] ?? userTags['recipientGender'] ?? '').toString().toLowerCase();
      final isMale = gender.contains('homme');
      final isFemale = gender.contains('femme');
      
      final passions = (userTags['passions'] as List?)?.map((p) => p.toString()).toList() ?? [];
      final categories = (userTags['categories'] as List?)?.map((c) => c.toString()).toList() ?? [];
      final giftTypes = (userTags['giftTypes'] as List?)?.map((g) => g.toString()).toList() ?? [];

      // Construire des mots-clés concis (2-3 termes max pour rapidité Google Shopping)
      String keyword = 'cadeau';
      if (passions.isNotEmpty) {
        keyword = passions.first.replaceAll('cat_', '').replaceAll('subcat_', '').replaceAll('_', ' ');
      } else if (giftTypes.isNotEmpty) {
        keyword = giftTypes.first.toString().replaceAll('_', ' ');
      } else if (categories.isNotEmpty) {
        keyword = categories.first.replaceAll('cat_', '').replaceAll('subcat_', '').replaceAll('_', ' ');
      } else if (isMale) {
        keyword = 'gadget tech homme';
      } else if (isFemale) {
        keyword = 'beauté mode femme';
      }

      final query = isMale ? '$keyword homme' : (isFemale ? '$keyword femme' : keyword);
      AppLogger.info('⚡ [SerpLiveSearch] Requête ciblée Google Shopping: "$query"', 'LiveSearch');

      final uri = Uri.parse(_serpApiBase).replace(queryParameters: {
        'engine': 'google_shopping',
        'q': query,
        'gl': 'fr',
        'hl': 'fr',
        'num': '10',
        'api_key': _serpApiKey,
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        AppLogger.warning('⚠️ [SerpLiveSearch] Statut HTTP ${response.statusCode}', 'LiveSearch');
        return [];
      }

      final data = jsonDecode(response.body);
      final rawShopping = (data['shopping_results'] as List?) ?? [];
      if (rawShopping.isEmpty) {
        AppLogger.warning('⚠️ [SerpLiveSearch] Aucun résultat Google Shopping retourné', 'LiveSearch');
        return [];
      }

      final List<Map<String, dynamic>> liveProducts = [];

      for (int i = 0; i < rawShopping.length; i++) {
        final item = rawShopping[i];
        final title = (item['title'] ?? '').toString().trim();
        final link = (item['link'] ?? '').toString().trim();
        final thumbnail = (item['thumbnail'] ?? '').toString().trim();
        final source = (item['source'] ?? 'Google Shopping').toString().trim();
        final rawPrice = item['price'];

        if (title.isEmpty || thumbnail.isEmpty || link.isEmpty) continue;

        // Exclusion stricte des Smartbox / Wonderbox
        final titleLower = title.toLowerCase();
        if (_excludedBoxes.any((b) => titleLower.contains(b) || source.toLowerCase().contains(b))) {
          continue;
        }

        // 🛑 VERROUILLAGE STRICT DU GENRE (0% FUITE)
        if (isMale && _femaleKeywords.any((kw) => titleLower.contains(kw))) {
          continue;
        }
        if (isFemale && _maleKeywords.any((kw) => titleLower.contains(kw))) {
          continue;
        }

        final price = _parsePrice(rawPrice);
        final brand = _extractBrand(title, source);
        final itemGender = isMale ? 'gender_homme' : (isFemale ? 'gender_femme' : 'gender_mixte');

        final docId = 'live_${DateTime.now().millisecondsSinceEpoch}_$i';

        liveProducts.add({
          'id': docId,
          'name': title,
          'product_title': title,
          'brand': brand,
          'brandId': brand.toLowerCase(),
          'price': price,
          'product_price': '${price.toStringAsFixed(2)} €',
          'image': thumbnail,
          'product_photo': thumbnail,
          'url': link,
          'product_url': link,
          'description': '$title — Découverte en temps réel pour $gender ($ageStr ans).',
          'category': 'cat_tendances',
          'subcategory': 'subcat_tendances_gadgets_viraux',
          'categories': ['cat_tendances', 'trending', itemGender, brand.toLowerCase()],
          'tags': [itemGender, 'trending', 'live_serp_google'],
          'gender': itemGender,
          'popularity': 100, // Score maximal pour le résultat en direct ultra-ciblé
          '_matchScore': 350.0, // Priorité absolue en tête de questionnaire
          'active': true,
          'source': source,
          'is_live': true,
        });
      }

      AppLogger.success('🎉 [SerpLiveSearch] ${liveProducts.length} produits ultra-ciblés récupérés en direct !', 'LiveSearch');
      return liveProducts;
    } catch (e) {
      AppLogger.warning('⚠️ [SerpLiveSearch] Exception recherche en direct (fallback local fluide): $e', 'LiveSearch');
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
