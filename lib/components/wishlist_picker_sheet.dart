import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doron/services/firebase_data_service.dart';
import '/utils/iconly_compat.dart';
import '/components/liquid_glass.dart';
import '/utils/app_tr.dart';

class WishlistPickerSheet extends StatefulWidget {
  final Map<String, dynamic> product;

  const WishlistPickerSheet({super.key, required this.product});

  static void show(BuildContext context, dynamic product) {
    if (product == null) return;
    
    Map<String, dynamic> productMap;
    if (product is Map<String, dynamic>) {
      productMap = product;
    } else {
      productMap = Map<String, dynamic>.from(product as Map);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: WishlistPickerSheet(product: productMap),
      ),
    );
  }

  @override
  State<WishlistPickerSheet> createState() => _WishlistPickerSheetState();
}

class _WishlistPickerSheetState extends State<WishlistPickerSheet> {
  List<Map<String, dynamic>> _wishlists = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadWishlists();
  }

  Future<void> _loadWishlists() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('wishlists')
          .get();
          
      if (mounted) {
        setState(() {
          _wishlists = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addToWishlist(String wishlistId, String wishlistName) async {
    if (_isSaving) return;
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    // Cache les objets liés au context avant de fermer la modale
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    
    // Ferme la modale immédiatement pour éviter le bug de l'écran grisé
    nav.pop();

    try {
      // FIX: Utilise le service global pour ajouter dans "products" avec le même format
      await FirebaseDataService.addProductToWishlist(wishlistId, widget.product);

      messenger.showSnackBar(SnackBar(
        content: Text('Ajouté à $wishlistName !', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF8A2BE2),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Erreur lors de l''ajout', style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0C29).withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2))),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Ajouter à une liste',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: Color(0xFF8A2BE2))))
            else if (_wishlists.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Aucune wishlist trouvée', style: GoogleFonts.poppins(color: Colors.white70)),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _wishlists.length,
                  itemBuilder: (context, index) {
                    final wl = _wishlists[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: LiquidGlassCard(
                        onTap: () => _addToWishlist(wl['id'], wl['name'] ?? 'Liste'),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(IconlyBold.document, color: Color(0xFF8A2BE2)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                wl['name'] ?? 'Sans nom',
                                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: LiquidGlassCard(
                onTap: () {
                  Navigator.of(context).pop();
                },
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.close, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Annuler', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
