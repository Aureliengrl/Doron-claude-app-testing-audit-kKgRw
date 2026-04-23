import 'dart:convert';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class WishlistDetailsWidget extends StatefulWidget {
  final String wishlistId;
  /// UID du propriétaire de la wishlist. Si null → c'est la wishlist de l'utilisateur courant.
  final String? ownerUid;
  const WishlistDetailsWidget({Key? key, required this.wishlistId, this.ownerUid}) : super(key: key);

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

  /// true si la wishlist appartient à l'utilisateur courant
  bool get _isOwner {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return false;
    if (widget.ownerUid == null) return true;
    return widget.ownerUid == myUid;
  }

  /// UID effectif du propriétaire (l'ami ou soi-même)
  String? get _effectiveOwnerUid =>
      widget.ownerUid ?? FirebaseAuth.instance.currentUser?.uid;

  /// Fixé à 2 colonnes pour un rendu premium dans les albums
  final int _gridColumns = 2;

  final Color violetColor = const Color(0xFF8A2BE2);
  final Color pinkColor = const Color(0xFFEC4899);

  @override
  void initState() {
    super.initState();
    _loadWishlistData();
  }

  Future<void> _loadWishlistData() async {
    setState(() => _isLoading = true);

    final ownerUid = _effectiveOwnerUid;
    if (ownerUid == null) {
      setState(() => _isLoading = false);
      return;
    }

    if (_isOwner) {
      // Ma propre wishlist : comportement normal via FirebaseDataService (cache local inclus)
      final allWishlists = await FirebaseDataService.loadWishlists();
      final match = allWishlists.where((w) => w['id'] == widget.wishlistId).toList();

      if (match.isNotEmpty) {
        _wishlistData = match.first;
      } else {
        _wishlistData = {'name': 'Wishlist', 'isPublic': true};
      }

      final products = await FirebaseDataService.loadWishlistProducts(widget.wishlistId);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } else {
      // Wishlist d'un ami : lire directement Firestore avec l'UID du propriétaire
      await _loadFriendWishlist(ownerUid);
    }
  }

  /// Charge la wishlist et ses produits pour un ami (ownerUid différent de l'utilisateur courant).
  /// Note: access control is already done by getVisibleWishlists/PublicProfilePage.
  /// Si ownerUid est fourni, l'accès est déjà considéré accordé — on charge toujours les produits.
  Future<void> _loadFriendWishlist(String ownerUid) async {
    try {
      // Metadata de la wishlist
      final wishlistDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerUid)
          .collection('wishlists')
          .doc(widget.wishlistId)
          .get();

      if (!wishlistDoc.exists) {
        _wishlistData = {'name': 'Wishlist', 'isPublic': false};
        setState(() => _isLoading = false);
        return;
      }

      final wData = wishlistDoc.data()!;
      final isPublicFlag = wData['isPublic'] as bool? ?? false;

      // FIX : si ownerUid est fourni explicitement depuis le profil public
      // (via PublicProfilePage → getVisibleWishlists), l'accès est déjà validé.
      // On traite la wishlist comme accessible même si isPublic == false.
      // (un ami a le droit de voir toutes les wishlists selon getVisibleWishlists)
      final bool accessGranted = widget.ownerUid != null;

      _wishlistData = {
        'id': wishlistDoc.id,
        'name': wData['name'] ?? 'Wishlist',
        'emoji': wData['emoji'] ?? '🎁',
        // FIX: si ownerUid fourni → on force isPublic=true pour débloquer _buildContent
        'isPublic': accessGranted ? true : isPublicFlag,
        'coverPhoto': wData['coverPhoto'] ?? '',
        'ownerUid': ownerUid,
      };

      // FIX : charger les produits que la wishlist soit publique ou non
      // (l'accès est garanti car PublicProfilePage a déjà filtré via getVisibleWishlists)
      if (accessGranted || isPublicFlag) {
        try {
          final productsSnap = await FirebaseFirestore.instance
              .collection('users')
              .doc(ownerUid)
              .collection('wishlists')
              .doc(widget.wishlistId)
              .collection('products')
              .orderBy('addedAt', descending: true)
              .get();

          _products = productsSnap.docs
              .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
              .toList();
        } catch (e) {
          // Firestore rules peuvent bloquer si non-ami — fallback silencieux
          _products = [];
        }
      } else {
        _products = [];
      }
    } catch (e) {
      _wishlistData = {'name': 'Wishlist', 'isPublic': false};
      _products = [];
    }

    setState(() => _isLoading = false);
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
                    // Toggle vue 2/3 colonnes
                    IconButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _gridColumns = _gridColumns == 2 ? 3 : 2;
                        });
                      },
                      icon: Icon(
                        _gridColumns == 2
                            ? Icons.grid_view_rounded        // vue 3 col = compact
                            : Icons.view_quilt_rounded,      // vue 2 col = confort
                        color: Colors.white,
                        size: 22,
                      ),
                      tooltip: _gridColumns == 2 ? 'Vue compacte' : 'Vue confortable',
                    ),
                    // Partager — masqué en mode lecture seule
                    if (_isOwner)
                      IconButton(
                        onPressed: _shareWishlist,
                        icon: const Icon(Icons.share_rounded, color: Colors.white, size: 22),
                        tooltip: 'Partager',
                      ),
                    // Date d'événement — masqué en mode lecture seule
                    if (_isOwner)
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

  /// Persiste l'ordre des produits dans Firestore
  Future<void> _saveProductOrder() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      // ── Firebase : écriture du champ 'order' sur chaque produit ──────────
      final batch = FirebaseFirestore.instance.batch();
      for (int i = 0; i < _products.length; i++) {
        final id = _products[i]['id'] as String?;
        if (id != null && id.isNotEmpty) {
          batch.update(
            FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('wishlists')
                .doc(widget.wishlistId)
                .collection('products')
                .doc(id),
            {'order': i},
          );
          // Mettre à jour l'index en mémoire aussi (dédoublonne re-fetch)
          _products[i]['order'] = i;
        }
      }
      await batch.commit();

      // ── Cache local : mise à jour SharedPreferences ────────────────────
      try {
        final prefs = await SharedPreferences.getInstance();
        final serializable = _products.map((p) => {
          ...p,
          'addedAt': (p['addedAt'] is String) ? p['addedAt'] : DateTime.now().toIso8601String(),
        }).toList();
        await prefs.setString('wishlist_products_${widget.wishlistId}', jsonEncode(serializable));
      } catch (_) {}
    } catch (_) {}
  }

  Widget _buildContent() {
    // Wishlist d'un ami privée
    if (!_isOwner && _wishlistData?['isPublic'] != true) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 72, color: Colors.white24),
            const SizedBox(height: 20),
            Text(
              'Liste privée',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cette liste n\'est pas publique.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white30),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Text(
          'Cette wishlist est vide.',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    // Mode lecture seule (wishlist d'un ami) : grille simple sans réordre ni suppression
    if (!_isOwner) {
      return GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 0.60,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
        children: List.generate(_products.length, (index) {
          final docData = _products[index];
          final productId = docData['id'] as String? ?? '';
          final nested = docData['product'] as Map<String, dynamic>? ?? {};
          final normalizedProduct = {
            'id': productId,
            'name': nested['product_title'] ?? docData['name'] ?? docData['product_name'] ?? 'Inconnu',
            'brand': nested['platform'] ?? docData['brand'] ?? docData['source'] ?? '',
            'image': nested['product_photo'] ?? docData['image'] ?? docData['image_url'] ?? '',
            'price': nested['product_price'] ?? docData['price']?.toString() ?? '',
            'url': nested['product_url'] ?? docData['product_url'] ?? docData['url'] ?? '',
          };
          return _WishlistProductCard(
            product: normalizedProduct,
            index: index,
            onRemove: null,
          );
        }),
      );
    }

    return ReorderableGridView.count(
      crossAxisCount: 2,
      childAspectRatio: 0.60,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
      onReorder: (oldIndex, newIndex) {
        HapticFeedback.mediumImpact();
        setState(() {
          final item = _products.removeAt(oldIndex);
          _products.insert(newIndex, item);
        });
        _saveProductOrder();
      },
      children: List.generate(_products.length, (index) {
        final docData = _products[index];
        final productId = docData['id'] as String? ?? '';
        final nested = docData['product'] as Map<String, dynamic>? ?? {};
        final normalizedProduct = {
          'id': productId,
          'name': nested['product_title'] ?? docData['name'] ?? docData['product_name'] ?? 'Inconnu',
          'brand': nested['platform'] ?? docData['brand'] ?? docData['source'] ?? '',
          'image': nested['product_photo'] ?? docData['image'] ?? docData['image_url'] ?? '',
          'price': nested['product_price'] ?? docData['price']?.toString() ?? '',
          'url': nested['product_url'] ?? docData['product_url'] ?? docData['url'] ?? '',
        };
        return SizedBox(
          key: ValueKey(productId.isNotEmpty ? productId : 'prod_$index'),
          child: _WishlistProductCard(
            product: normalizedProduct,
            index: index,
            onRemove: productId.isNotEmpty ? () => _removeProduct(productId) : null,
          ),
        );
      }),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Carte produit premium — exclusivement pour la page album wishlist
// ══════════════════════════════════════════════════════════════════
class _WishlistProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final int index;
  final VoidCallback? onRemove;

  static const _violet = Color(0xFF8A2BE2);
  static const _pink   = Color(0xFFEC4899);
  static const _gold   = Color(0xFFF59E0B);

  const _WishlistProductCard({
    required this.product,
    required this.index,
    this.onRemove,
  });

  String get _name  => product['name']  as String? ?? 'Produit';
  String get _brand => product['brand'] as String? ?? '';
  String get _price => product['price']?.toString() ?? '';
  String get _image => product['image'] as String? ?? '';

  Map<String, dynamic> get _normalized => {
    ...product,
    'name': _name, 'brand': _brand, 'price': _price, 'image': _image,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => GlobalProductDetailModal.show(context, _normalized),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.13)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image avec overlay gradient ──
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: SizedBox(
                        height: 178,
                        width: double.infinity,
                        child: _image.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _image,
                                fit: BoxFit.contain,
                                color: Colors.white.withOpacity(0.06),
                                colorBlendMode: BlendMode.overlay,
                                placeholder: (_, __) => Container(
                                  color: Colors.white.withOpacity(0.04),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24, height: 24,
                                      child: CircularProgressIndicator(
                                        color: _violet, strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: Colors.white.withOpacity(0.04),
                                  child: const Icon(
                                    Icons.card_giftcard_rounded,
                                    color: Colors.white24, size: 48,
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.white.withOpacity(0.04),
                                child: const Icon(
                                  Icons.card_giftcard_rounded,
                                  color: Colors.white24, size: 48,
                                ),
                              ),
                      ),
                    ),
                    // Gradient bas → transition fluide vers la zone texte
                    Positioned(
                      bottom: 0, left: 0, right: 0, height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(0),
                            bottomRight: Radius.circular(0),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Bouton supprimer (haut gauche)
                    if (onRemove != null)
                      Positioned(
                        top: 8, left: 8,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onRemove!();
                          },
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.80),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    // Bouton actions ⋮ (haut droite)
                    Positioned(
                      top: 8, right: 8,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          GlobalProductDetailModal.show(context, _normalized);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.40),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.more_vert, color: Colors.white, size: 15),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Zone texte ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge marque
                        if (_brand.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _violet.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _violet.withOpacity(0.35)),
                            ),
                            child: Text(
                              _brand.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB97EF8),
                                letterSpacing: 0.6,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 5),
                        // Nom du produit
                        Expanded(
                          child: Text(
                            _name,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.92),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Prix
                        if (_price.isNotEmpty && _price != '0')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _gold.withOpacity(0.22),
                                  _pink.withOpacity(0.16),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _gold.withOpacity(0.25)),
                            ),
                            child: Text(
                              _price.contains('€') ? _price : '$_price €',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _gold,
                              ),
                            ),
                          ),
                      ],
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
}

