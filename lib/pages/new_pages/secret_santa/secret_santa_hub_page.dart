import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/components/liquid_glass.dart';
import '/services/secret_santa_service.dart';

class SecretSantaHubPage extends StatefulWidget {
  const SecretSantaHubPage({super.key});

  static const String routeName = 'SecretSantaHub';
  static const String routePath = '/secret-santa';

  @override
  State<SecretSantaHubPage> createState() => _SecretSantaHubPageState();
}

class _SecretSantaHubPageState extends State<SecretSantaHubPage> {
  final Color _violet = const Color(0xFF8A2BE2);
  final Color _pink = const Color(0xFFEC4899);
  final Color _indigo = const Color(0xFF6366F1);
  final Color _cyan = const Color(0xFF06B6D4);

  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  void _showJoinDialog() {
    final tokenController = TextEditingController();
    bool isJoining = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF131322).withOpacity(0.96),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [_indigo, _cyan]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rejoindre un groupe',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Entre le code d\'invitation partagé par l\'organisateur',
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: tokenController,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      textCapitalization: TextCapitalization.none,
                      autocorrect: false,
                      decoration: InputDecoration(
                        hintText: 'Ex: a1b2c3d4e5f6',
                        hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 14),
                        prefixIcon: const Icon(Icons.tag_rounded, color: Colors.white38, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.content_paste_rounded, color: Colors.white60, size: 18),
                          tooltip: 'Coller',
                          onPressed: () async {
                            final data = await Clipboard.getData('text/plain');
                            if (data?.text != null && data!.text!.trim().isNotEmpty) {
                              setModalState(() {
                                tokenController.text = data.text!.trim();
                              });
                            }
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: _cyan, width: 1.5),
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isJoining
                            ? null
                            : () async {
                                final token = tokenController.text.trim();
                                if (token.isEmpty) return;

                                setModalState(() => isJoining = true);
                                try {
                                  final groupId = await SecretSantaService.joinByToken(token);
                                  if (!ctx.mounted || !context.mounted) return;
                                  if (groupId != null) {
                                    Navigator.pop(ctx);
                                    context.push('/secret-santa/lobby/$groupId');
                                  } else {
                                    setModalState(() => isJoining = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Code invalide ou groupe introuvable.',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        backgroundColor: Colors.red[700],
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (ctx.mounted && context.mounted) {
                                    setModalState(() => isJoining = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Erreur : $e', style: GoogleFonts.poppins()),
                                        backgroundColor: Colors.red[700],
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _indigo,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 6,
                          shadowColor: _indigo.withOpacity(0.5),
                        ),
                        child: isJoining
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.login_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Valider et Rejoindre',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(() => tokenController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar avec Hero ──────────────────────────────────────────
          SliverAppBar(
            backgroundColor: Colors.transparent,
            expandedHeight: 180,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                tooltip: 'Actualiser',
                onPressed: () => setState(() {}),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient atmosphérique
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _violet.withOpacity(0.85),
                          _pink.withOpacity(0.6),
                          const Color(0xFF0D0D18),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),

                  // Lueur décorative
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _pink.withOpacity(0.3),
                      ),
                    ),
                  ),

                  // Titre et Description
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [_pink, _violet]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _pink.withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 28),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Secret Santa',
                                  style: GoogleFonts.poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'Tirages au sort & wishlists magiques',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Actions Majeures : Créer & Rejoindre (Grand format) ──────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actions rapides',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 1. Bouton PROÉMINENT: REJOINDRE UN GROUPE
                  _buildMajorActionCard(
                    title: 'Rejoindre un groupe',
                    subtitle: 'Entre avec un code d\'invitation reçu',
                    badgeText: 'J\'ai un code',
                    icon: Icons.vpn_key_rounded,
                    gradientColors: [_indigo, _cyan],
                    accentColor: _cyan,
                    onTap: _showJoinDialog,
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 12),

                  // 2. Bouton CRÉER UN GROUPE
                  _buildMajorActionCard(
                    title: 'Créer un groupe',
                    subtitle: 'Organise un tirage au sort entre amis ou collègues',
                    badgeText: 'Organisateur',
                    icon: Icons.add_circle_outline_rounded,
                    gradientColors: [_violet, _pink],
                    accentColor: _pink,
                    onTap: () => context.push('/secret-santa/create'),
                  ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ),

          // ── Titre "Mes groupes" ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mes groupes',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Liste temps-réel des groupes ─────────────────────────────────
          SliverToBoxAdapter(
            child: StreamBuilder<List<SecretSantaGroup>>(
              stream: SecretSantaService.getMyGroupsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF8A2BE2)),
                    ),
                  );
                }

                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Erreur de chargement des groupes.',
                        style: GoogleFonts.poppins(color: Colors.white60),
                      ),
                    ),
                  );
                }

                final groups = snap.data ?? [];

                if (groups.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: _buildEmptyState(),
                  );
                }

                return Column(
                  children: groups.asMap().entries.map((entry) {
                    final i = entry.key;
                    final group = entry.value;
                    final isMyGroup = group.createdBy == _myUid;

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _GroupCard(
                        group: group,
                        isOrganizer: isMyGroup,
                        onTap: () {
                          if (group.isOpen) {
                            context.push('/secret-santa/lobby/${group.id}');
                          } else {
                            context.push('/secret-santa/reveal/${group.id}');
                          }
                        },
                      ).animate().fadeIn(delay: Duration(milliseconds: 60 + i * 50)).slideY(begin: 0.1, end: 0),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // ── Bottom Padding ───────────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildMajorActionCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required IconData icon,
    required List<Color> gradientColors,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_violet.withOpacity(0.3), _pink.withOpacity(0.2)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun groupe pour l\'instant',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Crée un groupe pour lancer les festivités ou rejoins tes amis avec un code d\'invitation.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Carte Groupe Moderne ──────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final SecretSantaGroup group;
  final bool isOrganizer;
  final VoidCallback onTap;

  const _GroupCard({
    required this.group,
    required this.isOrganizer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = group.isOpen
        ? const Color(0xFF10B981)
        : group.isDrawn
            ? const Color(0xFFF59E0B)
            : const Color(0xFF8A2BE2);

    final primaryColor = group.themePrimaryColor;
    final secondaryColor = group.themeSecondaryColor;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                // Icône Thème
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor.withOpacity(0.3), secondaryColor.withOpacity(0.15)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Icon(group.themeIcon, color: Colors.white, size: 26),
                  ),
                ),
                const SizedBox(width: 14),

                // Informations du groupe
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              group.name,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isOrganizer) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8A2BE2).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF8A2BE2).withOpacity(0.4)),
                              ),
                              child: Text(
                                'Hôte',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFC084FC),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Statut
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              group.statusLabel,
                              style: GoogleFonts.poppins(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Participants
                          const Icon(Icons.people_alt_outlined, color: Colors.white54, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            '${group.participantUids.length}',
                            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                          ),

                          const SizedBox(width: 8),

                          // Budget
                          if (group.budget.isNotEmpty) ...[
                            const Icon(Icons.euro_rounded, color: Colors.white38, size: 13),
                            Text(
                              '${group.budget['min']}–${group.budget['max']}€',
                              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

