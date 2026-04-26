const fs = require('fs');

// ─── F6: Ajouter la section suggestions de groupes dans le build() ───
const file = 'lib/pages/new_pages/chat/chat_list_page.dart';
let c = fs.readFileSync(file, 'utf8');

const tryReplace = (content, o, n, label) => {
  const oCR = o.replace(/\n/g, '\r\n'), nCR = n.replace(/\n/g, '\r\n');
  if (content.includes(oCR)) { console.log(label + ' OK CRLF'); return content.replace(oCR, nCR); }
  if (content.includes(o))   { console.log(label + ' OK LF');   return content.replace(o, n); }
  console.log('ERROR: ' + label);
  return content;
};

// 1. Ajouter imports nécessaires
const oldImports = `import 'create_chat_bottom_sheet.dart';`;
const newImports = `import 'create_chat_bottom_sheet.dart';
import '/services/birthday_service.dart'; // F6: suggestions anniversaire`;
c = tryReplace(c, oldImports, newImports, 'F6-imports');

// 2. Ajouter la section suggestions dans le Column
const oldColumn = `      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildChatsList(),
            ),
          ],
        ),
      ),`;

const newColumn = `      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            // F6: Suggestions de création de groupe
            _buildGroupSuggestions(),
            Expanded(
              child: _buildChatsList(),
            ),
          ],
        ),
      ),`;
c = tryReplace(c, oldColumn, newColumn, 'F6-column');

// 3. Ajouter les méthodes suggestions avant _buildHeader
const oldHeader = `  Widget _buildHeader() {`;
const newHeader = `  // ─── F6: Suggestions de groupe intelligentes ───────────────────────────────
  // Génère des cards de suggestions pour créer un groupe
  Widget _buildGroupSuggestions() {
    return FutureBuilder<List<Map<String,dynamic>>>(
      future: _loadGroupSuggestions(),
      builder: (ctx, snap) {
        final suggestions = snap.data ?? [];
        if (suggestions.isEmpty) return const SizedBox.shrink();
        return Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              final s = suggestions[i];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _openCreateChatWithSuggestion(s);
                },
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF8A2BE2).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s['emoji'] as String, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(
                        s['title'] as String,
                        style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text('Créer un groupe',
                        style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<List<Map<String,dynamic>>> _loadGroupSuggestions() async {
    final suggestions = <Map<String,dynamic>>[
      {'emoji': '🎉', 'title': 'Cadeau commun', 'type': 'gift'},
      {'emoji': '👨\u200d👩\u200d👧', 'title': 'Groupe Famille', 'type': 'family'},
      {'emoji': '👫', 'title': 'Déjeuner surprise', 'type': 'surprise'},
    ];

    // Ajouter une suggestion anniversaire si un ami fête son anniv dans 30 j
    try {
      final friendsBdays = await BirthdayService.getFriendsBirthdays();
      final now = DateTime.now();
      for (final friend in friendsBdays) {
        final day = friend['day'] as int;
        final month = friend['month'] as int;
        final thisYear = DateTime(now.year, month, day);
        final diff = thisYear.difference(now).inDays;
        if (diff >= 0 && diff <= 30) {
          suggestions.insert(0, {
            'emoji': '🎂',
            'title': 'Anniv de \${friend['name']} dans \${diff == 0 ? 'aujourd\'hui' : '\$diff j'}',
            'type': 'birthday',
            'friendName': friend['name'],
          });
          break;
        }
      }
    } catch (_) {}

    return suggestions;
  }

  void _openCreateChatWithSuggestion(Map<String,dynamic> suggestion) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: CreateChatBottomSheet(
            forceGroup: true,
            suggestedGroupName: suggestion['title'] as String,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {`;

c = tryReplace(c, oldHeader, newHeader, 'F6-suggestions-widget');
fs.writeFileSync(file, c, 'utf8');
console.log('F6 chat_list_page.dart done');
