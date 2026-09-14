import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Audit de cohérence des filtres d\'événements et de genre DORÕN', () async {
    final file = File('assets/jsons/fallback_products.json');
    expect(file.existsSync(), true, reason: 'fallback_products.json must exist');
    final jsonStr = await file.readAsString();
    final List<dynamic> products = jsonDecode(jsonStr);

    print('📊 Total produits dans le catalogue : ${products.length}');

    // Test Fête des Mères
    final feteMeresProducts = products.where((p) {
      final tags = ((p['tags'] as List?)?.cast<dynamic>() ?? []).map((t) => t.toString().toLowerCase()).toSet();
      final cats = ((p['categories'] as List?)?.cast<dynamic>() ?? []).map((c) => c.toString().toLowerCase()).toSet();
      final pCat = (p['category'] ?? '').toString().toLowerCase();
      final allTags = {...tags, ...cats, if (pCat.isNotEmpty) pCat};
      final text = '${p['name']} ${p['brand']} ${p['description']}'.toLowerCase();

      final isMaleProduct = allTags.contains('gender_homme') ||
          allTags.contains('subcat_vetements_homme') ||
          allTags.contains('subcat_rasage_barbe') ||
          text.contains('pour homme') ||
          (text.contains('homme') && !text.contains('femme'));

      if (isMaleProduct) return false;

      return allTags.contains('gender_femme') ||
          allTags.contains('gender_mixte') ||
          allTags.contains('cat_beaute') ||
          allTags.contains('cat_bienetre') ||
          allTags.contains('subcat_bijoux') ||
          allTags.contains('subcat_sacs_maroquinerie') ||
          allTags.contains('subcat_ambiance_bougies_senteurs') ||
          allTags.contains('subcat_linge_maison') ||
          allTags.contains('subcat_deco_murale_objets') ||
          allTags.contains('subcat_cuisine_arts_de_la_table') ||
          allTags.contains('subcat_chocolats_confiseries') ||
          allTags.contains('subcat_cafe_the') ||
          allTags.contains('subcat_coffrets_degustation') ||
          allTags.contains('subcat_plantes_interieur_cache_pots') ||
          allTags.contains('subcat_parfum') ||
          allTags.contains('subcat_soin_visage') ||
          allTags.contains('subcat_soin_corps') ||
          allTags.contains('occasion_fete');
    }).toList();

    print('🌸 Produits trouvés pour "Fête des Mères" : ${feteMeresProducts.length}');
    for (final p in feteMeresProducts.take(10)) {
      final tags = (p['tags'] as List).cast<String>();
      expect(tags.contains('gender_homme'), false, reason: 'Produit masculin dans Fête des Mères : ${p['name']}');
      expect(tags.contains('subcat_vetements_homme'), false);
      expect(tags.contains('subcat_rasage_barbe'), false);
      print('   • [${p['category']} / ${p['subcategory']}] ${p['brand']} - ${p['name']} (${p['price']}€)');
    }

    // Test Fête des Pères
    final fetePeresProducts = products.where((p) {
      final tags = ((p['tags'] as List?)?.cast<dynamic>() ?? []).map((t) => t.toString().toLowerCase()).toSet();
      final cats = ((p['categories'] as List?)?.cast<dynamic>() ?? []).map((c) => c.toString().toLowerCase()).toSet();
      final pCat = (p['category'] ?? '').toString().toLowerCase();
      final allTags = {...tags, ...cats, if (pCat.isNotEmpty) pCat};
      final text = '${p['name']} ${p['brand']} ${p['description']}'.toLowerCase();

      final isFemaleProduct = allTags.contains('gender_femme') ||
          allTags.contains('subcat_vetements_femme') ||
          allTags.contains('subcat_lingerie_nuit') ||
          allTags.contains('subcat_maquillage') ||
          text.contains('pour femme');

      if (isFemaleProduct) return false;

      return allTags.contains('gender_homme') ||
          allTags.contains('gender_mixte') ||
          allTags.contains('cat_mecanique_auto') ||
          allTags.contains('cat_tech') ||
          allTags.contains('subcat_vins_spiritueux') ||
          allTags.contains('subcat_accessoires_sommellerie_bar') ||
          allTags.contains('subcat_montres_classiques') ||
          allTags.contains('subcat_vetements_homme') ||
          allTags.contains('subcat_rasage_barbe') ||
          allTags.contains('subcat_sacs_maroquinerie') ||
          allTags.contains('cat_sport') ||
          allTags.contains('cat_aeronautique') ||
          allTags.contains('subcat_massages_relaxation') ||
          allTags.contains('occasion_fete');
    }).toList();

    print('\n👔 Produits trouvés pour "Fête des Pères" : ${fetePeresProducts.length}');
    for (final p in fetePeresProducts.take(10)) {
      final tags = (p['tags'] as List).cast<String>();
      expect(tags.contains('gender_femme'), false, reason: 'Produit féminin dans Fête des Pères : ${p['name']}');
      expect(tags.contains('subcat_vetements_femme'), false);
      expect(tags.contains('subcat_lingerie_nuit'), false);
      expect(tags.contains('subcat_maquillage'), false);
      print('   • [${p['category']} / ${p['subcategory']}] ${p['brand']} - ${p['name']} (${p['price']}€)');
    }
  });
}
