import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '/components/liquid_glass.dart';
import '/components/liquid_glass_loader.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatId;
  final Map<String, dynamic>? chatData;

  const ChatRoomPage({
    super.key, 
    required this.chatId,
    this.chatData,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Color violetColor = const Color(0xFF8A2BE2);
  
  Timer? _typingTimer;
  bool _isTyping = false;
  Map<String, dynamic> _chatDocData = {};
  StreamSubscription<DocumentSnapshot>? _chatDocSub;
  
  // Pour les chats 1-to-1 : profil de l'interlocuteur
  Map<String, dynamic>? _otherUserData;

  @override
  void initState() {
    super.initState();
    _updateReadStatus();
    _loadOtherUserIfDirect();
    // ── Brancher le stream du document chat pour lire readStatus + typingUsers ──
    _chatDocSub = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .snapshots()
        .listen((snap) {
      if (mounted && snap.exists) {
        setState(() => _chatDocData = snap.data() as Map<String, dynamic>);
      }
    });
  }

  /// Charge le profil de l'interlocuteur pour les chats directs (1-to-1)
  Future<void> _loadOtherUserIfDirect() async {
    final isGroup = widget.chatData?['isGroup'] == true;
    if (isGroup) return;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;
    final participants = List<String>.from(widget.chatData?['participants'] ?? []);
    final otherUid = participants.firstWhere((id) => id != currentUid, orElse: () => '');
    if (otherUid.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(otherUid).get();
      if (mounted && doc.exists) {
        setState(() => _otherUserData = doc.data());
      }
    } catch (_) {}
  }
  
  Future<void> _updateReadStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
        'readStatus': {
          user.uid: FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to update read status: $e');
    }
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _setTypingStatus(true);
    } else if (text.isEmpty && _isTyping) {
      _setTypingStatus(false);
    }

    _typingTimer?.cancel();
    if (text.isNotEmpty) {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _setTypingStatus(false);
      });
    }
  }

  Future<void> _setTypingStatus(bool isTyping) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    if (_isTyping == isTyping) return;
    _isTyping = isTyping;

    try {
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
        'typingUsers': {
          user.uid: isTyping ? DateTime.now().millisecondsSinceEpoch : FieldValue.delete(),
        }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to update typing status: $e');
    }
  }
  
  String _formatMessageTime(Timestamp? timestamp) {
    if (timestamp == null) return 'À l\'instant';
    final date = timestamp.toDate();
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _setTypingStatus(false);
    _typingTimer?.cancel();
    _chatDocSub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    _messageController.clear();
    _setTypingStatus(false);
    _typingTimer?.cancel();
    
    _updateReadStatus();
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    try {
      final messageRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc();
          
      final messageData = {
        'id': messageRef.id,
        'senderId': currentUser.uid,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      };
      
      await messageRef.set(messageData);
      
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Erreur d\'envoi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.chatData?['name'] ?? 'Chat';
    final isGroup = widget.chatData?['isGroup'] ?? true;

    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(title, isGroup),
            Expanded(
              child: _buildMessagesList(),
            ),
            _buildTypingIndicator(),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, bool isGroup) {
    // Pour un chat 1-to-1, utiliser les infos de l'interlocuteur chargé
    final displayName = !isGroup && _otherUserData != null
        ? (_otherUserData!['first_name'] as String? ?? 
           _otherUserData!['display_name'] as String? ?? 
           (_otherUserData!['email'] as String? ?? '').split('@').first.isNotEmpty
               ? (_otherUserData!['email'] as String? ?? '').split('@').first
               : title)
        : title;
    final photoUrl = !isGroup && _otherUserData != null
        ? (_otherUserData!['photo_url'] as String? ?? '')
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: LiquidGlassTokens.pageDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          // Avatar : vrai photo pour 1-to-1, icône groupe sinon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: (!isGroup && photoUrl.isEmpty) ? RadialGradient(
                colors: [const Color(0xFFEC4899), const Color(0xFF9C27B0)],
              ) : (isGroup ? RadialGradient(
                colors: [const Color(0xFF8A2BE2), const Color(0xFF4A148C)],
              ) : null),
              image: (!isGroup && photoUrl.isNotEmpty)
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(photoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (isGroup || photoUrl.isEmpty)
                ? Center(
                    child: Icon(
                      isGroup ? Icons.groups : Icons.person,
                      color: Colors.white,
                      size: 20,
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
                  displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isGroup)
                  Text(
                    '${(widget.chatData?['participants'] as List?)?.length ?? 0} participants',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    final isGroup = widget.chatData?['isGroup'] == true;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LiquidGlassLoader(size: 40));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'Aucun message',
              style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.5)),
            ),
          );
        }

        final messages = snapshot.data!.docs;

        return ListView.builder(
          reverse: true,
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageData = messages[index].data() as Map<String, dynamic>;
            final senderId = messageData['senderId'] as String?;
            final isMe = senderId == currentUser.uid;
            
            final text = messageData['text'] as String? ?? '';
            final timestamp = messageData['timestamp'] as Timestamp?;
            final timeStr = _formatMessageTime(timestamp);
            
            // Check read receipt
            bool isReadByOthers = false;
            if (isMe && timestamp != null && _chatDocData.containsKey('readStatus')) {
              final readStatuses = _chatDocData['readStatus'] as Map<String, dynamic>;
              for (final key in readStatuses.keys) {
                if (key != currentUser.uid) {
                  final otherReadTime = readStatuses[key] as Timestamp?;
                  if (otherReadTime != null && otherReadTime.compareTo(timestamp) >= 0) {
                    isReadByOthers = true;
                    // If at least one other person read it, we mark as read (or for groups, we could require all)
                    break;
                  }
                }
              }
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe && isGroup && senderId != null)
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(senderId).get(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData) return const SizedBox();
                        final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
                        return Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 4),
                          child: Text(
                            userData['first_name'] as String? ??  
                            userData['display_name'] as String? ?? 
                            userData['name'] as String? ?? 
                            'Utilisateur',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                    ),
                  Row(
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? violetColor : Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMe ? 20 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 20),
                          ),
                          border: isMe ? null : Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          text,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: 4,
                      left: isMe ? 0 : 12,
                      right: isMe ? 12 : 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeStr,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            isReadByOthers ? Icons.done_all : Icons.check,
                            size: 14,
                            color: isReadByOthers ? const Color(0xFF34D399) : Colors.white.withOpacity(0.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn().slideY(begin: 0.1, end: 0),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LiquidGlassTokens.pageDark,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
            onPressed: () => _showShareSheet(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Écrire un message...',
                  hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.4)),
                  border: InputBorder.none,
                ),
                onChanged: _onTextChanged,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _messageController,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasText
                      ? const LinearGradient(
                          colors: [Color(0xFF8A2BE2), Color(0xFFEC4899)],
                        )
                      : null,
                  color: hasText ? null : Colors.white12,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.send,
                    color: hasText ? Colors.white : Colors.white30,
                    size: 20,
                  ),
                  onPressed: hasText ? _sendMessage : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    if (_chatDocData.isEmpty || !_chatDocData.containsKey('typingUsers')) return const SizedBox.shrink();
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();
    
    final typingUsers = _chatDocData['typingUsers'] as Map<String, dynamic>;
    final othersTyping = typingUsers.entries.where((e) {
      if (e.key == currentUser.uid) return false;
      final time = e.value as int?;
      if (time == null) return false;
      // if it's older than 3 seconds, ignore
      return DateTime.now().millisecondsSinceEpoch - time < 3000;
    }).toList();
    
    if (othersTyping.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Row(
            children: [
              _buildTypingDot(0),
              const SizedBox(width: 4),
              _buildTypingDot(200),
              const SizedBox(width: 4),
              _buildTypingDot(400),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            othersTyping.length == 1 ? 'Quelqu\'un écrit...' : 'Plusieurs personnes écrivent...',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildTypingDot(int delayMs) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (controller) => controller.repeat())
      .fadeIn(duration: 300.ms, delay: delayMs.ms)
      .then(delay: 200.ms)
      .fadeOut(duration: 300.ms);
  }

  // ── Bottom sheet : partager un produit ou une wishlist ──

  void _showShareSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A0030),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Partager',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _buildShareOption(
              icon: Icons.card_giftcard_rounded,
              color: const Color(0xFF8A2BE2),
              label: 'Partager un produit',
              sublabel: 'Envoie une fiche produit dans le chat',
              onTap: () {
                Navigator.pop(context);
                _sendTextMessage('📦 [Produit partagé] — fonctionnalité bientôt disponible');
              },
            ),
            const SizedBox(height: 12),
            _buildShareOption(
              icon: Icons.bookmark_rounded,
              color: const Color(0xFFEC4899),
              label: 'Partager une wishlist',
              sublabel: 'Envoie un album complet',
              onTap: () {
                Navigator.pop(context);
                _sendTextMessage('📚 [Wishlist partagée] — fonctionnalité bientôt disponible');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTextMessage(String text) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    try {
      final messageRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc();
      await messageRef.set({
        'id': messageRef.id,
        'senderId': currentUser.uid,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'system',
      });
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('_sendTextMessage: $e');
    }
  }

  Widget _buildShareOption({
    required IconData icon,
    required Color color,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Text(sublabel,
                    style: GoogleFonts.poppins(
                        color: Colors.white54, fontSize: 12)),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
          ],
        ),
      ),
    );
  }
}
