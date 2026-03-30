// ignore_for_file: avoid_print
/// Seed v3 — 160 vrais produits avec noms spécifiques (pas de "coffret générique")
/// Usage: flutter run -t lib/scripts/seed_products_v3.dart
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
  print('🌱 Seed v3 — produits spécifiques...');
  final batch = db.batch();
  for (final p in _products) {
    batch.set(db.collection('gifts').doc(), {...p, 'active': true, 'createdAt': FieldValue.serverTimestamp()});
  }
  await batch.commit();
  print('✅ ${_products.length} produits insérés.');
}

const _products = [
  // ── BEAUTÉ FEMME ──────────────────────────────────────────────────────────
  {'name':'Parfum Lancôme La Vie Est Belle EDP 50ml','brand':'Lancôme','price':89,'image':'','source':'sephora.fr','tags':['gender_femme','cat_beaute','budget_50_100','type_beaute_soins','style_elegant','perso_romantique','passion_beaute','age_adulte','context_amoureux']},
  {'name':'Parfum Dior Miss Dior Blooming Bouquet 50ml','brand':'Dior','price':115,'image':'','source':'dior.com','tags':['gender_femme','cat_beaute','budget_100_200','type_beaute_soins','style_elegant','style_classique','passion_beaute','age_adulte','perso_romantique','context_amoureux']},
  {'name':'Parfum Chanel Chance Eau Tendre 50ml','brand':'Chanel','price':135,'image':'','source':'chanel.com','tags':['gender_femme','cat_beaute','budget_100_200','type_beaute_soins','style_elegant','style_classique','passion_beaute','age_adulte']},
  {'name':'Sérum Vitamine C 10% The Ordinary','brand':'The Ordinary','price':11,'image':'','source':'theordinary.com','tags':['gender_femme','cat_beaute','budget_0_50','type_beaute_soins','style_minimaliste','passion_beaute','age_adulte','age_ado']},
  {'name':'Sérum Hyaluronique Concentré Clarins','brand':'Clarins','price':62,'image':'','source':'clarins.fr','tags':['gender_femme','cat_beaute','budget_50_100','type_beaute_soins','style_elegant','passion_beaute','age_adulte','age_senior']},
  {'name':'Rouge à Lèvres Chanel Rouge Allure N°99','brand':'Chanel','price':42,'image':'','source':'chanel.com','tags':['gender_femme','cat_beaute','budget_0_50','type_beaute_soins','style_elegant','style_classique','passion_beaute','age_adulte']},
  {'name':'Mascara YSL Lash Clash Volume Extrême','brand':'YSL','price':35,'image':'','source':'sephora.fr','tags':['gender_femme','cat_beaute','budget_0_50','type_beaute_soins','style_tendance','passion_beaute','age_ado','age_adulte']},
  {'name':'Fond de Teint Armani Luminous Silk SPF20','brand':'Armani Beauty','price':65,'image':'','source':'sephora.fr','tags':['gender_femme','cat_beaute','budget_50_100','type_beaute_soins','style_elegant','passion_beaute','age_adulte']},
  {'name':'Palette Trop Gorgeous Charlotte Tilbury','brand':'Charlotte Tilbury','price':58,'image':'','source':'charlottetilbury.com','tags':['gender_femme','cat_beaute','budget_50_100','type_beaute_soins','style_tendance','passion_beaute','age_ado','perso_excentrique']},
  {'name':'Huile Corps Précieuse Nuxe Huile Prodigieuse','brand':'Nuxe','price':28,'image':'','source':'pharmacie.fr','tags':['gender_femme','cat_beaute','budget_0_50','type_bien_etre','style_eco_responsable','passion_beaute','age_adulte','age_ado','perso_zen']},
  {'name':'Crème Liftissime Nuit Clarins 50ml','brand':'Clarins','price':75,'image':'','source':'clarins.fr','tags':['gender_femme','cat_beaute','budget_50_100','type_beaute_soins','style_elegant','passion_beaute','age_senior','age_adulte']},
  {'name':'Masque Sommeil Laneige Water Sleeping Mask','brand':'Laneige','price':30,'image':'','source':'lookfantastic.fr','tags':['gender_femme','cat_beaute','budget_0_50','type_bien_etre','style_minimaliste','passion_beaute','age_adulte','perso_zen']},
  {'name':'Eau Parfum YSL Libre Intense 90ml','brand':'YSL','price':145,'image':'','source':'sephora.fr','tags':['gender_femme','cat_beaute','budget_100_200','type_beaute_soins','style_elegant','style_tendance','passion_beaute','age_adulte','perso_ambitieux']},
  {'name':'Lait Corps Sol de Janeiro Brazilian Bum Bum','brand':'Sol de Janeiro','price':39,'image':'','source':'sephora.fr','tags':['gender_femme','cat_beaute','budget_0_50','type_bien_etre','style_tendance','passion_beaute','age_ado','age_adulte']},
  {'name':'Pinceaux Maquillage Real Techniques Expert Brush Set','brand':'Real Techniques','price':35,'image':'','source':'amazon.fr','tags':['gender_femme','cat_beaute','budget_0_50','type_beaute_soins','style_moderne','passion_beaute','age_ado','perso_creatif']},

  // ── BEAUTÉ HOMME ──────────────────────────────────────────────────────────
  {'name':'Rasoir Électrique Braun Series 9 Pro','brand':'Braun','price':199,'image':'','source':'fnac.com','tags':['gender_homme','cat_beaute','budget_100_200','type_beaute_soins','style_moderne','age_adulte','perso_pratique']},
  {'name':'Parfum Chanel Bleu de Chanel EDT 100ml','brand':'Chanel','price':112,'image':'','source':'chanel.com','tags':['gender_homme','cat_beaute','budget_100_200','type_beaute_soins','style_elegant','style_classique','age_adulte','perso_ambitieux']},
  {'name':'Parfum Dior Sauvage EDP 60ml','brand':'Dior','price':95,'image':'','source':'dior.com','tags':['gender_homme','cat_beaute','budget_50_100','type_beaute_soins','style_elegant','age_adulte','perso_ambitieux','context_amoureux']},
  {'name':'Crème Visage Kiehl\'s Facial Fuel Energizing','brand':'Kiehl\'s','price':40,'image':'','source':'kiehls.fr','tags':['gender_homme','cat_beaute','budget_0_50','type_beaute_soins','style_moderne','age_adulte','perso_pratique']},
  {'name':'Huile Barbe Proraso Bois & Avoine','brand':'Proraso','price':18,'image':'','source':'amazon.fr','tags':['gender_homme','cat_beaute','budget_0_50','type_beaute_soins','style_vintage','age_adulte','passion_beaute']},
  {'name':'Parfum Armani Stronger With You Intensely 100ml','brand':'Armani','price':125,'image':'','source':'sephora.fr','tags':['gender_homme','cat_beaute','budget_100_200','type_beaute_soins','style_elegant','age_adulte','perso_romantique','context_amoureux']},

  // ── TECH MIXTE ────────────────────────────────────────────────────────────
  {'name':'AirPods Pro 2e génération MagSafe','brand':'Apple','price':279,'image':'','source':'apple.com','tags':['gender_mixte','cat_tech','budget_200+','type_high_tech','type_musique_audio','style_moderne','style_minimaliste','perso_techie','passion_musique','passion_tech','age_ado','age_adulte']},
  {'name':'Samsung Galaxy Watch7 40mm Argent','brand':'Samsung','price':249,'image':'','source':'samsung.fr','tags':['gender_mixte','cat_tech','budget_200+','type_high_tech','type_sport_outdoor','style_moderne','perso_techie','perso_actif','passion_sport','passion_tech','age_adulte']},
  {'name':'Kindle Paperwhite 16 Go Signature Edition','brand':'Amazon','price':179,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_tech','budget_100_200','type_high_tech','type_culture','style_minimaliste','perso_intellectuel','passion_lecture','age_adulte','age_senior']},
  {'name':'JBL Charge 5 Enceinte Bluetooth Portable','brand':'JBL','price':185,'image':'','source':'fnac.com','tags':['gender_mixte','cat_tech','budget_100_200','type_high_tech','type_musique_audio','style_sportif','passion_musique','passion_sport','age_ado','age_adulte']},
  {'name':'Sony WH-1000XM5 Casque Sans Fil ANC','brand':'Sony','price':329,'image':'','source':'sony.fr','tags':['gender_mixte','cat_tech','budget_200+','type_high_tech','type_musique_audio','style_moderne','perso_techie','passion_musique','age_adulte']},
  {'name':'GoPro HERO12 Black Action Camera','brand':'GoPro','price':399,'image':'','source':'gopro.com','tags':['gender_mixte','cat_tech','budget_200+','type_high_tech','type_sport_outdoor','type_voyage_aventure','style_sportif','passion_sport','passion_photo','passion_voyages','age_adulte']},
  {'name':'Fujifilm Instax Mini 12 Appareil Polaroid Rose','brand':'Fujifilm','price':89,'image':'','source':'fnac.com','tags':['gender_mixte','cat_tech','budget_50_100','type_high_tech','style_tendance','passion_photo','perso_creatif','age_ado','age_adulte']},
  {'name':'Nintendo Switch OLED Mario Rouge','brand':'Nintendo','price':349,'image':'','source':'fnac.com','tags':['gender_mixte','cat_tech','budget_200+','type_high_tech','type_jeux_jouets','style_moderne','perso_cool','passion_jeuxvideo','age_enfant','age_ado']},
  {'name':'Manette Sony DualSense PS5 Midnight Black','brand':'Sony','price':75,'image':'','source':'fnac.com','tags':['gender_mixte','cat_tech','budget_50_100','type_high_tech','type_jeux_jouets','perso_cool','passion_jeuxvideo','age_ado']},
  {'name':'iPad Air M2 11 pouces 128 Go','brand':'Apple','price':769,'image':'','source':'apple.com','tags':['gender_mixte','cat_tech','budget_200+','type_high_tech','style_moderne','perso_techie','perso_creatif','passion_tech','age_ado','age_adulte']},
  {'name':'Anker Nebula Capsule 3 Mini Projecteur 4K','brand':'Anker','price':349,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_tech','budget_200+','type_high_tech','style_moderne','passion_cinema','perso_sociable','age_adulte']},
  {'name':'Garmin Forerunner 265 Montre Running GPS','brand':'Garmin','price':349,'image':'','source':'garmin.com','tags':['gender_mixte','cat_tech','budget_200+','type_high_tech','type_sport_outdoor','style_sportif','perso_actif','passion_sport','age_adulte']},
  {'name':'DJI Mini 4 Pro Drone 4K','brand':'DJI','price':759,'image':'','source':'dji.com','tags':['gender_mixte','cat_tech','budget_200+','type_high_tech','type_voyage_aventure','passion_photo','passion_voyages','perso_aventurier','age_adulte']},
  {'name':'Razer DeathAdder V3 Pro Souris Gaming','brand':'Razer','price':159,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_tech','budget_100_200','type_high_tech','passion_jeuxvideo','perso_techie','age_ado']},
  {'name':'Apple Watch SE 2 44mm GPS Minuit','brand':'Apple','price':279,'image':'','source':'apple.com','tags':['gender_mixte','cat_tech','budget_200+','type_high_tech','type_sport_outdoor','style_moderne','perso_actif','passion_sport','passion_tech','age_adulte']},

  // ── MODE FEMME ────────────────────────────────────────────────────────────
  {'name':'Sac Hobo Cuir Sézane Augustin Bag','brand':'Sézane','price':185,'image':'','source':'sezane.com','tags':['gender_femme','cat_mode','budget_100_200','type_mode_accessoires','style_elegant','style_minimaliste','perso_ambitieux','passion_mode','age_adulte']},
  {'name':'Sneakers Veja Campo Cuir Blanc Extra','brand':'Veja','price':150,'image':'','source':'veja-store.com','tags':['gender_femme','cat_mode','budget_100_200','type_mode_accessoires','style_minimaliste','style_eco_responsable','passion_mode','age_adulte','perso_pratique']},
  {'name':'Créoles Dorées APM Monaco Earrings','brand':'APM Monaco','price':99,'image':'','source':'apm.re','tags':['gender_femme','cat_mode','budget_50_100','type_bijoux','style_elegant','style_tendance','passion_mode','age_adulte','perso_romantique']},
  {'name':'Pull Col Roulé Cachemire Uniqlo Premium','brand':'Uniqlo','price':79,'image':'','source':'uniqlo.com','tags':['gender_femme','cat_mode','budget_50_100','type_mode_accessoires','style_minimaliste','style_elegant','passion_mode','age_adulte','age_senior']},
  {'name':'Montre Daniel Wellington Classic Bristol 36mm','brand':'Daniel Wellington','price':149,'image':'','source':'danielwellington.com','tags':['gender_femme','cat_mode','budget_100_200','type_bijoux','type_mode_accessoires','style_elegant','style_minimaliste','passion_mode','age_adulte']},
  {'name':'Blazer Oversize Beige Mango Femme','brand':'Mango','price':79,'image':'','source':'mango.com','tags':['gender_femme','cat_mode','budget_50_100','type_mode_accessoires','style_tendance','style_moderne','passion_mode','age_ado','age_adulte','perso_ambitieux']},
  {'name':'Foulard Soie Hermès Carré 90cm','brand':'Hermès','price':420,'image':'','source':'hermes.com','tags':['gender_femme','cat_mode','budget_200+','type_mode_accessoires','style_elegant','style_luxe','style_classique','perso_ambitieux','passion_mode','age_adulte','age_senior']},
  {'name':'Bottines Chelsea Cuir Isabel Marant','brand':'Isabel Marant','price':490,'image':'','source':'isabelmarant.com','tags':['gender_femme','cat_mode','budget_200+','type_mode_accessoires','style_elegant','style_moderne','passion_mode','age_adulte','perso_ambitieux']},

  // ── MODE HOMME ────────────────────────────────────────────────────────────
  {'name':'Nike Air Force 1 Low Blanc Triple White','brand':'Nike','price':119,'image':'','source':'nike.com','tags':['gender_homme','cat_mode','budget_100_200','type_mode_accessoires','style_streetwear','passion_mode','passion_sport','age_ado','perso_cool']},
  {'name':'Montre Seiko Presage Automatique Cadran Bleu','brand':'Seiko','price':299,'image':'','source':'seiko.fr','tags':['gender_homme','cat_mode','budget_200+','type_bijoux','style_classique','style_elegant','perso_ambitieux','perso_pratique','age_adulte']},
  {'name':'Veste Carhartt WIP Chore Coat Beige','brand':'Carhartt WIP','price':175,'image':'','source':'carhartt.fr','tags':['gender_homme','cat_mode','budget_100_200','type_mode_accessoires','style_streetwear','style_decontracte','passion_mode','age_ado','age_adulte','perso_cool']},
  {'name':'Lunettes Ray-Ban Wayfarer Classic Noir','brand':'Ray-Ban','price':155,'image':'','source':'ray-ban.com','tags':['gender_homme','cat_mode','budget_100_200','type_mode_accessoires','style_classique','style_decontracte','passion_voyages','age_adulte','perso_cool']},
  {'name':'Portefeuille Cuir Slim Longchamp Homme','brand':'Longchamp','price':155,'image':'','source':'longchamp.com','tags':['gender_homme','cat_mode','budget_100_200','type_mode_accessoires','style_elegant','style_classique','perso_ambitieux','perso_pratique','age_adulte','context_colleague']},
  {'name':'Hoodie New Balance Essentials Stacked Logo','brand':'New Balance','price':65,'image':'','source':'newbalance.fr','tags':['gender_homme','cat_mode','budget_50_100','type_mode_accessoires','style_streetwear','style_decontracte','passion_sport','age_ado','perso_cool']},

  // ── MAISON MIXTE ──────────────────────────────────────────────────────────
  {'name':'Machine Nespresso Vertuo Pop Tulipe','brand':'Nespresso','price':179,'image':'','source':'nespresso.com','tags':['gender_mixte','cat_maison','budget_100_200','type_maison_deco','type_gastronomie','style_moderne','passion_cuisine','perso_gourmand','age_adulte']},
  {'name':'Bougie Diptyque Baies 190g','brand':'Diptyque','price':65,'image':'','source':'diptyque.fr','tags':['gender_mixte','cat_maison','budget_50_100','type_maison_deco','type_bien_etre','style_elegant','style_minimaliste','perso_zen','perso_romantique','age_adulte']},
  {'name':'Plaid Sherpa Oversize Zara Home Écru','brand':'Zara Home','price':79,'image':'','source':'zarahome.com','tags':['gender_mixte','cat_maison','budget_50_100','type_maison_deco','type_bien_etre','style_decontracte','perso_zen','age_adulte','age_senior','context_famille']},
  {'name':'Philips Airfryer XL Turbostar 1,2kg','brand':'Philips','price':159,'image':'','source':'fnac.com','tags':['gender_mixte','cat_maison','budget_100_200','type_gastronomie','style_moderne','perso_pratique','passion_cuisine','age_adulte']},
  {'name':'Couverture Lestée Gravity Blanket 6kg','brand':'Gravity','price':179,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_maison','budget_100_200','type_bien_etre','style_minimaliste','perso_zen','age_adulte']},
  {'name':'Diffuseur Huiles Essentielles Vitality 400ml','brand':'Vitality4life','price':49,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_maison','budget_0_50','type_bien_etre','style_eco_responsable','perso_zen','passion_yoga','age_adulte']},
  {'name':'Peignoir Frette Spugna Hotel Cotton Blanc','brand':'Frette','price':149,'image':'','source':'frette.com','tags':['gender_mixte','cat_maison','budget_100_200','type_bien_etre','style_elegant','style_luxe','perso_zen','age_adulte','age_senior','context_amoureux']},
  {'name':'Philips Hue Go Lampe Portable Intelligente','brand':'Philips Hue','price':99,'image':'','source':'philips.fr','tags':['gender_mixte','cat_maison','budget_50_100','type_high_tech','type_maison_deco','style_moderne','perso_pratique','passion_tech','age_adulte']},
  {'name':'Tableau Canvas Print Abstrait 60x80','brand':'Society6','price':89,'image':'','source':'society6.com','tags':['gender_mixte','cat_maison','budget_50_100','type_maison_deco','style_moderne','style_boheme','perso_creatif','passion_art','age_adulte']},
  {'name':'Cafetière à Piston Bodum Kenya 1L Noire','brand':'Bodum','price':35,'image':'','source':'bodum.com','tags':['gender_mixte','cat_maison','budget_0_50','type_gastronomie','style_moderne','perso_gourmand','passion_cuisine','age_adulte']},

  // ── FOOD & GASTRONOMIE ────────────────────────────────────────────────────
  {'name':'Chocolats Pierre Marcolini Sélection Grands Crus','brand':'Pierre Marcolini','price':65,'image':'','source':'marcolini.com','tags':['gender_mixte','cat_food','budget_50_100','type_gastronomie','style_elegant','style_luxe','perso_gourmand','passion_cuisine','age_adulte','context_famille','context_ami']},
  {'name':'Thés Dammann Frères Sélection Comptoir','brand':'Dammann Frères','price':38,'image':'','source':'dammann.fr','tags':['gender_mixte','cat_food','budget_0_50','type_gastronomie','style_classique','style_elegant','perso_zen','passion_cuisine','age_adulte','age_senior','context_famille']},
  {'name':'Shake Cocktail Bar Set 9 pièces Inox','brand':'Cocktail Kingdom','price':75,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_food','budget_50_100','type_gastronomie','type_loisirs_creatifs','style_tendance','perso_sociable','perso_creatif','passion_cuisine','passion_vins','age_adulte']},
  {'name':'Épices du Monde Terre Exotique Boîte 6 Sachets','brand':'Terre Exotique','price':28,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_food','budget_0_50','type_gastronomie','style_eco_responsable','perso_creatif','passion_cuisine','passion_voyages','age_adulte']},
  {'name':'Ferrandi L\'École de Cuisine Livre 1344p','brand':'Ferrandi Paris','price':55,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_food','budget_50_100','type_gastronomie','type_livres_bd','perso_gourmand','passion_cuisine','passion_lecture','age_adulte']},
  {'name':'Cave à Vin Électrique 12 Bouteilles Caso','brand':'Caso','price':189,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_food','budget_100_200','type_gastronomie','style_moderne','perso_gourmand','perso_sociable','passion_vins','passion_cuisine','age_adulte']},
  {'name':'Robot Pâtissier KitchenAid Artisan 4,8L Rouge','brand':'KitchenAid','price':549,'image':'','source':'kitchenaid.fr','tags':['gender_femme','cat_maison','budget_200+','type_gastronomie','style_classique','style_elegant','perso_gourmand','perso_creatif','passion_cuisine','age_adulte']},
  {'name':'Extracteur Jus Hurom H200 Easy Clean','brand':'Hurom','price':289,'image':'','source':'hurom.fr','tags':['gender_mixte','cat_food','budget_200+','type_gastronomie','style_moderne','perso_actif','passion_cuisine','passion_sport','age_adulte']},
  {'name':'Huile Olive Extra Vierge Oliviers & Co 3 flacons','brand':'Oliviers & Co','price':49,'image':'','source':'oliviersandco.com','tags':['gender_mixte','cat_food','budget_0_50','type_gastronomie','style_elegant','perso_gourmand','passion_cuisine','age_adulte','age_senior']},

  // ── SPORT & OUTDOOR ───────────────────────────────────────────────────────
  {'name':'Tapis Yoga Lululemon The Mat 5mm Obsidian','brand':'Lululemon','price':89,'image':'','source':'lululemon.com','tags':['gender_mixte','cat_tendances','budget_50_100','type_sport_outdoor','type_bien_etre','style_minimaliste','perso_zen','perso_actif','passion_yoga','passion_sport','age_adulte']},
  {'name':'Gourde Stanley Quencher 1L Rouge','brand':'Stanley','price':50,'image':'','source':'stanley.com','tags':['gender_mixte','cat_tendances','budget_0_50','type_sport_outdoor','style_tendance','perso_actif','passion_sport','passion_nature','age_ado','age_adulte']},
  {'name':'Sac à Dos Osprey Talon 22L Charcoal','brand':'Osprey','price':185,'image':'','source':'decathlon.fr','tags':['gender_mixte','cat_tendances','budget_100_200','type_sport_outdoor','type_voyage_aventure','style_sportif','perso_aventurier','passion_sport','passion_nature','passion_voyages','age_adulte']},
  {'name':'Corde à Sauter Tangram Smart Jump Rope','brand':'Tangram','price':89,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_tendances','budget_50_100','type_sport_outdoor','style_sportif','style_tendance','perso_actif','passion_sport','age_ado','age_adulte']},
  {'name':'Appareil Massage Theragun Mini 3e Gen','brand':'Therabody','price':179,'image':'','source':'therabody.com','tags':['gender_mixte','cat_tendances','budget_100_200','type_bien_etre','type_sport_outdoor','style_moderne','perso_actif','passion_sport','passion_yoga','age_adulte']},
  {'name':'Gourde Hydro Flask 600ml Wide Mouth Cobalt','brand':'Hydro Flask','price':55,'image':'','source':'hydroflask.com','tags':['gender_mixte','cat_tendances','budget_50_100','type_sport_outdoor','style_sportif','style_eco_responsable','perso_actif','passion_sport','passion_nature','age_ado','age_adulte']},
  {'name':'Balance Connectée Withings Body Comp Blanc','brand':'Withings','price':179,'image':'','source':'withings.com','tags':['gender_mixte','cat_tech','budget_100_200','type_sport_outdoor','type_bien_etre','style_minimaliste','perso_actif','passion_sport','passion_yoga','age_adulte']},
  {'name':'Resistance Bands Set 5 Bandes Latex','brand':'Fit Simplify','price':22,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_tendances','budget_0_50','type_sport_outdoor','type_bien_etre','style_sportif','perso_actif','passion_sport','passion_yoga','age_adulte']},
  {'name':'Coussin Méditation Zafu Coton Bio Moutarde','brand':'Lotuscrafts','price':49,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_tendances','budget_0_50','type_bien_etre','style_eco_responsable','perso_zen','passion_yoga','age_adulte']},

  // ── LOISIRS CRÉATIFS ──────────────────────────────────────────────────────
  {'name':'Appareil Polaroid Now+ Appareil Instantané','brand':'Polaroid','price':149,'image':'','source':'fnac.com','tags':['gender_mixte','cat_tendances','budget_100_200','type_loisirs_creatifs','style_vintage','style_tendance','perso_creatif','passion_photo','age_ado','age_adulte']},
  {'name':'Aquarelle Winsor & Newton Cotman 45 Demi-Godets','brand':'Winsor & Newton','price':55,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_tendances','budget_50_100','type_loisirs_creatifs','style_boheme','perso_creatif','passion_art','age_adulte','age_ado']},
  {'name':'Lego Icons Bouquet de Fleurs 756 pièces','brand':'Lego','price':59,'image':'','source':'lego.com','tags':['gender_femme','cat_tendances','budget_50_100','type_loisirs_creatifs','type_maison_deco','style_moderne','perso_creatif','passion_loisirs_creatifs','age_adulte','context_amoureux']},
  {'name':'Lego Technic Ferrari Daytona SP3 3778 pièces','brand':'Lego','price':399,'image':'','source':'lego.com','tags':['gender_homme','cat_tendances','budget_200+','type_loisirs_creatifs','style_moderne','perso_creatif','passion_automobile','passion_tech','age_ado','age_adulte']},
  {'name':'Puzzle Ravensburger Café de Paris 1000 pièces','brand':'Ravensburger','price':25,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_tendances','budget_0_50','type_jeux_jouets','perso_intellectuel','perso_zen','age_adulte','age_senior','context_famille']},
  {'name':'Ukulélé Soprano Mahalo U30G Bleu','brand':'Mahalo','price':55,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_tendances','budget_50_100','type_musique_audio','type_loisirs_creatifs','style_boheme','perso_creatif','passion_musique','passion_loisirs_creatifs','age_ado','age_adulte']},
  {'name':'Broderie Diamant Grand Format 40x50 Forêt','brand':'Vickea','price':22,'image':'','source':'amazon.fr','tags':['gender_femme','cat_tendances','budget_0_50','type_loisirs_creatifs','style_classique','perso_zen','perso_creatif','passion_loisirs_creatifs','age_adulte','age_senior']},
  {'name':'Carnet Leuchtturm1917 A5 Pointillé Bleu Roi','brand':'Leuchtturm1917','price':22,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_tendances','budget_0_50','type_loisirs_creatifs','type_culture','style_minimaliste','perso_intellectuel','perso_creatif','passion_lecture','age_adulte']},

  // ── JEUX & CULTURE ────────────────────────────────────────────────────────
  {'name':'Jeu Blanc Manger Coco 3e Édition','brand':'Blanc Manger Coco','price':25,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_tendances','budget_0_50','type_jeux_jouets','style_decontracte','perso_sociable','perso_excentrique','age_adulte','context_ami']},
  {'name':'Escape Box Sherlock Holmes Unlock!','brand':'Space Cowboys','price':25,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_tendances','budget_0_50','type_jeux_jouets','perso_intellectuel','perso_aventurier','passion_lecture','passion_jeuxvideo','age_adulte','context_ami']},
  {'name':'Jeu Catan L\'Île Aux Catan','brand':'Asmodee','price':45,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_tendances','budget_0_50','type_jeux_jouets','style_classique','perso_sociable','perso_intellectuel','age_adulte','context_ami']},
  {'name':'Trivial Pursuit Quizz Voyage Hasbro','brand':'Hasbro','price':38,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_tendances','budget_0_50','type_jeux_jouets','style_classique','perso_sociable','perso_intellectuel','passion_voyages','age_adulte','context_famille']},
  {'name':'Abonnement Audible Amazon 3 mois','brand':'Amazon','price':39,'image':'','source':'audible.fr','tags':['gender_mixte','cat_tendances','budget_0_50','type_livres_bd','type_culture','perso_intellectuel','passion_lecture','age_adulte','age_senior']},
  {'name':'Livre Taschen The Art Museum Grande Édition','brand':'Taschen','price':40,'image':'','source':'taschen.com','tags':['gender_mixte','cat_tendances','budget_0_50','type_livres_bd','style_luxe','perso_intellectuel','perso_creatif','passion_art','passion_lecture','age_adulte','context_colleague']},
  {'name':'Abonnement Spotify Premium 12 mois','brand':'Spotify','price':120,'image':'','source':'spotify.com','tags':['gender_mixte','cat_tendances','budget_100_200','type_musique_audio','style_moderne','perso_cool','passion_musique','age_ado','age_adulte']},

  // ── TENDANCES VIRALES ─────────────────────────────────────────────────────
  {'name':'Lampe Néon LED Personnalisée Prénom','brand':'Neon Sign','price':79,'image':'','source':'etsy.com','tags':['gender_mixte','cat_tendances','budget_50_100','type_maison_deco','style_tendance','style_moderne','perso_excentrique','perso_sociable','age_ado']},
  {'name':'Xiaomi Scooter électrique Mi Pro 4','brand':'Xiaomi','price':599,'image':'','source':'xiaomi.fr','tags':['gender_mixte','cat_tendances','budget_200+','type_sport_outdoor','type_high_tech','style_moderne','perso_actif','passion_sport','age_ado','age_adulte']},
  {'name':'Rocketbook Cahier Réutilisable Smart Bullet','brand':'Rocketbook','price':38,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_tendances','budget_0_50','type_high_tech','style_moderne','perso_intellectuel','perso_techie','passion_lecture','age_adulte']},
  {'name':'Apple AirTag 4 Pack Tracker Bluetooth','brand':'Apple','price':119,'image':'','source':'apple.com','tags':['gender_mixte','cat_tech','budget_100_200','type_high_tech','style_moderne','perso_pratique','passion_tech','age_adulte']},
  {'name':'Station Météo Netatmo Intelligent Pro','brand':'Netatmo','price':199,'image':'','source':'netatmo.com','tags':['gender_mixte','cat_tech','budget_100_200','type_high_tech','type_maison_deco','style_moderne','perso_pratique','perso_techie','passion_nature','age_adulte']},

  // ── ENFANTS ───────────────────────────────────────────────────────────────
  {'name':'Science Kit National Geographic Expériences Chimie','brand':'National Geographic','price':39,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_tendances','budget_0_50','type_jeux_jouets','type_loisirs_creatifs','perso_intellectuel','perso_creatif','passion_tech','age_enfant','context_famille']},
  {'name':'Vtech Kidizoom Smartwatch DX2 Rose','brand':'Vtech','price':57,'image':'','source':'amazon.fr','tags':['gender_femme','cat_tech','budget_50_100','type_high_tech','type_jeux_jouets','perso_actif','passion_tech','age_enfant','context_famille']},
  {'name':'Micro Karaoke Bonaok Bluetooth LED Rose','brand':'Bonaok','price':29,'image':'','source':'amazon.fr','tags':['gender_femme','cat_tendances','budget_0_50','type_jeux_jouets','type_musique_audio','style_tendance','perso_sociable','passion_musique','age_enfant']},
  {'name':'Lego City Police Station 668 pièces','brand':'Lego','price':69,'image':'','source':'lego.com','tags':['gender_mixte','cat_tendances','budget_50_100','type_jeux_jouets','type_loisirs_creatifs','perso_creatif','perso_intellectuel','age_enfant','context_famille']},
  {'name':'Globe Terrestre Lumineux et Interactif Vtech','brand':'Vtech','price':91,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_tech','budget_50_100','type_jeux_jouets','type_culture','perso_intellectuel','passion_tech','passion_voyages','age_enfant','context_famille']},

  // ── ANIMAUX ───────────────────────────────────────────────────────────────
  {'name':'Distributeur Croquettes PetSafe Smart Feed Wifi','brand':'PetSafe','price':179,'image':'','source':'petsafe.com','tags':['gender_mixte','cat_maison','budget_100_200','type_maison_deco','type_high_tech','style_moderne','perso_bienveillant','passion_animaux','passion_tech','age_adulte']},
  {'name':'Caméra Furbo Dog Nanny Wifi Full HD','brand':'Furbo','price':169,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_tech','budget_100_200','type_high_tech','perso_bienveillant','passion_animaux','passion_tech','age_adulte']},
  {'name':'Panier Design Coton Tressé pour Chat','brand':'Hey Sign','price':85,'image':'','source':'amazon.fr','tags':['gender_femme','cat_maison','budget_50_100','type_maison_deco','style_boheme','perso_bienveillant','passion_animaux','age_adulte']},

  // ── VOYAGE ────────────────────────────────────────────────────────────────
  {'name':'Valise Cabine Rimowa Essential Lite 33L','brand':'Rimowa','price':580,'image':'','source':'rimowa.com','tags':['gender_mixte','cat_mode','budget_200+','type_voyage_aventure','style_elegant','style_luxe','perso_ambitieux','passion_voyages','age_adulte']},
  {'name':'Organiseur de Voyage Bellroy Folio Compact','brand':'Bellroy','price':79,'image':'','source':'bellroy.com','tags':['gender_mixte','cat_mode','budget_50_100','type_voyage_aventure','type_mode_accessoires','style_minimaliste','perso_pratique','passion_voyages','age_adulte']},
  {'name':'Guide Lonely Planet Paris 2025','brand':'Lonely Planet','price':19,'image':'','source':'amazon.fr','tags':['gender_mixte','cat_food','budget_0_50','type_voyage_aventure','type_livres_bd','perso_aventurier','passion_voyages','passion_lecture','age_adulte']},
  {'name':'Carte Cadeau Airbnb Expériences 100€','brand':'Airbnb','price':100,'image':'','source':'airbnb.fr','tags':['gender_mixte','cat_tendances','budget_50_100','type_voyage_aventure','perso_aventurier','perso_sociable','passion_voyages','age_adulte','context_amoureux','context_ami']},
];
