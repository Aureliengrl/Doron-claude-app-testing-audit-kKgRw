import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/liquid_glass.dart';
import '/services/user_search_service.dart';
import '/utils/app_logger.dart';

class ChooseHandleWidget extends StatefulWidget {
  static const String routeName = 'ChooseHandle';
  static const String routePath = '/choose-handle';

  final String? returnTo;
  final String? personId;

  const ChooseHandleWidget({Key? key, this.returnTo, this.personId}) : super(key: key);

  @override
  _ChooseHandleWidgetState createState() => _ChooseHandleWidgetState();
}

class _ChooseHandleWidgetState extends State<ChooseHandleWidget> {
  final TextEditingController _handleController = TextEditingController();
  final FocusNode _handleFocusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _handleController.dispose();
    _handleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveHandle() async {
    final rawHandle = _handleController.text.trim().replaceAll('@', '');
    
    if (rawHandle.isEmpty || rawHandle.length < 3) {
      setState(() => _errorMessage = 'Au moins 3 caractères requis.');
      return;
    }
    
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(rawHandle)) {
      setState(() => _errorMessage = 'Uniquement lettres, chiffres, - et _');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check Uniqueness
      final isAvailable = await UserSearchService.isHandleAvailable(rawHandle, currentUserUid);
      
      if (!isAvailable) {
        setState(() {
          _errorMessage = 'Ce nom d\\'utilisateur existe déjà.';
          _isLoading = false;
        });
        return;
      }

      // Save to Firebase
      await currentUserReference?.update({
        'handle': rawHandle,
        'searchName': rawHandle.toLowerCase(),
      });

      AppLogger.debug('✅ Handle saved successfully: $rawHandle', 'Debug');

      if (!mounted) return;

      // Routing logic (borrowed from AuthentificationWidget)
      if (widget.personId != null && widget.personId!.isNotEmpty) {
        final returnParam = (widget.returnTo != null && widget.returnTo!.isNotEmpty)
            ? '&returnTo=${Uri.encodeComponent(widget.returnTo!)}'
            : '';
        context.go('/onboarding-gifts-result?personId=${widget.personId}$returnParam');
      } else {
        context.goNamedAuth('HomePinterest', context.mounted);
      }

    } catch (e) {
      AppLogger.debug('❌ Error saving handle: $e', 'Debug');
      setState(() {
        _errorMessage = 'Une erreur est survenue.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LiquidGlassTokens.darkPageGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.person_add_alt_1_rounded, size: 60, color: const Color(0xFF8A2BE2)),
                const SizedBox(height: 24),
                Text(
                  'Choisis ton Pseudo',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cela servira à tes amis pour te retrouver et partager des listes de cadeaux.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 48),
                LiquidGlassTextInput(
                  controller: _handleController,
                  focusNode: _handleFocusNode,
                  hintText: 'ex: marc_dupont',
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.text,
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 32),
                LiquidGlassPill(
                  height: 56,
                  isActive: !_isLoading,
                  activeColor: const Color(0xFF8A2BE2),
                  onTap: _isLoading ? () {} : _saveHandle,
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Continuer',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Tu pourras toujours le modifier plus tard.',
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
