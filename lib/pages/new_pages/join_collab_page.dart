import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '/components/liquid_glass.dart';
import '/components/collab_success_dialog.dart';
import '/services/collaboration_service.dart';

/// Page affichée quand l'utilisateur ouvre un lien d'invitation
/// (deep link : doron.app/join/{token}).
///
/// Flow : la route est protégée par `requireAuth: true` (voir nav.dart), donc
/// l'utilisateur est déjà connecté à ce stade (sinon il est redirigé vers le
/// login puis ramené ici). On lit ensuite les infos du lien SANS rejoindre
/// (aperçu), on demande confirmation ("veux-tu rejoindre la liste de X ?"),
/// et seulement après acceptation on rejoint réellement la collaboration —
/// avec le même écran de félicitations que lorsqu'un ami nous ajoute.
class JoinCollabPage extends StatefulWidget {
  final String token;

  const JoinCollabPage({super.key, required this.token});

  static const String routeName = 'JoinCollabPage';
  static const String routePath = '/join/:token';

  @override
  State<JoinCollabPage> createState() => _JoinCollabPageState();
}

enum _JoinStep { loading, confirm, joining, error, declined }

class _JoinCollabPageState extends State<JoinCollabPage> {
  static const _violet = Color(0xFF8A2BE2);
  static const _pink = Color(0xFFEC4899);

  _JoinStep _step = _JoinStep.loading;
  String? _error;
  Map<String, dynamic>? _preview;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final preview = await CollaborationService.previewInviteToken(widget.token);
      if (!mounted) return;
      if (preview == null) {
        setState(() {
          _step = _JoinStep.error;
          _error = 'Lien invalide ou expiré.';
        });
        return;
      }
      setState(() {
        _preview = preview;
        _step = _JoinStep.confirm;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _step = _JoinStep.error;
        _error = 'Impossible de charger ce lien. Réessaie.';
      });
    }
  }

  Future<void> _accept() async {
    setState(() => _step = _JoinStep.joining);
    try {
      final result = await CollaborationService.joinByToken(widget.token);
      if (!mounted) return;
      if (result == null) {
        setState(() {
          _step = _JoinStep.error;
          _error = 'Impossible de rejoindre la liste. Réessaie.';
        });
        return;
      }

      final chatId = result['chatId'] as String?;
      final profileName = result['profileName'] as String? ?? 'la liste';

      // Même écran de félicitations que pour tout autre moyen de rejoindre
      // une collaboration (ajout direct par le propriétaire, acceptation
      // d'invitation depuis l'app).
      await showCollabWelcomeDialog(
        context,
        message: Text(
          'Tu as rejoint la collaboration pour $profileName ! 🎁',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15, height: 1.4),
        ),
        chatId: chatId,
        chatName: 'Cadeaux pour $profileName',
        secondaryLabel: 'Plus tard',
        onDismiss: () => context.go('/home-pinterest'),
        onOpenChat: chatId != null
            ? () => context.go('/chat-room/$chatId', extra: {
                  'name': 'Cadeaux pour $profileName',
                  'isGroup': true,
                })
            : () => context.go('/home-pinterest'),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _step = _JoinStep.error;
        _error = 'Impossible de rejoindre la liste. Réessaie.';
      });
    }
  }

  void _decline() {
    setState(() => _step = _JoinStep.declined);
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
              _buildStepContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case _JoinStep.loading:
      case _JoinStep.joining:
        return Column(children: [
          const CircularProgressIndicator(color: _violet, strokeWidth: 2),
          const SizedBox(height: 16),
          Text(
            _step == _JoinStep.joining ? 'On te connecte au groupe…' : 'Chargement du lien…',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
          ),
        ]);

      case _JoinStep.error:
        return Column(children: [
          const Icon(Icons.link_off_rounded, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text('Lien invalide',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(_error ?? '', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          _primaryButton('Retour à l\'accueil', () => context.go('/home-pinterest')),
        ]);

      case _JoinStep.declined:
        return Column(children: [
          const Icon(Icons.info_outline_rounded, color: Colors.white54, size: 48),
          const SizedBox(height: 16),
          Text('Invitation ignorée',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          _primaryButton('Retour à l\'accueil', () => context.go('/home-pinterest')),
        ]);

      case _JoinStep.confirm:
        final profileName = _preview?['profileName'] as String? ?? 'la liste';
        final ownerName = _preview?['ownerName'] as String? ?? 'un ami';
        final alreadyMember = _preview?['alreadyMember'] as bool? ?? false;

        if (alreadyMember) {
          final chatId = _preview?['chatId'] as String?;
          return Column(children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 56),
            const SizedBox(height: 16),
            Text('Tu es déjà membre !',
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Tu fais déjà partie de la liste de $profileName.',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            _primaryButton(
              'Ouvrir la discussion',
              () => chatId != null
                  ? context.go('/chat-room/$chatId', extra: {
                      'name': 'Cadeaux pour $profileName',
                      'isGroup': true,
                    })
                  : context.go('/home-pinterest'),
            ),
          ]);
        }

        return Column(children: [
          Text(
            'Rejoindre la liste de\n$profileName ?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            '$ownerName t\'invite à collaborer sur cette liste de cadeaux : vous pourrez échanger vos idées et organiser vos achats ensemble.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54, height: 1.4),
          ),
          const SizedBox(height: 28),
          _primaryButton('Accepter et rejoindre', _accept),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _decline,
            child: Text('Refuser', style: GoogleFonts.poppins(color: Colors.white38, fontWeight: FontWeight.w600)),
          ),
        ]);
    }
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_violet, _pink]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }
}
