import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dialog demandant la connexion avec liste des bénéfices
class ConnectionRequiredDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onSkip;

  const ConnectionRequiredDialog({
    super.key,
    this.title,
    this.message,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    const violetColor = Color(0xFF8A2BE2);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8A2BE2), Color(0xFFEC4899)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_open,
                color: Colors.white,
                size: 40,
              ),
            ),

            const SizedBox(height: 24),

            // Titre
            Text(
              title ?? 'Connexion requise',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              message ?? 'Crée ton compte pour accéder à cette fonctionnalité',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // Liste des bénéfices
            _buildBenefit(Icons.auto_awesome, 'Des suggestions IA ultra-personnalisées'),
            const SizedBox(height: 12),
            _buildBenefit(Icons.bookmark_outline, 'Sauvegarde tes listes de cadeaux'),
            const SizedBox(height: 12),
            _buildBenefit(Icons.favorite_border, 'Garde tes favoris synchronisés'),
            const SizedBox(height: 12),
            _buildBenefit(Icons.people_outline, 'Crée des listes pour plusieurs personnes'),

            const SizedBox(height: 28),

            // Bouton créer un compte (primaire)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  HapticFeedback.mediumImpact();

                  // Désactiver le mode anonyme
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('anonymous_mode', false);

                  if (context.mounted) {
                    Navigator.pop(context);
                    // Rediriger vers le choix du mode (Classique ou Saint-Valentin)
                    context.go('/mode-choice');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: violetColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 4,
                  shadowColor: violetColor.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.rocket_launch, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Commencer (3 min)',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Bouton j'ai déjà un compte (secondaire)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  HapticFeedback.lightImpact();

                  // Désactiver le mode anonyme
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('anonymous_mode', false);

                  if (context.mounted) {
                    Navigator.pop(context);
                    context.go('/authentification');
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: violetColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: violetColor, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'J\'ai déjà un compte',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            if (onSkip != null) ...[
              const SizedBox(height: 16),
              // Bouton plus tard (tertiaire)
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  onSkip?.call();
                },
                child: Text(
                  'Plus tard',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF8A2BE2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF8A2BE2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF4B5563),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Fonction helper pour afficher le dialog
Future<void> showConnectionRequiredDialog(
  BuildContext context, {
  String? title,
  String? message,
  VoidCallback? onSkip,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => ConnectionRequiredDialog(
      title: title,
      message: message,
      onSkip: onSkip,
    ),
  );
}
