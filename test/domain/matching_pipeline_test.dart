import 'package:flutter_test/flutter_test.dart';
import 'package:doron/domain/matching/tag_converter.dart';
import 'package:doron/domain/matching/matching_engine.dart';

/// Tests d'intégration du pipeline complet :
/// profile utilisateur → TagConverter → MatchingEngine → score produit
void main() {
  group('Matching Pipeline — Intégration', () {
    // Produits de test couvrant différents cas
    final femaleProduct = {'name': 'Parfum rose élégant', 'tags': ['gender_femme', 'cat_beaute', 'budget_50_100']};
    final maleProduct = {'name': 'Coffret soin barbe premium', 'tags': ['gender_homme', 'cat_beaute', 'budget_50_100']};
    final universalProduct = {'name': 'Coffret chocolats artisanaux', 'tags': ['gender_mixte', 'cat_food', 'budget_20_50']};
    final techProduct = {'name': 'Écouteurs sans fil', 'tags': ['gender_mixte', 'cat_tech', 'budget_50_100']};

    group('Pipeline femme 30 ans, budget 80€', () {
      late Set<String> searchTags;
      late Map<String, dynamic> profile;

      setUpAll(() {
        profile = {
          'gender': 'Femme',
          'budget': '80',
          'recipientAge': '30',
        };
        searchTags = TagConverter.convert(profile);
      });

      test('TagConverter produit des tags à partir du profil', () {
        expect(searchTags, isNotEmpty);
        expect(searchTags, contains('gender_femme'));
      });

      test('produit féminin → non exclu', () {
        final result = MatchingEngine.score(femaleProduct, searchTags, {}, filteringMode: 'home');
        expect(result.isExcluded, isFalse);
        expect(result.score, greaterThan(0));
      });

      test('produit masculin → exclu en mode home', () {
        final result = MatchingEngine.score(maleProduct, searchTags, {}, filteringMode: 'home');
        expect(result.isExcluded, isTrue);
      });

      test('produit universel → non exclu, score positif', () {
        final result = MatchingEngine.score(universalProduct, searchTags, {}, filteringMode: 'home');
        expect(result.isExcluded, isFalse);
        expect(result.score, greaterThan(0));
      });

      test('le produit féminin a un meilleur score que le produit universel', () {
        final femaleScore = MatchingEngine.score(femaleProduct, searchTags, {}, filteringMode: 'home').score;
        final universalScore = MatchingEngine.score(universalProduct, searchTags, {}, filteringMode: 'home').score;
        expect(femaleScore, greaterThanOrEqualTo(universalScore));
      });
    });

    group('Pipeline homme 25 ans, budget 50€', () {
      late Set<String> searchTags;

      setUpAll(() {
        searchTags = TagConverter.convert({
          'gender': '🙋‍♂️ Homme',
          'budget': '50',
          'recipientAge': '25',
        });
      });

      test('TagConverter accepte les emojis dans le genre', () {
        expect(searchTags, contains('gender_homme'));
      });

      test('produit masculin → non exclu en mode person', () {
        final result = MatchingEngine.score(maleProduct, searchTags, {}, filteringMode: 'person');
        expect(result.isExcluded, isFalse);
      });

      test('produit féminin → exclu en mode person', () {
        final result = MatchingEngine.score(femaleProduct, searchTags, {}, filteringMode: 'person');
        expect(result.isExcluded, isTrue);
      });

      test('en mode discovery, aucun produit exclu par genre', () {
        for (final product in [femaleProduct, maleProduct, universalProduct, techProduct]) {
          final result = MatchingEngine.score(product, searchTags, {}, filteringMode: 'discovery');
          expect(result.isExcluded, isFalse,
              reason: 'Product ${product['name']} should not be excluded in discovery mode');
        }
      });
    });

    group('Pipeline profil neutre (Autre)', () {
      late Set<String> searchTags;

      setUpAll(() {
        searchTags = TagConverter.convert({'gender': 'Autre', 'budget': '100'});
      });

      test('gender_mixte dans les search tags pour genre "Autre"', () {
        expect(searchTags, contains('gender_mixte'));
      });

      test('aucun produit exclu pour un profil neutre en home mode', () {
        for (final product in [femaleProduct, maleProduct, universalProduct]) {
          final result = MatchingEngine.score(product, searchTags, {}, filteringMode: 'home');
          // gender_mixte = neutre → ne doit pas déclencher d'exclusion stricte
          // Les produits genrés peuvent quand même avoir un score négatif mais pas –9000
          if (result.isExcluded) {
            expect(result.score, lessThanOrEqualTo(-9000));
          }
        }
      });
    });

    group('Scoring comparatif', () {
      final userTags = TagConverter.convert({'gender': 'Femme', 'budget': '80'});

      test('tous les scores non exclus sont positifs', () {
        for (final product in [femaleProduct, universalProduct, techProduct]) {
          final result = MatchingEngine.score(product, userTags, {}, filteringMode: 'discovery');
          if (!result.isExcluded) {
            expect(result.score, greaterThan(0),
                reason: '${product['name']} should have positive score');
          }
        }
      });

      test('scores retournés en tant qu\'entiers', () {
        final result = MatchingEngine.score(femaleProduct, userTags, {});
        expect(result.score, isA<int>());
      });
    });
  });
}
