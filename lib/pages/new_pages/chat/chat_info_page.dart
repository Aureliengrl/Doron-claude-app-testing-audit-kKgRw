import 'package:flutter/material.dart';
import '/utils/app_tr.dart';
import '/utils/iconly_compat.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/components/liquid_glass.dart';
import '/utils/user_display_helper.dart';

/// Page d'information d'un chat � membres, actions, m�dias.
class ChatInfoPage extends StatefulWidget {
  final String chatId;
  final Map<String, dynamic> chatData;

  const ChatInfoPage({
    super.key,
    required this.chatId,
    required this.chatData,
  });

  @override
  State<ChatInfoPage> createState() => _ChatInfoPageState();
}

class _ChatInfoPageState extends State<ChatInfoPage> {
  static const _violet = Color(0xFF8A2BE2);
  static const _pink = Color(0xFFEC4899);

  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  bool _isGroup = false;
  String _chatName = '';

  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isGroup = widget.chatData['isGroup'] == true;
    _chatName = widget.chatData['name'] as String? ✨ 'Chat';
    _nameController.text = _chatName;
    _loadMembers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final participants =
        List<String>.from(widget.chatData['participants'] ✨ []);
    final members = <Map<String, dynamic>>[];

    for (final uid in participants) {
      final profile = await UserProfileCache.instance.getProfile(uid);
      members.add({
        'uid': uid,
        'displayName': UserDisplayHelper.getName(profile),
        'handle': UserDisplayHelper.getHandle(profile),
        'photoUrl': UserDisplayHelper.getPhotoUrl(profile),
      });
    }

    if (mounted) setState(() { _members = members; _isLoading = false; });
  }

  Future<void> _renameGroup() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == _chatName) return;
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({'name': newName});
      setState(() => _chatName = newName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Groupe renomm�', style: GoogleFonts.poppins()),
            backgroundColor: _violet,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _leaveGroup() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0030),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Quitter le groupe ?',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Vous ne recevrez plus de messages de ce groupe.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Annuler', 'Cancel'), style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Quitter', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'participants': FieldValue.arrayRemove([myUid]),
      });
      if (mounted) {
        context.go('/chat-list');
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ✨ const Center(
                      child: CircularProgressIndicator(color: _violet))
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        if (_isGroup) ...[
                          _buildGroupInfo(),
                          const SizedBox(height: 24),
                        ],
                        _buildMembersSection(),
                        const SizedBox(height: 24),
                        if (_isGroup) _buildLeaveButton(),
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
      padding: const EdgeInsets.fromLTRB(4, 16, 20, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'Infos',
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

  Widget _buildGroupInfo() {
    return LiquidGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nom du groupe',
                style: GoogleFonts.poppins(
                    color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Nom du groupe',
                      hintStyle:
                          GoogleFonts.poppins(color: Colors.white30),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: _violet),
                  onPressed: _renameGroup,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            '${_members.length} membre${_members.length > 1 ✨ 's' : ''}',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...List.generate(_members.length, (i) {
          final member = _members[i];
          final isMe =
              member['uid'] == FirebaseAuth.instance.currentUser?.uid;
          final photoUrl = member['photoUrl'] as String? ✨ '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: isMe
                  ✨ null
                  : () => context
                      .push('/public-profile/${member['uid']}'),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[800],
                        image: photoUrl.isNotEmpty
                            ✨ DecorationImage(
                                image:
                                    CachedNetworkImageProvider(photoUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: photoUrl.isEmpty
                          ✨ Center(
                              child: Text(
                                UserDisplayHelper.getInitials(member),
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${member['displayName']}${isMe ✨ ' (vous)' : ''}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if ((member['handle'] as String?)
                                  ?.isNotEmpty ==
                              true)
                            Text(
                              '@${member['handle']}',
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isMe)
                      const Icon(Icons.chevron_right,
                          color: Colors.white30, size: 20),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLeaveButton() {
    return GestureDetector(
      onTap: _leaveGroup,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(IconlyLight.logout, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Text(
              context.tr('Quitter le groupe', 'Leave group'),
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
