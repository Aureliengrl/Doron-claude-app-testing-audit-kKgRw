import 'dart:ui';
import 'package:flutter/material.dart';
import '/components/premium_3d_icon.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/components/liquid_glass.dart';
import '/components/cached_image.dart';
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
  final _tokenController = TextEditingController();

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _showJoinDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF13131F).withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🔑 Rejoindre un groupe',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Entre le code d\'invitation reçu',
                      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tokenController,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Code d\'invitation (ex: abc123xyz)',
                      hintStyle: GoogleFonts.poppins(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.07),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: _violet),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final token = _tokenController.text.trim();
                        if (token.isEmpty) return;
                        Navigator.pop(ctx);
                        final groupId = await SecretSantaService.joinByToken(token);
                        if (groupId != null && mounted) {
                          context.push('/secret-santa/lobby/$groupId');
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Code invalide ou groupe introuvable',
                                  style: GoogleFonts.poppins()),
                              backgroundColor: Colors.red[700],
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _violet,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Rejoindre',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: Colors.transparent,
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient fond
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF8A2BE2).withOpacity(0.8),
                          const Color(0xFFEC4899).withOpacity(0.5),
                          const Color(0xFF0A0A12),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  // Flocons animés (déco)
                  ...List.generate(8, (i) => Positioned(
                    left: (i * 47.0) % 380,
                    top: (i * 31.0) % 200,
                    child: Text(
                      i % 2 == 0 ? '❄️' : '🎄',
                      style: TextStyle(fontSize: 14 + (i % 3) * 4.0),
                    ).animate(onPlay: (c) => c.repeat()).shimmer(
                      duration: Duration(milliseconds: 1800 + i * 300),
                    ),
                  )),
                  // Titre
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Premium3DIcon(assetName: 'santa_3d.png', size: 64),
                          const SizedBox(height: 8),
                          Text('Secret Santa',
                              style: GoogleFonts.poppins(
                                fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white,
                                shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 8)],
                              )),
                          Text('Offrez le cadeau parfait à coup sûr',
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              TextButton.icon(
                onPressed: _showJoinDialog,
                icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                label: Text('Rejoindre', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
              ),
            ],
          ),

          // ── CTA Créer ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: GestureDetector(
                onTap: () => context.push('/secret-santa/create'),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_violet, _pink],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: _violet.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(child: Text('🎅', style: TextStyle(fontSize: 28))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Créer un groupe',
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('Pour Noël, un anniversaire ou le boulot',
                                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),
              ),
            ),
          ),

          // ── Mes groupes ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text('Mes groupes',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),

          SliverToBoxAdapter(
            child: StreamBuilder<List<SecretSantaGroup>>(
              stream: SecretSantaService.getMyGroupsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF8A2BE2))),
                  );
                }

                final groups = snap.data ?? [];

                if (groups.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                    child: _buildEmptyState(),
                  );
                }

                return Column(
                  children: groups.asMap().entries.map((entry) {
                    final i = entry.key;
                    final group = entry.value;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _GroupCard(
                        group: group,
                        onTap: () {
                          if (group.isOpen) {
                            context.push('/secret-santa/lobby/${group.id}');
                          } else {
                            context.push('/secret-santa/reveal/${group.id}');
                          }
                        },
                      ).animate().fadeIn(delay: Duration(milliseconds: 100 + i * 80)).slideY(begin: 0.15, end: 0),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // ── Padding bottom nav ─────────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 48)).animate().scale(
            duration: 600.ms, curve: Curves.elasticOut,
          ),
          const SizedBox(height: 16),
          Text('Aucun groupe pour l\'instant',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Crée ton premier groupe Secret Santa\nou rejoins-en un avec un code d\'invitation.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14)),
        ],
      ),
    );
  }
}

// ── Group Card ────────────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final SecretSantaGroup group;
  final VoidCallback onTap;

  const _GroupCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final violet = const Color(0xFF8A2BE2);
    final statusColor = group.isOpen
        ? const Color(0xFF10B981)
        : group.isDrawn
            ? const Color(0xFFF59E0B)
            : const Color(0xFF8A2BE2);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                // Emoji thème
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: violet.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(group.themeEmoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name,
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor.withOpacity(0.4)),
                            ),
                            child: Text(group.statusLabel,
                                style: GoogleFonts.poppins(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 8),
                          Text('${group.participantUids.length} participants',
                              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // FIX-ISSUE4: null-safety sur budget (min/max peuvent être null)
                      if (group.budget.isNotEmpty && (group.budget['min'] != null || group.budget['max'] != null))
                        Text('Budget : ${group.budget['min'] ?? '?'}€ – ${group.budget['max'] ?? '?'}€',
                            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
