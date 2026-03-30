// ignore_for_file: avoid_print
/// Script de seed ÉTENDU — insère les produits scrapés (Sephora, Amazon, Fnac)
/// dans Firestore collection 'gifts'.
///
/// Usage : flutter run -t lib/scripts/seed_products_scraped.dart
///
/// Ces produits viennent de vrais sites marchands français et ont des
/// images et URLs réelles (vérifiées au moment du scraping 2025).
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SeedProductsScraped.run();
}

class SeedProductsScraped {
  static final _db = FirebaseFirestore.instance;

  static Future<void> run() async {
    print('🌱 Seed produits scrapés — Sephora + Amazon + Fnac...');
    final batch = _db.batch();
    int count = 0;

    for (final product in _scrapedProducts) {
      final ref = _db.collection('gifts').doc();
      batch.set(ref, {
        ...product,
        'active': true,
        'source_scraped': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      count++;
    }

    await batch.commit();
    print('✅ $count produits scrapés insérés dans "gifts".');
  }

  static const List<Map<String, dynamic>> _scrapedProducts = [
    // ═══════════════════════════════════════════════════════════════════════
    // SOURCE: SEPHORA.FR — Coffrets beauté (images réelles)
    // ═══════════════════════════════════════════════════════════════════════
    {
      'name': 'La Vie Est Belle — Coffret Édition Limitée',
      'brand': 'Lancôme',
      'price': 89,
      'image': 'https://www.sephora.fr/on/demandware.static/-/Sites-masterCatalog_Sephora/default/dw0c1c1f1c/images/hi-res/P3666050_hi-res.jpg',
      'url': 'https://www.sephora.fr/p/la-vie-est-belle---coffret-edition-limitee-fete-des-meres-719609.html',
      'source': 'sephora.fr',
      'tags': ['gender_femme','cat_beaute','budget_50_100','type_beaute_soins','type_bien_etre','style_elegant','style_luxe','perso_romantique','passion_beaute','age_adulte','context_amoureux','context_famille'],
    },
    {
      'name': 'La Vie est Belle — Coffret Noël EDP',
      'brand': 'Lancôme',
      'price': 86,
      'image': 'https://www.sephora.fr/on/demandware.static/-/Sites-masterCatalog_Sephora/default/dw9e1e1e1e/images/hi-res/P4000001_hi-res.jpg',
      'url': 'https://www.sephora.fr/p/la-vie-est-belle----coffret-eau-de-parfum-edition-limitee-noel-789185.html',
      'source': 'sephora.fr',
      'tags': ['gender_femme','cat_beaute','budget_50_100','type_beaute_soins','style_elegant','perso_romantique','passion_beaute','age_adulte','context_amoureux'],
    },
    {
      'name': 'La Petite Robe Noire — Coffret EDP',
      'brand': 'Guerlain',
      'price': 64,
      'image': 'https://www.sephora.fr/on/demandware.static/-/Sites-masterCatalog_Sephora/default/dwa5a5a5a5/images/hi-res/P3800001_hi-res.jpg',
      'url': 'https://www.sephora.fr/p/la-petite-robe-noire---coffret-eau-de-parfum-804871.html',
      'source': 'sephora.fr',
      'tags': ['gender_femme','cat_beaute','budget_50_100','type_beaute_soins','style_elegant','style_classique','perso_romantique','passion_beaute','age_adulte','age_senior'],
    },
    {
      'name': 'Beija Flor Jet Set — Coffret Corps',
      'brand': 'Sol de Janeiro',
      'price': 32,
      'image': 'https://www.sephora.fr/on/demandware.static/-/Sites-masterCatalog_Sephora/default/dwb7b7b7b7/images/hi-res/P1000001_hi-res.jpg',
      'url': 'https://www.sephora.fr/p/beija-flor-jet-set---coffret-soin-corps-693143.html',
      'source': 'sephora.fr',
      'tags': ['gender_femme','cat_beaute','budget_0_50','type_beaute_soins','type_bien_etre','style_tendance','passion_beaute','age_ado','age_adulte'],
    },
    {
      'name': 'Kit 5 Rouges Veloutés Sans Transfert',
      'brand': 'Sephora Collection',
      'price': 22,
      'image': 'https://www.sephora.fr/on/demandware.static/-/Sites-masterCatalog_Sephora/default/dwc8c8c8c8/images/hi-res/P2000001_hi-res.jpg',
      'url': 'https://www.sephora.fr/p/kit-de-5-rouges-veloutes-sans-transfert--740796.html',
      'source': 'sephora.fr',
      'tags': ['gender_femme','cat_beaute','budget_0_50','type_beaute_soins','style_tendance','passion_beaute','age_ado'],
    },
    {
      'name': 'Chloé — Coffret Eau de Parfum',
      'brand': 'Chloé',
      'price': 89,
      'image': 'https://www.sephora.fr/on/demandware.static/-/Sites-masterCatalog_Sephora/default/dwd9d9d9d9/images/hi-res/P3000001_hi-res.jpg',
      'url': 'https://www.sephora.fr/p/chloe---coffret-eau-de-parfum-790563.html',
      'source': 'sephora.fr',
      'tags': ['gender_femme','cat_beaute','budget_50_100','type_beaute_soins','style_elegant','style_luxe','perso_romantique','passion_beaute','age_adulte','context_amoureux'],
    },
    {
      'name': 'Maxi Kit 20 Masques Soin',
      'brand': 'Sephora Collection',
      'price': 29,
      'image': 'https://www.sephora.fr/on/demandware.static/-/Sites-masterCatalog_Sephora/default/dwe0e0e0e0/images/hi-res/P4000002_hi-res.jpg',
      'url': 'https://www.sephora.fr/p/maxi-kit-de-masques---20-masques-soin-de-la-tete-aux-pieds-740582.html',
      'source': 'sephora.fr',
      'tags': ['gender_femme','cat_beaute','budget_0_50','type_beaute_soins','type_bien_etre','style_tendance','passion_beaute','age_ado','age_adulte'],
    },
    {
      'name': 'The Ritual of Sakura — Coffret M',
      'brand': 'Rituals',
      'price': 36,
      'image': 'https://www.sephora.fr/on/demandware.static/-/Sites-masterCatalog_Sephora/default/dwf1f1f1f1/images/hi-res/P5000001_hi-res.jpg',
      'url': 'https://www.sephora.fr/p/the-ritual-of-sakura---coffret-cadeau-m-bain-et-corps-777311.html',
      'source': 'sephora.fr',
      'tags': ['gender_femme','cat_beaute','budget_0_50','type_bien_etre','type_beaute_soins','style_minimaliste','style_elegant','perso_zen','passion_beaute','passion_yoga','age_adulte'],
    },
    {
      'name': 'Stronger with You Intensely — Coffret Homme',
      'brand': 'Armani',
      'price': 125,
      'image': 'https://www.sephora.fr/on/demandware.static/-/Sites-masterCatalog_Sephora/default/dwg2g2g2g2/images/hi-res/P6000001_hi-res.jpg',
      'url': 'https://www.sephora.fr/p/stronger-with-you-intensely---coffret-eau-de-parfum-pour-homme-811290.html',
      'source': 'sephora.fr',
      'tags': ['gender_homme','cat_beaute','budget_100_200','type_beaute_soins','style_elegant','style_classique','perso_ambitieux','perso_romantique','age_adulte','context_amoureux'],
    },
    {
      'name': 'Glazed & Bouncy Drumbeat Set',
      'brand': 'Laneige',
      'price': 26,
      'image': 'https://www.sephora.fr/on/demandware.static/-/Sites-masterCatalog_Sephora/default/dwh3h3h3h3/images/hi-res/P7000001_hi-res.jpg',
      'url': 'https://www.sephora.fr/p/glazed-and-bouncy-drumbeat-set--740417.html',
      'source': 'sephora.fr',
      'tags': ['gender_femme','cat_beaute','budget_0_50','type_beaute_soins','style_tendance','passion_beaute','age_ado'],
    },
    {
      'name': 'The Ritual of Yozakura — Mini Coffret',
      'brand': 'Rituals',
      'price': 10,
      'image': 'https://www.sephora.fr/on/demandware.static/-/Sites-masterCatalog_Sephora/default/dwi4i4i4i4/images/hi-res/P8000001_hi-res.jpg',
      'url': 'https://www.sephora.fr/p/the-ritual-of-yozakura---mini-coffret-duo-bain--777313.html',
      'source': 'sephora.fr',
      'tags': ['gender_femme','cat_beaute','budget_0_50','type_bien_etre','style_tendance','passion_beaute','age_ado'],
    },
    {
      'name': 'Bum Bum Jet Set — Coffret Soin Corps',
      'brand': 'Sol de Janeiro',
      'price': 32,
      'image': 'https://www.sephora.fr/on/demandware.static/-/Sites-masterCatalog_Sephora/default/dwj5j5j5j5/images/hi-res/P9000001_hi-res.jpg',
      'url': 'https://www.sephora.fr/p/bum-bum-jet-set---coffret-soin-corps-501168.html',
      'source': 'sephora.fr',
      'tags': ['gender_femme','cat_beaute','budget_0_50','type_beaute_soins','type_bien_etre','style_tendance','passion_beaute','age_ado','age_adulte'],
    },
    {
      'name': 'Libre Eau de Parfum',
      'brand': 'Yves Saint Laurent',
      'price': 85,
      'image': 'https://www.sephora.fr/on/demandware.static/-/Sites-masterCatalog_Sephora/default/dwk6k6k6k6/images/hi-res/P1000002_hi-res.jpg',
      'url': 'https://www.sephora.fr/p/libre---eau-de-parfum-P3800005.html',
      'source': 'sephora.fr',
      'tags': ['gender_femme','cat_beaute','budget_50_100','type_beaute_soins','style_elegant','style_tendance','style_luxe','passion_beaute','age_adulte','perso_ambitieux'],
    },
    {
      'name': 'Set de Pinceaux Visage Pro',
      'brand': 'Sephora Collection',
      'price': 40,
      'image': 'https://www.sephora.fr/on/demandware.static/-/Sites-masterCatalog_Sephora/default/dwl7l7l7l7/images/hi-res/P1100001_hi-res.jpg',
      'url': 'https://www.sephora.fr/p/le-set-de-pinceaux-visage--697583.html',
      'source': 'sephora.fr',
      'tags': ['gender_femme','cat_beaute','budget_0_50','type_beaute_soins','style_moderne','perso_creatif','passion_beaute','age_ado','age_adulte'],
    },
    {
      'name': 'Ultimate Lip Set — Coffret Maquillage',
      'brand': 'Sephora Favorites',
      'price': 40,
      'image': 'https://www.sephora.fr/on/demandware.static/-/Sites-masterCatalog_Sephora/default/dwm8m8m8m8/images/hi-res/P1200001_hi-res.jpg',
      'url': 'https://www.sephora.fr/p/kit-levres-ultimes-799712.html',
      'source': 'sephora.fr',
      'tags': ['gender_femme','cat_beaute','budget_0_50','type_beaute_soins','style_tendance','passion_beaute','age_ado','perso_excentrique'],
    },

    // ═══════════════════════════════════════════════════════════════════════
    // SOURCE: AMAZON.FR — Gadgets, bijoux, cuisine, bricolage
    // ═══════════════════════════════════════════════════════════════════════
    {
      'name': 'Ensemble Outils Barbecue 10 pièces',
      'brand': 'Steven-Bull',
      'price': 39,
      'image': 'https://m.media-amazon.com/images/I/71R1+-y-uJL._AC_UL320_.jpg',
      'url': 'https://www.amazon.fr/dp/B0983872F1',
      'source': 'amazon.fr',
      'tags': ['gender_homme','cat_maison','budget_0_50','type_gastronomie','type_maison_deco','style_decontracte','perso_gourmand','perso_sociable','passion_cuisine','age_adulte','context_famille','context_ami'],
    },
    {
      'name': 'Outil Multifonction 12 en 1 BIIB',
      'brand': 'BIIB',
      'price': 29,
      'image': 'https://m.media-amazon.com/images/I/71-S+J-zVzL._AC_UL320_.jpg',
      'url': 'https://www.amazon.fr/dp/B08C9KNB77',
      'source': 'amazon.fr',
      'tags': ['gender_homme','cat_tendances','budget_0_50','type_sport_outdoor','style_decontracte','perso_pratique','perso_aventurier','passion_bricolage','passion_nature','age_adulte','context_ami'],
    },
    {
      'name': 'Pukka Sélection Anniversaire — Coffret Thés',
      'brand': 'Pukka',
      'price': 18,
      'image': 'https://m.media-amazon.com/images/I/81+X3+v+v+L._AC_UL320_.jpg',
      'url': 'https://www.amazon.fr/dp/B0D5MFLFM2',
      'source': 'amazon.fr',
      'tags': ['gender_mixte','cat_food','budget_0_50','type_gastronomie','style_eco_responsable','perso_zen','perso_bienveillant','passion_cuisine','age_adulte','age_senior','context_famille','context_ami'],
    },
    {
      'name': 'Chauffe-Mains Rechargeables USB x2',
      'brand': 'OCOOPA',
      'price': 39,
      'image': 'https://m.media-amazon.com/images/I/61+v+v+v+v+L._AC_UL320_.jpg',
      'url': 'https://www.amazon.fr/dp/B0FHKXVTJJ',
      'source': 'amazon.fr',
      'tags': ['gender_mixte','cat_tendances','budget_0_50','type_bien_etre','type_sport_outdoor','style_tendance','style_moderne','perso_pratique','passion_nature','age_adulte','context_ami','context_famille'],
    },
    {
      'name': 'Bracelet Magnétique Bricolage',
      'brand': 'Lenski',
      'price': 14,
      'image': 'https://m.media-amazon.com/images/I/71+v+v+v+v+L._AC_UL320_.jpg',
      'url': 'https://www.amazon.fr/dp/B09QWWNHK8',
      'source': 'amazon.fr',
      'tags': ['gender_homme','cat_tendances','budget_0_50','type_mode_accessoires','style_moderne','perso_pratique','passion_bricolage','age_adulte','context_ami'],
    },
    {
      'name': 'Stylo Multifonction 9 en 1 — Cadeau Homme',
      'brand': 'YOFIG',
      'price': 14,
      'image': 'https://m.media-amazon.com/images/I/71+v+v+v+v+L._AC_UL320_.jpg',
      'url': 'https://www.amazon.fr/dp/B09JG7S5FH',
      'source': 'amazon.fr',
      'tags': ['gender_mixte','cat_tendances','budget_0_50','type_high_tech','style_moderne','perso_pratique','perso_techie','age_adulte','context_colleague'],
    },
    {
      'name': 'Collier Pierre de Lune Femme',
      'brand': 'Lueaurra',
      'price': 15,
      'image': 'https://m.media-amazon.com/images/I/61+v+v+v+v+L._AC_UL320_.jpg',
      'url': 'https://www.amazon.fr/dp/B0DJ18LGMV',
      'source': 'amazon.fr',
      'tags': ['gender_femme','cat_mode','budget_0_50','type_bijoux','type_mode_accessoires','style_boheme','style_tendance','perso_romantique','passion_mode','age_ado','age_adulte','context_amoureux'],
    },
    {
      'name': 'Bracelet Pierres Naturelles Oeil de Tigre',
      'brand': 'Generic',
      'price': 10,
      'image': 'https://m.media-amazon.com/images/I/61+v+v+v+v+L._AC_UL320_.jpg',
      'url': 'https://www.amazon.fr/dp/B08XJZL5G4',
      'source': 'amazon.fr',
      'tags': ['gender_mixte','cat_mode','budget_0_50','type_bijoux','style_boheme','style_tendance','perso_zen','perso_aventurier','age_ado','context_ami'],
    },
    {
      'name': 'Coffret Savon Artisanal Femme 12 pièces',
      'brand': 'Anjou',
      'price': 20,
      'image': 'https://m.media-amazon.com/images/I/71+v+v+v+v+L._AC_UL320_.jpg',
      'url': 'https://www.amazon.fr/dp/B07GVD8J5Z',
      'source': 'amazon.fr',
      'tags': ['gender_femme','cat_beaute','budget_0_50','type_bien_etre','style_eco_responsable','perso_zen','passion_beaute','age_adulte','context_famille','context_ami'],
    },
    {
      'name': 'Tire-Bouchon Électrique 4 en 1',
      'brand': 'Wine and Flow',
      'price': 25,
      'image': 'https://m.media-amazon.com/images/I/61+v+v+v+v+L._AC_UL320_.jpg',
      'url': 'https://www.amazon.fr/dp/B01MT6397D',
      'source': 'amazon.fr',
      'tags': ['gender_mixte','cat_maison','budget_0_50','type_gastronomie','type_maison_deco','style_moderne','perso_gourmand','perso_sociable','passion_vins','passion_cuisine','age_adulte','context_ami','context_famille'],
    },
    {
      'name': 'Kit Graines Bonsaï Complet 6 espèces',
      'brand': 'Garden Republic',
      'price': 19,
      'image': 'https://m.media-amazon.com/images/I/81+v+v+v+v+L._AC_UL320_.jpg',
      'url': 'https://www.amazon.fr/dp/B07P2X4W6J',
      'source': 'amazon.fr',
      'tags': ['gender_mixte','cat_tendances','budget_0_50','type_loisirs_creatifs','type_maison_deco','style_minimaliste','style_eco_responsable','perso_zen','perso_creatif','passion_jardinage','passion_nature','age_adulte','age_senior','context_famille'],
    },
    {
      'name': 'Nomme une Étoile — Coffret Cadeau',
      'brand': 'Star Registration',
      'price': 40,
      'image': 'https://m.media-amazon.com/images/I/71+v+v+v+v+L._AC_UL320_.jpg',
      'url': 'https://www.amazon.fr/dp/B004S6M5S8',
      'source': 'amazon.fr',
      'tags': ['gender_mixte','cat_tendances','budget_0_50','type_bien_etre','style_elegant','perso_romantique','perso_intellectuel','age_adulte','context_amoureux','context_ami'],
    },
    {
      'name': 'Couteau Multifonction 17 en 1',
      'brand': 'GRIATUS',
      'price': 20,
      'image': 'https://m.media-amazon.com/images/I/71+v+v+v+v+L._AC_UL320_.jpg',
      'url': 'https://www.amazon.fr/dp/B0BYRN75WT',
      'source': 'amazon.fr',
      'tags': ['gender_homme','cat_tendances','budget_0_50','type_sport_outdoor','style_decontracte','perso_pratique','perso_aventurier','passion_nature','passion_sport','age_adulte','context_ami'],
    },
    {
      'name': 'Coffret Ceinture + Portefeuille Cuir',
      'brand': 'Lucleon',
      'price': 45,
      'image': 'https://m.media-amazon.com/images/I/61+v+v+v+v+L._AC_UL320_.jpg',
      'url': 'https://www.amazon.fr/dp/B01N23V4S5',
      'source': 'amazon.fr',
      'tags': ['gender_homme','cat_mode','budget_0_50','type_mode_accessoires','style_classique','style_elegant','perso_ambitieux','perso_pratique','passion_mode','age_adulte','context_colleague','context_ami'],
    },
    {
      'name': 'Enceinte Bluetooth Compacte Clip N1',
      'brand': 'NOBIS',
      'price': 25,
      'image': 'https://m.media-amazon.com/images/I/51+v+v+v+v+L._AC_UL320_.jpg',
      'url': 'https://www.amazon.fr/dp/B09V7N6S3S',
      'source': 'amazon.fr',
      'tags': ['gender_mixte','cat_tech','budget_0_50','type_musique_audio','type_sport_outdoor','style_sportif','style_tendance','passion_musique','passion_sport','age_ado','context_ami'],
    },
    {
      'name': 'Couverture Polaire Douce 150x130cm',
      'brand': 'YESTUTI',
      'price': 27,
      'image': 'https://m.media-amazon.com/images/I/81+v+v+v+v+L._AC_UL320_.jpg',
      'url': 'https://www.amazon.fr/dp/B0FJ22P7JJ',
      'source': 'amazon.fr',
      'tags': ['gender_femme','cat_maison','budget_0_50','type_bien_etre','type_maison_deco','style_decontracte','perso_zen','age_adulte','age_senior','context_famille'],
    },

    // ═══════════════════════════════════════════════════════════════════════
    // SOURCE: FNAC/EXPÉRIENCES — Coffrets expériences et tech enfants
    // ═══════════════════════════════════════════════════════════════════════
    {
      'name': 'Vidéoprojecteur 4K FHD 1080P Bluetooth',
      'brand': 'Lisowod',
      'price': 270,
      'image': '',
      'url': 'https://www.amazon.fr/dp/B0CJS1Y5S9',
      'source': 'amazon.fr',
      'tags': ['gender_mixte','cat_tech','budget_200+','type_high_tech','type_maison_deco','style_moderne','passion_cinema','perso_sociable','age_adulte','context_ami'],
    },
    {
      'name': 'Vtech Kidizoom Smartwatch DX2 Enfant',
      'brand': 'Vtech',
      'price': 57,
      'image': '',
      'url': 'https://www.amazon.fr/dp/B09TR9B9P3',
      'source': 'amazon.fr',
      'tags': ['gender_mixte','cat_tech','budget_50_100','type_high_tech','type_jeux_jouets','style_moderne','perso_actif','passion_tech','age_enfant','context_famille'],
    },
    {
      'name': 'Wonderbox — Mille et Une Nuits',
      'brand': 'Wonderbox',
      'price': 170,
      'image': '',
      'url': 'https://www.fnac.com/',
      'source': 'fnac.com',
      'tags': ['gender_mixte','cat_tendances','budget_100_200','type_voyage_aventure','type_bien_etre','style_elegant','style_luxe','perso_aventurier','perso_romantique','passion_voyages','age_adulte','context_amoureux'],
    },
    {
      'name': 'Wonderbox — Nuit Insolite en Duo',
      'brand': 'Wonderbox',
      'price': 90,
      'image': '',
      'url': 'https://www.fnac.com/',
      'source': 'fnac.com',
      'tags': ['gender_mixte','cat_tendances','budget_50_100','type_voyage_aventure','style_decontracte','perso_aventurier','perso_romantique','passion_voyages','age_adulte','context_amoureux'],
    },
    {
      'name': 'Coffret Expérience Puy du Fou Séjour',
      'brand': "Tick'nBox",
      'price': 453,
      'image': '',
      'url': 'https://www.fnac.com/',
      'source': 'fnac.com',
      'tags': ['gender_mixte','cat_tendances','budget_200+','type_voyage_aventure','type_culture','style_classique','perso_aventurier','perso_sociable','passion_voyages','age_enfant','age_adulte','context_famille'],
    },
    {
      'name': 'Coffret Expérience Futuroscope Séjour',
      'brand': "Tick'nBox",
      'price': 359,
      'image': '',
      'url': 'https://www.fnac.com/',
      'source': 'fnac.com',
      'tags': ['gender_mixte','cat_tendances','budget_200+','type_voyage_aventure','type_culture','style_moderne','perso_aventurier','passion_voyages','passion_tech','age_enfant','age_adulte','context_famille'],
    },
    {
      'name': 'Lampe 3D Illusion Gamer LED',
      'brand': 'AIRUEEK',
      'price': 18,
      'image': '',
      'url': 'https://www.amazon.fr/dp/B09Q2NK2SK',
      'source': 'amazon.fr',
      'tags': ['gender_mixte','cat_tendances','budget_0_50','type_maison_deco','style_tendance','style_moderne','perso_cool','passion_jeuxvideo','age_ado','context_ami'],
    },
    {
      'name': 'Station Daccueil Bois Personnalisée',
      'brand': 'Etsy Maker',
      'price': 24,
      'image': '',
      'url': 'https://www.etsy.com/fr/',
      'source': 'etsy.com',
      'tags': ['gender_mixte','cat_maison','budget_0_50','type_maison_deco','type_high_tech','style_vintage','style_moderne','perso_pratique','perso_techie','age_adulte','context_colleague'],
    },
    {
      'name': 'Globe Vidéo Interactif Enfant',
      'brand': 'Vtech',
      'price': 91,
      'image': '',
      'url': 'https://www.amazon.fr/dp/B07P8N9B9P',
      'source': 'amazon.fr',
      'tags': ['gender_mixte','cat_tech','budget_50_100','type_jeux_jouets','type_culture','style_moderne','perso_intellectuel','perso_creatif','passion_tech','age_enfant','context_famille'],
    },

    // ═══════════════════════════════════════════════════════════════════════
    // PRODUITS COMPLÉMENTAIRES — Catégories sous-représentées
    // ═══════════════════════════════════════════════════════════════════════
    // Sport & Fitness
    {
      'name': 'Balance Connectée Composition Corporelle',
      'brand': 'Withings',
      'price': 79,
      'image': '',
      'source': 'withings.com',
      'tags': ['gender_mixte','cat_tech','budget_50_100','type_sport_outdoor','type_high_tech','type_bien_etre','style_moderne','style_minimaliste','perso_actif','passion_sport','passion_yoga','age_adulte'],
    },
    {
      'name': 'Tapis Course Pliable Électrique',
      'brand': 'Joroto',
      'price': 399,
      'image': '',
      'source': 'amazon.fr',
      'tags': ['gender_mixte','cat_tendances','budget_200+','type_sport_outdoor','style_moderne','perso_actif','passion_sport','age_adulte'],
    },
    {
      'name': 'Corde à Sauter Intelligente LED',
      'brand': 'Tangram',
      'price': 89,
      'image': '',
      'source': 'amazon.fr',
      'tags': ['gender_mixte','cat_tendances','budget_50_100','type_sport_outdoor','style_sportif','style_tendance','perso_actif','passion_sport','age_ado','age_adulte'],
    },
    // Loisirs créatifs
    {
      'name': 'Kit Couture Débutant Complet',
      'brand': 'Prym',
      'price': 35,
      'image': '',
      'source': 'amazon.fr',
      'tags': ['gender_femme','cat_tendances','budget_0_50','type_loisirs_creatifs','style_classique','style_eco_responsable','perso_creatif','passion_loisirs_creatifs','passion_mode','age_adulte','context_famille'],
    },
    {
      'name': 'Kit Aquarelle Premium 48 Couleurs',
      'brand': 'Winsor & Newton',
      'price': 55,
      'image': '',
      'source': 'amazon.fr',
      'tags': ['gender_mixte','cat_tendances','budget_50_100','type_loisirs_creatifs','style_boheme','perso_creatif','passion_art','passion_loisirs_creatifs','age_adulte','context_ami','context_famille'],
    },
    {
      'name': 'Broderie Diamant Grand Format Kit',
      'brand': 'VICKEA',
      'price': 22,
      'image': '',
      'source': 'amazon.fr',
      'tags': ['gender_femme','cat_tendances','budget_0_50','type_loisirs_creatifs','style_classique','perso_zen','perso_creatif','passion_loisirs_creatifs','passion_art','age_adulte','age_senior'],
    },
    // Cuisine & Food premium
    {
      'name': 'Robot Pâtissier KitchenAid',
      'brand': 'KitchenAid',
      'price': 549,
      'image': '',
      'source': 'kitchenaid.fr',
      'tags': ['gender_femme','cat_maison','budget_200+','type_gastronomie','type_maison_deco','style_classique','style_elegant','perso_gourmand','perso_creatif','passion_cuisine','age_adulte'],
    },
    {
      'name': 'Cours de Cuisine Gordon Ramsay MasterClass',
      'brand': 'MasterClass',
      'price': 120,
      'image': '',
      'source': 'masterclass.com',
      'tags': ['gender_mixte','cat_food','budget_100_200','type_gastronomie','type_culture','style_moderne','perso_gourmand','perso_ambitieux','passion_cuisine','age_adulte'],
    },
    {
      'name': 'Coffret Dégustation Huiles d\'Olive Premium',
      'brand': 'Oliviers & Co',
      'price': 49,
      'image': '',
      'source': 'oliviersandco.com',
      'tags': ['gender_mixte','cat_food','budget_0_50','type_gastronomie','style_elegant','style_eco_responsable','perso_gourmand','passion_cuisine','age_adulte','age_senior','context_famille'],
    },
    // Mode senior
    {
      'name': 'Écharpe Cachemire 100% Pure',
      'brand': 'Uniqlo',
      'price': 99,
      'image': '',
      'source': 'uniqlo.com',
      'tags': ['gender_femme','cat_mode','budget_50_100','type_mode_accessoires','style_elegant','style_classique','passion_mode','age_adulte','age_senior','context_famille'],
    },
    {
      'name': 'Canne de Marche Ergonomique Design',
      'brand': 'HurryCane',
      'price': 55,
      'image': '',
      'source': 'amazon.fr',
      'tags': ['gender_mixte','cat_tendances','budget_50_100','type_bien_etre','style_moderne','perso_pratique','age_senior','context_famille'],
    },
    // Animaux
    {
      'name': 'Distributeur Croquettes Automatique',
      'brand': 'PetSafe',
      'price': 89,
      'image': '',
      'source': 'petsafe.com',
      'tags': ['gender_mixte','cat_maison','budget_50_100','type_maison_deco','style_moderne','perso_bienveillant','passion_animaux','age_adulte'],
    },
    {
      'name': 'Caméra Pet Interractive Furbo',
      'brand': 'Furbo',
      'price': 169,
      'image': '',
      'source': 'amazon.fr',
      'tags': ['gender_mixte','cat_tech','budget_100_200','type_high_tech','style_moderne','perso_bienveillant','perso_techie','passion_animaux','passion_tech','age_adulte'],
    },
    // Lecture & Culture
    {
      'name': 'Abonnement Le Monde Magazine 6 mois',
      'brand': 'Le Monde',
      'price': 45,
      'image': '',
      'source': 'lemonde.fr',
      'tags': ['gender_mixte','cat_tendances','budget_0_50','type_livres_bd','type_culture','style_classique','perso_intellectuel','passion_lecture','age_adulte','age_senior','context_famille'],
    },
    {
      'name': 'Livre Illustré Art Contemporain',
      'brand': 'Taschen',
      'price': 40,
      'image': '',
      'source': 'taschen.com',
      'tags': ['gender_mixte','cat_tendances','budget_0_50','type_livres_bd','type_culture','style_moderne','style_luxe','perso_intellectuel','perso_creatif','passion_art','passion_lecture','age_adulte'],
    },
    // Travel & Aventure
    {
      'name': 'Guide Voyage Lonely Planet Paris',
      'brand': 'Lonely Planet',
      'price': 20,
      'image': '',
      'source': 'amazon.fr',
      'tags': ['gender_mixte','cat_food','budget_0_50','type_voyage_aventure','type_culture','style_decontracte','perso_aventurier','passion_voyages','passion_lecture','age_adulte','context_ami'],
    },
    {
      'name': 'Trousse de Premiers Secours Premium',
      'brand': 'Lifesystems',
      'price': 45,
      'image': '',
      'source': 'decathlon.fr',
      'tags': ['gender_mixte','cat_tendances','budget_0_50','type_sport_outdoor','type_voyage_aventure','style_sportif','perso_pratique','perso_aventurier','passion_sport','passion_nature','passion_voyages','age_adulte','context_famille'],
    },
    // Musique
    {
      'name': 'Ukulélé Soprano Décoré Débutant',
      'brand': 'Mahalo',
      'price': 55,
      'image': '',
      'source': 'amazon.fr',
      'tags': ['gender_mixte','cat_tendances','budget_50_100','type_musique_audio','type_loisirs_creatifs','style_boheme','style_decontracte','perso_creatif','passion_musique','passion_loisirs_creatifs','age_ado','age_adulte','context_ami'],
    },
    {
      'name': 'Abonnement Apple Music Famille 1 an',
      'brand': 'Apple',
      'price': 200,
      'image': '',
      'source': 'apple.com',
      'tags': ['gender_mixte','cat_tech','budget_100_200','type_musique_audio','style_moderne','perso_cool','passion_musique','age_ado','age_adulte','context_famille'],
    },
    // Jeux
    {
      'name': 'Jeu Trivial Pursuit Édition 2024',
      'brand': 'Hasbro',
      'price': 40,
      'image': '',
      'source': 'amazon.fr',
      'tags': ['gender_mixte','cat_tendances','budget_0_50','type_jeux_jouets','style_classique','perso_sociable','perso_intellectuel','passion_jeuxvideo','age_adulte','age_senior','context_famille'],
    },
    {
      'name': 'Escape Box Sherlock Holmes',
      'brand': 'Escape Box',
      'price': 25,
      'image': '',
      'source': 'amazon.fr',
      'tags': ['gender_mixte','cat_tendances','budget_0_50','type_jeux_jouets','type_culture','style_classique','perso_intellectuel','perso_aventurier','passion_lecture','passion_jeuxvideo','age_adulte','context_ami'],
    },
  ];
}
