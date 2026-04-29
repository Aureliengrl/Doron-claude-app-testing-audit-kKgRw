import 'package:flutter/material.dart';
import '/utils/app_tr.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '/services/friend_service.dart';
import '/services/user_search_service.dart';
import '/components/liquid_glass.dart';
import '/components/liquid_glass_loader.dart';
import '/components/shared_product_card.dart';
import '/components/block_report_sheet.dart';

/// Page de profil public â€” mÃªme layout que user_profile_widget.dart
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
  List<Map<String, dynamic>> _likedProducts = [];
  bool _likedProductsArePrivate = false; // true si l'onglet "Produits likÃ©s" n'est pas accessible
  FriendshipStatus _friendshipStatus = FriendshipStatus.none;
  String? _requestId;
  bool _isLoading = true;
  bool _isFriendActionLoading = false;
  int _friendsCount = 0;

  bool get _isMyProfile =>
      FirebaseAuth.instance.currentUser?.uid == widget.uid;

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
      _loadLikedProducts(),
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
          'birthday': data['birthday'],  // F3: anniversaire
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

  Future<void> _loadLikedProducts() async {
    // Les produits likÃ©s sont privÃ©s : on ne charge jamais ceux d'un autre utilisateur
    if (!_isMyProfile) {
      _likedProductsArePrivate = true;
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('favorites')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      _likedProducts = snap.docs.map((doc) {
        final d = doc.data();
        return <String, dynamic>{
          'id': doc.id,
          'name': d['name'] ?? '',
          'brand': d['brand'] ?? '',
          'price': d['price']?.toString() ?? '',
          'image': d['image'] ?? '',
          'url': d['url'] ?? '',
        };
      }).toList();
    } catch (_) {}
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
          _showSnack('âœ… Demande envoyÃ©e !', _green);
        } else {
          _showSnack('âŒ Erreur lors de l\'envoi', Colors.red);
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
            _showSnack('Demande annulÃ©e', Colors.grey);
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
            _showSnack('ðŸ‘¥ Vous Ãªtes maintenant amis !', _green);
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
          _showSnack('RetirÃ© de vos amis', Colors.grey);
        }
        break;
    }
    setState(() => _isFriendActionLoading = false);
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

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // BUILD
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _violet, strokeWidth: 2))
          : _profile == null
              ? _buildNotFound()
              : CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    _buildTabBar(),
                    _buildTabContent(),
                  ],
                ),
    );
  }

  // â”€â”€â”€ App Bar (identique au profil perso) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildAppBar() {
    final photoUrl = _profile!['photoUrl'] as String? ?? '';
    final displayName = _profile!['displayName'] as String? ?? '';
    final handle = _profile!['handle'] as String? ?? '';
    final bio = _profile!['bio'] as String? ?? '';

    return SliverAppBar(
      expandedHeight: 240,
      floating: false,
      pinned: true,
      backgroundColor: LiquidGlassTokens.pageDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (!_isMyProfile)
          IconButton(
            icon: const Icon(IconlyLight.moreCircle, color: Colors.white),
            onPressed: () {
              final h = _profile?['handle'] as String? ?? _profile?['displayName'] as String? ?? '';
              BlockReportSheet.show(context, uid: widget.uid, handle: h);
            },
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LiquidGlassTokens.darkPageGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Photo de profil
                      Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.8), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: _violet.withOpacity(0.6),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: photoUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: photoUrl,
                                      fit: BoxFit.cover,
                                      cacheKey: 'pub_profile_' + photoUrl,
                                      memCacheHeight: 160,
                                      memCacheWidth: 160,
                                      placeholder: (_, __) => Container(
                                        color: Colors.grey[800],
                                        child: const Center(
                                          child: LiquidGlassLoader(size: 16, isDark: false),
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
                      // Stats â€” Amis / Wishlists / Cadeaux
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildProfileStat('Amis', '$_friendsCount'),
                            _buildProfileStat(context.tr('Wishlists', 'Wishlists'), '${_wishlists.length}'),
                            _buildProfileStat('Cadeaux', '${_likedProducts.length}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Nom & Handle
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (handle.isNotEmpty)
                    Text(
                      '@$handle',
                      style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
                    ),
                  // S9 FIX: afficher la presence en ligne sur le profil public
                  if (!_isMyProfile) Builder(builder: (ctx) {
                    final isOnline = _profile?['isOnline'] == true;
                    final lastSeen = _profile?['lastSeen'];
                    String statusText = '';
                    Color statusColor = Colors.white38;
                    if (isOnline) {
                      statusText = 'En ligne';
                      statusColor = const Color(0xFF10B981);
                    } else if (lastSeen != null) {
                      final seen = (lastSeen as dynamic).toDate() as DateTime;
                      final diff = DateTime.now().difference(seen);
                      if (diff.inMinutes < 1) { statusText = 'Vu a l instant'; statusColor = Colors.white54; }
                      else if (diff.inMinutes < 60) { statusText = 'Vu il y a ${diff.inMinutes} min'; statusColor = Colors.white38; }
                      else if (diff.inHours < 24) { statusText = 'Vu il y a ${diff.inHours}h'; statusColor = Colors.white38; }
                    }
                    if (statusText.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Container(width: 7, height: 7, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text(statusText, style: GoogleFonts.outfit(fontSize: 12, color: statusColor)),
                        ],
                      ),
                    );
                  }),
                  // F3: affichage de l'anniversaire de l'ami sur son profil public
                  if (_friendshipStatus == FriendshipStatus.friends) Builder(builder: (ctx) {
                    final b = _profile?['birthday'] as Map<String, dynamic>?;
                    if (b == null) return const SizedBox.shrink();
                    const months = ['', 'jan', 'fév', 'mar', 'avr', 'mai', 'juin', 'juil', 'août', 'sep', 'oct', 'nov', 'déc'];
                    final now = DateTime.now();
                    final day = (b['day'] as num).toInt();
                    final month = (b['month'] as num).toInt();
                    final isToday = now.day == day && now.month == month;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Text(isToday ? '🎂' : '🎁', style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            isToday ? 'C'est son anniversaire aujourd'hui !' : 'Anniv: $day ${months[month]}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: isToday ? const Color(0xFFEC4899) : Colors.white54,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (bio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        bio,
                        style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Boutons d'action â€” remplacent "Modifier/Amis/Partager" du profil perso
                  if (!_isMyProfile)
                    Row(
                      children: [
                        Expanded(child: _buildFriendButton()),
                        if (_friendshipStatus == FriendshipStatus.friends ||
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
    );
  }

  Widget _buildAvatarFallback(String displayName) {
    return Container(
      color: _violet.withOpacity(0.3),
      child: displayName.isNotEmpty
          ? Center(
              child: Text(
                displayName[0].toUpperCase(),
                style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            )
          : const Icon(IconlyLight.profile, size: 40, color: Colors.white),
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
      FriendshipStatus.pendingSent: (label: 'En attenteâ€¦', icon: Icons.hourglass_top_rounded, color: Colors.grey.shade600),
      FriendshipStatus.pendingReceived: (label: 'Accepter', icon: Icons.check_circle_rounded, color: _green),
      FriendshipStatus.friends: (label: 'Amis âœ“', icon: IconlyLight.people, color: const Color(0xFF6366F1)),
    };
    final cfg = configs[_friendshipStatus]!;

    return LiquidGlassCard(
      blur: LiquidGlassTokens.blurLight,
      padding: const EdgeInsets.symmetric(vertical: 8),
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
                  const SizedBox(width: 6),
                  Text(cfg.label,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ],
              ),
      ),
    );
  }

  Widget _buildChatButton() {
    return LiquidGlassCard(
      blur: LiquidGlassTokens.blurLight,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      onTap: _openDirectChat,
      child: const Icon(IconlyLight.chat, color: Colors.white, size: 20),
    );
  }

  // â”€â”€â”€ Tab Bar (identique au profil perso) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.45),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
          tabs: [
            Tab(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(IconlyLight.document),
                  const SizedBox(width: 8),
                  const Text(context.tr('Wishlists', 'Wishlists')),
                ],
              ),
            ),
            Tab(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(IconlyBold.heart),
                  const SizedBox(width: 8),
                  const Text('Produits likÃ©s'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: LiquidGlassTokens.pageDark.withOpacity(0.9),
      ),
    );
  }

  // â”€â”€â”€ Tab Content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildTabContent() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildWishlists(),
          _buildLikedProducts(),
        ],
      ),
    );
  }

  Widget _buildWishlists() {
    if (_wishlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconlyLight.bookmark, size: 80, color: Colors.white.withOpacity(0.35)),
            const SizedBox(height: 16),
            Text(context.tr('Aucune wishlist publique', 'No public wishlists'),
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.7))),
            const SizedBox(height: 8),
            Text('Cet utilisateur n\'a pas encore de wishlist publique',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
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
    final emoji = wishlist['emoji'] as String? ?? 'ðŸŽ';
    final productCount = (wishlist['productCount'] as int?) ?? 0;
    final coverUrl = wishlist['coverPhoto'] as String?;

    return GestureDetector(
      onTap: () => context.push(
        '/wishlist-details/${wishlist['id']}',
        extra: {'ownerUid': widget.uid},
      ),
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
                      colors: [_violet.withOpacity(0.4), _pink.withOpacity(0.4)],
                    ),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 40))),
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
                      Text(name,
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text('$productCount produit${productCount != 1 ? 's' : ''}',
                          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
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

  Widget _buildLikedProducts() {
    // Produits likÃ©s d'un autre utilisateur â€” toujours privÃ©s
    if (_likedProductsArePrivate) {
      return Center(
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
              child: const Icon(IconlyLight.lock, size: 38, color: Colors.white38),
            ),
            const SizedBox(height: 20),
            Text(
              'Produits likÃ©s privÃ©s',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les produits likÃ©s de cet utilisateur\nsont privÃ©s et non visibles.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white30),
            ),
          ],
        ),
      );
    }

    if (_likedProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconlyLight.heart, size: 80, color: Colors.white.withOpacity(0.35)),
            const SizedBox(height: 16),
            Text('Aucun produit likÃ©',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.7))),
            const SizedBox(height: 8),
            Text('Les produits likÃ©s de cet utilisateur apparaÃ®tront ici',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _likedProducts.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SharedProductCard(
          product: _likedProducts[index],
          index: index,
          showWishlistButton: false,
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

// â”€â”€â”€ DÃ©lÃ©guÃ© Tab Bar sticky â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

