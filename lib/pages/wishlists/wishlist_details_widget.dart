import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/services/firebase_data_service.dart';
import '/services/wishlist_sharing_service.dart';
import '/services/gift_reservation_service.dart';
import '/services/event_reminder_service.dart';
import '/components/liquid_glass.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '/components/product_detail_modal.dart';
import '/components/wishlist_picker_sheet.dart';
import 'package:flutter/services.dart';
import '/components/shared_product_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistDetailsWidget extends StatefulWidget {
  final String wishlistId;
  const WishlistDetailsWidget({Key? key, required this.wishlistId}) : super(key: key);

  static String routeName = 'WishlistDetails';
  static String routePath = '/wishlist-details/:wishlistId';

  @override
  State<WishlistDetailsWidget> createState() => _WishlistDetailsWidgetState();
}

class _WishlistDetailsWidgetState extends State<WishlistDetailsWidget> {
  Map<String, dynamic>? _wishlistData;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  Map<String, String> _reservations = {}; // productId → reservedByUid
  bool _isOwner = true;

  final Color violetColor = const Color(0xFF8A2BE2);
  final Color pinkColor = const Color(0xFFEC4899);

  @override
  void initState() {
    super.initState();
    _loadWishlistData();
  }

  Future<void> _loadWishlistData() async {
    setState(() => _isLoading = true);
    
    // Fetch wishlist metadata (if available, else fallback)
    final allWishlists = await FirebaseDataService.loadWishlists();
    final match = allWishlists.where((w) => w['id'] == widget.wishlistId).toList();
    
    if (match.isNotEmpty) {
      _wishlistData = match.first;
    } else {
      _wishlistData = {'name': 'Wishlist Publique', 'isPublic': true};
    }

    final products = await FirebaseDataService.loadWishlistProducts(widget.wishlistId);
    
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  Future<void> _removeProduct(String productId) async {
    final success = await FirebaseDataService.removeProductFromWishlist(widget.wishlistId, productId);
    if (success) {
      setState(() {
        _products.removeWhere((p) => p['product_id'] == productId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produit retiré', style: GoogleFonts.poppins()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ─── Partage par lien ──────────────────────────────────────────────────────
  Future<void> _shareWishlist() async {
    try {
      HapticFeedback.mediumImpact();
      final url = await WishlistSharingService.getShareUrl(widget.wishlistId);
      await Share.share(
        'Voici ma wishlist "${_wishlistData?['name'] ?? 'Wishlist'}" sur Doron :\n$url',
        subject: 'Ma wishlist Doron',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de partage', style: GoogleFonts.poppins()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ─── Date d'événement ───────────────────────────────────────────────────────
  Future<void> _setEventDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: violetColor,
              surface: const Color(0xFF1A0030),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;

    final labelController = TextEditingController();
    if (!mounted) return;
    final label = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0030),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Nom de l\'événement',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: labelController,
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Ex: Anniversaire de Papa',
            hintStyle: GoogleFonts.poppins(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: violetColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('Annuler', style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, labelController.text),
            child: Text('OK', style: GoogleFonts.poppins(color: violetColor)),
          ),
        ],
      ),
    );
    labelController.dispose();
    if (label == null) return;

    await EventReminderService.setEventDate(
      wishlistId: widget.wishlistId,
      eventDate: picked,
      eventLabel: label.isNotEmpty ? label : null,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Rappel programmé pour le ${picked.day}/${picked.month}/${picked.year}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: violetColor,
        ),
      );
    }
  }

  // ─── Réservation de cadeau ─────────────────────────────────────────────────
  Future<void> _toggleReservation(String productId) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    final ownerUid = _wishlistData?['ownerUid'] as String? ?? myUid;

    if (_reservations.containsKey(productId)) {
      if (_reservations[productId] == myUid) {
        final success = await GiftReservationService.cancelReservation(
          wishlistId: widget.wishlistId,
          productId: productId,
        );
        if (success && mounted) {
          setState(() => _reservations.remove(productId));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Réservation annulée', style: GoogleFonts.poppins()),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Déjà réservé par quelqu\'un d\'autre',
                  style: GoogleFonts.poppins()),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } else {
      final success = await GiftReservationService.reserveGift(
        ownerUid: ownerUid,
        wishlistId: widget.wishlistId,
        productId: productId,
      );
      if (success && mounted) {
        setState(() => _reservations[productId] = myUid);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cadeau réservé ! Le propriétaire ne verra pas.',
                style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading ? _buildLoading() : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                LiquidGlassTokens.primary.withOpacity(0.50),
                LiquidGlassTokens.secondary.withOpacity(0.35),
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            border: const Border(
              bottom: BorderSide(color: Color(0x44FFFFFF), width: 1.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _wishlistData?['name'] ?? 'Chargement...',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Partager
                    IconButton(
                      onPressed: _shareWishlist,
                      icon: const Icon(Icons.share_rounded, color: Colors.white, size: 22),
                      tooltip: 'Partager',
                    ),
                    // Date d'événement
                    IconButton(
                      onPressed: _setEventDate,
                      icon: const Icon(Icons.event_rounded, color: Colors.white, size: 22),
                      tooltip: 'Ajouter une date',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 56),
                  child: Text(
                    '${_products.length} produit${_products.length > 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(
        color: violetColor,
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildContent() {
    if (_products.isEmpty) {
      return Center(
        child: Text(
          'Cette wishlist est vide.',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final docData = _products[index];
        final productId = docData['id'] as String? ?? '';

        // Normaliser depuis FavouritesRecord ou Map plat
        final nested = docData['product'] as Map<String, dynamic>? ?? {};
        final normalizedProduct = {
          'id': productId,
          'name': nested['product_title'] ?? docData['name'] ?? docData['product_name'] ?? 'Inconnu',
          'brand': nested['platform'] ?? docData['brand'] ?? docData['source'] ?? '',
          'image': nested['product_photo'] ?? docData['image'] ?? docData['image_url'] ?? '',
          'price': nested['product_price'] ?? docData['price']?.toString() ?? '',
          'url': nested['product_url'] ?? docData['product_url'] ?? docData['url'] ?? '',
        };

        return SharedProductCard(
          product: normalizedProduct,
          index: index,
          showWishlistButton: true,
          onRemove: productId.isNotEmpty ? () => _removeProduct(productId) : null,
        );
      },
    );
  }
}
