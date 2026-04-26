import 'dart:convert';
import 'package:http/http.dart' as http;
import '/utils/app_logger.dart';

/// Service de géolocalisation et recherche de magasins physiques.
/// Utilise l'API Google Places Nearby Search pour trouver les enseignes
/// proches d'une position géographique, en fonction de la marque produit.
class StoreFinderService {
  /// Retourne false si Google Maps n'est pas configuré — évite les erreurs silencieuses
  static bool get isConfigured {
    const key = String.fromEnvironment('GOOGLE_MAPS_KEY', defaultValue: '');
    return key.isNotEmpty;
  }

  // ── Configuration ─────────────────────────────────────────────────────────
  // ⚠️ Remplacer par votre clé API Google Places
  static const String _apiKey = 'YOUR_GOOGLE_PLACES_API_KEY';
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
  static const int _defaultRadiusMeters = 5000; // 5 km

  // ── Mapping marque → enseigne(s) physique(s) ──────────────────────────────

  static const Map<String, List<String>> brandToStores = {
    // Tech & Électronique
    'apple': ['Apple Store', 'Fnac', 'Darty', 'Boulanger'],
    'samsung': ['Samsung', 'Fnac', 'Darty', 'Boulanger'],
    'sony': ['Fnac', 'Darty', 'Boulanger'],
    'dyson': ['Fnac', 'Darty', 'Boulanger'],

    // Sport
    'nike': ['Nike', 'Sport 2000', 'Décathlon', 'Foot Locker'],
    'adidas': ['Adidas', 'Sport 2000', 'Décathlon', 'Foot Locker'],
    'under armour': ['Décathlon', 'Sport 2000'],
    'puma': ['Sport 2000', 'Décathlon'],
    'decathlon': ['Décathlon'],

    // Beauté / Soin
    'sephora': ['Sephora'],
    'clarins': ['Sephora', 'Marionnaud', 'Douglas'],
    "l'oreal": ['Sephora', 'Marionnaud', 'Douglas'],
    'nuxe': ['Sephora', 'Marionnaud', 'Pharmacie'],
    'ysl': ['Sephora', 'Marionnaud'],
    'dior': ['Sephora', 'Marionnaud'],
    'chanel': ['Chanel', 'Sephora', 'Marionnaud'],

    // Mode
    'zara': ['Zara'],
    'h&m': ['H&M'],
    'uniqlo': ['Uniqlo'],
    'mango': ['Mango'],
    'lacoste': ['Lacoste'],

    // Maison
    'ikea': ['IKEA'],
    'maisons du monde': ['Maisons du Monde'],
    'bolia': ['Bolia'],

    // Jouets
    'lego': ['Joué Club', 'La Grande Récré', 'Fnac'],
    'playmobil': ['Joué Club', 'La Grande Récré'],
    'hasbro': ['Joué Club', 'La Grande Récré', 'Fnac'],

    // Générique / Amazon
    'amazon': ['Fnac', 'Darty'],
    'default': ['Fnac', 'Fnac'],
  };

  // ── API principale ─────────────────────────────────────────────────────────

  /// Trouve les magasins proches vendant potentiellement ce produit.
  ///
  /// [brand] : marque du produit (ex: "Nike")
  /// [lat] / [lng] : coordonnées GPS de l'utilisateur
  /// [radiusMeters] : rayon de recherche (défaut 5 km)
  ///
  /// Retourne une liste de magasins avec nom, adresse, distance, horaires.
  static Future<List<Map<String, dynamic>>> findNearbyStores({
    required String brand,
    required double lat,
    required double lng,
    int radiusMeters = _defaultRadiusMeters,
  }) async {
    try {
      final storeNames = _getStoreNamesForBrand(brand);
      final results = <Map<String, dynamic>>[];

      // Chercher chaque type d'enseigne (max 2 appels pour limiter les coûts)
      for (final storeName in storeNames.take(2)) {
        final stores = await _searchNearby(
          keyword: storeName,
          lat: lat,
          lng: lng,
          radius: radiusMeters,
        );
        for (final s in stores) {
          // Éviter les doublons
          if (!results.any((r) => r['placeId'] == s['placeId'])) {
            results.add(s);
          }
        }
      }

      // Trier par distance
      results.sort((a, b) =>
          (a['distanceMeters'] as int).compareTo(b['distanceMeters'] as int));

      return results.take(8).toList();
    } catch (e) {
      AppLogger.debug('❌ StoreFinderService.findNearbyStores: $e', 'Stores');
      return [];
    }
  }

  /// Recherche le nom standard de l'enseigne pour une marque donnée.
  static List<String> getStoreNamesForBrand(String brand) =>
      _getStoreNamesForBrand(brand);

  static List<String> _getStoreNamesForBrand(String brand) {
    final brandLower = brand.toLowerCase().trim();

    // Cherche une correspondance exacte ou partielle
    for (final entry in brandToStores.entries) {
      if (brandLower.contains(entry.key) || entry.key.contains(brandLower)) {
        return entry.value;
      }
    }

    return brandToStores['default']!;
  }

  // ── Google Places API ──────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> _searchNearby({
    required String keyword,
    required double lat,
    required double lng,
    required int radius,
  }) async {
    if (_apiKey == 'YOUR_GOOGLE_PLACES_API_KEY') {
      // Mode démo — retourner des données factices pour les tests
      return _mockStores(keyword, lat, lng);
    }

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'keyword': keyword,
        'location': '$lat,$lng',
        'radius': radius.toString(),
        'language': 'fr',
        'type': 'store',
        'key': _apiKey,
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      final places = (data['results'] as List?) ?? [];

      return places.map<Map<String, dynamic>>((place) {
        final location = place['geometry']?['location'];
        final storeLat = (location?['lat'] as num?)?.toDouble() ?? lat;
        final storeLng = (location?['lng'] as num?)?.toDouble() ?? lng;
        final distance = _haversineDistance(lat, lng, storeLat, storeLng);

        // Horaires
        final openingHours = place['opening_hours'];
        final isOpen = openingHours?['open_now'] as bool?;

        return {
          'placeId': place['place_id'] ?? '',
          'name': place['name'] ?? keyword,
          'address': place['vicinity'] ?? '',
          'distanceMeters': distance,
          'distanceText': _formatDistance(distance),
          'isOpenNow': isOpen,
          'rating': place['rating'],
          'lat': storeLat,
          'lng': storeLng,
          'mapsUrl':
              'https://www.google.com/maps/place/?q=place_id:${place['place_id']}',
        };
      }).toList();
    } catch (e) {
      AppLogger.debug('❌ Places API error: $e', 'Stores');
      return [];
    }
  }

  // ── Utilitaires ────────────────────────────────────────────────────────────

  /// Distance Haversine entre deux points GPS (en mètres).
  static int _haversineDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0; // Rayon de la Terre en mètres
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = _sin2(dLat / 2) +
        _cos(_toRad(lat1)) * _cos(_toRad(lat2)) * _sin2(dLng / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return (r * c).toInt();
  }

  static double _toRad(double deg) => deg * 3.141592653589793 / 180;
  static double _sin2(double x) => _sin(x) * _sin(x);
  static double _sin(double x) => x - x * x * x / 6;
  static double _cos(double x) => 1 - x * x / 2;
  static double _sqrt(double x) => x <= 0 ? 0 : x * (1 - x / 4);
  static double _atan2(double y, double x) =>
      x > 0 ? y / x : (x < 0 ? y / x + 3.14159 : 1.5708);

  static String _formatDistance(int meters) {
    if (meters < 1000) return '${meters}m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  /// Données de démonstration quand la clé API n'est pas configurée.
  static List<Map<String, dynamic>> _mockStores(
      String keyword, double lat, double lng) {
    return [
      {
        'placeId': 'mock_1',
        'name': keyword,
        'address': '15 Rue du Commerce',
        'distanceMeters': 450,
        'distanceText': '450m',
        'isOpenNow': true,
        'rating': 4.2,
        'lat': lat + 0.004,
        'lng': lng + 0.002,
        'mapsUrl': 'https://maps.google.com',
      },
      {
        'placeId': 'mock_2',
        'name': keyword,
        'address': '87 Avenue de la République',
        'distanceMeters': 1200,
        'distanceText': '1.2 km',
        'isOpenNow': false,
        'rating': 4.5,
        'lat': lat - 0.008,
        'lng': lng + 0.005,
        'mapsUrl': 'https://maps.google.com',
      },
    ];
  }
}
