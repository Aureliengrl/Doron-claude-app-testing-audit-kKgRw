import '/utils/app_logger.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/services/firebase_data_service.dart';
import '/services/push_notifications_service.dart';
import 'authentification_model.dart';
export 'authentification_model.dart';

class AuthentificationWidget extends StatefulWidget {
  const AuthentificationWidget({super.key});

  static String routeName = 'authentification';
  static String routePath = '/authentification';

  @override
  State<AuthentificationWidget> createState() => _AuthentificationWidgetState();
}

class _AuthentificationWidgetState extends State<AuthentificationWidget> {
  late AuthentificationModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  String? _pendingPersonId;
  String? _returnTo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AuthentificationModel());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = GoRouterState.of(context).uri;
      _pendingPersonId = uri.queryParameters['personId'];
      _returnTo = uri.queryParameters['returnTo'];
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    try {
      GoRouter.of(context).prepareAuthEvent();
      final user = await authManager.signInWithGoogle(context);
      if (!mounted) return;
      if (user == null) {
        // Annulé par l'utilisateur — pas d'erreur à afficher
        setState(() => _isLoading = false);
        return;
      }
      await _afterSignIn();
    } catch (e) {
      AppLogger.debug('❌ Google SignIn: $e', 'Auth');
      if (mounted) {
        setState(() => _isLoading = false);
        _showAuthError('Connexion Google impossible', e.toString());
      }
    }
  }

  Future<void> _signInWithApple() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    try {
      GoRouter.of(context).prepareAuthEvent();
      final user = await authManager.signInWithApple(context);
      if (!mounted) return;
      if (user == null) {
        // Annulé par l'utilisateur
        setState(() => _isLoading = false);
        return;
      }
      await _afterSignIn();
    } catch (e) {
      AppLogger.debug('❌ Apple SignIn: $e', 'Auth');
      if (mounted) {
        setState(() => _isLoading = false);
        _showAuthError('Connexion Apple impossible', e.toString());
      }
    }
  }

  void _showAuthError(String title, String detail) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0030),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(IconlyLight.danger, color: Colors.redAccent, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
        content: Text(
          detail.length > 200 ? '${detail.substring(0, 200)}…' : detail,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: GoogleFonts.poppins(color: const Color(0xFF8A2BE2), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _signInAnonymously() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
      await _afterSignIn();
    } catch (e) {
      AppLogger.debug('❌ Anonymous SignIn: $e', 'Auth');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _afterSignIn() async {
    try {
      await PushNotificationsService.initialize();
    } catch (_) {}

    if (!mounted) return;

    // Si returnTo est défini, on le prioritise
    if (_returnTo != null && _returnTo!.isNotEmpty) {
      context.go(_returnTo!);
      return;
    }

    // Vérifier si c'est une première inscription (pas de handle encore)
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final handle = doc.data()?['handle'] as String?;
        if (!mounted) return;
        if (handle == null || handle.trim().isEmpty) {
          // Nouvel utilisateur → setup username
          context.go('/setup-profile');
          return;
        }
      }
    } catch (_) {}

    // Utilisateur existant → accueil direct
    if (mounted) {
      context.go('/search-page');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFF0A0014),
      body: Stack(
        children: [
          // Arrière-plan avec blob violet
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8A2BE2).withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFEC4899).withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Contenu principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/doron_logo.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Titre
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF8A2BE2), Color(0xFFEC4899)],
                    ).createShader(bounds),
                    child: Text(
                      'Bienvenue sur Doron',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Connecte-toi pour accéder à tes listes de cadeaux et retrouver tes amis.',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.6),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 2),

                  // Bouton Google
                  if (_isLoading)
                    const CircularProgressIndicator(color: Color(0xFF8A2BE2))
                  else ...[
                    _buildAuthButton(
                      onTap: _signInWithGoogle,
                      iconWidget: kIsWeb
                          ? const Icon(Icons.g_mobiledata, size: 26, color: Color(0xFF4285F4))
                          : Image.asset('assets/images/googleg_standard_color_64px.png', width: 22, height: 22),
                      label: 'Continuer avec Google',
                      backgroundColor: Colors.white,
                      textColor: const Color(0xFF1A1A1A),
                    ),
                    const SizedBox(height: 16),
                    // Bouton Apple
                    _buildAuthButton(
                      onTap: _signInWithApple,
                      iconWidget: const Icon(Icons.apple, size: 24, color: Colors.white),
                      label: 'Continuer avec Apple',
                      backgroundColor: const Color(0xFF1A1A1A),
                      textColor: Colors.white,
                      borderColor: Colors.white24,
                    ),
                  ],

                  // 🛠️ BOUTON DEBUG — visible uniquement en local (kDebugMode)
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _signInAnonymously,
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.withOpacity(0.6), width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bug_report, color: Colors.orange.withOpacity(0.8), size: 18),
                            const SizedBox(width: 10),
                            Text(
                              'Mode test local (debug)',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Mention légale
                  Text(
                    'En continuant, vous acceptez nos Conditions d\'utilisation\net notre Politique de confidentialité.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.3),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButton({
    required VoidCallback onTap,
    String? icon,
    Widget? iconWidget,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: borderColor != null ? Border.all(color: borderColor, width: 1) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Image.asset(
                icon,
                width: 22,
                height: 22,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.g_mobiledata, size: 24, color: Color(0xFF4285F4)),
              )
            else if (iconWidget != null)
              iconWidget,
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
