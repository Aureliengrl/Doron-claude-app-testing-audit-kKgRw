import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/services/firebase_data_service.dart';
import '/services/product_url_service.dart';
import '/components/cached_image.dart';
import '/components/connection_required_dialog.dart';
import '/utils/app_logger.dart';


class GlobalProductDetailModal {
  static final Color violetColor = const Color(0xFF8A2BE2);

  /// Affiche le modal de détails du produit de manière unifiée
  static void show(BuildContext context, Map<String, dynamic> product, {bool initialIsLiked = false, Function()? onLikeToggled}) {
    bool isLiked = initialIsLiked;

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
                              _showProductActionsSheet(context, product);
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
                                Icons.more_vert,
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
                                Icons.bookmark_border,
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
                                isLiked ? Icons.favorite : Icons.favorite_border,
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
                        Text(
                          '${product['price'] ?? product['product_price'] ?? 0}€'.replaceAll('€€', '€'),
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: violetColor,
                          ),
                        ),
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
                            'Cadeau parfait par ${product['brand'] as String? ?? product['source'] as String? ?? product['platform'] as String? ?? 'une marque de qualité'}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white60,
                              height: 1.6,
                            ),
                          ),
                        const SizedBox(height: 20),
                        // Bouton Voir sur...
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final url = product['product_url'] ?? product['url'] ?? ProductUrlService.generateProductUrl(product);
                              if (url.isNotEmpty) {
                                try {
                                  final uri = Uri.parse(url);
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                } catch (e) {
                                  AppLogger.debug('? Erreur ouverture URL: ${e}', 'Debug');
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: violetColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              shadowColor: violetColor.withOpacity(0.4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Voir sur ${product['brand'] ?? product['source'] ?? product['platform'] ?? 'Amazon'}'.split(' ')[0] == 'Voir' ? 'Voir sur ${product['brand'] ?? product['source'] ?? product['platform'] ?? 'Amazon'}' : 'Voir',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.open_in_new,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
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

  /// Fonction globale de favoris — écrit dans users/{uid}/favorites
  static Future<bool> _toggleFavoriteGlobally(BuildContext context, Map<String, dynamic> product, bool isCurrentlyLiked) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connexion requise pour les favoris.', style: GoogleFonts.poppins()),
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
                    Icon(Icons.bookmark_border, color: violetColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ajouter à une wishlist',
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
                      Icon(Icons.list_alt, size: 60, color: Colors.white24),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune wishlist',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crée ta première wishlist ci-dessous',
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
                            Icons.bookmark,
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
                      'Créer une nouvelle wishlist',
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
              'Annuler',
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
                const Icon(Icons.bookmark, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ajouté à la wishlist !',
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
            content: Text('Erreur lors de l\'ajout à la wishlist', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Affiche le bottom sheet avec les actions produit (envoyer par message, ajouter pour quelqu'un)
  static void _showProductActionsSheet(BuildContext context, Map<String, dynamic> product) {
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
                    Icon(Icons.more_vert, color: violetColor, size: 24),
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
                  child: Icon(Icons.send_rounded, color: violetColor, size: 24),
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
                  'Partager ce produit dans une conversation',
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
                  'Ajouter ce cadeau dans la liste d\'un proche',
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
                    Icon(Icons.send_rounded, color: violetColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Envoyer par message',
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
                              Icon(Icons.chat_bubble_outline, size: 48, color: Colors.white24),
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
        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
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
      trailing: Icon(Icons.send, color: violetColor, size: 20),
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
                        'Ajouter pour quelqu\'un',
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
                              Icon(Icons.person_outline, size: 48, color: Colors.white24),
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
                        final personName = person['name'] as String? ?? person['firstName'] as String? ?? 'Proche';
                        final personEmoji = person['emoji'] as String? ?? person['avatar'] as String?;
                        final personPhoto = person['photoUrl'] as String? ?? person['photo_url'] as String?;

                        return ListTile(
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFEC4899).withOpacity(0.2),
                            backgroundImage: (personPhoto != null && personPhoto.isNotEmpty) ? NetworkImage(personPhoto) : null,
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
