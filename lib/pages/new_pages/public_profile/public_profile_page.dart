import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/services/friend_service.dart';
import '/services/user_search_service.dart';
import '/components/liquid_glass.dart';

/// Page de profil public d'un utilisateur.
/// Route : /public-profile/:uid
class PublicProfilePage extends StatefulWidget {
  final String uid;
  const PublicProfilePage({super.key, required this.uid});

  static const String routeName = 'PublicProfile';
  static const String routePath = '/public-profile/:uid';

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  final Color _violetColor = const Color(0xFF8A2BE2);
  final Color _pinkColor = const Color(0xFFEC4899);

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _wishlists = [];
  FriendshipStatus _friendshipStatus = FriendshipStatus.none;
  String? _requestId;
  bool _isLoading = true;
  bool _isFriendActionLoading = false;

  bool get _isMyProfile =>
      FirebaseAuth.instance.currentUser?.uid == widget.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([
      _loadProfile(),
      _loadWishlists(),
      _loadFriendshipStatus(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _profile = {
          'uid': doc.id,
          'displayName': data['display_name'] ?? data['name'] ?? 'Utilisateur',
          'handle': data['handle'] ?? '',
          'photoUrl': data['photo_url'] ?? '',
          'bio': data['bio'] ?? '',
          'city': data['city'] ?? '',
          'friendsCount': (data['friends'] as List?)?.length ?? 0,
        };
      }
    } catch (_) {}
  }

  Future<void> _loadWishlists() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    _wishlists = await UserSearchService.getVisibleWishlists(
      widget.uid,
      viewerUid: myUid,
    );
  }

  Future<void> _loadFriendshipStatus() async {
    if (_isMyProfile) return;
    final result = await FriendService.getFriendshipStatus(widget.uid);
    _friendshipStatus = result.status;
    _requestId = result.requestId;
  }

  Future<void> _onFriendButtonPressed() async {
    setState(() => _isFriendActionLoading = true);
    HapticFeedback.mediumImpact();

    switch (_friendshipStatus) {
      case FriendshipStatus.none:
        final id = await FriendService.sendRequest(widget.uid);
        if (id != null) {
          setState(() {
            _friendshipStatus = FriendshipStatus.pendingSent;
            _requestId = id;
          });
          _showSnack('✅ Demande envoyée !', const Color(0xFF10B981));
        } else {
          _showSnack('❌ Erreur lors de l\'envoi', Colors.red);
        }
        break;

      case FriendshipStatus.pendingSent:
        if (_requestId != null) {
          final ok = await FriendService.cancelRequest(_requestId!);
          if (ok) {
            setState(() {
              _friendshipStatus = FriendshipStatus.none;
              _requestId = null;
            });
            _showSnack('Demande annulée', Colors.grey);
          }
        }
        break;

      case FriendshipStatus.pendingReceived:
        if (_requestId != null) {
          final ok = await FriendService.acceptRequest(_requestId!, widget.uid);
          if (ok) {
            setState(() {
              _friendshipStatus = FriendshipStatus.friends;
              _requestId = null;
            });
            _showSnack('👥 Vous êtes maintenant amis !', const Color(0xFF10B981));
          }
        }
        break;

      case FriendshipStatus.friends:
        final ok = await FriendService.removeFriend(widget.uid);
        if (ok) {
          setState(() => _friendshipStatus = FriendshipStatus.none);
          _showSnack('Retiré de vos amis', Colors.grey);
        }
        break;
    }

    setState(() => _isFriendActionLoading = false);
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _violetColor))
          : _profile == null
              ? _buildNotFound()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(child: _buildProfileHeader()),
        if (!_isMyProfile) SliverToBoxAdapter(child: _buildFriendButton()),
        SliverToBoxAdapter(child: _buildWishlistsSection()),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      backgroundColor: LiquidGlassTokens.pageDark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        _isMyProfile ? 'Mon profil' : 'Profil',
        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final photoUrl = _profile!['photoUrl'] as String? ?? '';
    final displayName = _profile!['displayName'] as String? ?? 'Utilisateur';
    final handle = _profile!['handle'] as String? ?? '';
    final bio = _profile!['bio'] as String? ?? '';
    final city = _profile!['city'] as String? ?? '';
    final friendsCount = _profile!['friendsCount'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _violetColor.withOpacity(0.15),
            _pinkColor.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [_violetColor, _pinkColor]),
              boxShadow: [
                BoxShadow(color: _violetColor.withOpacity(0.4), blurRadius: 20, spreadRadius: 2),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: LiquidGlassTokens.pageDark,
              backgroundImage: photoUrl.isNotEmpty
                  ? CachedNetworkImageProvider(photoUrl)
                  : null,
              child: photoUrl.isEmpty
                  ? Text(
                      displayName[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          // Nom
          Text(
            displayName,
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (handle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _violetColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _violetColor.withOpacity(0.4)),
              ),
              child: Text(
                '@$handle',
                style: GoogleFonts.poppins(
                    color: _violetColor, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
            ),
          ],
          const SizedBox(height: 16),
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (city.isNotEmpty) ...[
                const Icon(Icons.location_on_rounded, color: Colors.white38, size: 14),
                const SizedBox(width: 4),
                Text(city, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13)),
                const SizedBox(width: 16),
              ],
              const Icon(Icons.people_rounded, color: Colors.white38, size: 14),
              const SizedBox(width: 4),
              Text('$friendsCount ami${friendsCount > 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendButton() {
    final buttonConfig = _getFriendButtonConfig();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isFriendActionLoading ? null : _onFriendButtonPressed,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: buttonConfig.gradient),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: buttonConfig.gradient.first.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isFriendActionLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  else
                    Text(buttonConfig.icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    buttonConfig.label,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _FriendButtonConfig _getFriendButtonConfig() {
    switch (_friendshipStatus) {
      case FriendshipStatus.none:
        return _FriendButtonConfig(
          label: 'Ajouter en ami',
          icon: '➕',
          gradient: [_violetColor, _pinkColor],
        );
      case FriendshipStatus.pendingSent:
        return _FriendButtonConfig(
          label: 'En attente…',
          icon: '⏳',
          gradient: [Colors.grey.shade600, Colors.grey.shade700],
        );
      case FriendshipStatus.pendingReceived:
        return _FriendButtonConfig(
          label: 'Accepter la demande',
          icon: '✅',
          gradient: [const Color(0xFF10B981), const Color(0xFF059669)],
        );
      case FriendshipStatus.friends:
        return _FriendButtonConfig(
          label: 'Amis  ✓',
          icon: '👥',
          gradient: [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
        );
    }
  }

  Widget _buildWishlistsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '🎁 Wishlists',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              if (_wishlists.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _violetColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_wishlists.length}',
                    style: GoogleFonts.poppins(
                        color: _violetColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_wishlists.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.list_alt_rounded,
                        size: 48, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(height: 8),
                    Text(
                      'Aucune wishlist publique',
                      style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.4), fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: _wishlists.length,
              itemBuilder: (context, index) =>
                  _buildWishlistCard(_wishlists[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildWishlistCard(Map<String, dynamic> wishlist) {
    final name = wishlist['name'] as String? ?? 'Wishlist';
    final emoji = wishlist['emoji'] as String? ?? '🎁';
    final productCount = wishlist['productCount'] as int? ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: naviguer vers les produits de cette wishlist
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.09),
                Colors.white.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$productCount produit${productCount > 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(
                        color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded,
              size: 64, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Utilisateur introuvable',
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Retour', style: GoogleFonts.poppins(color: _violetColor)),
          ),
        ],
      ),
    );
  }
}

/// Config visuelle du bouton ami.
class _FriendButtonConfig {
  final String label;
  final String icon;
  final List<Color> gradient;
  const _FriendButtonConfig({
    required this.label,
    required this.icon,
    required this.gradient,
  });
}
