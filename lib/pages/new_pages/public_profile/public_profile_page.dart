import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '/services/friend_service.dart';
import '/services/user_search_service.dart';
import '/services/firebase_data_service.dart';
import '/components/liquid_glass.dart';

/// Page de profil public d'un utilisateur — design unifié avec le profil perso.
/// Route : /public-profile/:uid
class PublicProfilePage extends StatefulWidget {
  final String uid;
  const PublicProfilePage({super.key, required this.uid});

  static const String routeName = 'PublicProfile';
  static const String routePath = '/public-profile/:uid';

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage>
    with SingleTickerProviderStateMixin {
  static const _violet = Color(0xFF8A2BE2);
  static const _pink = Color(0xFFEC4899);
  static const _green = Color(0xFF10B981);

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _wishlists = [];
  FriendshipStatus _friendshipStatus = FriendshipStatus.none;
  String? _requestId;
  bool _isLoading = true;
  bool _isFriendActionLoading = false;

  // Stats
  int _friendsCount = 0;
  int _wishlistsCount = 0;
  int _giftsCount = 0;

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
      if (!_isMyProfile) _loadFriendshipStatus(),
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
        final friends = (data['friends'] as List?) ?? [];
        _friendsCount = friends.length;
        _profile = {
          'uid': doc.id,
          'displayName': data['display_name'] ?? data['name'] ?? 'Utilisateur',
          'handle': data['handle'] ?? '',
          'photoUrl': data['photo_url'] ?? '',
          'bio': data['bio'] ?? '',
          'city': data['city'] ?? '',
          'friendsCount': friends.length,
        };
      }
    } catch (_) {}
  }

  Future<void> _loadWishlists() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final wishlists = await UserSearchService.getVisibleWishlists(
      widget.uid,
      viewerUid: myUid,
    );
    _wishlists = wishlists;
    _wishlistsCount = wishlists.length;
    // Compter les produits dans toutes les wishlists
    _giftsCount = wishlists.fold(0, (sum, w) {
      final count = (w['productCount'] as int?) ?? 0;
      return sum + count;
    });
  }

  Future<void> _loadFriendshipStatus() async {
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
          _showSnack('✅ Demande envoyée !', _green);
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
              _friendsCount++;
            });
            _showSnack('👥 Vous êtes maintenant amis !', _green);
          }
        }
        break;
      case FriendshipStatus.friends:
        final ok = await FriendService.removeFriend(widget.uid);
        if (ok) {
          setState(() {
            _friendshipStatus = FriendshipStatus.none;
            _friendsCount = (_friendsCount - 1).clamp(0, 999);
          });
          _showSnack('Retiré de vos amis', Colors.grey);
        }
        break;
    }

    setState(() => _isFriendActionLoading = false);
  }

  Future<void> _openDirectChat() async {
    try {
      final name = _profile?['displayName'] as String? ?? 'Utilisateur';
      final chatId = await FriendService.getOrCreateDirectChat(widget.uid);
      if (mounted) {
        context.push('/chat-room/$chatId', extra: {'name': name, 'isGroup': false});
      }
    } catch (_) {
      _showSnack('Impossible d\'ouvrir le chat.', Colors.red);
    }
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
          ? Center(child: CircularProgressIndicator(color: _violet, strokeWidth: 2))
          : _profile == null
              ? _buildNotFound()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(child: _buildStatsRow()),
        if (!_isMyProfile) SliverToBoxAdapter(child: _buildActionButtons()),
        if ((_profile!['bio'] as String? ?? '').isNotEmpty)
          SliverToBoxAdapter(child: _buildBio()),
        SliverToBoxAdapter(child: _buildWishlistsSection()),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  // ─── Sliver App Bar (hero photo + nom) ─────────────────────────────────────

  Widget _buildSliverAppBar() {
    final photoUrl = _profile!['photoUrl'] as String? ?? '';
    final displayName = _profile!['displayName'] as String? ?? '';
    final handle = _profile!['handle'] as String? ?? '';

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      stretch: true,
      backgroundColor: LiquidGlassTokens.pageDark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Dégradé de fond
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _violet.withOpacity(0.6),
                    _pink.withOpacity(0.4),
                    LiquidGlassTokens.pageDark,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Contenu : avatar + nom
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  // Avatar avec bordure dégradée
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [_violet, _pink]),
                      boxShadow: [
                        BoxShadow(
                          color: _violet.withOpacity(0.5),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: LiquidGlassTokens.pageDark,
                      backgroundImage: photoUrl.isNotEmpty
                          ? CachedNetworkImageProvider(photoUrl)
                          : null,
                      child: photoUrl.isEmpty
                          ? Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 8)]),
                  ),
                  if (handle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(
                        '@$handle',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Stats row (amis / wishlists / cadeaux) ─────────────────────────────────

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_violet.withOpacity(0.1), _pink.withOpacity(0.07)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            _buildStatItem(_friendsCount.toString(), 'Amis', Icons.people_rounded),
            _buildStatDivider(),
            _buildStatItem(_wishlistsCount.toString(), 'Wishlists', Icons.bookmark_rounded),
            _buildStatDivider(),
            _buildStatItem(_giftsCount.toString(), 'Cadeaux', Icons.card_giftcard_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: _violet, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.1),
    );
  }

  // ─── Boutons d'action (Ajouter ami + Message) ───────────────────────────────

  Widget _buildActionButtons() {
    final friendConfig = _getFriendButtonConfig();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Bouton ami (principal)
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: _isFriendActionLoading ? null : _onFriendButtonPressed,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: friendConfig.gradient),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: friendConfig.gradient.first.withOpacity(0.4),
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
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                    else ...[
                      Text(friendConfig.icon,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(friendConfig.label,
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Bouton message (visible uniquement si amis ou demande reçue)
          if (_friendshipStatus == FriendshipStatus.friends ||
              _friendshipStatus == FriendshipStatus.pendingReceived) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _openDirectChat,
              child: Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.chat_bubble_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _FriendButtonConfig _getFriendButtonConfig() {
    switch (_friendshipStatus) {
      case FriendshipStatus.none:
        return _FriendButtonConfig(
          label: 'Ajouter en ami',
          icon: '➕',
          gradient: [_violet, _pink],
        );
      case FriendshipStatus.pendingSent:
        return _FriendButtonConfig(
          label: 'En attente…',
          icon: '⏳',
          gradient: [Colors.grey.shade600, Colors.grey.shade700],
        );
      case FriendshipStatus.pendingReceived:
        return _FriendButtonConfig(
          label: 'Accepter',
          icon: '✅',
          gradient: [_green, const Color(0xFF059669)],
        );
      case FriendshipStatus.friends:
        return _FriendButtonConfig(
          label: 'Amis ✓',
          icon: '👥',
          gradient: [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
        );
    }
  }

  // ─── Bio ─────────────────────────────────────────────────────────────────────

  Widget _buildBio() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Text(
        _profile!['bio'] as String? ?? '',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, height: 1.5),
      ),
    );
  }

  // ─── Wishlists ────────────────────────────────────────────────────────────────

  Widget _buildWishlistsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre section
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_violet, _pink],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Albums',
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
                    color: _violet.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_wishlists.length}',
                    style: GoogleFonts.poppins(
                        color: _violet, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_wishlists.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.list_alt_rounded,
                        size: 56, color: Colors.white.withOpacity(0.15)),
                    const SizedBox(height: 12),
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
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.9,
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
    final productCount = (wishlist['productCount'] as int?) ?? 0;
    final coverUrl = wishlist['coverPhoto'] as String?;

    return GestureDetector(
      onTap: () {
        // TODO: naviguer vers les produits de cette wishlist
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image de fond (coverPhoto ou dégradé)
            if (coverUrl != null && coverUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: coverUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_violet.withOpacity(0.4), _pink.withOpacity(0.4)],
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => _buildDefaultAlbumGradient(emoji),
              )
            else
              _buildDefaultAlbumGradient(emoji),
            // Overlay gradient sombre en bas
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Texte en bas
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.card_giftcard_rounded,
                          color: Colors.white60, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '$productCount produit${productCount != 1 ? 's' : ''}',
                        style: GoogleFonts.poppins(
                            color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAlbumGradient(String emoji) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_violet.withOpacity(0.5), _pink.withOpacity(0.5)],
        ),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 40)),
      ),
    );
  }

  // ─── Not found ───────────────────────────────────────────────────────────────

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded,
              size: 72, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'Utilisateur introuvable',
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Retour',
                style: GoogleFonts.poppins(color: _violet)),
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
