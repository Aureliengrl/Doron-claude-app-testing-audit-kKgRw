import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:doron/services/product_matching_service.dart';

class _AllowAllHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _AllowAllHttpOverrides();

  test('Test getPersonalizedProducts returns live API products at the top', () async {
    final userProfile = {
      'personName': 'Lucas',
      'gender': 'Homme',
      'personGender': 'Homme',
      'age': '28',
      'personAge': '28',
      'recipientPersonality': ['Tech & Gadgets', 'Gamer'],
      'giftTypes': ['Objet physique'],
      'voiceDescription': 'Il adore les drones et la photo',
      'occasion': 'Anniversaire',
      'budgetTier': '100-200€',
    };

    final products = await ProductMatchingService.getPersonalizedProducts(
      userTags: userProfile,
      count: 30,
      filteringMode: 'person',
    );

    print('🎁 Total products returned: ${products.length}');
    final liveCount = products.where((p) => p['is_live'] == true || p['from_api'] == true).length;
    print('✨ Live products count in top 30: $liveCount');

    expect(products.isNotEmpty, true);
    expect(liveCount > 0, true);

    for (int i = 0; i < products.take(5).length; i++) {
      final p = products[i];
      print('[$i] ${p['name']} | Price: ${p['product_price'] ?? p['price']} | is_live: ${p['is_live']} | score: ${p['_matchScore']}');
    }

    expect(products.first['is_live'], true);
  });
}
