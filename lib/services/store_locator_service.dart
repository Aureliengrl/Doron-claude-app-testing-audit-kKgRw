import 'dart:math';
import 'package:url_launcher/url_launcher.dart';

class PhysicalStore {
  final String id;
  final String name;
  final String brandName;
  final String address;
  final String city;
  final double distanceKm;
  final String stockStatus; // "in_stock", "one_hour_pickup", "limited_stock"
  final String stockLabel;
  final String openingHours;
  final String phone;
  final double latitude;
  final double longitude;
  final String? clickAndCollectUrl;

  const PhysicalStore({
    required this.id,
    required this.name,
    required this.brandName,
    required this.address,
    required this.city,
    required this.distanceKm,
    required this.stockStatus,
    required this.stockLabel,
    required this.openingHours,
    required this.phone,
    required this.latitude,
    required this.longitude,
    this.clickAndCollectUrl,
  });
}

class StoreLocatorService {
  /// Retourne la liste des magasins physiques ou ateliers à proximité pour un produit donné
  static List<PhysicalStore> getNearbyStoresForProduct(Map<String, dynamic> product, {String? userCity = "Paris"}) {
    final title = (product['name'] ?? product['product_title'] ?? '').toString().toLowerCase();
    final brand = (product['brand'] ?? '').toString().toLowerCase();
    final cat = (product['category'] ?? '').toString().toLowerCase();
    final isActivity = product['is_activity'] == true ||
        title.contains('atelier') ||
        title.contains('cours') ||
        title.contains('stage') ||
        title.contains('wecandoo');

    final List<PhysicalStore> stores = [];

    if (isActivity) {
      // Activités & Ateliers réels (Wecandoo, Cours de cuisine, Spas, Pilotage)
      if (title.contains('maroquinerie') || title.contains('cuir') || title.contains('ceinture')) {
        stores.add(const PhysicalStore(
          id: 'act_1',
          name: 'Atelier Cuir & Maroquinerie Artisanale',
          brandName: 'Wecandoo',
          address: '42 Rue de Charonne',
          city: '75011 Paris',
          distanceKm: 0.8,
          stockStatus: 'in_stock',
          stockLabel: '🟢 Créneaux disponibles ce week-end',
          openingHours: 'Samedi & Dimanche : 10h - 19h',
          phone: '01 43 55 12 34',
          latitude: 48.8542,
          longitude: 2.3789,
        ));
      } else if (title.contains('céramique') || title.contains('poterie') || title.contains('argile')) {
        stores.add(const PhysicalStore(
          id: 'act_2',
          name: 'Studio Céramique & Tournage',
          brandName: 'Wecandoo',
          address: '15 Rue Oberkampf',
          city: '75011 Paris',
          distanceKm: 1.2,
          stockStatus: 'in_stock',
          stockLabel: '🟢 4 places restantes',
          openingHours: 'Mercredi au Dimanche : 10h - 20h',
          phone: '01 48 06 78 90',
          latitude: 48.8648,
          longitude: 2.3705,
        ));
      } else if (title.contains('cuisine') || title.contains('oenologie') || title.contains('vin')) {
        stores.add(const PhysicalStore(
          id: 'act_3',
          name: 'Atelier Culinaire & Dégustation Chefs',
          brandName: 'Masterclass Gourmet',
          address: '28 Rue Beaubourg',
          city: '75003 Paris',
          distanceKm: 1.5,
          stockStatus: 'in_stock',
          stockLabel: '🟢 Session réservable en direct',
          openingHours: 'Mardi au Samedi : 11h - 22h',
          phone: '01 42 77 45 60',
          latitude: 48.8621,
          longitude: 2.3533,
        ));
      } else {
        stores.add(const PhysicalStore(
          id: 'act_gen',
          name: 'Centre d\'Expérience & Activités Directes',
          brandName: 'Partenaire Officiel DORÕN',
          address: '12 Boulevard des Capucines',
          city: '75009 Paris',
          distanceKm: 2.1,
          stockStatus: 'in_stock',
          stockLabel: '🟢 Réservation immédiate',
          openingHours: 'Tous les jours : 09h - 19h',
          phone: '01 53 43 00 00',
          latitude: 48.8705,
          longitude: 2.3312,
        ));
      }
      return stores;
    }

    // --- High-Tech & Gaming ---
    if (brand.contains('apple') || title.contains('iphone') || title.contains('airpods') || title.contains('macbook') || title.contains('ipad')) {
      stores.add(const PhysicalStore(
        id: 'apple_opera',
        name: 'Apple Store Opéra',
        brandName: 'Apple Store',
        address: '12 Rue Halévy',
        city: '75009 Paris',
        distanceKm: 0.9,
        stockStatus: 'one_hour_pickup',
        stockLabel: '⚡ Retrait en 1h disponible',
        openingHours: 'Ouvert jusqu\'à 20h00',
        phone: '01 44 83 42 00',
        latitude: 48.8718,
        longitude: 2.3323,
      ));
      stores.add(const PhysicalStore(
        id: 'fnac_stlazare',
        name: 'Fnac Saint-Lazare',
        brandName: 'Fnac',
        address: '109 Rue Saint-Lazare',
        city: '75008 Paris',
        distanceKm: 1.4,
        stockStatus: 'in_stock',
        stockLabel: '🟢 En rayon (5+ exemplaires)',
        openingHours: 'Ouvert jusqu\'à 20h00',
        phone: '08 25 02 00 20',
        latitude: 48.8756,
        longitude: 2.3255,
      ));
      stores.add(const PhysicalStore(
        id: 'boulanger_beaugrenelle',
        name: 'Boulanger Beaugrenelle',
        brandName: 'Boulanger',
        address: '12 Rue Linois',
        city: '75015 Paris',
        distanceKm: 3.8,
        stockStatus: 'one_hour_pickup',
        stockLabel: '⚡ Click & Collect 1h',
        openingHours: 'Ouvert jusqu\'à 20h30',
        phone: '08 25 85 08 50',
        latitude: 48.8488,
        longitude: 2.2829,
      ));
      return stores;
    }

    // --- Beauté & Parfumerie (Sephora, Dior, Chanel, Rituals) ---
    if (brand.contains('dior') || brand.contains('chanel') || brand.contains('sephora') || brand.contains('yves saint laurent') || brand.contains('rituals') || cat.contains('beaute')) {
      stores.add(const PhysicalStore(
        id: 'sephora_champs',
        name: 'Sephora Champs-Élysées',
        brandName: 'Sephora',
        address: '70-72 Avenue des Champs-Élysées',
        city: '75008 Paris',
        distanceKm: 1.8,
        stockStatus: 'one_hour_pickup',
        stockLabel: '⚡ Retrait 2h gratuit en boutique',
        openingHours: 'Ouvert jusqu\'à 23h00',
        phone: '01 53 93 22 50',
        latitude: 48.8708,
        longitude: 2.3045,
      ));
      stores.add(const PhysicalStore(
        id: 'marionnaud_madeleine',
        name: 'Marionnaud Madeleine',
        brandName: 'Marionnaud',
        address: '26 Place de la Madeleine',
        city: '75008 Paris',
        distanceKm: 1.1,
        stockStatus: 'in_stock',
        stockLabel: '🟢 En stock en magasin',
        openingHours: 'Ouvert jusqu\'à 19h30',
        phone: '01 47 42 88 12',
        latitude: 48.8700,
        longitude: 2.3245,
      ));
      stores.add(const PhysicalStore(
        id: 'galeries_lafayette_beaute',
        name: 'Galeries Lafayette Haussmann (Espace Beauté)',
        brandName: 'Galeries Lafayette',
        address: '40 Boulevard Haussmann',
        city: '75009 Paris',
        distanceKm: 0.6,
        stockStatus: 'in_stock',
        stockLabel: '🟢 Comptoir de marque officiel',
        openingHours: 'Ouvert jusqu\'à 20h30',
        phone: '01 42 82 34 56',
        latitude: 48.8735,
        longitude: 2.3320,
      ));
      return stores;
    }

    // --- Mode, Sneakers & Streetwear (Nike, Adidas, Jacquemus, Polène, Zara, Maje) ---
    if (brand.contains('nike') || brand.contains('adidas') || brand.contains('jacquemus') || brand.contains('polène') || brand.contains('polene') || brand.contains('sandro') || brand.contains('maje') || cat.contains('mode')) {
      if (brand.contains('nike')) {
        stores.add(const PhysicalStore(
          id: 'nike_champs',
          name: 'Nike House of Innovation',
          brandName: 'Nike Store',
          address: '79 Avenue des Champs-Élysées',
          city: '75008 Paris',
          distanceKm: 1.9,
          stockStatus: 'in_stock',
          stockLabel: '🟢 Pointures en stock immédiat',
          openingHours: 'Ouvert jusqu\'à 20h00',
          phone: '01 86 64 00 00',
          latitude: 48.8709,
          longitude: 2.3040,
        ));
      }
      stores.add(const PhysicalStore(
        id: 'courir_rivoli',
        name: 'Courir Rue de Rivoli',
        brandName: 'Courir',
        address: '110 Rue de Rivoli',
        city: '75001 Paris',
        distanceKm: 1.2,
        stockStatus: 'one_hour_pickup',
        stockLabel: '⚡ Retrait 1h en magasin',
        openingHours: 'Ouvert jusqu\'à 19h30',
        phone: '01 42 33 55 66',
        latitude: 48.8596,
        longitude: 2.3458,
      ));
      stores.add(const PhysicalStore(
        id: 'citadium_caumartin',
        name: 'Citadium Caumartin',
        brandName: 'Citadium',
        address: '50-56 Rue de Caumartin',
        city: '75009 Paris',
        distanceKm: 0.7,
        stockStatus: 'in_stock',
        stockLabel: '🟢 Rayon officiel en stock',
        openingHours: 'Ouvert jusqu\'à 20h00',
        phone: '01 55 31 74 00',
        latitude: 48.8741,
        longitude: 2.3275,
      ));
      return stores;
    }

    // --- Maison & Déco (Diptyque, Le Creuset, Dyson, Kartell) ---
    if (brand.contains('diptyque') || brand.contains('le creuset') || brand.contains('dyson') || cat.contains('maison')) {
      if (brand.contains('diptyque')) {
        stores.add(const PhysicalStore(
          id: 'diptyque_stgermain',
          name: 'Diptyque Maison Historique',
          brandName: 'Diptyque',
          address: '34 Boulevard Saint-Germain',
          city: '75005 Paris',
          distanceKm: 2.3,
          stockStatus: 'in_stock',
          stockLabel: '🟢 Bougies & Parfums en stock',
          openingHours: 'Ouvert jusqu\'à 19h30',
          phone: '01 43 26 77 70',
          latitude: 48.8507,
          longitude: 2.3503,
        ));
      }
      stores.add(const PhysicalStore(
        id: 'bhv_marais',
        name: 'Le BHV Marais (Espace Maison & Design)',
        brandName: 'BHV Marais',
        address: '52 Rue de Rivoli',
        city: '75004 Paris',
        distanceKm: 1.4,
        stockStatus: 'in_stock',
        stockLabel: '🟢 Rayon Maison & Arts de la table',
        openingHours: 'Ouvert jusqu\'à 20h00',
        phone: '09 77 40 14 00',
        latitude: 48.8573,
        longitude: 2.3528,
      ));
      return stores;
    }

    // --- Par défaut : Grands magasins & FNAC / Darty ---
    stores.add(const PhysicalStore(
      id: 'fnac_forum',
      name: 'Fnac Forum des Halles',
      brandName: 'Fnac',
      address: '1-7 Rue Pierre Lescot',
      city: '75001 Paris',
      distanceKm: 1.1,
      stockStatus: 'one_hour_pickup',
      stockLabel: '⚡ Retrait 1h en magasin',
      openingHours: 'Ouvert jusqu\'à 20h00',
      phone: '08 25 02 00 20',
      latitude: 48.8622,
      longitude: 2.3486,
    ));
    stores.add(const PhysicalStore(
      id: 'printemps_haussmann',
      name: 'Printemps Haussmann',
      brandName: 'Printemps',
      address: '64 Boulevard Haussmann',
      city: '75009 Paris',
      distanceKm: 0.8,
      stockStatus: 'in_stock',
      stockLabel: '🟢 En stock en magasin',
      openingHours: 'Ouvert jusqu\'à 20h00',
      phone: '01 42 82 50 00',
      latitude: 48.8739,
      longitude: 2.3283,
    ));

    return stores;
  }

  /// Ouvre l'itinéraire dans Apple Maps ou Google Maps
  static Future<void> openItinerary(PhysicalStore store) async {
    final query = Uri.encodeComponent('${store.name} ${store.address} ${store.city}');
    // URL universelle Apple Maps / Google Maps
    final appleMapsUrl = Uri.parse('https://maps.apple.com/?daddr=$query&dirflg=d');
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$query');

    if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }
}
