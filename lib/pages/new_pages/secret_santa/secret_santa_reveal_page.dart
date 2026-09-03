import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/components/cached_image.dart';
import '/services/secret_santa_service.dart';

class SecretSantaRevealPage extends StatefulWidget {
  final String groupId;
  const SecretSantaRevealPage({super.key, required this.groupId});

  static const String routeName = 'SecretSantaReveal';
  static const String routePath = '/secret-santa/reveal/:groupId';

  @override
  State<SecretSantaRevealPage> createState() => _SecretSantaRevealPageState();
}

class _SecretSantaRevealPageState extends State<SecretSantaRevealPage>
    with TickerProviderStateMixin {
  final Color _violet = const Color(0xFF8A2BE2);
  final Color _pink = const Color(0xFFEC4899);

  late AnimationController _flipCtrl;
  late AnimationController _confettiCtrl;
  late Animation<double> _flipAnim;

  bool _revealed = false;
  bool _loading = true;
  Map<String, dynamic>? _pair;
  Map<String, dynamic>? _targetProfile;
  SecretSantaGroup? _group;

  @override
  void initState() {
    super.initState();

    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _flipAnim = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutCubic),
    );

    _loadData();
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        SecretSantaService.getMyPair(widget.groupId),
        SecretSantaService.getGroupStream(widget.groupId).first,
      ]);

      _pair = results[0] as Map<String, dynamic>?;
      _group = results[1] as SecretSantaGroup?;

      if (_pair != null) {
        final targetUid = _pair!['assignedToUid'] as String?;
        if (targetUid != null) {
          _targetProfile = await SecretSantaService.getParticipantProfile(targetUid);
        }
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _doReveal() async {
    if (_revealed) return;
    HapticFeedback.heavyImpact();
    _flipCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _revealed = true);
    _confettiCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8A2BE2)))
          : _pair == null
              ? _buildNoPair()
              : _buildReveal(),
    );
  }

  Widget _buildNoPair() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_violet.withOpacity(0.3), _pink.withOpacity(0.2)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 20),
          Text('Le tirage n\'a pas encore eu lieu',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(backgroundColor: _violet, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text('Retour', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildReveal() {
    final name = _pair!['assignedToName'] as String? ?? 'Quelqu\'un';
    final photo = _targetProfile?['photo_url'] as String? ?? _targetProfile?['photoUrl'] as String?;
    final groupName = _group?.name ?? 'Secret Santa';

    return Stack(
      children: [
        // ── Fond animé ────────────────────────────────────────────────────
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  _violet.withOpacity(_revealed ? 0.4 : 0.1),
                  const Color(0xFF0A0A12),
                ],
              ),
            ),
          ),
        ),

        // ── Confettis ─────────────────────────────────────────────────────
        if (_revealed)
          ...List.generate(20, (i) => _buildConfetti(i)),

        // ── Contenu principal ─────────────────────────────────────────────
        SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        groupName,
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Titre suspense / reveal ────────────────────────
                      if (!_revealed)
                        Text(
                          'Tu as tiré au sort…',
                          style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 18,
                          ),
                        ).animate().fadeIn().slideY(begin: -0.2, end: 0),

                      if (_revealed)
                        Text(
                          'Tu offres un cadeau à…',
                          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16),
                        ).animate().fadeIn(duration: 400.ms),

                      const SizedBox(height: 32),

                      // ── Carte flip ────────────────────────────────────
                      GestureDetector(
                        onTap: _doReveal,
                        child: AnimatedBuilder(
                          animation: _flipAnim,
                          builder: (context, child) {
                            final angle = _flipAnim.value;
                            final isFront = angle <= math.pi / 2;
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(isFront ? angle : angle - math.pi),
                              child: isFront ? _buildCardFront() : _buildCardBack(name, photo),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Instructions / CTA ────────────────────────────
                      if (!_revealed)
                        Column(
                          children: [
                            Text('Touche la carte pour découvrir !',
                                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _violet.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.touch_app_rounded, color: Colors.white, size: 28),
                            )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .slideY(begin: 0, end: -0.3, duration: 800.ms, curve: Curves.easeInOut),
                          ],
                        ).animate().fadeIn(delay: 500.ms),

                      if (_revealed)
                        Column(
                          children: [
                            Text('Consulte sa wishlist et trouve le cadeau parfait',
                                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/secret-santa/wishlist/${widget.groupId}'),
                              icon: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 20),
                              label: Text('Voir sa wishlist →',
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _violet,
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                elevation: 8,
                                shadowColor: _violet.withOpacity(0.5),
                              ),
                            ).animate().fadeIn(duration: 500.ms, delay: 300.ms).slideY(begin: 0.3, end: 0),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardFront() {
    return Container(
      width: 260, height: 320,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [_violet.withOpacity(0.6), _pink.withOpacity(0.4), const Color(0xFF1A0A2E)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(color: _violet.withOpacity(0.5), blurRadius: 40, offset: const Offset(0, 16)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 54),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2000.ms),
          const SizedBox(height: 20),
          Text('Ton Secret Santa',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Appuie pour révéler',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCardBack(String name, String? photoUrl) {
    return Container(
      width: 260, height: 320,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [const Color(0xFF1A1A2E), _violet.withOpacity(0.4)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _violet.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: _violet.withOpacity(0.6), blurRadius: 40, offset: const Offset(0, 16)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CachedCircleAvatar(
            photoUrl: photoUrl,
            radius: 50,
            backgroundColor: _violet.withOpacity(0.3),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text(name,
              style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold,
              )).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text('C\'est à toi d\'offrir !',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14))
              .animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildConfetti(int i) {
    final rng = math.Random(i);
    final colors = [_violet, _pink, Colors.white, const Color(0xFF10B981), const Color(0xFFF59E0B)];
    return Positioned(
      left: rng.nextDouble() * MediaQuery.of(context).size.width,
      top: -20,
      child: AnimatedBuilder(
        animation: _confettiCtrl,
        builder: (ctx, _) {
          final t = _confettiCtrl.value;
          return Transform.translate(
            offset: Offset(
              math.sin(t * 2 * math.pi + i) * 40,
              t * (MediaQuery.of(context).size.height + 60),
            ),
            child: Transform.rotate(
              angle: t * 4 * math.pi + i,
              child: Container(
                width: 8 + rng.nextDouble() * 8,
                height: 8 + rng.nextDouble() * 8,
                decoration: BoxDecoration(
                  color: colors[i % colors.length].withOpacity(0.85),
                  borderRadius: BorderRadius.circular(rng.nextDouble() * 4),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
