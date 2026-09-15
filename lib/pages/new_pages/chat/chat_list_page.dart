import 'package:flutter/material.dart';
import '../../../../services/badge_service.dart';
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
import '/components/app_notch.dart';
import 'create_chat_bottom_sheet.dart';
import '/services/firebase_data_service.dart';
import '/utils/app_tr.dart';

class ChatListPage extends StatefulWidget {
  final bool showBackButton;
  const ChatListPage({super.key, this.showBackButton = true});

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
      // 'Hier' / 'Yesterday' "” needs context, handled in chatTile
      return context.tr('Hier', 'Yesterday');
    } else if (diff.inDays < 7) {
      // Day abbreviations "” handled per-locale in chatTile
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
    final currentUid = FirebaseDataService.currentUserId;

    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: Stack(
        children: [
          SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: currentUid == null || currentUid.isEmpty
                      ? Center(child: Text(context.tr('Non connecté', 'Not connected'), style: const TextStyle(color: Colors.white)))
                      : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('chats')
                              .where('participants', arrayContains: currentUid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: LiquidGlassLoader(size: 40));
                            }

                            final allDocs = snapshot.data?.docs ?? [];
                            return Column(
                              children: [
                                _buildFilterBar(allDocs, currentUid),
                                Expanded(
                                  child: _buildChatsList(allDocs, currentUid),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 76,
            left: 0,
            right: 0,
            child: StreamBuilder<int>(
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
          ),
        ],
      ),
    );
  }

  String _activeFilter = 'all'; // 'all', 'unread', 'groups', 'direct'

  bool _isGroupChat(Map<String, dynamic> data) {
    return data['isGroup'] == true ||
        data['isGroup'] == 'true' ||
        data['type'] == 'group' ||
        data['collabId'] != null ||
        (data['name'] != null && data['name'].toString().startsWith('Cadeaux pour '));
  }

  Widget _buildFilterBar(List<QueryDocumentSnapshot> allChats, String currentUid) {
    final totalCount = allChats.length;
    final unreadCount = allChats.where((c) {
      final d = c.data() as Map<String, dynamic>;
      final dynamic u = d['unreadCount'];
      if (u is Map) {
        final val = u[currentUid];
        return val is num && val > 0;
      }
      return false;
    }).length;
    final groupsCount = allChats.where((c) => _isGroupChat(c.data() as Map<String, dynamic>)).length;
    final directCount = allChats.where((c) => !_isGroupChat(c.data() as Map<String, dynamic>)).length;

    final filters = [
      {'id': 'all', 'label': context.tr('Toutes', 'All'), 'count': totalCount, 'icon': IconlyLight.chat, 'activeIcon': IconlyBold.chat},
      {'id': 'direct', 'label': context.tr('Amis', 'Friends'), 'count': directCount, 'icon': IconlyLight.user2, 'activeIcon': IconlyBold.user2},
      {'id': 'groups', 'label': context.tr('Groupes', 'Groups'), 'count': groupsCount, 'icon': IconlyLight.user3, 'activeIcon': IconlyBold.user3},
      {'id': 'unread', 'label': context.tr('Non lus', 'Unread'), 'count': unreadCount, 'icon': IconlyLight.notification, 'activeIcon': IconlyBold.notification},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: filters.map((f) {
            final filterId = f['id'] as String;
            return _ChatFilterChip(
              key: ValueKey('filter_$filterId'),
              id: filterId,
              label: f['label'] as String,
              count: f['count'] as int,
              icon: f['icon'] as IconData,
              activeIcon: f['activeIcon'] as IconData,
              isSelected: _activeFilter == filterId,
              onSelected: (id) {
                HapticFeedback.selectionClick();
                setState(() {
                  _activeFilter = id;
                });
              },
            );
          }).toList(),
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
    if (!widget.showBackButton) return const SizedBox.shrink();

    return AppNotch(
      title: context.tr('Messages', 'Messages'),
      subtitle: context.tr('Vos discussions et groupes', 'Your chats and groups'),
      trailing: StreamBuilder<QuerySnapshot>(
        stream: (FirebaseDataService.currentUserId ?? FirebaseAuth.instance.currentUser?.uid) != null
          ? FirebaseFirestore.instance
              .collection('notifications')
              .doc(FirebaseDataService.currentUserId ?? FirebaseAuth.instance.currentUser!.uid)
              .collection('items')
              .where('read', isEqualTo: false)
              .snapshots()
          : null,
        builder: (context, snap) {
          final unreadCount = snap.data?.docs.length ?? 0;
          return Stack(
            children: [
              IconButton(
                icon: const Icon(IconlyLight.notification, color: Colors.white, size: 28),
                onPressed: () => context.push('/notifications'),
                tooltip: context.tr('Notifications', 'Notifications'),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 6, right: 6,
                  child: Container(
                    width: 18, height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEC4899),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChatsList(List<QueryDocumentSnapshot> allDocs, String currentUid) {
    // Copie de la liste pour tri
    final chats = List<QueryDocumentSnapshot>.from(allDocs);

    // Trie localement par date du dernier message
    chats.sort((a, b) {
      final timeA = (a.data() as Map<String, dynamic>)['lastMessageTime'] as Timestamp?;
      final timeB = (b.data() as Map<String, dynamic>)['lastMessageTime'] as Timestamp?;
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;
      return timeB.compareTo(timeA);
    });

    // Application du filtre actif
    final List<QueryDocumentSnapshot> filteredChats;
    switch (_activeFilter) {
      case 'unread':
        filteredChats = chats.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final dynamic u = d['unreadCount'];
          if (u is Map) {
            final val = u[currentUid];
            return val is num && val > 0;
          }
          return false;
        }).toList();
        break;
      case 'groups':
        filteredChats = chats.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return _isGroupChat(d);
        }).toList();
        break;
      case 'direct':
        filteredChats = chats.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return !_isGroupChat(d);
        }).toList();
        break;
      case 'all':
      default:
        filteredChats = chats;
        break;
    }

    if (filteredChats.isEmpty) {
      if (_activeFilter == 'groups') {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: violetColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.groups_rounded, color: violetColor, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('Aucun groupe de discussion', 'No group chats'),
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    'Créez un groupe pour organiser un cadeau en commun ou discuter à plusieurs.',
                    'Create a group to organize a joint gift or chat together.',
                  ),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _openCreateChat(forceGroup: true),
                  icon: const Icon(Icons.group_add_rounded, color: Colors.white, size: 18),
                  label: Text(context.tr('Créer un groupe', 'Create a group'), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: violetColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (_activeFilter == 'unread') {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.done_all_rounded, color: Color(0xFF10B981), size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('Tout est à jour !', 'All caught up!'),
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('Vous n\'avez aucun message non lu en attente.', 'You have no unread messages.'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      } else if (_activeFilter == 'direct') {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFEC4899), size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('Aucune discussion directe', 'No direct messages'),
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    'Démarrez une conversation privée avec l\'un de vos proches.',
                    'Start a private chat with one of your loved ones.',
                  ),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _openCreateChat(forceGroup: false),
                  icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 20),
                  label: Text(context.tr('Nouveau message', 'New message'), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC4899),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        return LiquidGlassEmptyStateWidget(
          icon: IconlyLight.chat,
          title: context.tr('Aucun message', 'No messages'),
          subtitle: context.tr(
            'Commencez à discuter avec vos proches ou collaborez sur une liste de cadeaux.',
            'Start chatting with your friends or collaborate on a gift list.',
          ),
        );
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 160),
      itemCount: filteredChats.length,
      itemBuilder: (context, index) {
        final chatDoc = filteredChats[index];
        final chatData = chatDoc.data() as Map<String, dynamic>;
        final chatId = chatDoc.id;
            
            final isGroup = _isGroupChat(chatData);
            final lastMessage = chatData['lastMessage'] as String? ?? '';
            final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;
            
            // Safe parsing of unreadCount map
            final dynamic unreadCountData = chatData['unreadCount'];
            int unread = 0;
            if (unreadCountData is Map) {
              final unreadVal = unreadCountData[currentUid];
              if (unreadVal is num) {
                unread = unreadVal.toInt();
              }
            }

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
                          // Avatar "” FIX C5: initiale affichée si pas de photo
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
                ).animate().fadeIn(duration: const Duration(milliseconds: 150)),
              );
            }

            if (isGroup) {
              return chatTile(chatData['name'] as String? ?? 'Groupe', '');
            } else {
              // BUG 4 FIX: utilise le cache au lieu d'un FutureBuilder par item
              final participants = List<String>.from(chatData['participants'] ?? []);
              final otherUserId = participants.firstWhere(
                (id) => id != currentUid,
                orElse: () => currentUid,
              );

              if (otherUserId == currentUid) {
                return chatTile(context.tr('Moi', 'Me'), '');
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
  }
}

class _ChatFilterChip extends StatefulWidget {
  final String id;
  final String label;
  final int count;
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final ValueChanged<String> onSelected;

  const _ChatFilterChip({
    super.key,
    required this.id,
    required this.label,
    required this.count,
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  State<_ChatFilterChip> createState() => _ChatFilterChipState();
}

class _ChatFilterChipState extends State<_ChatFilterChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final icon = isSelected ? widget.activeIcon : widget.icon;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          setState(() => _isPressed = true);
          widget.onSelected(widget.id);
        },
        onPointerUp: (_) => setState(() => _isPressed = false),
        onPointerCancel: (_) => setState(() => _isPressed = false),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedScale(
            scale: _isPressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF8A2BE2), Color(0xFFEC4899)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFEC4899).withOpacity(0.7)
                      : Colors.white.withOpacity(0.15),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF8A2BE2).withOpacity(0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.white : Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: GoogleFonts.poppins(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (widget.count > 0 || isSelected) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.black.withOpacity(0.3)
                            : (widget.id == 'unread' && widget.count > 0)
                                ? const Color(0xFFEC4899)
                                : Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.count}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

