import 'package:cloud_functions/cloud_functions.dart';
import '/utils/app_logger.dart';

class ClaudeApiService {
  /// Appelle la Cloud Function 'generateGiftIdeas' et retourne une liste de cadeaux suggérés
  static Future<List<Map<String, dynamic>>> generateGiftIdeas(Map<String, dynamic> userTags) async {
    try {
      AppLogger.info('🤖 Appel de l\'API Claude pour générer des cadeaux...', 'ClaudeApi');
      
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('generateGiftIdeas');
      
      final response = await callable.call(<String, dynamic>{
        'userTags': userTags,
      });
      
      final data = response.data;
      if (data != null && data['ideas'] != null) {
        final List<dynamic> ideasDynamic = data['ideas'];
        final List<Map<String, dynamic>> ideasList = ideasDynamic.map((e) => Map<String, dynamic>.from(e)).toList();
        
        AppLogger.info('✅ Claude a généré ${ideasList.length} idées de cadeaux.', 'ClaudeApi');
        return ideasList;
      }
      
      return [];
    } catch (e) {
      AppLogger.error('❌ Erreur lors de l\'appel à Claude: $e', 'ClaudeApi');
      return [];
    }
  }

  /// Appelle la Cloud Function 'generateBrands' et retourne une liste de marques
  static Future<List<String>> generatePersonalizedBrands(int age, List<String> domains) async {
    try {
      AppLogger.info('🤖 Appel de l\'API Claude pour générer des marques...', 'ClaudeApi');
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('generateBrands');
      final response = await callable.call(<String, dynamic>{
        'age': age,
        'domains': domains,
      });
      final data = response.data;
      if (data != null && data['brands'] != null) {
        final List<dynamic> brandsDynamic = data['brands'];
        final List<String> brandsList = brandsDynamic.map((e) => e.toString()).toList();
        AppLogger.info('✅ Claude a généré ${brandsList.length} marques.', 'ClaudeApi');
        return brandsList;
      }
      return [];
    } catch (e) {
      AppLogger.error('❌ Erreur lors de l\'appel à Claude (marques): $e', 'ClaudeApi');
      return [];
    }
  }

  /// Appelle la Cloud Function 'generateEvents' et retourne une liste d'événements
  static Future<List<String>> generateUpcomingEvents(int age, List<String> domains) async {
    try {
      AppLogger.info('🤖 Appel de l\'API Claude pour générer des événements...', 'ClaudeApi');
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('generateEvents');
      final response = await callable.call(<String, dynamic>{
        'age': age,
        'domains': domains,
      });
      final data = response.data;
      if (data != null && data['events'] != null) {
        final List<dynamic> eventsDynamic = data['events'];
        final List<String> eventsList = eventsDynamic.map((e) => e.toString()).toList();
        AppLogger.info('✅ Claude a généré ${eventsList.length} événements.', 'ClaudeApi');
        return eventsList;
      }
      return [];
    } catch (e) {
      AppLogger.error('❌ Erreur lors de l\'appel à Claude (événements): $e', 'ClaudeApi');
      return [];
    }
  }

  /// Appelle la Cloud Function 'rerankProductsWithClaude' pour obtenir un Perfect Match 200%
  static Future<List<Map<String, dynamic>>> rerankProducts(List<Map<String, dynamic>> products, Map<String, dynamic> userProfile) async {
    try {
      AppLogger.info('🤖 Appel de l\'API Claude pour reranker ${products.length} produits...', 'ClaudeApi');
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('rerankProductsWithClaude');
      
      // We should only send minimal data to save tokens
      final simplifiedProducts = products.map((p) => {
        'id': p['id'],
        'name': p['name'],
        'description': p['description']?.toString().substring(0, p['description'].toString().length > 100 ? 100 : p['description'].toString().length),
        'price': p['price'],
      }).toList();

      final response = await callable.call(<String, dynamic>{
        'products': simplifiedProducts,
        'userProfile': userProfile,
      }).timeout(const Duration(milliseconds: 1500));
      
      final data = response.data;
      if (data != null && data['rerankedProducts'] != null) {
        final List<dynamic> rerankedList = data['rerankedProducts'];
        
        // Re-order and enrich original products based on the IDs returned
        final result = <Map<String, dynamic>>[];
        for (var item in rerankedList) {
          final id = item['id'];
          final justification = item['justification'];
          
          final originalProduct = products.firstWhere(
            (p) => p['id'] == id, 
            orElse: () => <String, dynamic>{}
          );
          
          if (originalProduct.isNotEmpty) {
            // Ajouter la justification IA au produit
            final enrichedProduct = Map<String, dynamic>.from(originalProduct);
            enrichedProduct['ia_justification'] = justification;
            enrichedProduct['is_perfect_match'] = true;
            result.add(enrichedProduct);
          }
        }
        
        AppLogger.info('✅ Claude a trouvé ${result.length} Perfect Matches.', 'ClaudeApi');
        
        // Si l'IA a retourné des résultats, on les retourne, complétés éventuellement par d'autres
        if (result.isNotEmpty) {
          // Add remaining products not in top 6, keeping them below the perfect matches
          final selectedIds = result.map((p) => p['id']).toSet();
          final remaining = products.where((p) => !selectedIds.contains(p['id'])).toList();
          return [...result, ...remaining];
        }
      }
      return products; // fallback
    } catch (e) {
      AppLogger.error('❌ Erreur ou timeout lors du reranking Claude: $e', 'ClaudeApi');
      return products; // fallback au matching classique
    }
  }
}

