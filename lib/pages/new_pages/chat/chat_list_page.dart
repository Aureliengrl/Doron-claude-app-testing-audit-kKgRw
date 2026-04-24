import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/components/liquid_glass.dart';
import '/components/liquid_glass_empty_state_widget.dart';
import '/components/liquid_glass_loader.dart';
import 'create_chat_bottom_sheet.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final Color violetColor = const Color(0xFF8A2BE2);

  // BUG 4 FIX: cache des profils participants pour éviter un FutureBuilder
  // par item (rebuild infini + surcharge Firestore à chaque scroll)
  final Map<String, Map<String, dynamic>> _profileCache = {};

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);
    
    if (diff.inDays == 0 && now.day == date.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1 || (diff.inDays == 0 && now.day != date.day)) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[date.weekday - 1];
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    }
  }

  /// Charge le profil d'un utilisateur depuis le cache ou Firestore.
  Future<Map<String, dynamic>> _getProfile(String uid) async {
    if (_profileCache.containsKey(uid)) return _profileCache[uid]!;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final profile = {
          'name': data['display_name'] ?? data['first_name'] ?? 'Utilisateur',
          'photo': data['photo_url'] ?? data['photoUrl'] ?? '',
        };
        _profileCache[uid] = profile;
        return profile;
      }
    } catch (_) {}
    return {'name': 'Utilisateur', 'photo': ''};
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
              child: _buildChatsList(),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateChat({bool forceGroup = false}) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: CreateChatBottomSheet(forceGroup: forceGroup),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => context.pop(),
                splashRadius: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Messages',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          // Boutons d'action à droite
          Row(
            children: [
              // Bouton Nouveau Groupe
              Tooltip(
                message: 'Nouveau groupe',
                child: GestureDetector(
                  onTap: () => _openCreateChat(forceGroup: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8A2BE2), Color(0xFFEC4899)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8A2BE2).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(IconlyLight.addUser, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Groupe',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Bouton Nouveau Message (icône)
              IconButton(
                icon: const Icon(IconlyBold.editSquare, color: Colors.white),
                onPressed: () => _openCreateChat(forceGroup: false),
                splashRadius: 24,
                tooltip: 'Nouveau message',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatsList() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text('Non connecté', style: TextStyle(color: Colors.white)));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LiquidGlassLoader(size: 40));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const LiquidGlassEmptyStateWidget(
            icon: IconlyLight.chat,
            title: 'Aucun message',
            subtitle: 'Commencez à discuter avec vos proches ou collaborez sur une liste de cadeaux.',
          );
        }

        final chats = snapshot.data!.docs;
        
        // Trie localement par date du dernier message
        chats.sort((a, b) {
          final timeA = (a.data() as Map<String, dynamic>)['lastMessageTime'] as Timestamp?;
          final timeB = (b.data() as Map<String, dynamic>)['lastMessageTime'] as Timestamp?;
          if (timeA == null && timeB == null) return 0;
          if (timeA == null) return 1;
          if (timeB == null) return -1;
          return timeB.compareTo(timeA);
        });

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chatDoc = chats[index];
            final chatData = chatDoc.data() as Map<String, dynamic>;
            final chatId = chatDoc.id;
            
            final isGroup = chatData['isGroup'] == true;
            final lastMessage = chatData['lastMessage'] as String? ?? '';
            final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;
            final unread = (chatData['unreadCount'] as Map?)?.entries
                .firstWhere((e) => e.key == currentUser.uid, orElse: () => MapEntry('', 0))
                .value ?? 0;

            Widget chatTile(String chatName, String photoUrl) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      context.push('/chat-room/$chatId', extra: {
                        ...chatData,
                        'id': chatId,
                        'name': chatName,
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: isGroup ? const RadialGradient(
                                colors: [Color(0xFF8A2BE2), Color(0xFF4A148C)]
                              ) : null,
                              color: isGroup ? null : Colors.grey[800],
                              image: (!isGroup && photoUrl.isNotEmpty) ? DecorationImage(
                                image: CachedNetworkImageProvider(photoUrl),
                                fit: BoxFit.cover,
                              ) : null,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: (isGroup || photoUrl.isEmpty) ? Center(
                              child: Icon(
                                isGroup ? IconlyBold.people : IconlyLight.profile,
                                color: Colors.white,
                                size: 28,
                              ),
                            ) : null,
                          ),
                          const SizedBox(width: 16),
                          // Infos
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        chatName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: (unread as int) > 0 ? FontWeight.bold : FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      _formatTime(lastMessageTime),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: (unread as int) > 0 ? const Color(0xFFEC4899) : Colors.white.withOpacity(0.5),
                                        fontWeight: (unread as int) > 0 ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        lastMessage.isNotEmpty ? lastMessage : 'Nouvelle conversation',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if ((unread as int) > 0)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEC4899),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$unread',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1, end: 0),
              );
            }

            if (isGroup) {
              return chatTile(chatData['name'] as String? ?? 'Groupe', '');
            } else {
              // BUG 4 FIX: utilise le cache au lieu d'un FutureBuilder par item
              final participants = List<String>.from(chatData['participants'] ?? []);
              final otherUserId = participants.firstWhere(
                (id) => id != currentUser.uid,
                orElse: () => currentUser.uid,
              );

              if (otherUserId == currentUser.uid) {
                return chatTile('Moi', '');
              }

              // Si déjà en cache → affiche directement (pas de rebuild infini)
              if (_profileCache.containsKey(otherUserId)) {
                final cached = _profileCache[otherUserId]!;
                return chatTile(cached['name'] as String, cached['photo'] as String);
              }

              // Sinon charge une seule fois et met à jour le state
              return FutureBuilder<Map<String, dynamic>>(
                future: _getProfile(otherUserId),
                builder: (ctx, snap) {
                  final name = snap.data?['name'] as String? ?? 'Utilisateur';
                  final photo = snap.data?['photo'] as String? ?? '';
                  return chatTile(name, photo);
                },
              );
            }
          },
        );
      },
    );
  }
}
