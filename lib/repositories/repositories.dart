/// Repositories métier — couche d'abstraction sur [FirebaseDataService].
///
/// Ces repositories encapsulent les méthodes statiques de [FirebaseDataService]
/// derrière des interfaces typées et testables, en préparation d'une
/// migration complète vers une architecture Repository/Clean.
///
/// Usage :
/// ```dart
/// // Avant (code hérité) :
/// await FirebaseDataService.saveOnboardingAnswers(answers);
///
/// // Après (nouveau code) :
/// final repo = OnboardingRepository();
/// await repo.saveAnswers(answers);
/// ```
library repositories;

export 'src/onboarding_repository.dart';
export 'src/person_repository.dart';
export 'src/favorites_repository.dart';
export 'src/wishlist_repository.dart';
export 'src/catalog_repository.dart';
