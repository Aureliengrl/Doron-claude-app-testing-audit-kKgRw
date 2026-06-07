import 'dart:convert';
import 'package:flutter/material.dart';
import '/utils/app_tr.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/services/firebase_data_service.dart';
import '/services/product_url_service.dart';
import '/services/gift_events_service.dart';
import '/components/cached_image.dart';
import '/components/connection_required_dialog.dart';
import '/components/wishlist_picker_sheet.dart';
import '/utils/app_logger.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/services/api/multi_market_service.dart';

class GlobalProductDetailModal {
  static final Color violetColor = const Color(0xFF8A2BE2);

  /// Affiche le modal de détails du produit de manière unifiée
  static void show(BuildContext context, Map<String, dynamic> product, {bool initialIsLiked = false, Function()? onLikeToggled}) {
    bool isLiked = initialIsLiked;

    // Synchronisation "lazy" silencieuse du prix (si c'est un produit issu de Rakuten)
    if (product['source'] != null) {
      MultiMarketService().refreshProductPrice(product).then((freshData) {
        if (freshData != null && freshData['price'] != product['price']) {
          AppLogger.debug('💰 Prix mis à jour silencieusement (Background): ${freshData['price']}', 'PriceSync');
          product['price'] = freshData['price']; // Met à jour l'objet en mémoire
        }
      });
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.10),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 60,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image avec boutons
                  Stack(
                    children: [
                      ProductImage(
                        imageUrl: product['image'] as String? ?? product['product_photo'] as String? ?? product['image_url'] as String? ?? '',
                        height: 350,
                        fit: BoxFit.contain,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        backgroundColor: Colors.white.withOpacity(0.05),
                      ),
                      // Bouton fermer
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFF111827),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Bouton 3-dot menu
                      Positioned(
                        top: 12,
                        right: 116,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              showProductActionsSheet(context, product);
                            },
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                IconlyLight.moreCircle,
                                color: violetColor,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Bouton wishlist
                      Positioned(
                        top: 12,
                        right: 64,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              // Ne pas fermer le modal — ouvrir le wishlist picker par-dessus
                              _showWishlistModal(context, product);
                            },
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                IconlyLight.bookmark,
                                color: violetColor,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Bouton coeur
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              final success = await _toggleFavoriteGlobally(context, product, isLiked);
                              if (success) {
                                setDialogState(() {
                                  isLiked = !isLiked;
                                });
                                if (onLikeToggled != null) onLikeToggled();
                              }
                            },
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isLiked ? Colors.red : Colors.white.withOpacity(0.95),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isLiked ? IconlyBold.heart : IconlyLight.heart,
                                color: isLiked ? Colors.white : const Color(0xFF111827),
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Détails du produit
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: violetColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            product['brand'] as String? ?? product['source'] as String? ?? product['platform'] as String? ?? 'Amazon',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: violetColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          product['name'] as String? ?? product['product_title'] as String? ?? product['product_name'] as String? ?? 'Produit',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // #FIX-2: masquer prix si 0 ou null
                        Builder(builder: (_) {
                          final _priceRaw = product['price'] ?? product['product_price'];
                          final _priceStr = _priceRaw?.toString().replaceAll('\u20ac', '').trim() ?? '';
                          final _isBlank = _priceStr.isEmpty || _priceStr == '0' || _priceStr == '0.0';
                          return Text(
                            _isBlank ? context.tr('Prix non renseigné', 'Price not listed') : '${_priceStr}€',
                            style: GoogleFonts.poppins(
                              fontSize: _isBlank ? 16 : 32,
                              fontWeight: FontWeight.bold,
                              color: _isBlank ? Colors.white38 : violetColor,
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        if (product['description'] != null && (product['description'] as String).isNotEmpty)
                          Text(
                            product['description'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white60,
                              height: 1.6,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          Text(
                          context.tr('Cadeau parfait par ${product['brand'] as String? ?? product['source'] as String? ?? product['platform'] as String? ?? 'une marque de qualité'}', 'The perfect gift from ${product['brand'] as String? ?? product['source'] as String? ?? product['platform'] as String? ?? 'a quality brand'}'),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white60,
                              height: 1.6,
                            ),
                          ),
                        const SizedBox(height: 20),
                        // ── Comparateur de prix / Liens d'achat ──────────
                        _buildBuyLinksSection(context, product),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  // ─── Site colors & icons ────────────────────────────────────────────────────
  static Color _siteColor(String site) {
    final s = site.toLowerCase();
    if (s.contains('amazon')) return const Color(0xFFFF9900);
    if (s.contains('fnac'))   return const Color(0xFFFFCC00);
    if (s.contains('darty'))  return const Color(0xFFE30613);
    if (s.contains('cdiscount')) return const Color(0xFF0070C0);
    if (s.contains('zalando')) return const Color(0xFFFF6600);
    if (s.contains('la redoute')) return const Color(0xFFE91E63);
    if (s.contains('galeries')) return const Color(0xFF1A237E);
    if (s.contains('sephora')) return const Color(0xFF000000);
    if (s.contains('boulanger')) return const Color(0xFF003DA5);
    if (s.contains('decathlon')) return const Color(0xFF007DBA);
    if (s.contains('monoprix')) return const Color(0xFFE30613);
    return const Color(0xFF6B7280);
  }

  static String _siteEmoji(String site) {
    final s = site.toLowerCase();
    if (s.contains('amazon'))   return '🟠';
    if (s.contains('fnac'))     return '🟡';
    if (s.contains('darty'))    return '🔴';
    if (s.contains('zalando'))  return '🟧';
    if (s.contains('cdiscount'))return '🔷';
    if (s.contains('sephora'))  return '⚫';
    if (s.contains('boulanger'))return '🔵';
    if (s.contains('decathlon'))return '💙';
    return '🌐';
  }

  /// Mini comparateur de prix — affiche tous les buyLinks[]
  static Widget _buildBuyLinksSection(BuildContext context, Map<String, dynamic> product) {
    // Récupérer buyLinks depuis le produit
    final rawLinks = product['buyLinks'];
    List<Map<String, dynamic>> buyLinks = [];

    if (rawLinks is List && rawLinks.isNotEmpty) {
      buyLinks = rawLinks
          .whereType<Map>()
          .map((l) => Map<String, dynamic>.from(l))
          .toList();
      // Trier : affiliés d'abord, puis par priorité, puis par prix
      buyLinks.sort((a, b) {
        final aAff = a['affiliated'] == true ? 0 : 1;
        final bAff = b['affiliated'] == true ? 0 : 1;
        if (aAff != bAff) return aAff - bAff;
        final aPrio = (a['priority'] as num?)?.toInt() ?? 99;
        final bPrio = (b['priority'] as num?)?.toInt() ?? 99;
        if (aPrio != bPrio) return aPrio - bPrio;
        final aPrice = (a['price'] as num?)?.toDouble() ?? 9999;
        final bPrice = (b['price'] as num?)?.toDouble() ?? 9999;
        return aPrice.compareTo(bPrice);
      });
    }

    // Pas de buyLinks → fallback bouton simple
    if (buyLinks.isEmpty) {
      final url = (product['product_url'] ?? product['url'] ?? '').toString();
      final brand = (product['brand'] ?? product['source'] ?? 'Boutique').toString();
      if (url.isEmpty) {
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            context.tr('Aucun lien disponible', 'No link available'),
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white38),
            textAlign: TextAlign.center,
          ),
        );
      }
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            try { await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); } catch (_) {}
          },
          icon: const Icon(Icons.open_in_new, color: Colors.white, size: 18),
          label: Text('Voir sur $brand', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: violetColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
          ),
        ),
      );
    }

    // Trouver le prix min pour le badge
    final prices = buyLinks.map((l) => (l['price'] as num?)?.toDouble()).whereType<double>().toList();
    final priceMin = prices.isNotEmpty ? prices.reduce((a, b) => a < b ? a : b) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
            context.tr('Où acheter', 'Where to buy'),
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            if (priceMin != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                ),
                child: Text(
                  'Dès ${priceMin.toStringAsFixed(priceMin == priceMin.roundToDouble() ? 0 : 2)}€',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        // Liste des liens
        ...buyLinks.take(6).map((link) {
          final site    = (link['site'] as String?) ?? 'Boutique';
          final url     = (link['url'] as String?) ?? '';
          final price   = (link['price'] as num?)?.toDouble();
          final isAffiliated = link['affiliated'] == true;
          final isBest  = price != null && price == priceMin;
          final siteColor = _siteColor(site);
          final emoji = _siteEmoji(site);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: url.isNotEmpty ? () async {
                HapticFeedback.lightImpact();
                try { await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); } catch (_) {}
              } : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: isBest
                      ? const Color(0xFF10B981).withOpacity(0.08)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isBest
                        ? const Color(0xFF10B981).withOpacity(0.4)
                        : Colors.white.withOpacity(0.08),
                    width: isBest ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Emoji site
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    // Nom du site
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                site,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              if (isBest) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    context.tr('Meilleur prix', 'Best price'),
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                              if (isAffiliated) ...[
                                const SizedBox(width: 4),
                                const Text('💰', style: TextStyle(fontSize: 10)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Prix
                    if (price != null)
                      Text(
                        '${price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2)}€',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isBest ? const Color(0xFF10B981) : Colors.white,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.white38,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 4),
      ],
    );
  }

  /// Fonction globale de favoris — écrit dans users/{uid}/favorites
  static Future<bool> _toggleFavoriteGlobally(BuildContext context, Map<String, dynamic> product, bool isCurrentlyLiked) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Connexion requise pour les favoris.', 'Sign in to save favourites.'), style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    try {
      final uid = user.uid;
      final favCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('favorites');

      final productTitle = product['name'] as String? ?? product['product_title'] as String? ?? 'Produit';
      final productImage = product['image'] as String? ?? product['product_photo'] as String? ?? product['image_url'] as String? ?? '';
      final productUrl = product['product_url'] ?? product['url'] ?? ProductUrlService.generateProductUrl(product);
      final brandOrSource = product['brand'] ?? product['source'] ?? product['platform'] ?? 'Amazon';
      final price = '${product['price'] ?? product['product_price'] ?? 0}'.replaceAll('€', '').trim();

      if (isCurrentlyLiked) {
        // Supprimer : chercher par name
        final snap = await favCollection
            .where('name', isEqualTo: productTitle)
            .limit(5)
            .get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
      } else {
        // Ajouter
        final docId = 'fav_${DateTime.now().millisecondsSinceEpoch}';
        await favCollection.doc(docId).set({
          'id': docId,
          'name': productTitle,
          'brand': brandOrSource.toString(),
          'price': price,
          'image': productImage,
          'url': productUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return true;
    } catch (e) {
      AppLogger.error('Erreur favoris global', 'Debug', e);
      return false;
    }
  }

  /// Affiche le modal de sélection de wishlist
  static Future<void> _showWishlistModal(BuildContext context, Map<String, dynamic> product) async {
    if (FirebaseAuth.instance.currentUser == null) {
      await showConnectionRequiredDialog(
        context,
        title: 'Connexion requise',
        message: 'Crée ton compte pour organiser tes cadeaux en wishlists',
      );
      return;
    }

    final wishlists = await FirebaseDataService.loadWishlists();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(IconlyLight.bookmark, color: violetColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Ajouter à une wishlist', 'Add to a wishlist'),
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            product['name'] as String? ?? product['product_title'] as String? ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (wishlists.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(IconlyLight.document, size: 60, color: Colors.white24),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('Aucune wishlist', 'No wishlists'),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('Crée ta première wishlist ci-dessous', 'Create your first wishlist below'),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: wishlists.length,
                    itemBuilder: (context, index) {
                      final wishlist = wishlists[index];
                      final giftCount = (wishlist['productCount'] as int?) ?? (wishlist['productIds'] as List?)?.length ?? 0;

                      return ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: violetColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            IconlyBold.bookmark,
                            color: violetColor,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          wishlist['name'] as String? ?? 'Wishlist',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          '$giftCount cadeau${giftCount > 1 ? 's' : ''}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white60,
                          ),
                        ),
                        trailing: Icon(
                          Icons.add_circle,
                          color: violetColor,
                          size: 28,
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                          await _addToWishlist(context, product, wishlist['id'] as String);
                        },
                      );
                    },
                  ),
                ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _createNewWishlist(context, product);
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      context.tr('Créer une nouvelle wishlist', 'Create a new wishlist'),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: violetColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _createNewWishlist(BuildContext context, Map<String, dynamic> product) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Nouvelle wishlist',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Nom de la wishlist',
                hintText: 'Ex: Anniversaire Maman',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: violetColor, width: 2),
                ),
              ),
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (optionnel)',
                hintText: 'Ex: Idées cadeaux pour ses 50 ans',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: violetColor, width: 2),
                ),
              ),
              style: GoogleFonts.poppins(),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              context.tr('Annuler', 'Cancel'),
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: violetColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Créer',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final wishlistId = await FirebaseDataService.createWishlist(
        name: nameController.text,
        description: descriptionController.text,
      );

      if (wishlistId != null) {
        await _addToWishlist(context, product, wishlistId);
      }
    }
  }

  static Future<void> _addToWishlist(BuildContext context, Map<String, dynamic> product, String wishlistId) async {
    try {
      // Utilise addProductToWishlist qui écrit dans la sous-collection products/
      // (cohérent avec loadWishlistProducts et WishlistPickerSheet)
      final ok = await FirebaseDataService.addProductToWishlist(wishlistId, product);
      if (!ok) throw Exception('addProductToWishlist returned false');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(IconlyBold.bookmark, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr('Ajouté à la wishlist !', 'Added to wishlist!'),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Erreur ajout wishlist globale', 'Debug', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('Erreur lors de l\'ajout à la wishlist', 'Error adding to wishlist'), style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Expose le chat picker comme méthode publique (utilisée depuis la page Inspiration)
  static void showChatPicker(BuildContext context, Map<String, dynamic> product) {
    _showChatPickerSheet(context, product);
  }

  /// Expose le person picker comme méthode publique (utilisée depuis la page Inspiration)
  static void showPersonPicker(BuildContext context, Map<String, dynamic> product) {
    _showPersonPickerSheet(context, product);
  }

  static void showWishlistPicker(BuildContext context, Map<String, dynamic> product) {
    WishlistPickerSheet.show(context, product);
  }

  /// Affiche le bottom sheet avec les actions produit (envoyer par message, ajouter pour quelqu'un)
  static void showProductActionsSheet(BuildContext context, Map<String, dynamic> product) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showConnectionRequiredDialog(
        context,
        title: 'Connexion requise',
        message: 'Connecte-toi pour partager des produits',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Icon(IconlyLight.moreCircle, color: violetColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Actions',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              // Option 1: Envoyer par message
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: violetColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(IconlyBold.send, color: violetColor, size: 24),
                ),
                title: Text(
                  'Envoyer par message',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  context.tr('Partager ce produit dans une conversation', 'Share this product in a conversation'),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.white38),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showChatPickerSheet(context, product);
                },
              ),
              // Option 2: Ajouter pour quelqu'un
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.card_giftcard, color: Color(0xFFEC4899), size: 24),
                ),
                title: Text(
                  'Ajouter pour quelqu\'un',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  context.tr('Ajouter ce cadeau dans la liste d\'un proche', 'Add this gift to a friend\'s list'),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.white38),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showPersonPickerSheet(context, product);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Affiche la liste des conversations pour envoyer le produit en tant que product_card
  static void _showChatPickerSheet(BuildContext context, Map<String, dynamic> product) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Icon(IconlyBold.send, color: violetColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr('Envoyer par message', 'Send in a message'),
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              // Chat list from Firestore
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .where('participants', arrayContains: user.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF8A2BE2)),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(IconlyLight.chat, size: 48, color: Colors.white24),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune conversation',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final chats = snapshot.data!.docs;
                    chats.sort((a, b) {
                      final timeA = (a.data() as Map<String, dynamic>)['lastMessageTime'] as Timestamp?;
                      final timeB = (b.data() as Map<String, dynamic>)['lastMessageTime'] as Timestamp?;
                      if (timeA == null && timeB == null) return 0;
                      if (timeA == null) return 1;
                      if (timeB == null) return -1;
                      return timeB.compareTo(timeA);
                    });

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chatDoc = chats[index];
                        final chatData = chatDoc.data() as Map<String, dynamic>;
                        final chatId = chatDoc.id;
                        final isGroup = chatData['isGroup'] == true;
                        final chatName = chatData['name'] as String? ?? 'Conversation';

                        if (isGroup) {
                          return _buildChatTile(sheetContext, chatId, chatName, chatData['photoUrl'] as String?, product);
                        }

                        // For 1-on-1 chats, resolve the other user's name
                        final participants = (chatData['participants'] as List?)?.cast<String>() ?? [];
                        final otherUid = participants.firstWhere(
                          (p) => p != user.uid,
                          orElse: () => '',
                        );
                        if (otherUid.isEmpty) {
                          return _buildChatTile(sheetContext, chatId, chatName, null, product);
                        }

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('users').doc(otherUid).get(),
                          builder: (context, userSnap) {
                            final userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
                            final name = userData['first_name'] as String? ??
                                userData['display_name'] as String? ??
                                userData['name'] as String? ??
                                chatName;
                            final photo = userData['photo_url'] as String? ?? userData['photoUrl'] as String?;
                            return _buildChatTile(sheetContext, chatId, name, photo, product);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildChatTile(BuildContext context, String chatId, String name, String? photoUrl, Map<String, dynamic> product) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: violetColor.withOpacity(0.2),
        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? CachedNetworkImageProvider(photoUrl) : null,
        child: (photoUrl == null || photoUrl.isEmpty)
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              )
            : null,
      ),
      title: Text(
        name,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      trailing: Icon(IconlyLight.send, color: violetColor, size: 20),
      onTap: () async {
        Navigator.pop(context);
        await _sendProductToChat(context, chatId, product);
      },
    );
  }

  /// Envoie le produit comme message product_card dans le chat
  static Future<void> _sendProductToChat(BuildContext context, String chatId, Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final productTitle = product['name'] as String? ?? product['product_title'] as String? ?? 'Produit';
      final productImage = product['image'] as String? ?? product['product_photo'] as String? ?? product['image_url'] as String? ?? '';
      final productUrl = product['product_url'] ?? product['url'] ?? ProductUrlService.generateProductUrl(product);
      final brand = product['brand'] ?? product['source'] ?? product['platform'] ?? '';
      final price = '${product['price'] ?? product['product_price'] ?? 0}'.replaceAll('€', '').trim();

      final productCardJson = json.encode({
        'name': productTitle,
        'image_url': productImage,
        'brand': brand.toString(),
        'price': price,
        'url': productUrl,
      });

      final messageRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      await messageRef.set({
        'id': messageRef.id,
        'senderId': user.uid,
        'text': productCardJson,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'product_card',
      });

      await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
        'lastMessage': 'a partagé un produit',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Produit envoyé !',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Erreur envoi produit par message', 'Debug', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Affiche la liste des personnes (proches) pour ajouter le produit à leur liste de cadeaux
  static void _showPersonPickerSheet(BuildContext context, Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard, color: Color(0xFFEC4899), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr('Ajouter pour quelqu\'un', 'Add for someone'),
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              // Person list
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: FirebaseDataService.loadPeople(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF8A2BE2)),
                      );
                    }
                    final people = snapshot.data ?? [];
                    if (people.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(IconlyLight.profile, size: 48, color: Colors.white24),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun proche',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ajoute des proches dans l\'onglet recherche',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: people.length,
                      itemBuilder: (context, index) {
                        final person = people[index];
                        final personId = person['id'] as String? ?? '';
                        // Chercher le nom dans plusieurs structures possibles (local vs Firebase)
                        final tags = person['tags'] as Map<String, dynamic>? ?? {};
                        final personName = (person['name'] as String?)?.isNotEmpty == true
                            ? person['name'] as String
                            : (tags['name'] as String?)?.isNotEmpty == true
                                ? tags['name'] as String
                                : (tags['personName'] as String?)?.isNotEmpty == true
                                    ? tags['personName'] as String
                                    : (tags['recipient'] as String?)?.isNotEmpty == true
                                        ? tags['recipient'] as String
                                        : (person['firstName'] as String?)?.isNotEmpty == true
                                            ? person['firstName'] as String
                                            : 'Proche';
                        final personEmoji = person['emoji'] as String? ?? person['avatar'] as String? ?? tags['emoji'] as String?;
                        final personPhoto = person['photoUrl'] as String? ?? person['photo_url'] as String?;

                        return ListTile(
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFEC4899).withOpacity(0.2),
                            backgroundImage: (personPhoto != null && personPhoto.isNotEmpty) ? CachedNetworkImageProvider(personPhoto) : null,
                            child: (personPhoto == null || personPhoto.isEmpty)
                                ? Text(
                                    personEmoji ?? (personName.isNotEmpty ? personName[0].toUpperCase() : '?'),
                                    style: GoogleFonts.poppins(
                                      fontSize: personEmoji != null ? 22 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            personName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          trailing: Icon(Icons.add_circle, color: violetColor, size: 28),
                          onTap: () async {
                            Navigator.pop(sheetContext);
                            await _addProductToPerson(context, personId, personName, product);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ajoute le produit à la liste de cadeaux d'une personne
  static Future<void> _addProductToPerson(BuildContext context, String personId, String personName, Map<String, dynamic> product) async {
    if (personId.isEmpty) return;

    try {
      final productTitle = product['name'] as String? ?? product['product_title'] as String? ?? 'Produit';
      final productImage = product['image'] as String? ?? product['product_photo'] as String? ?? product['image_url'] as String? ?? '';
      final productUrl = product['product_url'] ?? product['url'] ?? ProductUrlService.generateProductUrl(product);
      final brand = product['brand'] ?? product['source'] ?? product['platform'] ?? '';
      final price = '${product['price'] ?? product['product_price'] ?? 0}'.replaceAll('€', '').trim();

      final gift = {
        'id': 'gift_${DateTime.now().millisecondsSinceEpoch}',
        'name': productTitle,
        'brand': brand.toString(),
        'price': price,
        'image': productImage,
        'url': productUrl,
        'addedAt': DateTime.now().toIso8601String(),
      };

      final success = await FirebaseDataService.addGiftToPerson(
        personId: personId,
        gift: gift,
      );

      if (success) {
        // Notifie la SearchPage pour qu'elle injecte le cadeau en tête de grille
        GiftEventsService.notifyGiftAdded(personId, gift);
      }

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.card_giftcard, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ajouté pour $personName !',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'ajout', style: GoogleFonts.poppins()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Erreur ajout cadeau pour personne', 'Debug', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
