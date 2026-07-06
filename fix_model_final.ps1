$path = "lib\pages\new_pages\onboarding_advanced\onboarding_advanced_model.dart"
$content = Get-Content -Path "model_backup.dart" -Raw -Encoding UTF8

# Update answers map
$content = $content -replace "(?s)Map<String, dynamic> answers = \{.*?\}", "Map<String, dynamic> answers = {
    'personName': '',
    'personIdentifier': '',
    'location': '',
    'giftTypes': <String>[],
    'personGender': '',
    'personAge': '',
    'occasion': '',
    'personalityMode': '',
    'recipientPersonality': <String>[],
    'budgetTier': '',
  }"

$newGetSteps = @"
  List<Map<String, dynamic>> getSteps({
    bool skipUserQuestions = false,
    bool onlyUserQuestions = false,
    bool expressMode = false,
    String? onboardingMode,
  }) {
    List<Map<String, dynamic>> steps = [
      {
        'id': 'welcome',
        'type': 'welcome',
        'title': 'DORON',
        'subtitle': 'Trouvons le cadeau parfait grâce à l''IA ✨',
        'emoji': '',
        'useLogo': true,
      },
      {
        'section': 'person',
        'id': 'personInfo',
        'type': 'dual_text',
        'question': 'Pour qui cherches-tu ?',
        'subtitle': 'En renseignant son pseudo Doron, l''IA s''inspirera de ses propres wishlists et préférences enregistrées pour trouver le cadeau parfait !',
        'icon': '📝',
        'fields': [
          {
            'field': 'personName',
            'label': 'Prénom',
            'placeholder': 'Ex: Marie',
            'required': true,
            'hint': 'REQUIS',
          },
          {
            'field': 'personIdentifier',
            'label': 'Nom d''utilisateur DORON',
            'placeholder': '@username',
            'required': false,
            'hint': 'OPTIONNEL - Pour lier ses Wishlists',
          },
        ],
      },
      {
        'section': 'person',
        'id': 'location',
        'type': 'single',
        'question': 'Où habite cette personne ?',
        'subtitle': 'Pour suggérer des activités locales',
        'field': 'location',
        'options': [
          'Paris / Ile-de-France',
          'Province',
          'International',
          'Peu importe'
        ],
        'icon': '📍',
      },
      {
        'section': 'gift',
        'id': 'giftTypes',
        'type': 'multiple',
        'question': 'Quel type de cadeau ?',
        'subtitle': 'Tu peux choisir plusieurs options !',
        'field': 'giftTypes',
        'options': [
          '🎁 Cadeaux Physiques (Livres, Mode, Déco)',
          '🎟️ Expériences & Activités (Spa, Voyages)',
          '📦 Abonnements (Box, Magasines, Streaming)',
          '❤️ Dons / Charité'
        ],
        'icon': '🛍️',
      },
      {
        'section': 'person',
        'id': 'personGender',
        'type': 'single',
        'question': 'Son profil ?',
        'subtitle': 'Affinons la recherche',
        'field': 'personGender',
        'options': [
          '👨‍🦱 Homme',
          '👩‍🦱 Femme',
          '🤝 Non-binaire',
          '👶 Enfant',
        ],
        'icon': '👤',
      },
      {
        'section': 'person',
        'id': 'personAge',
        'type': 'single',
        'question': 'Sa tranche d''âge ?',
        'field': 'personAge',
        'options': [
          'Moins de 12 ans',
          'Ados (13-17)',
          '18-25 ans',
          '26-45 ans',
          '45-65 ans',
          '65+ ans'
        ],
        'icon': '🎂',
      },
      {
        'section': 'gift',
        'id': 'occasion',
        'type': 'single',
        'question': 'L''occasion (Le "Pourquoi") ?',
        'field': 'occasion',
        'options': [
          '🎂 Anniversaire',
          '🎄 Noël',
          '❤️ Saint Valentin',
          '👶 Naissance',
          '🎉 Fête des Mères/Pères',
          '🥂 Pendaison de crémaillère',
          '✨ Juste comme ça'
        ],
        'icon': '🍾',
      },
      {
        'section': 'gift',
        'id': 'personalityMode',
        'type': 'single',
        'question': 'Comment veux-tu décrire sa personnalité ?',
        'subtitle': 'Choisis ton mode préféré',
        'field': 'personalityMode',
        'options': [
          '💬 Essayer le mode vocal (Recommandé)',
          '📝 Répondre aux questions (Classique)',
        ],
        'icon': '🗣️',
      }
    ];

    if (answers['personalityMode'] == '💬 Essayer le mode vocal (Recommandé)') {
      steps.add({
        'section': 'gift',
        'id': 'voiceRecording',
        'type': 'voice_recording',
        'question': 'Parle-nous un peu de la personne !',
        'subtitle': 'Inspire-toi de ces questions :\n- Quels sont ses hobbies ou ses passions ?\n- Dans quoi travaille-t-il/elle ?\n- Raconte une anecdote drôle',
        'field': 'recipientPersonality',
      });
    } else {
      steps.add({
        'section': 'gift',
        'id': 'personality',
        'type': 'multiple',
        'question': 'Sa personnalité (Le "Style de vie") ?',
        'subtitle': 'Sélection multiple possible',
        'field': 'recipientPersonality',
        'options': [
          '🧗 L''Explorateur (Voyage, Nature, Aventure)',
          '🛋️ Le Casanier (Déco, Cocooning, Lecture)',
          '💻 Le Tech-Addict (Gadgets, Gaming)',
          '👗 Le Fashioniste (Mode, Beauté)',
          '🍷 L''Épicurien (Vin, Gastronomie)',
          '🎨 Le Créatif (Art, Musique, DIY)',
          '⚽ Le Sportif (Fitness, Compétition)',
          '🧘 Le Zen (Bien-être, Spiritualité, Yoga)',
        ],
        'icon': '🎭',
      });
    }

    steps.add({
      'section': 'gift',
      'id': 'budgetTier',
      'type': 'single',
      'question': 'Le Budget (Filtre strict) ?',
      'field': 'budgetTier',
      'options': [
        '💸 < 20€',
        '💰 20€ - 50€',
        '💎 50€ - 150€',
        '👑 Luxe (> 150€)'
      ],
      'icon': '💳',
    });

    return steps;
  }

"@

$startIndex = $content.IndexOf("  List<Map<String, dynamic>> getSteps(")
$endIndex = $content.IndexOf("  void handleSelect(")
$part1 = $content.Substring(0, $startIndex)
$part2 = $content.Substring($endIndex)

$content = $part1 + $newGetSteps + $part2

# Add voice_recording check in canProceed
$newCanProceed = @"
    if (type == 'voice_recording') {
      final value = answers[stepData['field'] as String];
      return value != null && value.toString().trim().isNotEmpty;
    }
"@
$content = $content -replace "(?s)if \(type == 'slider'\) \{\s*return true;\s*\}", "if (type == 'slider') { return true; } $newCanProceed"

Set-Content -Path $path -Value $content -Encoding UTF8
