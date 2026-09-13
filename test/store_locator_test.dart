import 'package:flutter_test/flutter_test.dart';
import 'package:doron/services/store_locator_service.dart';

void main() {
  test('Test StoreLocatorService resolves physical stores and activities', () {
    // 1. Tech (Apple)
    final appleStores = StoreLocatorService.getNearbyStoresForProduct({
      'name': 'Apple iPhone 15 Pro Max',
      'brand': 'Apple',
      'category': 'cat_tech',
    });
    expect(appleStores.isNotEmpty, true);
    expect(appleStores.any((s) => s.name.contains('Apple Store') || s.name.contains('Fnac')), true);

    // 2. Beauté (Dior / Sephora)
    final beautyStores = StoreLocatorService.getNearbyStoresForProduct({
      'name': 'Dior Sauvage Eau de Parfum',
      'brand': 'Dior',
      'category': 'cat_beaute',
    });
    expect(beautyStores.isNotEmpty, true);
    expect(beautyStores.any((s) => s.name.contains('Sephora') || s.name.contains('Marionnaud')), true);

    // 3. Activité artisanale Wecandoo
    final activityStores = StoreLocatorService.getNearbyStoresForProduct({
      'name': 'Wecandoo - Réalisez votre accessoire de maroquinerie',
      'brand': 'Wecandoo',
      'category': 'cat_activites_experiences',
      'is_activity': true,
    });
    expect(activityStores.isNotEmpty, true);
    expect(activityStores.first.address.isNotEmpty, true);
    expect(activityStores.first.distanceKm > 0, true);
  });
}
