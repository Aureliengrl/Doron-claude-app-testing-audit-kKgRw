import 'package:flutter/material.dart';

/// Page onboarding — Quel type de cadeau cherchez-vous ?
/// 3 options principales : objet physique, expérience, bon cadeau.
/// Cette information enrichit le profil avec des types de cadeaux préférés.
class MomentTypePage extends StatefulWidget {
  const MomentTypePage({super.key, this.onComplete, this.occasion});
  static const routeName = '/moment-type';

  final void Function(String momentType)? onComplete;
  final String? occasion;

  @override
  State<MomentTypePage> createState() => _MomentTypePageState();
}

class _MomentTypePageState extends State<MomentTypePage> {
  String? _selected;

  static const _options = <Map<String, Object>>[
    {
      'icon': '🎁',
      'title': 'Un objet à offrir',
      'subtitle': 'Quelque chose de concret, emballé, livré.',
      'value': 'product',
      'types': ['type_mode_accessoires', 'type_high_tech', 'type_beaute_soins', 'type_maison_deco'],
    },
    {
      'icon': '✨',
      'title': 'Une expérience',
      'subtitle': 'Spa, cours, sortie, aventure, dégustation.',
      'value': 'experience',
      'types': ['type_voyage_aventure', 'type_bien_etre', 'type_gastronomie', 'type_culture'],
    },
    {
      'icon': '🃏',
      'title': 'Un bon cadeau',
      'subtitle': 'Flexible, carte, abonnement, crédit.',
      'value': 'voucher',
      'types': ['type_culture', 'type_musique_audio', 'type_livres_bd'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.arrow_back_rounded, color: cs.onSurface, size: 22),
                ),
              ),
              const SizedBox(height: 32),
              // Title
              Text('Quel type de cadeau ?',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: cs.onBackground, height: 1.2)),
              const SizedBox(height: 8),
              Text('Pour affiner les suggestions selon vos envies.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 32),
              // Option cards
              Expanded(
                child: Column(
                  children: _options.map((opt) {
                    final isSelected = _selected == opt['value'] as String;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = opt['value'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cs.primary.withOpacity(0.08)
                              : cs.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? cs.primary : cs.outline,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: cs.primary.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))]
                              : [const BoxShadow(color: Color(0x0A000000), blurRadius: 6)],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cs.primary.withOpacity(0.15)
                                    : cs.surfaceVariant,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(opt['icon'] as String,
                                  style: const TextStyle(fontSize: 26)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    opt['title'] as String,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? cs.primary : cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    opt['subtitle'] as String,
                                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, color: cs.primary, size: 24),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selected != null ? cs.primary : cs.surfaceVariant,
                    foregroundColor: _selected != null ? cs.onPrimary : cs.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: _selected != null ? 4 : 0,
                  ),
                  onPressed: _selected == null
                      ? null
                      : () {
                          final selectedOpt = _options.firstWhere(
                              (o) => o['value'] == _selected);
                          final types = selectedOpt['types'] as List<String>;
                          widget.onComplete?.call(_selected!);
                          Navigator.of(context).pop({
                            'momentType': _selected,
                            'giftTypes': types,
                            'occasion': widget.occasion,
                          });
                        },
                  child: const Text('Voir les idées ✨',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              // Skip
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop({'momentType': 'all'}),
                  child: Text('Tout voir',
                      style: TextStyle(color: cs.outline, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
