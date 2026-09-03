import 'package:flutter/material.dart';
import 'dart:ui';
import '/utils/app_tr.dart';
import '/utils/iconly_compat.dart';
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
import '/components/liquid_glass_loader.dart';
import '/components/product_detail_modal.dart';
import '/components/block_report_sheet.dart';

/// Page de profil public — layout et design 100% identiques à user_profile_widget.dart
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

  late TabController _tabController;

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _wishlists = [];
  FriendshipStatus _friendshipStatus = FriendshipStatus.none;
  String? _requestId;
  bool _isLoading = true;
  bool _isFriendActionLoading = false;
  int _friendsCount = 0;

  bool get _isMyProfile =>
      FirebaseAuth.instance.currentUser?.uid == widget.uid;

  bool get _isFriendsWithUser =>
      _isMyProfile || _friendshipStatus == FriendshipStatus.friends;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          'displayName': data['display_name'] ?? data['displayName'] ?? data['name'] ?? 'Utilisateur',
          'handle': data['handle'] ?? '',
          'photoUrl': data['photo_url'] ?? data['photoUrl'] ?? '',
          'bio': data['bio'] ?? '',
          'isOnline': data['isOnline'] ?? false,
          'lastSeen': data['lastSeen'],
          'birthday': data['birthday'],
        };
      }
    } catch (_) {
      _profile = null;
    }
  }

  Future<void> _loadWishlists() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final wishlists = await UserSearchService.getVisibleWishlists(
      widget.uid,
      viewerUid: myUid,
    );
    _wishlists = wishlists;
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
          _friendshipStatus = FriendshipStatus.pendingSent;
          _requestId = id;
          _showSnack('Demande d\'ami envoyée ! ✉️', _violet);
        } else {
          _showSnack('Erreur lors de l\'envoi de la demande.', Colors.red);
        }
        break;

      case FriendshipStatus.pendingSent:
        if (_requestId != null) {
          final ok = await FriendService.cancelRequest(_requestId!);
          if (ok) {
            _friendshipStatus = FriendshipStatus.none;
            _requestId = null;
            _showSnack('Demande annulée.', Colors.grey.shade700);
          }
        }
        break;

      case FriendshipStatus.pendingReceived:
        if (_requestId != null) {
          final ok = await FriendService.acceptRequest(_requestId!, widget.uid);
          if (ok) {
            _friendshipStatus = FriendshipStatus.friends;
            _friendsCount++;
            _showSnack('Vous êtes maintenant amis ! 🎉', _green);
          }
        }
        break;

      case FriendshipStatus.friends:
        final confirm = await _confirmRemoveFriend();
        if (confirm == true) {
          final ok = await FriendService.removeFriend(widget.uid);
          if (ok) {
            _friendshipStatus = FriendshipStatus.none;
            _friendsCount = (_friendsCount - 1).clamp(0, 999999);
            _showSnack('Ami retiré.', Colors.grey.shade700);
          }
        }
        break;
    }

    if (mounted) setState(() => _isFriendActionLoading = false);
  }

  Future<bool?> _confirmRemoveFriend() {
    final name = _profile?['displayName'] as String? ?? 'cet ami';
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E0B36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Retirer des amis',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Voulez-vous vraiment retirer $name de vos amis ?',
            style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Annuler', style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Retirer', style: GoogleFonts.poppins(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _openDirectChat() async {
    try {
      final name = _profile?['displayName'] as String? ?? 'Utilisateur';
      final chatId = await FriendService.getOrCreateDirectChat(widget.uid);
      if (!mounted) return;
      context.push('/chat-room/$chatId', extra: {'name': name, 'isGroup': false});
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
          ? const Center(child: CircularProgressIndicator(color: _violet, strokeWidth: 2))
          : _profile == null
              ? _buildNotFound()
              : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      _buildAppBar(),
                      if (_isFriendsWithUser) _buildTabBar(),
                    ];
                  },
                  body: !_isFriendsWithUser
                      ? _buildPrivateProfileView()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildWishlistsTab(),
                            _buildLikedProductsTab(),
                          ],
                        ),
                ),
    );
  }

  // ── Header / App Bar (100% identique à user_profile_widget.dart) ─────────────

  Widget _buildAppBar() {
    final displayName = _profile?['displayName'] as String? ?? 'Utilisateur';
    final handle = _profile?['handle'] as String? ?? '';
    final photoUrl = _profile?['photoUrl'] as String? ?? '';
    final bio = _profile?['bio'] as String? ?? '';

    return SliverToBoxAdapter(
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _violet.withOpacity(0.12),
                  _pink.withOpacity(0.06),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.10),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Navigation row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        if (!_isMyProfile)
                          IconButton(
                            icon: const Icon(IconlyLight.moreCircle, color: Colors.white),
                            onPressed: () {
                              final h = _profile?['handle'] as String? ?? _profile?['displayName'] as String? ?? '';
                              BlockReportSheet.show(context, uid: widget.uid, handle: h);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Photo de profil taille identique (100x100 avec halo violet)
                        Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.8), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: _violet.withOpacity(0.6),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: photoUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: photoUrl,
                                        fit: BoxFit.cover,
                                        cacheKey: 'pub_profile_$photoUrl',
                                        memCacheHeight: 200,
                                        memCacheWidth: 200,
                                        placeholder: (_, __) => Container(
                                          color: Colors.grey[800],
                                          child: const Center(
                                            child: LiquidGlassLoader(size: 20, isDark: false),
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) => _buildAvatarFallback(displayName),
                                      )
                                    : _buildAvatarFallback(displayName),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        // Stats : Amis / Wishlists / Cadeaux
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildProfileStat(context.tr('Amis', 'Friends'), '$_friendsCount'),
                              _buildProfileStat(context.tr('Wishlists', 'Wishlists'), '${_wishlists.length}'),
                              _buildProfileStat(context.tr('Cadeaux', 'Gifts'), '${_wishlists.fold<int>(0, (sum, w) => sum + ((w['productCount'] as int?) ?? 0))}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Nom & Handle
                    const SizedBox(height: 12),
                    Text(
                      displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (handle.isNotEmpty)
                      Text(
                        '@$handle',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                      ),
                    // Statut en ligne
                    if (!_isMyProfile) Builder(builder: (ctx) {
                      final isOnline = _profile?['isOnline'] == true;
                      final lastSeen = _profile?['lastSeen'];
                      String statusText = '';
                      Color statusColor = Colors.white38;
                      if (isOnline) {
                        statusText = 'En ligne';
                        statusColor = const Color(0xFF10B981);
                      } else if (lastSeen != null) {
                        try {
                          final seen = (lastSeen as dynamic).toDate() as DateTime;
                          final diff = DateTime.now().difference(seen);
                          if (diff.inMinutes < 1) { statusText = 'Vu à l\'instant'; statusColor = Colors.white54; }
                          else if (diff.inMinutes < 60) { statusText = 'Vu il y a ${diff.inMinutes} min'; statusColor = Colors.white38; }
                          else if (diff.inHours < 24) { statusText = 'Vu il y a ${diff.inHours}h'; statusColor = Colors.white38; }
                        } catch (_) {}
                      }
                      if (statusText.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Container(width: 7, height: 7, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Text(statusText, style: GoogleFonts.poppins(fontSize: 12, color: statusColor)),
                          ],
                        ),
                      );
                    }),
                    // Affichage anniversaire propre
                    if (_isFriendsWithUser) Builder(builder: (ctx) {
                      final b = _profile?['birthday'] as Map<String, dynamic>?;
                      if (b == null) return const SizedBox.shrink();
                      const months = ['', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
                      final now = DateTime.now();
                      final day = (b['day'] as num?)?.toInt() ?? 1;
                      final month = (b['month'] as num?)?.toInt() ?? 1;
                      final isToday = now.day == day && now.month == month;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Text(isToday ? '🎂' : '🎁', style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              isToday ? "C'est son anniversaire aujourd'hui !" : 'Anniv : $day ${months[month]}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: isToday ? const Color(0xFFEC4899) : Colors.white70,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (bio.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          bio,
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Boutons d'action
                    if (!_isMyProfile)
                      Row(
                        children: [
                          Expanded(child: _buildFriendButton()),
                          if (_isFriendsWithUser ||
                              _friendshipStatus == FriendshipStatus.pendingReceived) ...[
                            const SizedBox(width: 8),
                            _buildChatButton(),
                          ],
                        ],
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String displayName) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    return Container(
      color: _violet,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.poppins(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count,
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12, color: Colors.white.withOpacity(0.9))),
      ],
    );
  }

  Widget _buildFriendButton() {
    final configs = {
      FriendshipStatus.none: (label: context.tr('Ajouter en ami', 'Add as friend'), icon: IconlyLight.addUser, color: _violet),
      FriendshipStatus.pendingSent: (label: 'En attente...', icon: Icons.hourglass_top_rounded, color: Colors.grey.shade600),
      FriendshipStatus.pendingReceived: (label: 'Accepter', icon: Icons.check_circle_rounded, color: _green),
      FriendshipStatus.friends: (label: 'Amis ✓', icon: IconlyLight.user2, color: const Color(0xFF6366F1)),
    };
    final cfg = configs[_friendshipStatus]!;

    return LiquidGlassCard(
      blur: LiquidGlassTokens.blurLight,
      padding: const EdgeInsets.symmetric(vertical: 10),
      onTap: _isFriendActionLoading ? null : _onFriendButtonPressed,
      child: Center(
        child: _isFriendActionLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cfg.icon, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    cfg.label,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildChatButton() {
    return LiquidGlassCard(
      blur: LiquidGlassTokens.blurLight,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      onTap: _openDirectChat,
      child: const Icon(IconlyLight.chat, color: Colors.white, size: 20),
    );
  }

  // ── TabBar Sticky (100% identique à user_profile_widget.dart) ────────────────

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.45),
          indicatorColor: const Color(0xFFEC4899),
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          tabs: [
            Tab(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.redeem_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(context.tr('Listes de cadeaux', 'Gift lists')),
                ],
              ),
            ),
            Tab(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(context.tr('Coups de coeur', 'Favourites')),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: LiquidGlassTokens.pageDark.withOpacity(0.9),
      ),
    );
  }

  // ── Vue Compte Privé (si non-ami) ───────────────────────────────────────────

  Widget _buildPrivateProfileView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.lock_outline_rounded, size: 44, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('Ce compte est privé', 'This account is private'),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(
                'Ajoutez cet utilisateur en ami pour voir ses wishlists et ses inspirations.',
                'Add this user as a friend to see their wishlists and inspirations.',
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // ── Onglet 1 : Wishlists ───────────────────────────────────────────────────

  Widget _buildWishlistsTab() {
    if (_wishlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconlyLight.bookmark, size: 60, color: Colors.white.withOpacity(0.35)),
            const SizedBox(height: 16),
            Text(
              context.tr('Aucune wishlist publique', 'No public wishlists'),
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 8),
            Text(
              'Cet utilisateur n\'a pas encore de wishlist partagée',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _wishlists.length,
      itemBuilder: (context, index) => _buildWishlistCard(_wishlists[index]),
    );
  }

  Widget _buildWishlistCard(Map<String, dynamic> wishlist) {
    final name = wishlist['name'] as String? ?? 'Wishlist';
    final productCount = (wishlist['productCount'] as int?) ?? 0;
    final coverUrl = wishlist['coverPhoto'] as String?;

    return GestureDetector(
      onTap: () => _showWishlistDetail(wishlist),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x1AFFFFFF), Color(0x0AFFFFFF)],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (coverUrl != null && coverUrl.isNotEmpty)
                CachedNetworkImage(imageUrl: coverUrl, fit: BoxFit.cover)
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_violet.withOpacity(0.8), _pink.withOpacity(0.8)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.bolt_rounded, size: 48, color: Colors.white70),
                  ),
                ),
              // Overlay sombre en bas
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 32, 12, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$productCount produit${productCount != 1 ? 's' : ''}',
                        style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Détail Wishlist (Grille 3 colonnes avec tap sur photo pour fiche produit) ──

  Future<void> _showWishlistDetail(Map<String, dynamic> wishlist) async {
    final wishlistId = wishlist['id'] as String;
    final products = await FirebaseDataService.loadWishlistProducts(wishlistId);

    if (!mounted) return;

    final normalizedProducts = products.map((p) => {
      'id': p['id'] ?? '',
      'name': p['title'] ?? p['name'] ?? p['product_title'] ?? 'Produit',
      'brand': p['brand'] ?? p['platform'] ?? p['source'] ?? '',
      'price': (p['price'] ?? p['product_price'] ?? '').toString(),
      'image': p['imageUrl'] ?? p['image'] ?? p['product_photo'] ?? p['photo'] ?? '',
      'url': p['url'] ?? p['productUrl'] ?? p['product_url'] ?? '',
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bsCtx) {
        return Container(
          height: MediaQuery.of(bsCtx).size.height * 0.88,
          decoration: BoxDecoration(
            color: LiquidGlassTokens.pageDark,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wishlist['name'] as String? ?? 'Wishlist',
                            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            '${normalizedProducts.length} ${context.tr(normalizedProducts.length > 1 ? 'articles' : 'article', normalizedProducts.length > 1 ? 'items' : 'item')}',
                            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF8A2BE2)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(bsCtx),
                      icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.white.withOpacity(0.08), height: 1),
              if (normalizedProducts.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.card_giftcard_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun produit dans cette liste',
                          style: GoogleFonts.poppins(fontSize: 16, color: Colors.white38, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: normalizedProducts.length,
                    itemBuilder: (context, index) {
                      final p = normalizedProducts[index];
                      final image = p['image'] as String? ?? '';
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          GlobalProductDetailModal.show(context, p);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              image.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: image,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(color: Colors.white.withOpacity(0.05)),
                                      errorWidget: (_, __, ___) => Container(
                                        color: Colors.white.withOpacity(0.08),
                                        child: const Icon(Icons.card_giftcard_rounded, color: Colors.white24, size: 28),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.white.withOpacity(0.08),
                                      child: const Icon(Icons.card_giftcard_rounded, color: Colors.white24, size: 28),
                                    ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                height: 32,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Onglet 2 : Coups de cœur privés ─────────────────────────────────────────

  Widget _buildLikedProductsTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(IconlyLight.lock, size: 38, color: Colors.white54),
            ),
            const SizedBox(height: 20),
            Text(
              'Produits likés privés',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les produits likés de cet utilisateur\nsont privés et non visibles.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white38),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(IconlyLight.profile, size: 72, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('Utilisateur introuvable',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Retour', style: GoogleFonts.poppins(color: _violet)),
          ),
        ],
      ),
    );
  }
}

// ── Délégué Tab Bar sticky ───────────────────────────────────────────────────

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, {this.backgroundColor = Colors.white});

  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
