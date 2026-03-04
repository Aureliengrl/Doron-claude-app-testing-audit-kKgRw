```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/components/liquid_glass.dart';
import '/components/bounce_button.dart'; // Added import for BounceCard
import '/services/user_search_service.dart';
import '/utils/app_logger.dart';

/// Page de profil public d'un utilisateur Doron.
/// Accessible par @pseudo ou uid, affiche les infos publiques
/// et les wishlists (publiques uniquement pour les non-propriétaires).
class PublicProfilePage extends StatefulWidget {
  final String? userUid;
  final String? handle;

  const PublicProfilePage({super.key, this.userUid, this.handle})
      : assert(userUid != null || handle != null,
            'Fournir uid OU handle');

  static const String routeName = 'PublicProfile';
  static const String routePath = '/u/:handle';

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  static const _violet = Color(0xFF8A2BE2);
  static const _pink = Color(0xFFEC4899);

  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _wishlists = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      Map<String, dynamic>? profile;

      if (widget.handle != null) {
        profile = await UserSearchService.findUserByHandle(widget.handle!);
      }

      if (profile == null) {
        setState(() {
          _error = 'Profil introuvable.';
          _isLoading = false;
        });
        return;
      }

      final ownerUid = profile['uid'] as String;
      final wishlists = await UserSearchService.getVisibleWishlists(ownerUid);

      setState(() {
        _profile = profile;
        _wishlists = wishlists;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.debug('❌ PublicProfilePage: $e', 'Social');
      setState(() {
        _error = 'Erreur de chargement.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _violet, strokeWidth: 2))
          : _error != null
              ? _buildError()
              : CustomScrollView(slivers: [
                  _buildAppBar(),
                  _buildInfoSection(),
                  _buildWishlistSection(),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ]),
    );
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.poppins(
                  fontSize: 16, color: const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.pop(),
              child: Text('Retour',
                  style: GoogleFonts.poppins(color: _violet)),
            ),
          ],
        ),
      );

  Widget _buildAppBar() {
    final profile = _profile!;
    final photoUrl = profile['photoUrl'] as String? ?? '';
    final displayName = profile['displayName'] as String? ?? 'Utilisateur';
    final handle = profile['handle'] as String? ?? '';

    return SliverAppBar(
      expandedHeight: 250,
      floating: false,
      pinned: true,
      backgroundColor: _violet,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          onPressed: _shareProfile,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_violet, _pink],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Photo de profil
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: photoUrl.isNotEmpty
                            ? CachedNetworkImageProvider(photoUrl)
                            : null,
                        child: photoUrl.isEmpty
                            ? Text(
                                displayName[0].toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 24),
                      // Stats
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildProfileStat('Cadeaux', '0'),
                            _buildProfileStat('Abonnés', '0'),
                            _buildProfileStat('Abonnements', '0'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (handle.isNotEmpty)
                    Text(
                      '@$handle',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Vous suivez maintenant $displayName',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _violet,
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Suivre',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    final profile = _profile!;
    final bio = profile['bio'] as String? ?? '';
    final city = profile['city'] as String? ?? '';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bio.isNotEmpty) ...[
              Text(
                '"$bio"',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (city.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 4),
                  Text(
                    city,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎁 Wishlists',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            if (_wishlists.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Aucune wishlist publique.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              )
            else
              ..._wishlists.map((w) => _buildWishlistTile(w)),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistTile(Map<String, dynamic> wishlist) {
    final name = wishlist['name'] as String? ?? 'Wishlist';
    final count = wishlist['productCount'] as int? ?? 0;
    final isPublic = wishlist['isPublic'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BounceCard(
        onTap: () {
          final wishlistId = wishlist['id'] as String?;
          if (wishlistId != null && wishlistId.isNotEmpty) {
            context.push('/wishlist-details/$wishlistId');
          }
        },
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_violet, _pink]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPublic ? Icons.bookmark : Icons.lock,
              color: Colors.white,
              size: 22,
            ),
          ),
          title: Text(
            name,
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '$count cadeau${count > 1 ? 'x' : ''}',
            style: GoogleFonts.poppins(
                fontSize: 13, color: const Color(0xFF6B7280)),
          ),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
        ),
      ),
    );
  }

  Future<void> _shareProfile() async {
    final handle = _profile?['handle'] as String?;
    if (handle == null || handle.isEmpty) return;
    final url = 'https://doron.app/@$handle';
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lien copié ! $url',
              style: GoogleFonts.poppins()),
          backgroundColor: _violet,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
