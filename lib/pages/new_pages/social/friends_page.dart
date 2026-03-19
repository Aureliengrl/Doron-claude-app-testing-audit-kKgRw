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

/// Page Amis — 3 onglets : Mes amis / Rechercher / Demandes reçues
/// ─ Chaque résultat de recherche affiche le statut exact (none/pending/friend)
/// ─ Clic sur profil → /public-profile/:uid (PublicProfilePage)
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
  static const _green = Color(0xFF10B981);

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Onglet Recherche
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _lastQuery = '';
  // Cache des statuts d'amitié pour les résultats de recherche
  final Map<String, ({FriendshipStatus status, String? requestId})> _statusCache = {};
  final Set<String> _loadingStatuses = {};

  // Onglet Demandes — stream temps réel
  Stream<List<Map<String, dynamic>>>? _requestsStream;
  List<Map<String, dynamic>> _pendingRequests = [];
  final Set<String> _processingRequestIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Stream temps réel des demandes reçues
    _requestsStream = FriendService.getPendingRequestsStream();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ─── Recherche ──────────────────────────────────────────────────────────

  Future<void> _search(String query) async {
    if (query.trim() == _lastQuery) return;
    _lastQuery = query.trim();

    if (query.trim().isEmpty) {
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await UserSearchService.searchUsers(query.trim());
      if (mounted) {
        setState(() { _searchResults = results; _isSearching = false; });
        // Charger les statuts en arrière-plan
        for (final r in results) {
          final uid = r['uid'] as String? ?? '';
          if (uid.isNotEmpty && !_statusCache.containsKey(uid)) {
            _loadFriendshipStatus(uid);
          }
        }
      }
    } catch (e) {
      AppLogger.debug('❌ FriendsPage search: $e', 'Social');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _loadFriendshipStatus(String uid) async {
    if (_loadingStatuses.contains(uid)) return;
    _loadingStatuses.add(uid);
    try {
      final result = await FriendService.getFriendshipStatus(uid);
      if (mounted) {
        setState(() => _statusCache[uid] = result);
      }
    } catch (_) {}
    _loadingStatuses.remove(uid);
  }

  // ─── Demandes ───────────────────────────────────────────────────────────
  // Les demandes sont gérées via _requestsStream (StreamBuilder) — pas de chargement manuel.

  Future<void> _acceptRequest(String requestId, String fromUid) async {
    setState(() => _processingRequestIds.add(requestId));
    HapticFeedback.mediumImpact();
    final ok = await FriendService.acceptRequest(requestId, fromUid);
    if (mounted) {
      setState(() {
        _processingRequestIds.remove(requestId);
        if (ok) _pendingRequests.removeWhere((r) => r['requestId'] == requestId);
      });
      _showSnack(ok ? '👥 Vous êtes maintenant amis !' : '❌ Erreur', ok ? _green : Colors.red);
      if (ok) {
        // Invalider le cache pour cet uid
        _statusCache.remove(fromUid);
      }
    }
  }

  Future<void> _declineRequest(String requestId) async {
    setState(() => _processingRequestIds.add(requestId));
    final ok = await FriendService.declineRequest(requestId);
    if (mounted) {
      setState(() {
        _processingRequestIds.remove(requestId);
        if (ok) _pendingRequests.removeWhere((r) => r['requestId'] == requestId);
      });
    }
  }

  // ─── Actions (recherche) ────────────────────────────────────────────────

  Future<void> _sendRequest(String uid) async {
    setState(() => _loadingStatuses.add(uid));
    HapticFeedback.lightImpact();
    final requestId = await FriendService.sendRequest(uid);
    if (mounted) {
      setState(() {
        _loadingStatuses.remove(uid);
        if (requestId != null) {
          _statusCache[uid] = (status: FriendshipStatus.pendingSent, requestId: requestId);
        }
      });
      if (requestId != null) _showSnack('✅ Demande envoyée !', _green);
    }
  }

  Future<void> _cancelRequest(String uid, String requestId) async {
    setState(() => _loadingStatuses.add(uid));
    HapticFeedback.lightImpact();
    final ok = await FriendService.cancelRequest(requestId);
    if (mounted) {
      setState(() {
        _loadingStatuses.remove(uid);
        if (ok) _statusCache[uid] = (status: FriendshipStatus.none, requestId: null);
      });
      if (ok) _showSnack('Demande annulée', Colors.grey);
    }
  }

  Future<void> _acceptFromSearch(String uid, String requestId) async {
    setState(() => _loadingStatuses.add(uid));
    HapticFeedback.mediumImpact();
    final ok = await FriendService.acceptRequest(requestId, uid);
    if (mounted) {
      setState(() {
        _loadingStatuses.remove(uid);
        if (ok) _statusCache[uid] = (status: FriendshipStatus.friends, requestId: null);
      });
      if (ok) {
        _showSnack('👥 Vous êtes maintenant amis !', _green);
        _pendingRequests.removeWhere((r) => r['fromUid'] == uid);
      }
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

  void _openProfile(String uid) {
    context.push('/public-profile/$uid');
  }

  void _openDirectChat(String uid, String name) async {
    try {
      final chatId = await FriendService.getOrCreateDirectChat(uid);
      if (mounted) {
        context.push('/chat-room/$chatId', extra: {'name': name, 'isGroup': false});
      }
    } catch (_) {
      _showSnack('Impossible d\'ouvrir le chat.', Colors.red);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────

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
                  _buildPendingRequests(),
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
          Text('Amis', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
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
                      if (_tabController.index != 1) _tabController.animateTo(1);
                    },
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par @pseudo ou prénom…',
                      hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () { _searchController.clear(); _search(''); },
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.clear, color: Colors.white54, size: 18),
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
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _requestsStream,
      builder: (context, snap) {
        // Mettre à jour la liste locale avec les données du stream
        if (snap.hasData) _pendingRequests = snap.data!;
        final pendingCount = _pendingRequests.length;
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
            labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
            tabs: [
              const Tab(text: '👥 Amis'),
              const Tab(text: '🔍 Rechercher'),
              Tab(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Text('📬 Demandes', style: GoogleFonts.poppins(fontSize: 13)),
                    if (pendingCount > 0)
                      Positioned(
                        top: -6,
                        right: -10,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Onglet Amis ────────────────────────────────────────────────────────

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
                Text('Aucun ami pour l\'instant',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white54)),
                const SizedBox(height: 8),
                Text('Recherche des utilisateurs et ajoute-les !',
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.white30)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: friends.length,
          itemBuilder: (context, index) => _buildFriendTile(friends[index]),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openProfile(uid),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                // Avatar cliquable
                GestureDetector(
                  onTap: () => _openProfile(uid),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _violet.withOpacity(0.3),
                    backgroundImage: photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? Text(name[0].toUpperCase(),
                            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))
                        : null,
                  ),
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
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.people_rounded, size: 12, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          Text('Amis', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF10B981))),
                        ],
                      ),
                    ],
                  ),
                ),
                // Bouton voir profil
                GestureDetector(
                  onTap: () => _openProfile(uid),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: _violet.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _violet.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.person_rounded, color: _violet, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                // Bouton message
                GestureDetector(
                  onTap: () => _openDirectChat(uid, name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_violet, _pink]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                // Supprimer
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
                    if (confirm == true) {
                      await FriendService.removeFriend(uid);
                      _statusCache.remove(uid);
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.person_remove_outlined, color: Colors.white38, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Onglet Recherche ───────────────────────────────────────────────────

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text('Cherche par @pseudo ou prénom', style: GoogleFonts.poppins(fontSize: 16, color: Colors.white38)),
          ],
        ),
      );
    }
    if (_isSearching) return const Center(child: CircularProgressIndicator(color: _violet, strokeWidth: 2));
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text('Aucun utilisateur trouvé', style: GoogleFonts.poppins(fontSize: 16, color: Colors.white38)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) => _buildSearchResultTile(_searchResults[index]),
    );
  }

  Widget _buildSearchResultTile(Map<String, dynamic> profile) {
    final photoUrl = profile['photoUrl'] as String? ?? '';
    final name = profile['displayName'] as String? ?? 'Utilisateur';
    final handle = profile['handle'] as String? ?? '';
    final uid = profile['uid'] as String? ?? '';
    final cached = _statusCache[uid];
    final isLoadingStatus = _loadingStatuses.contains(uid);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openProfile(uid),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: _pink.withOpacity(0.3),
                      backgroundImage: photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
                      child: photoUrl.isEmpty
                          ? Text(name[0].toUpperCase(),
                              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))
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
                    // Bouton voir profil
                    GestureDetector(
                      onTap: () => _openProfile(uid),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.person_rounded, color: Colors.white54, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Bouton(s) d'action selon statut
                _buildFriendActionButtons(uid, name, cached, isLoadingStatus),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendActionButtons(
    String uid,
    String name,
    ({FriendshipStatus status, String? requestId})? cached,
    bool isLoading,
  ) {
    if (isLoading || cached == null) {
      return _actionChip(
        label: 'Chargement…',
        icon: Icons.hourglass_empty_rounded,
        color: Colors.grey.shade600,
        onTap: null,
      );
    }

    switch (cached.status) {
      case FriendshipStatus.none:
        return _actionChip(
          label: 'Ajouter en ami',
          icon: Icons.person_add_outlined,
          gradient: [_violet, _pink],
          onTap: () => _sendRequest(uid),
        );

      case FriendshipStatus.pendingSent:
        return _actionChip(
          label: 'En attente… (annuler)',
          icon: Icons.hourglass_top_rounded,
          color: Colors.grey.shade600,
          onTap: cached.requestId != null ? () => _cancelRequest(uid, cached.requestId!) : null,
        );

      case FriendshipStatus.pendingReceived:
        return Row(
          children: [
            Expanded(
              child: _actionChip(
                label: 'Accepter',
                icon: Icons.check_rounded,
                gradient: [_green, const Color(0xFF059669)],
                onTap: cached.requestId != null ? () => _acceptFromSearch(uid, cached.requestId!) : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionChip(
                label: 'Refuser',
                icon: Icons.close_rounded,
                color: Colors.red.shade700,
                onTap: cached.requestId != null ? () async {
                  await FriendService.declineRequest(cached.requestId!);
                  if (mounted) setState(() => _statusCache[uid] = (status: FriendshipStatus.none, requestId: null));
                } : null,
              ),
            ),
          ],
        );

      case FriendshipStatus.friends:
        return GestureDetector(
          onTap: () => _openProfile(uid),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _green.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_rounded, size: 16, color: _green),
                const SizedBox(width: 6),
                Text('Amis — Voir le profil', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _green)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _green),
              ],
            ),
          ),
        );
    }
  }

  Widget _actionChip({
    required String label,
    required IconData icon,
    List<Color>? gradient,
    Color? color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: gradient != null ? LinearGradient(colors: gradient) : null,
          color: gradient == null ? (color ?? Colors.grey.shade700) : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // ─── Onglet Demandes ────────────────────────────────────────────────────

  Widget _buildPendingRequests() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _requestsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _violet, strokeWidth: 2));
        }
        final requests = snapshot.data ?? _pendingRequests;
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mark_email_read_outlined, size: 72, color: Colors.white24),
                const SizedBox(height: 20),
                Text('Aucune demande en attente', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white54)),
                const SizedBox(height: 8),
                Text('Les demandes d\'amis reçues apparaîtront ici', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white30)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: requests.length,
          itemBuilder: (context, index) => _buildPendingRequestTile(requests[index]),
        );
      },
    );
  }

  Widget _buildPendingRequestTile(Map<String, dynamic> request) {
    final requestId = request['requestId'] as String? ?? '';
    final fromUid = request['fromUid'] as String? ?? '';
    final name = request['displayName'] as String? ?? 'Utilisateur';
    final handle = request['handle'] as String? ?? '';
    final photoUrl = request['photoUrl'] as String? ?? '';
    final isProcessing = _processingRequestIds.contains(requestId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_violet.withOpacity(0.12), _pink.withOpacity(0.06)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _violet.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            // Avatar cliquable
            GestureDetector(
              onTap: () => _openProfile(fromUid),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: _violet.withOpacity(0.3),
                backgroundImage: photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
                child: photoUrl.isEmpty
                    ? Text(name[0].toUpperCase(),
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))
                    : null,
              ),
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
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _violet.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Demande d\'ami', style: GoogleFonts.poppins(fontSize: 10, color: _violet, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            // Boutons Accepter / Refuser
            if (isProcessing)
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: _violet, strokeWidth: 2))
            else
              Row(
                children: [
                  // Refuser
                  GestureDetector(
                    onTap: () => _declineRequest(requestId),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.red, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Accepter
                  GestureDetector(
                    onTap: () => _acceptRequest(requestId, fromUid),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_green, Color(0xFF059669)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: _green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
