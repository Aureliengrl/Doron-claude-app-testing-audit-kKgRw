import 'package:flutter/material.dart';
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: const FractionallySizedBox(
                heightFactor: 0.85,
                child: CreateChatBottomSheet(),
              ),
            ),
          );
        },
        backgroundColor: violetColor,
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
            splashRadius: 24,
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
            icon: Icons.chat_bubble_outline,
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
            final unread = chatData['unreadCount']?[currentUser.uid] ?? 0;
            
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
                        'name': chatName, // Pass the resolved name
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
                                isGroup ? Icons.groups : Icons.person,
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
                                          fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w600,
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
                                        color: unread > 0 ? const Color(0xFFEC4899) : Colors.white.withOpacity(0.5),
                                        fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
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
                                    if (unread > 0)
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
              // Extract the OTHER user's ID
              final participants = List<String>.from(chatData['participants'] ?? []);
              final otherUserId = participants.firstWhere(
                (id) => id != currentUser.uid, 
                orElse: () => currentUser.uid
              );
              
              if (otherUserId == currentUser.uid) {
                 return chatTile('Moi', '');
              }
              
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  String name = 'Utilisateur';
                  String photo = '';
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                    name = userData['display_name'] ?? userData['first_name'] ?? 'Utilisateur';
                    photo = userData['photo_url'] ?? '';
                  }
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
