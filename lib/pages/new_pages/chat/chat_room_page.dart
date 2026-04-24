import 'package:flutter/material.dart';
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
    final chatData = _effectiveChatData;
    final title = chatData?['name'] ?? 'Chat';
    final isGroup = chatData?['isGroup'] ?? true;

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
                      isGroup ? IconlyBold.people : IconlyLight.profile,
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
                    '${(_effectiveChatData?['participants'] as List?)?.length ?? 0} participants',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(IconlyLight.infoSquare, color: Colors.white),
            onPressed: () {},
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
          return Center(
            child: Text(
              'Aucun message',
              style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.5)),
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

  // ── Rich card message builders ──

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
                      '$price €',
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
                  '$productCount produit${productCount != 1 ? 's' : ''}',
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
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
        'lastMessage': previewText,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
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
