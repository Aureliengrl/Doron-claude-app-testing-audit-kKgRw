// ignore_for_file: avoid_print
/// Seed supplémentaire — 65 produits de marques diversifiées
/// Couvre les angles manquants: sport premium, gaming, cuisine haut de gamme,
/// lifestyle ado, cadeaux pro (collègue), senior, animaux, marques françaises.
///
/// Usage: flutter run -t lib/scripts/seed_products_extra.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _seed();
}

Future<void> _seed() async {
  final db = FirebaseFirestore.instance;
  print('🌱 Seed extra — marques diversifiées...');
  var batch = db.batch();
  int count = 0;
  for (final p in _extra) {
    if (count > 0 && count % 490 == 0) {
      await batch.commit();
      batch = db.batch();
    }
    batch.set(db.collection('gifts').doc(), {
      ...p, 'active': true, 'createdAt': FieldValue.serverTimestamp()
    });
    count++;
  }
  await batch.commit();
  print('✅ $count produits extra insérés.');
}

const _extra = [
  // ── SPORT PREMIUM (marques sous-représentées) ─────────────────────────────
  {'name': 'Veste Trail Salomon Bonatti Race', 'brand': 'Salomon', 'price': 170,
   'image': 'https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=400', 'source': 'salomon.com',
   'tags': ['gender_mixte','cat_mode','budget_100_200','type_sport_outdoor','style_sportif','perso_actif','passion_sport','passion_nature','age_adulte']},
  {'name': 'Chaussures Trail Hoka Speedgoat 5', 'brand': 'Hoka', 'price': 165,
   'image': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400', 'source': 'hoka.com',
   'tags': ['gender_mixte','cat_mode','budget_100_200','type_sport_outdoor','style_sportif','perso_actif','passion_sport','passion_nature','age_adulte']},
  {'name': 'Vêtement Yoga Sweaty Betty Sweat Flow', 'brand': 'Sweaty Betty', 'price': 85,
   'image': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400', 'source': 'sweatybetty.com',
   'tags': ['gender_femme','cat_mode','budget_50_100','type_sport_outdoor','style_sportif','style_minimaliste','perso_actif','passion_yoga','passion_sport','age_adulte']},
  {'name': 'Kettlebell Fonte Compétition 16kg Rogue', 'brand': 'Rogue', 'price': 89,
   'image': 'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?w=400', 'source': 'roguefitness.com',
   'tags': ['gender_mixte','cat_tendances','budget_50_100','type_sport_outdoor','style_sportif','perso_actif','perso_ambitieux','passion_sport','age_adulte']},
  {'name': 'Trottinette Électrique Segway Ninebot MAX G2', 'brand': 'Segway', 'price': 799,
   'image': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400', 'source': 'segway.com',
   'tags': ['gender_mixte','cat_tendances','budget_200+','type_sport_outdoor','type_high_tech','style_moderne','style_tendance','perso_actif','passion_sport','age_ado','age_adulte']},
  {'name': 'Vélo Électrique Ville B\'Twin 500Wh', 'brand': 'B\'Twin','price': 999,
   'image': 'https://images.unsplash.com/photo-1571068316344-75bc76f77890?w=400', 'source': 'decathlon.fr',
   'tags': ['gender_mixte','cat_tendances','budget_200+','type_sport_outdoor','style_eco_responsable','style_moderne','perso_actif','passion_sport','passion_nature','age_adulte']},
  {'name': 'Montre Polar Ignite 3 Triathlon', 'brand': 'Polar', 'price': 249,
   'image': 'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=400', 'source': 'polar.com',
   'tags': ['gender_mixte','cat_tech','budget_200+','type_high_tech','type_sport_outdoor','style_sportif','perso_actif','passion_sport','age_adulte']},

  // ── GAMING & GEEK ─────────────────────────────────────────────────────────
  {'name': 'Casque Gaming Astro A50 Gen 4 Xbox', 'brand': 'Astro', 'price': 299,
   'image': 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=400', 'source': 'astrogaming.com',
   'tags': ['gender_mixte','cat_tech','budget_200+','type_high_tech','type_musique_audio','style_moderne','passion_jeuxvideo','passion_musique','age_ado']},
  {'name': 'Chaise Gaming SecretLab Titan EVO 2022', 'brand': 'SecretLab', 'price': 449,
   'image': 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=400', 'source': 'secretlab.co',
   'tags': ['gender_mixte','cat_tendances','budget_200+','type_high_tech','style_moderne','passion_jeuxvideo','perso_techie','age_ado','age_adulte']},
  {'name': 'Souris Logitech G Pro X Superlight 2 DEX', 'brand': 'Logitech', 'price': 165,
   'image': 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=400', 'source': 'logitech.com',
   'tags': ['gender_mixte','cat_tech','budget_100_200','type_high_tech','style_moderne','passion_jeuxvideo','perso_techie','age_ado']},
  {'name': 'Clavier SteelSeries Apex Pro Mini Wireless', 'brand': 'SteelSeries', 'price': 199,
   'image': 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=400', 'source': 'steelseries.com',
   'tags': ['gender_mixte','cat_tech','budget_100_200','type_high_tech','style_moderne','passion_jeuxvideo','perso_techie','age_ado']},
  {'name': 'Carte Cadeau Xbox 50€', 'brand': 'Xbox', 'price': 50,
   'image': 'https://images.unsplash.com/photo-1606813907291-d86efa9b94db?w=400', 'source': 'xbox.com',
   'tags': ['gender_mixte','cat_tendances','budget_0_50','type_jeux_jouets','type_high_tech','passion_jeuxvideo','age_enfant','age_ado','context_famille','context_ami']},
  {'name': 'Figurine Funko Pop Stranger Things Eleven', 'brand': 'Funko', 'price': 15,
   'image': 'https://images.unsplash.com/photo-1587654780291-39c9404d746b?w=400', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_tendances','budget_0_50','type_maison_deco','style_tendance','passion_cinema','passion_jeuxvideo','age_ado','context_ami']},

  // ── MODE FEMME (marques manquantes) ───────────────────────────────────────
  {'name': 'Sac Polène Numéro Un Micro Caramel', 'brand': 'Polène', 'price': 295,
   'image': 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=400', 'source': 'polene-paris.com',
   'tags': ['gender_femme','cat_mode','budget_200+','type_mode_accessoires','style_elegant','style_minimaliste','perso_ambitieux','passion_mode','age_adulte']},
  {'name': 'Sneakers New Balance 530 Blanc Marine', 'brand': 'New Balance', 'price': 110,
   'image': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400', 'source': 'newbalance.fr',
   'tags': ['gender_femme','cat_mode','budget_100_200','type_mode_accessoires','style_tendance','style_decontracte','passion_mode','age_ado','age_adulte']},
  {'name': 'Bague Argent Améthyste Mauboussin', 'brand': 'Mauboussin', 'price': 199,
   'image': 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=400', 'source': 'mauboussin.fr',
   'tags': ['gender_femme','cat_mode','budget_100_200','type_bijoux','style_elegant','perso_romantique','passion_mode','age_adulte','context_amoureux']},
  {'name': 'Chapeau Bucket Hat Jacquemus Le Bob', 'brand': 'Jacquemus', 'price': 175,
   'image': 'https://images.unsplash.com/photo-1521369909029-2afed882baee?w=400', 'source': 'jacquemus.com',
   'tags': ['gender_femme','cat_mode','budget_100_200','type_mode_accessoires','style_tendance','style_elegant','passion_mode','passion_voyages','age_adulte']},
  {'name': 'Costume Sandro Paris Veste Blazer', 'brand': 'Sandro', 'price': 350,
   'image': 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400', 'source': 'sandro-paris.com',
   'tags': ['gender_femme','cat_mode','budget_200+','type_mode_accessoires','style_elegant','style_tendance','perso_ambitieux','passion_mode','age_adulte']},

  // ── MODE HOMME (marques manquantes) ───────────────────────────────────────
  {'name': 'Sneakers Adidas Samba OG Blanc Noir', 'brand': 'Adidas', 'price': 100,
   'image': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400', 'source': 'adidas.fr',
   'tags': ['gender_homme','cat_mode','budget_50_100','type_mode_accessoires','style_streetwear','style_tendance','passion_mode','passion_sport','age_ado','age_adulte','perso_cool']},
  {'name': 'Sweat Ami de Coeur Ami Paris', 'brand': 'Ami Paris', 'price': 250,
   'image': 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=400', 'source': 'amiparis.com',
   'tags': ['gender_homme','cat_mode','budget_200+','type_mode_accessoires','style_elegant','style_tendance','perso_ambitieux','passion_mode','age_adulte']},
  {'name': 'Polo Ralph Lauren Slim Fit Blanc', 'brand': 'Ralph Lauren', 'price': 110,
   'image': 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=400', 'source': 'ralphlauren.fr',
   'tags': ['gender_homme','cat_mode','budget_100_200','type_mode_accessoires','style_classique','style_elegant','perso_ambitieux','passion_mode','age_adulte']},
  {'name': 'Parfum Jean Paul Gaultier Le Male Elixir', 'brand': 'JPG', 'price': 89,
   'image': 'https://images.unsplash.com/photo-1547887538-e3a2f32cb1cc?w=400', 'source': 'jeanpaulgaultier.com',
   'tags': ['gender_homme','cat_beaute','budget_50_100','type_beaute_soins','style_tendance','perso_ambitieux','perso_romantique','passion_beaute','age_adulte','context_amoureux']},
  {'name': 'Boots Chelsea Cuir Timberland Homme', 'brand': 'Timberland', 'price': 190,
   'image': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400', 'source': 'timberland.fr',
   'tags': ['gender_homme','cat_mode','budget_100_200','type_mode_accessoires','style_classique','style_decontracte','passion_mode','passion_nature','age_adulte']},

  // ── CUISINE & ÉPICERIE FINE ───────────────────────────────────────────────
  {'name': 'KitchenAid Mini Robot Pâtissier 3,3L Mandarine', 'brand': 'KitchenAid', 'price': 349,
   'image': 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=400', 'source': 'kitchenaid.fr',
   'tags': ['gender_femme','cat_maison','budget_200+','type_gastronomie','style_classique','style_tendance','perso_gourmand','perso_creatif','passion_cuisine','age_adulte']},
  {'name': 'Thermomix TM6 Companion Robot Culinaire', 'brand': 'Vorwerk', 'price': 1299,
   'image': 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=400', 'source': 'thermomix.com',
   'tags': ['gender_mixte','cat_maison','budget_200+','type_gastronomie','style_moderne','perso_gourmand','perso_pratique','passion_cuisine','age_adulte','age_senior']},
  {'name': 'Raclette Tefal Pierrade Convivio Max 8p', 'brand': 'Tefal', 'price': 89,
   'image': 'https://images.unsplash.com/photo-1574180045827-681f8a1a9622?w=400', 'source': 'tefal.fr',
   'tags': ['gender_mixte','cat_maison','budget_50_100','type_gastronomie','style_moderne','perso_sociable','perso_gourmand','passion_cuisine','age_adulte','context_famille','context_ami']},
  {'name': 'Pâtes Artigianali Rustichella Pasta Box 6 types', 'brand': 'Rustichella', 'price': 38,
   'image': 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_food','budget_0_50','type_gastronomie','style_elegant','perso_gourmand','passion_cuisine','age_adulte','context_famille']},
  {'name': 'Tablette Chocolat Manufacture Valrhona Coffret', 'brand': 'Valrhona', 'price': 45,
   'image': 'https://images.unsplash.com/photo-1549007994-cb92caebd54b?w=400', 'source': 'valrhona.com',
   'tags': ['gender_mixte','cat_food','budget_0_50','type_gastronomie','style_elegant','style_luxe','perso_gourmand','passion_cuisine','age_adulte','age_senior','context_famille']},
  {'name': 'Miel Artisanal La Ruche Qui Dit Oui 6 Pots', 'brand': 'La Ruche', 'price': 35,
   'image': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400', 'source': 'lrqdo.com',
   'tags': ['gender_mixte','cat_food','budget_0_50','type_gastronomie','style_eco_responsable','perso_bienveillant','passion_cuisine','age_adulte','age_senior']},
  {'name': 'Cours Dégustation Vin Cave Mouton Rothschild', 'brand': 'Mouton Rothschild', 'price': 120,
   'image': 'https://images.unsplash.com/photo-1474722883778-792e7990302f?w=400', 'source': 'chateau-mouton-rothschild.com',
   'tags': ['gender_mixte','cat_food','budget_100_200','type_gastronomie','type_culture','style_luxe','style_elegant','perso_gourmand','perso_sociable','passion_vins','age_adulte','context_ami']},

  // ── MAISON & INTÉRIEUR ────────────────────────────────────────────────────
  {'name': 'Vase en Céramique Fait Main Atelier Kumo', 'brand': 'Kumo', 'price': 65,
   'image': 'https://images.unsplash.com/photo-1561043433-aaf687c4cf04?w=400', 'source': 'atelierkunmo.fr',
   'tags': ['gender_femme','cat_maison','budget_50_100','type_maison_deco','style_boheme','style_minimaliste','perso_creatif','passion_art','age_adulte']},
  {'name': 'Théière en Fonte Japonaise Tetsubin Iwachu', 'brand': 'Iwachu', 'price': 95,
   'image': 'https://images.unsplash.com/photo-1553361371-9b22f78e8b1d?w=400', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_maison','budget_50_100','type_gastronomie','type_maison_deco','style_minimaliste','perso_zen','passion_cuisine','age_adulte','age_senior']},
  {'name': 'Plante Monstera Thai Constellation XL', 'brand': 'Plantes & Jardins', 'price': 89,
   'image': 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400', 'source': 'plantsetjardins.com',
   'tags': ['gender_femme','cat_maison','budget_50_100','type_maison_deco','style_boheme','style_tendance','perso_bienveillant','passion_jardinage','passion_nature','age_adulte']},
  {'name': 'Machine à Pain Panasonic SD-B2510', 'brand': 'Panasonic', 'price': 139,
   'image': 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=400', 'source': 'panasonic.fr',
   'tags': ['gender_mixte','cat_maison','budget_100_200','type_gastronomie','style_moderne','perso_gourmand','perso_pratique','passion_cuisine','age_adulte','age_senior']},
  {'name': 'Aspirateur Balai Dyson V15 Detect Absolute', 'brand': 'Dyson', 'price': 699,
   'image': 'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400', 'source': 'dyson.fr',
   'tags': ['gender_mixte','cat_tech','budget_200+','type_high_tech','type_maison_deco','style_moderne','perso_pratique','age_adulte','age_senior']},
  {'name': 'Bouilloire Électrique KitchenAid Design 1,5L', 'brand': 'KitchenAid', 'price': 149,
   'image': 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400', 'source': 'kitchenaid.fr',
   'tags': ['gender_mixte','cat_maison','budget_100_200','type_gastronomie','type_maison_deco','style_elegant','style_classique','perso_gourmand','passion_cuisine','age_adulte']},

  // ── BIEN-ÊTRE & SPA ───────────────────────────────────────────────────────
  {'name': 'Rituals The Ritual of Ayurveda L Coffret', 'brand': 'Rituals', 'price': 55,
   'image': 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=400', 'source': 'rituals.com',
   'tags': ['gender_femme','cat_beaute','budget_50_100','type_bien_etre','style_elegant','perso_zen','passion_beaute','passion_yoga','age_adulte','context_amoureux']},
  {'name': 'Bon Cadeau Massage Spa 1h Institut', 'brand': 'Spa Collection', 'price': 79,
   'image': 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400', 'source': 'spas.fr',
   'tags': ['gender_femme','cat_tendances','budget_50_100','type_bien_etre','style_luxe','perso_zen','perso_romantique','passion_beaute','passion_yoga','age_adulte','context_amoureux','context_ami']},
  {'name': 'Savon Artisanal Provence Lavande & Miel', 'brand': 'La Parfumerie de Grasse', 'price': 18,
   'image': 'https://images.unsplash.com/photo-1601612628452-9e99ced43524?w=400', 'source': 'grasse.fr',
   'tags': ['gender_femme','cat_beaute','budget_0_50','type_bien_etre','style_eco_responsable','perso_zen','passion_beaute','age_adulte','age_senior','context_famille']},
  {'name': 'Bain Moussant L\'Occitane Amande Huile', 'brand': 'L\'Occitane', 'price': 28,
   'image': 'https://images.unsplash.com/photo-1601612628452-9e99ced43524?w=400', 'source': 'loccitane.fr',
   'tags': ['gender_femme','cat_beaute','budget_0_50','type_bien_etre','style_eco_responsable','perso_zen','passion_beaute','age_adulte']},
  {'name': 'Rouleau de Jade Massage Visage', 'brand': 'Herbivore', 'price': 35,
   'image': 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=400', 'source': 'amazon.fr',
   'tags': ['gender_femme','cat_beaute','budget_0_50','type_bien_etre','style_tendance','style_eco_responsable','perso_zen','passion_beaute','passion_yoga','age_ado','age_adulte']},

  // ── CADEAUX COLLÈGUE ──────────────────────────────────────────────────────
  {'name': 'Carnet Moleskine Classic Hard Cover A5 Noir', 'brand': 'Moleskine', 'price': 22,
   'image': 'https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=400', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_tendances','budget_0_50','type_loisirs_creatifs','style_classique','style_minimaliste','perso_intellectuel','perso_ambitieux','passion_lecture','age_adulte','context_colleague']},
  {'name': 'Mug Thermos Hydro Flask 354ml Coffee', 'brand': 'Hydro Flask', 'price': 35,
   'image': 'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=400', 'source': 'hydroflask.com',
   'tags': ['gender_mixte','cat_tendances','budget_0_50','type_maison_deco','style_moderne','style_eco_responsable','perso_pratique','age_adulte','context_colleague']},
  {'name': 'Prise Multi USB Hub Anker 615', 'brand': 'Anker', 'price': 49,
   'image': 'https://images.unsplash.com/photo-1547082299-de196ea013d6?w=400', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_tech','budget_0_50','type_high_tech','style_moderne','perso_pratique','perso_techie','passion_tech','age_adulte','context_colleague']},
  {'name': 'Repose-Poignet Ergonomique Fellowes', 'brand': 'Fellowes', 'price': 29,
   'image': 'https://images.unsplash.com/photo-1547082299-de196ea013d6?w=400', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_tendances','budget_0_50','type_bien_etre','style_moderne','perso_pratique','age_adulte','context_colleague']},
  {'name': 'Box Bureau Personnalisée avec Café Grains', 'brand': 'La Cafetière', 'price': 45,
   'image': 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400', 'source': 'lacafetiere.com',
   'tags': ['gender_mixte','cat_food','budget_0_50','type_gastronomie','style_moderne','perso_gourmand','passion_cuisine','age_adulte','context_colleague']},

  // ── CADEAUX SENIOR ────────────────────────────────────────────────────────
  {'name': 'Lunettes de Lecture Diopter +2.0 Design', 'brand': 'Chez Rémy', 'price': 45,
   'image': 'https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=400', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_tendances','budget_0_50','type_bien_etre','style_classique','perso_pratique','passion_lecture','age_senior','context_famille']},
  {'name': 'Abonnement France 2/3 en Streaming 6 mois', 'brand': 'France TV', 'price': 0,
   'image': 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=400', 'source': 'francetv.fr',
   'tags': ['gender_mixte','cat_tendances','budget_0_50','type_culture','type_bien_etre','style_classique','perso_intellectuel','passion_cinema','passion_lecture','age_senior','context_famille']},
  {'name': 'Tablette Amazon Fire HD 10 Senior', 'brand': 'Amazon', 'price': 179,
   'image': 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=400', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_tech','budget_100_200','type_high_tech','style_moderne','perso_pratique','passion_lecture','passion_cinema','age_senior','context_famille']},
  {'name': 'Appareil Photo Bridge Sony RX10 IV', 'brand': 'Sony', 'price': 1299,
   'image': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=400', 'source': 'sony.fr',
   'tags': ['gender_mixte','cat_tech','budget_200+','type_high_tech','style_moderne','passion_photo','passion_voyages','age_adulte','age_senior']},

  // ── MARQUES FRANÇAISES ────────────────────────────────────────────────────
  {'name': 'Sac Isabel Marant Wardy Mini Bag Fauve', 'brand': 'Isabel Marant', 'price': 590,
   'image': 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=400', 'source': 'isabelmarant.com',
   'tags': ['gender_femme','cat_mode','budget_200+','type_mode_accessoires','style_elegant','style_tendance','perso_ambitieux','passion_mode','age_adulte']},
  {'name': 'Eau de Parfum Chloé Nomade 75ml', 'brand': 'Chloé', 'price': 118,
   'image': 'https://images.unsplash.com/photo-1524638431109-93d95c968f03?w=400', 'source': 'chloe.com',
   'tags': ['gender_femme','cat_beaute','budget_100_200','type_beaute_soins','style_elegant','style_boheme','passion_beaute','age_adulte','perso_romantique','context_amoureux']},
  {'name': 'Bijou Messika Move Uno Bracelet Diamants', 'brand': 'Messika', 'price': 890,
   'image': 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=400', 'source': 'messika.fr',
   'tags': ['gender_femme','cat_mode','budget_200+','type_bijoux','style_elegant','style_luxe','perso_ambitieux','perso_romantique','passion_mode','age_adulte','context_amoureux']},
  {'name': 'Basket Veja Esplar Animara Blanc Naturel', 'brand': 'Veja', 'price': 120,
   'image': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400', 'source': 'veja-store.com',
   'tags': ['gender_femme','cat_mode','budget_100_200','type_mode_accessoires','style_minimaliste','style_eco_responsable','passion_mode','age_ado','age_adulte']},
  {'name': 'Livre Alain Ducasse Fait Maison', 'brand': 'Alain Ducasse Éditions', 'price': 39,
   'image': 'https://images.unsplash.com/photo-1466637574441-749b8f19452f?w=400', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_food','budget_0_50','type_gastronomie','type_livres_bd','style_elegant','perso_gourmand','passion_cuisine','passion_lecture','age_adulte','age_senior']},

  // ── ENFANTS & FAMILLE ─────────────────────────────────────────────────────
  {'name': 'Livre La Vérité sur l\'Affaire Harry Quebert', 'brand': 'Joël Dicker', 'price': 12,
   'image': 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=400', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_tendances','budget_0_50','type_livres_bd','style_moderne','perso_intellectuel','passion_lecture','age_adulte']},
  {'name': 'Peluche Jellycat Bunny Bunnies Medium 31cm', 'brand': 'Jellycat', 'price': 28,
   'image': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_tendances','budget_0_50','type_jeux_jouets','style_tendance','perso_bienveillant','age_enfant','context_famille']},
  {'name': 'Lego Technic Bugatti Bolide 905 pièces', 'brand': 'Lego', 'price': 59,
   'image': 'https://images.unsplash.com/photo-1587654780291-39c9404d746b?w=400', 'source': 'lego.com',
   'tags': ['gender_homme','cat_tendances','budget_50_100','type_jeux_jouets','type_loisirs_creatifs','perso_creatif','passion_automobile','passion_tech','age_enfant','age_ado','context_famille']},
  {'name': 'Abonnement YouTube Premium Famille 1 an', 'brand': 'Google', 'price': 180,
   'image': 'https://images.unsplash.com/photo-1614680376573-df3480f0c6ff?w=400', 'source': 'youtube.com',
   'tags': ['gender_mixte','cat_tendances','budget_100_200','type_culture','type_musique_audio','passion_cinema','passion_musique','age_enfant','age_ado','age_adulte','context_famille']},

  // ── PHOTOGRAPHIE & CRÉATIFS ───────────────────────────────────────────────
  {'name': 'Objectif Sony 35mm f/1.8 Full Frame', 'brand': 'Sony', 'price': 699,
   'image': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=400', 'source': 'sony.fr',
   'tags': ['gender_mixte','cat_tech','budget_200+','type_high_tech','style_moderne','passion_photo','perso_creatif','age_adulte']},
  {'name': 'Appareil Photo Sony ZV-E10 Vlog Kit', 'brand': 'Sony', 'price': 699,
   'image': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=400', 'source': 'sony.fr',
   'tags': ['gender_mixte','cat_tech','budget_200+','type_high_tech','style_moderne','passion_photo','passion_cinema','perso_creatif','age_ado','age_adulte']},
  {'name': 'Trépied Gorilla Pod 3K Kit', 'brand': 'Gorilla Pod', 'price': 89,
   'image': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=400', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_tendances','budget_50_100','type_high_tech','style_moderne','passion_photo','passion_voyages','perso_creatif','age_adulte']},
  {'name': 'Livre Apprendre la Photo Numérique', 'brand': 'Eyrolles', 'price': 29,
   'image': 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=400', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_tendances','budget_0_50','type_livres_bd','type_culture','style_moderne','perso_creatif','passion_photo','passion_lecture','age_adulte']},
];
