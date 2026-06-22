/// Définitions officielles et exhaustives des tags produits DORÕN
///
/// Ce fichier centralise TOUTES les valeurs de tags autorisées.
///
/// Structure : 13 familles de tags
class TagsDefinitions {
  // ========================================================================
  // TAGS OBLIGATOIRES - 1 SEULE VALEUR POSSIBLE
  // ========================================================================

  /// 1️⃣ SEXE (OBLIGATOIRE - 1 seul tag)
  /// Règle : STRICTE - correspondance exacte requise
  static const List<String> genderTags = [
    'gender_femme',
    'gender_homme',
    'gender_mixte', // Rare, seulement si vraiment universel
  ];

  /// 2️⃣ CATÉGORIE PRINCIPALE (OBLIGATOIRE - 1 seul tag)
  /// Règle : STRICTE - correspondance exacte requise
  static const List<String> categoryTags = [
    'cat_tendances', // Produits viraux, TikTok, nouveautés tendances
    'cat_tech', // High-tech, gadgets, électronique
    'cat_mode', // Vêtements, accessoires mode
    'cat_maison', // Déco, maison, intérieur
    'cat_beaute', // Beauté, soins, parfums
    'cat_food', // Gastronomie, cuisine, alimentaire
  ];

  /// 3️⃣ TRANCHE DE PRIX (OBLIGATOIRE - 1 seul tag)
  /// Règle : STRICTE - correspondance exacte requise
  static const List<String> budgetTags = [
    'budget_0_50',
    'budget_50_100',
    'budget_100_200',
    'budget_200+',
  ];

  // ========================================================================
  // TAGS MULTIPLES - PLUSIEURS VALEURS POSSIBLES
  // ========================================================================

  /// 4️⃣ TYPE DE CADEAU (MULTIPLE possible)
  /// Règle : SOUPLE - matching partiel autorisé
  static const List<String> giftTypeTags = [
    'type_mode_accessoires',
    'type_bien_etre',
    'type_sport_outdoor',
    'type_gastronomie',
    'type_culture',
    'type_high_tech',
    'type_maison_deco',
    'type_beaute_soins',
    'type_loisirs_creatifs',
    'type_jeux_jouets',
    'type_livres_bd',
    'type_musique_audio',
    'type_voyage_aventure',
    'type_automobile',
    'type_bijoux',
    'type_intime', // lingerie, bijoux très personnels — exclu auto en context_colleague
  ];

  /// 5️⃣ STYLE (MULTIPLE possible)
  /// Règle : SOUPLE - matching partiel autorisé
  static const List<String> styleTags = [
    'style_elegant',
    'style_tendance',
    'style_minimaliste',
    'style_classique',
    'style_decontracte',
    'style_sportif',
    'style_vintage',
    'style_moderne',
    'style_luxe',
    'style_boheme',
    'style_streetwear',
    'style_eco_responsable',
  ];

  /// 6️⃣ PERSONNALITÉ (MULTIPLE possible)
  /// Règle : SOUPLE - matching partiel autorisé
  static const List<String> personalityTags = [
    'perso_creatif',
    'perso_actif',
    'perso_cool',
    'perso_bienveillant',
    'perso_ambitieux',
    'perso_romantique',
    'perso_aventurier',
    'perso_intellectuel',
    'perso_sociable',
    'perso_zen',
    'perso_excentrique',
    'perso_pratique',
    'perso_gourmand',
    'perso_techie',
  ];

  /// 7️⃣ PASSIONS (MULTIPLE possible)
  /// Règle : SOUPLE - matching partiel autorisé
  static const List<String> passionTags = [
    'passion_sport',
    'passion_cuisine',
    'passion_voyages',
    'passion_photo',
    'passion_jeuxvideo',
    'passion_lecture',
    'passion_musique',
    'passion_cinema',
    'passion_mode',
    'passion_beaute',
    'passion_tech',
    'passion_art',
    'passion_jardinage',
    'passion_bricolage',
    'passion_yoga',
    'passion_danse',
    'passion_nature',
    'passion_animaux',
    'passion_automobile',
    'passion_vins',
    'passion_loisirs_creatifs', // tricot, origami, couture...
  ];

  /// 8⃣ ÂGE DU DESTINATAIRE (facultatif)
  /// Règle : SOUPLE - bonus si match, pas d'exclusion
  static const List<String> ageTags = [
    'age_enfant',  // < 13 ans
    'age_ado',     // 13-24 ans
    'age_adulte',  // 25-54 ans
    'age_senior',  // 55+ ans
  ];

  /// 9⃣ CONTEXTE RELATION (facultatif)
  /// Règle : SOUPLE - bonus si match, pas d'exclusion
  static const List<String> contextTags = [
    'context_famille',
    'context_ami',
    'context_colleague',
    'context_amoureux',
  ];

  /// 10⃣ OCCASION (facultatif)
  /// Règle : SOUPLE - bonus si match (+60pts)
  static const List<String> occasionTags = [
    'occasion_anniversaire',
    'occasion_noel',
    'occasion_mariage',
    'occasion_saint_valentin',
    'occasion_fete',        // fête des mères/pères, fête prénom
    'occasion_remerciement', // cadeau de remerciement, prof, coach
    'occasion_naissance',   // naissance, baby shower
    'occasion_diplome',     // bac, licence, master, permis
  ];

  /// 11⃣ SAISON (facultatif)
  /// Règle : SOUPLE - bonus si match (+30pts), malus si opposé (-15pts)
  static const List<String> saisonTags = [
    'saison_printemps',
    'saison_ete',
    'saison_automne',
    'saison_hiver',
  ];

  /// 12⃣ POPULARITÉ (1=niche, 5=viral/bestseller)
  /// Règle : SOUPLE - popularite_5 = +20pts, popularite_4 = +10pts
  static const List<String> populariteTags = [
    'popularite_1',
    'popularite_2',
    'popularite_3',
    'popularite_4',
    'popularite_5', // Bestseller, produit viral
  ];


  // ========================================================================
  // UTILITAIRES DE VALIDATION
  // ========================================================================

  /// Vérifie si un tag de genre est valide
  static bool isValidGenderTag(String tag) => genderTags.contains(tag);

  /// Vérifie si un tag de catégorie est valide
  static bool isValidCategoryTag(String tag) => categoryTags.contains(tag);

  /// Vérifie si un tag de budget est valide
  static bool isValidBudgetTag(String tag) => budgetTags.contains(tag);

  /// Vérifie si un tag de type de cadeau est valide
  static bool isValidGiftTypeTag(String tag) => giftTypeTags.contains(tag);

  /// Vérifie si un tag de style est valide
  static bool isValidStyleTag(String tag) => styleTags.contains(tag);

  /// Vérifie si un tag de personnalité est valide
  static bool isValidPersonalityTag(String tag) => personalityTags.contains(tag);

  /// Vérifie si un tag de passion est valide
  static bool isValidPassionTag(String tag) => passionTags.contains(tag);

  /// Retourne tous les tags valides (toutes catégories confondues)
  static List<String> get allValidTags => [
        ...genderTags,
        ...categoryTags,
        ...budgetTags,
        ...giftTypeTags,
        ...styleTags,
        ...personalityTags,
        ...passionTags,
        ...ageTags,
        ...contextTags,
        ...occasionTags,
        ...saisonTags,
        ...populariteTags,
      ];

  /// Filtre une liste de tags pour ne garder que ceux qui sont valides
  static List<String> filterValidTags(List<String> tags) {
    return tags.where((tag) => allValidTags.contains(tag)).toList();
  }

  /// Extrait le tag de budget en fonction d'un prix
  static String getBudgetTagFromPrice(int price) {
    if (price < 50) return 'budget_0_50';
    if (price < 100) return 'budget_50_100';
    if (price < 200) return 'budget_100_200';
    return 'budget_200+';
  }

  /// Convertit un âge en tag âge
  static String getAgeTagFromAge(int age) {
    if (age < 13) return 'age_enfant';
    if (age < 25) return 'age_ado';
    if (age < 55) return 'age_adulte';
    return 'age_senior';
  }

  /// Retourne le tag saison courant selon la date
  static String getSaisonTag() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'saison_printemps';
    if (month >= 6 && month <= 8) return 'saison_ete';
    if (month >= 9 && month <= 11) return 'saison_automne';
    return 'saison_hiver'; // 12, 1, 2
  }

  /// Saison opposée (pour pénaliser les produits hors-saison)
  static String getOppositeSaisonTag(String saison) {
    const opposites = {
      'saison_printemps': 'saison_automne',
      'saison_automne': 'saison_printemps',
      'saison_ete': 'saison_hiver',
      'saison_hiver': 'saison_ete',
    };
    return opposites[saison] ✨ '';
  }

  // ========================================================================
  // MAPS DE CONVERSION (pour onboarding et voice assistant)
  // ========================================================================

  /// Conversion genre utilisateur → tag produit
  static const Map<String, String> genderConversion = {
    'Femme': 'gender_femme',
    'Homme': 'gender_homme',
    'Mixte': 'gender_mixte',
    'Non spécifié': 'gender_mixte',
  };

  /// Conversion catégories onboarding → tags produit
  static const Map<String, String> categoryConversion = {
    'Tendances': 'cat_tendances',
    'Tech': 'cat_tech',
    'Électronique': 'cat_tech',
    'Mode': 'cat_mode',
    'Vêtements': 'cat_mode',
    'Maison': 'cat_maison',
    'Déco': 'cat_maison',
    'Beauté': 'cat_beaute',
    'Soins': 'cat_beaute',
    'Food': 'cat_food',
    'Gastronomie': 'cat_food',
    'Cuisine': 'cat_food',
  };

  /// Conversion occasion utilisateur → tag produit
  static const Map<String, String> occasionConversion = {
    'Anniversaire': 'occasion_anniversaire',
    'Noël': 'occasion_noel',
    'Mariage': 'occasion_mariage',
    'Saint-Valentin': 'occasion_saint_valentin',
    'Fête': 'occasion_fete',
    'Remerciement': 'occasion_remerciement',
    'Naissance': 'occasion_naissance',
    'Diplôme': 'occasion_diplome',
    'anniversaire': 'occasion_anniversaire',
    'noel': 'occasion_noel',
    'noël': 'occasion_noel',
    'saint-valentin': 'occasion_saint_valentin',
    'valentin': 'occasion_saint_valentin',
    'mariage': 'occasion_mariage',
    'fête des mères': 'occasion_fete',
    'fête des pères': 'occasion_fete',
    'remerciement': 'occasion_remerciement',
  };

  /// Conversion styles utilisateur → tags produit
  static const Map<String, String> styleConversion = {
    'Élégant': 'style_elegant',
    'Tendance': 'style_tendance',
    'Minimaliste': 'style_minimaliste',
    'Classique': 'style_classique',
    'Décontracté': 'style_decontracte',
    'Sportif': 'style_sportif',
    'Vintage': 'style_vintage',
    'Moderne': 'style_moderne',
    'Luxe': 'style_luxe',
    'Bohème': 'style_boheme',
    'Street': 'style_streetwear',
    'Eco': 'style_eco_responsable',
  };

  /// Conversion passions/hobbies → tags passion
  static const Map<String, String> passionConversion = {
    'sport': 'passion_sport',
    'cuisine': 'passion_cuisine',
    'voyages': 'passion_voyages',
    'photo': 'passion_photo',
    'photographie': 'passion_photo',
    'jeux vidéo': 'passion_jeuxvideo',
    'gaming': 'passion_jeuxvideo',
    'lecture': 'passion_lecture',
    'livres': 'passion_lecture',
    'musique': 'passion_musique',
    'cinéma': 'passion_cinema',
    'films': 'passion_cinema',
    'mode': 'passion_mode',
    'fashion': 'passion_mode',
    'beauté': 'passion_beaute',
    'maquillage': 'passion_beaute',
    'tech': 'passion_tech',
    'technologie': 'passion_tech',
    'art': 'passion_art',
    'peinture': 'passion_art',
    'jardinage': 'passion_jardinage',
    'bricolage': 'passion_bricolage',
    'yoga': 'passion_yoga',
    'danse': 'passion_danse',
    'nature': 'passion_nature',
    'randonnée': 'passion_nature',
    'animaux': 'passion_animaux',
    'automobile': 'passion_automobile',
    'voitures': 'passion_automobile',
    'vins': 'passion_vins',
    'oenologie': 'passion_vins',
  };

  /// Conversion personnalités → tags personnalité
  static const Map<String, String> personalityConversion = {
    'créatif': 'perso_creatif',
    'créative': 'perso_creatif',
    'actif': 'perso_actif',
    'active': 'perso_actif',
    'sportif': 'perso_actif',
    'cool': 'perso_cool',
    'calme': 'perso_zen',
    'bienveillant': 'perso_bienveillant',
    'bienveillante': 'perso_bienveillant',
    'ambitieux': 'perso_ambitieux',
    'ambitieuse': 'perso_ambitieux',
    'romantique': 'perso_romantique',
    'aventurier': 'perso_aventurier',
    'aventurière': 'perso_aventurier',
    'aventureux': 'perso_aventurier',
    'intellectuel': 'perso_intellectuel',
    'intellectuelle': 'perso_intellectuel',
    'sociable': 'perso_sociable',
    'zen': 'perso_zen',
    'excentrique': 'perso_excentrique',
    'original': 'perso_excentrique',
    'originale': 'perso_excentrique',
    'pratique': 'perso_pratique',
    'pragmatique': 'perso_pratique',
    'gourmand': 'perso_gourmand',
    'gourmande': 'perso_gourmand',
    'techie': 'perso_techie',
    'geek': 'perso_techie',
  };

  // ========================================================================
  // HELPERS DE CONVERSION
  // ========================================================================

  /// Convertit une liste de mots-clés en tags valides
  static List<String> convertKeywordsToTags(List<String> keywords) {
    final Set<String> tags = {};

    for (final keyword in keywords) {
      final lowerKeyword = keyword.toLowerCase().trim();

      // Chercher dans les passions
      passionConversion.forEach((key, value) {
        if (lowerKeyword.contains(key.toLowerCase())) {
          tags.add(value);
        }
      });

      // Chercher dans les personnalités
      personalityConversion.forEach((key, value) {
        if (lowerKeyword.contains(key.toLowerCase())) {
          tags.add(value);
        }
      });

      // Chercher dans les styles
      styleConversion.forEach((key, value) {
        if (lowerKeyword.contains(key.toLowerCase())) {
          tags.add(value);
        }
      });
    }

    return tags.toList();
  }
}
