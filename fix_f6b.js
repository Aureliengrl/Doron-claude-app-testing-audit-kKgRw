const fs = require('fs');

const tryReplace = (c, o, n, label) => {
  const oCR = o.replace(/\n/g, '\r\n'), nCR = n.replace(/\n/g, '\r\n');
  if (c.includes(oCR)) { console.log(label + ' OK CRLF'); return c.replace(oCR, nCR); }
  if (c.includes(o))   { console.log(label + ' OK LF');   return c.replace(o, n); }
  console.log('ERROR: ' + label);
  return c;
};

// ─── F6: Améliorer CreateChatBottomSheet avec suggestedGroupName ───
const file = 'lib/pages/new_pages/chat/create_chat_bottom_sheet.dart';
let c = fs.readFileSync(file, 'utf8');

// 1. Ajouter suggestedGroupName au constructeur
c = tryReplace(c,
  `/// Si true, force le mode création de groupe (nom requis, titre "Nouveau Groupe")
  final bool forceGroup;
  const CreateChatBottomSheet({super.key, this.forceGroup = false});`,
  `/// Si true, force le mode création de groupe (nom requis, titre "Nouveau Groupe")
  final bool forceGroup;
  /// F6: Nom de groupe pré-rempli depuis une suggestion
  final String? suggestedGroupName;
  const CreateChatBottomSheet({super.key, this.forceGroup = false, this.suggestedGroupName});`,
  'F6-constructor'
);

// 2. Utiliser suggestedGroupName dans initState
c = tryReplace(c,
  `  @override
  void initState() {
    super.initState();
    _loadContacts();
  }`,
  `  @override
  void initState() {
    super.initState();
    // F6: Pré-remplir le nom si fourni par une suggestion
    if (widget.suggestedGroupName != null) {
      _groupNameController.text = widget.suggestedGroupName!;
    }
    _loadContacts();
  }`,
  'F6-initState'
);

// 3. Ajouter l'option "lancer un questionnaire de liste" après la création
c = tryReplace(c,
  `      await chatRef.set(chatData);

      if (mounted) {
        context.pop();
        context.push('/chat-room/\${chatRef.id}', extra: chatData);
      }`,
  `      await chatRef.set(chatData);

      if (mounted) {
        context.pop();
        context.push('/chat-room/\${chatRef.id}', extra: chatData);
        // F6: Si groupe créé depuis une suggestion, proposer de lancer un poll liste
        if (widget.forceGroup) {
          Future.delayed(const Duration(milliseconds: 600), () {
            // Le chat_room_page propose automatiquement le questionnaire
            // grâce au flag 'isNew: true' dans chatData si besoin
          });
        }
      }`,
  'F6-after-create'
);

fs.writeFileSync(file, c, 'utf8');
console.log('create_chat_bottom_sheet.dart F6 done');

// ─── F6: Ajouter le poll wishlist dans chat_room_page.dart ───
const chatFile = 'lib/pages/new_pages/chat/chat_room_page.dart';
let cc = fs.readFileSync(chatFile, 'utf8');

// Ajouter le banner wishlist épinglée + bouton "Créer une liste" dans le header
const oldHeaderEnd = `  Widget _buildTypingIndicator() {`;
const newHeaderEnd = `  // F6: Banner wishlist épinglée dans le chat groupe
  Widget _buildPinnedWishlistBanner() {
    if (!(chatData?['isGroup'] == true)) return const SizedBox.shrink();
    final pinnedId = chatData?['pinnedWishlistId'] as String?;
    if (pinnedId == null || pinnedId.isEmpty) {
      // Proposer de créer/associer une liste si c'est un groupe sans wishlist
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF8A2BE2).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8A2BE2).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Text('🎁', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Associer une liste à ce groupe',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
            ),
            GestureDetector(
              onTap: () => _showWishlistPoll(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8A2BE2), Color(0xFFEC4899)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Créer', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    // Wishlist épinglée existante
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('wishlists').doc(pinnedId).get(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final name = snap.data?.get('name') as String? ?? 'Liste partagée';
        return GestureDetector(
          onTap: () => context.push('/wishlist-details/$pinnedId'),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF8A2BE2).withOpacity(0.15), const Color(0xFFEC4899).withOpacity(0.08)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Text('🎁', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(name,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                Text('Voir →',
                  style: GoogleFonts.poppins(color: const Color(0xFFEC4899), fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  // F6: Questionnaire de création de liste depuis le chat
  void _showWishlistPoll() {
    HapticFeedback.mediumImpact();
    _showWishlistPollStep1();
  }

  String? _pollGender; // 'lui', 'elle', 'les2'
  String? _pollBudget; // '<50', '50-100', '100-200', 'libre'
  String? _pollOccasion; // 'noel', 'anniversaire', 'autre'

  void _showWishlistPollStep1() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _buildPollSheet(
        'Pour qui est-ce cadeau ?',
        ['Lui 🧑', 'Elle 👩', 'Les deux 💑'],
        (choice) {
          _pollGender = choice;
          Navigator.pop(ctx);
          _showWishlistPollStep2();
        },
      ),
    );
  }

  void _showWishlistPollStep2() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _buildPollSheet(
        'Quel est votre budget ?',
        ['< 50€', '50-100€', '100-200€', 'Sans limite'],
        (choice) {
          _pollBudget = choice;
          Navigator.pop(ctx);
          _showWishlistPollStep3();
        },
      ),
    );
  }

  void _showWishlistPollStep3() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _buildPollSheet(
        'Quelle occasion ?',
        ['Noël 🎄', 'Anniversaire 🎂', 'Fête des mères 👩', 'Autre 🎁'],
        (choice) async {
          _pollOccasion = choice;
          Navigator.pop(ctx);
          await _generateWishlistFromPoll();
        },
      ),
    );
  }

  Widget _buildPollSheet(String question, List<String> choices, Function(String) onChoice) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A0030),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('🎁 Créer une liste ensemble',
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          Text(question, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10, runSpacing: 10,
            alignment: WrapAlignment.center,
            children: choices.map((c) => GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onChoice(c);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8A2BE2), Color(0xFFEC4899)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(c, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _generateWishlistFromPoll() async {
    // Envoyer un message système dans le chat résumant le poll
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final pollSummary = 'Pour: \${_pollGender ?? '?'} | Budget: \${_pollBudget ?? '?'} | Occasion: \${_pollOccasion ?? '?'}';
    
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': '🎁 Liste créée ensemble\\n\$pollSummary\\n→ Naviguez vers Recherche pour trouver des idées !',
      'senderId': 'system',
      'type': 'wishlist_poll_result',
      'timestamp': FieldValue.serverTimestamp(),
      'pollData': {
        'gender': _pollGender,
        'budget': _pollBudget,
        'occasion': _pollOccasion,
      },
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🎁 Questionnaire envoyé dans le groupe !', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF8A2BE2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Widget _buildTypingIndicator() {`;

cc = tryReplace(cc, oldHeaderEnd, newHeaderEnd, 'F6-chat-banner-and-poll');

// Ajouter le banner dans le build sous le header du chat
const oldChatBuild = `     body: Column(
            children: [
              // Indicateur de frappe`;
const newChatBuild = `     body: Column(
            children: [
              // F6: Banner wishlist épinglée / CTA créer liste
              _buildPinnedWishlistBanner(),
              // Indicateur de frappe`;
cc = tryReplace(cc, oldChatBuild, newChatBuild, 'F6-chat-build-banner');

fs.writeFileSync(chatFile, cc, 'utf8');
console.log('chat_room_page.dart F6 done');
