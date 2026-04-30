import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/components/liquid_glass.dart';
import '/components/cached_image.dart';
import '/components/shared_product_card.dart';
import '/services/secret_santa_service.dart';

class SecretSantaWishlistPage extends StatefulWidget {
  final String groupId;
  const SecretSantaWishlistPage({super.key, required this.groupId});

  static const String routeName = 'SecretSantaWishlist';
  static const String routePath = '/secret-santa/wishlist/:groupId';

  @override
  State<SecretSantaWishlistPage> createState() => _SecretSantaWishlistPageState();
}

class _SecretSantaWishlistPageState extends State<SecretSantaWishlistPage> {
  final Color _violet = const Color(0xFF8A2BE2);
  final Color _pink = const Color(0xFFEC4899);
  final Color _green = const Color(0xFF10B981);

  bool _loading = true;
  bool _marking = false;
  bool _hasBought = false;

  Map<String, dynamic>? _pair;
  Map<String, dynamic>? _targetProfile;
  SecretSantaGroup? _group;
  List<Map<String, dynamic>> _wishlistItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        SecretSantaService.getMyPair(widget.groupId),
        SecretSantaService.getGroupStream(widget.groupId).first,
      ]);

      _pair = results[0] as Map<String, dynamic>?;
      _group = results[1] as SecretSantaGroup?;

      if (_pair != null && _group != null) {
        final targetUid = _pair!['assignedToUid'] as String;

        final profileAndItems = await Future.wait([
          SecretSantaService.getParticipantProfile(targetUid),
          SecretSantaService.getWishlistItemsInBudget(
            targetUid: targetUid,
            budgetMax: _group!.budget['max'] ?? 50,
          ),
        ]);

        _targetProfile = profileAndItems[0] as Map<String, dynamic>?;
        _wishlistItems = profileAndItems[1] as List<Map<String, dynamic>>;
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markBought() async {
    if (_marking) return;
    setState(() => _marking = true);
    try {
      await SecretSantaService.markBought(widget.groupId);
      HapticFeedback.heavyImpact();
      setState(() => _hasBought = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Text('🎁 ', style: TextStyle(fontSize: 20)),
              Text('Cadeau marqué comme acheté !', style: GoogleFonts.poppins(color: Colors.white)),
            ]),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e', style: GoogleFonts.poppins()), backgroundColor: Colors.red[700]),
        );
      }
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: LiquidGlassTokens.pageDark,
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF8A2BE2))),
      );
    }

    if (_pair == null || _group == null) {
      return Scaffold(
        backgroundColor: LiquidGlassTokens.pageDark,
        appBar: AppBar(backgroundColor: Colors.transparent, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => context.pop())),
        body: Center(child: Text('Aucune information disponible', style: GoogleFonts.poppins(color: Colors.white))),
      );
    }

    final name = _pair!['assignedToName'] as String? ?? '?';
    final photo = _targetProfile?['photo_url'] as String? ?? _targetProfile?['photoUrl'] as String?;
    final budgetMax = _group!.budget['max'] ?? 50;
    final budgetMin = _group!.budget['min'] ?? 0;

    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: CustomScrollView(
        slivers: [
          // ── Header ───────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: Colors.transparent,
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [_violet.withOpacity(0.6), LiquidGlassTokens.pageDark],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      CachedCircleAvatar(
                        photoUrl: photo,
                        radius: 44,
                        backgroundColor: _violet.withOpacity(0.3),
                      ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 12),
                      Text(name,
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))
                          .animate().fadeIn(delay: 200.ms),
                      Text('Budget : $budgetMin€ – $budgetMax€',
                          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13))
                          .animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Bouton acheté ────────────────────────────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    margin: const EdgeInsets.only(bottom: 24),
                    child: _hasBought
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _green.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: _green, size: 28),
                                const SizedBox(width: 12),
                                Text('Cadeau acheté ✅',
                                    style: GoogleFonts.poppins(color: _green, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9))
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _marking ? null : _markBought,
                              icon: _marking
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                              label: Text('Marquer comme acheté',
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _violet,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                  ),

                  // ── Wishlist items ────────────────────────────────────────
                  Text('🎁 Sa wishlist dans ton budget',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Articles sous $budgetMax€',
                      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 16),

                  if (_wishlistItems.isEmpty)
                    _buildEmptyWishlist(name, budgetMax)
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _wishlistItems.length,
                      itemBuilder: (context, i) {
                        final item = _wishlistItems[i];
                        return SharedProductCard(
                          product: item,
                          onTap: () {},
                        ).animate().fadeIn(delay: Duration(milliseconds: 60 * i)).slideY(begin: 0.1, end: 0);
                      },
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWishlist(String name, int budgetMax) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          const Text('🛍️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('$name n\'a pas encore de wishlist\ndans ce budget',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 8),
          Text('Inspire-toi du catalogue Doron pour trouver l\'idée parfaite sous $budgetMax€',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => context.push('/home-pinterest'),
            icon: const Icon(Icons.search_rounded, color: Color(0xFF8A2BE2)),
            label: Text('Explorer les idées',
                style: GoogleFonts.poppins(color: const Color(0xFF8A2BE2), fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF8A2BE2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
