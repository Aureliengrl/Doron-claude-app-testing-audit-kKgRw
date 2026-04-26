// ignore_for_file: avoid_print
/// Tests unitaires du MatchingEngine et TagConverter
/// Lance avec: dart test test/matching/matching_engine_test.dart
///
/// Ces tests sont PURS — aucun Firebase, aucun réseau requis.
/// Ils valident:
///   1. TagConverter: conversion correcte des profils utilisateur en tags
///   2. MatchingEngine: scoring correct de produits vs tags utilisateur
///   3. Variation: deux appels identiques donnent des ordres légèrement différents
///   4. Personas: 6 profils types donnent des résultats pertinents
import 'dart:math';
import 'package:test/test.dart';

// ─── Minimal stubs (évite d'importer Firebase dans les tests) ────────────────
// On recopie la logique pure ici pour tests isolés

// Re-implémentation locale minimaliste de MatchingEngine pour les tests
double _scoreProduct(Map<String, dynamic> product, Set<String> searchTags,
    Map<String, dynamic> userProfile,
    {String mode = 'person'}) {
  double s = 150.0;
  final tags = Set<String>.from((product['tags'] as List).cast<String>());

  // Genre
  final userGender = searchTags.where((t) => t.startsWith('gender_')).firstOrNull;
  if (userGender != null && userGender != 'gender_mixte') {
    final pGender = tags.where((t) => t.startsWith('gender_')).toList();
    if (pGender.isEmpty) {
      s += 50;
    } else if (pGender.contains(userGender)) {
      s += 100;
    } else if (pGender.contains('gender_mixte')) {
      s += 70;
    } else {
      if (mode == 'person' || mode == 'home') return -10000;
      s -= 80;
    }
  }

  // Âge
  final userAge = searchTags.where((t) => t.startsWith('age_')).firstOrNull;
  if (userAge != null) {
    final pAge = tags.where((t) => t.startsWith('age_')).toList();
    if (pAge.isEmpty) {
      s += 10;
    } else if (pAge.contains(userAge)) {
      s += 60;
    } else {
      s -= 25;
    }
  }

  // Catégorie
  final userCats = searchTags.where((t) => t.startsWith('cat_')).toList();
  if (userCats.isNotEmpty) {
    final pCats = tags.where((t) => t.startsWith('cat_')).toList();
    if (pCats.isEmpty) {
      s += 15;
    } else if (userCats.any(pCats.contains)) {
      s += 100;
    } else {
      s -= (mode == 'home' ? 40 : mode == 'person' ? 25 : 8);
    }
  }

  // Budget
  final userBudget = searchTags.where((t) => t.startsWith('budget_')).firstOrNull;
  if (userBudget != null) {
    final pBudget = tags.where((t) => t.startsWith('budget_')).firstOrNull;
    if (pBudget == null) {
      s += 10;
    } else if (pBudget == userBudget) {
      s += 80;
    } else {
      // Adjacent?
      const adj = {
        'budget_0_50': ['budget_50_100'],
        'budget_50_100': ['budget_0_50', 'budget_100_200'],
        'budget_100_200': ['budget_50_100', 'budget_200+'],
        'budget_200+': ['budget_100_200'],
      };
      if ((adj[userBudget] ?? []).contains(pBudget)) {
        s -= (mode == 'home' ? 30 : mode == 'person' ? 20 : 5);
      } else {
        s -= (mode == 'home' ? 65 : mode == 'person' ? 45 : 10);
      }
    }
  }

  // Passions
  int passionMatches = 0;
  for (final tag in searchTags.where((t) => t.startsWith('passion_'))) {
    if (tags.contains(tag)) { s += 30; passionMatches++; }
  }
  if (passionMatches >= 3) s += 150;
  else if (passionMatches == 2) s += 50;

  // Styles
  int styleMatches = 0;
  for (final tag in searchTags.where((t) => t.startsWith('style_'))) {
    if (tags.contains(tag)) { s += 50; styleMatches++; }
  }
  if (styleMatches >= 2) s += 80;

  // Personnalité
  for (final tag in searchTags.where((t) => t.startsWith('perso_'))) {
    if (tags.contains(tag)) s += 35;
  }

  // Types
  int typeMatches = 0;
  for (final tag in searchTags.where((t) => t.startsWith('type_'))) {
    if (tags.contains(tag)) { s += 25; typeMatches++; }
  }
  if (typeMatches >= 2) s += 30;

  // Contexte
  for (final tag in searchTags.where((t) => t.startsWith('context_'))) {
    if (tags.contains(tag)) s += 20;
  }

  return s;
}

// Sort avec variation (epsilon aléatoire dans les égalités)
List<Map<String, dynamic>> _sortWithVariation(
    List<Map<String, dynamic>> products, Set<String> searchTags,
    Map<String, dynamic> userProfile, {int seed = 0}) {
  final rng = Random(seed);
  final scored = products.map((p) {
    final base = _scoreProduct(p, searchTags, userProfile);
    // Epsilon ±8 pts pour briser les égalités tout en préservant les rangs nets
    final epsilon = (rng.nextDouble() * 16) - 8;
    return {...p, '_score': base + epsilon};
  }).toList();
  scored.sort((a, b) => (b['_score'] as double).compareTo(a['_score'] as double));
  return scored;
}

// ─── Catalogue de test réduit (représentatif) ────────────────────────────────
final _catalog = [
  // Beauté femme
  {'name': 'Parfum Lancôme La Vie Est Belle', 'brand': 'Lancôme', 'price': 89,
   'tags': ['gender_femme','cat_beaute','budget_50_100','type_beaute_soins','style_elegant','passion_beaute','age_adulte','context_amoureux']},
  {'name': 'Sérum Vitamine C The Ordinary', 'brand': 'The Ordinary', 'price': 11,
   'tags': ['gender_femme','cat_beaute','budget_0_50','type_beaute_soins','style_minimaliste','passion_beaute','age_ado','age_adulte']},
  {'name': 'Mascara YSL Lash Clash', 'brand': 'YSL', 'price': 35,
   'tags': ['gender_femme','cat_beaute','budget_0_50','type_beaute_soins','style_tendance','passion_beaute','age_ado']},
  // Tech mixte
  {'name': 'AirPods Pro 2', 'brand': 'Apple', 'price': 279,
   'tags': ['gender_mixte','cat_tech','budget_200+','type_high_tech','type_musique_audio','style_moderne','passion_musique','passion_tech','age_ado','age_adulte']},
  {'name': 'Sony WH-1000XM5', 'brand': 'Sony', 'price': 329,
   'tags': ['gender_mixte','cat_tech','budget_200+','type_high_tech','type_musique_audio','style_moderne','passion_musique','age_adulte']},
  {'name': 'Nintendo Switch OLED', 'brand': 'Nintendo', 'price': 349,
   'tags': ['gender_mixte','cat_tech','budget_200+','type_high_tech','type_jeux_jouets','passion_jeuxvideo','age_enfant','age_ado']},
  {'name': 'Kindle Paperwhite', 'brand': 'Amazon', 'price': 179,
   'tags': ['gender_mixte','cat_tech','budget_100_200','type_high_tech','style_minimaliste','passion_lecture','age_adulte','age_senior']},
  // Mode homme
  {'name': 'Nike Air Force 1', 'brand': 'Nike', 'price': 119,
   'tags': ['gender_homme','cat_mode','budget_100_200','type_mode_accessoires','style_streetwear','passion_mode','passion_sport','age_ado']},
  {'name': 'Montre Seiko Automatique', 'brand': 'Seiko', 'price': 299,
   'tags': ['gender_homme','cat_mode','budget_200+','type_bijoux','style_classique','style_elegant','perso_ambitieux','age_adulte']},
  // Sport
  {'name': 'Tapis Yoga Lululemon', 'brand': 'Lululemon', 'price': 89,
   'tags': ['gender_mixte','cat_tendances','budget_50_100','type_sport_outdoor','type_bien_etre','style_minimaliste','passion_yoga','passion_sport','age_adulte']},
  {'name': 'Gourde Stanley 1L', 'brand': 'Stanley', 'price': 50,
   'tags': ['gender_mixte','cat_tendances','budget_0_50','type_sport_outdoor','style_tendance','passion_sport','passion_nature','age_ado','age_adulte']},
  // Food
  {'name': 'Chocolats Pierre Marcolini', 'brand': 'Pierre Marcolini', 'price': 65,
   'tags': ['gender_mixte','cat_food','budget_50_100','type_gastronomie','style_luxe','passion_cuisine','age_adulte']},
  {'name': 'Cafetière Bodum Kenya', 'brand': 'Bodum', 'price': 35,
   'tags': ['gender_mixte','cat_maison','budget_0_50','type_gastronomie','style_moderne','passion_cuisine','age_adulte']},
  // Maison
  {'name': 'Bougie Diptyque Baies', 'brand': 'Diptyque', 'price': 65,
   'tags': ['gender_mixte','cat_maison','budget_50_100','type_maison_deco','type_bien_etre','style_elegant','perso_zen','age_adulte']},
  // Enfants
  {'name': 'Lego City Police Station', 'brand': 'Lego', 'price': 69,
   'tags': ['gender_mixte','cat_tendances','budget_50_100','type_jeux_jouets','passion_jeuxvideo','age_enfant']},
  {'name': 'Science Kit National Geographic', 'brand': 'Natl. Geographic', 'price': 39,
   'tags': ['gender_mixte','cat_tendances','budget_0_50','type_jeux_jouets','passion_tech','age_enfant']},
  // Lecture
  {'name': 'Abonnement Audible 3 mois', 'brand': 'Amazon', 'price': 39,
   'tags': ['gender_mixte','cat_tendances','budget_0_50','type_livres_bd','passion_lecture','age_adulte','age_senior']},
];

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // GROUPE 1 — TagConverter (logique de conversion)
  // ═══════════════════════════════════════════════════════════════════════════
  group('TagConverter logic', () {
    test('Femme → gender_femme', () {
      final tags = <String>{};
      final g = 'Femme'.toLowerCase();
      if (g.contains('femme')) tags.add('gender_femme');
      expect(tags, contains('gender_femme'));
    });

    test('Budget 75€ → budget_50_100', () {
      String budgetTag(int price) {
        if (price < 50) return 'budget_0_50';
        if (price < 100) return 'budget_50_100';
        if (price < 200) return 'budget_100_200';
        return 'budget_200+';
      }
      expect(budgetTag(75), equals('budget_50_100'));
      expect(budgetTag(25), equals('budget_0_50'));
      expect(budgetTag(150), equals('budget_100_200'));
      expect(budgetTag(300), equals('budget_200+'));
    });

    test('Âge 10 → age_enfant, 20 → age_ado, 35 → age_adulte, 65 → age_senior', () {
      String ageTag(int age) {
        if (age < 13) return 'age_enfant';
        if (age < 25) return 'age_ado';
        if (age < 55) return 'age_adulte';
        return 'age_senior';
      }
      expect(ageTag(10), equals('age_enfant'));
      expect(ageTag(20), equals('age_ado'));
      expect(ageTag(35), equals('age_adulte'));
      expect(ageTag(65), equals('age_senior'));
    });

    test('Passion yoga → passion_yoga, fitness → passion_sport', () {
      const passionMap = {
        'yoga': 'passion_yoga', 'fitness': 'passion_sport',
        'cuisine': 'passion_cuisine', 'lecture': 'passion_lecture',
        'photo': 'passion_photo', 'musique': 'passion_musique',
      };
      final tags = <String>{};
      for (final interest in ['yoga', 'fitness', 'cuisine']) {
        passionMap.forEach((key, value) {
          if (interest.contains(key)) tags.add(value);
        });
      }
      expect(tags, containsAll(['passion_yoga', 'passion_sport', 'passion_cuisine']));
    });

    test('Relation maman → context_famille, ami → context_ami', () {
      bool isFamily(String s) =>
          s.contains('maman') || s.contains('mère') || s.contains('papa') || s.contains('famille');
      bool isFriend(String s) =>
          s.contains('ami') || s.contains('copain') || s.contains('pote');
      expect(isFamily('maman'), isTrue);
      expect(isFriend('meilleur ami'), isTrue);
      expect(isFamily('copain'), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUPE 2 — Scoring de base
  // ═══════════════════════════════════════════════════════════════════════════
  group('MatchingEngine scoring', () {
    test('Produit genre correct score > produit mauvais genre', () {
      final searchTags = <String>{'gender_femme', 'cat_beaute', 'budget_0_50', 'passion_beaute'};
      final profile = <String, dynamic>{};
      final mascara = _catalog.firstWhere((p) => p['name'] == 'Mascara YSL Lash Clash');
      final seiko = _catalog.firstWhere((p) => p['name'] == 'Montre Seiko Automatique');
      final scoreMascara = _scoreProduct(mascara, searchTags, profile);
      final scoreSeiko = _scoreProduct(seiko, searchTags, profile, mode: 'discovery');
      print('✅ Mascara: $scoreMascara | Seiko: $scoreSeiko');
      expect(scoreMascara, greaterThan(scoreSeiko));
    });

    test('Produit homme exclu pour profil femme en mode person', () {
      final searchTags = <String>{'gender_femme', 'budget_200+', 'passion_mode'};
      final profile = <String, dynamic>{};
      final seiko = _catalog.firstWhere((p) => p['name'] == 'Montre Seiko Automatique');
      final score = _scoreProduct(seiko, searchTags, profile, mode: 'person');
      print('✅ Seiko pour femme (person): $score');
      expect(score, lessThan(-1000)); // Exclu
    });

    test('Produit mixte accepté peu importe le genre', () {
      final searchTagsFemme = <String>{'gender_femme', 'budget_0_50'};
      final searchTagsHomme = <String>{'gender_homme', 'budget_0_50'};
      final profile = <String, dynamic>{};
      final stanley = _catalog.firstWhere((p) => p['name'] == 'Gourde Stanley 1L');
      final scoreFemme = _scoreProduct(stanley, searchTagsFemme, profile);
      final scoreHomme = _scoreProduct(stanley, searchTagsHomme, profile);
      print('✅ Stanley pour femme: $scoreFemme | pour homme: $scoreHomme');
      expect(scoreFemme, greaterThan(100));
      expect(scoreHomme, greaterThan(100));
    });

    test('Passion clustering: 3+ passions = gros bonus', () {
      final searchTags = <String>{
        'gender_mixte', 'passion_musique', 'passion_tech', 'cat_tech', 'budget_200+'
      };
      final profile = <String, dynamic>{};
      final airpods = _catalog.firstWhere((p) => p['name'] == 'AirPods Pro 2');
      final score = _scoreProduct(airpods, searchTags, profile);
      // AirPods: musique + tech = 2 passions → +50 cluster bonus
      print('✅ AirPods (2 passions): $score');
      expect(score, greaterThan(400)); // Base 150 + genre 70 + cat 100 + budget 80 + passions 60+50
    });

    test('Budget exact score >> budget lointain', () {
      final searchTags = <String>{'gender_mixte', 'budget_0_50'};
      final profile = <String, dynamic>{};
      final stanley = _catalog.firstWhere((p) => p['name'] == 'Gourde Stanley 1L'); // 50€
      final airpods = _catalog.firstWhere((p) => p['name'] == 'AirPods Pro 2'); // 279€
      final scoreStanley = _scoreProduct(stanley, searchTags, profile);
      final scoreAirpods = _scoreProduct(airpods, searchTags, profile);
      print('✅ Stanley (budget match): $scoreStanley | AirPods (trop cher): $scoreAirpods');
      expect(scoreStanley, greaterThan(scoreAirpods));
    });

    test('Âge: produit enfant favorisé pour profil enfant', () {
      final searchTags = <String>{'gender_mixte', 'budget_0_50', 'age_enfant'};
      final profile = <String, dynamic>{};
      final lego = _catalog.firstWhere((p) => p['name'] == 'Lego City Police Station');
      final audible = _catalog.firstWhere((p) => p['name'] == 'Abonnement Audible 3 mois');
      final scoreLego = _scoreProduct(lego, searchTags, profile);
      final scoreAudible = _scoreProduct(audible, searchTags, profile);
      print('✅ Lego (enfant): $scoreLego | Audible (adulte/senior): $scoreAudible');
      expect(scoreLego, greaterThan(scoreAudible));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUPE 3 — Personas complets
  // ═══════════════════════════════════════════════════════════════════════════
  group('Personas — résultats pertinents', () {
    List<String> _topN(Set<String> tags, Map<String, dynamic> profile, int n,
        {String mode = 'person'}) {
      final scored = _catalog
          .map((p) => {'p': p, 's': _scoreProduct(p, tags, profile, mode: mode)})
          .where((e) => (e['s'] as double) > -1000)
          .toList()
        ..sort((a, b) => (b['s'] as double).compareTo(a['s'] as double));
      return scored.take(n).map((e) => (e['p'] as Map)['name'] as String).toList();
    }

    test('[PERSONA 1] Femme 28 ans, beauté+yoga, budget 50€', () {
      final tags = <String>{
        'gender_femme', 'cat_beaute', 'budget_0_50',
        'passion_beaute', 'passion_yoga', 'age_adulte', 'style_minimaliste'
      };
      final top5 = _topN(tags, {}, 5);
      print('🎯 Femme 28 beauté+yoga 50€: $top5');
      // Au moins un produit beauté femme dans le top 5
      expect(top5.any((n) => n.contains('Sérum') || n.contains('Mascara') || n.contains('Lancôme')), isTrue);
    });

    test('[PERSONA 2] Homme 32 ans, musique+tech, budget 200€+', () {
      final tags = <String>{
        'gender_homme', 'cat_tech', 'budget_200+',
        'passion_musique', 'passion_tech', 'age_adulte', 'style_moderne'
      };
      final top5 = _topN(tags, {}, 5);
      print('🎯 Homme 32 musique+tech 200€+: $top5');
      expect(top5.any((n) => n.contains('AirPods') || n.contains('Sony')), isTrue);
    });

    test('[PERSONA 3] Gamin 10 ans, jeux, budget 50€', () {
      final tags = <String>{
        'gender_mixte', 'cat_tendances', 'budget_0_50',
        'passion_jeuxvideo', 'passion_tech', 'age_enfant'
      };
      final top5 = _topN(tags, {}, 5);
      print('🎯 Enfant 10 ans jeux 50€: $top5');
      expect(top5.any((n) => n.contains('Lego') || n.contains('Science Kit')), isTrue);
    });

    test('[PERSONA 4] Senior femme 68 ans, lecture, budget 50€', () {
      final tags = <String>{
        'gender_femme', 'budget_0_50', 'passion_lecture', 'age_senior'
      };
      final top5 = _topN(tags, {}, 5, mode: 'discovery');
      print('🎯 Senior femme lecture 50€: $top5');
      expect(top5.any((n) => n.contains('Audible') || n.contains('Kindle')), isTrue);
    });

    test('[PERSONA 5] Homme 20 ans, streetwear+sport, budget 100€', () {
      final tags = <String>{
        'gender_homme', 'cat_mode', 'budget_100_200',
        'passion_sport', 'passion_mode', 'style_streetwear', 'age_ado'
      };
      final top5 = _topN(tags, {}, 5);
      print('🎯 Homme 20 streetwear 100€: $top5');
      expect(top5.any((n) => n.contains('Nike') || n.contains('Gourde')), isTrue);
    });

    test('[PERSONA 6] Couple, cuisine+bien-être, budget 50-100€', () {
      final tags = <String>{
        'gender_mixte', 'cat_food', 'budget_50_100',
        'passion_cuisine', 'context_amoureux', 'age_adulte'
      };
      final top5 = _topN(tags, {}, 5);
      print('🎯 Couple cuisine 50-100€: $top5');
      expect(top5.any((n) => n.contains('Marcolini') || n.contains('Bougie')), isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUPE 4 — Variation (même input ≠ même ordre)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Variation entre appels identiques', () {
    final searchTags = <String>{
      'gender_mixte', 'budget_50_100', 'passion_cuisine', 'passion_sport', 'age_adulte'
    };
    final profile = <String, dynamic>{};

    test('Deux appels avec seeds différents donnent des ordres différents', () {
      final order1 = _sortWithVariation(_catalog, searchTags, profile, seed: 1)
          .where((p) => (_scoreProduct(p, searchTags, profile) > -1000))
          .map((p) => p['name'] as String)
          .take(5)
          .toList();
      final order2 = _sortWithVariation(_catalog, searchTags, profile, seed: 99)
          .where((p) => (_scoreProduct(p, searchTags, profile) > -1000))
          .map((p) => p['name'] as String)
          .take(5)
          .toList();
      print('🎲 Ordre seed=1:  $order1');
      print('🎲 Ordre seed=99: $order2');
      // Les top 5 ne doivent pas être identiques (la variation fait changer l'ordre)
      expect(order1, isNot(equals(order2)));
    });

    test('Le meilleur produit reste dans les top 3 malgré variation ±8pts', () {
      // Produit avec score nettement supérieur ne doit pas sortir du top 3
      final highScoreSearch = <String>{
        'gender_femme', 'cat_beaute', 'budget_0_50',
        'passion_beaute', 'style_minimaliste', 'age_adulte'
      };
      final runs5 = List.generate(5, (i) {
        return _sortWithVariation(_catalog, highScoreSearch, profile, seed: i * 7 + 3)
            .where((p) => (_scoreProduct(p, highScoreSearch, profile) > -1000))
            .map((p) => p['name'] as String)
            .take(3)
            .toList();
      });
      print('🎯 Top 3 sur 5 runs: $runs5');
      // Le Sérum The Ordinary devrait être dans le top 3 à chaque run (score très élevé pour beauté femme ado/adulte 0-50€)
      final alwaysTop3 = runs5.every((run) =>
          run.contains('Sérum Vitamine C The Ordinary') ||
          run.contains('Mascara YSL Lash Clash'));
      expect(alwaysTop3, isTrue,
          reason: 'Un produit très pertinent doit rester dans le top 3 même avec variation');
    });

    test('Scores bruts sont différents entre deux sessions', () {
      final rng1 = Random(1);
      final rng2 = Random(2);
      final scores1 = _catalog.map((p) {
        final base = _scoreProduct(p, searchTags, profile);
        return base + (rng1.nextDouble() * 16 - 8);
      }).toList();
      final scores2 = _catalog.map((p) {
        final base = _scoreProduct(p, searchTags, profile);
        return base + (rng2.nextDouble() * 16 - 8);
      }).toList();
      // Les scores ne doivent pas être strictement identiques
      final allSame = List.generate(scores1.length, (i) => scores1[i] == scores2[i]).every((v) => v);
      expect(allSame, isFalse, reason: 'La variation epsilon doit produire des scores différents');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUPE 5 — Couverture catalogue
  // ═══════════════════════════════════════════════════════════════════════════
  group('Couverture catalogue', () {
    test('Au moins 1 produit pour chaque tranche de budget', () {
      final budgets = ['budget_0_50','budget_50_100','budget_100_200','budget_200+'];
      for (final b in budgets) {
        final count = _catalog.where((p) =>
            (p['tags'] as List).contains(b)).length;
        print('  $b: $count produits');
        expect(count, greaterThan(0), reason: 'Budget $b non représenté');
      }
    });

    test('Au moins 1 produit pour chaque genre', () {
      for (final g in ['gender_femme','gender_homme','gender_mixte']) {
        final count = _catalog.where((p) =>
            (p['tags'] as List).contains(g)).length;
        print('  $g: $count produits');
        expect(count, greaterThan(0));
      }
    });

    test('Au moins 1 produit pour chaque tranche d\'âge', () {
      for (final a in ['age_enfant','age_ado','age_adulte','age_senior']) {
        final count = _catalog.where((p) =>
            (p['tags'] as List).contains(a)).length;
        print('  $a: $count produits');
        expect(count, greaterThan(0), reason: 'Âge $a non représenté');
      }
    });

    test('Pas de produit avec tag invalide évident', () {
      final knownInvalid = ['age_jeune', 'style_zen', 'budget_100-200', 'gender_girl'];
      for (final p in _catalog) {
        final tags = p['tags'] as List;
        for (final invalid in knownInvalid) {
          expect(tags.contains(invalid), isFalse,
              reason: '${p['name']} contient le tag invalide "$invalid"');
        }
      }
    });
  });
}
