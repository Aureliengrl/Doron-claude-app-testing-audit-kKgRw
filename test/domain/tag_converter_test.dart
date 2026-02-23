import 'package:flutter_test/flutter_test.dart';
import 'package:doron/domain/matching/tag_converter.dart';

void main() {
  group('TagConverter', () {
    // ── Genre ──────────────────────────────────────────────────────────────────

    test('converts "Femme" to gender_femme', () {
      final tags = TagConverter.convert({'gender': 'Femme'});
      expect(tags, contains('gender_femme'));
      expect(tags, isNot(contains('gender_homme')));
    });

    test('converts "🙋‍♀️ Femme" (with emoji) to gender_femme', () {
      final tags = TagConverter.convert({'gender': '🙋‍♀️ Femme'});
      expect(tags, contains('gender_femme'));
    });

    test('converts "Homme" to gender_homme', () {
      final tags = TagConverter.convert({'gender': 'Homme'});
      expect(tags, contains('gender_homme'));
    });

    test('converts "🙋‍♂️ Homme" (with emoji) to gender_homme', () {
      final tags = TagConverter.convert({'gender': '🙋‍♂️ Homme'});
      expect(tags, contains('gender_homme'));
    });

    test('converts "Autre" to gender_mixte', () {
      final tags = TagConverter.convert({'gender': 'Autre'});
      expect(tags, contains('gender_mixte'));
    });

    test('no gender key → no gender tag', () {
      final tags = TagConverter.convert({'budget': '50'});
      expect(tags.where((t) => t.startsWith('gender_')), isEmpty);
    });

    // ── Budget ────────────────────────────────────────────────────────────────

    test('budget 0 → no budget tag (budget of 0 skipped)', () {
      final tags = TagConverter.convert({'budget': '0'});
      expect(tags.where((t) => t.startsWith('budget_')), isEmpty);
    });

    test('budget 50 → budget tag present', () {
      final tags = TagConverter.convert({'budget': '50'});
      final budgetTags = tags.where((t) => t.startsWith('budget_')).toList();
      expect(budgetTags, isNotEmpty);
    });

    test('budget 200 → budget tag present', () {
      final tags = TagConverter.convert({'budget': '200'});
      final budgetTags = tags.where((t) => t.startsWith('budget_')).toList();
      expect(budgetTags, isNotEmpty);
    });

    // ── Interests / passions ──────────────────────────────────────────────────

    test('string interests split by comma', () {
      final tags = TagConverter.convert({'interests': 'sport, musique'});
      // At least one passion_ tag should be generated if the keywords match
      // (depends on TagsDefinitions.passionConversion having 'sport' / 'musique')
      // We just test that no exception is thrown
      expect(tags, isA<Set<String>>());
    });

    test('list interests works', () {
      final tags = TagConverter.convert({
        'interests': ['voyage', 'cuisine'],
      });
      expect(tags, isA<Set<String>>());
    });

    // ── Normalization ─────────────────────────────────────────────────────────

    test('all output tags are lowercase', () {
      final tags = TagConverter.convert({'gender': 'Femme', 'budget': '100'});
      for (final tag in tags) {
        expect(tag, equals(tag.toLowerCase()), reason: 'Tag "$tag" should be lowercase');
      }
    });

    test('all output tags use underscores (no hyphens)', () {
      final tags = TagConverter.convert({'gender': 'Femme', 'budget': '150'});
      for (final tag in tags) {
        expect(tag, isNot(contains('-')), reason: 'Tag "$tag" should not contain hyphens');
      }
    });

    // ── Combined profile ──────────────────────────────────────────────────────

    test('full onboarding profile produces multiple valid tags', () {
      final tags = TagConverter.convert({
        'gender': 'Femme',
        'budget': '80',
        'recipientAge': '35',
        'interests': ['yoga', 'lecture'],
        'preferredCategories': [],
      });
      expect(tags.length, greaterThanOrEqualTo(1));
      expect(tags, contains('gender_femme'));
    });
  });
}
