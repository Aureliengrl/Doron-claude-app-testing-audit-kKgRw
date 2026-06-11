import 'package:flutter/material.dart';
import '/utils/iconly_compat.dart';
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
import '/components/floating_cta_button.dart';
import '/components/floating_cta_button.dart';
import 'create_chat_bottom_sheet.dart';
import '/services/birthday_service.dart'; // F6: suggestions anniversaire
import '/utils/app_tr.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final Color violetColor = const Color(0xFF8A2BE2);

  // BUG 4 FIX: cache des profils participants pour Ã©viter un FutureBuilder
  // par item (rebuild infini + surcharge Firestore Ã  chaque scroll)
  final Map<String, Map<String, dynamic>> _profileCache = {};

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);
    
    if (diff.inDays == 0 && now.day == date.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1 || (diff.inDays == 0 && now.day != date.day)) {
      // 'Hier' / 'Yesterday' â€” needs context, handled in chatTile
      return context.tr('Hier', 'Yesterday');
    } else if (diff.inDays < 7) {
      // Day abbreviations â€” handled per-locale in chatTile
      return context.isEn ? ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][date.weekday-1] : ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'][date.weekday-1];
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
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                // F6: Suggestions de création de groupe
                _buildGroupSuggestions(),
                Expanded(
                  child: _buildChatsList(),
                ),
              ],
            ),
          ),
          StreamBuilder<int>(
            stream: BadgeService.pendingInvitesCountStream,
            initialData: 0,
            builder: (context, snapshot) {
              final pendingCount = snapshot.data ?? 0;
              return FloatingCtaButton(
                title: 'Trouver des amis',
                icon: Icons.person_add,
                badgeCount: pendingCount,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context.push('/friends');
                },
              );
            },
          ),
        ],
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

  // â”€â”€â”€ F6: Suggestions de groupe intelligentes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // GÃ©nÃ¨re des cards de suggestions pour crÃ©er un groupe
  Widget _buildGroupSuggestions() {
    return FutureBuilder<List<Map<String,dynamic>>>(
      future: _loadGroupSuggestions(),
      builder: (ctx, snap) {
        final suggestions = snap.data ?? [];
        if (suggestions.isEmpty) return const SizedBox.shrink();
        return Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              final s = suggestions[i];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _openCreateChatWithSuggestion(s);
                },
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF8A2BE2).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s['emoji'] as String, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(
                        s['title'] as String,
                        style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text('CrÃ©er un groupe',
                        style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<List<Map<String,dynamic>>> _loadGroupSuggestions() async {
    final suggestions = <Map<String,dynamic>>[
      {'emoji': 'ðŸŽ‰', 'title': context.isEn ? 'Group gift' : 'Cadeau commun', 'type': 'gift'},
      {'emoji': 'ðŸ‘¨â€ðŸ‘©â€ðŸ‘§', 'title': context.isEn ? 'Family Group' : 'Groupe Famille', 'type': 'family'},
      {'emoji': 'ðŸ‘«', 'title': 'DÃ©jeuner surprise', 'type': 'surprise'},
    ];

    // Ajouter une suggestion anniversaire si un ami fÃªte son anniv dans 30 j
    try {
      final friendsBdays = await BirthdayService.getFriendsBirthdays();
      final now = DateTime.now();
      for (final friend in friendsBdays) {
        final day = friend['day'] as int;
        final month = friend['month'] as int;
        final thisYear = DateTime(now.year, month, day);
        final diff = thisYear.difference(now).inDays;
        if (diff >= 0 && diff <= 30) {
          suggestions.insert(0, {
            'emoji': 'ðŸŽ‚',
            'title': 'Anniv de ${friend['name']} dans ${diff == 0 ? "aujourd'hui" : '$diff j'}',
            'type': 'birthday',
            'friendName': friend['name'],
          });
          break;
        }
      }
    } catch (_) {}

    return suggestions;
  }

  void _openCreateChatWithSuggestion(Map<String,dynamic> suggestion) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: CreateChatBottomSheet(
            forceGroup: true,
            suggestedGroupName: suggestion['title'] as String,
          ),
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
                context.tr('Messages', 'Messages'),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          // Boutons d'action Ã  droite
          Row(
            children: [
              // Bouton Nouveau Groupe
              Tooltip(
                message: context.tr('Nouveau groupe', 'New group'),
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
                          context.tr('Groupe', 'Group'),
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
              // Bouton Nouveau Message (icÃ´ne)
              IconButton(
                icon: const Icon(IconlyBold.editSquare, color: Colors.white),
                onPressed: () => _openCreateChat(forceGroup: false),
                splashRadius: 24,
                tooltip: context.tr('Nouveau message', 'New message'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatsList() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Center(child: Text(context.tr('Non connectÃ©', 'Not connected'), style: const TextStyle(color: Colors.white)));

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
          return LiquidGlassEmptyStateWidget(
            icon: IconlyLight.chat,
            title: context.tr('Aucun message', 'No messages'),
            subtitle: context.tr(
              'Commencez Ã  discuter avec vos proches ou collaborez sur une liste de cadeaux.',
              'Start chatting with your friends or collaborate on a gift list.',
            ),
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
                          // Avatar â€” FIX C5: initiale affichÃ©e si pas de photo
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: isGroup
                                ? const RadialGradient(
                                    colors: [Color(0xFF8A2BE2), Color(0xFF4A148C)])
                                : photoUrl.isEmpty
                                  ? LinearGradient(
                                      colors: [
                                        HSLColor.fromAHSL(1, (chatName.hashCode % 360).toDouble().abs(), 0.55, 0.45).toColor(),
                                        HSLColor.fromAHSL(1, ((chatName.hashCode + 60) % 360).toDouble().abs(), 0.55, 0.35).toColor(),
                                      ],
                                    )
                                  : null,
                              color: (!isGroup && photoUrl.isNotEmpty) ? null : null,
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
                            child: (!isGroup && photoUrl.isNotEmpty)
                              ? null
                              : Center(
                                  child: isGroup
                                    ? const Icon(IconlyBold.user2, color: Colors.white, size: 26)
                                    : Text(
                                        chatName.isNotEmpty ? chatName[0].toUpperCase() : '?',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                ),
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
                return chatTile(context.tr('Moi', 'Me'), '');
              }

              // Si dÃ©jÃ  en cache â†’ affiche directement (pas de rebuild infini)
              if (_profileCache.containsKey(otherUserId)) {
                final cached = _profileCache[otherUserId]!;
                return chatTile(cached['name'] as String, cached['photo'] as String);
              }

              // Sinon charge une seule fois et met Ã  jour le state
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

