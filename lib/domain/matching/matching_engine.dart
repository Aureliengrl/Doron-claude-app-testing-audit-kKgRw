import '/utils/app_logger.dart';
import '/services/tags_definitions.dart';

/// Résultat du scoring d'un produit par rapport à un profil utilisateur.
class ScoredProduct {
  final Map<String, dynamic> product;
  final double score;

  const ScoredProduct({required this.product, required this.score});

  /// Retourne true si le produit a été exclu (score très négatif).
  bool get isExcluded => score <= -9000.0;
}

/// Moteur de scoring v2 — calcule le score de pertinence de chaque produit
/// vis-à-vis d'un profil utilisateur.
///
/// Cette classe est **pure** — aucun appel réseau, aucun effet de bord.
/// Elle peut être testée unitairement de manière exhaustive.
///
/// ### Paramètres de scoring v2
/// | Dimension | Points max | Mode |
/// |---|---|---|
/// | Genre match | +100 | Strict (exclusion en home/person) |
/// | Catégorie match | +100 | Scoring + pénalité |
/// | Budget exact | +80 | Scoring |
/// | Budget adjacent | –50 | Tolérance (pas exclu) |
/// | Âge match | +60 | Scoring seulement |
/// | Passion clustering 3+ | +300 | Cumulatif |
/// | Passion match (1–2) | +30 / passion | Souple |
/// | Style match | +50 / style | Souple |
/// | Style cluster 2+ | +80 bonus | Cumulatif |
/// | Personnalité match | +35 / perso | Souple |
/// | Type cadeau match | +25 / type | Souple |
/// | Contexte (ami/famille) | +20 | Souple |
/// | Base bonus | +150 | Toujours |
class MatchingEngine {
  const MatchingEngine._();

  /// Score un produit par rapport aux tags de recherche.
  ///
  /// [product] : données brutes du produit Firebase
  /// [searchTags] : tags de recherche générés par [TagConverter.convert]
  /// [userProfile] : profil brut de l'utilisateur (pour âge, budget…)
  /// [filteringMode] : 'home', 'person', ou 'discovery'
  /// [categoryFilter] : filtre de catégorie actif (null = pas de filtre)
  ///
  /// Retourne un [ScoredProduct] avec le score calculé.
  /// Un score ≤ -9000 signifie que le produit est exclu.
  static ScoredProduct score(
    Map<String, dynamic> product,
    Set<String> searchTags,
    Map<String, dynamic> userProfile, {
    String filteringMode = 'discovery',
    String? categoryFilter,
    List<String> brandsSeen = const [],
  }) {
    double s = 150.0; // Bonus de base

    final allProductTags = _extractProductTags(product);
    final hasCategoryFilter = categoryFilter != null &&
        categoryFilter != 'Pour toi' &&
        categoryFilter != 'all';
    final isHome = filteringMode == 'home';
    final isPerson = filteringMode == 'person';
    final isDiscovery = filteringMode == 'discovery';

    // ── 1. Genre (hard exclusion possible) ──────────────────────────────────
    s = _scoreGender(s, searchTags, allProductTags, product, isHome, isPerson,
        hasCategoryFilter, isDiscovery);
    if (s <= -9000) return ScoredProduct(product: product, score: s);

    // ── 2. Âge ──────────────────────────────────────────────────────────────
    s = _scoreAge(s, userProfile, searchTags, allProductTags);

    // ── 3. Catégorie ─────────────────────────────────────────────────────────
    s = _scoreCategory(s, searchTags, allProductTags, isHome, isPerson,
        hasCategoryFilter);

    // ── 4. Budget (avec tolérance adjacente) ─────────────────────────────────
    s = _scoreBudget(
        s, searchTags, allProductTags, product, isHome, isPerson, isDiscovery);

    // ── 5. Passions (clustering) ─────────────────────────────────────────────
    s = _scorePassions(s, searchTags, allProductTags);

    // ── 6. Styles (clustering) ───────────────────────────────────────────────
    s = _scoreStyles(s, searchTags, allProductTags);

    // ── 7. Personnalité ──────────────────────────────────────────────────────
    s = _scorePersonality(s, searchTags, allProductTags);

    // ── 8. Types de cadeaux ─────────────────────────────────────────────────
    s = _scoreGiftTypes(s, searchTags, allProductTags);

    // ── 9. Contexte (relation) ───────────────────────────────────────────────
    s = _scoreContext(s, searchTags, allProductTags);

    // ── 10. Occasion (nouv.) ─────────────────────────────────────────────────
    s = _scoreOccasion(s, searchTags, allProductTags);

    // ── 11. Saison (nouv.) ────────────────────────────────────────────────────
    s = _scoreSaison(s, allProductTags);

    // ── 12. Prix inverse — trop cheap pour budget élevé (nouv.) ──────────────
    s = _scorePrixInverse(s, searchTags, product);

    // ── 13. Popularité (nouv.) ────────────────────────────────────────────────
    s = _scorePopularite(s, allProductTags);

    // ── 14. Exclusion intime en contexte collègue (nouv.) ─────────────────────
    s = _scoreContextIntime(s, searchTags, allProductTags);

    // ── 15. Anti-doublon marque (nouv.) ──────────────────────────────────────
    s = _scoreBrandSeen(s, product, brandsSeen);

    AppLogger.debug(
      'Score "${product['name']}": ${s.toStringAsFixed(0)} pts '
      '(${allProductTags.length} tags, mode=$filteringMode)',
      'MatchingEngine',
    );
    return ScoredProduct(product: product, score: s);
  }

  // ---
  // Extraction des tags produit
  // ---

  static Set<String> _extractProductTags(Map<String, dynamic> product) {
    final tags = (product['tags'] as List?)?.cast<String>() ?? <String>[];
    final cats = (product['categories'] as List?)?.cast<String>() ?? <String>[];
    return {...tags, ...cats}
        .map((t) => t.toLowerCase().replaceAll('-', '_'))
        .toSet();
  }

  // ---
  // 1. Genre
  // ---

  static double _scoreGender(
    double s,
    Set<String> searchTags,
    Set<String> productTags,
    Map<String, dynamic> product,
    bool isHome,
    bool isPerson,
    bool hasCategoryFilter,
    bool isDiscovery,
  ) {
    final userGenderTags = searchTags.where((t) => t.startsWith('gender_')).toList();
    if (userGenderTags.isEmpty) return s + 50.0; // Pas de préférence → universel

    final userGender = userGenderTags.first.toLowerCase();
    // gender_mixte côté utilisateur → pas d'exclusion stricte
    if (userGender == 'gender_mixte') return s + 40.0;

    final productGenderTags = productTags.where((t) => t.startsWith('gender_')).toList();

    if (productGenderTags.isEmpty) {
      // Pas de tag genre → déduction depuis le nom du produit
      final name = (product['name'] ?? '').toString().toLowerCase();
      if (userGender == 'gender_homme' && _isStronglyFeminine(name)) return -10000.0;
      if (userGender == 'gender_femme' && _isStronglyMasculine(name)) return -10000.0;
      return s + 50.0; // Produit universel
    }

    // Exclusions par sous-catégories spécifiques au genre opposé
    if (userGender == 'gender_femme') {
      if (productTags.contains('subcat_vetements_homme') ||
          productTags.contains('subcat_rasage_barbe')) {
        return -10000.0;
      }
    } else if (userGender == 'gender_homme') {
      if (productTags.contains('subcat_vetements_femme') ||
          productTags.contains('subcat_lingerie_nuit') ||
          productTags.contains('subcat_maquillage')) {
        return -10000.0;
      }
    }

    if (productGenderTags.contains(userGender)) return s + 100.0; // Match exact
    if (productGenderTags.contains('gender_mixte')) return s + 70.0; // Mixte OK

    // Règle DORÕN : exclusion absolue pour le genre opposé (ex: chemise homme pour femme)
    return -10000.0;
  }

  static bool _isStronglyFeminine(String name) {
    const kw = [
      'robe de soirée', 'jupe', 'lingerie', 'soutien-gorge',
      'culotte femme', 'collant', 'maquillage', 'rouge à lèvres', 'mascara',
      'eye-liner', 'fond de teint', 'blush', 'highlighter', 'contouring',
    ];
    return kw.any(name.contains);
  }

  static bool _isStronglyMasculine(String name) {
    const kw = [
      'cravate', 'rasoir électrique', 'tondeuse barbe', 'after shave',
      'costume homme', 'tondeuse à barbe', 'rasage homme', 'gel après-rasage',
    ];
    return kw.any(name.contains);
  }

  // ---
  // 2. Âge
  // ---

  static double _scoreAge(
    double s,
    Map<String, dynamic> userProfile,
    Set<String> searchTags,
    Set<String> productTags,
  ) {
    // Chercher age tag dans searchTags en priorité, puis dans userProfile
    final ageTagFromSearch = searchTags.where((t) => t.startsWith('age_')).firstOrNull;

    String? userAgeTag = ageTagFromSearch;
    if (userAgeTag == null) {
      final age = (userProfile['age'] ?? userProfile['recipientAge'])?.toString() ?? '';
      if (age.isNotEmpty) {
        final ageInt = int.tryParse(age) ?? 0;
        if (ageInt > 0) {
          userAgeTag = ageInt < 13
              ? 'age_enfant'
              : ageInt < 25
                  ? 'age_ado'
                  : ageInt < 50
                      ? 'age_adulte'
                      : 'age_senior';
        }
      }
    }

    if (userAgeTag == null) return s;

    final productAgeTags = productTags.where((t) => t.startsWith('age_')).toList();
    if (productAgeTags.isEmpty) return s + 10.0; // Universel → léger bonus
    if (productAgeTags.contains(userAgeTag)) return s + 60.0; // Match parfait

    // Âge adjacent : enfant↔ado ou adulte↔senior → pénalité légère
    const adjacent = {
      'age_enfant': 'age_ado',
      'age_ado': 'age_enfant',
      'age_adulte': 'age_senior',
      'age_senior': 'age_adulte',
    };
    if (productAgeTags.contains(adjacent[userAgeTag])) return s - 10.0;
    return s - 25.0; // Mauvaise tranche d'âge
  }

  // ---
  // 3. Catégorie
  // ---

  static double _scoreCategory(
    double s,
    Set<String> searchTags,
    Set<String> productTags,
    bool isHome,
    bool isPerson,
    bool hasCategoryFilter,
  ) {
    final userCats = searchTags.where((t) => t.startsWith('cat_')).toList();
    if (userCats.isEmpty) return s;

    final productCats = productTags.where((t) => t.startsWith('cat_')).toList();
    if (productCats.isEmpty) return s + 15.0; // Pas de catégorie produit → neutre

    // Match sur n'importe quelle catégorie préférée
    for (final userCat in userCats) {
      if (productCats.contains(userCat)) return s + 100.0;
    }

    // Pas de match
    if (hasCategoryFilter && isHome) return s - 60.0; // Filtre actif = pénalité forte
    if (isHome) return s - 40.0;
    if (isPerson) return s - 25.0;
    return s - 8.0; // Discovery : très souple
  }

  // ---
  // 4. Budget — avec tolérance adjacente
  // ---

  static double _scoreBudget(
    double s,
    Set<String> searchTags,
    Set<String> productTags,
    Map<String, dynamic> product,
    bool isHome,
    bool isPerson,
    bool isDiscovery,
  ) {
    final userBudgets = searchTags.where((t) => t.startsWith('budget_')).toList();
    if (userBudgets.isEmpty) return s;

    final userBudget = userBudgets.first.toLowerCase();
    final productBudgetTags = productTags.where((t) => t.startsWith('budget_')).toList();

    String effectiveBudget;
    if (productBudgetTags.isEmpty) {
      final price = product['price'];
      if (price == null) return s + 10.0;
      final priceInt = price is int ? price : (price is double ? price.toInt() : 0);
      effectiveBudget = TagsDefinitions.getBudgetTagFromPrice(priceInt).toLowerCase();
    } else {
      effectiveBudget = productBudgetTags.first.toLowerCase();
    }

    if (effectiveBudget == userBudget) return s + 80.0; // Match exact

    // Tolérance adjacente (tranche voisine = pénalité légère, PAS d'exclusion)
    const adjacentBudgets = {
      'budget_0_50': ['budget_50_100'],
      'budget_50_100': ['budget_0_50', 'budget_100_200'],
      'budget_100_200': ['budget_50_100', 'budget_200+'],
      'budget_200+': ['budget_100_200'],
    };
    final adjacents = adjacentBudgets[userBudget] ?? [];
    if (adjacents.contains(effectiveBudget)) {
      // Adjacent : pas d'exclusion, pénalité modérée
      if (isHome) return s - 30.0;
      if (isPerson) return s - 20.0;
      return s - 5.0;
    }

    // Budget très différent (2+ tranches d'écart)
    if (isHome) return s - 65.0;
    if (isPerson) return s - 45.0;
    if (isDiscovery) return s - 10.0;
    return s - 35.0;
  }

  // ---
  // 5. Passions — clustering avec bonus cumulatif
  // ---

  static double _scorePassions(
      double s, Set<String> searchTags, Set<String> productTags) {
    final userPassions = searchTags.where((t) => t.startsWith('passion_')).toList();
    if (userPassions.isEmpty) return s;

    int matchCount = 0;
    for (final passion in userPassions) {
      if (productTags.contains(passion)) {
        s += 30.0; // +30 par passion matchée
        matchCount++;
      }
    }

    // Bonus de clustering : 3+ passions matchées = le produit est très pertinent
    if (matchCount >= 3) s += 150.0;
    else if (matchCount == 2) s += 50.0;

    return s;
  }

  // ---
  // 6. Styles — clustering avec bonus
  // ---

  static double _scoreStyles(
      double s, Set<String> searchTags, Set<String> productTags) {
    final userStyles = searchTags.where((t) => t.startsWith('style_')).toList();
    if (userStyles.isEmpty) return s;

    int matchCount = 0;
    for (final style in userStyles) {
      if (productTags.contains(style)) {
        s += 50.0;
        matchCount++;
      } else if (productTags.any((t) => t.startsWith('style_'))) {
        s -= 5.0; // Style différent mais présent → petite pénalité
      }
    }

    // Bonus cluster : 2+ styles → cohérence esthétique forte
    if (matchCount >= 2) s += 80.0;

    return s;
  }

  // ---
  // 7. Personnalité
  // ---

  static double _scorePersonality(
      double s, Set<String> searchTags, Set<String> productTags) {
    for (final tag in searchTags.where((t) => t.startsWith('perso_'))) {
      if (productTags.contains(tag)) s += 35.0;
    }
    return s;
  }

  // ---
  // 8. Types de cadeaux
  // ---

  static double _scoreGiftTypes(
      double s, Set<String> searchTags, Set<String> productTags) {
    int matchCount = 0;
    for (final tag in searchTags.where((t) => t.startsWith('type_'))) {
      if (productTags.contains(tag)) {
        s += 25.0;
        matchCount++;
      }
    }
    if (matchCount >= 2) s += 30.0; // Bonus multi-type
    return s;
  }

  // ---
  // 9. Contexte (relation: ami, famille, collègue)
  // ---

  static double _scoreContext(
      double s, Set<String> searchTags, Set<String> productTags) {
    for (final tag in searchTags.where((t) => t.startsWith('context_'))) {
      if (productTags.contains(tag)) s += 20.0;
    }
    return s;
  }

  // ---
  // 10. Occasion (anniversaire, noël, mariage, saint-valentin…)
  // ---

  static double _scoreOccasion(
      double s, Set<String> searchTags, Set<String> productTags) {
    for (final tag in searchTags.where((t) => t.startsWith('occasion_'))) {
      if (productTags.contains(tag)) s += 60.0; // Bonus occasion forte
    }
    return s;
  }

  // ---
  // 11. Saison — bonus si saison courante, pénalité si saison opposée
  // ---

  static double _scoreSaison(double s, Set<String> productTags) {
    final currentSaison = TagsDefinitions.getSaisonTag();
    final oppositeSaison = TagsDefinitions.getOppositeSaisonTag(currentSaison);

    final productSaisons = productTags.where((t) => t.startsWith('saison_')).toList();
    if (productSaisons.isEmpty) return s; // Produit universel → neutre

    if (productSaisons.contains(currentSaison)) return s + 30.0;
    if (productSaisons.contains(oppositeSaison)) return s - 15.0;
    return s; // Autre saison → neutre
  }

  // ---
  // 12. Prix inverse — pénalise les produits trop cheap pour un gros budget
  //     (un budget 200€+ ne veut pas voir un produit à 8€)
  // ---

  static double _scorePrixInverse(
      double s, Set<String> searchTags, Map<String, dynamic> product) {
    final userBudget = searchTags.where((t) => t.startsWith('budget_')).firstOrNull;
    if (userBudget == null) return s;

    final price = product['price'];
    if (price == null) return s;
    final priceInt = price is int ? price : (price is double ? price.toInt() : 0);

    // Budget 200€+ avec produit < 30€ = maladroit comme cadeau
    if (userBudget == 'budget_200+' && priceInt < 30) return s - 40.0;
    // Budget 100-200€ avec produit < 15€ = aussi problématique
    if (userBudget == 'budget_100_200' && priceInt < 15) return s - 25.0;
    return s;
  }

  // ---
  // 13. Popularité — bestsellers / produits viraux remontent légèrement
  // ---

  static double _scorePopularite(double s, Set<String> productTags) {
    if (productTags.contains('popularite_5')) return s + 20.0; // Viral/bestseller
    if (productTags.contains('popularite_4')) return s + 10.0; // Très populaire
    if (productTags.contains('popularite_1')) return s - 5.0;  // Niche (léger malus)
    return s;
  }

  // ---
  // 14. Exclusion intime en contexte collègue
  //     (lingerie, bijoux très personnels → inapproprié pour un collègue)
  // ---

  static double _scoreContextIntime(
      double s, Set<String> searchTags, Set<String> productTags) {
    final isColleague = searchTags.contains('context_colleague');
    if (!isColleague) return s;
    if (productTags.contains('type_intime')) return s - 80.0;
    return s;
  }

  // ---
  // 15. Anti-doublon marque inter-sessions
  //     Pénalise légèrement une marque déjà vue récemment
  // ---

  static double _scoreBrandSeen(
      double s, Map<String, dynamic> product, List<String> brandsSeen) {
    if (brandsSeen.isEmpty) return s;
    final brand = (product['brand'] ?? '').toString().toLowerCase();
    if (brand.isEmpty) return s;
    if (brandsSeen.any((b) => b.toLowerCase() == brand)) return s - 15.0;
    return s;
  }
}
