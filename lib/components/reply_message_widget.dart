import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget de prévisualisation du message en cours de réponse.
/// S'affiche au-dessus de l'input de message dans le chat.
class ReplyMessageWidget extends StatelessWidget {
  final String replyToText;
  final String replyToSenderName;
  final VoidCallback onCancel;

  const ReplyMessageWidget({
    super.key,
    required this.replyToText,
    required this.replyToSenderName,
    required this.onCancel,
  });

  static const _violet = Color(0xFF8A2BE2);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: _violet.withOpacity(0.1),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
          left: BorderSide(color: _violet, width: 3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, color: _violet, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  replyToSenderName,
                  style: GoogleFonts.poppins(
                    color: _violet,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  replyToText,
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white38, size: 18),
            onPressed: onCancel,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32),
          ),
        ],
      ),
    );
  }
}

/// Widget de bulle de réponse dans un message (montre quel message a été répondu).
class ReplyBubbleWidget extends StatelessWidget {
  final String originalText;
  final String originalSenderName;

  const ReplyBubbleWidget({
    super.key,
    required this.originalText,
    required this.originalSenderName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: const Color(0xFF8A2BE2).withOpacity(0.6),
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            originalSenderName,
            style: GoogleFonts.poppins(
              color: const Color(0xFF8A2BE2),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            originalText,
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
