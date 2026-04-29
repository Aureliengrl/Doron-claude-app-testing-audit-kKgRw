import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/utils/app_tr.dart';

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
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  // Anniversaire (optionnel — jour + mois uniquement)
  int? _birthdayDay;
  int? _birthdayMonth;
  bool _birthdayExpanded = false;

  // ── Mois dynamiques (dépendent de la langue) ─────────────────────────────
  List<String> _months(BuildContext ctx) => [
    ctx.tr('Janvier', 'January'),
    ctx.tr('Février', 'February'),
    ctx.tr('Mars', 'March'),
    ctx.tr('Avril', 'April'),
    ctx.tr('Mai', 'May'),
    ctx.tr('Juin', 'June'),
    ctx.tr('Juillet', 'July'),
    ctx.tr('Août', 'August'),
    ctx.tr('Septembre', 'September'),
    ctx.tr('Octobre', 'October'),
    ctx.tr('Novembre', 'November'),
    ctx.tr('Décembre', 'December'),
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill name from auth provider (Google/Apple display name)
    final providerName = FirebaseAuth.instance.currentUser?.displayName ?? '';
    if (providerName.isNotEmpty) {
      _nameController.text = providerName;
    }
  }

  @override
  void dispose() {
    _handleController.dispose();
    _nameController.dispose();
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
      // 1. Vérifier disponibilité du handle
      final available = await _isHandleAvailable(handle);
      if (!available) {
        setState(() {
          _isLoading = false;
          _errorMessage = context.tr(
            'Ce nom d\'utilisateur est déjà pris. Essaie-en un autre.',
            'This username is already taken. Try another one.',
          );
        });
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      final uid = currentUser?.uid;
      if (uid == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = context.tr(
            'Session expirée. Reconnecte-toi.',
            'Session expired. Please sign in again.',
          );
        });
        return;
      }

      // Nom d'affichage : priorité au champ saisi, sinon auth provider
      final nameInput = _nameController.text.trim();
      final displayName = nameInput.isNotEmpty
          ? nameInput
          : (currentUser?.displayName ?? '');
      final displayNameLower = displayName.toLowerCase().trim();
      final searchName = displayNameLower.isNotEmpty ? displayNameLower : handle;

      // 2. Données de base du profil
      final profileData = <String, dynamic>{
        'handle': handle,
        'handle_lower': handle,
        'display_name': displayName,
        'first_name': displayName,
        'searchName': searchName,
        'display_name_lower': displayNameLower,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 3. Ajouter l'anniversaire si renseigné
      if (_birthdayDay != null && _birthdayMonth != null) {
        profileData['birthday'] = {
          'day': _birthdayDay,
          'month': _birthdayMonth,
        };
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(profileData, SetOptions(merge: true));

      // 4. Mettre à jour l'index handles
      try {
        await FirebaseFirestore.instance.collection('handles').doc(handle).set({
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (indexErr) {
        debugPrint('[SetupProfile] handles index write failed: $indexErr');
      }

      if (mounted) {
        context.go('/search-page');
      }
    } catch (e, st) {
      debugPrint('[SetupProfile] _save error: $e\n$st');
      setState(() {
        _isLoading = false;
        _errorMessage = context.tr(
          'Une erreur est survenue. Réessaie. ($e)',
          'An error occurred. Please try again. ($e)',
        );
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
            top: -100, left: -80,
            child: Container(
              width: 350, height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF8A2BE2).withOpacity(0.35),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -80, right: -60,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFEC4899).withOpacity(0.25),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // ── SÉLECTEUR DE LANGUE ──────────────────────────────
                    _buildLanguageSelector(),

                    const SizedBox(height: 32),

                    // Icon
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8A2BE2), Color(0xFFEC4899)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(IconlyLight.message, color: Colors.white, size: 32),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      context.tr('Crée ton profil', 'Create your profile'),
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr(
                        'Quelques infos pour personnaliser ton expérience Doron.',
                        'A few details to personalise your Doron experience.',
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.55),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── ANNIVERSAIRE (optionnel) ──────────────────────────
                    _buildBirthdaySection(),

                    const SizedBox(height: 28),

                    // ── HANDLE ───────────────────────────────────────────
                    Text(
                      context.tr('Nom d\'utilisateur', 'Username'),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                                  return context.tr('Champ obligatoire', 'Required field');
                                }
                                if (val.trim().length < 3) {
                                  return context.tr('Au moins 3 caractères', 'At least 3 characters');
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(
                        'Uniquement lettres, chiffres, _ et . — min. 3 caractères',
                        'Letters, numbers, _ and . only — min. 3 characters',
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.35),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── PRÉNOM ───────────────────────────────────────────
                    Text(
                      context.tr('Ton prénom', 'Your first name'),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr(
                        'C\'est le nom que tes amis verront.',
                        'This is the name your friends will see.',
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.45),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: context.tr('Ex : Marie', 'E.g. John'),
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.25),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                        ),
                        inputFormatters: [LengthLimitingTextInputFormatter(50)],
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return context.tr('Champ obligatoire', 'Required field');
                          }
                          return null;
                        },
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.redAccent),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // ── BOUTON CONTINUER ─────────────────────────────────
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
                                  context.tr('Continuer →', 'Continue →'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sélecteur de langue ───────────────────────────────────────────────────

  Widget _buildLanguageSelector() {
    final isEn = context.isEn;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🇫🇷 Français
          _buildLangButton(
            label: '🇫🇷  Français',
            isSelected: !isEn,
            onTap: () {
              setAppLanguage(context, 'fr');
              // Rebuild cette page pour mettre à jour toutes les strings
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(width: 6),
          // 🇬🇧 English
          _buildLangButton(
            label: '🇬🇧  English',
            isSelected: isEn,
            onTap: () {
              setAppLanguage(context, 'en');
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLangButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF8A2BE2), Color(0xFFEC4899)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8A2BE2).withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.45),
          ),
        ),
      ),
    );
  }

  // ── Section anniversaire ──────────────────────────────────────────────────

  Widget _buildBirthdaySection() {
    final hasBirthday = _birthdayDay != null && _birthdayMonth != null;
    final months = _months(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête cliquable
        GestureDetector(
          onTap: () => setState(() => _birthdayExpanded = !_birthdayExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: hasBirthday
                  ? const Color(0xFF8A2BE2).withOpacity(0.15)
                  : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasBirthday
                    ? const Color(0xFF8A2BE2).withOpacity(0.5)
                    : Colors.white.withOpacity(0.15),
              ),
            ),
            child: Row(
              children: [
                const Text('🎂', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('Ton anniversaire', 'Your birthday'),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        hasBirthday
                            ? '$_birthdayDay ${months[_birthdayMonth! - 1]}'
                            : context.tr(
                                'Optionnel — apparaît dans le calendrier de tes amis',
                                'Optional — appears in your friends\' calendar',
                              ),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: hasBirthday
                              ? const Color(0xFFEC4899)
                              : Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _birthdayExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ),

        // Sélecteurs déroulants
        if (_birthdayExpanded) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              // Jour
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('Jour', 'Day'),
                        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: DropdownButton<int>(
                        value: _birthdayDay,
                        hint: Text(context.tr('Jour', 'Day'),
                            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 14)),
                        dropdownColor: const Color(0xFF1A0030),
                        underline: const SizedBox(),
                        isExpanded: true,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: List.generate(31, (i) => i + 1).map((d) => DropdownMenuItem(
                          value: d,
                          child: Text('$d'),
                        )).toList(),
                        onChanged: (v) => setState(() => _birthdayDay = v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Mois
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('Mois', 'Month'),
                        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: DropdownButton<int>(
                        value: _birthdayMonth,
                        hint: Text(context.tr('Mois', 'Month'),
                            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 14)),
                        dropdownColor: const Color(0xFF1A0030),
                        underline: const SizedBox(),
                        isExpanded: true,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(months[m - 1]),
                        )).toList(),
                        onChanged: (v) => setState(() => _birthdayMonth = v),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Note RGPD
          const SizedBox(height: 8),
          Text(
            context.tr(
              '🔒 Seuls le jour et le mois sont enregistrés (pas l\'année)',
              '🔒 Only day and month are saved (not the year)',
            ),
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.white30),
          ),
        ],
      ],
    );
  }
}
