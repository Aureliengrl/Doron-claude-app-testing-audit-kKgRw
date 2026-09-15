import "package:flutter/material.dart";
import "dart:convert";
import "package:flutter/services.dart";
import "package:google_fonts/google_fonts.dart";
import "package:go_router/go_router.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:cached_network_image/cached_network_image.dart";
import "/utils/iconly_compat.dart";
import "/components/liquid_glass.dart";
import "/components/product_detail_modal.dart";
import "/components/cached_image.dart";
import "/services/friend_service.dart";
import "/services/collaboration_service.dart";
import "/services/firebase_data_service.dart";
import "/pages/new_pages/search_page/search_page_model.dart";

/// Page de details et parametres de discussion (style Instagram / DORON)
/// Route : /chat-info/:id
class ChatInfoPage extends StatefulWidget {
  final String chatId;
  final Map<String, dynamic>? chatData;

  const ChatInfoPage({
    super.key,
    required this.chatId,
    this.chatData,
  });

  static const String routeName = "ChatInfo";
  static const String routePath = "/chat-info/:id";

  @override
  State<ChatInfoPage> createState() => _ChatInfoPageState();
}

class _ChatInfoPageState extends State<ChatInfoPage>
    with SingleTickerProviderStateMixin {
  static const _violet = Color(0xFF8A2BE2);
  static const _pink = Color(0xFFEC4899);

  Map<String, dynamic> _chatData = {};
  bool _isLoading = true;
  bool _isMuted = false;

  // 1-to-1 data
  Map<String, dynamic>? _otherUserData;
  String _otherUid = "";

  // Group data
  List<Map<String, dynamic>> _groupMembers = [];
  List<Map<String, dynamic>> _sharedMedia = [];
  List<Map<String, dynamic>> _sharedProducts = [];
  List<Map<String, dynamic>> _myFriends = [];

  late TabController _mediaTabController;

  String get _currentUid => FirebaseDataService.currentUserId ?? "";

  bool get _isGroup => _chatData["isGroup"] == true;

  @override
  void initState() {
    super.initState();
    _mediaTabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _mediaTabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("chats")
          .doc(widget.chatId)
          .get();

      if (doc.exists) {
        _chatData = {"id": doc.id, ...doc.data()!};
      } else if (widget.chatData != null) {
        _chatData = Map<String, dynamic>.from(widget.chatData!);
      }

      final mutedUsers = List<String>.from(_chatData["mutedUsers"] ?? []);
      _isMuted = mutedUsers.contains(_currentUid);

      final participants = List<String>.from(_chatData["participants"] ?? []);

      if (!_isGroup) {
        _otherUid = participants.firstWhere(
          (id) => id != _currentUid,
          orElse: () => "",
        );
        if (_otherUid.isNotEmpty) {
          final userDoc = await FirebaseFirestore.instance
              .collection("users")
              .doc(_otherUid)
              .get();
          if (userDoc.exists) {
            _otherUserData = userDoc.data();
          }
        }
      } else {
        // Charger tous les profils des membres du groupe
        final List<Map<String, dynamic>> members = [];
        for (final uid in participants) {
          final uDoc = await FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .get();
          if (uDoc.exists) {
            members.add({"uid": uid, ...uDoc.data()!});
          }
        }
        _groupMembers = members;
      }

      // Charger les medias et produits partages dans ce chat
      final msgSnap = await FirebaseFirestore.instance
          .collection("chats")
          .doc(widget.chatId)
          .collection("messages")
          .orderBy("timestamp", descending: true)
          .limit(100)
          .get();

      final List<Map<String, dynamic>> media = [];
      final Set<String> seenImageUrls = {};
      final List<Map<String, dynamic>> products = [];
      final Set<String> seenProductKeys = {};

      for (final mDoc in msgSnap.docs) {
        final d = mDoc.data();
        final type = d["type"] as String?;
        final imgUrl = d["imageUrl"] as String?;

        if (imgUrl != null && imgUrl.isNotEmpty && !seenImageUrls.contains(imgUrl)) {
          seenImageUrls.add(imgUrl);
          media.add({"id": mDoc.id, "imageUrl": imgUrl, "timestamp": d["timestamp"]});
        }

        Map<String, dynamic>? prodData;
        if (type == "product_card") {
          try {
            final rawText = d["text"] as String? ?? "{}";
            prodData = json.decode(rawText) as Map<String, dynamic>;
          } catch (_) {}
        } else if (d["product"] != null && d["product"] is Map) {
          prodData = Map<String, dynamic>.from(d["product"] as Map);
        }

        if (prodData != null) {
          final key = (prodData["id"] ?? prodData["name"] ?? prodData["title"] ?? "").toString();
          if (key.isNotEmpty && !seenProductKeys.contains(key)) {
            seenProductKeys.add(key);
            products.add(prodData);
          }
        }
      }

      _sharedMedia = media;
      _sharedProducts = products;

      // Charger ma liste d amis pour l ajout
      final friends = await FriendService.getFriends(_currentUid);
      _myFriends = friends;
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  // Action Mute
  Future<void> _toggleMute() async {
    HapticFeedback.lightImpact();
    final newMuted = !_isMuted;
    setState(() => _isMuted = newMuted);

    try {
      await FirebaseFirestore.instance
          .collection("chats")
          .doc(widget.chatId)
          .set({
        "mutedUsers": newMuted
            ? FieldValue.arrayUnion([_currentUid])
            : FieldValue.arrayRemove([_currentUid]),
      }, SetOptions(merge: true));

      _showSnack(
        newMuted ? "Notifications en sourdine" : "Notifications réactivées",
        _violet,
      );
    } catch (_) {}
  }

  Future<void> _changeGroupNameAndPhoto() async {
    final controller = TextEditingController(
      text: _chatData["name"] as String? ?? "Groupe",
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E0B36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Nom du groupe",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          cursorColor: _pink,
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Entrez un nom de groupe...",
            hintStyle: GoogleFonts.poppins(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _pink.withOpacity(0.5)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _pink),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Annuler", style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _violet,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Enregistrer", style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != _chatData["name"]) {
      setState(() => _chatData["name"] = newName);
      try {
        await FirebaseFirestore.instance
            .collection("chats")
            .doc(widget.chatId)
            .update({"name": newName});
        _showSnack("Nom du groupe mis à jour !", _violet);
      } catch (_) {}
    }
  }

  Future<void> _showAddMemberModal() async {
    HapticFeedback.lightImpact();
    final participants = List<String>.from(_chatData["participants"] ?? []);

    final nonMemberFriends = _myFriends.where((f) {
      final uid = f["uid"] as String? ?? "";
      return !participants.contains(uid);
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bCtx) => Container(
        height: MediaQuery.of(bCtx).size.height * 0.7,
        decoration: BoxDecoration(
          color: const Color(0xFF130E26),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                "Ajouter des amis au groupe",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            if (nonMemberFriends.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      "Tous vos amis sont déjà dans ce groupe !",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: nonMemberFriends.length,
                  itemBuilder: (ctx, idx) {
                    final f = nonMemberFriends[idx];
                    final fUid = f["uid"] as String? ?? "";
                    final fName = f["displayName"] as String? ?? "Ami";
                    final fPhoto = f["photoUrl"] as String? ?? "";

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Row(
                          children: [
                            UserAvatar(photoUrl: fPhoto, name: fName, radius: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                fName,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                Navigator.pop(bCtx);
                                await _addMemberToGroupAndCollab(fUid, fName);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [_violet, _pink]),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "Ajouter",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
      ),
    );
  }

  Future<void> _addMemberToGroupAndCollab(String uid, String name) async {
    HapticFeedback.mediumImpact();
    try {
      // 1. Ajouter au document de chat
      await FirebaseFirestore.instance
          .collection("chats")
          .doc(widget.chatId)
          .update({
        "participants": FieldValue.arrayUnion([uid]),
      });

      // 2. Message systeme dans le chat
      await FirebaseFirestore.instance
          .collection("chats")
          .doc(widget.chatId)
          .collection("messages")
          .add({
        "senderId": "system",
        "text": "👤 " + name + " a rejoint la discussion !",
        "timestamp": FieldValue.serverTimestamp(),
        "type": "system",
      });

      // 3. Si ce chat est lie a une collaboration, ajouter automatiquement le membre a la liste
      final collabSnap = await FirebaseFirestore.instance
          .collection("collaborations")
          .where("chatId", isEqualTo: widget.chatId)
          .limit(1)
          .get();

      if (collabSnap.docs.isNotEmpty) {
        final collabId = collabSnap.docs.first.id;
        await CollaborationService.addMember(
          collabId: collabId,
          uid: uid,
          chatId: widget.chatId,
        );
      }

      _showSnack(name + " a été ajouté au groupe et à la liste partagée ! 🎁", _pink);
      _loadAllData();
    } catch (_) {
      _showSnack("Erreur lors de l ajout", Colors.red);
    }
  }

  Future<void> _leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E0B36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Quitter le groupe",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Voulez-vous vraiment quitter ce groupe et la collaboration ?",
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Annuler", style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("Quitter", style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection("chats")
            .doc(widget.chatId)
            .update({
          "participants": FieldValue.arrayRemove([_currentUid]),
        });

        final collabSnap = await FirebaseFirestore.instance
            .collection("collaborations")
            .where("chatId", isEqualTo: widget.chatId)
            .limit(1)
            .get();

        if (collabSnap.docs.isNotEmpty) {
          final collabDoc = collabSnap.docs.first;
          await collabDoc.reference.update({
            "members": FieldValue.arrayRemove([_currentUid]),
          });
          final profileId = collabDoc.data()['profileId']?.toString();
          if (profileId != null && profileId.isNotEmpty) {
            await FirebaseDataService.deletePerson(profileId);
          }
        }
        SearchPageModel.clearCache();

        if (mounted) {
          context.go("/chat-list");
          _showSnack("Vous avez quitté le groupe.", Colors.grey);
        }
      } catch (_) {
        _showSnack("Erreur lors de la sortie", Colors.red);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: LiquidGlassTokens.pageDark,
        body: const Center(child: CircularProgressIndicator(color: _violet, strokeWidth: 2)),
      );
    }

    final displayName = _isGroup
        ? (_chatData["name"] as String? ?? "Groupe")
        : ((_otherUserData?["display_name"] ?? _otherUserData?["name"] ?? "Ami") as String);

    final handle = !_isGroup ? (_otherUserData?["handle"] as String? ?? "") : "";
    final photoUrl = !_isGroup ? (_otherUserData?["photo_url"] as String? ?? "") : "";

    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── 1. Avatar & Nom ──────────────────────────────────────────────
            const SizedBox(height: 10),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _violet.withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _isGroup
                    ? const GroupAvatar(radius: 45)
                    : UserAvatar(photoUrl: photoUrl, name: displayName, radius: 45),
              ),
            ),
            const SizedBox(height: 14),
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
                "@" + handle,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
              ),
            if (_isGroup)
              GestureDetector(
                onTap: _changeGroupNameAndPhoto,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    "Modifier le nom et l image",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF00D4FF),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // ── 2. Boutons d Action Rapides (3 boutons épurés) ────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!_isGroup)
                    _buildQuickAction(
                      icon: IconlyLight.profile,
                      label: "Profil",
                      onTap: () {
                        if (_otherUid.isNotEmpty) context.push("/public-profile/" + _otherUid);
                      },
                    )
                  else
                    _buildQuickAction(
                      icon: IconlyLight.addUser,
                      label: "Ajouter",
                      onTap: _showAddMemberModal,
                    ),
                  _buildQuickAction(
                    icon: _isMuted ? IconlyBold.volumeOff : IconlyLight.notification,
                    label: _isMuted ? "En sourdine" : "Sourdine",
                    isActive: _isMuted,
                    onTap: _toggleMute,
                  ),
                  _buildQuickAction(
                    icon: IconlyLight.moreCircle,
                    label: "Options",
                    onTap: () => _showOptionsSheet(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── 3. Menu Paramètres (Pour groupes : Membres & Quitter) ─────────
            if (_isGroup)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.people_alt_outlined,
                      iconColor: _violet,
                      title: "Membres",
                      subtitle: "${_groupMembers.length} participants",
                      onTap: () => _showMembersSheet(),
                    ),
                    _buildSettingsTile(
                      icon: Icons.logout_rounded,
                      iconColor: Colors.redAccent,
                      title: "Quitter le groupe",
                      subtitle: "Sortir de la collaboration",
                      titleColor: Colors.redAccent,
                      onTap: _leaveGroup,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

            // ── 4. Onglets Photos & Cadeaux Partages ──────────────────────────
            _buildSharedMediaSection(),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isActive ? _pink.withOpacity(0.2) : Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? _pink : Colors.white.withOpacity(0.15),
              ),
            ),
            child: Center(
              child: Icon(icon, color: isActive ? _pink : Colors.white, size: 22),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isActive ? _pink : Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSharedMediaSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _mediaTabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            indicatorColor: _pink,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: "Photos partagées"),
              Tab(text: "Cadeaux partagés"),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 230,
            child: TabBarView(
              controller: _mediaTabController,
              children: [
                // 1. Photos partagées
                _sharedMedia.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.photo_library_outlined, color: Colors.white24, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              "Aucune photo partagée pour l instant",
                              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        scrollDirection: Axis.horizontal,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: _sharedMedia.length,
                        itemBuilder: (ctx, idx) {
                          final imgUrl = _sharedMedia[idx]["imageUrl"] as String;
                          return GestureDetector(
                            onTap: () {
                              // Plein écran pour la photo
                              showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: CachedNetworkImage(imageUrl: imgUrl, fit: BoxFit.contain),
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: imgUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                // 2. Cadeaux partagés
                _sharedProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.redeem_rounded, color: Colors.white24, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              "Aucun cadeau partagé pour l instant",
                              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _sharedProducts.length,
                        itemBuilder: (ctx, idx) {
                          final p = _sharedProducts[idx];
                          final img = p["image"] as String? ?? p["imageUrl"] as String? ?? "";
                          final name = p["name"] as String? ?? p["title"] as String? ?? "Produit";
                          final price = p["price"] as num? ?? 0.0;

                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () => GlobalProductDetailModal.show(context, p),
                              child: Container(
                                width: 145,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                        child: img.isNotEmpty
                                            ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover, width: double.infinity)
                                            : Container(color: Colors.white12, child: const Icon(Icons.card_giftcard, color: Colors.white38)),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (price > 0)
                                            Text(
                                              "${price.toStringAsFixed(0)} €",
                                              style: GoogleFonts.poppins(color: _pink, fontSize: 11, fontWeight: FontWeight.w600),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMembersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bCtx) => Container(
        height: MediaQuery.of(bCtx).size.height * 0.7,
        decoration: BoxDecoration(
          color: const Color(0xFF130E26),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                "Membres du groupe (${_groupMembers.length})",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _groupMembers.length,
                itemBuilder: (ctx, idx) {
                  final m = _groupMembers[idx];
                  final name = m["displayName"] ?? m["name"] ?? "Membre";
                  final photo = m["photoUrl"] as String? ?? "";
                  final isMe = m["uid"] == _currentUid;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          UserAvatar(photoUrl: photo, name: name as String, radius: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isMe ? "$name (Vous)" : name,
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (!isMe)
                            TextButton(
                              onPressed: () {
                                Navigator.pop(bCtx);
                                context.push("/public-profile/" + m["uid"]);
                              },
                              child: Text("Voir profil", style: GoogleFonts.poppins(color: _pink)),
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
      ),
    );
  }

  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF130E26),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report_problem_outlined, color: Colors.orangeAccent),
              title: Text("Signaler cette discussion", style: GoogleFonts.poppins(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _showSnack("Signalement envoyé aux modérateurs.", _violet);
              },
            ),
            if (!_isGroup)
              ListTile(
                leading: const Icon(Icons.block_rounded, color: Colors.redAccent),
                title: Text("Bloquer cet utilisateur", style: GoogleFonts.poppins(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showSnack("Utilisateur bloqué.", Colors.grey);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: Text("Quitter le groupe", style: GoogleFonts.poppins(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  _leaveGroup();
                },
              ),
          ],
        ),
      ),
    );
  }
}