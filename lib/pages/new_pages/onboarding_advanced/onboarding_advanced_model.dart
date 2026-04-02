import '/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '/services/firebase_data_service.dart';
import '/services/first_time_service.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingAdvancedModel {
  int currentStep = 0;
  // FIX Bug 2: Variable pour empêcher les doubles clics
  bool isNavigating = false;
  Map<String, dynamic> answers = {
    'personName': '', // Prénom de la personne (REQUIS)
    'personIdentifier': '', // Username DORON (OPTIONNEL)
    'location': '', // Localisation
    'giftTypes': <String>[], // Physique vs Activité
    'personGender': '', // Homme / Femme / Non-binaire / Enfant
    'personAge': '', // Tranche d'âge
    'occasion': '', // Événement
    'recipientPersonality': <String>[], // Tags de style de vie
    'budgetTier': '', // Paliers de budget
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
    // NOUVEL ENTONNOIR HAUTE PRÉCISION (Refonte Totale)
    return [
      // Écran de bienvenue
      {
        'id': 'welcome',
        'type': 'welcome',
        'title': 'DORÕN',
        'subtitle': 'Trouvons le cadeau parfait grâce à l\'IA 🎯',
        'emoji': '',
        'useLogo': true,
      },
      // Étape 0.1 : Prénom et Pseudo
      {
        'section': 'person',
        'id': 'personInfo',
        'type': 'dual_text',
        'question': 'Pour qui cherches-tu ?',
        'subtitle': '👤 Prénom requis • 🔗 Pseudo optionnel',
        'icon': '✍️',
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
            'label': 'Nom d\'utilisateur DORON',
            'placeholder': '@username',
            'required': false,
            'hint': 'OPTIONNEL - Pour inclure sa Wishlist',
          },
        ],
      },
      // Étape 0.2 : Localisation
      {
        'section': 'person',
        'id': 'location',
        'type': 'single', // Change to text or autocomplete later if needed, but single works for broad regions
        'question': 'Où habite cette personne ?',
        'subtitle': '📍 Pour suggérer des activités locales',
        'field': 'location',
        'options': [
          'Île-de-France (Paris)',
          'Sud-Est (Lyon, Marseille, Nice...)',
          'Sud-Ouest (Bordeaux, Toulouse...)',
          'Nord & Est (Lille, Strasbourg...)',
          'Ouest (Nantes, Rennes...)',
          'Peu importe / Ailleurs'
        ],
        'icon': '🌍',
      },
      // Étape 0.3 : Type de cadeau
      {
        'section': 'gift',
        'id': 'giftTypes',
        'type': 'multiple',
        'question': 'Quel type de cadeau ?',
        'subtitle': '🎁 Tu peux choisir les deux !',
        'field': 'giftTypes',
        'options': [
          '🛍️ Cadeaux Physiques (Livres, Mode, Déco...)',
          '🎟️ Expériences & Activités (Spa, Voyages, Sorties...)'
        ],
        'icon': '✨',
      },
      // Étape 1.1 : Sexe
      {
        'section': 'person',
        'id': 'personGender',
        'type': 'single',
        'question': 'Son profil ?',
        'subtitle': '🎯 Affinons la recherche',
        'field': 'personGender',
        'options': [
          '🙋‍♂️ Homme',
          '🙋‍♀️ Femme',
          '🌈 Non-binaire',
          '👶 Enfant',
        ],
        'icon': '👥',
      },
      // Étape 1.2 : Âge
      {
        'section': 'person',
        'id': 'personAge',
        'type': 'single',
        'question': 'Sa tranche d\'âge ?',
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
      // Étape 2 : L'Occasion
      {
        'section': 'gift',
        'id': 'occasion',
        'type': 'single',
        'question': 'L\'occasion (Le "Pourquoi") ?',
        'field': 'occasion',
        'options': [
          '🎂 Anniversaire',
          '🏠 Pendaison de crémaillère',
          '💍 Mariage',
          '🍼 Naissance',
          '🙏 Remerciement',
          '❤️ Juste comme ça'
        ],
        'icon': '🎉',
      },
      // Étape 3 : La Personnalité
      {
        'section': 'gift',
        'id': 'personality',
        'type': 'multiple',
        'question': 'Sa personnalité (Le "Style de vie") ?',
        'subtitle': '🎯 Sélection multiple possible',
        'field': 'recipientPersonality',
        'options': [
          '🌍 L\'Explorateur (Voyage, Nature, Aventure)',
          '🏠 Le Casanier (Déco, Cocooning, Lecture)',
          '💻 Le Tech-Enthusiast (Gadgets, Gaming)',
          '👗 Le Fashioniste (Mode, Beauté)',
          '🍷 L\'Épicurien (Vin, Gastronomie)',
          '🎨 Le Créatif (Art, Musique, DIY)'
        ],
        'icon': '💫',
      },
      // Étape 4 : Le Budget
      {
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
        'icon': '💶',
      }
    ];
  }

  void handleSelect(String field, String value, bool isMultiple, {int? maxSelections}) {
    if (isMultiple) {
      final currentList = answers[field] as List<String>;
      if (currentList.contains(value)) {
        currentList.remove(value);
      } else {
        // Vérifier la limite de sélection si définie
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

    if (type == 'slider') {
      return true;
    }

    // Gestion du type dual_text (Prénom + Pseudo)
    if (type == 'dual_text') {
      final fields = stepData['fields'] as List;
      // Vérifier que tous les champs requis sont remplis
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

    // Pour les autres types, vérifier que le champ existe
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
    // FIX Bug 2: Empêcher les doubles clics
    if (isNavigating) {
      AppLogger.debug('⚠️ Navigation déjà en cours, ignoré', 'Debug');
      return;
    }
    isNavigating = true;

    final currentStepData = steps[currentStep];

    // ==================== NOUVELLE ARCHITECTURE ====================
    // Détecter la fin de l'Étape A (section user) - juste après la transition
    if (currentStepData['id'] == 'transition') {
      // Sauvegarder les tags utilisateur (Étape A)
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
        AppLogger.debug('✅ Étape A terminée: Tags utilisateur sauvegardés', 'Debug');
      } catch (e) {
        AppLogger.debug('❌ Erreur sauvegarde tags utilisateur: $e', 'Debug');
      }

      // 🎯 CAS SPÉCIAL: Si onlyUserQuestions=true, on s'arrête ici
      // L'utilisateur modifie juste son profil depuis les paramètres
      if (onlyUserQuestions) {
        AppLogger.debug('✅ Modification profil utilisateur terminée (onlyUserQuestions=true)', 'Debug');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Profil mis à jour avec succès !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Retourner à la page d'origine (ou page Recherche par défaut)
        await Future.delayed(const Duration(milliseconds: 500));
        if (context.mounted) {
          if (returnTo != null && returnTo.isNotEmpty) {
            context.go(returnTo);
          } else {
            context.go('/search-page'); // Redirection vers page Recherche
          }
        }
        isNavigating = false; // Reset le flag avant de return
        return; // Arrêter ici, ne pas créer de personne
      }
    }
    // =================================================================

    if (currentStep < steps.length - 1) {
      currentStep++;
      isNavigating = false; // FIX Bug 2: Reset le flag après l'incrémentation
      AppLogger.debug('✅ Step avancé: $currentStep', 'Debug');
    } else {
      // Onboarding terminé (fin de l'Étape B)
      AppLogger.debug('✅ Onboarding terminé: $answers', 'Debug');

      try {
        // ==================== NOUVELLE ARCHITECTURE ====================
        // 1. Créer la première personne (Étape B) avec isPendingFirstGen=true

        // Déterminer si c'est un username ou un prénom
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
          isPendingFirstGen: true, // Flag pour génération post-auth
        );

        AppLogger.debug('✅ Première personne cre: $personId (isPendingFirstGen=true)', 'Debug');
        // =================================================================

        // 2. Sauvegarder aussi l'ancien format pour compatibilité
        await FirebaseDataService.saveOnboardingAnswers(answers);

        // Afficher un feedback de succès
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Profil sauvegardé avec succès !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // 3. Marquer l'onboarding comme complété (seulement si c'est le premier onboarding)
        if (!skipUserQuestions) {
          await FirstTimeService.setOnboardingCompleted();
        }

        // 4. Navigation
        if (context.mounted) {
          // TOUJOURS montrer la page cadeaux d'abord
          if (personId != null) {
            // Si on a un returnTo, le passer en paramètre pour revenir après
            final returnParam = (returnTo != null && returnTo.isNotEmpty)
                ? '&returnTo=${Uri.encodeComponent(returnTo)}'
                : '';

            // Si c'est le PREMIER onboarding (pas de skipUserQuestions)
            if (!skipUserQuestions) {
              // Aller d'abord à l'authentification AVANT de voir les cadeaux
              AppLogger.debug('🚀 Premier onboarding: Navigation vers authentification puis cadeaux', 'Debug');
              context.go('/authentification?personId=$personId$returnParam');
            } else {
              // Si c'est un ajout de personne, aller directement aux cadeaux
              AppLogger.debug('🚀 Ajout de personne: Navigation directe vers cadeaux', 'Debug');
              context.go('/onboarding-gifts-result?personId=$personId$returnParam');
            }
          } else {
            // Fallback: si pas de personId (erreur)
            AppLogger.debug('⚠️ Pas de personId, navigation vers authentification', 'Debug');
            context.go('/authentification');
          }
        }
      } catch (e) {
        AppLogger.debug('❌ Erreur sauvegarde onboarding: $e', 'Debug');
        isNavigating = false; // Reset le flag en cas d'erreur
        // Même en cas d'erreur, on navigue
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
}
