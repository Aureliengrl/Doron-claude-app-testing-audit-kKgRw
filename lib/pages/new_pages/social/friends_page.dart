import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/components/liquid_glass.dart';
import '/services/user_search_service.dart';
import '/services/friend_service.dart';
import '/utils/app_logger.dart';

/// Page Amis — recherche d'utilisateurs par @handle, liste des amis,
/// et accès rapide au chat direct.
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  static const String routeName = 'FriendsPage';
  static const String routePath = '/friends';

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  static const _violet = Color(0xFF8A2BE2);
  static const _pink = Color(0xFFEC4899);

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ─── Recherche ───────────────────────────────────────────────────────────

  Future<void> _search(String query) async {
    if (query.trim() == _lastQuery) return;
    _lastQuery = query.trim();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await UserSearchService.searchUsers(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      AppLogger.debug('❌ FriendsPage search: $e', 'Social');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  Future<void> _addFriend(Map<String, dynamic> profile) async {
    try {
      await FriendService.addFriend(profile);
      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '👥 ${profile['displayName']} ajouté(e) comme ami(e) !',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: _violet,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openDirectChat(String friendUid, String friendName) async {
    try {
      final chatId = await FriendService.getOrCreateDirectChat(friendUid);
      if (mounted) {
        context.push('/chat-room/$chatId', extra: {
          'name': friendName,
          'isGroup': false,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir le chat.', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFriendsList(),
                  _buildSearchResults(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          Text(
            'Amis',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, color: Colors.white54, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) {
                      _search(v);
                      if (_tabController.index != 1) {
                        _tabController.animateTo(1);
                      }
                    },
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par @pseudo ou prénom...',
                      hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _search('');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: const Icon(Icons.clear, color: Colors.white54, size: 18),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(colors: [_violet, _pink]),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        labelPadding: const EdgeInsets.symmetric(vertical: 8),
        labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14),
        tabs: const [
          Tab(text: '👥 Mes amis'),
          Tab(text: '🔍 Rechercher'),
        ],
      ),
    );
  }

  // ─── Onglet Amis ─────────────────────────────────────────────────────────

  Widget _buildFriendsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FriendService.getFriendsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _violet, strokeWidth: 2));
        }

        final friends = snapshot.data ?? [];

        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 72, color: Colors.white24),
                const SizedBox(height: 20),
                Text(
                  'Aucun ami pour l\'instant',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white54),
                ),
                const SizedBox(height: 8),
                Text(
                  'Recherche des utilisateurs et ajoute-les !',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white30),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return _buildFriendTile(friend);
          },
        );
      },
    );
  }

  Widget _buildFriendTile(Map<String, dynamic> friend) {
    final photoUrl = friend['photoUrl'] as String? ?? '';
    final name = friend['displayName'] as String? ?? 'Utilisateur';
    final handle = friend['handle'] as String? ?? '';
    final uid = friend['uid'] as String? ?? friend['id'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: _violet.withOpacity(0.3),
              backgroundImage: photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
              child: photoUrl.isEmpty
                  ? Text(
                      name[0].toUpperCase(),
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  if (handle.isNotEmpty)
                    Text('@$handle', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white54)),
                ],
              ),
            ),
            // Bouton message
            GestureDetector(
              onTap: () => _openDirectChat(uid, name),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_violet, _pink]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text('Message', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Supprimer ami
            GestureDetector(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1E1E1E),
                    title: Text('Retirer l\'ami ?', style: GoogleFonts.poppins(color: Colors.white)),
                    content: Text('Supprimer $name de vos amis ?', style: GoogleFonts.poppins(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Annuler', style: GoogleFonts.poppins(color: Colors.white54))),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Supprimer', style: GoogleFonts.poppins(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) await FriendService.removeFriend(uid);
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.person_remove_outlined, color: Colors.white38, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Onglet Recherche ────────────────────────────────────────────────────

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'Cherche par @pseudo ou prénom',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white38),
            ),
          ],
        ),
      );
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator(color: _violet, strokeWidth: 2));
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'Aucun utilisateur trouvé',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildSearchResultTile(_searchResults[index]);
      },
    );
  }

  Widget _buildSearchResultTile(Map<String, dynamic> profile) {
    final photoUrl = profile['photoUrl'] as String? ?? '';
    final name = profile['displayName'] as String? ?? 'Utilisateur';
    final handle = profile['handle'] as String? ?? '';
    final uid = profile['uid'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: _pink.withOpacity(0.3),
              backgroundImage: photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
              child: photoUrl.isEmpty
                  ? Text(
                      name[0].toUpperCase(),
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  if (handle.isNotEmpty)
                    Text('@$handle', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white54)),
                ],
              ),
            ),
            // Bouton ajouter
            FutureBuilder<bool>(
              future: FriendService.isFriend(uid),
              builder: (context, snap) {
                final alreadyFriend = snap.data ?? false;
                if (alreadyFriend) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check, color: Colors.white54, size: 16),
                        const SizedBox(width: 4),
                        Text('Ami(e)', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white54)),
                      ],
                    ),
                  );
                }
                return GestureDetector(
                  onTap: () => _addFriend(profile),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_violet, _pink]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_add_outlined, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text('Ajouter', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
