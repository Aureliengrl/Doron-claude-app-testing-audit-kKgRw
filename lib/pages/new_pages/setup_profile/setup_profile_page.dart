import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Page affichée une seule fois après la première connexion,
/// uniquement si l'utilisateur n'a pas encore de handle.
class SetupProfilePage extends StatefulWidget {
  const SetupProfilePage({super.key});

  static const String routeName = 'SetupProfile';
  static const String routePath = '/setup-profile';

  @override
  State<SetupProfilePage> createState() => _SetupProfilePageState();
}

class _SetupProfilePageState extends State<SetupProfilePage> {
  final _handleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _handleController.dispose();
    super.dispose();
  }

  Future<bool> _isHandleAvailable(String handle) async {
    final lower = handle.toLowerCase().trim();
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('handle', isEqualTo: lower)
        .limit(1)
        .get();
    return snap.docs.isEmpty;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final handle = _handleController.text.toLowerCase().trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Vérifier disponibilité
      final available = await _isHandleAvailable(handle);
      if (!available) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Ce nom d\'utilisateur est déjà pris. Essaie-en un autre.';
        });
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      final uid = currentUser?.uid;
      if (uid == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Session expirée. Reconnecte-toi.';
        });
        return;
      }

      // Nom d'affichage pour les index de recherche
      final displayNameRaw = currentUser.displayName ?? '';
      final displayNameLower = displayNameRaw.toLowerCase().trim();
      // searchName = handle OU prénom (le plus utile pour être trouvé)
      final searchName = displayNameLower.isNotEmpty ? displayNameLower : handle;

      // 2. Sauvegarder le handle dans le profil utilisateur (critique)
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'handle': handle,
        'handle_lower': handle,
        // Champs index pour la recherche
        'searchName': searchName,
        'display_name_lower': displayNameLower,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. Mettre à jour l'index handles (non critique — ne bloque pas si ça échoue)
      try {
        await FirebaseFirestore.instance.collection('handles').doc(handle).set({
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (indexErr) {
        // L'index handles est secondaire — on continue quand même
        debugPrint('[SetupProfile] handles index write failed: $indexErr');
      }

      if (mounted) {
        context.go('/search-page');
      }
    } catch (e, st) {
      debugPrint('[SetupProfile] _save error: $e\n$st');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Une erreur est survenue. Réessaie. ($e)';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0014),
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8A2BE2).withOpacity(0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFEC4899).withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),

                    // Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8A2BE2), Color(0xFFEC4899)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.alternate_email, color: Colors.white, size: 32),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Choisis ton\nnom d\'utilisateur',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'C\'est ton identifiant unique sur Doron. Tes amis pourront te retrouver avec ce nom.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.55),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Champ handle
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 18, right: 4),
                            child: Text(
                              '@',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF8A2BE2),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _handleController,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'ton_pseudo',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.white.withOpacity(0.25),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 18),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_\.]')),
                                LengthLimitingTextInputFormatter(30),
                              ],
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Champ obligatoire';
                                }
                                if (val.trim().length < 3) {
                                  return 'Au moins 3 caractères';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    Text(
                      'Uniquement lettres, chiffres, _ et . — min. 3 caractères',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.35),
                      ),
                    ),

                    const Spacer(),

                    // Bouton Continuer
                    GestureDetector(
                      onTap: _isLoading ? null : () { HapticFeedback.mediumImpact(); _save(); },
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8A2BE2), Color(0xFFEC4899)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8A2BE2).withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              : Text(
                                  'Continuer →',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
