import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

/// Écran "Félicitations !" partagé, affiché chaque fois qu'une collaboration
/// / liste de cadeaux gagne un nouveau membre — que ce soit parce que le
/// propriétaire l'a ajouté directement, qu'il a accepté une invitation
/// depuis l'app, ou qu'il a rejoint via un lien d'invitation. Un seul
/// visuel et un seul CTA "Rejoindre la discussion" partout dans l'app.
Future<void> showCollabWelcomeDialog(
  BuildContext context, {
  required Widget message,
  String? chatId,
  String chatName = '',
  VoidCallback? onOpenChat,
  VoidCallback? onDismiss,
  String secondaryLabel = 'Fermer',
}) {
  const violet = Color(0xFF8A2BE2);
  const pink = Color(0xFFEC4899);
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dCtx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF130E26),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: pink.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: pink.withOpacity(0.25),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [violet, pink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: pink.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6)),
                ],
              ),
              child: const Center(child: Text('🎉', style: TextStyle(fontSize: 42))),
            ),
            const SizedBox(height: 24),
            Text(
              'Félicitations !',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            message,
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [violet, pink]),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: pink.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4)),
                  ],
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(dCtx);
                    if (onOpenChat != null) {
                      onOpenChat();
                    } else if (chatId != null) {
                      context.push('/chat-room/$chatId', extra: {
                        'id': chatId,
                        'name': chatName,
                        'isGroup': true,
                      });
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Rejoindre la discussion 💬',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () {
                Navigator.pop(dCtx);
                onDismiss?.call();
              },
              child: Text(
                secondaryLabel,
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
