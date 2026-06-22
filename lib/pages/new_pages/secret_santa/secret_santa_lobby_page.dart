import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/components/liquid_glass.dart';
import '/components/cached_image.dart';
import '/services/secret_santa_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecretSantaLobbyPage extends StatefulWidget {
  final String groupId;
  const SecretSantaLobbyPage({super.key, required this.groupId});

  static const String routeName = 'SecretSantaLobby';
  static const String routePath = '/secret-santa/lobby/:groupId';

  @override
  State<SecretSantaLobbyPage> createState() => _SecretSantaLobbyPageState();
}

class _SecretSantaLobbyPageState extends State<SecretSantaLobbyPage> {
  final Color _violet = const Color(0xFF8A2BE2);
  final Color _pink = const Color(0xFFEC4899);
  final Color _green = const Color(0xFF10B981);

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ✨ '';
  bool _drawing = false;

  Future<void> _launchDraw(SecretSantaGroup group) async {
    if (_drawing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13131F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('🎅 Lancer le tirage ?',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Cela va attribuer aléatoirement une personne à chaque participant. Cette action est irréversible.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _violet, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Tirer au sort !', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _drawing = true);
    try {
      await SecretSantaService.performDraw(widget.groupId);
      HapticFeedback.heavyImpact();
      if (mounted) {
        context.pushReplacement('/secret-santa/reveal/${widget.groupId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur tirage : $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _drawing = false);
    }
  }

  void _shareInvite(String token) {
    final link = SecretSantaService.getInviteLink(token);
    final text = '🎅 Rejoins mon Secret Santa sur Doron !\n\nLien : $link\nCode : $token';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lien copié ! Colle-le dans ton app de messagerie 📋', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF8A2BE2),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: StreamBuilder<SecretSantaGroup?>(
        stream: SecretSantaService.getGroupStream(widget.groupId),
        builder: (context, groupSnap) {
          if (groupSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF8A2BE2)));
          }

          final group = groupSnap.data;
          if (group == null) {
            return Center(child: Text('Groupe introuvable', style: GoogleFonts.poppins(color: Colors.white)));
          }

          // Si le tirage a déjà eu lieu, rediriger
          if (!group.isOpen && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.pushReplacement('/secret-santa/reveal/${widget.groupId}');
            });
          }

          final isOrganizer = group.createdBy == _myUid;

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: SecretSantaService.getParticipants(widget.groupId),
            builder: (context, partSnap) {
              final participants = partSnap.data ✨ [];
              final hasBoughtCount = participants.where((p) => p['hasBought'] == true).length;

              return CustomScrollView(
                slivers: [
                  // ── App Bar ────────────────────────────────────────────
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    pinned: true,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    title: Text(
                      '${group.themeEmoji} ${group.name}',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    centerTitle: true,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.share_rounded, color: Colors.white),
                        onPressed: () => _shareInvite(group.inviteToken),
                      ),
                    ],
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [

                          // ── Info card ─────────────────────────────────
                          _buildInfoCard(group).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 16),

                          // ── Invite link ───────────────────────────────
                          _buildInviteCard(group),

                          const SizedBox(height: 24),

                          // ── Participants header ────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Participants (${participants.length})',
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              if (group.isDrawn)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _green.withOpacity(0.4)),
                                  ),
                                  child: Text('$hasBoughtCount/${participants.length} ont acheté',
                                      style: GoogleFonts.poppins(color: _green, fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ── Participant list ───────────────────────────
                          ...participants.asMap().entries.map((entry) {
                            final i = entry.key;
                            final p = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildParticipantTile(p).animate().fadeIn(
                                delay: Duration(milliseconds: 100 + i * 60),
                              ),
                            );
                          }),

                          const SizedBox(height: 24),

                          // ── Bouton tirage (organisateur seulement) ─────
                          if (isOrganizer && group.isOpen)
                            _buildDrawButton(group, participants),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(SecretSantaGroup group) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_violet.withOpacity(0.2), _pink.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _violet.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildInfoItem('Budget', '${group.budget['min']}€ – ${group.budget['max']}€', '💰'),
              ),
              Container(width: 1, height: 40, color: Colors.white12),
              Expanded(
                child: _buildInfoItem('Participants', '${group.participantUids.length}', '👥'),
              ),
              Container(width: 1, height: 40, color: Colors.white12),
              Expanded(
                child: _buildInfoItem('Statut', group.statusLabel, group.isOpen ✨ '🟢' : '🎯'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        Text(label, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildInviteCard(SecretSantaGroup group) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.link_rounded, color: Color(0xFF8A2BE2), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Code d\'invitation', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
                    Text(group.inviteToken,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: group.inviteToken));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Code copié !', style: GoogleFonts.poppins()), backgroundColor: _violet, behavior: SnackBarBehavior.floating),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _violet.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _violet.withOpacity(0.4)),
                  ),
                  child: Text('Copier', style: GoogleFonts.poppins(color: _violet, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _shareInvite(group.inviteToken),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _pink.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _pink.withOpacity(0.4)),
                  ),
                  child: Text('Partager', style: GoogleFonts.poppins(color: _pink, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantTile(Map<String, dynamic> p) {
    final name = p['displayName'] as String? ✨ '✨';
    final photo = p['photoUrl'] as String?;
    final isOrganizer = p['isOrganizer'] == true;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              CachedCircleAvatar(
                photoUrl: photo,
                radius: 20,
                backgroundColor: _violet.withOpacity(0.3),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        if (isOrganizer) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: _violet.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Organisateur', style: GoogleFonts.poppins(color: _violet, fontSize: 10, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawButton(SecretSantaGroup group, List<Map<String, dynamic>> participants) {
    final canDraw = participants.length >= 2;
    return Column(
      children: [
        if (!canDraw)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Il faut au moins 2 participants pour lancer le tirage',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.orange, fontSize: 13)),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canDraw && !_drawing ✨ () => _launchDraw(group) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canDraw ✨ _violet : Colors.grey[800],
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: canDraw ✨ 8 : 0,
              shadowColor: _violet.withOpacity(0.5),
            ),
            child: _drawing
                ✨ Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Text('Tirage en cours…', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  )
                : Text('🎅 Lancer le tirage !',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ).animate(onPlay: canDraw ✨ (c) => c.repeat() : null).shimmer(
          duration: 2000.ms, color: Colors.white.withOpacity(0.15),
          delay: 1000.ms,
        ),
      ],
    );
  }
}
