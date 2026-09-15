import 'package:flutter_test/flutter_test.dart';
import 'package:doron/domain/matching/matching_engine.dart';

void main() {
  group('MatchingEngine', () {
    // ── Hard exclusions ────────────────────────────────────────────────────────

    group('gender hard exclusion', () {
      final feminineProductTags = {
        'tags': ['gender_femme'],
      };
      final masculineProductTags = {
        'tags': ['gender_homme'],
      };
      final universalProductTags = {
        'tags': ['gender_mixte'],
      };
      final noGenderProductTags = {
        'name': 'Coffret thé premium',
        'tags': <String>[],
      };

      test('male user + female product → excluded in home mode', () {
        final result = MatchingEngine.score(
          feminineProductTags,
          {'gender_homme'},
          {},
          filteringMode: 'home',
        );
        expect(result.isExcluded, isTrue);
      });

      test('female user + male product → excluded in home mode', () {
        final result = MatchingEngine.score(
          masculineProductTags,
          {'gender_femme'},
          {},
          filteringMode: 'home',
        );
        expect(result.isExcluded, isTrue);
      });

      test('male user + female product → excluded in person mode', () {
        final result = MatchingEngine.score(
          feminineProductTags,
          {'gender_homme'},
          {},
          filteringMode: 'person',
        );
        expect(result.isExcluded, isTrue);
      });

      test('male user + female product → strictly excluded in discovery mode (0% leakage)', () {
        final result = MatchingEngine.score(
          feminineProductTags,
          {'gender_homme'},
          {},
          filteringMode: 'discovery',
        );
        expect(result.isExcluded, isTrue);
        expect(result.score, lessThanOrEqualTo(-9000));
      });

      test('universal product → not excluded for any user', () {
        for (final mode in ['home', 'person', 'discovery']) {
          final maleResult = MatchingEngine.score(
            universalProductTags,
            {'gender_homme'},
            {},
            filteringMode: mode,
          );
          expect(maleResult.isExcluded, isFalse, reason: 'Mode: $mode');

          final femaleResult = MatchingEngine.score(
            universalProductTags,
            {'gender_femme'},
            {},
            filteringMode: mode,
          );
          expect(femaleResult.isExcluded, isFalse, reason: 'Mode: $mode');
        }
      });

      test('product sans genre → not excluded (treated as universal)', () {
        final result = MatchingEngine.score(
          noGenderProductTags,
          {'gender_homme'},
          {},
          filteringMode: 'home',
        );
        expect(result.isExcluded, isFalse);
      });
    });

    // ── Name-based strong exclusion ────────────────────────────────────────────

    test('product with strongly feminine name (lingerie) excluded for male user', () {
      final product = {'name': 'Set de lingerie premium', 'tags': <String>[]};
      final result = MatchingEngine.score(
        product,
        {'gender_homme'},
        {},
        filteringMode: 'home',
      );
      expect(result.isExcluded, isTrue);
    });

    test('product with strongly masculine name (tondeuse barbe) excluded for female', () {
      final product = {'name': 'Tondeuse barbe professionnelle', 'tags': <String>[]};
      final result = MatchingEngine.score(
        product,
        {'gender_femme'},
        {},
        filteringMode: 'home',
      );
      expect(result.isExcluded, isTrue);
    });

    // ── Scoring positif ────────────────────────────────────────────────────────

    test('gender match gives higher score than no gender', () {
      final femaleProduct = {'tags': ['gender_femme']};
      final noGenderProduct = {'name': 'Coffret bien-être', 'tags': <String>[]};

      final matchScore = MatchingEngine.score(
        femaleProduct,
        {'gender_femme'},
        {},
        filteringMode: 'discovery',
      ).score;
      final noMatchScore = MatchingEngine.score(
        noGenderProduct,
        {'gender_femme'},
        {},
        filteringMode: 'discovery',
      ).score;

      expect(matchScore, greaterThan(noMatchScore));
    });

    test('all products start with positive base score', () {
      final product = {'name': 'Produit', 'tags': <String>[]};
      final result = MatchingEngine.score(product, {}, {});
      // Base = 150, no gender tags means +50 for universal → 200
      expect(result.score, greaterThan(0));
    });

    // ── ScoredProduct ─────────────────────────────────────────────────────────

    test('isExcluded is false for score > -9000', () {
      final product = {'tags': ['gender_femme']};
      final result = MatchingEngine.score(
        product,
        {'gender_femme'},
        {},
        filteringMode: 'home',
      );
      expect(result.isExcluded, isFalse);
      expect(result.score, greaterThan(0));
    });

    test('isExcluded is true for score <= -9000', () {
      final product = {'tags': ['gender_homme']};
      final result = MatchingEngine.score(
        product,
        {'gender_femme'},
        {},
        filteringMode: 'home',
      );
      expect(result.isExcluded, isTrue);
      expect(result.score, lessThanOrEqualTo(-9000));
    });
  });
}
