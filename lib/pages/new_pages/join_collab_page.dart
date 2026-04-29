import 'package:flutter/material.dart';
import '/utils/app_tr.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '/components/liquid_glass.dart';
import '/services/collaboration_service.dart';

/// Page affichée quand l'utilisateur ouvre un lien d'invitation
/// (deep link : doron.app/join/{token}).
/// Si non connecté → redirigé vers le login (géré par le routeur).
/// Si connecté → rejoint la collaboration directement.
class JoinCollabPage extends StatefulWidget {
  final String token;

  const JoinCollabPage({super.key, required this.token});

  static const String routeName = 'JoinCollabPage';
  static const String routePath = '/join/:token';

  @override
  State<JoinCollabPage> createState() => _JoinCollabPageState();
}

class _JoinCollabPageState extends State<JoinCollabPage> {
  static const _violet = Color(0xFF8A2BE2);
  static const _pink = Color(0xFFEC4899);

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _joinCollab();
  }

  Future<void> _joinCollab() async {
    try {
      final result = await CollaborationService.joinByToken(widget.token);
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
          if (result == null) _error = 'Lien invalide ou expiré.';
        });

        if (result != null) {
          final chatId = result['chatId'] as String?;
          final profileName = result['profileName'] as String? ?? 'la liste';
          final alreadyMember = result['alreadyMember'] as bool? ?? false;

          if (!alreadyMember) {
            _showSnackBar('🎁 Tu as rejoint "$profileName" !');
          }

          // Naviguer vers le chat de groupe après 1s
          if (chatId != null) {
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                context.go('/chat-room/$chatId', extra: {
                  'name': 'Cadeaux pour $profileName',
                  'isGroup': true,
                });
              }
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de rejoindre la liste. Réessaie.';
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      backgroundColor: _violet,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / icône
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_violet, _pink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: _violet.withOpacity(0.5), blurRadius: 30, spreadRadius: 5),
                  ],
                ),
                child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 28),

              if (_isLoading) ...[
                const CircularProgressIndicator(color: _violet, strokeWidth: 2),
                const SizedBox(height: 16),
                Text('Rejoindre la liste…',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text('Connexion à la collaboration en cours',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.white38)),
              ] else if (_error != null) ...[
                const Icon(Icons.link_off_rounded, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Lien invalide', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text(_error!, style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => context.go('/'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_violet, _pink]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Retour à l\'accueil',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ] else ...[
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 56),
                const SizedBox(height: 16),
                Text(
                  _result?['alreadyMember'] == true ? 'Tu es déjà membre !' : '🎉 Bienvenue !',
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ouverture du chat de groupe…',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
