const fs = require('fs');
const path = 'lib/services/claude_api_service.dart';
let content = fs.readFileSync(path, 'utf8');

const newMethods = `
  /// Appelle la Cloud Function 'generateBrands' et retourne une liste de marques
  static Future<List<String>> generatePersonalizedBrands(int age, List<String> domains) async {
    try {
      AppLogger.info('🤖 Appel de l\\'API Claude pour générer des marques...', 'ClaudeApi');
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('generateBrands');
      final response = await callable.call(<String, dynamic>{
        'age': age,
        'domains': domains,
      });
      final data = response.data;
      if (data != null && data['brands'] != null) {
        final List<dynamic> brandsDynamic = data['brands'];
        final List<String> brandsList = brandsDynamic.map((e) => e.toString()).toList();
        AppLogger.info('✅ Claude a généré \${brandsList.length} marques.', 'ClaudeApi');
        return brandsList;
      }
      return [];
    } catch (e) {
      AppLogger.error('❌ Erreur lors de l\\'appel à Claude (marques): $e', 'ClaudeApi');
      return [];
    }
  }

  /// Appelle la Cloud Function 'generateEvents' et retourne une liste d'événements
  static Future<List<String>> generateUpcomingEvents(int age, List<String> domains) async {
    try {
      AppLogger.info('🤖 Appel de l\\'API Claude pour générer des événements...', 'ClaudeApi');
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('generateEvents');
      final response = await callable.call(<String, dynamic>{
        'age': age,
        'domains': domains,
      });
      final data = response.data;
      if (data != null && data['events'] != null) {
        final List<dynamic> eventsDynamic = data['events'];
        final List<String> eventsList = eventsDynamic.map((e) => e.toString()).toList();
        AppLogger.info('✅ Claude a généré \${eventsList.length} événements.', 'ClaudeApi');
        return eventsList;
      }
      return [];
    } catch (e) {
      AppLogger.error('❌ Erreur lors de l\\'appel à Claude (événements): $e', 'ClaudeApi');
      return [];
    }
  }
}
`;

if (!content.includes('generatePersonalizedBrands')) {
  content = content.replace(/}\s*$/, newMethods);
  fs.writeFileSync(path, content, 'utf8');
  console.log('claude_api_service updated successfully.');
} else {
  console.log('Methods already exist in claude_api_service.');
}
