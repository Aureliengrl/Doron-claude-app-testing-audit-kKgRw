import 'package:flutter/material.dart';
import '/utils/app_tr.dart';
import 'moment_type_page.dart';

/// Page onboarding — Quelle est l'occasion ?
/// Permet de capturer le contexte de la recherche de cadeau.
/// Les chips sélectionnées sont enregistrées dans le profil utilisateur
/// et converties en tags `occasion_*` par TagConverter.
class OccasionQuestionPage extends StatefulWidget {
  const OccasionQuestionPage({super.key, this.onComplete});
  static const routeName = '/occasion-question';
  final void Function(String occasion)? onComplete;

  @override
  State<OccasionQuestionPage> createState() => _OccasionQuestionPageState();
}

class _OccasionQuestionPageState extends State<OccasionQuestionPage> {
  String? _selected;

  static const _occasions = [
    {'label': '🎂 Anniversaire',       'value': 'anniversaire'},
    {'label': '🎄 Noël',               'value': 'noel'},
    {'label': '💝 Saint-Valentin',     'value': 'saint-valentin'},
    {'label': '💍 Mariage',            'value': 'mariage'},
    {'label': '🥳 Fête',              'value': 'fete'},
    {'label': '🙏 Remerciement',       'value': 'remerciement'},
    {'label': '👶 Naissance',          'value': 'naissance'},
    {'label': '🎓 Diplôme',           'value': 'diplome'},
    {'label': '🎁 Sans occasion',      'value': 'surprise'},
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
              Text('Pour quelle occasion ?',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: cs.onBackground, height: 1.2)),
              const SizedBox(height: 8),
              Text('Cela permet de personnaliser les idées de cadeaux.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 28),
              // Chips
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _occasions.map((occ) {
                      final isSelected = _selected == occ['value'];
                      return GestureDetector(
                        onTap: () => setState(() => _selected = occ['value']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? cs.primary : cs.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? cs.primary : cs.outline,
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: cs.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                : [],
                          ),
                          child: Text(
                            occ['label']!,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? cs.onPrimary : cs.onSurface,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              // CTA
              const SizedBox(height: 24),
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
                          widget.onComplete?.call(_selected!);
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => MomentTypePage(occasion: _selected),
                          ));
                        },
                  child: Text(context.tr('Continuer', 'Continue'),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              // Skip
              Center(
                child: TextButton(
                  onPressed: () {
                    widget.onComplete?.call('surprise');
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const MomentTypePage(occasion: 'surprise'),
                    ));
                  },
                  child: Text('Passer cette étape',
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
