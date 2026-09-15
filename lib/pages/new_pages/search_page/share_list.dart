import 'package:flutter/material.dart';
import '/utils/iconly_compat.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/services/firebase_data_service.dart';
import '/components/liquid_glass.dart';
import '/services/friend_service.dart';
import '/services/collaboration_service.dart';
import '/pages/new_pages/search_page/search_page_model.dart';

/// Bottom sheet de collaboration — 2 méthodes d'invitation :
/// 1. Amis (accès rapide, ajout direct)
/// 2. Lien (copier / partager ? redirige vers App Store si pas installé)
class ShareListBottomSheet extends StatefulWidget {
  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>>? gifts;

  const ShareListBottomSheet({super.key, required this.profile, this.gifts});

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
  bool _collabInitFailed = false;
  String? _collabId;
  String? _chatId;
  String? _inviteLink;

  // Onglet Amis
  List<Map<String, dynamic>> _friends = [];
  bool _loadingFriends = true;

  // uid ? 'added' | 'loading' | null
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

  // --- Init collaboration ---

  Future<void> _initCollab() async {
    setState(() {
      _isCreatingCollab = true;
      _collabInitFailed = false;
    });

    // Charger les amis EN PARALLÈLE de la collab (pas dépendant)
    _loadFriends();

    try {
      // Chercher l'id dans plusieurs champs possibles
      final profileId = widget.profile['id']?.toString() ??
          widget.profile['personId']?.toString() ??
          widget.profile['uid']?.toString() ??
          widget.profile['userId']?.toString() ?? '';
      final profileName = widget.profile['name'] as String? ??
          widget.profile['displayName'] as String? ?? 'quelqu\'un';

      if (profileId.isEmpty) {
        throw Exception('profileId vide — profil invalide');
      }

      final collab = await CollaborationService.createOrGetCollab(
        profileId: profileId,
        profileName: profileName,
        personData: widget.profile,
        gifts: widget.gifts,
      );

      _collabId = collab['collabId'] as String?;
      _chatId = collab['chatId'] as String?;
      final token = collab['inviteToken'] as String? ?? '';
      if (token.isNotEmpty) {
        _inviteLink = CollaborationService.generateInviteLink(token);
      }

      // FIX #4 : notifier immédiatement le parent avec le chatId
      // pour qu'il puisse afficher le badge et le bouton Chat
      if (_chatId != null && mounted) {
        // On ne pop pas ici — le sheet reste ouvert pour inviter des amis
        // Mais on stocke le chatId dans le résultat lors de la fermeture
      }
    } catch (e) {
      debugPrint('ShareListBottomSheet._initCollab: $e');
      if (mounted) setState(() => _collabInitFailed = true);
    } finally {
      if (mounted) setState(() => _isCreatingCollab = false);
    }
  }

  Future<void> _loadFriends() async {
    try {
      // Utilise getFriends directement au lieu du stream (évite le bug de chargement infini)
      final uid = FirebaseDataService.currentUserId;
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

  // --- Actions ---

  Future<void> _addFriendToCollab(String uid) async {
    if (_collabId == null) {
      // Réessayer l'initialisation avant d'abandonner
      await _initCollab();
      if (_collabId == null) return;
    }
    setState(() => _inviteStatus[uid] = 'loading');
    HapticFeedback.lightImpact();
    try {
      await CollaborationService.addMember(collabId: _collabId!, uid: uid);
      // Envoyer notification à l'ami ajouté
      try {
        final myUid = FirebaseDataService.currentUserId;
        final profileName = widget.profile['name'] as String? ?? 'quelqu\'un';
        if (myUid != null) {
          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(uid)
              .collection('items')
              .add({
            'type': 'collab_invite',
            'fromUid': myUid,
            'collabId': _collabId,
            'profileName': profileName,
            'message': 'Tu as été ajouté à la liste de cadeaux pour $profileName !',
            'createdAt': FieldValue.serverTimestamp(),
            'read': false,
          });
        }
      } catch (_) {} // notification non critique
      if (mounted) {
        setState(() => _inviteStatus[uid] = 'added');
        final friendName = _friends.firstWhere((f) => f['uid'] == uid, orElse: () => {})['displayName'] as String? ?? 'Votre ami';
        final profileName = widget.profile['name'] as String? ?? 'ce proche';
        
        _showCollabSuccessDialog(friendName, profileName);
      }
    } catch (e) {
      debugPrint('_addFriendToCollab error: $e');
      if (mounted) setState(() => _inviteStatus[uid] = null);
      _showSnack('Erreur lors de l\'ajout', Colors.red);
    }
  }

  /// FIX C9 - Quitter la collaboration
  Future<void> _leaveCollab() async {
    if (_collabId == null) return;
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Quitter la collaboration ?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        content: Text('Tu ne pourras plus voir la liste ni le chat de ce groupe.',
            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Quitter', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final profileId = widget.profile['id']?.toString();
      if (_collabId != null) {
        await CollaborationService.leaveCollaboration(
          collabId: _collabId!,
          chatId: _chatId,
          profileId: profileId,
        );
      }
      SearchPageModel.clearCache();
      if (mounted) Navigator.pop(context, 'left_collab');
    } catch (e) {
      if (mounted) _showSnack('Erreur lors de la sortie', Colors.red);
    }
  }

  void _showCollabSuccessDialog(String friendName, String profileName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF130E26),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: _pink.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _pink.withOpacity(0.25),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône festive animée
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_violet, _pink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _pink.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🎉', style: TextStyle(fontSize: 42)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Félicitations !',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15, height: 1.4),
                  children: [
                    TextSpan(
                      text: friendName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' a rejoint la collaboration pour '),
                    TextSpan(
                      text: profileName,
                      style: const TextStyle(color: _pink, fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' ! 🎁'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Vous pouvez dès maintenant échanger vos idées cadeaux et organiser vos achats ensemble.',
                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Bouton Principal Grand CTA vers la discussion
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_violet, _pink],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _pink.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(dCtx); // Ferme le dialog
                      Navigator.pop(context, _chatId); // Ferme le bottom sheet avec le chatId
                      if (_chatId != null) {
                        context.push('/chat-room/$_chatId', extra: {
                          'id': _chatId,
                          'name': 'Cadeaux pour $profileName',
                          'isGroup': true,
                        });
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Rejoindre la discussion 💬',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Bouton secondaire pour rester sur le sheet
              TextButton(
                onPressed: () => Navigator.pop(dCtx),
                child: Text(
                  'Inviter d\'autres amis',
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // FIX #4 : quand le sheet se ferme, retourner le chatId au parent
      onPopInvoked: (bool didPop) {
        if (didPop && _chatId != null) {
          // Le résultat est passé via la valeur de retour du showModalBottomSheet
          // On doit utiliser Navigator.pop avec la valeur avant que didPop soit true
          // Le hook onPopInvoked est déclenché APRÈS le pop — donc on utilise
          // une approche différente : override du bouton de fermeture ci-dessous
        }
      },
      child: Container(
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
                  child: const Icon(IconlyLight.addUser, color: Colors.white, size: 20),
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
                      // FIX #4 : retourner le chatId au parent via pop
                      Navigator.pop(context, _chatId);
                      Future.microtask(() => context.push('/chat-room/$_chatId', extra: {
                        'name': 'Cadeaux pour ${widget.profile['name']}',
                        'isGroup': true,
                      }));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_violet, _pink]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(IconlyBold.chat, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text('Chat', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  // FIX C9: Bouton quitter la collaboration
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _leaveCollab,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.withOpacity(0.4)),
                      ),
                      child: const Icon(IconlyLight.logout, color: Colors.red, size: 16),
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
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_alt_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('Amis'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.link_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('Lien'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          if (_isCreatingCollab)
            const Expanded(child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _violet, strokeWidth: 2),
                  SizedBox(height: 12),
                  Text('Préparation de la collaboration…',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ))
          else if (_collabInitFailed)
            Expanded(child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 12),
                  const Text('Échec de la connexion',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _initCollab,
                    icon: const Icon(Icons.refresh, color: _violet),
                    label: const Text('Réessayer',
                      style: TextStyle(color: _violet, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ))
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
      ),
    );
  }

  // --- Onglet 1 : Amis ---

  Widget _buildFriendsTab() {
    if (_loadingFriends) {
      return const Center(child: CircularProgressIndicator(color: _violet, strokeWidth: 2));
    }
    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(IconlyLight.user2, size: 56, color: Colors.white24),
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

  // --- Onglet 2 : Lien ---

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
                        icon: IconlyBold.send,
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
                const Icon(IconlyLight.infoSquare, color: Colors.blue, size: 18),
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

