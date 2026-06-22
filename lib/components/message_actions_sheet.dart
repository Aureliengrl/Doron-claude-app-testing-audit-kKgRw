import '/components/aesthetic_bottom_sheet_notch.dart';
import 'package:flutter/material.dart';
import '/utils/iconly_compat.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Bottom sheet d'actions sur un message : répondre, réagir, copier, supprimer.
class MessageActionsSheet extends StatelessWidget {
  final String chatId;
  final String messageId;
  final String messageText;
  final String senderId;
  final Function(String messageId, String text, String senderId)? onReply;

  const MessageActionsSheet({
    super.key,
    required this.chatId,
    required this.messageId,
    required this.messageText,
    required this.senderId,
    this.onReply,
  });

  static const _violet = Color(0xFF8A2BE2);
  static const _quickEmojis = ['❤️', '👍', '😂', '😮', '😢', '🔥'];

  @override
  Widget build(BuildContext context) {
    final isMe = senderId == FirebaseAuth.instance.currentUser?.uid;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A0030),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Quick emoji reactions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _quickEmojis
                .map((emoji) => GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _addReaction(context, emoji);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),

          // Reply
          _buildAction(
            icon: Icons.reply_rounded,
            label: 'Répondre',
            color: _violet,
            onTap: () {
              Navigator.pop(context);
              onReply?.call(messageId, messageText, senderId);
            },
          ),

          // Copy
          _buildAction(
            icon: Icons.copy_rounded,
            label: 'Copier',
            color: Colors.white70,
            onTap: () {
              Clipboard.setData(ClipboardData(text: messageText));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copié', style: GoogleFonts.poppins()),
                  backgroundColor: _violet,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),

          // Delete (only for own messages)
          if (isMe)
            _buildAction(
              icon: IconlyLight.delete,
              label: 'Supprimer',
              color: Colors.red,
              onTap: () => _showDeleteOptions(context),
            ),
        ],
      ),
    );
  }

  Widget _buildAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addReaction(BuildContext context, String emoji) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    Navigator.pop(context);

    try {
      final ref = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);

      // Toggle reaction : si j'ai déjà mis cet emoji, le retirer
      final doc = await ref.get();
      final reactions =
          Map<String, dynamic>.from(doc.data()?['reactions'] ?? {});
      final usersForEmoji =
          List<String>.from(reactions[emoji] ?? []);

      if (usersForEmoji.contains(myUid)) {
        usersForEmoji.remove(myUid);
      } else {
        usersForEmoji.add(myUid);
      }

      if (usersForEmoji.isEmpty) {
        reactions.remove(emoji);
      } else {
        reactions[emoji] = usersForEmoji;
      }

      await ref.update({'reactions': reactions});
    } catch (_) {}
  }

  void _showDeleteOptions(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A0030),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
                    const AestheticBottomSheetNotch(),
            Text('Supprimer ce message ?',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _DeleteOption(
              label: 'Supprimer pour moi',
              icon: IconlyLight.profile,
              onTap: () {
                Navigator.pop(context);
                _deleteForMe();
              },
            ),
            const SizedBox(height: 10),
            _DeleteOption(
              label: 'Supprimer pour tous',
              icon: IconlyBold.delete,
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _deleteForAll();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteForMe() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'deletedFor': FieldValue.arrayUnion([myUid]),
      });
    } catch (_) {}
  }

  Future<void> _deleteForAll() async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'text': 'Message supprimé',
        'type': 'deleted',
        'reactions': {},
      });
    } catch (_) {}
  }
}

class _DeleteOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DeleteOption({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : Colors.white70;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (isDestructive ? Colors.red : Colors.white).withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(label,
                style: GoogleFonts.poppins(
                    color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
