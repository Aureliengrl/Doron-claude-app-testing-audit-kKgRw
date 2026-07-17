import '/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '/services/firebase_data_service.dart';
import '/services/first_time_service.dart';
import 'package:go_router/go_router.dart';

class OnboardingAdvancedModel {
  int currentStep = 0;
  String? editProfileId;
  // FIX Bug 2: Variable pour emp�cher les doubles clics
  bool isNavigating = false;
  Map<String, dynamic> answers = {
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
  };

  // Animations
  late List<AnimationController> particleControllers;
  late List<Offset> particlePositions;
  late List<double> particleSizes;

  void initAnimations(TickerProvider vsync) {
    final random = math.Random();
    particleControllers = List.generate(
      20,
      (index) => AnimationController(
        vsync: vsync,
        duration: Duration(
          milliseconds: 2000 + random.nextInt(1000),
        ),
      )..repeat(reverse: true),
    );

    particlePositions = List.generate(
      20,
      (index) => Offset(
        random.nextDouble(),
        random.nextDouble(),
      ),
    );

    particleSizes = List.generate(
      20,
      (index) => 2.0 + random.nextDouble() * 4,
    );
  }

  void dispose() {
    for (var controller in particleControllers) {
      controller.dispose();
    }
  }

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
        'icon': '🥂',
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
      'icon': 'ðŸ’³',
    });

    return steps;
  }
  void handleSelect(String field, String value, bool isMultiple, {int? maxSelections}) {
    if (isMultiple) {
      final currentList = answers[field] as List<String>;
      if (currentList.contains(value)) {
        currentList.remove(value);
      } else {
        // V�rifier la limite de s�lection si d�finie
        if (maxSelections != null && currentList.length >= maxSelections) {
          // Ne pas ajouter si la limite est atteinte
          return;
        }
        currentList.add(value);
      }
    } else {
      answers[field] = value;
    }
  }

  bool isSelected(String field, String value) {
    final fieldValue = answers[field];
    if (fieldValue is List<String>) {
      return fieldValue.contains(value);
    }
    return fieldValue == value;
  }

  bool canProceed(Map<String, dynamic> stepData) {
    final type = stepData['type'] as String;

    if (type == 'welcome' || type == 'transition') {
      return true;
    }

    if (type == 'slider') { return true; }     if (type == 'voice_recording') {
      final value = answers[stepData['field'] as String];
      return value != null && value.toString().trim().isNotEmpty;
    }

    // Gestion du type dual_text (Pr�nom + Pseudo)
    if (type == 'dual_text') {
      final fields = stepData['fields'] as List;
      // V�rifier que tous les champs requis sont remplis
      for (var fieldData in fields) {
        final field = fieldData['field'] as String;
        final required = fieldData['required'] as bool? ?? false;
        final value = answers[field];

        if (required && (value == null || value.toString().trim().isEmpty)) {
          return false;
        }
      }
      return true;
    }

    // Pour les autres types, v�rifier que le champ existe
    if (!stepData.containsKey('field')) {
      return true; // Si pas de field, on peut continuer
    }

    final field = stepData['field'] as String;
    final fieldValue = answers[field];

    if (type == 'multiple') {
      return (fieldValue as List<String>).isNotEmpty;
    }

    return fieldValue != null &&
        fieldValue != '' &&
        (fieldValue is! double || fieldValue > 0);
  }

  Future<void> handleNext(List<Map<String, dynamic>> steps, BuildContext context, {bool skipUserQuestions = false, String? returnTo, bool onlyUserQuestions = false}) async {
    // FIX Bug 2: Emp�cher les doubles clics
    if (isNavigating) {
      AppLogger.debug('?? Navigation d�j� en cours, ignor�', 'Debug');
      return;
    }
    isNavigating = true;

    final currentStepData = steps[currentStep];

    // ==================== NOUVELLE ARCHITECTURE ====================
    // D�tecter la fin de l'�tape A (section user) - juste apr�s la transition
    if (currentStepData['id'] == 'transition') {
      // Sauvegarder les tags utilisateur (�tape A)
      final userTags = {
        'firstName': answers['firstName'],
        'age': answers['age'],
        'gender': answers['gender'],
        'interests': answers['interests'],
        'style': answers['style'],
        'giftTypes': answers['giftTypes'],
      };

      try {
        await FirebaseDataService.saveUserProfileTags(userTags);
        AppLogger.debug('? �tape A termin�e: Tags utilisateur sauvegard�s', 'Debug');
      } catch (e) {
        AppLogger.debug('? Erreur sauvegarde tags utilisateur: $e', 'Debug');
      }

      // ?? CAS SP�CIAL: Si onlyUserQuestions=true, on s'arr�te ici
      // L'utilisateur modifie juste son profil depuis les param�tres
      if (onlyUserQuestions) {
        AppLogger.debug('? Modification profil utilisateur termin�e (onlyUserQuestions=true)', 'Debug');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('? Profil mis � jour avec succ�s !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Retourner � la page d'origine (ou page Recherche par d�faut)
        await Future.delayed(const Duration(milliseconds: 500));
        if (context.mounted) {
          if (returnTo != null && returnTo.isNotEmpty) {
            context.go(returnTo);
          } else {
            context.go('/search-page'); // Redirection vers page Recherche
          }
        }
        isNavigating = false; // Reset le flag avant de return
        return; // Arr�ter ici, ne pas cr�er de personne
      }
    }
    // =================================================================

    if (currentStep < steps.length - 1) {
      currentStep++;
      isNavigating = false; // FIX Bug 2: Reset le flag apr�s l'incr�mentation
      AppLogger.debug('? Step avanc�: $currentStep', 'Debug');
    } else {
      // Onboarding termin� (fin de l'�tape B)
      AppLogger.debug('? Onboarding termin�: $answers', 'Debug');

      try {
        // ==================== NOUVELLE ARCHITECTURE ====================
        // 1. Cr�er la premi�re personne (�tape B) avec isPendingFirstGen=true

        // D�terminer si c'est un username ou un pr�nom
        final isUsername = answers['personIdentifierType']?.contains('utilisateur') == true;
        final identifier = answers['personIdentifier'] ?? '';

        final personTags = {
          'name': answers['personIdentifier'] == null || answers['personIdentifier'].toString().isEmpty ? answers['personName'] : answers['personIdentifier'],
          'username': answers['personIdentifier']?.replaceAll('@', ''),
          'isUsername': answers['personIdentifier'] != null && answers['personIdentifier'].toString().isNotEmpty,
          'gender': answers['personGender'],
          'age': answers['personAge'],
          'location': answers['location'],
          'giftTypes': answers['giftTypes'],
          'occasion': answers['occasion'],
          'recipientPersonality': answers['recipientPersonality'],
          'budgetTier': answers['budgetTier'],
        };

        final personId = await FirebaseDataService.createPerson(
          tags: personTags,
          isPendingFirstGen: true, // Flag pour g�n�ration post-auth
        );

        AppLogger.debug('? Premi�re personne cre: $personId (isPendingFirstGen=true)', 'Debug');
        // =================================================================

        // 2. Sauvegarder aussi l'ancien format pour compatibilit�
        await FirebaseDataService.saveOnboardingAnswers(answers);

        // Afficher un feedback de succ�s
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('? Profil sauvegard� avec succ�s !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // 3. Marquer l'onboarding comme compl�t� (seulement si c'est le premier onboarding)
        if (!skipUserQuestions) {
          await FirstTimeService.setOnboardingCompleted();
        }

        // 4. Navigation
        if (context.mounted) {
          // TOUJOURS montrer la page cadeaux d'abord
          if (personId != null) {
            // Si on a un returnTo, le passer en param�tre pour revenir apr�s
            final returnParam = (returnTo != null && returnTo.isNotEmpty)
                ? '&returnTo=${Uri.encodeComponent(returnTo)}'
                : '';

            // Si c'est le PREMIER onboarding (pas de skipUserQuestions)
            if (!skipUserQuestions) {
              // Aller d'abord � l'authentification AVANT de voir les cadeaux
              AppLogger.debug('?? Premier onboarding: Navigation vers authentification puis cadeaux', 'Debug');
              context.go('/authentification?personId=$personId$returnParam');
            } else {
              // Si c'est un ajout de personne, aller directement aux cadeaux
              AppLogger.debug('?? Ajout de personne: Navigation directe vers cadeaux', 'Debug');
              context.go('/onboarding-gifts-result?personId=$personId$returnParam');
            }
          } else {
            // Fallback: si pas de personId (erreur)
            AppLogger.debug('?? Pas de personId, navigation vers authentification', 'Debug');
            context.go('/authentification');
          }
        }
      } catch (e) {
        AppLogger.debug('? Erreur sauvegarde onboarding: $e', 'Debug');
        isNavigating = false; // Reset le flag en cas d'erreur
        // M�me en cas d'erreur, on navigue
        if (context.mounted) {
          if (returnTo != null && returnTo.isNotEmpty) {
            context.go(returnTo);
          } else {
            context.go('/authentification');
          }
        }
      }
    }
  }

  void handleBack() {
    if (currentStep > 0) {
      currentStep--;
    }
  }

  /// Vrai dès qu'on connaît le nom (ou le @username) du destinataire :
  /// à partir de là on peut passer les questions de goûts ou créer direct.
  bool get hasRecipientName =>
      (answers['personName']?.toString().trim().isNotEmpty == true) ||
      (answers['personIdentifier']?.toString().trim().isNotEmpty == true);

  /// « Passer » : avance à la question suivante sans exiger de réponse.
  void skipStep(List<Map<String, dynamic>> steps) {
    if (currentStep < steps.length - 1) {
      currentStep++;
    }
  }

  /// « Créer directement » : saute les questions restantes et termine
  /// l'onboarding tout de suite (crée la personne + navigue vers les cadeaux).
  Future<void> createDirectly(
    List<Map<String, dynamic>> steps,
    BuildContext context, {
    bool skipUserQuestions = false,
    String? returnTo,
    bool onlyUserQuestions = false,
  }) async {
    currentStep = steps.length - 1;
    await handleNext(
      steps,
      context,
      skipUserQuestions: skipUserQuestions,
      returnTo: returnTo,
      onlyUserQuestions: onlyUserQuestions,
    );
  }
}





