import '/utils/app_logger.dart';
import '/services/tags_definitions.dart';

/// Convertit les réponses utilisateur (onboarding, vocal, search) en
/// un ensemble de tags officiels Doron utilisés pour le matching Firebase.
///
/// Cette classe est **pure** (aucun effet de bord, aucun appel réseau) —
/// elle peut donc être testée unitairement sans infrastructure Firebase.
///
/// Exemple :
/// ```dart
/// final tags = TagConverter.convert({
///   'gender': 'Femme',
///   'budget': '80',
///   'style': 'Élégant',
///   'interests': ['mode', 'voyage'],
///   'recipientAge': '35',
///   'relation': 'amie',
/// });
/// // → {'gender_femme', 'budget_50_100', 'style_elegant', 'passion_mode',
/// //    'passion_voyages', 'age_adulte', 'context_ami'}
/// ```
class TagConverter {
  const TagConverter._();

  /// Convertit un profil utilisateur en ensemble de tags officiels Doron.
  ///
  /// Les tags produits sont normalisés : toLowerCase + tirets → underscores.
  /// Les tags officiels (gender/cat/budget/type/style/perso/passion) passent
  /// par [TagsDefinitions.filterValidTags]. Les tags étendus (age, context) sont
  /// ajoutés directement car ils ne sont pas encore dans allValidTags.
  static Set<String> convert(Map<String, dynamic> userProfile) {
    final raw = <String>{};

    _addGenderTag(userProfile, raw);
    _addCategoryTags(userProfile, raw);
    _addBudgetTag(userProfile, raw);
    _addStyleTag(userProfile, raw);
    _addPersonalityTags(userProfile, raw);
    _addPassionTags(userProfile, raw);
    _addGiftTypeTags(userProfile, raw);

    // Validation stricte pour les tags officiels
    final validated = TagsDefinitions.filterValidTags(raw.toList())
        .map((t) => t.toLowerCase().replaceAll('-', '_'))
        .toSet();

    // Tags étendus (age, context) — pas dans filterValidTags mais utilisés par MatchingEngine
    _addAgeTag(userProfile, validated);
    _addContextTag(userProfile, validated);

    // Tags nouveaux v3 — occasion et saison
    _addOccasionTag(userProfile, validated);
    _addSaisonTag(userProfile, validated);

    AppLogger.debug(
      'TagConverter: ${validated.length} tags (${raw.length} bruts + étendus): '
      '${validated.join(", ")}',
      'TagConverter',
    );
    return validated;
  }

  // ---------------------------------------------------------------------------
  // Tags officiels Doron
  // ---------------------------------------------------------------------------

  static void _addGenderTag(Map<String, dynamic> profile, Set<String> tags) {
    final gender = (profile['gender'] ?? profile['recipientGender'])?.toString() ?? '';
    final g = gender.toLowerCase();
    if (g.contains('femme') || g.contains('fille')) {
      tags.add('gender_femme');
    } else if (g.contains('homme') || g.contains('garçon') || g.contains('garcon')) {
      tags.add('gender_homme');
    } else if (gender.isNotEmpty) {
      tags.add('gender_mixte');
    }
  }

  static void _addCategoryTags(Map<String, dynamic> profile, Set<String> tags) {
    final cats = profile['preferredCategories'];
    if (cats == null) return;
    final list = cats is List ? cats : [cats];
    for (final c in list) {
      final converted = TagsDefinitions.categoryConversion[c.toString()];
      if (converted != null) tags.add(converted);
    }
  }

  static void _addBudgetTag(Map<String, dynamic> profile, Set<String> tags) {
    final budget = profile['budget'];
    if (budget == null) return;
    final amount = int.tryParse(budget.toString()) ?? 0;
    if (amount > 0) tags.add(TagsDefinitions.getBudgetTagFromPrice(amount));
  }

  static void _addStyleTag(Map<String, dynamic> profile, Set<String> tags) {
    final styleRaw = profile['style'];
    if (styleRaw == null) return;
    final styles = styleRaw is List ? styleRaw : [styleRaw];
    for (final s in styles) {
      final converted = TagsDefinitions.styleConversion[s.toString()];
      if (converted != null) tags.add(converted);
    }
  }

  static void _addPersonalityTags(Map<String, dynamic> profile, Set<String> tags) {
    final personality = profile['personality']?.toString().toLowerCase() ?? '';
    if (personality.isEmpty) return;
    TagsDefinitions.personalityConversion.forEach((key, value) {
      if (personality.contains(key.toLowerCase())) tags.add(value);
    });
  }

  static void _addPassionTags(Map<String, dynamic> profile, Set<String> tags) {
    // Supporte plusieurs clés possibles pour les centres d'intérêt
    final raw = profile['interests'] ??
        profile['hobbies'] ??
        profile['recipientHobbies'] ??
        profile['passions'];
    if (raw == null) return;

    final interests = raw is String
        ? raw.split(RegExp(r'[,;/]')).map((s) => s.trim())
        : (raw is List ? raw.map((e) => e.toString()) : [raw.toString()]);

    for (final interest in interests) {
      final lower = interest.toLowerCase().trim();
      if (lower.isEmpty) continue;
      // Chercher dans la map de conversion passions (enrichie)
      _enrichedPassionConversion.forEach((key, value) {
        if (lower.contains(key.toLowerCase())) tags.add(value);
      });
      // Fallback sur TagsDefinitions.passionConversion
      TagsDefinitions.passionConversion.forEach((key, value) {
        if (lower.contains(key.toLowerCase())) tags.add(value);
      });
    }
  }

  static void _addGiftTypeTags(Map<String, dynamic> profile, Set<String> tags) {
    final types = profile['giftTypes'];
    if (types == null) return;
    final list = types is List ? types : [types];
    for (final type in list) {
      final lower = type.toString().toLowerCase();
      for (final validType in TagsDefinitions.giftTypeTags) {
        if (lower.contains(validType.replaceFirst('type_', '')) ||
            validType.contains(lower)) {
          tags.add(validType);
          break;
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Tags étendus — âge et contexte (utilisés par MatchingEngine)
  // ---------------------------------------------------------------------------

  static void _addAgeTag(Map<String, dynamic> profile, Set<String> tags) {
    final ageRaw = profile['age'] ??
        profile['recipientAge'] ??
        profile['destinataireAge'];
    if (ageRaw == null) return;
    final age = int.tryParse(ageRaw.toString()) ?? 0;
    if (age <= 0) return;

    if (age < 13) {
      tags.add('age_enfant');
    } else if (age < 25) {
      tags.add('age_ado');
    } else if (age < 55) {
      tags.add('age_adulte');
    } else {
      tags.add('age_senior');
    }
  }

  static void _addContextTag(Map<String, dynamic> profile, Set<String> tags) {
    final relation = (profile['relation'] ??
            profile['recipient'] ??
            profile['recipientRelation'])
        ?.toString()
        .toLowerCase() ??
        '';
    if (relation.isEmpty) return;

    if (_isFamilyRelation(relation)) {
      tags.add('context_famille');
    } else if (_isFriendRelation(relation)) {
      tags.add('context_ami');
    } else if (_isColleagueRelation(relation)) {
      tags.add('context_colleague');
    } else if (_isRomanticRelation(relation)) {
      tags.add('context_amoureux');
    }
  }

  static bool _isFamilyRelation(String s) {
    return s.contains('maman') || s.contains('mère') || s.contains('mere') ||
        s.contains('papa') || s.contains('père') || s.contains('pere') ||
        s.contains('frère') || s.contains('frere') || s.contains('soeur') ||
        s.contains('sœur') || s.contains('fils') || s.contains('fille') ||
        s.contains('grand') || s.contains('oncle') || s.contains('tante') ||
        s.contains('cousin') || s.contains('enfant') || s.contains('famille');
  }

  static bool _isFriendRelation(String s) {
    return s.contains('ami') || s.contains('amie') || s.contains('copain') ||
        s.contains('copine') || s.contains('pote') || s.contains('meilleur');
  }

  static bool _isColleagueRelation(String s) {
    return s.contains('collègue') || s.contains('collegue') ||
        s.contains('boss') || s.contains('chef') || s.contains('patron') ||
        s.contains('collaborateur') || s.contains('associé');
  }

  static bool _isRomanticRelation(String s) {
    return s.contains('amoureux') || s.contains('amoureuse') ||
        s.contains('conjoint') || s.contains('conjointe') ||
        s.contains('chéri') || s.contains('petite amie') ||
        s.contains('petit ami') || s.contains('fiancé') ||
        s.contains('mari') || s.contains('femme') && s.contains('ma ');
  }

  // ---------------------------------------------------------------------------
  // Tags v3 — Occasion et Saison
  // ---------------------------------------------------------------------------

  static void _addOccasionTag(Map<String, dynamic> profile, Set<String> tags) {
    // 1. Depuis le profil explicite
    final raw = (profile['occasion'] ?? profile['event'] ?? profile['moment'])
        ?.toString()
        .toLowerCase() ?? '';
    if (raw.isNotEmpty) {
      TagsDefinitions.occasionConversion.forEach((key, value) {
        if (raw.contains(key.toLowerCase())) tags.add(value);
      });
    }

    // 2. Auto-détection depuis la date calendaire
    final month = DateTime.now().month;
    final day = DateTime.now().day;
    if (month == 2 && day >= 10 && day <= 16) tags.add('occasion_saint_valentin');
    if (month == 12) tags.add('occasion_noel');
    if (month == 5 && day >= 20 && day <= 31) tags.add('occasion_fete'); // Fête des mères
    if (month == 6 && day >= 10 && day <= 20) tags.add('occasion_fete'); // Fête des pères
  }

  static void _addSaisonTag(Map<String, dynamic> profile, Set<String> tags) {
    // 1. Depuis le profil explicite
    final raw = (profile['saison'] ?? profile['season'])?.toString().toLowerCase() ?? '';
    if (raw.contains('été') || raw.contains('ete') || raw.contains('summer')) {
      tags.add('saison_ete');
    } else if (raw.contains('hiver') || raw.contains('winter')) {
      tags.add('saison_hiver');
    } else if (raw.contains('printemps') || raw.contains('spring')) {
      tags.add('saison_printemps');
    } else if (raw.contains('automne') || raw.contains('autumn') || raw.contains('fall')) {
      tags.add('saison_automne');
    } else {
      // 2. Auto-détection depuis la date actuelle
      tags.add(TagsDefinitions.getSaisonTag());
    }
  }

  // ---------------------------------------------------------------------------
  // Map de passions enrichie v3 (25 mots-clés supplémentaires)
  // ---------------------------------------------------------------------------

  static const Map<String, String> _enrichedPassionConversion = {
    // Sport
    'fitness': 'passion_sport',
    'gym': 'passion_sport',
    'running': 'passion_sport',
    'course': 'passion_sport',
    'natation': 'passion_sport',
    'vélo': 'passion_sport',
    'velo': 'passion_sport',
    'escalade': 'passion_sport',
    'skateboard': 'passion_sport',
    'surf': 'passion_sport',
    'ski': 'passion_sport',
    'golf': 'passion_sport',
    'tennis': 'passion_sport',
    'padel': 'passion_sport',
    'gravel': 'passion_sport',
    'karting': 'passion_automobile',
    // Nature
    'hiking': 'passion_nature',
    'trek': 'passion_nature',
    'plongée': 'passion_nature',
    'chasse': 'passion_nature',
    'pêche': 'passion_nature',
    // Bien-être
    'meditation': 'passion_yoga',
    'méditation': 'passion_yoga',
    'pilates': 'passion_yoga',
    // Cuisine
    'recettes': 'passion_cuisine',
    'gastronomie': 'passion_cuisine',
    'pâtisserie': 'passion_cuisine',
    'patisserie': 'passion_cuisine',
    'sushi': 'passion_cuisine',
    // Boissons
    'cocktails': 'passion_vins',
    'bières': 'passion_vins',
    'whisky': 'passion_vins',
    // Cinéma / Séries
    'séries': 'passion_cinema',
    'netflix': 'passion_cinema',
    'anime': 'passion_cinema',
    'manga': 'passion_cinema',
    // Lecture
    'bd': 'passion_lecture',
    'bande dessinée': 'passion_lecture',
    'podcast': 'passion_musique',
    // Musique
    'guitare': 'passion_musique',
    'piano': 'passion_musique',
    'kpop': 'passion_musique',
    // Art & Créatif
    'dessin': 'passion_art',
    'aquarelle': 'passion_art',
    'sculpture': 'passion_art',
    'tatouage': 'passion_art',
    'tricot': 'passion_loisirs_creatifs',
    'couture': 'passion_loisirs_creatifs',
    'broderie': 'passion_loisirs_creatifs',
    'origami': 'passion_loisirs_creatifs',
    // Jeux
    'jeux de société': 'passion_jeuxvideo',
    'jeux de carte': 'passion_jeuxvideo',
    'escape game': 'passion_jeuxvideo',
    // Jardinage
    'plantes': 'passion_jardinage',
    'terrarium': 'passion_jardinage',
    // Tech
    'imprimante 3d': 'passion_tech',
    'arduino': 'passion_tech',
    'drone': 'passion_tech',
    'astronomie': 'passion_nature',
    'astro': 'passion_nature',
    // Photo
    'photographie': 'passion_photo',
  };
}
