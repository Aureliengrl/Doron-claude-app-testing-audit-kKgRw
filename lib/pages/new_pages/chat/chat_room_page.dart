import 'package:flutter/material.dart';
import '/utils/app_tr.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'dart:convert';
import '/components/liquid_glass.dart';
import '/components/liquid_glass_loader.dart';
import '/components/product_detail_modal.dart';
import '/services/firebase_data_service.dart';
import '/pages/new_pages/occasion_question_page.dart'; // F6: flow questionnaire complet

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

  // Pagination des messages
  int _messageLimit = 50;

  // S15 FIX: cache noms expediteurs pour les messages de groupe
  final Map<String, String> _senderNameCache = {};

  Future<String> _getSenderName(String uid) async {
    if (_senderNameCache.containsKey(uid)) return _senderNameCache[uid]!;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final name = data['first_name'] as String? ?? data['display_name'] as String? ?? 'Utilisateur';
        _senderNameCache[uid] = name;
        return name;
      }
    } catch (_) {}
    _senderNameCache[uid] = 'Utilisateur';
    return 'Utilisateur';
  }

  @override
  void initState() {
    super.initState();
    _updateReadStatus();

    if (widget.chatData == null) {
      FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get().then((snap) {
        if (mounted && snap.exists) {
          setState(() => _chatDocData = snap.data() as Map<String, dynamic>);
          _loadOtherUserIfDirect();
        }
      });
    } else {
      _loadOtherUserIfDirect();
    }

    // â”€â”€ Brancher le stream du document chat pour lire readStatus + typingUsers â”€â”€
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

  /// Returns effective chat data, falling back to loaded _chatDocData when widget.chatData is null.
  Map<String, dynamic>? get _effectiveChatData => widget.chatData ?? (_chatDocData.isNotEmpty ? _chatDocData : null);

  /// Charge le profil de l'interlocuteur pour les chats directs (1-to-1)
  Future<void> _loadOtherUserIfDirect() async {
    final chatData = _effectiveChatData;
    final isGroup = chatData?['isGroup'] == true;
    if (isGroup) return;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;
    final participants = List<String>.from(chatData?['participants'] ?? []);
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
        },
        // BUG 3 FIX: reset unread counter to 0 for current user on open
        'unreadCount': {
          user.uid: 0,
        },
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
    if (timestamp == null) return context.tr('À l\'instant', 'Just now');
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

      // BUG 2 FIX: increment unreadCount for all other participants
      final chatData = _effectiveChatData;
      final participants = List<String>.from(chatData?['participants'] ?? []);
      final Map<String, dynamic> unreadUpdate = {
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      };
      for (final pid in participants) {
        if (pid != currentUser.uid) {
          unreadUpdate['unreadCount.$pid'] = FieldValue.increment(1);
        }
      }
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update(unreadUpdate);
    } catch (e) {
      debugPrint('Erreur d\'envoi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatData = _effectiveChatData;
    final title = chatData?['name'] ?? 'Chat';
    final isGroup = chatData?['isGroup'] ?? true;

    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(title, isGroup),
            // F6: Banner wishlist épinglée (groupes)
            _buildPinnedWishlistBanner(),
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
        ? ((_otherUserData!['first_name'] as String?) ??
           (_otherUserData!['display_name'] as String?) ??
           ((_otherUserData!['email'] as String? ?? '').split('@').first.isNotEmpty
               ? (_otherUserData!['email'] as String).split('@').first
               : null) ??
           title)
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
                      isGroup ? IconlyBold.user2 : IconlyLight.profile,
                      color: Colors.white,
                      size: 20,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // S11 FIX: tapper sur avatar/nom pour acceder au profil de l'interlocuteur
          Expanded(
            child: GestureDetector(
              onTap: !isGroup && _otherUserData != null ? () {
                final participants = List<String>.from(_effectiveChatData?['participants'] ?? []);
                final currentUid = FirebaseAuth.instance.currentUser?.uid;
                final otherUid = participants.firstWhere((id) => id != currentUid, orElse: () => '');
                if (otherUid.isNotEmpty) context.push('/public-profile/$otherUid');
              } : null,
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
                    '${(_effectiveChatData?['participants'] as List?)?.length ?? 0} participants',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  )
                else
                  // S3 FIX: afficher la presence en ligne dans le chat
                  StreamBuilder<DocumentSnapshot>(
                    stream: (() {
                      final participants = List<String>.from(_effectiveChatData?['participants'] ?? []);
                      final currentUid = FirebaseAuth.instance.currentUser?.uid;
                      final otherUid = participants.firstWhere((id) => id != currentUid, orElse: () => '');
                      if (otherUid.isEmpty) return const Stream<DocumentSnapshot>.empty();
                      return FirebaseFirestore.instance.collection('users').doc(otherUid).snapshots();
                    })(),
                    builder: (ctx, snap) {
                      if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();
                      final data = snap.data!.data() as Map<String, dynamic>? ?? {};
                      final isOnline = data['isOnline'] == true;
                      final lastSeen = data['lastSeen'] as Timestamp?;
                      String statusText = '';
                      if (isOnline) {
                        statusText = 'En ligne';
                      } else if (lastSeen != null) {
                        final diff = DateTime.now().difference(lastSeen.toDate());
                        if (diff.inMinutes < 1) statusText = 'Vu a l instant';
                        else if (diff.inMinutes < 60) statusText = 'Vu il y a ${diff.inMinutes} min';
                        else if (diff.inHours < 24) statusText = 'Vu il y a ${diff.inHours}h';
                      }
                      if (statusText.isEmpty) return const SizedBox.shrink();
                      return Row(
                        children: [
                          if (isOnline) Container(
                            width: 7, height: 7,
                            decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                          ),
                          if (isOnline) const SizedBox(width: 4),
                          Text(statusText, style: GoogleFonts.poppins(fontSize: 11, color: isOnline ? const Color(0xFF10B981) : Colors.white38)),
                        ],
                      );
                    },
                  ),
              ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(IconlyLight.infoSquare, color: Colors.white),
            onPressed: () { context.push('/chat-info/' + widget.chatId, extra: _effectiveChatData); },
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    final isGroup = _effectiveChatData?['isGroup'] == true;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(_messageLimit)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LiquidGlassLoader(size: 40));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // S14 FIX: CTA pour le premier message
          final chatData = _effectiveChatData;
          final isGroup = chatData?['isGroup'] == true;
          final otherName = !isGroup && _otherUserData != null
              ? ((_otherUserData!['first_name'] as String?) ?? (_otherUserData!['display_name'] as String?) ?? 'votre ami')
              : (chatData?['name'] as String? ?? 'le groupe');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF8A2BE2).withOpacity(0.15),
                  ),
                  child: const Icon(Icons.waving_hand_rounded, size: 48, color: Color(0xFF8A2BE2)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Dites bonjour a $otherName !',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Envoyez votre premier message',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white38),
                ),
              ],
            ),
          );
        }

        final messages = snapshot.data!.docs;
        final hasMore = messages.length == _messageLimit;

        return ListView.builder(
          reverse: true,
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          itemCount: messages.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            // "Charger plus" button at the top (last index in reversed list)
            if (index == messages.length) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _messageLimit += 50;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: violetColor,
                    ),
                    child: Text(
                      'Charger plus',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: violetColor,
                      ),
                    ),
                  ),
                ),
              );
            }
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
                  // S15 FIX: cache sender name - un seul fetch Firestore par UID (evite N appels par scroll)
                  if (!isMe && isGroup && senderId != null)
                    FutureBuilder<String>(
                      future: _getSenderName(senderId),
                      builder: (context, snap) {
                        if (!snap.hasData) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 4),
                          child: Text(
                            snap.data!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  // S4 FIX: long-press pour copier ou supprimer le message
                  GestureDetector(
                    onLongPress: () {
                      HapticFeedback.heavyImpact();
                      final msgId = messages[index].id;
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A0030),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: const Icon(Icons.copy_rounded, color: Colors.white),
                                title: Text(context.tr('Copier', 'Copy'), style: GoogleFonts.poppins(color: Colors.white)),
                                onTap: () {
                                  Navigator.pop(context);
                                  Clipboard.setData(ClipboardData(text: text));
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Message copie', style: GoogleFonts.poppins()),
                                    backgroundColor: const Color(0xFF8A2BE2),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    duration: const Duration(seconds: 2),
                                  ));
                                },
                              ),
                              if (isMe) ListTile(
                                leading: const Icon(Icons.delete_rounded, color: Colors.red),
                                title: Text(context.tr('Supprimer', 'Delete'), style: GoogleFonts.poppins(color: Colors.red)),
                                onTap: () async {
                                  Navigator.pop(context);
                                  await FirebaseFirestore.instance
                                      .collection('chats')
                                      .doc(widget.chatId)
                                      .collection('messages')
                                      .doc(msgId)
                                      .delete();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Row(
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (messageData['type'] == 'product_card')
                        _buildProductCardMessage(text, isMe)
                      else if (messageData['type'] == 'wishlist_card')
                        _buildWishlistCardMessage(text, isMe)
                      else
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
                            isReadByOthers ? IconlyBold.shieldDone : Icons.check,
                            size: 14,
                            color: isReadByOthers ? const Color(0xFF34D399) : Colors.white.withOpacity(0.4),
                          ),
                          // S8 FIX: "Vu par" dans les groupes
                          if (isGroup && isReadByOthers) ...[
                            const SizedBox(width: 4),
                            Builder(builder: (ctx) {
                              final readStatuses = _chatDocData['readStatus'] as Map<String, dynamic>? ?? {};
                              final readBy = readStatuses.keys.where((k) {
                                if (k == currentUser.uid) return false;
                                final t = readStatuses[k] as Timestamp?;
                                return t != null && timestamp != null && t.compareTo(timestamp) >= 0;
                              }).length;
                              if (readBy == 0) return const SizedBox.shrink();
                              return Text(
                                'Vu $readBy',
                                style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF34D399)),
                              );
                            }),
                          ],
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
                  hintText: context.tr('Écrire un message...', 'Write a message...'),
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
                    IconlyLight.send,
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

  // S6 FIX: affiche le vrai prenom de la personne qui ecrit
  // F6: Banner wishlist épinglée dans le chat groupe
  Widget _buildPinnedWishlistBanner() {
    if (!(_effectiveChatData?['isGroup'] == true)) return const SizedBox.shrink();
    final pinnedId = _effectiveChatData?['pinnedWishlistId'] as String?;
    if (pinnedId == null || pinnedId.isEmpty) {
      // Proposer de créer/associer une liste si c'est un groupe sans wishlist
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF8A2BE2).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8A2BE2).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Text('🎁', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Associer une liste à ce groupe',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
            ),
            GestureDetector(
              onTap: () => _showWishlistPoll(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8A2BE2), Color(0xFFEC4899)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Créer', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    // Wishlist épinglée existante
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('wishlists').doc(pinnedId).get(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final name = snap.data?.get('name') as String? ?? 'Liste partagée';
        return GestureDetector(
          onTap: () => context.push('/wishlist-details/$pinnedId'),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF8A2BE2).withOpacity(0.15), const Color(0xFFEC4899).withOpacity(0.08)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Text('🎁', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(name,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                Text('Voir →',
                  style: GoogleFonts.poppins(color: const Color(0xFFEC4899), fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  // F6: Lance le questionnaire existant complet (OccasionQuestionPage -> MomentTypePage)
  void _showWishlistPoll() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => OccasionQuestionPage(
          onComplete: (String occasion) {
            // Called after OccasionQuestionPage, before MomentTypePage
            // The actual result comes back via Navigator.pop in MomentTypePage
          },
        ),
      ),
    ).then((result) async {
      // result = {'momentType': '...', 'giftTypes': [...], 'occasion': '...'}
      // (retourné par Navigator.pop dans MomentTypePage)
      if (result == null || !mounted) return;

      final occasion = result['occasion'] as String? ?? '';
      final momentType = result['momentType'] as String? ?? '';
      final giftTypes = (result['giftTypes'] as List?)?.join(', ') ?? '';

      // Envoyer un message récapitulatif dans le chat du groupe
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final occasionLabels = {
        'anniversaire': '🎂 Anniversaire',
        'noel': '🎄 Noël',
        'saint-valentin': '💝 Saint-Valentin',
        'mariage': '💍 Mariage',
        'fete': '🥳 Fête',
        'remerciement': '🙏 Remerciement',
        'naissance': '👶 Naissance',
        'diplome': '🎓 Diplôme',
        'surprise': '🎁 Sans occasion',
      };

      final momentLabels = {
        'product': '🎁 Un objet à offrir',
        'experience': '✨ Une expérience',
        'voucher': '🃏 Un bon cadeau',
        'all': '🌟 Tout voir',
      };

      final occasionLabel = occasionLabels[occasion] ?? occasion;
      final momentLabel = momentLabels[momentType] ?? momentType;

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'text': '🎁 Idées cadeaux en cours...\n\n'
            '📅 Occasion : $occasionLabel\n'
            '🛍 Type : $momentLabel\n\n'
            '➡️ Voir les suggestions dans Recherche → Trouver un cadeau',
        'senderId': 'system',
        'type': 'wishlist_poll_result',
        'timestamp': FieldValue.serverTimestamp(),
        'pollData': {
          'occasion': occasion,
          'momentType': momentType,
          'giftTypes': giftTypes,
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🎁 Questionnaire envoyé dans le groupe !',
              style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFF8A2BE2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    });
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
      return DateTime.now().millisecondsSinceEpoch - time < 3000;
    }).toList();
    
    if (othersTyping.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: FutureBuilder<String>(
        future: (() async {
          if (othersTyping.isEmpty) return '';
          final uid = othersTyping.first.key;
          return await _getSenderName(uid);
        })(),
        builder: (ctx, snap) {
          final name = snap.data ?? '';
          final typingText = othersTyping.length == 1
              ? (name.isNotEmpty
                  ? context.tr('$name écrit...', '$name is typing...')
                  : context.tr('Quelqu\'un écrit...', 'Someone is typing...'))
              : context.tr('Plusieurs personnes écrivent...', 'Several people are typing...');
          return Row(
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
                typingText,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ).animate().fadeIn();
        },
      ),
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

  // â”€â”€ Rich card message builders â”€â”€

  Widget _buildProductCardMessage(String jsonText, bool isMe) {
    Map<String, dynamic> product = {};
    try {
      product = json.decode(jsonText) as Map<String, dynamic>;
    } catch (_) {
      product = {'name': jsonText};
    }

    final imageUrl = product['image_url'] as String? ?? product['imageUrl'] as String? ?? product['image'] as String? ?? '';
    final title    = product['name']  as String? ?? product['title']  as String? ?? 'Produit';
    final brand    = product['brand'] as String? ?? '';
    final price    = product['price']?.toString() ?? '';
    final url      = product['url']   as String? ?? product['product_url'] as String? ?? '';

    // Normalise le format pour GlobalProductDetailModal
    final normalizedProduct = {
      'name':  title,
      'brand': brand,
      'price': price,
      'image': imageUrl,
      'url':   url,
      ...product, // conserve les champs supplémentaires
    };

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        GlobalProductDetailModal.show(context, normalizedProduct);
      },
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? violetColor.withOpacity(0.85) : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          border: isMe ? null : Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image produit
            if (imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 150,
                  color: Colors.white.withOpacity(0.05),
                  child: const Center(child: LiquidGlassLoader(size: 24)),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 150,
                  color: Colors.white.withOpacity(0.05),
                  child: const Icon(IconlyLight.image, color: Colors.white38, size: 40),
                ),
              ),
            // Infos produit
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (brand.isNotEmpty)
                    Text(
                      brand.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEC4899),
                        letterSpacing: 1,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (price.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$price â‚¬',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Barre d'action "Voir la fiche"
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.12)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new_rounded,
                      size: 13, color: Colors.white.withOpacity(0.55)),
                  const SizedBox(width: 5),
                  Text(
                    'Voir la fiche produit',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.55),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistCardMessage(String jsonText, bool isMe) {
    Map<String, dynamic> wishlist = {};
    try {
      wishlist = json.decode(jsonText) as Map<String, dynamic>;
    } catch (_) {
      wishlist = {'name': jsonText};
    }
    final emoji = wishlist['emoji'] as String? ?? '\uD83C\uDF81';
    final name = wishlist['name'] as String? ?? 'Wishlist';
    final productCount = wishlist['productCount'] as int? ?? wishlist['product_count'] as int? ?? 0;

    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMe
              ? [const Color(0xFF8A2BE2), const Color(0xFF6A1FB0)]
              : [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isMe ? 20 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 20),
        ),
        border: isMe ? null : Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEC4899).withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  context.isEn ? '$productCount product${productCount != 1 ? 's' : ''}' : '$productCount produit${productCount != 1 ? 's' : ''}' ,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(IconlyBold.bookmark, color: Color(0xFFEC4899), size: 20),
        ],
      ),
    );
  }

  // â”€â”€ Bottom sheet : partager un produit ou une wishlist â”€â”€

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
                _showProductPicker();
              },
            ),
            const SizedBox(height: 12),
            _buildShareOption(
              icon: IconlyBold.bookmark,
              color: const Color(0xFFEC4899),
              label: 'Partager une wishlist',
              sublabel: 'Envoie un album complet',
              onTap: () {
                Navigator.pop(context);
                _showWishlistPicker();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Opens a bottom sheet showing the user's favorite products for selection.
  void _showProductPicker() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: const Color(0xFF1A0030),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Column(
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.card_giftcard_rounded, color: Color(0xFF8A2BE2), size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Choisir un produit',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('favorites')
                    .orderBy('addedAt', descending: true)
                    .limit(50)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: LiquidGlassLoader(size: 36));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'Aucun favori pour le moment',
                        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
                      ),
                    );
                  }
                  final favs = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: favs.length,
                    itemBuilder: (context, index) {
                      final data = favs[index].data() as Map<String, dynamic>;
                      final imageUrl = data['image_url'] as String? ?? data['imageUrl'] as String? ?? '';
                      final name = data['name'] as String? ?? data['title'] as String? ?? 'Produit';
                      final brand = data['brand'] as String? ?? '';
                      final price = data['price']?.toString() ?? '';

                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _sendTypedMessage(
                            type: 'product_card',
                            jsonPayload: {
                              'name': name,
                              'brand': brand,
                              'price': price,
                              'image_url': imageUrl,
                            },
                            previewText: '\uD83D\uDCE6 $name',
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => Container(
                                          width: 56,
                                          height: 56,
                                          color: Colors.white10,
                                          child: const Icon(IconlyLight.image, color: Colors.white30),
                                        ),
                                      )
                                    : Container(
                                        width: 56,
                                        height: 56,
                                        color: Colors.white10,
                                        child: const Icon(IconlyLight.buy, color: Colors.white30),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (brand.isNotEmpty)
                                      Text(
                                        brand.toUpperCase(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFEC4899),
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    Text(
                                      name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (price.isNotEmpty)
                                      Text(
                                        '$price \u20AC',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(IconlyBold.send, color: Color(0xFF8A2BE2), size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens a bottom sheet showing the user's wishlists for selection.
  void _showWishlistPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: const Color(0xFF1A0030),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Column(
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(IconlyBold.bookmark, color: Color(0xFFEC4899), size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Choisir une wishlist',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: FirebaseDataService.loadWishlists(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: LiquidGlassLoader(size: 36));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'Aucune wishlist pour le moment',
                        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
                      ),
                    );
                  }
                  final wishlists = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: wishlists.length,
                    itemBuilder: (context, index) {
                      final wl = wishlists[index];
                      final emoji = wl['emoji'] as String? ?? '\uD83C\uDF81';
                      final name = wl['name'] as String? ?? 'Wishlist';
                      final productCount = wl['productCount'] as int? ?? wl['product_count'] as int? ?? 0;

                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _sendTypedMessage(
                            type: 'wishlist_card',
                            jsonPayload: {
                              'id': wl['id'],
                              'name': name,
                              'emoji': emoji,
                              'productCount': productCount,
                            },
                            previewText: '$emoji $name',
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEC4899).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '$productCount produit${productCount != 1 ? 's' : ''}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(IconlyBold.send, color: Color(0xFFEC4899), size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sends a typed message (product_card or wishlist_card) with JSON payload.
  Future<void> _sendTypedMessage({
    required String type,
    required Map<String, dynamic> jsonPayload,
    required String previewText,
  }) async {
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
        'text': json.encode(jsonPayload),
        'timestamp': FieldValue.serverTimestamp(),
        'type': type,
      });
      // S5 FIX: incrementer unreadCount pour les autres participants (partage produit/wishlist)
      final chatDataForTyped = _effectiveChatData;
      final participantsForTyped = List<String>.from(chatDataForTyped?['participants'] ?? []);
      final Map<String, dynamic> typedUpdate = {
        'lastMessage': previewText,
        'lastMessageTime': FieldValue.serverTimestamp(),
      };
      for (final pid in participantsForTyped) {
        if (pid != currentUser.uid) {
          typedUpdate['unreadCount.$pid'] = FieldValue.increment(1);
        }
      }
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update(typedUpdate);
    } catch (e) {
      debugPrint('_sendTypedMessage: $e');
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





