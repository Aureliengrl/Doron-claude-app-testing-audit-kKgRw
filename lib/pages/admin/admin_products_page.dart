import '/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/environment_values.dart';
import '/components/liquid_glass.dart';

/// Page d'administration pour scanner et corriger les produits Firebase.
/// Scanne tous les produits, identifie ceux avec des problèmes
/// (photo manquante, prix incorrect, nom générique, URL cassée)
/// et tente de les corriger automatiquement via l'API Amazon.
class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  static String routeName = 'AdminProducts';
  static String routePath = '/admin-products';

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isLoading = false;
  String _statusMessage = '';
  List<String> _logs = [];
  int _progress = 0;
  int _total = 0;

  // Résultats du scan
  int _noImage = 0;
  int _brokenImage = 0;
  int _noPrice = 0;
  int _noUrl = 0;
  int _noName = 0;
  int _fixed = 0;
  int _unfixable = 0;

  static const _violet = Color(0xFF8A2BE2);

  void _log(String msg) {
    setState(() {
      _logs.add(msg);
      _statusMessage = msg;
    });
  }

  // ─── SCAN : identifie tous les problèmes ────────────────────────────────

  Future<void> _scanProducts() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
      _progress = 0;
      _noImage = 0;
      _brokenImage = 0;
      _noPrice = 0;
      _noUrl = 0;
      _noName = 0;
    });

    _log('Chargement de tous les produits Firebase...');

    try {
      final snapshot = await _db.collection('gifts').get();
      final docs = snapshot.docs;
      setState(() => _total = docs.length);
      _log('${docs.length} produits trouvés. Analyse en cours...');

      for (int i = 0; i < docs.length; i++) {
        final doc = docs[i];
        final data = doc.data();
        final name = (data['name'] ?? data['product_title'] ?? '').toString().trim();
        final image = (data['image'] ?? data['product_photo'] ?? '').toString().trim();
        final price = data['price'];
        final url = (data['url'] ?? data['product_url'] ?? '').toString().trim();
        final brand = (data['brand'] ?? '').toString().trim();

        final issues = <String>[];

        // Image manquante ou Unsplash placeholder
        if (image.isEmpty || image == 'N/A') {
          issues.add('PAS DE PHOTO');
          _noImage++;
        } else if (image.contains('unsplash.com')) {
          issues.add('PHOTO UNSPLASH (fake)');
          _brokenImage++;
        }

        // Prix manquant ou zéro
        if (price == null || price == 0 || price.toString().trim().isEmpty) {
          issues.add('PAS DE PRIX');
          _noPrice++;
        }

        // URL manquante
        if (url.isEmpty || url == '#') {
          issues.add('PAS DE LIEN');
          _noUrl++;
        }

        // Nom générique
        if (name.isEmpty || name.length < 4 || name == 'Produit') {
          issues.add('NOM GENERIQUE');
          _noName++;
        }

        if (issues.isNotEmpty) {
          _log('[${doc.id}] $name ($brand) → ${issues.join(', ')}');
        }

        setState(() => _progress = i + 1);
      }

      final totalIssues = _noImage + _brokenImage + _noPrice + _noUrl + _noName;
      _log('');
      _log('══════════════════════════════════');
      _log('RÉSULTAT DU SCAN');
      _log('══════════════════════════════════');
      _log('Total produits: ${docs.length}');
      _log('Sans photo: $_noImage');
      _log('Photo Unsplash (fake): $_brokenImage');
      _log('Sans prix: $_noPrice');
      _log('Sans lien: $_noUrl');
      _log('Nom générique: $_noName');
      _log('');
      if (totalIssues == 0) {
        _log('Ta base est propre !');
      } else {
        _log('$totalIssues problèmes détectés.');
        _log('Lance "Corriger automatiquement" pour les réparer.');
      }
    } catch (e) {
      _log('ERREUR: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ─── FIX : corrige automatiquement via API Amazon ─────────────────────

  Future<void> _fixProducts() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
      _progress = 0;
      _fixed = 0;
      _unfixable = 0;
    });

    _log('Chargement des produits avec problèmes...');

    try {
      final snapshot = await _db.collection('gifts').get();
      final docs = snapshot.docs;

      // Filtrer les produits avec problèmes
      final problematic = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final doc in docs) {
        final data = doc.data();
        final image = (data['image'] ?? data['product_photo'] ?? '').toString().trim();
        final price = data['price'];
        final url = (data['url'] ?? data['product_url'] ?? '').toString().trim();

        final hasImageIssue = image.isEmpty || image == 'N/A' || image.contains('unsplash.com');
        final hasPriceIssue = price == null || price == 0;
        final hasUrlIssue = url.isEmpty || url == '#';

        if (hasImageIssue || hasPriceIssue || hasUrlIssue) {
          problematic.add(doc);
        }
      }

      setState(() => _total = problematic.length);
      _log('${problematic.length} produits à corriger.');
      _log('');

      final rapidApiKey = FFDevEnvironmentValues().rapidApiKey;
      if (rapidApiKey.isEmpty) {
        _log('ERREUR: Clé RapidAPI manquante dans environment.json');
        _log('Ajoute "rapidApiKey" dans assets/environment_values/environment.json');
        setState(() => _isLoading = false);
        return;
      }

      // Traiter chaque produit
      for (int i = 0; i < problematic.length; i++) {
        final doc = problematic[i];
        final data = doc.data();
        final name = (data['name'] ?? data['product_title'] ?? '').toString().trim();
        final brand = (data['brand'] ?? '').toString().trim();
        final image = (data['image'] ?? '').toString().trim();

        _log('[${ i + 1}/${problematic.length}] $name ($brand)...');

        final updates = <String, dynamic>{};

        try {
          // Chercher sur Amazon pour obtenir image + prix + URL
          final searchQuery = '$brand $name'.trim();
          final amazonResult = await _searchAmazon(searchQuery, rapidApiKey);

          if (amazonResult != null) {
            // Image
            if (image.isEmpty || image.contains('unsplash.com') || image == 'N/A') {
              final newImage = amazonResult['image'] ?? '';
              if (newImage.isNotEmpty) {
                updates['image'] = newImage;
                updates['product_photo'] = newImage;
                _log('  + Photo trouvée');
              }
            }

            // Prix
            final currentPrice = data['price'];
            if (currentPrice == null || currentPrice == 0) {
              final newPrice = amazonResult['price'];
              if (newPrice != null) {
                updates['price'] = newPrice;
                updates['product_price'] = newPrice.toString();
                _log('  + Prix trouvé: ${newPrice}€');
              }
            }

            // URL
            final currentUrl = (data['url'] ?? '').toString();
            if (currentUrl.isEmpty || currentUrl == '#') {
              final newUrl = amazonResult['url'] ?? '';
              if (newUrl.isNotEmpty) {
                updates['url'] = newUrl;
                updates['product_url'] = newUrl;
                _log('  + Lien trouvé');
              }
            }
          }

          if (updates.isNotEmpty) {
            updates['lastFixed'] = FieldValue.serverTimestamp();
            updates['hasIssues'] = false;
            await doc.reference.update(updates);
            _fixed++;
            _log('  CORRIGÉ (${updates.length} champs)');
          } else {
            _unfixable++;
            _log('  Aucune correction trouvée sur Amazon');
          }
        } catch (e) {
          _unfixable++;
          _log('  ERREUR: $e');
        }

        setState(() => _progress = i + 1);

        // Délai entre chaque requête pour respecter les rate limits
        await Future.delayed(const Duration(milliseconds: 500));
      }

      _log('');
      _log('══════════════════════════════════');
      _log('CORRECTION TERMINÉE');
      _log('══════════════════════════════════');
      _log('Corrigés: $_fixed');
      _log('Non corrigés: $_unfixable');
    } catch (e) {
      _log('ERREUR: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Cherche un produit sur Amazon via RapidAPI et retourne image + prix + URL.
  Future<Map<String, dynamic>?> _searchAmazon(String query, String apiKey) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final uri = Uri.parse(
        'https://real-time-amazon-data.p.rapidapi.com/search?query=$encodedQuery&country=fr&page=1',
      );

      final response = await http.get(uri, headers: {
        'x-rapidapi-host': 'real-time-amazon-data.p.rapidapi.com',
        'x-rapidapi-key': apiKey,
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final body = json.decode(response.body);
      final products = body['data']?['products'] as List?;
      if (products == null || products.isEmpty) return null;

      // Prendre le premier résultat
      final first = products[0] as Map<String, dynamic>;

      // Extraire le prix
      double? price;
      final priceStr = first['product_price'] as String?;
      if (priceStr != null) {
        final numMatch = RegExp(r'[\d]+[.,]?\d*').firstMatch(priceStr.replaceAll(',', '.'));
        if (numMatch != null) {
          price = double.tryParse(numMatch.group(0)!);
        }
      }

      return {
        'image': first['product_photo'] as String? ?? '',
        'price': price,
        'url': first['product_url'] as String? ?? '',
        'title': first['product_title'] as String? ?? '',
      };
    } catch (e) {
      AppLogger.debug('Amazon search error for "$query": $e', 'Admin');
      return null;
    }
  }

  // ─── SUPPRIMER les produits sans photo (non réparables) ─────────────────

  Future<void> _deleteProductsWithoutImage() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
      _progress = 0;
    });

    _log('Recherche des produits sans photo...');

    try {
      final snapshot = await _db.collection('gifts').get();
      final toDelete = <DocumentReference>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final image = (data['image'] ?? data['product_photo'] ?? '').toString().trim();
        if (image.isEmpty || image == 'N/A' || image.contains('unsplash.com')) {
          toDelete.add(doc.reference);
          final name = data['name'] ?? 'Inconnu';
          _log('Suppression: $name');
        }
      }

      setState(() => _total = toDelete.length);
      _log('${toDelete.length} produits sans photo à supprimer.');

      if (toDelete.isEmpty) {
        _log('Rien à supprimer !');
        setState(() => _isLoading = false);
        return;
      }

      // Batch delete
      for (int i = 0; i < toDelete.length; i += 500) {
        final batch = _db.batch();
        final end = (i + 500 < toDelete.length) ? i + 500 : toDelete.length;
        for (int j = i; j < end; j++) {
          batch.delete(toDelete[j]);
        }
        await batch.commit();
        setState(() => _progress = end);
        _log('$end/${toDelete.length} supprimés...');
      }

      _log('Suppression terminée !');
    } catch (e) {
      _log('ERREUR: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      appBar: AppBar(
        title: Text('Admin Produits', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: _violet,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Gestion des produits Firebase',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Scanne, corrige et nettoie tes produits',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Boutons
            _buildButton(
              label: 'Scanner tous les produits',
              icon: IconlyBold.search,
              color: _violet,
              onTap: _isLoading ? null : _scanProducts,
            ),
            const SizedBox(height: 10),
            _buildButton(
              label: 'Corriger automatiquement (API Amazon)',
              icon: IconlyLight.activity,
              color: const Color(0xFF10B981),
              onTap: _isLoading ? null : _fixProducts,
            ),
            const SizedBox(height: 10),
            _buildButton(
              label: 'Supprimer les produits sans photo',
              icon: IconlyBold.delete,
              color: Colors.red,
              onTap: _isLoading ? null : _deleteProductsWithoutImage,
            ),
            const SizedBox(height: 20),

            // Progress
            if (_isLoading && _total > 0) ...[
              LinearProgressIndicator(
                value: _total > 0 ? _progress / _total : 0,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(_violet),
              ),
              const SizedBox(height: 6),
              Text(
                '$_progress / $_total',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],

            if (_isLoading && _total == 0)
              const Center(child: CircularProgressIndicator(color: _violet)),

            // Logs
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      _logs[i],
                      style: GoogleFonts.poppins(
                        color: _logs[i].contains('ERREUR')
                            ? Colors.red
                            : _logs[i].contains('CORRIGÉ') || _logs[i].contains('trouvé')
                                ? const Color(0xFF10B981)
                                : _logs[i].contains('══')
                                    ? Colors.white
                                    : Colors.white70,
                        fontSize: 11,
                        fontWeight: _logs[i].contains('══') ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: onTap == null ? color.withOpacity(0.2) : color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            )),
          ],
        ),
      ),
    );
  }
}
