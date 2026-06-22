import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/utils/iconly_compat.dart';
import '/components/liquid_glass.dart';
import '/utils/app_tr.dart';

/// Page de notifications in-app.
/// Affiche toutes les notifs de la collection notifications/{uid}/items
/// triées par date décroissante.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  static const String routeName = 'NotificationsPage';
  static const String routePath = '/notifications';

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const _violet = Color(0xFF8A2BE2);
  static const _pink = Color(0xFFEC4899);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: LiquidGlassTokens.pageDark,
        body: Center(
          child: Text(
            context.tr('Non connecté', 'Not connected'),
            style: GoogleFonts.poppins(color: Colors.white54),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            backgroundColor: Colors.transparent,
            expandedHeight: 80,
            pinned: true,
            leading: IconButton(
              icon: const Icon(IconlyLight.arrowLeft2, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              // Tout marquer comme lu
              TextButton.icon(
                onPressed: () => _markAllRead(user.uid),
                icon: const Icon(Icons.done_all_rounded, color: _violet, size: 18),
                label: Text(
                  context.tr('Tout lire', 'Mark all read'),
                  style: GoogleFonts.poppins(color: _violet, fontSize: 12),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
              title: Text(
                context.tr('Notifications', 'Notifications'),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Liste des notifications
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(user.uid)
                  .collection('items')
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: _violet),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          const Icon(IconlyLight.notification, size: 64, color: Colors.white24),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('Aucune notification', 'No notifications'),
                            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr(
                              'Les invitations et demandes d\'amis apparaîtront ici.',
                              'Invitations and friend requests will appear here.',
                            ),
                            style: GoogleFonts.poppins(color: Colors.white30, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final doc = docs[i];
                      final data = doc.data() as Map<String, dynamic>;
                      return _NotificationTile(
                        docId: doc.id,
                        uid: user.uid,
                        data: data,
                        onTap: () => _handleNotificationTap(data, doc.id, user.uid),
                      );
                    },
                    childCount: docs.length,
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Future<void> _markAllRead(String uid) async {
    HapticFeedback.lightImpact();
    try {
      final snap = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(uid)
          .collection('items')
          .where('read', isEqualTo: false)
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all read: $e');
    }
  }

  Future<void> _handleNotificationTap(
    Map<String, dynamic> data,
    String docId,
    String uid,
  ) async {
    HapticFeedback.mediumImpact();

    // Marquer comme lu
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(uid)
          .collection('items')
          .doc(docId)
          .update({'read': true});
    } catch (_) {}

    if (!mounted) return;

    final type = data['type'] as String? ?? '';
    switch (type) {
      case 'collab_invite':
        // Naviguer vers la collab (chat ou page de collaboration)
        final chatId = data['chatId'] as String?;
        if (chatId != null) {
          context.push('/chat-room/$chatId', extra: {
            'id': chatId,
            'name': data['profileName'] ?? 'Collaboration',
            'isGroup': true,
          });
        }
        break;
      case 'friend_request':
        // Naviguer vers la page amis
        context.push('/friends');
        break;
      case 'message':
        final chatId = data['chatId'] as String?;
        if (chatId != null) {
          context.push('/chat-room/$chatId', extra: {'id': chatId});
        }
        break;
      default:
        break;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final String docId;
  final String uid;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.docId,
    required this.uid,
    required this.data,
    required this.onTap,
  });

  static const _violet = Color(0xFF8A2BE2);
  static const _pink = Color(0xFFEC4899);

  @override
  Widget build(BuildContext context) {
    final isRead = data['read'] == true;
    final type = data['type'] as String? ?? '';
    final title = data['title'] as String? ?? '';
    final body = data['body'] as String? ?? '';
    final ts = data['createdAt'] as Timestamp?;
    final timeStr = ts != null ? _formatTime(ts.toDate()) : '';

    IconData icon;
    Color iconColor;
    switch (type) {
      case 'collab_invite':
        icon = IconlyBold.addUser;
        iconColor = _violet;
        break;
      case 'friend_request':
        icon = Icons.person_rounded;
        iconColor = _pink;
        break;
      case 'message':
        icon = IconlyBold.chat;
        iconColor = Colors.blue;
        break;
      default:
        icon = IconlyBold.notification;
        iconColor = Colors.amber;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isRead
                  ? Colors.white.withOpacity(0.05)
                  : _violet.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRead
                    ? Colors.white.withOpacity(0.08)
                    : _violet.withOpacity(0.35),
              ),
            ),
            child: Row(
              children: [
                // Icône
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [iconColor.withOpacity(0.8), iconColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),

                // Texte
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _pink,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white54,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (timeStr.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          timeStr,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white30,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Chevron
                const Icon(IconlyLight.arrowRight2, color: Colors.white24, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
