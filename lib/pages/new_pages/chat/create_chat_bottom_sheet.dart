import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/utils/iconly_compat.dart';
import '/services/friend_service.dart';
import '/services/firebase_data_service.dart';
import '/utils/app_tr.dart';

class CreateChatBottomSheet extends StatefulWidget {
  final bool? forceGroup;
  final String? suggestedGroupName;
  final dynamic product;
  final dynamic profile;

  const CreateChatBottomSheet({
    super.key,
    this.forceGroup,
    this.suggestedGroupName,
    this.product,
    this.profile,
  });

  static void show(BuildContext context, {dynamic product, dynamic profile, bool forceGroup = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: CreateChatBottomSheet(
            forceGroup: forceGroup,
            product: product,
            profile: profile,
          ),
        ),
      ),
    );
  }

  @override
  State<CreateChatBottomSheet> createState() => _CreateChatBottomSheetState();
}

class _CreateChatBottomSheetState extends State<CreateChatBottomSheet> {
  static const _violet = Color(0xFF8A2BE2);
  static const _pink = Color(0xFFEC4899);

  bool _isGroup = false;
  final _groupNameCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _friends = [];
  bool _loading = true;
  final Set<String> _selectedUids = {};
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _isGroup = widget.forceGroup == true;
    if (widget.suggestedGroupName != null && widget.suggestedGroupName!.isNotEmpty) {
      _groupNameCtrl.text = widget.suggestedGroupName!;
    }
    _loadFriends();
  }

  @override
  void dispose() {
    _groupNameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    final uid = FirebaseDataService.currentUserId;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final list = await FriendService.getFriends(uid);
      if (mounted) {
        setState(() {
          _friends = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredFriends {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _friends;
    return _friends.where((f) {
      final name = (f['displayName'] ?? f['first_name'] ?? f['name'] ?? '').toString().toLowerCase();
      final username = (f['username'] ?? '').toString().toLowerCase();
      return name.contains(q) || username.contains(q);
    }).toList();
  }

  Future<void> _startDirectChat(Map<String, dynamic> friend) async {
    final myUid = FirebaseDataService.currentUserId;
    final otherUid = friend['uid']?.toString();
    if (myUid == null || otherUid == null) return;

    setState(() => _creating = true);
    HapticFeedback.lightImpact();

    try {
      final chatsRef = FirebaseFirestore.instance.collection('chats');
      // Chercher si un chat direct existe déjà
      final query = await chatsRef
          .where('isGroup', isEqualTo: false)
          .where('participants', arrayContains: myUid)
          .get();

      String? existingChatId;
      for (final doc in query.docs) {
        final parts = (doc.data()['participants'] as List?)?.cast<String>() ?? [];
        if (parts.contains(otherUid)) {
          existingChatId = doc.id;
          break;
        }
      }

      final friendName = (friend['displayName'] ?? friend['first_name'] ?? 'Ami').toString();

      if (existingChatId != null) {
        if (!mounted) return;
        Navigator.pop(context);
        context.push('/chat-room/$existingChatId', extra: {
          'id': existingChatId,
          'name': friendName,
          'isGroup': false,
          'otherUid': otherUid,
        });
        return;
      }

      // Créer un nouveau chat direct
      final newDoc = chatsRef.doc();
      await newDoc.set({
        'id': newDoc.id,
        'isGroup': false,
        'participants': [myUid, otherUid],
        'lastMessage': 'Discussion démarrée 👋',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': myUid,
      });

      if (!mounted) return;
      Navigator.pop(context);
      context.push('/chat-room/${newDoc.id}', extra: {
        'id': newDoc.id,
        'name': friendName,
        'isGroup': false,
        'otherUid': otherUid,
      });
    } catch (e) {
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _createGroupChat() async {
    final myUid = FirebaseDataService.currentUserId;
    if (myUid == null) return;

    final groupName = _groupNameCtrl.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Donnez un nom au groupe !', 'Please enter a group name!')),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Sélectionnez au moins un ami !', 'Select at least one friend!')),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _creating = true);
    HapticFeedback.mediumImpact();

    try {
      final allMembers = [myUid, ..._selectedUids];
      final chatRef = FirebaseFirestore.instance.collection('chats').doc();

      await chatRef.set({
        'id': chatRef.id,
        'name': groupName,
        'isGroup': true,
        'participants': allMembers,
        'lastMessage': 'Groupe créé 🎉',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': myUid,
      });

      await chatRef.collection('messages').add({
        'senderId': 'system',
        'text': '🎉 Groupe "$groupName" créé avec succès !',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      context.push('/chat-room/${chatRef.id}', extra: {
        'id': chatRef.id,
        'name': groupName,
        'isGroup': true,
      });
    } catch (e) {
      if (mounted) {
        setState(() => _creating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = _filteredFriends;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF140D26).withOpacity(0.88),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
          width: 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          const SizedBox(height: 12),

          // En-tête
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isGroup ? 'Nouveau groupe' : 'Nouvelle discussion',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Sélecteur 1-à-1 / Groupe
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _isGroup = false);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: !_isGroup
                              ? const LinearGradient(colors: [_violet, _pink])
                              : null,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Message privé',
                          style: GoogleFonts.poppins(
                            color: !_isGroup ? Colors.white : Colors.white60,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _isGroup = true);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: _isGroup
                              ? const LinearGradient(colors: [_violet, _pink])
                              : null,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Groupe 👥',
                          style: GoogleFonts.poppins(
                            color: _isGroup ? Colors.white : Colors.white60,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Champ de nom de groupe si mode groupe
          if (_isGroup)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _groupNameCtrl,
                cursorColor: _pink,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Nom du groupe (ex: Cadeau Anniversaire 🎁)',
                  hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.group_rounded, color: _pink, size: 20),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _pink, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

          // Barre de recherche d'amis
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              cursorColor: _pink,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rechercher un ami...',
                hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(IconlyLight.search, color: Colors.white54, size: 18),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),

          // Liste des amis
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _pink))
                : friends.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(IconlyLight.addUser, color: Colors.white30, size: 40),
                            const SizedBox(height: 10),
                            Text(
                              _friends.isEmpty
                                  ? 'Vous n\'avez pas encore d\'amis ajoutés.'
                                  : 'Aucun ami trouvé pour cette recherche.',
                              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          final uid = friend['uid']?.toString() ?? '';
                          final name = (friend['displayName'] ?? friend['first_name'] ?? 'Ami').toString();
                          final photoUrl = (friend['avatarUrl'] ?? friend['photo_url'] ?? friend['profile_picture']) as String?;
                          final selected = _selectedUids.contains(uid);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: selected ? _pink.withOpacity(0.12) : Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected ? _pink.withOpacity(0.5) : Colors.white.withOpacity(0.08),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (_isGroup) {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      if (selected) {
                                        _selectedUids.remove(uid);
                                      } else {
                                        _selectedUids.add(uid);
                                      }
                                    });
                                  } else {
                                    _startDirectChat(friend);
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: _violet.withOpacity(0.4),
                                        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                            ? CachedNetworkImageProvider(photoUrl)
                                            : null,
                                        child: (photoUrl == null || photoUrl.isEmpty)
                                            ? Text(
                                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 14),
                                      // Nom
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Action / Checkbox
                                      if (_isGroup)
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: selected ? _pink : Colors.transparent,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: selected ? _pink : Colors.white38,
                                              width: 2,
                                            ),
                                          ),
                                          child: selected
                                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                              : null,
                                        )
                                      else
                                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Bouton CTA Créer le groupe
          if (_isGroup)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_violet, _pink]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _pink.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _creating ? null : _createGroupChat,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _creating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _selectedUids.isEmpty
                                ? 'Créer le groupe'
                                : 'Créer le groupe (${_selectedUids.length}) 🚀',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
