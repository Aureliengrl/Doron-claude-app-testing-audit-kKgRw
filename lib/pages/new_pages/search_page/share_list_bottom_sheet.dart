import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/components/liquid_glass.dart';
import '/services/friend_service.dart';
import '/services/collaboration_service.dart';
import '/services/user_search_service.dart';

/// Bottom sheet de collaboration — 4 méthodes d'invitation :
/// 1. Recherche sur Doron (ami → direct, non-ami → invitation)
/// 2. Mes amis (accès rapide)
/// 3. Partager le lien (copy / share)
/// 4. Contacts téléphone → SMS natif
class ShareListBottomSheet extends StatefulWidget {
  final Map<String, dynamic> profile;

  const ShareListBottomSheet({super.key, required this.profile});

  @override
  State<ShareListBottomSheet> createState() => _ShareListBottomSheetState();
}

class _ShareListBottomSheetState extends State<ShareListBottomSheet>
    with SingleTickerProviderStateMixin {
  static const _violet = Color(0xFF8A2BE2);
  static const _pink = Color(0xFFEC4899);
  static const _green = Color(0xFF10B981);

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // État global
  bool _isCreatingCollab = false;
  String? _collabId;
  String? _chatId;
  String? _inviteLink;

  // Onglet Recherche Doron
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  // uid → 'added' | 'pending' | null
  final Map<String, String?> _inviteStatus = {};

  // Onglet Amis
  List<Map<String, dynamic>> _friends = [];
  bool _loadingFriends = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initCollab();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ─── Init collaboration ───────────────────────────────────────────────────

  Future<void> _initCollab() async {
    setState(() => _isCreatingCollab = true);
    try {
      final profileId = widget.profile['id']?.toString() ?? '';
      final profileName = widget.profile['name'] as String? ?? 'quelqu\'un';

      final collab = await CollaborationService.createOrGetCollab(
        profileId: profileId,
        profileName: profileName,
      );

      _collabId = collab['collabId'] as String?;
      _chatId = collab['chatId'] as String?;
      final token = collab['inviteToken'] as String? ?? '';
      if (token.isNotEmpty) {
        _inviteLink = CollaborationService.generateInviteLink(token);
      }

      // Charger les amis en parallèle
      _loadFriends();
    } catch (e) {
      debugPrint('❌ ShareListBottomSheet._initCollab: $e');
    } finally {
      if (mounted) setState(() => _isCreatingCollab = false);
    }
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await FriendService.getFriendsStream().first;
      if (mounted) {
        setState(() {
          _friends = friends;
          _loadingFriends = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFriends = false);
    }
  }

  // ─── Recherche Doron ──────────────────────────────────────────────────────

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await UserSearchService.searchUsers(query.trim());
      if (mounted) setState(() { _searchResults = results; _isSearching = false; });
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _inviteUser(Map<String, dynamic> user) async {
    final uid = user['uid'] as String? ?? '';
    if (uid.isEmpty || _collabId == null) return;

    setState(() => _inviteStatus[uid] = 'loading');
    HapticFeedback.lightImpact();

    try {
      final isFriend = await FriendService.isFriend(uid);
      final profileName = widget.profile['name'] as String? ?? 'la liste';

      await CollaborationService.inviteUser(
        collabId: _collabId!,
        toUid: uid,
        profileName: profileName,
        isAlreadyFriend: isFriend,
      );

      if (mounted) {
        setState(() => _inviteStatus[uid] = isFriend ? 'added' : 'pending');
        _showSnack(
          isFriend ? '✅ Ajouté à la collaboration !' : '📬 Invitation envoyée !',
          isFriend ? _green : _violet,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _inviteStatus[uid] = null);
    }
  }

  Future<void> _addFriendDirectly(String uid) async {
    if (_collabId == null) return;
    setState(() => _inviteStatus[uid] = 'loading');
    HapticFeedback.lightImpact();
    try {
      await CollaborationService.addMember(collabId: _collabId!, uid: uid);
      if (mounted) {
        setState(() => _inviteStatus[uid] = 'added');
        _showSnack('✅ Ami ajouté à la collaboration !', _green);
      }
    } catch (_) {
      if (mounted) setState(() => _inviteStatus[uid] = null);
    }
  }

  // ─── Lien d'invitation ────────────────────────────────────────────────────

  void _copyLink() {
    if (_inviteLink == null) return;
    Clipboard.setData(ClipboardData(text: _inviteLink!));
    HapticFeedback.selectionClick();
    _showSnack('🔗 Lien copié !', _violet);
  }

  Future<void> _shareLink() async {
    if (_inviteLink == null) return;
    HapticFeedback.lightImpact();
    final profileName = widget.profile['name'] as String? ?? 'quelqu\'un';
    await Share.share(
      '🎁 Rejoins ma liste de cadeaux pour $profileName sur Doron !\n\n$_inviteLink',
      subject: 'Collaboration Doron',
    );
  }

  // ─── Contacts téléphone ───────────────────────────────────────────────────

  Future<void> _shareViaContacts() async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      _showSnack('Permission contacts refusée', Colors.red);
      return;
    }
    // Partager le lien via SMS/mail natif
    if (_inviteLink == null) return;
    final profileName = widget.profile['name'] as String? ?? 'quelqu\'un';
    await Share.share(
      '🎁 Rejoins ma liste de cadeaux pour $profileName sur Doron !\n\n$_inviteLink',
      subject: 'Invitation Doron',
    );
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

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: LiquidGlassTokens.pageDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              height: 5,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_violet, _pink]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.group_add_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Collaborer',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Inviter des amis sur la liste de ${widget.profile['name'] ?? ''}',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54)),
                    ],
                  ),
                ),
                // Bouton ouvrir le chat si déjà partagé
                if (_chatId != null)
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context, _chatId);
                      context.push('/chat-room/$_chatId', extra: {
                        'name': 'Cadeaux pour ${widget.profile['name']}',
                        'isGroup': true,
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_violet, _pink]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text('Chat', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
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
                labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: '🔍 Doron'),
                  Tab(text: '👥 Amis'),
                  Tab(text: '🔗 Lien'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          if (_isCreatingCollab)
            const Expanded(child: Center(child: CircularProgressIndicator(color: _violet, strokeWidth: 2)))
          else
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDoronSearchTab(),
                  _buildFriendsTab(),
                  _buildLinkTab(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Onglet 1 : Recherche Doron ───────────────────────────────────────────

  Widget _buildDoronSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, color: Colors.white38, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchUsers,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Chercher par @pseudo ou prénom…',
                      hintStyle: GoogleFonts.poppins(color: Colors.white30, fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_isSearching)
          const Expanded(child: Center(child: CircularProgressIndicator(color: _violet, strokeWidth: 2)))
        else if (_searchController.text.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_search_rounded, size: 56, color: Colors.white24),
                  const SizedBox(height: 12),
                  Text('Cherche un utilisateur Doron', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Amis ajoutés directement, autres → invitation', style: GoogleFonts.poppins(color: Colors.white24, fontSize: 12)),
                ],
              ),
            ),
          )
        else if (_searchResults.isEmpty)
          Expanded(
            child: Center(child: Text('Aucun résultat', style: GoogleFonts.poppins(color: Colors.white38))),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _searchResults.length,
              itemBuilder: (ctx, i) => _buildSearchResultTile(_searchResults[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchResultTile(Map<String, dynamic> user) {
    final uid = user['uid'] as String? ?? '';
    final name = user['displayName'] as String? ?? 'Utilisateur';
    final handle = user['handle'] as String? ?? '';
    final photoUrl = user['photoUrl'] as String? ?? '';
    final status = _inviteStatus[uid];
    final isFriend = _friends.any((f) => f['uid'] == uid);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _violet.withOpacity(0.3),
              backgroundImage: photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
              child: photoUrl.isEmpty ? Text(name[0].toUpperCase(), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      if (isFriend) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: _green.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                          child: Text('Ami', style: GoogleFonts.poppins(fontSize: 9, color: _green, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                  if (handle.isNotEmpty)
                    Text('@$handle', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38)),
                ],
              ),
            ),
            _buildInviteButton(uid, status, isFriend),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteButton(String uid, String? status, bool isFriend) {
    if (status == 'loading') {
      return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _violet, strokeWidth: 2));
    }
    if (status == 'added') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: _green.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          const Icon(Icons.check_rounded, color: _green, size: 14),
          const SizedBox(width: 4),
          Text('Ajouté', style: GoogleFonts.poppins(fontSize: 11, color: _green, fontWeight: FontWeight.w600)),
        ]),
      );
    }
    if (status == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
        child: Text('Invité', style: GoogleFonts.poppins(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600)),
      );
    }

    return GestureDetector(
      onTap: () => isFriend ? _addFriendDirectly(uid) : _inviteUser(_searchResults.firstWhere((u) => u['uid'] == uid, orElse: () => {'uid': uid})),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: isFriend ? [_violet, _pink] : [Colors.white12, Colors.white12]),
          borderRadius: BorderRadius.circular(20),
          border: isFriend ? null : Border.all(color: Colors.white30),
        ),
        child: Text(
          isFriend ? 'Ajouter' : 'Inviter',
          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  // ─── Onglet 2 : Amis ──────────────────────────────────────────────────────

  Widget _buildFriendsTab() {
    if (_loadingFriends) {
      return const Center(child: CircularProgressIndicator(color: _violet, strokeWidth: 2));
    }
    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 56, color: Colors.white24),
            const SizedBox(height: 12),
            Text('Aucun ami pour l\'instant', style: GoogleFonts.poppins(color: Colors.white38)),
            const SizedBox(height: 4),
            Text('Cherche des utilisateurs dans l\'onglet Doron', style: GoogleFonts.poppins(color: Colors.white24, fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _friends.length,
      itemBuilder: (ctx, i) {
        final friend = _friends[i];
        final uid = friend['uid'] as String? ?? '';
        final name = friend['displayName'] as String? ?? 'Ami';
        final photoUrl = friend['photoUrl'] as String? ?? '';
        final status = _inviteStatus[uid];

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _violet.withOpacity(0.3),
                  backgroundImage: photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
                  child: photoUrl.isEmpty ? Text(name[0].toUpperCase(), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Text(name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: _green.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                        child: Text('Ami', style: GoogleFonts.poppins(fontSize: 9, color: _green, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                _buildInviteButton(uid, status, true),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Onglet 3 : Lien + Contacts ───────────────────────────────────────────

  Widget _buildLinkTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lien
          Text('Lien d\'invitation', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white54)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _violet.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  _inviteLink ?? 'Génération du lien…',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white60),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _linkButton(
                        icon: Icons.copy_rounded,
                        label: 'Copier',
                        color: _violet,
                        onTap: _copyLink,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _linkButton(
                        icon: Icons.ios_share_rounded,
                        label: 'Partager',
                        color: _pink,
                        onTap: _shareLink,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Note : le lien redirige vers l'App Store si non installé
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ce lien télécharge Doron si nécessaire, puis ajoute la personne directement à la liste.',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.blue.shade200),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Contacts téléphone
          Text('Via mes contacts', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white54)),
          const SizedBox(height: 10),
          _linkButton(
            icon: Icons.contacts_rounded,
            label: 'Envoyer par SMS / mail',
            color: _green,
            onTap: _shareViaContacts,
            fullWidth: true,
          ),

          const SizedBox(height: 8),
          Text(
            'Sélectionnez vos contacts depuis votre téléphone pour envoyer une invitation.',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.white30),
          ),
        ],
      ),
    );
  }

  Widget _linkButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: fullWidth ? 20 : 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
