import 'dart:ui';
import 'package:flutter/material.dart';
import '/utils/app_tr.dart';
import '/utils/iconly_compat.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/components/liquid_glass.dart';
import '/components/cached_image.dart';
import '/components/collab_success_dialog.dart';
import '/services/user_search_service.dart';
import '/services/friend_service.dart';
import '/services/collaboration_service.dart';
import '/services/suggestion_service.dart';
import '/utils/app_logger.dart';
import '/components/block_report_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/firebase_data_service.dart';

/// Page Amis "” 3 onglets : Mes amis / Rechercher / Demandes reçues
/// â”€ Chaque résultat de recherche affiche le statut exact (none/pending/friend)
/// â”€ Clic sur profil → /public-profile/:uid (PublicProfilePage)
class FriendsPage extends StatefulWidget {
  final bool showBackButton;
  const FriendsPage({super.key, this.showBackButton = true});

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

  // Historique de recherche
  List<String> _searchHistory = [];
  String get _historyKey => '${FirebaseDataService.currentUserId ?? "guest"}_friends_search_history';

  // Onglet Demandes "” stream temps réel
  Stream<List<Map<String, dynamic>>>? _requestsStream;
  List<Map<String, dynamic>> _pendingRequests = [];
  final Set<String> _processingRequestIds = {};
  // Garde-fou : si aucun des deux flux (demandes / invitations collab) n'a
  // émis après ce délai, on arrête d'afficher le spinner indéfiniment et on
  // affiche l'état vide/le contenu déjà connu à la place.
  bool _requestsLoadTimedOut = false;

  // Invitations de collaboration reçues
  Stream<List<Map<String, dynamic>>>? _collabInvitesStream;
  List<Map<String, dynamic>> _pendingCollabInvites = [];
  final Set<String> _processingCollabIds = {};

  // Suggestions d'amis
  List<Map<String, dynamic>> _suggestions = [];
  bool _suggestionsLoading = false;
  bool _suggestionsLoaded = false;
  final Set<String> _dismissedSuggestions = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Stream temps réel des demandes d'amis reçues
    _requestsStream = FriendService.getPendingRequestsStream();
    // Stream des invitations de collaboration reçues
    _collabInvitesStream = CollaborationService.getMyPendingCollabInvitesStream();
    // Garde-fou anti-spinner-infini : si rien n'est arrivé après 10s, on
    // arrête d'attendre et on affiche l'état vide au lieu de tourner.
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && !_requestsLoadTimedOut) {
        setState(() => _requestsLoadTimedOut = true);
      }
    });
    // Charger l'historique de recherche
    _loadSearchHistory();
    // Précharger les suggestions en arrière-plan
    _loadSuggestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // â”€â”€â”€ Historique de recherche â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_historyKey) ?? [];
      if (mounted) setState(() => _searchHistory = history);
    } catch (_) {}
  }

  Future<void> _saveToHistory(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = List<String>.from(_searchHistory);
      history.remove(query.trim()); // éviter doublon
      history.insert(0, query.trim()); // plus récent en premier
      if (history.length > 10) history.removeLast();
      await prefs.setStringList(_historyKey, history);
      if (mounted) setState(() => _searchHistory = history);
    } catch (_) {}
  }

  Future<void> _removeFromHistory(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = List<String>.from(_searchHistory)..remove(query);
      await prefs.setStringList(_historyKey, history);
      if (mounted) setState(() => _searchHistory = history);
    } catch (_) {}
  }

  Future<void> _clearAllHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      if (mounted) setState(() => _searchHistory = []);
    } catch (_) {}
  }

  // --- Suggestions ---

  Future<void> _loadSuggestions() async {
    if (_suggestionsLoaded || _suggestionsLoading) return;
    setState(() => _suggestionsLoading = true);
    try {
      final suggestions = await SuggestionService.getSuggestions(limit: 15);
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _suggestionsLoading = false;
          _suggestionsLoaded = true;
        });
        // Charger les statuts d'amitié pour les suggestions
        for (final s in suggestions) {
          final uid = s['uid'] as String? ?? '';
          if (uid.isNotEmpty && !_statusCache.containsKey(uid)) {
            _loadFriendshipStatus(uid);
          }
        }
      }
    } catch (e) {
      AppLogger.debug('❌ FriendsPage suggestions: $e', 'Social');
      if (mounted) setState(() => _suggestionsLoading = false);
    }
  }

  // --- Recherche ---

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
        // Sauvegarder dans l'historique si des résultats
        if (results.isNotEmpty) _saveToHistory(query.trim());
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

  // BUG 12 FIX: _loadingStatuses est maintenant modifié dans setState()
  // pour déclencher correctement les rebuilds (affichage/masquage des spinners).
  Future<void> _loadFriendshipStatus(String uid) async {
    if (mounted) setState(() => _loadingStatuses.add(uid));
    try {
      final result = await FriendService.getFriendshipStatus(uid);
      if (mounted) {
        setState(() {
          _statusCache[uid] = result;
          _loadingStatuses.remove(uid);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _statusCache[uid] = (status: FriendshipStatus.none, requestId: null);
          _loadingStatuses.remove(uid);
        });
      }
    }
  }

  // --- Demandes ---
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
      _showSnack(ok ? '✅ Vous êtes maintenant amis !' : '❌ Erreur', ok ? _green : Colors.red);
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

  // --- Invitations de collaboration ---

  Future<void> _acceptCollabInvite(String inviteId) async {
    setState(() => _processingCollabIds.add(inviteId));
    HapticFeedback.mediumImpact();
    try {
      final result = await CollaborationService.acceptInvite(inviteId);
      if (mounted) {
        setState(() {
          _processingCollabIds.remove(inviteId);
          _pendingCollabInvites.removeWhere((i) => i['inviteId'] == inviteId);
        });
        final chatId = result['chatId'] as String?;
        final profileName = result['profileName'] as String? ?? 'la liste';
        // Même écran de félicitations que lorsque le propriétaire ajoute
        // directement un ami, pour une expérience cohérente.
        showCollabWelcomeDialog(
          context,
          message: Text(
            'Tu as rejoint la collaboration pour $profileName ! 🎁',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15, height: 1.4),
          ),
          chatId: chatId,
          chatName: 'Cadeaux pour $profileName',
          secondaryLabel: 'Plus tard',
        );
      }
    } catch (_) {
      if (mounted) setState(() => _processingCollabIds.remove(inviteId));
      _showSnack('❌ Erreur', Colors.red);
    }
  }

  Future<void> _declineCollabInvite(String inviteId) async {
    setState(() => _processingCollabIds.add(inviteId));
    await CollaborationService.declineInvite(inviteId);
    if (mounted) {
      setState(() {
        _processingCollabIds.remove(inviteId);
        _pendingCollabInvites.removeWhere((i) => i['inviteId'] == inviteId);
      });
    }
  }


  // â”€â”€â”€ Actions (recherche) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
        _showSnack('✅ Vous êtes maintenant amis !', _green);
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

  // â”€â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
                  _KeepAliveTab(child: _buildFriendsList()),
                  _KeepAliveTab(child: _buildSearchResults()),
                  _KeepAliveTab(child: _buildPendingRequests()),
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
          Text(context.tr('Amis', 'Friends'), style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
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
                const Icon(IconlyLight.search, color: Colors.white54, size: 20),
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
                      hintText: 'Rechercher par @pseudo ou prénom"¦',
                      hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 14),
                      border: InputBorder.none,
                      filled: false,
                      fillColor: Colors.transparent,
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
        if (snap.hasData && mounted) _pendingRequests = snap.data!;
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
              const Tab(text: 'Amis'),
              const Tab(text: 'Rechercher'),
              Tab(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Text('Demandes', style: GoogleFonts.poppins(fontSize: 13)),
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

  // â”€â”€â”€ Onglet Amis â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
                const Icon(IconlyLight.user2, size: 72, color: Colors.white24),
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
                // S3 FIX: indicateur de presence en ligne sur l'avatar
                GestureDetector(
                  onTap: () => _openProfile(uid),
                  child: Stack(
                    children: [
                      UserAvatar(photoUrl: photoUrl, name: name, radius: 26),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                        builder: (ctx, snap) {
                          if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();
                          final data = snap.data!.data() as Map<String, dynamic>? ?? {};
                          if (data['isOnline'] != true) return const SizedBox.shrink();
                          return Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF0D0D1A), width: 2),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
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
                          const Icon(IconlyLight.user2, size: 12, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          Text(context.tr('Amis', 'Friends'), style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF10B981))),
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
                    child: const Icon(IconlyBold.profile, color: _violet, size: 18),
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
                    child: const Icon(IconlyLight.chat, color: Colors.white, size: 18),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text(context.tr('Retirer cet ami ?', 'Remove this friend?'), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                        content: Text(
                          'Vous ne pourrez plus voir ses wishlists priv\u00e9es ni collaborer avec lui.',
                          style: GoogleFonts.poppins(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(context.tr('Annuler', 'Cancel'), style: GoogleFonts.poppins(color: Colors.grey)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(context.tr('Retirer', 'Remove'), style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await FriendService.removeFriend(uid);
                      // BUG 10 FIX: setState pour update UI imm\u00e9diatement
                      if (mounted) setState(() => _statusCache.remove(uid));
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    // BUG 5 FIX: ic\u00f4ne distincte rouge pour supprimer un ami
                    child: Icon(Icons.person_remove_rounded, color: Colors.red, size: 20),
                  ),
                ),
                const SizedBox(width: 4),
                // Menu bloquer/signaler
                GestureDetector(
                  onTap: () => BlockReportSheet.show(context, uid: uid, handle: handle.isNotEmpty ? handle : name),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(IconlyLight.moreCircle, color: Colors.white38, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // â”€â”€â”€ Onglet Recherche â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) {
      // Pas de recherche active : afficher historique + suggestions
      final hasHistory = _searchHistory.isNotEmpty;

      return ListView(
        children: [
          // Historique si dispo
          if (hasHistory) ...[
            _buildSearchHistoryHeader(),
            ..._searchHistory.map((q) => _buildHistoryTile(q)),
            const SizedBox(height: 16),
          ],
          // Section suggestions
          _buildSuggestionsSection(),
        ],
      );
    }
    if (_isSearching) return const Center(child: CircularProgressIndicator(color: _violet, strokeWidth: 2));
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(IconlyLight.profile, size: 64, color: Colors.white24),
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

  Widget _buildSuggestionsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_violet, _pink]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(IconlyLight.user2, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                'Suggestions pour toi',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const Spacer(),
              if (_suggestionsLoading)
                const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: _violet, strokeWidth: 2))
              else if (_suggestions.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() { _suggestionsLoaded = false; });
                    _loadSuggestions();
                  },
                  child: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white38),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (_suggestionsLoading)
            ...[1, 2, 3].map((_) => _buildSuggestionSkeletonTile()),

          if (!_suggestionsLoading && _suggestions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(IconlyLight.search, size: 48, color: Colors.white24),
                    const SizedBox(height: 12),
                    Text('Cherche par @pseudo ou prénom',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.white38)),
                  ],
                ),
              ),
            ),

          if (!_suggestionsLoading && _suggestions.isNotEmpty)
            ..._suggestions
                .where((s) => !_dismissedSuggestions.contains(s['uid'] as String? ?? ''))
                .map((s) => _buildSuggestionTile(s)),
        ],
      ),
    );
  }

  Widget _buildSuggestionSkeletonTile() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(Map<String, dynamic> suggestion) {
    final uid = suggestion['uid'] as String? ?? '';
    final name = suggestion['displayName'] as String? ?? 'Utilisateur';
    final handle = suggestion['handle'] as String? ?? '';
    final photoUrl = suggestion['photoUrl'] as String? ?? '';
    final source = suggestion['source'] as String? ?? '';
    final mutualCount = suggestion['mutualCount'] as int? ?? 0;

    final statusInfo = _statusCache[uid];
    final status = statusInfo?.status ?? FriendshipStatus.none;
    final requestId = statusInfo?.requestId;

    String sourceLabel;
    IconData sourceIcon;
    if (source.contains('contact')) {
      sourceLabel = 'Dans vos contacts';
      sourceIcon = IconlyLight.user2;
    } else if (mutualCount > 0) {
      sourceLabel = '$mutualCount ami${mutualCount > 1 ? 's' : ''} en commun';
      sourceIcon = IconlyLight.user2;
    } else {
      sourceLabel = 'Suggestion';
      sourceIcon = IconlyLight.star;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _openProfile(uid),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              // Avatar
              UserAvatar(photoUrl: photoUrl, name: name, radius: 24),
              const SizedBox(width: 12),
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    if (handle.isNotEmpty)
                      Text('@$handle', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(sourceIcon, size: 11, color: _violet.withOpacity(0.8)),
                        const SizedBox(width: 4),
                        Text(sourceLabel,
                            style: GoogleFonts.poppins(fontSize: 11, color: _violet.withOpacity(0.8))),
                      ],
                    ),
                  ],
                ),
              ),
              // Action bouton
              if (_loadingStatuses.contains(uid))
                const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: _violet, strokeWidth: 2))
              else
                _buildSuggestionActionBtn(uid, status, requestId),
              const SizedBox(width: 6),
              // Ignorer la suggestion
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _dismissedSuggestions.add(uid));
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 16, color: Colors.white30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionActionBtn(String uid, FriendshipStatus status, String? requestId) {
    switch (status) {
      case FriendshipStatus.friends:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _green.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _green.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_rounded, size: 14, color: _green),
              const SizedBox(width: 4),
              Text(context.tr('Amis', 'Friends'), style: GoogleFonts.poppins(fontSize: 12, color: _green, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      case FriendshipStatus.pendingSent:
      case FriendshipStatus.pendingReceived:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Text('En attente', style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600)),
        );
      default:
        return GestureDetector(
          onTap: () => _sendRequest(uid),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_violet, _pink]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: _violet.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(IconlyLight.addUser, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(context.tr('Ajouter', 'Add'), style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildSearchHistoryHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          const Icon(IconlyLight.timeCircle, size: 18, color: Colors.white54),
          const SizedBox(width: 8),
          Text('Recherches récentes',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white54)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _clearAllHistory();
            },
            child: Text('Effacer tout',
                style: GoogleFonts.poppins(fontSize: 12, color: _violet, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(String query) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _searchController.text = query;
            _lastQuery = '';
            _search(query);
            if (_tabController.index != 1) _tabController.animateTo(1);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(IconlyLight.timeCircle, size: 16, color: Colors.white38),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(query,
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _removeFromHistory(query);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 16, color: Colors.white30),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // BUG 7 FIX: méthode morte supprimée (_buildSearchHistoryList n'était jamais appelée).

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
                    UserAvatar(photoUrl: photoUrl, name: name, radius: 26),
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
                        child: const Icon(IconlyBold.profile, color: Colors.white54, size: 18),
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
        label: 'Chargement"¦',
        icon: Icons.hourglass_empty_rounded,
        color: Colors.grey.shade600,
        onTap: null,
      );
    }

    switch (cached.status) {
      case FriendshipStatus.none:
        return _actionChip(
          label: 'Ajouter en ami',
          icon: IconlyLight.addUser,
          gradient: [_violet, _pink],
          onTap: () => _sendRequest(uid),
        );

      case FriendshipStatus.pendingSent:
        return _actionChip(
          label: 'En attente"¦ (annuler)',
          icon: Icons.hourglass_top_rounded,
          color: Colors.grey.shade600,
          onTap: cached.requestId != null ? () => _cancelRequest(uid, cached.requestId!) : null,
        );

      case FriendshipStatus.pendingReceived:
        return Row(
          children: [
            Expanded(
              child: _actionChip(
                label: context.tr('Accepter', 'Accept'),
                icon: Icons.check_rounded,
                gradient: [_green, const Color(0xFF059669)],
                onTap: cached.requestId != null ? () => _acceptFromSearch(uid, cached.requestId!) : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionChip(
                label: context.tr('Refuser', 'Decline'),
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
                const Icon(IconlyLight.user2, size: 16, color: _green),
                const SizedBox(width: 6),
                Text('Amis • Voir le profil', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _green)),
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

  // ─── Onglet Demandes ─────────────────────────────────────────────────────────

  Widget _buildPendingRequests() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _requestsStream,
      initialData: _pendingRequests.isNotEmpty ? _pendingRequests : null,
      builder: (context, friendSnap) {
        if (friendSnap.hasData && friendSnap.data != null) {
          _pendingRequests = friendSnap.data!;
        }

        // Erreur sur le stream
        if (friendSnap.hasError && _pendingRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.white24),
                const SizedBox(height: 16),
                Text('Impossible de charger les demandes',
                    style: GoogleFonts.poppins(fontSize: 15, color: Colors.white54)),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${friendSnap.error}',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.white30),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() {
                    _requestsStream = FriendService.getPendingRequestsStream();
                    _collabInvitesStream = CollaborationService.getMyPendingCollabInvitesStream();
                  }),
                  child: Text('Réessayer', style: GoogleFonts.poppins(color: _violet)),
                ),
              ],
            ),
          );
        }

        // Stream collab séparé
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _collabInvitesStream,
          initialData: _pendingCollabInvites.isNotEmpty ? _pendingCollabInvites : null,
          builder: (context, collabSnap) {
            if (collabSnap.hasData && collabSnap.data != null) {
              _pendingCollabInvites = collabSnap.data!;
            }

            final friendRequests = friendSnap.data ?? _pendingRequests;
            final collabInvites = collabSnap.data ?? _pendingCollabInvites;

            // On n'affiche le spinner que tant qu'AUCUN des deux flux n'a encore
            // émis (état initial). Dès que l'un des deux répond, on montre son
            // contenu (vide ou non) plutôt que de rester bloqué en chargement
            // en attendant l'autre indéfiniment.
            final stillWaitingForBoth =
                friendSnap.connectionState == ConnectionState.waiting &&
                collabSnap.connectionState == ConnectionState.waiting &&
                friendRequests.isEmpty &&
                collabInvites.isEmpty;
            if (stillWaitingForBoth && !_requestsLoadTimedOut) {
              return const Center(child: CircularProgressIndicator(color: _violet, strokeWidth: 2));
            }

            if (friendRequests.isEmpty && collabInvites.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(IconlyLight.notification, size: 72, color: Colors.white24),
                    const SizedBox(height: 20),
                    Text('Aucune demande en attente', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white54)),
                    const SizedBox(height: 8),
                    Text('Les demandes d\'amis et collaborations apparaîtront ici', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white30)),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // Invitations de collaboration
                if (collabInvites.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.card_giftcard_rounded, size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 6),
                        Text('Invitations de collaboration',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFF59E0B))),
                      ],
                    ),
                  ),
                  ...collabInvites.map((invite) => _buildCollabInviteTile(invite)),
                  if (friendRequests.isNotEmpty) const SizedBox(height: 12),
                ],
                // Demandes d'amis
                if (friendRequests.isNotEmpty) ...[
                  if (collabInvites.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(IconlyLight.addUser, size: 14, color: Colors.white54),
                          const SizedBox(width: 6),
                          Text('Demandes d\'amis',
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white54)),
                        ],
                      ),
                    ),
                  ...friendRequests.map((req) => _buildPendingRequestTile(req)),
                ],
              ],
            );
          },
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
              child: UserAvatar(photoUrl: photoUrl, name: name, radius: 26),
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

  Widget _buildCollabInviteTile(Map<String, dynamic> invite) {
    final inviteId = invite['inviteId'] as String? ?? '';
    final fromName = invite['fromName'] as String? ?? 'Quelqu\'un';
    final fromPhotoUrl = invite['fromPhotoUrl'] as String? ?? '';
    final profileName = invite['profileName'] as String? ?? 'une liste';
    final isProcessing = _processingCollabIds.contains(inviteId);
    const amber = Color(0xFFF59E0B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [amber.withOpacity(0.1), amber.withOpacity(0.04)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: amber.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            UserAvatar(photoUrl: fromPhotoUrl, name: fromName, radius: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fromName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('t\'invite à collaborer sur', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white54)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.card_giftcard_rounded, size: 12, color: amber),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(profileName,
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: amber),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isProcessing)
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: amber, strokeWidth: 2))
            else
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _declineCollabInvite(inviteId),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.red, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _acceptCollabInvite(inviteId),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: amber.withOpacity(0.5)),
                      ),
                      child: const Icon(Icons.check_rounded, color: amber, size: 18),
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

class _KeepAliveTab extends StatefulWidget {
  final Widget child;
  const _KeepAliveTab({required this.child});

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}



