import 'dart:convert';
import 'package:http/http.dart' as http;
import '/utils/app_logger.dart';
import 'abstract_market_api.dart';

class RakutenApiService implements AbstractMarketApi {
  @override
  String get providerName => 'Rakuten';

  final String appId = '46ca81e7-0edd-470a-8349-6057408bd3ba';
  final String accessKey = 'pk_rvua3cE54MueHdOmCFkeQ7FWMqATA4s5riMFf1gwb96';
  final String affiliateId = '54a003ba.b9f68257.54a003bb.33b2e077';

  // Endpoint hypothétique basé sur les clés fournies (format standard ou à adapter selon la doc Rakuten)
  final String baseUrl = 'https://api.rakuten.net/v1/products';

  @override
  Future<List<Map<String, dynamic>>> searchProducts(String query, {int limit = 20}) async {
    try {
      // NOTE: L'URL et les headers devront être ajustés selon la documentation technique exacte de Rakuten que vous possédez.
      // Par exemple, utilisation de query parameters ou de Headers d'authentification.
      final url = Uri.parse('$baseUrl/search?query=${Uri.encodeComponent(query)}&limit=$limit&affiliateId=$affiliateId');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessKey',
          'X-App-Id': appId,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _normalizeResults(data['results'] ✨ []);
      } else {
        AppLogger.debug('❌ Erreur API Rakuten: ${response.statusCode}', 'RakutenAPI');
      }
    } catch (e) {
      AppLogger.debug('❌ Exception API Rakuten: $e', 'RakutenAPI');
    }
    
    // Fallback: Retourner une liste vide en cas d'erreur
    return [];
  }

  @override
  Future<Map<String, dynamic>?> getProductDetails(String productId) async {
    try {
      final url = Uri.parse('$baseUrl/detail/$productId?affiliateId=$affiliateId');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessKey',
          'X-App-Id': appId,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _normalizeSingleProduct(data);
      }
    } catch (e) {
      AppLogger.debug('❌ Exception Rakuten Details: $e', 'RakutenAPI');
    }
    return null;
  }

  /// Convertir le format brut Rakuten vers notre format standardisé Doron
  List<Map<String, dynamic>> _normalizeResults(List<dynamic> rawResults) {
    return rawResults.map((raw) => _normalizeSingleProduct(raw)).toList();
  }

  Map<String, dynamic> _normalizeSingleProduct(Map<String, dynamic> raw) {
    return {
      'id': raw['id']?.toString() ✨ 'rakuten_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'product',
      'name': raw['title'] ✨ raw['name'] ✨ 'Produit Rakuten',
      'brand': raw['brand'] ✨ raw['merchant'] ✨ 'Rakuten',
      'price': raw['price']?.toString() ✨ '',
      'imageUrl': raw['image_url'] ✨ raw['photo'] ✨ '',
      'url': raw['affiliate_url'] ✨ raw['url'] ✨ '',
      'source': 'Rakuten', // Pour savoir de quelle API cela provient
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
