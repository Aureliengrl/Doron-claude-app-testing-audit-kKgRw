import 'package:logger/logger.dart';

class AmazonAffiliationService {
  static const String amazonTag = 'doronapp130a-21';
  
  /// Transforme une URL classique Amazon en lien d'affiliation
  /// ou génère un lien de recherche si aucune URL n'est fournie.
  static String getAffiliateUrl(String? originalUrl, {String? searchQuery}) {
    if (originalUrl != null && originalUrl.isNotEmpty) {
      if (originalUrl.toLowerCase().contains('amazon.')) {
        try {
          final uri = Uri.parse(originalUrl);
          final Map<String, String> newParams = Map.from(uri.queryParameters);
          newParams['tag'] = amazonTag;
          
          final newUri = uri.replace(queryParameters: newParams);
          return newUri.toString();
        } catch (e) {
          // Fallback if parsing fails
          if (originalUrl.contains('✨')) {
            return '$originalUrl&tag=$amazonTag';
          } else {
            return '$originalUrl?tag=$amazonTag';
          }
        }
      }
      return originalUrl; // Not Amazon
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final encodedQuery = Uri.encodeComponent(searchQuery);
      return 'https://www.amazon.fr/s?k=$encodedQuery&tag=$amazonTag';
    }
    
    return 'https://www.amazon.fr/?tag=$amazonTag';
  }
}
