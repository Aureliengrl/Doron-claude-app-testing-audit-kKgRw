import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/components/liquid_glass.dart';
import '/services/friend_service.dart';
import '/services/collaboration_service.dart';

/// Bottom sheet de collaboration — 2 méthodes d'invitation :
/// 1. Amis (accès rapide, ajout direct)
/// 2. Lien (copier / partager → redirige vers App Store si pas installé)
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

  // État global
  bool _isCreatingCollab = false;
  String? _collabId;
  String? _chatId;
  String? _inviteLink;

  // Onglet Amis
  List<Map<String, dynamic>> _friends = [];
  bool _loadingFriends = true;

  // uid → 'added' | 'loading' | null
  final Map<String, String?> _inviteStatus = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initCollab();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Init collaboration ───────────────────────────────────────────────────

  Future<void> _initCollab() async {
    setState(() => _isCreatingCollab = true);

    // Charger les amis EN PARALLÈLE de la collab (pas dépendant)
    _loadFriends();

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
    } catch (e) {
      debugPrint('ShareListBottomSheet._initCollab: $e');
      if (mounted) _showSnack('Impossible de créer la collaboration', Colors.red);
    } finally {
      if (mounted) setState(() => _isCreatingCollab = false);
    }
  }

  Future<void> _loadFriends() async {
    try {
      // Utilise getFriends directement au lieu du stream (évite le bug de chargement infini)
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => _loadingFriends = false);
        return;
      }
      final friends = await FriendService.getFriends(uid);
      if (mounted) {
        setState(() {
          _friends = friends;
          _loadingFriends = false;
        });
      }
    } catch (e) {
      debugPrint('ShareListBottomSheet._loadFriends: $e');
      if (mounted) setState(() => _loadingFriends = false);
    }
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  Future<void> _addFriendToCollab(String uid) async {
    if (_collabId == null) {
      _showSnack('Collaboration indisponible', Colors.red);
      return;
    }
    setState(() => _inviteStatus[uid] = 'loading');
    HapticFeedback.lightImpact();
    try {
      await CollaborationService.addMember(collabId: _collabId!, uid: uid);
      if (mounted) {
        setState(() => _inviteStatus[uid] = 'added');
        _showSnack('Ami ajouté à la collaboration !', _green);
      }
    } catch (_) {
      if (mounted) setState(() => _inviteStatus[uid] = null);
      _showSnack('Erreur lors de l\'ajout', Colors.red);
    }
  }

  void _copyLink() {
    if (_inviteLink == null) {
      _showSnack('Lien en cours de génération...', Colors.orange);
      return;
    }
    Clipboard.setData(ClipboardData(text: _inviteLink!));
    HapticFeedback.selectionClick();
    _showSnack('Lien copié !', _violet);
  }

  Future<void> _shareLink() async {
    if (_inviteLink == null) {
      _showSnack('Lien en cours de génération...', Colors.orange);
      return;
    }
    HapticFeedback.lightImpact();
    final profileName = widget.profile['name'] as String? ?? 'quelqu\'un';
    await Share.share(
      'Rejoins ma liste de cadeaux pour $profileName sur Doron !\n\n$_inviteLink',
      subject: 'Collaboration Doron',
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
      height: MediaQuery.of(context).size.height * 0.75,
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
                      Text('Inviter sur la liste de ${widget.profile['name'] ?? ''}',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54)),
                    ],
                  ),
                ),
                if (_chatId != null)
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
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

          // 2 Tabs : Amis + Lien
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
                labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
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
                  _buildFriendsTab(),
                  _buildLinkTab(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Onglet 1 : Amis ─────────────────────────────────────────────────────

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
            Text('Aucun ami pour l\'instant', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 15)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                context.push('/friends');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_violet, _pink]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Trouver des amis', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
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
                  child: photoUrl.isEmpty
                      ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
                // Bouton action
                if (status == 'loading')
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _violet, strokeWidth: 2))
                else if (status == 'added')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: _green.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.check_rounded, color: _green, size: 14),
                      const SizedBox(width: 4),
                      Text('Ajouté', style: GoogleFonts.poppins(fontSize: 11, color: _green, fontWeight: FontWeight.w600)),
                    ]),
                  )
                else
                  GestureDetector(
                    onTap: () => _addFriendToCollab(uid),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_violet, _pink]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Ajouter', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Onglet 2 : Lien ─────────────────────────────────────────────────────

  Widget _buildLinkTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lien d'invitation
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
                      child: _actionButton(
                        icon: Icons.copy_rounded,
                        label: 'Copier',
                        color: _violet,
                        onTap: _copyLink,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionButton(
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

          const SizedBox(height: 20),

          // Explication
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
                    'Ce lien redirige vers le téléchargement de Doron si l\'app n\'est pas installée, puis ajoute la personne directement à la collaboration.',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.blue.shade200),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
