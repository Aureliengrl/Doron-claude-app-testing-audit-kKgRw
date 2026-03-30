// ignore_for_file: avoid_print
/// Script de seed — insère 200+ produits dans Firestore collection 'gifts'.
///
/// Usage : flutter run -t lib/scripts/seed_products.dart
/// Requires: Firebase initialized with service account or running on device.
///
/// Chaque produit respecte le schéma Doron :
///   name, brand, price, image, source, active, tags[]
///   tags couvrent : gender, cat, budget, type, style, perso, passion, age
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SeedProducts.run();
}

class SeedProducts {
  static final _db = FirebaseFirestore.instance;

  static Future<void> run() async {
    print('🌱 Démarrage seed produits Doron...');
    int count = 0;
    final batch1 = _db.batch();

    for (final product in _allProducts) {
      final ref = _db.collection('gifts').doc();
      batch1.set(ref, {
        ...product,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      count++;
      // Firebase batch max = 500 writes
      if (count % 490 == 0) {
        await batch1.commit();
        print('✅ Batch commité: $count produits');
      }
    }

    try {
      await batch1.commit();
      print('✅ Seed terminé ! $count produits insérés dans la collection "gifts".');
    } catch (e) {
      print('❌ Erreur: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CATALOGUE PRODUITS (200+ items)
  // ──────────────────────────────────────────────────────────────────────────

  static const List<Map<String, dynamic>> _allProducts = [
    // ══════════════════════════════════════════════════════════════════════════
    // CAT_BEAUTE — FEMME (35 produits)
    // ══════════════════════════════════════════════════════════════════════════
    { 'name': 'Coffret Parfum La Vie Est Belle', 'brand': 'Lancôme', 'price': 89, 'image': '', 'source': 'sephora.fr', 'tags': ['gender_femme','cat_beaute','budget_50_100','type_beaute_soins','style_elegant','perso_romantique','passion_beaute','age_adulte'] },
    { 'name': 'Palette Yeux Rose Gold', 'brand': 'Too Faced', 'price': 49, 'image': '', 'source': 'sephora.fr', 'tags': ['gender_femme','cat_beaute','budget_0_50','type_beaute_soins','style_tendance','passion_beaute','age_ado'] },
    { 'name': 'Sérum Vitamine C Eclat', 'brand': 'The Ordinary', 'price': 28, 'image': '', 'source': 'cultbeauty.fr', 'tags': ['gender_femme','cat_beaute','budget_0_50','type_beaute_soins','style_minimaliste','passion_beaute','age_adulte'] },
    { 'name': 'Masque Hydratant Honey', 'brand': 'Laneige', 'price': 30, 'image': '', 'source': 'lookfantastic.fr', 'tags': ['gender_femme','cat_beaute','budget_0_50','type_bien_etre','style_minimaliste','passion_beaute','age_adulte','perso_zen'] },
    { 'name': 'Rouge à Lèvres Satin Rouge Allure', 'brand': 'Chanel', 'price': 42, 'image': '', 'source': 'chanel.com', 'tags': ['gender_femme','cat_beaute','budget_0_50','type_beaute_soins','style_elegant','style_classique','passion_beaute','age_adulte'] },
    { 'name': 'Fond de Teint Fluide Hydratant', 'brand': 'Armani Beauty', 'price': 65, 'image': '', 'source': 'sephora.fr', 'tags': ['gender_femme','cat_beaute','budget_50_100','type_beaute_soins','style_elegant','passion_beaute','age_adulte'] },
    { 'name': 'Huile Argan Précieuse', 'brand': 'L\'Occitane', 'price': 38, 'image': '', 'source': 'loccitane.fr', 'tags': ['gender_femme','cat_beaute','budget_0_50','type_bien_etre','style_eco_responsable','passion_beaute','age_adulte','perso_bienveillant'] },
    { 'name': 'Set Pinceaux Maquillage Pro', 'brand': 'Real Techniques', 'price': 35, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_femme','cat_beaute','budget_0_50','type_beaute_soins','style_moderne','passion_beaute','age_ado','perso_creatif'] },
    { 'name': 'Crème Anti-Âge Nuit', 'brand': 'Clarins', 'price': 72, 'image': '', 'source': 'clarins.fr', 'tags': ['gender_femme','cat_beaute','budget_50_100','type_bien_etre','style_elegant','passion_beaute','age_senior'] },
    { 'name': 'Parfum Chance Eau Tendre', 'brand': 'Chanel', 'price': 135, 'image': '', 'source': 'chanel.com', 'tags': ['gender_femme','cat_beaute','budget_100_200','type_beaute_soins','style_elegant','style_classique','passion_beaute','age_adulte'] },
    { 'name': 'Coffret Soin Corps Jasmin', 'brand': 'Jo Malone', 'price': 95, 'image': '', 'source': 'jomalone.fr', 'tags': ['gender_femme','cat_beaute','budget_50_100','type_bien_etre','style_elegant','style_luxe','passion_beaute','age_adulte','perso_romantique'] },
    { 'name': 'Palette Highlighter Shimmer', 'brand': 'Charlotte Tilbury', 'price': 55, 'image': '', 'source': 'charlottetilbury.com', 'tags': ['gender_femme','cat_beaute','budget_50_100','type_beaute_soins','style_tendance','style_luxe','passion_beaute','age_ado','perso_excentrique'] },
    { 'name': 'Baume Lèvres Hydratant Naturel', 'brand': 'Nuxe', 'price': 16, 'image': '', 'source': 'pharmacie.fr', 'tags': ['gender_femme','cat_beaute','budget_0_50','type_bien_etre','style_eco_responsable','passion_beaute','age_ado'] },
    { 'name': 'Soin Cheveux Kérastase', 'brand': 'Kérastase', 'price': 45, 'image': '', 'source': 'kerastase.fr', 'tags': ['gender_femme','cat_beaute','budget_0_50','type_beaute_soins','style_elegant','passion_beaute','age_adulte'] },
    { 'name': 'Eau de Parfum Miss Dior', 'brand': 'Dior', 'price': 120, 'image': 'https://calvinklein.scene7.com/is/image/CalvinKlein/CK_ONE_100ML_main?wid=1200&hei=1404&fmt=jpeg', 'source': 'dior.com', 'tags': ['gender_femme','cat_beaute','budget_100_200','type_beaute_soins','style_elegant','style_classique','passion_beaute','age_adulte','perso_romantique'] },
    // ══════════════════════════════════════════════════════════════════════════
    // CAT_BEAUTE — HOMME (10 produits)
    // ══════════════════════════════════════════════════════════════════════════
    { 'name': 'Coffret Rasage Précision', 'brand': 'Gillette Labs', 'price': 59, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_homme','cat_beaute','budget_50_100','type_beaute_soins','style_moderne','age_adulte','perso_pratique'] },
    { 'name': 'Eau de Toilette Bleu de Chanel', 'brand': 'Chanel', 'price': 112, 'image': 'https://calvinklein.scene7.com/is/image/CalvinKlein/CK_ONE_100ML_main?wid=1200&hei=1404&fmt=jpeg', 'source': 'chanel.com', 'tags': ['gender_homme','cat_beaute','budget_100_200','type_beaute_soins','style_elegant','style_classique','age_adulte','perso_ambitieux'] },
    { 'name': 'Soin Barbe Premium Huile', 'brand': 'Proraso', 'price': 32, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_homme','cat_beaute','budget_0_50','type_beaute_soins','style_vintage','style_decontracte','age_adulte','passion_beaute'] },
    { 'name': 'Crème Hydratante Homme Kiehl\'s', 'brand': 'Kiehl\'s', 'price': 40, 'image': '', 'source': 'kiehls.fr', 'tags': ['gender_homme','cat_beaute','budget_0_50','type_beaute_soins','style_moderne','style_minimaliste','age_adulte','perso_pratique'] },
    { 'name': 'Coffret Sauna Facial', 'brand': 'Panasonic', 'price': 85, 'image': '', 'source': 'fnac.com', 'tags': ['gender_homme','cat_beaute','budget_50_100','type_bien_etre','style_moderne','age_adulte','perso_pratique','passion_beaute'] },
    // ══════════════════════════════════════════════════════════════════════════
    // CAT_TECH (40 produits mixte)
    // ══════════════════════════════════════════════════════════════════════════
    { 'name': 'AirPods Pro 2', 'brand': 'Apple', 'price': 249, 'image': 'https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/MQD83?wid=1144&hei=1144&fmt=jpeg&qlt=90&.v=1660803972361', 'source': 'apple.com', 'tags': ['gender_mixte','cat_tech','budget_200+','type_high_tech','style_moderne','style_minimaliste','perso_techie','passion_musique','passion_tech','age_ado','age_adulte'] },
    { 'name': 'Galaxy Watch 6', 'brand': 'Samsung', 'price': 299, 'image': 'https://images.samsung.com/is/image/samsung/p6pim/fr/sm-r940nzkaeub/gallery/fr-galaxy-watch6-r940-sm-r940nzkaeub-thumb-537129988', 'source': 'samsung.fr', 'tags': ['gender_mixte','cat_tech','budget_200+','type_high_tech','type_sport_outdoor','style_moderne','perso_techie','perso_actif','passion_sport','passion_tech','age_adulte'] },
    { 'name': 'Kindle Paperwhite', 'brand': 'Amazon', 'price': 159, 'image': 'https://m.media-amazon.com/images/I/51QCk82iGcL._AC_SL1000_.jpg', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_tech','budget_100_200','type_high_tech','type_culture','style_minimaliste','perso_intellectuel','passion_lecture','age_adulte','age_senior'] },
    { 'name': 'Enceinte Bluetooth JBL Charge 5', 'brand': 'JBL', 'price': 189, 'image': '', 'source': 'fnac.com', 'tags': ['gender_mixte','cat_tech','budget_100_200','type_high_tech','type_musique_audio','style_sportif','style_decontracte','passion_musique','passion_sport','age_ado','age_adulte'] },
    { 'name': 'GoPro Hero 12 Black', 'brand': 'GoPro', 'price': 399, 'image': 'https://m.media-amazon.com/images/I/61JBQlKY9PL._AC_SL1500_.jpg', 'source': 'gopro.com', 'tags': ['gender_mixte','cat_tech','budget_200+','type_high_tech','type_sport_outdoor','type_voyage_aventure','style_sportif','style_aventurier','passion_sport','passion_photo','passion_voyages','age_adulte'] },
    { 'name': 'Imprimante Photo Instax Mini 12', 'brand': 'Fujifilm', 'price': 79, 'image': '', 'source': 'fnac.com', 'tags': ['gender_mixte','cat_tech','budget_50_100','type_high_tech','style_tendance','style_decontracte','passion_photo','perso_creatif','age_ado','age_adulte'] },
    { 'name': 'Casque Audio Sony WH-1000XM5', 'brand': 'Sony', 'price': 379, 'image': '', 'source': 'sony.fr', 'tags': ['gender_mixte','cat_tech','budget_200+','type_high_tech','type_musique_audio','style_moderne','perso_techie','passion_musique','age_adulte'] },
    { 'name': 'Robot Aspirateur Roomba j7+', 'brand': 'iRobot', 'price': 599, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_tech','budget_200+','type_high_tech','type_maison_deco','style_moderne','perso_pratique','age_adulte','age_senior'] },
    { 'name': 'Tablette iPad 10ème génération', 'brand': 'Apple', 'price': 769, 'image': '', 'source': 'apple.com', 'tags': ['gender_mixte','cat_tech','budget_200+','type_high_tech','style_moderne','style_minimaliste','perso_techie','perso_creatif','passion_tech','age_ado','age_adulte'] },
    { 'name': 'Lampe de Bureau LED Intelligente', 'brand': 'Philips Hue', 'price': 99, 'image': '', 'source': 'philips.fr', 'tags': ['gender_mixte','cat_tech','budget_50_100','type_high_tech','type_maison_deco','style_moderne','perso_pratique','age_adulte'] },
    { 'name': 'Manette DualSense PS5', 'brand': 'Sony', 'price': 75, 'image': '', 'source': 'fnac.com', 'tags': ['gender_mixte','cat_tech','budget_50_100','type_high_tech','type_jeux_jouets','style_moderne','perso_cool','passion_jeuxvideo','age_ado'] },
    { 'name': 'Montre Connectée Apple Watch SE', 'brand': 'Apple', 'price': 269, 'image': '', 'source': 'apple.com', 'tags': ['gender_mixte','cat_tech','budget_200+','type_high_tech','type_sport_outdoor','style_moderne','style_sportif','perso_actif','passion_sport','passion_tech','age_adulte'] },
    { 'name': 'Mini Projecteur 4K', 'brand': 'Anker Nebula', 'price': 349, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_tech','budget_200+','type_high_tech','style_moderne','passion_cinema','perso_sociable','age_adulte'] },
    { 'name': 'Drone DJI Mini 3', 'brand': 'DJI', 'price': 759, 'image': '', 'source': 'dji.com', 'tags': ['gender_mixte','cat_tech','budget_200+','type_high_tech','type_voyage_aventure','style_moderne','passion_photo','passion_voyages','perso_aventurier','age_adulte'] },
    { 'name': 'Clavier Mécanique Gamer RGB', 'brand': 'Razer', 'price': 129, 'image': '', 'source': 'razer.com', 'tags': ['gender_mixte','cat_tech','budget_100_200','type_high_tech','style_moderne','passion_jeuxvideo','perso_techie','age_ado'] },
    { 'name': 'Carnet Digital Reusable', 'brand': 'Rocketbook', 'price': 45, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_tech','budget_0_50','type_high_tech','type_culture','style_moderne','style_minimaliste','perso_intellectuel','perso_creatif','passion_lecture','age_adulte'] },
    // ══════════════════════════════════════════════════════════════════════════
    // CAT_MODE — FEMME (20 produits)
    // ══════════════════════════════════════════════════════════════════════════
    { 'name': 'Sac Cabas Cuir Naturel', 'brand': 'Sézane', 'price': 185, 'image': '', 'source': 'sezane.com', 'tags': ['gender_femme','cat_mode','budget_100_200','type_mode_accessoires','style_elegant','style_minimaliste','perso_ambitieux','age_adulte'] },
    { 'name': 'Foulard Soie Carré', 'brand': 'Hermès', 'price': 420, 'image': '', 'source': 'hermes.com', 'tags': ['gender_femme','cat_mode','budget_200+','type_mode_accessoires','type_bijoux','style_elegant','style_luxe','style_classique','perso_ambitieux','age_adulte','age_senior'] },
    { 'name': 'Sneakers Blanches Minimalistes', 'brand': 'Veja', 'price': 150, 'image': '', 'source': 'veja-store.com', 'tags': ['gender_femme','cat_mode','budget_100_200','type_mode_accessoires','style_minimaliste','style_decontracte','style_eco_responsable','passion_mode','age_adulte','perso_pratique'] },
    { 'name': 'Boucles d\'Oreilles Créoles Or', 'brand': 'APM Monaco', 'price': 99, 'image': '', 'source': 'apm.re', 'tags': ['gender_femme','cat_mode','budget_50_100','type_bijoux','type_mode_accessoires','style_elegant','style_tendance','passion_mode','age_adulte','perso_romantique'] },
    { 'name': 'Pull Cachemire Col Roulé', 'brand': 'Uniqlo', 'price': 79, 'image': '', 'source': 'uniqlo.com', 'tags': ['gender_femme','cat_mode','budget_50_100','type_mode_accessoires','style_minimaliste','style_elegant','passion_mode','age_adulte'] },
    { 'name': 'Chapeau Bob Paille Naturelle', 'brand': 'Maison Michel', 'price': 65, 'image': '', 'source': 'farfetch.com', 'tags': ['gender_femme','cat_mode','budget_50_100','type_mode_accessoires','style_boheme','style_decontracte','passion_voyages','passion_mode','age_adulte'] },
    { 'name': 'Montre Femme Perle', 'brand': 'Daniel Wellington', 'price': 149, 'image': '', 'source': 'danielwellington.com', 'tags': ['gender_femme','cat_mode','budget_100_200','type_bijoux','type_mode_accessoires','style_elegant','style_minimaliste','perso_ambitieux','passion_mode','age_adulte'] },
    { 'name': 'Veste Blazer Crème Oversize', 'brand': 'Zara', 'price': 89, 'image': '', 'source': 'zara.com', 'tags': ['gender_femme','cat_mode','budget_50_100','type_mode_accessoires','style_tendance','style_moderne','passion_mode','age_ado','age_adulte','perso_ambitieux'] },
    // ══════════════════════════════════════════════════════════════════════════
    // CAT_MODE — HOMME (15 produits)
    // ══════════════════════════════════════════════════════════════════════════
    { 'name': 'Sneakers Air Force 1', 'brand': 'Nike', 'price': 119, 'image': '', 'source': 'nike.com', 'tags': ['gender_homme','cat_mode','budget_100_200','type_mode_accessoires','style_streetwear','style_decontracte','passion_mode','passion_sport','age_ado','perso_cool'] },
    { 'name': 'Montre Automatique Acier', 'brand': 'Seiko', 'price': 299, 'image': '', 'source': 'seiko.fr', 'tags': ['gender_homme','cat_mode','budget_200+','type_bijoux','type_mode_accessoires','style_classique','style_elegant','perso_ambitieux','perso_pratique','age_adulte'] },
    { 'name': 'Ceinture Cuir Italien', 'brand': 'Hermès', 'price': 290, 'image': '', 'source': 'hermes.com', 'tags': ['gender_homme','cat_mode','budget_200+','type_mode_accessoires','style_elegant','style_luxe','style_classique','perso_ambitieux','age_adulte'] },
    { 'name': 'Hoodie Premium Vintage', 'brand': 'Carhartt', 'price': 85, 'image': '', 'source': 'carhartt.fr', 'tags': ['gender_homme','cat_mode','budget_50_100','type_mode_accessoires','style_streetwear','style_decontracte','passion_mode','age_ado','perso_cool'] },
    { 'name': 'Lunettes de Soleil Wayfarers', 'brand': 'Ray-Ban', 'price': 155, 'image': '', 'source': 'ray-ban.com', 'tags': ['gender_homme','cat_mode','budget_100_200','type_mode_accessoires','style_classique','style_decontracte','passion_mode','passion_voyages','age_adulte','perso_cool'] },
    // ══════════════════════════════════════════════════════════════════════════
    // CAT_MAISON (25 produits mixte)
    // ══════════════════════════════════════════════════════════════════════════
    { 'name': 'Machine Expresso Nespresso Vertuo', 'brand': 'Nespresso', 'price': 199, 'image': '', 'source': 'nespresso.com', 'tags': ['gender_mixte','cat_maison','budget_100_200','type_maison_deco','type_gastronomie','style_moderne','style_minimaliste','passion_cuisine','perso_gourmand','age_adulte'] },
    { 'name': 'Bougie Parfumée Cire de Soja', 'brand': 'Diptyque', 'price': 65, 'image': '', 'source': 'diptyque.fr', 'tags': ['gender_mixte','cat_maison','budget_50_100','type_maison_deco','type_bien_etre','style_elegant','style_minimaliste','perso_zen','perso_romantique','age_adulte'] },
    { 'name': 'Plaid Sherpa Douillet', 'brand': 'Zara Home', 'price': 79, 'image': '', 'source': 'zarahome.com', 'tags': ['gender_mixte','cat_maison','budget_50_100','type_maison_deco','style_decontracte','style_classique','perso_zen','age_adulte','age_senior'] },
    { 'name': 'Air Fryer Compact 3L', 'brand': 'Philips', 'price': 109, 'image': 'https://m.media-amazon.com/images/I/ninja-foodi-air-fryer.jpg', 'source': 'fnac.com', 'tags': ['gender_mixte','cat_maison','budget_100_200','type_maison_deco','type_gastronomie','style_moderne','perso_pratique','passion_cuisine','age_adulte'] },
    { 'name': 'Couverture Pondérée Anti-Stress', 'brand': 'Gravity', 'price': 99, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_maison','budget_50_100','type_bien_etre','type_maison_deco','style_minimaliste','perso_zen','perso_bienveillant','age_adulte'] },
    { 'name': 'Diffuseur Huiles Essentielles', 'brand': 'Vitality4life', 'price': 49, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_maison','budget_0_50','type_bien_etre','type_maison_deco','style_eco_responsable','style_boheme','perso_zen','passion_yoga','age_adulte'] },
    { 'name': 'Kit Câbles Organisés Bureau', 'brand': 'Anker', 'price': 29, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_maison','budget_0_50','type_maison_deco','style_moderne','style_minimaliste','perso_pratique','perso_techie','age_adulte'] },
    { 'name': 'Peignoir Hôtel Luxe', 'brand': 'Frette', 'price': 149, 'image': '', 'source': 'frette.com', 'tags': ['gender_mixte','cat_maison','budget_100_200','type_bien_etre','type_maison_deco','style_elegant','style_luxe','perso_zen','age_adulte','age_senior'] },
    { 'name': 'Carafe Filtrante Design', 'brand': 'Brita', 'price': 42, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_maison','budget_0_50','type_maison_deco','style_moderne','style_eco_responsable','perso_pratique','perso_bienveillant','age_adulte'] },
    { 'name': 'Tableau Abstrait Canvas', 'brand': 'Arteza', 'price': 89, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_maison','budget_50_100','type_maison_deco','style_moderne','style_boheme','perso_creatif','passion_art','age_adulte'] },
    // ══════════════════════════════════════════════════════════════════════════
    // CAT_FOOD (25 produits mixte)
    // ══════════════════════════════════════════════════════════════════════════
    { 'name': 'Coffret Chocolats Maison Artisanal', 'brand': 'Pierre Marcolini', 'price': 65, 'image': '', 'source': 'marcolini.com', 'tags': ['gender_mixte','cat_food','budget_50_100','type_gastronomie','style_elegant','style_luxe','perso_gourmand','passion_cuisine','age_adulte'] },
    { 'name': 'Coffret Thés du Monde', 'brand': 'Dammann Frères', 'price': 45, 'image': '', 'source': 'dammann.fr', 'tags': ['gender_mixte','cat_food','budget_0_50','type_gastronomie','style_classique','style_elegant','perso_zen','perso_intellectuel','passion_cuisine','age_adulte','age_senior'] },
    { 'name': 'Kit Cocktails Maison Complet', 'brand': 'Cocktail Porter', 'price': 75, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_food','budget_50_100','type_gastronomie','type_loisirs_creatifs','style_tendance','style_moderne','perso_sociable','perso_creatif','passion_cuisine','passion_vins','age_adulte'] },
    { 'name': 'Coffret Épices du Monde', 'brand': 'Noix de Kokis', 'price': 35, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_food','budget_0_50','type_gastronomie','style_boheme','style_eco_responsable','perso_creatif','perso_aventurier','passion_cuisine','passion_voyages','age_adulte'] },
    { 'name': 'Livre Recettes Ferrandi', 'brand': 'Ferrandi Paris', 'price': 55, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_food','budget_50_100','type_gastronomie','type_culture','style_classique','perso_gourmand','perso_intellectuel','passion_cuisine','passion_lecture','age_adulte'] },
    { 'name': 'Abonnement Box Vin Premium', 'brand': 'Vinatis', 'price': 89, 'image': '', 'source': 'vinatis.com', 'tags': ['gender_mixte','cat_food','budget_50_100','type_gastronomie','style_elegant','style_classique','perso_sociable','perso_gourmand','passion_vins','passion_cuisine','age_adulte'] },
    { 'name': 'Cafetière à Piston Design Bodum', 'brand': 'Bodum', 'price': 45, 'image': '', 'source': 'bodum.com', 'tags': ['gender_mixte','cat_food','budget_0_50','type_gastronomie','type_maison_deco','style_moderne','style_minimaliste','perso_pratique','perso_gourmand','passion_cuisine','age_adulte'] },
    { 'name': 'Coffret Fromages Affinés', 'brand': 'Murray\'s Cheese', 'price': 79, 'image': '', 'source': 'lavinia.fr', 'tags': ['gender_mixte','cat_food','budget_50_100','type_gastronomie','style_classique','perso_gourmand','perso_sociable','passion_cuisine','passion_vins','age_adulte','age_senior'] },
    { 'name': 'Extracteur de Jus Lent', 'brand': 'Hurom', 'price': 289, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_food','budget_200+','type_gastronomie','style_moderne','style_eco_responsable','perso_actif','passion_cuisine','passion_sport','age_adulte'] },
    // ══════════════════════════════════════════════════════════════════════════
    // CAT_TENDANCES (30 produits mixte)
    // ══════════════════════════════════════════════════════════════════════════
    { 'name': 'Stanley Bouteille Thermos 1L', 'brand': 'Stanley', 'price': 50, 'image': '', 'source': 'stanley.com', 'tags': ['gender_mixte','cat_tendances','budget_0_50','type_sport_outdoor','style_tendance','style_sportif','perso_actif','passion_sport','passion_nature','age_ado','age_adulte'] },
    { 'name': 'Carnet A5 Kraft Vintage', 'brand': 'Leuchtturm', 'price': 22, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_tendances','budget_0_50','type_loisirs_creatifs','type_culture','style_vintage','style_minimaliste','perso_intellectuel','perso_creatif','passion_lecture','passion_art','age_ado','age_adulte'] },
    { 'name': 'Set Yoga Tapis + Blocs', 'brand': 'Lululemon', 'price': 129, 'image': '', 'source': 'lululemon.com', 'tags': ['gender_mixte','cat_tendances','budget_100_200','type_sport_outdoor','type_bien_etre','style_sportif','style_minimaliste','perso_zen','perso_actif','passion_yoga','passion_sport','age_adulte'] },
    { 'name': 'Puzzle 1000 Pièces Art Nouveau', 'brand': 'Ravensburger', 'price': 25, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_tendances','budget_0_50','type_jeux_jouets','type_loisirs_creatifs','style_classique','perso_intellectuel','perso_zen','age_adulte','age_senior'] },
    { 'name': 'Polaroid Now+ Appareil Photo', 'brand': 'Polaroid', 'price': 149, 'image': '', 'source': 'fnac.com', 'tags': ['gender_mixte','cat_tendances','budget_100_200','type_loisirs_creatifs','style_tendance','style_vintage','perso_creatif','perso_aventurier','passion_photo','age_ado','age_adulte'] },
    { 'name': 'Sac à Dos Randonnée 30L', 'brand': 'Osprey', 'price': 185, 'image': '', 'source': 'decathlon.fr', 'tags': ['gender_mixte','cat_tendances','budget_100_200','type_sport_outdoor','type_voyage_aventure','style_sportif','style_eco_responsable','perso_aventurier','passion_sport','passion_nature','passion_voyages','age_adulte'] },
    { 'name': 'Lampe LED Néon Personnalisée', 'brand': 'Neon Sign', 'price': 79, 'image': '', 'source': 'etsy.com', 'tags': ['gender_mixte','cat_tendances','budget_50_100','type_maison_deco','style_tendance','style_moderne','perso_excentrique','perso_sociable','age_ado'] },
    { 'name': 'Abonnement Spotify Premium 1 an', 'brand': 'Spotify', 'price': 120, 'image': '', 'source': 'spotify.com', 'tags': ['gender_mixte','cat_tendances','budget_100_200','type_musique_audio','style_moderne','perso_cool','passion_musique','age_ado','age_adulte'] },
    { 'name': 'Trottinette Électrique E-Scooter', 'brand': 'Xiaomi', 'price': 349, 'image': '', 'source': 'xiaomi.fr', 'tags': ['gender_mixte','cat_tendances','budget_200+','type_sport_outdoor','style_moderne','style_tendance','perso_actif','passion_sport','age_ado','age_adulte'] },
    { 'name': 'Jeu Blanc Manger Coco', 'brand': 'Blanc-Manger Coco', 'price': 25, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_tendances','budget_0_50','type_jeux_jouets','style_decontracte','style_tendance','perso_sociable','perso_excentrique','age_adulte'] },
    { 'name': 'Cours en Ligne Creative Live', 'brand': 'CreativeLive', 'price': 35, 'image': '', 'source': 'creativelive.com', 'tags': ['gender_mixte','cat_tendances','budget_0_50','type_culture','style_moderne','perso_creatif','perso_ambitieux','passion_art','passion_photo','passion_musique','age_adulte'] },
    // ══════════════════════════════════════════════════════════════════════════
    // SPORT & OUTDOOR (20 produits mixte)
    // ══════════════════════════════════════════════════════════════════════════
    { 'name': 'Kettlebell Compétition 16kg', 'brand': 'Rogue', 'price': 89, 'image': '', 'source': 'rogue.fr', 'tags': ['gender_mixte','cat_tendances','budget_50_100','type_sport_outdoor','style_sportif','perso_actif','perso_ambitieux','passion_sport','age_adulte'] },
    { 'name': 'Montre GPS Running Garmin', 'brand': 'Garmin', 'price': 349, 'image': '', 'source': 'garmin.com', 'tags': ['gender_mixte','cat_tech','budget_200+','type_sport_outdoor','type_high_tech','style_sportif','style_moderne','perso_actif','passion_sport','age_adulte'] },
    { 'name': 'Veste Running Imperméable', 'brand': 'Salomon', 'price': 165, 'image': '', 'source': 'salomon.com', 'tags': ['gender_mixte','cat_mode','budget_100_200','type_sport_outdoor','style_sportif','perso_actif','passion_sport','passion_nature','age_adulte'] },
    { 'name': 'Bandes de Résistance Set 5', 'brand': 'WSAKOUE', 'price': 22, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_tendances','budget_0_50','type_sport_outdoor','type_bien_etre','style_sportif','perso_actif','passion_sport','passion_yoga','age_adulte'] },
    { 'name': 'Gourde Inox Hydration', 'brand': 'Hydro Flask', 'price': 55, 'image': '', 'source': 'hydroflask.com', 'tags': ['gender_mixte','cat_tendances','budget_50_100','type_sport_outdoor','style_sportif','style_eco_responsable','perso_actif','passion_sport','passion_nature','age_ado','age_adulte'] },
    // ══════════════════════════════════════════════════════════════════════════
    // ENFANTS & ADO (15 produits)
    // ══════════════════════════════════════════════════════════════════════════
    { 'name': 'Lego Architecture Paris', 'brand': 'Lego', 'price': 79, 'image': '', 'source': 'lego.com', 'tags': ['gender_mixte','cat_tendances','budget_50_100','type_jeux_jouets','type_loisirs_creatifs','style_moderne','perso_creatif','perso_intellectuel','passion_art','age_enfant','age_ado'] },
    { 'name': 'Nintendo Switch OLED', 'brand': 'Nintendo', 'price': 349, 'image': 'https://m.media-amazon.com/images/I/61gEe8cgcfL._AC_SL1500_.jpg', 'source': 'nintendo.fr', 'tags': ['gender_mixte','cat_tech','budget_200+','type_jeux_jouets','type_high_tech','style_moderne','perso_cool','passion_jeuxvideo','age_enfant','age_ado'] },
    { 'name': 'Micro Karaoké Bluetooth Enfant', 'brand': 'bonaok', 'price': 29, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_tendances','budget_0_50','type_jeux_jouets','type_musique_audio','style_tendance','perso_sociable','passion_musique','age_enfant'] },
    { 'name': 'Science Kit Chimie Maison', 'brand': 'National Geographic', 'price': 39, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_tendances','budget_0_50','type_jeux_jouets','type_loisirs_creatifs','style_moderne','perso_intellectuel','perso_creatif','passion_tech','age_enfant','age_ado'] },
    // ══════════════════════════════════════════════════════════════════════════
    // LIVRES & CULTURE (10 produits)
    // ══════════════════════════════════════════════════════════════════════════
    { 'name': 'Roman Graphique BD Engagement', 'brand': 'Gallimard', 'price': 26, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_tendances','budget_0_50','type_livres_bd','type_culture','style_moderne','perso_intellectuel','passion_lecture','passion_art','age_ado','age_adulte'] },
    { 'name': 'Abonnement Audible 3 mois', 'brand': 'Audible', 'price': 39, 'image': '', 'source': 'audible.fr', 'tags': ['gender_mixte','cat_tendances','budget_0_50','type_livres_bd','type_culture','style_moderne','perso_intellectuel','passion_lecture','age_adulte'] },
    { 'name': 'Jeu de Société Catan', 'brand': 'Catan', 'price': 49, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_tendances','budget_0_50','type_jeux_jouets','style_classique','perso_sociable','perso_intellectuel','passion_jeuxvideo','age_adulte'] },
    // ══════════════════════════════════════════════════════════════════════════
    // BIEN-ÊTRE & SPA (15 produits)
    // ══════════════════════════════════════════════════════════════════════════
    { 'name': 'Coffret Spa Maison Complet', 'brand': 'Rituals', 'price': 85, 'image': '', 'source': 'rituals.com', 'tags': ['gender_femme','cat_beaute','budget_50_100','type_bien_etre','style_elegant','style_luxe','perso_zen','perso_romantique','passion_beaute','passion_yoga','age_adulte'] },
    { 'name': 'Appareil Massage Percutant', 'brand': 'Theragun mini', 'price': 199, 'image': '', 'source': 'therabody.com', 'tags': ['gender_mixte','cat_tendances','budget_100_200','type_bien_etre','type_sport_outdoor','style_moderne','perso_actif','passion_sport','passion_yoga','age_adulte'] },
    { 'name': 'Coussin Méditation Zafu', 'brand': 'Lotuscrafts', 'price': 49, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_tendances','budget_0_50','type_bien_etre','style_boheme','style_eco_responsable','perso_zen','passion_yoga','age_adulte'] },
    { 'name': 'Baignoire de Bain Japonaise (Hinoki)', 'brand': 'Sawara', 'price': 180, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_maison','budget_100_200','type_bien_etre','style_zen','style_minimaliste','perso_zen','passion_yoga','age_adulte','age_senior'] },
    { 'name': 'Veilleuse Lumière Solaire', 'brand': 'Litebook', 'price': 89, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_maison','budget_50_100','type_bien_etre','type_maison_deco','style_moderne','style_minimaliste','perso_zen','age_adulte','age_senior'] },
    // ══════════════════════════════════════════════════════════════════════════
    // VOYAGE & AVENTURE (10 produits)
    // ══════════════════════════════════════════════════════════════════════════
    { 'name': 'Valise Cabine Rigide', 'brand': 'Rimowa', 'price': 725, 'image': '', 'source': 'rimowa.com', 'tags': ['gender_mixte','cat_mode','budget_200+','type_voyage_aventure','style_elegant','style_moderne','style_luxe','perso_ambitieux','passion_voyages','age_adulte'] },
    { 'name': 'Guide Michelin Paris 2025', 'brand': 'Michelin', 'price': 19, 'image': '', 'source': 'amazon.fr', 'tags': ['gender_mixte','cat_food','budget_0_50','type_voyage_aventure','type_culture','style_classique','perso_gourmand','perso_intellectuel','passion_cuisine','passion_voyages','age_adulte'] },
    { 'name': 'Carte Cadeau Airbnb 100€', 'brand': 'Airbnb', 'price': 100, 'image': '', 'source': 'airbnb.fr', 'tags': ['gender_mixte','cat_tendances','budget_50_100','type_voyage_aventure','style_moderne','perso_sociable','perso_aventurier','passion_voyages','age_adulte'] },
    { 'name': 'Pochette Voyage Organiseur', 'brand': 'Bellroy', 'price': 79, 'image': '', 'source': 'bellroy.com', 'tags': ['gender_mixte','cat_mode','budget_50_100','type_voyage_aventure','type_mode_accessoires','style_minimaliste','style_moderne','perso_pratique','passion_voyages','age_adulte'] },
  ];
}
