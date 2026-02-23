// ignore_for_file: avoid_print
/// Script de migration Firebase — ajoute les nouveaux tags (occasion, saison, popularite, type_intime)
/// aux produits existants dans la collection 'gifts'.
///
/// LOGIQUE: Analyse le nom du produit, la marque et les tags existants pour inférer
/// automatiquement les tags manquants.
///
/// Usage: flutter run -t lib/scripts/migrate_existing_products.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _migrate();
}

Future<void> _migrate() async {
  final db = FirebaseFirestore.instance;
  print('🔄 Migration — chargement des produits...');

  final snapshot = await db.collection('gifts').get();
  print('📦 ${snapshot.docs.length} produits trouvés.');

  var batch = db.batch();
  int batchCount = 0;
  int migratedCount = 0;

  for (final doc in snapshot.docs) {
    final data = doc.data();
    final name = (data['name'] ?? '').toString().toLowerCase();
    final brand = (data['brand'] ?? '').toString().toLowerCase();
    final price = (data['price'] ?? 0) as num;
    final existingTags = List<String>.from(data['tags'] ?? []);

    final newTags = List<String>.from(existingTags);
    bool changed = false;

    // ── 1. Popularité ─────────────────────────────────────────────────────────
    final hasPopularite = newTags.any((t) => t.startsWith('popularite_'));
    if (!hasPopularite) {
      final pop = _inferPopularite(brand, name, existingTags);
      if (pop != null) {
        newTags.add(pop);
        changed = true;
      }
    }

    // ── 2. Saison ─────────────────────────────────────────────────────────────
    final hasSaison = newTags.any((t) => t.startsWith('saison_'));
    if (!hasSaison) {
      final saison = _inferSaison(name, existingTags);
      if (saison != null) {
        newTags.add(saison);
        changed = true;
      }
    }

    // ── 3. Occasion ───────────────────────────────────────────────────────────
    final hasOccasion = newTags.any((t) => t.startsWith('occasion_'));
    if (!hasOccasion) {
      final occasions = _inferOccasions(name, brand, existingTags, price.toInt());
      if (occasions.isNotEmpty) {
        newTags.addAll(occasions);
        changed = true;
      }
    }

    // ── 4. type_intime ────────────────────────────────────────────────────────
    if (!newTags.contains('type_intime')) {
      if (_isIntime(name)) {
        newTags.add('type_intime');
        changed = true;
      }
    }

    if (changed) {
      // Dédupliquer
      final uniqueTags = newTags.toSet().toList();
      batch.update(doc.reference, {'tags': uniqueTags});
      batchCount++;
      migratedCount++;

      if (batchCount >= 490) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
        print('💾 Batch commité ($migratedCount produits migrés jusqu\'ici)...');
      }
    }
  }

  if (batchCount > 0) await batch.commit();
  print('✅ Migration terminée: $migratedCount produits mis à jour sur ${snapshot.docs.length}.');
}

// ── Inférence de popularité selon la marque ────────────────────────────────
String? _inferPopularite(String brand, String name, List<String> tags) {
  // Bestsellers viraux reconnus
  const viral = ['apple', 'chanel', 'dior', 'nike', 'airpods', 'lego', 'stanley',
    'crocs', 'ugg', 'nespresso', 'diptyque', 'rituals', 'the ordinary', 'lululemon'];
  // Populaires
  const popular = ['sony', 'samsung', 'lancôme', 'garmin', 'jbl', 'veja', 'sézane',
    'clarins', 'nuxe', 'kitchenaid', 'dyson', 'montblanc', 'longines', 'tractive'];
  // Niche
  const niche = ['iwachu', 'beebox', 'lotuscrafts', 'kumo', 'luthendo'];

  if (viral.any((b) => brand.contains(b) || name.contains(b))) return 'popularite_5';
  if (popular.any((b) => brand.contains(b))) return 'popularite_4';
  if (niche.any((b) => brand.contains(b))) return 'popularite_1';
  return 'popularite_3'; // Default
}

// ── Inférence de saison selon le nom du produit ────────────────────────────
String? _inferSaison(String name, List<String> tags) {
  // Hiver
  const kHiver = ['ski', 'snow', 'neige', 'bonnet', 'écharpe', 'manteau', 'doudoune',
    'bouillotte', 'chocolat chaud', 'noël', 'hiver', 'gants', 'chaufferette', 'fourrure',
    'cachemire', 'polaire', 'chaleur', 'couverture', 'plaid', 'ugg', 'apres-ski'];
  // Été
  const kEte = ['solaire', 'soleil', 'plage', 'bikini', 'été', 'barbecue', 'piscine',
    'sunscreen', 'tanning', 'sac de plage', 'parasol', 'ventilateur', 'sangria',
    'rafraîchissant', 'cool', 'estival', 'tong'];
  // Printemps
  const kPrintemps = ['fleurs', 'printemps', 'jardin', 'jardinage', 'semences', 'potager'];
  // Automne
  const kAutomne = ['automne', 'citrouille', 'truffes', 'vins', 'champagne', 'rentrée'];

  if (kHiver.any(name.contains)) return 'saison_hiver';
  if (kEte.any(name.contains)) return 'saison_ete';
  if (kPrintemps.any(name.contains)) return 'saison_printemps';
  if (kAutomne.any(name.contains)) return 'saison_automne';

  // Déduction depuis tags existants
  if (tags.any((t) => ['passion_ski','passion_snowboard'].contains(t))) return 'saison_hiver';
  if (tags.any((t) => ['passion_surf', 'passion_natation'].contains(t))) return 'saison_ete';
  if (tags.any((t) => ['passion_jardinage'].contains(t))) return 'saison_printemps';

  return null; // Produit universel
}

// ── Inférence des occasions selon le type de produit ─────────────────────
List<String> _inferOccasions(String name, String brand, List<String> tags, int price) {
  final occasions = <String>{};

  // Bijoux → anniversaire, mariage, saint-valentin systématiquement
  if (tags.contains('type_bijoux') || name.contains('bague') || name.contains('collier') ||
      name.contains('bracelet') || name.contains('montre')) {
    occasions.addAll(['occasion_anniversaire', 'occasion_mariage', 'occasion_saint_valentin']);
  }

  // Parfums → anniversaire, saint-valentin
  if (tags.contains('type_beaute_soins') &&
      (name.contains('parfum') || name.contains('eau de') || name.contains('edp') || name.contains('edt'))) {
    occasions.addAll(['occasion_anniversaire', 'occasion_saint_valentin']);
  }

  // Tech gadgets → noël, anniversaire
  if (tags.contains('type_high_tech')) {
    occasions.addAll(['occasion_noel', 'occasion_anniversaire']);
  }

  // Expériences → anniversaire
  if (tags.contains('type_voyage_aventure') || name.contains('expérience') ||
      name.contains('cours ') || name.contains('spa') || name.contains('dégustation')) {
    occasions.add('occasion_anniversaire');
  }

  // Bougie, spa, bien-être → saint-valentin
  if (tags.contains('type_bien_etre') &&
      (name.contains('bougie') || name.contains('bain') || name.contains('spa'))) {
    occasions.add('occasion_saint_valentin');
  }

  // Gastronomie haut de gamme → noël, anniversaire
  if (tags.contains('type_gastronomie') && price >= 40) {
    occasions.addAll(['occasion_noel', 'occasion_anniversaire']);
  }

  // Carnet, stylo → remerciement, collègue
  if (name.contains('carnet') || name.contains('stylo') || name.contains('plume')) {
    occasions.addAll(['occasion_remerciement', 'occasion_anniversaire']);
  }

  // Jouets enfant → noël
  if (tags.contains('type_jeux_jouets') || tags.contains('age_enfant')) {
    occasions.add('occasion_noel');
  }

  return occasions.toList();
}

// ── Inférence type_intime ─────────────────────────────────────────────────
bool _isIntime(String name) {
  const keywords = ['lingerie', 'soutien-gorge', 'culotte', 'string', 'boxer',
    'slip', 'sexy', 'massage érotique', 'bijou intime', 'accessoire romantique',
    'vibromasseur', 'sextoy'];
  return keywords.any(name.contains);
}
