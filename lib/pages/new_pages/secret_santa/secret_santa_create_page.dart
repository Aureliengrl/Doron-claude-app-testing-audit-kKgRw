import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/components/liquid_glass.dart';
import '/services/secret_santa_service.dart';

class SecretSantaCreatePage extends StatefulWidget {
  const SecretSantaCreatePage({super.key});

  static const String routeName = 'SecretSantaCreate';
  static const String routePath = '/secret-santa/create';

  @override
  State<SecretSantaCreatePage> createState() => _SecretSantaCreatePageState();
}

class _SecretSantaCreatePageState extends State<SecretSantaCreatePage> {
  final Color _violet = const Color(0xFF8A2BE2);
  final Color _pink = const Color(0xFFEC4899);

  final _nameCtrl = TextEditingController();
  int _step = 0;
  String _theme = 'christmas';
  double _budgetMin = 20;
  double _budgetMax = 50;
  bool _loading = false;

  final List<Map<String, String>> _themes = [
    {'id': 'christmas', 'label': 'Noël', 'emoji': '🎄'},
    {'id': 'winter',    'label': 'Hiver',     'emoji': '❄️'},
    {'id': 'birthday',  'label': 'Anniversaire', 'emoji': '🎂'},
    {'id': 'corporate', 'label': 'Entreprise', 'emoji': '💼'},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final groupId = await SecretSantaService.createGroup(
        name: _nameCtrl.text.trim().isEmpty ? 'Mon Secret Santa' : _nameCtrl.text.trim(),
        mode: 'personal',
        budgetMin: _budgetMin.round(),
        budgetMax: _budgetMax.round(),
        theme: _theme,
      );
      if (mounted) {
        context.pushReplacement('/secret-santa/lobby/$groupId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e', style: GoogleFonts.poppins()), backgroundColor: Colors.red[700]),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Créer un groupe', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Stepper indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: List.generate(2, (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 1 ? 8 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: i <= _step ? _violet : Colors.white.withOpacity(0.15),
                  ),
                ),
              )),
            ),
          ),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.3, 0), end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: _step == 0 ? _buildStep0() : _buildStep1(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Étape 0 : Nom + Thème ──────────────────────────────────────────────────

  Widget _buildStep0() {
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🎁 Nom du groupe',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
              .animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 6),
          Text('Comment s\'appelle votre Secret Santa ?',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Ex: Secret Santa Équipe Dev 🎄',
              hintStyle: GoogleFonts.poppins(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withOpacity(0.07),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _violet, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          ),
          const SizedBox(height: 32),
          Text('🎨 Thème',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.0,
            children: _themes.map((t) {
              final selected = _theme == t['id'];
              return GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); setState(() => _theme = t['id']!); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: selected
                        ? LinearGradient(colors: [_violet.withOpacity(0.5), _pink.withOpacity(0.3)])
                        : null,
                    color: selected ? null : Colors.white.withOpacity(0.07),
                    border: Border.all(
                      color: selected ? _violet : Colors.white.withOpacity(0.12),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t['emoji']!, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(t['label']!,
                          style: GoogleFonts.poppins(
                            color: selected ? Colors.white : Colors.white70,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 14,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () { HapticFeedback.mediumImpact(); setState(() => _step = 1); },
              style: ElevatedButton.styleFrom(
                backgroundColor: _violet,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Suivant →', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Étape 1 : Budget ────────────────────────────────────────────────────────

  Widget _buildStep1() {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💰 Budget par personne',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
              .animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 6),
          Text('Chaque participant offre dans cette fourchette',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 32),

          // Budget display
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_violet.withOpacity(0.2), _pink.withOpacity(0.1)]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _violet.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    '${_budgetMin.round()}€ – ${_budgetMax.round()}€',
                    style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('par participant', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Minimum
          Text('Minimum : ${_budgetMin.round()}€',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _violet,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              overlayColor: _violet.withOpacity(0.2),
            ),
            child: Slider(
              value: _budgetMin,
              min: 5, max: 200, divisions: 39,
              onChanged: (v) => setState(() {
                _budgetMin = v;
                if (_budgetMax < _budgetMin + 10) _budgetMax = _budgetMin + 10;
              }),
            ),
          ),

          const SizedBox(height: 8),

          // Maximum
          Text('Maximum : ${_budgetMax.round()}€',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _pink,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              overlayColor: _pink.withOpacity(0.2),
            ),
            child: Slider(
              value: _budgetMax,
              min: 15, max: 500, divisions: 97,
              onChanged: (v) => setState(() {
                _budgetMax = v;
                if (_budgetMin > _budgetMax - 10) _budgetMin = _budgetMax - 10;
              }),
            ),
          ),

          const SizedBox(height: 16),

          // Suggestions rapides
          Text('Suggestions rapides',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              {'label': '20 – 30€', 'min': 20.0, 'max': 30.0},
              {'label': '30 – 50€', 'min': 30.0, 'max': 50.0},
              {'label': '50 – 100€', 'min': 50.0, 'max': 100.0},
              {'label': '100 – 200€', 'min': 100.0, 'max': 200.0},
            ].map((p) => GestureDetector(
              onTap: () => setState(() {
                _budgetMin = p['min'] as double;
                _budgetMax = p['max'] as double;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Text(p['label'] as String,
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
              ),
            )).toList(),
          ),

          const SizedBox(height: 48),

          // Boutons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step = 0),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('← Retour', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _loading ? null : _create,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _violet,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('🎅 Créer le groupe', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
