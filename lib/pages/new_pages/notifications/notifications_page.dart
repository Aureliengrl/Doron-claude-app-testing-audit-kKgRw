import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/utils/iconly_compat.dart';
import '/components/liquid_glass.dart';
import '/utils/app_tr.dart';
import '/services/firebase_data_service.dart';

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
    // Utilise FirebaseDataService.currentUserId pour respecter le compte actif
    // (même en cas de multi-compte avec override)
    final uid = FirebaseDataService.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(IconlyLight.arrowLeft2, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.tr('Notifications', 'Notifications'),
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(uid),
            child: Row(
              children: [
                const Icon(Icons.done_all_rounded, color: _violet, size: 16),
                const SizedBox(width: 4),
                Text(
                  context.tr('Tout lire', 'Mark all read'),
                  style: GoogleFonts.poppins(color: _violet, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .doc(uid)
            .collection('items')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: _violet),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(IconlyLight.notification, size: 64, color: Colors.white24),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('Aucune notification', 'No notifications'),
                      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        context.tr(
                          'Les invitations et demandes d\'amis apparaîtront ici.',
                          'Invitations and friend requests will appear here.',
                        ),
                        style: GoogleFonts.poppins(color: Colors.white30, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              return _NotificationTile(
                docId: doc.id,
                uid: uid,
                data: data,
                onTap: () => _handleNotificationTap(data, doc.id, uid),
              );
            },
          );
        },
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
      case 'wishlist_share':
        final wishlistId = data['wishlistId'] as String?;
        if (wishlistId != null) {
          context.push('/wishlist-details/$wishlistId');
        }
        break;
      case 'friend_request_accepted':
        final fromUid = data['fromUid'] as String?;
        if (fromUid != null) {
          context.push('/public-profile/$fromUid');
        } else {
          context.push('/friends');
        }
        break;
      case 'group_payment_due':
      case 'group_payment_declared':
      case 'group_payment_confirmed':
      case 'group_collection_cancelled':
        final collabId = data['collabId'] as String?;
        final chatId = data['chatId'] as String?;
        if (collabId != null && chatId != null) {
          context.push('/group-gift/$collabId', extra: {
            'chatId': chatId,
            'profileName': data['profileName'] ?? '',
          });
        } else if (chatId != null) {
          context.push('/chat-room/$chatId', extra: {'id': chatId});
        }
        break;
      case 'event_reminder':
        context.push('/birthday-calendar');
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
    String title = data['title'] as String? ?? '';
    String body = data['body'] as String? ?? '';

    if (title.isEmpty) {
      switch (type) {
        case 'collab_invite':
          title = context.tr('Invitation à collaborer', 'Collaboration invite');
          if (body.isEmpty) body = context.tr('Quelqu\'un vous a invité à collaborer.', 'Someone invited you to collaborate.');
          break;
        case 'friend_request':
          title = context.tr('Demande d\'ami', 'Friend request');
          if (body.isEmpty) body = context.tr('Quelqu\'un veut être votre ami.', 'Someone wants to be your friend.');
          break;
        case 'message':
          title = context.tr('Nouveau message', 'New message');
          if (body.isEmpty) body = context.tr('Quelqu\'un vous a envoyé un message.', 'Someone sent you a message.');
          break;
        case 'wishlist_share':
          title = context.tr('Wishlist partagée', 'Shared wishlist');
          if (body.isEmpty) body = context.tr('Quelqu\'un a partagé une wishlist avec vous.', 'Someone shared a wishlist with you.');
          break;
        case 'friend_request_accepted':
          title = context.tr('Demande acceptée', 'Request accepted');
          if (body.isEmpty) body = context.tr('Votre demande d\'ami a été acceptée !', 'Your friend request was accepted!');
          break;
        case 'group_payment_due':
          title = context.tr('Cagnotte', 'Group pot');
          if (body.isEmpty) body = context.tr('Une cagnotte a été lancée.', 'A group pot was started.');
          break;
        case 'group_payment_declared':
          title = context.tr('Paiement déclaré', 'Payment declared');
          if (body.isEmpty) body = context.tr('Un paiement a été déclaré comme envoyé.', 'A payment was marked as sent.');
          break;
        case 'group_payment_confirmed':
          title = context.tr('Paiement confirmé', 'Payment confirmed');
          if (body.isEmpty) body = context.tr('Ton paiement a été confirmé.', 'Your payment was confirmed.');
          break;
        case 'group_collection_cancelled':
          title = context.tr('Cagnotte annulée', 'Pot cancelled');
          if (body.isEmpty) body = context.tr('Une cagnotte a été annulée.', 'A group pot was cancelled.');
          break;
        case 'event_reminder':
          title = context.tr('Événement à venir', 'Upcoming event');
          if (body.isEmpty) body = context.tr('Un événement approche.', 'An event is coming up.');
          break;
        default:
          title = context.tr('Nouvelle notification', 'New notification');
      }
    }
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
      case 'wishlist_share':
        icon = IconlyBold.heart;
        iconColor = _pink;
        break;
      case 'friend_request_accepted':
        icon = Icons.how_to_reg_rounded;
        iconColor = const Color(0xFF10B981);
        break;
      case 'group_payment_due':
        icon = Icons.account_balance_wallet_rounded;
        iconColor = const Color(0xFFF59E0B);
        break;
      case 'group_payment_declared':
        icon = Icons.hourglass_top_rounded;
        iconColor = const Color(0xFFF59E0B);
        break;
      case 'group_payment_confirmed':
        icon = Icons.verified_rounded;
        iconColor = const Color(0xFF10B981);
        break;
      case 'group_collection_cancelled':
        icon = Icons.cancel_rounded;
        iconColor = Colors.redAccent;
        break;
      case 'event_reminder':
        icon = IconlyBold.calendar;
        iconColor = const Color(0xFFF59E0B);
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
