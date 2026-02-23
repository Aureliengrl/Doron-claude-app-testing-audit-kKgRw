import '/utils/app_logger.dart';
import 'package:flutter/material.dart';
import '/services/firebase_data_service.dart';
import '/services/product_matching_service.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Page d'administration pour gérer les produits Firebase
/// Permet de supprimer et re-uploader les produits directement depuis l'app
class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  static String routeName = 'AdminProducts';
  static String routePath = '/admin-products';

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String _statusMessage = '';
  List<String> _logs = [];
  int _progress = 0;
  int _total = 0;

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
      _statusMessage = message;
    });
    AppLogger.debug(message, 'Debug');
  }

  /// Supprime tous les produits de Firebase
  Future<void> _deleteAllProducts() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
      _progress = 0;
      _total = 0;
    });

    _addLog('🗑️  Suppression de tous les produits...');

    try {
      // Compter les produits (collection gifts)
      final countQuery = await _firestore.collection('gifts').count().get();
      final totalCount = countQuery.count ?? 0;

      if (totalCount == 0) {
        _addLog('✅ Aucun produit à supprimer');
        setState(() => _isLoading = false);
        return;
      }

      _addLog('Produits à supprimer: $totalCount');
      setState(() => _total = totalCount);

      int deletedCount = 0;
      const batchSize = 500;

      while (true) {
        // Récupérer un batch (collection gifts)
        final snapshot = await _firestore
            .collection('gifts')
            .limit(batchSize)
            .get();

        if (snapshot.docs.isEmpty) break;

        // Créer un batch de suppression
        final batch = _firestore.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        // Commit
        await batch.commit();
        deletedCount += snapshot.docs.length;

        setState(() => _progress = deletedCount);
        _addLog('✅ $deletedCount/$totalCount produits supprimés...');

        // Petit délai
        await Future.delayed(const Duration(milliseconds: 200));
      }

      _addLog('✅ SUPPRESSION TERMINÉE! $deletedCount produits supprimés');
    } catch (e) {
      _addLog('❌ Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Upload tous les produits depuis fallback_products.json
  Future<void> _uploadAllProducts() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
      _progress = 0;
      _total = 0;
    });

    _addLog('🚀 Démarrage de l\'upload des produits...');

    try {
      // Lire le fichier JSON
      _addLog('📖 Lecture du fichier...');
      final jsonString = await rootBundle.loadString('assets/jsons/fallback_products.json');
      final List<dynamic> products = json.decode(jsonString);

      _addLog('✅ ${products.length} produits chargés');
      setState(() => _total = products.length);

      // Upload par batch
      const batchSize = 500;
      int uploadedCount = 0;
      int errorCount = 0;

      _addLog('📤 Upload des produits (batch size: $batchSize)...');

      for (int i = 0; i < products.length; i += batchSize) {
        final batch = _firestore.batch();
        final endIndex = (i + batchSize < products.length) ? i + batchSize : products.length;
        final currentBatch = products.sublist(i, endIndex);

        _addLog('📦 Batch ${(i ~/ batchSize) + 1}: Produits ${i + 1} à $endIndex...');

        for (var product in currentBatch) {
          try {
            final productMap = product as Map<String, dynamic>;
            final docRef = _firestore.collection('gifts').doc(productMap['id'].toString());

            // Retirer l'ID du map (il sera dans le document ID)
            final data = Map<String, dynamic>.from(productMap);
            data.remove('id');

            // Assurer que les arrays sont corrects
            if (!data.containsKey('tags')) data['tags'] = [];
            if (!data.containsKey('categories')) data['categories'] = [];

            batch.set(docRef, data);
            uploadedCount++;
          } catch (e) {
            _addLog('⚠️  Erreur produit ${product['id']}: $e');
            errorCount++;
          }
        }

        // Commit le batch
        try {
          await batch.commit();
          setState(() => _progress = uploadedCount);
          _addLog('✅ Batch ${(i ~/ batchSize) + 1} uploadé (${currentBatch.length} produits)');

          // Délai pour éviter de surcharger Firebase
          if (endIndex < products.length) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } catch (e) {
          _addLog('❌ Erreur upload batch ${(i ~/ batchSize) + 1}: $e');
          errorCount += currentBatch.length;
        }
      }

      _addLog('✅ UPLOAD TERMINÉ!');
      _addLog('📊 Produits uploadés: $uploadedCount');
      _addLog('📊 Erreurs: $errorCount');

      // Vérification finale
      _addLog('🔍 Vérification finale...');
      final finalCount = await _firestore.collection('products').count().get();
      _addLog('✅ Collection "products" contient: ${finalCount.count} documents');

      _addLog('✨ Firebase est maintenant peuplé!');
    } catch (e) {
      _addLog('❌ Erreur fatale: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// NETTOIE la base en supprimant SEULEMENT les produits incomplets
  Future<void> _cleanIncompleteProducts() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
      _progress = 0;
      _total = 0;
    });

    _addLog('🧹 NETTOYAGE DE LA BASE');
    _addLog('Suppression des produits incomplets...');

    try {
      // Récupérer TOUS les produits
      final snapshot = await _firestore.collection('gifts').get();
      final totalCount = snapshot.docs.length;

      if (totalCount == 0) {
        _addLog('✅ Aucun produit dans la base');
        setState(() => _isLoading = false);
        return;
      }

      _addLog('📊 Total de produits: $totalCount');
      _addLog('🔍 Analyse en cours...');

      setState(() => _total = totalCount);

      List<DocumentReference> toDelete = [];
      int completeCount = 0;

      // Analyser chaque produit
      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Vérifier si le produit est complet
        final name = data['name'] ?? data['product_title'] ?? '';
        final brand = data['brand'] ?? '';
        final price = data['price'] ?? 0;
        final image = data['image'] ?? data['product_photo'] ?? '';
        final url = data['url'] ?? data['product_url'] ?? '';

        bool isIncomplete = false;
        List<String> issues = [];

        // Nom invalide
        if (name.toString().trim().isEmpty ||
            name == 'Juste une petite vérification' ||
            name == 'Invalid URL' ||
            name == 'www.backmarket.fr') {
          issues.add('nom');
          isIncomplete = true;
        }

        // Marque invalide
        if (brand.toString().trim().isEmpty || brand == 'Unknown') {
          issues.add('marque');
          isIncomplete = true;
        }

        // Prix invalide
        if (price == 0 || price == null) {
          issues.add('prix');
          isIncomplete = true;
        }

        // Image manquante
        if (image.toString().trim().isEmpty || image == 'N/A') {
          issues.add('image');
          isIncomplete = true;
        }

        // URL manquante
        if (url.toString().trim().isEmpty) {
          issues.add('url');
          isIncomplete = true;
        }

        if (isIncomplete) {
          toDelete.add(doc.reference);
          _addLog('❌ [${doc.id}] $name (manque: ${issues.join(', ')})');
        } else {
          completeCount++;
          _addLog('✅ [${doc.id}] $name');
        }
      }

      final incompleteCount = toDelete.length;

      _addLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _addLog('📊 RÉSUMÉ');
      _addLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _addLog('Total:        $totalCount');
      _addLog('✅ Complets:  $completeCount (${(completeCount/totalCount*100).toStringAsFixed(1)}%)');
      _addLog('❌ Incomplets: $incompleteCount (${(incompleteCount/totalCount*100).toStringAsFixed(1)}%)');
      _addLog('');

      if (incompleteCount == 0) {
        _addLog('✨ Ta base est déjà propre!');
        setState(() => _isLoading = false);
        return;
      }

      _addLog('🗑️  Suppression des $incompleteCount produits incomplets...');

      // Supprimer par batch de 500
      const batchSize = 500;
      int deletedCount = 0;

      for (int i = 0; i < toDelete.length; i += batchSize) {
        final batch = _firestore.batch();
        final endIndex = (i + batchSize < toDelete.length) ? i + batchSize : toDelete.length;

        for (int j = i; j < endIndex; j++) {
          batch.delete(toDelete[j]);
        }

        await batch.commit();
        deletedCount = endIndex;

        setState(() => _progress = deletedCount);
        _addLog('✅ $deletedCount/$incompleteCount supprimés...');

        if (deletedCount < incompleteCount) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      _addLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _addLog('✅ NETTOYAGE TERMINÉ!');
      _addLog('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _addLog('Supprimés:  $deletedCount');
      _addLog('Restants:   $completeCount');
      _addLog('');
      _addLog('✨ Ta base est maintenant propre!');
    } catch (e) {
      _addLog('❌ Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Supprime ET re-upload (option recommandée)
  Future<void> _deleteAndReupload() async {
    await _deleteAllProducts();
    await Future.delayed(const Duration(seconds: 2));
    await _uploadAllProducts();
  }

  @override
  Widget build(BuildContext context) {
    final violetColor = const Color(0xFF8A2BE2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Gestion Produits'),
        backgroundColor: violetColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titre
            const Text(
              '🔧 Gestion des Produits Firebase',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Utilise cette page pour réparer les images',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Boutons d'action
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _deleteAndReupload,
              icon: const Icon(Icons.refresh),
              label: const Text('🔄 Supprimer et Re-uploader (Recommandé)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: violetColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _deleteAllProducts,
              icon: const Icon(Icons.delete),
              label: const Text('🗑️  Supprimer tous les produits'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _uploadAllProducts,
              icon: const Icon(Icons.upload),
              label: const Text('📤 Uploader les nouveaux produits'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _cleanIncompleteProducts,
              icon: const Icon(Icons.cleaning_services),
              label: const Text('🧹 Nettoyer produits incomplets'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),

            // Progress
            if (_isLoading && _total > 0) ...[
              LinearProgressIndicator(
                value: _progress / _total,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(violetColor),
              ),
              const SizedBox(height: 8),
              Text(
                '$_progress / $_total',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],

            // Status
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Logs
            const Text(
              'Logs:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        _logs[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
