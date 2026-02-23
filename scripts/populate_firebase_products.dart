import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

/// Script pour peupler Firebase avec les produits depuis fallback_products.json
///
/// UTILISATION:
/// 1. Ouvre un terminal dans le dossier du projet
/// 2. Lance: dart run scripts/populate_firebase_products.dart
/// 3. Attends que tous les produits soient uploadés (peut prendre 5-10 minutes)
///
/// Ce script va:
/// - Lire assets/jsons/fallback_products.json
/// - Uploader tous les produits dans Firestore collection 'products'
/// - Batch par 500 produits pour éviter les limites Firestore

Future<void> main() async {
  print('🚀 Démarrage du script de peuplement Firebase...\n');

  // Initialiser Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialisé\n');
  } catch (e) {
    print('❌ Erreur initialisation Firebase: $e');
    exit(1);
  }

  final firestore = FirebaseFirestore.instance;

  // Lire le fichier JSON
  print('📖 Lecture du fichier fallback_products.json...');
  final jsonFile = File('assets/jsons/fallback_products.json');

  if (!await jsonFile.exists()) {
    print('❌ Fichier fallback_products.json non trouvé!');
    print('   Chemin attendu: ${jsonFile.absolute.path}');
    exit(1);
  }

  final jsonString = await jsonFile.readAsString();
  final List<dynamic> products = json.decode(jsonString);

  print('✅ ${products.length} produits chargés depuis le JSON\n');

  // Vérifier si la collection existe déjà et combien de produits
  final existingSnapshot = await firestore.collection('products').limit(1).get();
  if (existingSnapshot.docs.isNotEmpty) {
    print('⚠️  La collection "products" existe déjà dans Firebase');
    print('   Voulez-vous la SUPPRIMER et recommencer? (y/n)');

    final response = stdin.readLineSync();
    if (response?.toLowerCase() == 'y') {
      print('🗑️  Suppression de l\'ancienne collection...');
      await _deleteCollection(firestore, 'products');
      print('✅ Collection supprimée\n');
    } else {
      print('ℹ️  Les nouveaux produits seront ajoutés à la collection existante\n');
    }
  }

  // Uploader les produits par batch de 500
  const batchSize = 500;
  var uploadedCount = 0;
  var errorCount = 0;

  print('📤 Upload des produits dans Firebase...');
  print('   Batch size: $batchSize produits par batch\n');

  for (var i = 0; i < products.length; i += batchSize) {
    final batch = firestore.batch();
    final endIndex = (i + batchSize < products.length) ? i + batchSize : products.length;
    final currentBatch = products.sublist(i, endIndex);

    print('📦 Batch ${(i ~/ batchSize) + 1}: Produits ${i + 1} à $endIndex...');

    for (var product in currentBatch) {
      try {
        final productData = product as Map<String, dynamic>;

        // Créer un document avec l'ID du produit comme nom de document
        final docRef = firestore.collection('products').doc(productData['id'].toString());

        // Préparer les données (retirer l'ID car il sera dans le document ID)
        final data = Map<String, dynamic>.from(productData);
        data.remove('id'); // Pas besoin de stocker l'ID dans le document

        // Assurer que les arrays sont bien des arrays
        if (data['tags'] == null) data['tags'] = [];
        if (data['categories'] == null) data['categories'] = [];

        batch.set(docRef, data);
        uploadedCount++;
      } catch (e) {
        print('   ⚠️  Erreur produit ${product['id']}: $e');
        errorCount++;
      }
    }

    // Commit le batch
    try {
      await batch.commit();
      print('   ✅ Batch ${(i ~/ batchSize) + 1} uploadé (${currentBatch.length} produits)');

      // Petit délai pour éviter de surcharger Firebase
      if (endIndex < products.length) {
        await Future.delayed(Duration(milliseconds: 500));
      }
    } catch (e) {
      print('   ❌ Erreur upload batch ${(i ~/ batchSize) + 1}: $e');
      errorCount += currentBatch.length;
    }
  }

  print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('✅ UPLOAD TERMINÉ!');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📊 Statistiques:');
  print('   - Produits uploadés: $uploadedCount');
  print('   - Erreurs: $errorCount');
  print('   - Total: ${products.length} produits');

  // Vérification finale
  print('\n🔍 Vérification finale...');
  final finalSnapshot = await firestore.collection('products').count().get();
  print('   Collection "products" contient: ${finalSnapshot.count} documents');

  // Tester une query avec filtre sexe
  print('\n🧪 Test de requête avec filtre sexe...');
  final maleQuery = await firestore
      .collection('products')
      .where('tags', arrayContains: 'homme')
      .limit(10)
      .get();
  print('   - Produits avec tag "homme": ${maleQuery.docs.length} trouvés');

  final femaleQuery = await firestore
      .collection('products')
      .where('tags', arrayContains: 'femme')
      .limit(10)
      .get();
  print('   - Produits avec tag "femme": ${femaleQuery.docs.length} trouvés');

  if (maleQuery.docs.isEmpty && femaleQuery.docs.isEmpty) {
    print('\n⚠️  ATTENTION: Aucun produit trouvé avec tags "homme" ou "femme"!');
    print('   Les tags dans le JSON sont peut-être différents.');
    print('   Vérifiez les tags dans le premier produit:');

    final firstDoc = await firestore.collection('products').limit(1).get();
    if (firstDoc.docs.isNotEmpty) {
      print('   Tags: ${firstDoc.docs.first.data()['tags']}');
    }
  }

  print('\n✨ Firebase est maintenant peuplé avec ${uploadedCount} produits!');
  print('   L\'app devrait maintenant afficher des produits variés.\n');
}

/// Supprime tous les documents d'une collection (par batch de 500)
Future<void> _deleteCollection(FirebaseFirestore firestore, String collectionPath) async {
  final collectionRef = firestore.collection(collectionPath);

  while (true) {
    final snapshot = await collectionRef.limit(500).get();
    if (snapshot.docs.isEmpty) break;

    final batch = firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    print('   Supprimés: ${snapshot.docs.length} documents...');
    await Future.delayed(Duration(milliseconds: 500));
  }
}
