const fs = require('fs');
const file = 'lib/pages/new_pages/chat/chat_room_page.dart';
let c = fs.readFileSync(file, 'utf8');

// 1. Ajouter l'import OccasionQuestionPage au début
const oldImport = `import '/services/firebase_data_service.dart';`;
const newImport = `import '/services/firebase_data_service.dart';
import '/pages/new_pages/occasion_question_page.dart'; // F6: flow questionnaire complet`;

c = c.replace(oldImport, newImport);
console.log('import added:', c.includes(newImport));

// 2. Remplacer tout le bloc "F6: Questionnaire de création..." jusqu'avant _buildTypingIndicator
const pollStart = c.indexOf('// F6: Questionnaire de cr');
const typingStart = c.indexOf('\r\n  Widget _buildTypingIndicator()');

if (pollStart < 0 || typingStart < 0) {
  console.log('ERROR: block not found', pollStart, typingStart);
  process.exit(1);
}

const before = c.substring(0, pollStart);
const after = c.substring(typingStart); // inclut \r\n  Widget _buildTypingIndicator()

// Nouveau code : lancer le vrai questionnaire existant via Navigator.push
const newPollCode = `// F6: Lance le questionnaire existant complet (OccasionQuestionPage -> MomentTypePage)
  void _showWishlistPoll() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => OccasionQuestionPage(
          onComplete: (String occasion) {
            // Called after OccasionQuestionPage, before MomentTypePage
            // The actual result comes back via Navigator.pop in MomentTypePage
          },
        ),
      ),
    ).then((result) async {
      // result = {'momentType': '...', 'giftTypes': [...], 'occasion': '...'}
      // (retourné par Navigator.pop dans MomentTypePage)
      if (result == null || !mounted) return;

      final occasion = result['occasion'] as String? ?? '';
      final momentType = result['momentType'] as String? ?? '';
      final giftTypes = (result['giftTypes'] as List?)?.join(', ') ?? '';

      // Envoyer un message récapitulatif dans le chat du groupe
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final occasionLabels = {
        'anniversaire': '🎂 Anniversaire',
        'noel': '🎄 Noël',
        'saint-valentin': '💝 Saint-Valentin',
        'mariage': '💍 Mariage',
        'fete': '🥳 Fête',
        'remerciement': '🙏 Remerciement',
        'naissance': '👶 Naissance',
        'diplome': '🎓 Diplôme',
        'surprise': '🎁 Sans occasion',
      };

      final momentLabels = {
        'product': '🎁 Un objet à offrir',
        'experience': '✨ Une expérience',
        'voucher': '🃏 Un bon cadeau',
        'all': '🌟 Tout voir',
      };

      final occasionLabel = occasionLabels[occasion] ?? occasion;
      final momentLabel = momentLabels[momentType] ?? momentType;

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'text': '🎁 Idées cadeaux en cours...\\n\\n'
            '📅 Occasion : \$occasionLabel\\n'
            '🛍 Type : \$momentLabel\\n\\n'
            '➡️ Voir les suggestions dans Recherche → Trouver un cadeau',
        'senderId': 'system',
        'type': 'wishlist_poll_result',
        'timestamp': FieldValue.serverTimestamp(),
        'pollData': {
          'occasion': occasion,
          'momentType': momentType,
          'giftTypes': giftTypes,
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🎁 Questionnaire envoyé dans le groupe !',
              style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFF8A2BE2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    });
  }

`;

c = before + newPollCode + after;
fs.writeFileSync(file, c, 'utf8');
console.log('F6 poll replaced with full OccasionQuestionPage flow, file length:', c.length);
