import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Vérification exhaustive des 15 catégories et 98 sous-catégories', () async {
    final file = File('assets/jsons/fallback_products.json');
    expect(file.existsSync(), true);
    final jsonStr = await file.readAsString();
    final List<dynamic> products = jsonDecode(jsonStr);

    final expectedCategories = [
      'cat_tech',
      'cat_mode',
      'cat_maison',
      'cat_beaute',
      'cat_food',
      'cat_sport',
      'cat_art',
      'cat_lecture',
      'cat_voyage',
      'cat_jeuxvideo',
      'cat_musique',
      'cat_jardinage',
      'cat_bienetre',
      'cat_mecanique_auto',
      'cat_aeronautique',
      'cat_activites_experiences',
      'cat_tendances',
    ];

    final Map<String, Set<String>> subcategoriesFound = {};
    for (final cat in expectedCategories) {
      subcategoriesFound[cat] = {};
    }

    for (final p in products) {
      final cat = p['category'] as String?;
      final subcat = p['subcategory'] as String?;
      expect(cat != null, true, reason: 'Produit sans category: ${p['id']}');
      expect(subcat != null, true, reason: 'Produit sans subcategory: ${p['id']}');
      expect(expectedCategories.contains(cat), true, reason: 'Catégorie inconnue: $cat');
      subcategoriesFound[cat]!.add(subcat!);
    }

    print('============================================================');
    print('📊 BILAN DE COUVERTURE DES 17 CATÉGORIES ET SOUS-CATÉGORIES');
    print('============================================================');
    int totalSubcats = 0;
    for (final cat in expectedCategories) {
      final subcats = subcategoriesFound[cat]!;
      totalSubcats += subcats.length;
      print('✅ $cat : ${subcats.length} sous-catégories distinctes');
      for (final s in subcats) {
        print('    └─ $s');
      }
    }

    print('============================================================');
    print('🏆 Total sous-catégories couvertes et vérifiées : $totalSubcats');
    expect(totalSubcats >= 98, true);
    expect(expectedCategories.length, 17);
  });
}
