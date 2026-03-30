// ignore_for_file: avoid_print
/// Seed v4 — 160 produits pour les 8 catégories manquantes
/// Ado fille, Homme 55+, Couple expériences, Animaux premium,
/// Green/Eco, Passion auto, DIY/Maker, Saison hiver
///
/// Usage: flutter run -t lib/scripts/seed_products_v4.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🌱 Seed v4 — 8 catégories manquantes...');
  final db = FirebaseFirestore.instance;
  var batch = db.batch();
  int count = 0;
  for (final p in _v4) {
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
  print('✅ $count produits v4 insérés.');
}

const _v4 = [
  // ══════════ ADO FILLE ══════════════════════════════════════════════════════
  {'name': 'Stanley Quencher Flowstate 1.18L Rose Flamingo', 'brand': 'Stanley', 'price': 55,
   'image': '', 'source': 'stanley.com',
   'tags': ['gender_femme','cat_tendances','budget_50_100','type_sport_outdoor','style_tendance','perso_cool','passion_sport','age_ado','occasion_anniversaire','occasion_noel','popularite_5','saison_ete']},
  {'name': 'Crocs Classic Clog Taffy Pink', 'brand': 'Crocs', 'price': 55,
   'image': '', 'source': 'crocs.eu',
   'tags': ['gender_femme','cat_mode','budget_50_100','type_mode_accessoires','style_tendance','style_decontracte','passion_mode','age_ado','occasion_anniversaire','popularite_5']},
  {'name': 'Polaroid Go Appareil Photo Instantané Rose', 'brand': 'Polaroid', 'price': 79,
   'image': '', 'source': 'polaroid.com',
   'tags': ['gender_femme','cat_tech','budget_50_100','type_high_tech','type_loisirs_creatifs','style_tendance','style_vintage','passion_photo','perso_creatif','age_ado','occasion_anniversaire','occasion_noel','popularite_5']},
  {'name': 'UGG Classic Mini Platform Chestnut', 'brand': 'UGG', 'price': 175,
   'image': '', 'source': 'ugg.com',
   'tags': ['gender_femme','cat_mode','budget_100_200','type_mode_accessoires','style_tendance','style_decontracte','passion_mode','age_ado','occasion_noel','popularite_5','saison_hiver']},
  {'name': 'Palette Fenty Beauty Snap Shadows Mix & Match', 'brand': 'Fenty Beauty', 'price': 38,
   'image': '', 'source': 'fentybeauty.com',
   'tags': ['gender_femme','cat_beaute','budget_0_50','type_beaute_soins','style_tendance','passion_beaute','perso_creatif','age_ado','occasion_anniversaire','popularite_5']},
  {'name': 'Sweat Crop Top Stüssy Femme Blanc', 'brand': 'Stüssy', 'price': 89,
   'image': '', 'source': 'stussy.com',
   'tags': ['gender_femme','cat_mode','budget_50_100','type_mode_accessoires','style_streetwear','style_tendance','passion_mode','perso_cool','age_ado','occasion_anniversaire']},
  {'name': 'Tarte à la Fraise Kit Nail Art Gel', 'brand': 'Manucurist', 'price': 35,
   'image': '', 'source': 'manucurist.com',
   'tags': ['gender_femme','cat_beaute','budget_0_50','type_beaute_soins','style_tendance','passion_beaute','perso_creatif','age_ado','popularite_4']},
  {'name': 'AirPods 4 en 2 Blanc', 'brand': 'Apple', 'price': 179,
   'image': '', 'source': 'apple.com',
   'tags': ['gender_femme','cat_tech','budget_100_200','type_high_tech','type_musique_audio','style_moderne','passion_musique','passion_tech','perso_cool','age_ado','occasion_anniversaire','occasion_noel','popularite_5']},
  {'name': 'Book Enemies to Lovers 5 romans Sarah J. Maas', 'brand': 'Bloomsbury', 'price': 45,
   'image': '', 'source': 'amazon.fr',
   'tags': ['gender_femme','cat_tendances','budget_0_50','type_livres_bd','style_tendance','passion_lecture','perso_romantique','age_ado','occasion_anniversaire']},
  {'name': 'Basket Nike Dunk Low Femme Triple White', 'brand': 'Nike', 'price': 115,
   'image': '', 'source': 'nike.com',
   'tags': ['gender_femme','cat_mode','budget_100_200','type_mode_accessoires','style_tendance','style_streetwear','passion_mode','passion_sport','age_ado','occasion_anniversaire','popularite_5']},

  // ══════════ HOMME 55+ / SENIOR ═════════════════════════════════════════════
  {'name': 'Stylo Plume Montblanc Meisterstück Platimum', 'brand': 'Montblanc', 'price': 430,
   'image': '', 'source': 'montblanc.com',
   'tags': ['gender_homme','cat_mode','budget_200+','type_mode_accessoires','style_elegant','style_luxe','perso_ambitieux','age_senior','occasion_anniversaire','occasion_remerciement','popularite_4']},
  {'name': 'Whisky Glenfiddich 18 ans Single Malt', 'brand': 'Glenfiddich', 'price': 85,
   'image': '', 'source': 'glenfiddich.com',
   'tags': ['gender_homme','cat_food','budget_50_100','type_gastronomie','style_classique','style_luxe','passion_vins','perso_gourmand','age_senior','age_adulte','occasion_anniversaire','occasion_noel','popularite_4']},
  {'name': 'Montre Longines HydroConquest 39mm Bleu', 'brand': 'Longines', 'price': 890,
   'image': '', 'source': 'longines.com',
   'tags': ['gender_homme','cat_mode','budget_200+','type_bijoux','style_elegant','style_classique','perso_ambitieux','age_senior','age_adulte','occasion_anniversaire','occasion_mariage','popularite_4']},
  {'name': 'Bottes Cuir S.T. Dupont Homme Classique', 'brand': 'S.T. Dupont', 'price': 320,
   'image': '', 'source': 'st-dupont.com',
   'tags': ['gender_homme','cat_mode','budget_200+','type_mode_accessoires','style_elegant','style_classique','perso_ambitieux','age_senior','occasion_anniversaire']},
  {'name': 'Cours de Bridge en Ligne - 6 mois', 'brand': 'BridgeBase', 'price': 59,
   'image': '', 'source': 'bridgebase.com',
   'tags': ['gender_mixte','cat_tendances','budget_50_100','type_jeux_jouets','type_culture','style_classique','perso_intellectuel','perso_sociable','age_senior','context_famille']},
  {'name': 'Fauteuil Massant Shiatsu Medisana MC 826', 'brand': 'Medisana', 'price': 349,
   'image': '', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_maison','budget_200+','type_bien_etre','style_moderne','perso_zen','perso_pratique','age_senior','context_famille','occasion_anniversaire','popularite_4']},
  {'name': 'Abonnement Presse Le Monde + L\'Obs 1 an', 'brand': 'Le Monde', 'price': 99,
   'image': '', 'source': 'lemonde.fr',
   'tags': ['gender_mixte','cat_tendances','budget_50_100','type_livres_bd','type_culture','style_classique','perso_intellectuel','passion_lecture','age_senior','context_famille']},
  {'name': 'Livre Encyclopédie Larousse Gastronomique 2024', 'brand': 'Larousse', 'price': 65,
   'image': '', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_food','budget_50_100','type_gastronomie','type_livres_bd','style_classique','passion_cuisine','perso_gourmand','age_senior','age_adulte','occasion_anniversaire','occasion_noel']},

  // ══════════ EXPÉRIENCES COUPLE ══════════════════════════════════════════════
  {'name': 'Cours de Cuisine Gordon Ramsay MasterClass', 'brand': 'MasterClass', 'price': 120,
   'image': '', 'source': 'masterclass.com',
   'tags': ['gender_mixte','cat_tendances','budget_100_200','type_gastronomie','type_culture','style_moderne','perso_creatif','perso_gourmand','passion_cuisine','age_adulte','context_amoureux','context_ami','occasion_anniversaire','occasion_saint_valentin']},
  {'name': 'Spa en Duo Cinq Mondes 2h Rituel', 'brand': 'Cinq Mondes', 'price': 280,
   'image': '', 'source': 'cinqmondes.com',
   'tags': ['gender_mixte','cat_tendances','budget_200+','type_bien_etre','style_luxe','style_elegant','perso_zen','perso_romantique','passion_beaute','passion_yoga','age_adulte','context_amoureux','occasion_saint_valentin','occasion_anniversaire','popularite_4']},
  {'name': 'Dégustation Vins Domaine Margnat Bordeaux', 'brand': 'Margnat', 'price': 85,
   'image': '', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_food','budget_50_100','type_gastronomie','type_culture','style_elegant','perso_sociable','passion_vins','passion_cuisine','age_adulte','context_amoureux','context_ami','occasion_anniversaire']},
  {'name': 'Escape Game Privé Paris 2 joueurs', 'brand': 'Time Breakers', 'price': 99,
   'image': '', 'source': 'timebreakers.fr',
   'tags': ['gender_mixte','cat_tendances','budget_50_100','type_jeux_jouets','type_voyage_aventure','style_tendance','perso_aventurier','perso_sociable','age_adulte','context_amoureux','context_ami','occasion_anniversaire','occasion_saint_valentin']},
  {'name': 'Concert Événement Billet Surprise Paris', 'brand': 'Surprise Concert', 'price': 120,
   'image': '', 'source': 'ticketmaster.fr',
   'tags': ['gender_mixte','cat_tendances','budget_100_200','type_musique_audio','type_culture','style_tendance','perso_sociable','passion_musique','passion_cinema','age_adulte','age_ado','context_amoureux','context_ami','occasion_anniversaire']},
  {'name': 'Nuit Romantique Hôtel Spa Seine Normandie', 'brand': 'Relais & Châteaux', 'price': 350,
   'image': '', 'source': 'relaischateaux.com',
   'tags': ['gender_mixte','cat_tendances','budget_200+','type_voyage_aventure','type_bien_etre','style_luxe','style_elegant','perso_romantique','passion_voyages','age_adulte','context_amoureux','occasion_anniversaire','occasion_saint_valentin','popularite_4']},
  {'name': 'Atelier Poterie Duo Paris 3h', 'brand': 'Le Marais Poterie', 'price': 95,
   'image': '', 'source': 'lesvoisinsdumarais.com',
   'tags': ['gender_mixte','cat_tendances','budget_50_100','type_loisirs_creatifs','style_boheme','style_tendance','perso_creatif','perso_sociable','passion_art','age_adulte','context_amoureux','context_ami','occasion_anniversaire','occasion_noel']},
  {'name': 'Vol en Montgolfière Duo Beaujolais', 'brand': 'Air Escargot', 'price': 380,
   'image': '', 'source': 'airescargot.com',
   'tags': ['gender_mixte','cat_tendances','budget_200+','type_voyage_aventure','style_boheme','perso_aventurier','perso_romantique','passion_voyages','passion_nature','age_adulte','context_amoureux','occasion_anniversaire','occasion_saint_valentin']},

  // ══════════ ANIMAUX PREMIUM ══════════════════════════════════════════════════
  {'name': 'GPS Tracker Tractive DOG 4 LTE Bleu', 'brand': 'Tractive', 'price': 49,
   'image': '', 'source': 'tractive.com',
   'tags': ['gender_mixte','cat_tech','budget_0_50','type_high_tech','style_moderne','passion_animaux','perso_bienveillant','age_adulte','popularite_5']},
  {'name': 'Nourriture Royal Canin Indoor Adult 1 an', 'brand': 'Royal Canin', 'price': 65,
   'image': '', 'source': 'royalcanin.com',
   'tags': ['gender_mixte','cat_food','budget_50_100','type_gastronomie','style_minimaliste','passion_animaux','perso_bienveillant','perso_pratique','age_adulte','popularite_4']},
  {'name': 'Collier Lumineux LED Waterproof Chien Night Dog', 'brand': 'PetSafe', 'price': 28,
   'image': '', 'source': 'petsafe.com',
   'tags': ['gender_mixte','cat_tendances','budget_0_50','type_sport_outdoor','style_moderne','passion_animaux','perso_actif','age_adulte']},
  {'name': 'Fontaine à Eau CATIT Flower Fountain 3L Filtrante', 'brand': 'Catit', 'price': 39,
   'image': '', 'source': 'catit.com',
   'tags': ['gender_mixte','cat_maison','budget_0_50','type_maison_deco','style_moderne','passion_animaux','perso_bienveillant','age_adulte','popularite_4']},
  {'name': 'Sac Transport Chien Ryanair Cabin Bag 40x20x25', 'brand': 'Petcarryon', 'price': 45,
   'image': '', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_mode','budget_0_50','type_voyage_aventure','type_mode_accessoires','style_moderne','passion_animaux','passion_voyages','perso_actif','age_adulte']},
  {'name': 'Arbre à Chat Trixie Parla 145cm Naturel', 'brand': 'Trixie', 'price': 99,
   'image': '', 'source': 'trixie.de',
   'tags': ['gender_mixte','cat_maison','budget_50_100','type_maison_deco','type_bien_etre','style_minimaliste','passion_animaux','perso_bienveillant','age_adulte']},
  {'name': 'Caméra Petcube Bites 2 Lite Anti-stress Chat/Chien', 'brand': 'Petcube', 'price': 89,
   'image': '', 'source': 'petcube.com',
   'tags': ['gender_mixte','cat_tech','budget_50_100','type_high_tech','style_moderne','passion_animaux','passion_tech','perso_bienveillant','age_adulte','popularite_4']},
  {'name': 'Sac à Dos Hiking Chien Rondas Trixie 34L', 'brand': 'Trixie', 'price': 45,
   'image': '', 'source': 'trixie.de',
   'tags': ['gender_mixte','cat_tendances','budget_0_50','type_sport_outdoor','style_sportif','passion_animaux','passion_nature','perso_actif','age_adulte']},

  // ══════════ GREEN / ECO ══════════════════════════════════════════════════════
  {'name': 'Kit Potager Balcon Jardin Factory 6 plantes aromatiques', 'brand': 'Jardin Factory', 'price': 42,
   'image': '', 'source': 'jardinfactory.fr',
   'tags': ['gender_mixte','cat_maison','budget_0_50','type_maison_deco','type_bien_etre','style_eco_responsable','style_boheme','perso_bienveillant','passion_jardinage','passion_cuisine','passion_nature','age_adulte','popularite_4']},
  {'name': 'Ruche Observatoire BeeBox Starter Pack', 'brand': 'BeeBox', 'price': 149,
   'image': '', 'source': 'beebox.fr',
   'tags': ['gender_mixte','cat_tendances','budget_100_200','type_loisirs_creatifs','type_maison_deco','style_eco_responsable','style_boheme','perso_bienveillant','perso_creatif','passion_jardinage','passion_nature','age_adulte']},
  {'name': 'Veste Patagonia Down Sweater Femme Coupe-vent', 'brand': 'Patagonia', 'price': 299,
   'image': '', 'source': 'patagonia.com',
   'tags': ['gender_femme','cat_mode','budget_200+','type_mode_accessoires','type_sport_outdoor','style_eco_responsable','style_sportif','perso_actif','perso_bienveillant','passion_sport','passion_nature','age_adulte','saison_hiver','saison_automne']},
  {'name': 'Sneakers Ecoalf Quartz Barcelona Blanc', 'brand': 'Ecoalf', 'price': 120,
   'image': '', 'source': 'ecoalf.com',
   'tags': ['gender_mixte','cat_mode','budget_100_200','type_mode_accessoires','style_eco_responsable','style_minimaliste','passion_mode','passion_nature','age_adulte','popularite_4']},
  {'name': 'Kit Kombucha Maison ChouKrout Bio Starter', 'brand': 'ChouKrout', 'price': 39,
   'image': '', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_food','budget_0_50','type_gastronomie','type_loisirs_creatifs','style_eco_responsable','perso_creatif','passion_cuisine','passion_nature','age_adulte']},
  {'name': 'Lampe Solaire LED Luci Core Camping & Randonnée', 'brand': 'MPOWERD', 'price': 22,
   'image': '', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_tendances','budget_0_50','type_sport_outdoor','type_voyage_aventure','style_eco_responsable','perso_actif','passion_sport','passion_nature','age_adulte','saison_ete']},
  {'name': 'Bougie Natural Cire Soja Bergamote Noir Cedar', 'brand': 'Maison Margiela Replica', 'price': 55,
   'image': '', 'source': 'maisonmargiela.com',
   'tags': ['gender_mixte','cat_maison','budget_50_100','type_maison_deco','type_bien_etre','style_elegant','style_eco_responsable','perso_zen','passion_nature','age_adulte','popularite_4']},
  {'name': 'Zero Waste Starter Kit Bambou 12 pièces', 'brand': 'Package Free Shop', 'price': 45,
   'image': '', 'source': 'packagefreeshop.com',
   'tags': ['gender_mixte','cat_tendances','budget_0_50','type_bien_etre','type_maison_deco','style_eco_responsable','style_minimaliste','perso_bienveillant','passion_nature','age_adulte','age_ado']},

  // ══════════ PASSION AUTO / MOTO ══════════════════════════════════════════════
  {'name': 'Expérience Circuit Ferrari 458 Italia 3 tours', 'brand': 'Prestige Auto Driving', 'price': 299,
   'image': '', 'source': 'prestigeautodriving.fr',
   'tags': ['gender_homme','cat_tendances','budget_200+','type_voyage_aventure','type_automobile','style_luxe','style_moderne','perso_aventurier','perso_ambitieux','passion_automobile','passion_sport','age_adulte','occasion_anniversaire','popularite_4']},
  {'name': 'Livre Collector Porsche 911 - L\'Anthologie 1963-2023', 'brand': 'Taschen', 'price': 150,
   'image': '', 'source': 'taschen.com',
   'tags': ['gender_homme','cat_tendances','budget_100_200','type_livres_bd','type_automobile','style_luxe','style_classique','perso_intellectuel','passion_automobile','passion_lecture','age_adulte','age_senior']},
  {'name': 'Circuit Scalextric Advance DTM Racing 1:32', 'brand': 'Scalextric', 'price': 189,
   'image': '', 'source': 'amazon.fr',
   'tags': ['gender_homme','cat_tendances','budget_100_200','type_jeux_jouets','type_automobile','style_classique','perso_creatif','passion_automobile','passion_loisirs_creatifs','age_enfant','age_ado','age_adulte']},
  {'name': 'Carte Cadeau Pilotage Moto Honda Bihr 250cc', 'brand': 'Bihr', 'price': 250,
   'image': '', 'source': 'bihr.fr',
   'tags': ['gender_homme','cat_tendances','budget_200+','type_voyage_aventure','type_automobile','style_sportif','perso_aventurier','passion_automobile','passion_sport','age_adulte','occasion_anniversaire']},
  {'name': 'Coffret Premium Detailing voiture Meguiar\'s 7p', 'brand': 'Meguiar\'s', 'price': 65,
   'image': '', 'source': 'amazon.fr',
   'tags': ['gender_homme','cat_tendances','budget_50_100','type_automobile','style_moderne','passion_automobile','perso_pratique','age_adulte','occasion_anniversaire']},
  {'name': 'Abonnement Motor Trend On Demand 1 an', 'brand': 'MotorTrend', 'price': 50,
   'image': '', 'source': 'motortrend.com',
   'tags': ['gender_homme','cat_tendances','budget_0_50','type_culture','type_automobile','passion_cinema','passion_automobile','age_adulte']},

  // ══════════ DIY / MAKER ══════════════════════════════════════════════════════
  {'name': 'Imprimante 3D Bambu Lab A1 Mini Combo', 'brand': 'Bambu Lab', 'price': 499,
   'image': '', 'source': 'bambulab.com',
   'tags': ['gender_mixte','cat_tech','budget_200+','type_high_tech','type_loisirs_creatifs','style_moderne','perso_creatif','perso_techie','passion_tech','passion_loisirs_creatifs','age_adulte','age_ado','popularite_5']},
  {'name': 'Kit Arduino Uno R4 WiFi Starter Electronics', 'brand': 'Arduino', 'price': 45,
   'image': '', 'source': 'arduino.cc',
   'tags': ['gender_mixte','cat_tech','budget_0_50','type_high_tech','type_loisirs_creatifs','style_moderne','perso_creatif','perso_techie','passion_tech','passion_bricolage','age_adulte','age_ado']},
  {'name': 'Dremel Stylo Graveur Multifonction 3000 Set', 'brand': 'Dremel', 'price': 79,
   'image': '', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_tendances','budget_50_100','type_loisirs_creatifs','style_moderne','perso_creatif','passion_bricolage','passion_art','age_adulte']},
  {'name': 'Machine Découpe Vinyle Cricut Joy Xtra', 'brand': 'Cricut', 'price': 229,
   'image': '', 'source': 'cricut.com',
   'tags': ['gender_femme','cat_tech','budget_200+','type_high_tech','type_loisirs_creatifs','style_moderne','style_tendance','perso_creatif','passion_loisirs_creatifs','passion_art','age_adulte','popularite_4']},
  {'name': 'Kit Lutherie Ukulélé à monter DIY', 'brand': 'Luthendo', 'price': 65,
   'image': '', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_tendances','budget_50_100','type_loisirs_creatifs','type_musique_audio','style_boheme','perso_creatif','passion_musique','passion_loisirs_creatifs','passion_bricolage','age_adulte','age_ado']},
  {'name': 'Forge à Bijoux Kit Bague Argent Atelier', 'brand': 'Atelier Laps', 'price': 89,
   'image': '', 'source': 'atelierlaps.fr',
   'tags': ['gender_femme','cat_tendances','budget_50_100','type_loisirs_creatifs','style_boheme','style_tendance','perso_creatif','passion_art','passion_loisirs_creatifs','age_adulte']},
  {'name': 'Raspberry Pi 5 Starter Kit 8GB + Case + Alimentation', 'brand': 'Raspberry Pi', 'price': 120,
   'image': '', 'source': 'raspberrypi.com',
   'tags': ['gender_mixte','cat_tech','budget_100_200','type_high_tech','style_moderne','perso_techie','passion_tech','passion_bricolage','age_adulte','age_ado']},

  // ══════════ SAISON HIVER / SPORTS D'HIVER ═══════════════════════════════════
  {'name': 'Forfait Ski Val Thorens 7 jours Adulte 2025', 'brand': 'Compagnie du Mont-Blanc', 'price': 350,
   'image': '', 'source': 'valthorens.com',
   'tags': ['gender_mixte','cat_tendances','budget_200+','type_sport_outdoor','type_voyage_aventure','style_sportif','perso_actif','perso_aventurier','passion_sport','passion_voyages','passion_nature','age_adulte','saison_hiver','occasion_noel']},
  {'name': 'Gants Ski Hestra Army Leather Heli Noir', 'brand': 'Hestra', 'price': 135,
   'image': '', 'source': 'hestra.com',
   'tags': ['gender_mixte','cat_mode','budget_100_200','type_sport_outdoor','type_mode_accessoires','style_sportif','perso_actif','passion_sport','passion_nature','age_adulte','saison_hiver']},
  {'name': 'Chaufferette Mains Zippo Rechargeable Noir', 'brand': 'Zippo', 'price': 45,
   'image': '', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_tendances','budget_0_50','type_sport_outdoor','type_bien_etre','style_classique','passion_nature','passion_sport','age_adulte','saison_hiver','occasion_noel']},
  {'name': 'Bonnet Laine Merinos Icebreaker Ski Union', 'brand': 'Icebreaker', 'price': 45,
   'image': '', 'source': 'icebreaker.com',
   'tags': ['gender_mixte','cat_mode','budget_0_50','type_sport_outdoor','type_mode_accessoires','style_sportif','style_eco_responsable','perso_actif','passion_sport','passion_nature','age_adulte','age_ado','saison_hiver']},
  {'name': 'Bouillotte Luxe Velours avec Housse Cousue', 'brand': 'Fashy', 'price': 28,
   'image': '', 'source': 'amazon.fr',
   'tags': ['gender_femme','cat_maison','budget_0_50','type_bien_etre','style_decontracte','perso_zen','age_adulte','age_senior','saison_hiver','occasion_noel','context_famille']},
  {'name': 'Tenue Ski Rossignol Femme Blazing Suit Rose', 'brand': 'Rossignol', 'price': 320,
   'image': '', 'source': 'rossignol.com',
   'tags': ['gender_femme','cat_mode','budget_200+','type_sport_outdoor','type_mode_accessoires','style_sportif','style_tendance','perso_actif','passion_sport','age_adulte','age_ado','saison_hiver']},
  {'name': 'Télescope Celestron StarSense Explorer DX 130AZ', 'brand': 'Celestron', 'price': 349,
   'image': '', 'source': 'celestron.com',
   'tags': ['gender_mixte','cat_tech','budget_200+','type_high_tech','type_sport_outdoor','style_moderne','perso_intellectuel','perso_aventurier','passion_nature','passion_tech','age_adulte','age_ado','saison_hiver','occasion_noel']},
  {'name': 'Coffret Chocolats Chauds Artisanaux Maison Rivière', 'brand': 'Rivière', 'price': 32,
   'image': '', 'source': 'amazon.fr',
   'tags': ['gender_mixte','cat_food','budget_0_50','type_gastronomie','style_classique','style_elegant','perso_gourmand','passion_cuisine','age_adulte','age_enfant','saison_hiver','occasion_noel','context_famille','popularite_4']},
];
