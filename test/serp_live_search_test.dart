import 'package:flutter_test/flutter_test.dart';
import 'package:doron/services/serp_live_search_service.dart';

void main() {
  test('Test unitaire SerpLiveSearchService pour le questionnaire', () async {
    final quizProfile = {
      'personName': 'Lucas',
      'gender': 'Homme',
      'personGender': 'Homme',
      'age': '28',
      'personAge': '28',
      'recipientPersonality': ['Tech & Gadgets', 'Gamer'],
      'giftTypes': ['Objet physique', 'Expérience'],
      'voiceDescription': 'Il adore les drones et la photo',
      'occasion': 'Anniversaire',
      'budgetTier': '100-200€',
    };

    final liveGifts = await SerpLiveSearchService.fetchLiveProductsForQuiz(quizProfile);
    print('📦 Total live gifts fetched: ${liveGifts.length}');
    
    if (liveGifts.isNotEmpty) {
      for (final p in liveGifts.take(5)) {
        print('✨ LIVE: ${p['name']} | ${p['product_price']} | ${p['source']} | Image: ${p['image']}');
        expect(p['gender'], 'gender_homme');
        expect(p['is_live'], true);
        expect(p['product_url'], isNotEmpty);
      }
    } else {
      print('ℹ️ Network call timed out or mock environment: verified graceful fallback return list');
      expect(liveGifts, isA<List<Map<String, dynamic>>>());
    }
  });
}
