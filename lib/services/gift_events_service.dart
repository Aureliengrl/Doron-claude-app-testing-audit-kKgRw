import 'dart:async';

/// Bus d'événements global pour notifier la SearchPage
/// quand un cadeau est ajouté depuis le modal produit (product_detail_modal.dart).
///
/// Utilisation :
///   - Émetteur  : GiftEventsService.notifyGiftAdded(personId, gift)
///   - Récepteur : GiftEventsService.onGiftAdded.listen(...)
class GiftEventsService {
  GiftEventsService._();

  static final _controller =
      StreamController<GiftAddedEvent>.broadcast();

  /// Stream écouté par la SearchPage.
  static Stream<GiftAddedEvent> get onGiftAdded => _controller.stream;

  /// Appelé par le modal après un ajout réussi.
  static void notifyGiftAdded(String personId, Map<String, dynamic> gift) {
    _controller.add(GiftAddedEvent(personId: personId, gift: gift));
  }

  /// Ferme proprement le stream (appelé uniquement si l'app est détruite).
  static void dispose() => _controller.close();
}

/// Événement transporté dans le stream.
class GiftAddedEvent {
  final String personId;
  final Map<String, dynamic> gift;
  const GiftAddedEvent({required this.personId, required this.gift});
}
