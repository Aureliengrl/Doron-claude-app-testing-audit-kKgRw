import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '/utils/app_tr.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/services/firebase_data_service.dart';
import '/services/group_gift_service.dart';

/// Page centrale du mode « Cadeau de groupe » (cagnotte).
///
/// Une seule page, deux visages :
///   - HÔTE  → tableau de bord : choisir le cadeau retenu, répartir, lancer la
///     collecte, confirmer/refuser chaque paiement, voir l'avancement.
///   - PARTICIPANT → vue simple : voir le cadeau retenu, sa part, payer l'hôte,
///     déclarer « j'ai envoyé », suivre son statut.
class GroupGiftPage extends StatefulWidget {
  final String collabId;
  final String chatId;
  final String profileName;
  final String ownerId;
  final List<Map<String, dynamic>> gifts;

  const GroupGiftPage({
    super.key,
    required this.collabId,
    required this.chatId,
    required this.profileName,
    required this.ownerId,
    this.gifts = const [],
  });

  static const String routeName = 'GroupGift';
  static const String routePath = '/group-gift/:collabId';

  @override
  State<GroupGiftPage> createState() => _GroupGiftPageState();
}

class _GroupGiftPageState extends State<GroupGiftPage> {
  static const _violet = Color(0xFF8A2BE2);
  static const _pink = Color(0xFFEC4899);
  static const _green = Color(0xFF10B981);
  static const _amber = Color(0xFFF59E0B);
  static const _bg = Color(0xFF0E0B14);
  static const _card = Color(0xFF1A1622);

  bool get _isHost => (FirebaseDataService.currentUserId ?? currentUserUid) == widget.ownerId;

  String _eur(num v) => '${v.toStringAsFixed(2)} €';

  // ─── Actions hôte ─────────────────────────────────────────────────────────

  Future<void> _pickRetained(Map<String, dynamic> gift) async {
    try {
      await GroupGiftService.setRetainedGift(
        collabId: widget.collabId,
        chatId: widget.chatId,
        gift: gift,
      );
      _toast(context.tr('Cadeau retenu ✅', 'Gift selected ✅'));
    } catch (e) {
      _toast(context.tr('Erreur, réessaie', 'Something went wrong'), error: true);
    }
  }

  Future<void> _confirmParticipant(String uid) async {
    try {
      await GroupGiftService.confirmPayment(
        collabId: widget.collabId,
        chatId: widget.chatId,
        participantUid: uid,
        participantName: await _userName(uid),
      );
      _toast(context.tr('Paiement confirmé ✅', 'Payment confirmed ✅'));
    } catch (_) {
      _toast(context.tr('Erreur, réessaie', 'Something went wrong'), error: true);
    }
  }

  Future<void> _refuseParticipant(String uid) async {
    final note = await _askNote();
    try {
      await GroupGiftService.refusePayment(
        collabId: widget.collabId,
        chatId: widget.chatId,
        participantUid: uid,
        note: note,
      );
    } catch (_) {
      _toast(context.tr('Erreur, réessaie', 'Something went wrong'), error: true);
    }
  }

  // ─── Actions participant ────────────────────────────────────────────────

  Future<void> _payHost(Map<String, dynamic> payment, double amount) async {
    final method = (payment['method'] ?? 'link').toString();
    final url = _payUrl(payment);
    if (url != null) {
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        return;
      } catch (_) {/* fallback ci-dessous */}
    }
    // Pas de lien direct (IBAN / Wero) → afficher les infos + copier
    final holder = (payment['holderName'] ?? '').toString();
    final iban = (payment['iban'] ?? '').toString();
    final handle = (payment['handle'] ?? '').toString();
    final detail = method == 'iban'
        ? '$iban${holder.isNotEmpty ? '\n$holder' : ''}'
        : handle;
    await showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 34),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(context.tr('Payer ${_eur(amount)}', 'Pay ${_eur(amount)}'),
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 14),
          SelectableText(detail,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 15, color: Colors.white70)),
          const SizedBox(height: 18),
          _bigButton(context.tr('Copier', 'Copy'), () {
            Clipboard.setData(ClipboardData(text: method == 'iban' ? iban : handle));
            Navigator.pop(ctx);
            _toast(context.tr('Copié', 'Copied'));
          }),
        ]),
      ),
    );
  }

  Future<void> _declareSent() async {
    try {
      await GroupGiftService.declarePayment(
        collabId: widget.collabId,
        chatId: widget.chatId,
        profileName: widget.profileName,
        myName: await _myName(),
      );
      _toast(context.tr('Envoyé ! L\'hôte va confirmer.', 'Sent! The host will confirm.'));
    } catch (_) {
      _toast(context.tr('Erreur, réessaie', 'Something went wrong'), error: true);
    }
  }

  // ─── Répartition + lancement de la collecte (hôte) ──────────────────────

  Future<void> _openCollectionSetup({
    required double total,
    required List<String> memberUids,
  }) async {
    // Résoudre les noms pour l'écran de répartition.
    final names = <String, String>{};
    for (final uid in memberUids) {
      names[uid] = await _userName(uid);
    }
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _CollectionSetupSheet(
        collabId: widget.collabId,
        chatId: widget.chatId,
        profileName: widget.profileName,
        total: total,
        memberUids: memberUids,
        names: names,
        hostUid: widget.ownerId,
        onDone: () {
          Navigator.pop(ctx);
          _toast(context.tr('Collecte lancée 🎉', 'Collection started 🎉'));
        },
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  String? _payUrl(Map<String, dynamic> payment) {
    final url = (payment['url'] ?? '').toString();
    if (url.isNotEmpty) return url;
    final method = (payment['method'] ?? '').toString();
    final handle = (payment['handle'] ?? '').toString().replaceAll('@', '').trim();
    if (method == 'revolut' && handle.isNotEmpty) return 'https://revolut.me/$handle';
    if (method == 'lydia' && handle.isNotEmpty) return handle.startsWith('http') ? handle : 'https://lydia-app.com/collect/$handle';
    if (method == 'paypal' && handle.isNotEmpty) return handle.startsWith('http') ? handle : 'https://paypal.me/$handle';
    return null;
  }

  Future<String> _myName() => _userName(FirebaseDataService.currentUserId ?? currentUserUid);

  Future<String> _userName(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final d = doc.data() ?? {};
      return (d['first_name'] ?? d['display_name'] ?? d['displayName'] ?? 'Quelqu\'un')
          .toString();
    } catch (_) {
      return 'Quelqu\'un';
    }
  }

  Future<String?> _askNote() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        title: Text(context.tr('Paiement non reçu ?', 'Payment not received?'),
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 17)),
        content: TextField(
          controller: ctrl,
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            hintText: context.tr('Note (optionnel)', 'Note (optional)'),
            hintStyle: GoogleFonts.poppins(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('Annuler', 'Cancel'),
                  style: GoogleFonts.poppins(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text(context.tr('Confirmer', 'Confirm'),
                  style: GoogleFonts.poppins(color: _pink, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      backgroundColor: error ? Colors.red.shade700 : _violet,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/search-page'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('Cadeau de groupe', 'Group gift'),
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            Text(widget.profileName,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: context.tr('Ouvrir le chat', 'Open chat'),
            icon: const Icon(Icons.forum_rounded, color: Colors.white, size: 22),
            onPressed: () => context.push('/chat-room/${widget.chatId}', extra: {
              'name': 'Cadeaux pour ${widget.profileName}',
              'isGroup': true,
            }),
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: GroupGiftService.groupStream(widget.collabId),
        builder: (context, groupSnap) {
          final group = groupSnap.data ?? {};
          final retained = (group['retainedGift'] as Map?)?.cast<String, dynamic>();
          final collection = (group['collection'] as Map?)?.cast<String, dynamic>();
          final payment = (group['payment'] as Map?)?.cast<String, dynamic>() ?? {};
          final members = ((group['members'] as List?) ?? const [])
              .map((e) => e.toString())
              .toList();
          final collectionOpen = (collection?['status'] == 'open');

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: GroupGiftService.participantsStream(widget.collabId),
            builder: (context, partSnap) {
              final participants = partSnap.data ?? const [];
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: [
                  _roleBanner(),
                  const SizedBox(height: 16),
                  _retainedSection(retained, collectionOpen),
                  const SizedBox(height: 20),
                  if (collectionOpen)
                    _collectionSection(collection!, payment, participants)
                  else if (_isHost && retained != null)
                    _launchCollectionCta(retained, members),
                  const SizedBox(height: 8),
                  if (collectionOpen) _participantsSection(collection!, participants),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _roleBanner() {
    final host = _isHost;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: (host ? _violet : const Color(0xFF2A7DB8)).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: (host ? _violet : const Color(0xFF2A7DB8)).withOpacity(0.4)),
      ),
      child: Row(children: [
        Icon(host ? Icons.workspace_premium_rounded : Icons.groups_rounded,
            color: host ? _violet : const Color(0xFF63B3E6), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            host
                ? context.tr('Tu es l\'hôte — tu pilotes la cagnotte.',
                    'You\'re the host — you run the pot.')
                : context.tr('Tu participes — suis les étapes ci-dessous.',
                    'You\'re a participant — follow the steps below.'),
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
          ),
        ),
      ]),
    );
  }

  Widget _retainedSection(Map<String, dynamic>? retained, bool locked) {
    if (retained != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _green.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _green.withOpacity(0.6), width: 1.5),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: (retained['image'] ?? '').toString().isNotEmpty
                ? Image.network(retained['image'], width: 60, height: 60, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _giftPlaceholder())
                : _giftPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.check_circle_rounded, color: _green, size: 16),
                const SizedBox(width: 5),
                Text(context.tr('CADEAU RETENU', 'CHOSEN GIFT'),
                    style: GoogleFonts.poppins(
                        fontSize: 11, fontWeight: FontWeight.w700, color: _green, letterSpacing: 0.5)),
              ]),
              const SizedBox(height: 3),
              Text((retained['name'] ?? '').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              if ((retained['price'] ?? 0) != 0)
                Text(_eur(retained['price'] as num),
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60)),
            ]),
          ),
          if (_isHost && !locked)
            IconButton(
              tooltip: context.tr('Changer', 'Change'),
              icon: const Icon(Icons.edit_rounded, color: Colors.white54, size: 18),
              onPressed: () => GroupGiftService.clearRetainedGift(collabId: widget.collabId),
            ),
        ]),
      );
    }

    // Pas encore de cadeau retenu
    if (!_isHost) {
      return _infoCard(
        Icons.hourglass_empty_rounded,
        context.tr('En attente du choix de l\'hôte',
            'Waiting for the host\'s choice'),
        context.tr('L\'hôte va choisir le cadeau retenu parmi les idées du groupe.',
            'The host will pick the chosen gift from the group\'s ideas.'),
      );
    }

    // Hôte : sélectionner parmi les candidats
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(context.tr('Choisis le cadeau retenu', 'Choose the chosen gift'),
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 4),
      Text(
        context.tr('Il passera en vert pour tout le monde.',
            'It will turn green for everyone.'),
        style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white54),
      ),
      const SizedBox(height: 12),
      if (widget.gifts.isEmpty)
        _infoCard(
          Icons.card_giftcard_rounded,
          context.tr('Aucun cadeau dans la liste', 'No gift in the list yet'),
          context.tr('Ajoute des idées à la liste, puis reviens ici pour en retenir un.',
              'Add ideas to the list, then come back to pick one.'),
        )
      else
        ...widget.gifts.take(30).map((g) => _candidateTile(g)),
    ]);
  }

  Widget _candidateTile(Map<String, dynamic> g) {
    final img = (g['image'] ?? g['imageUrl'] ?? g['image_url'] ?? '').toString();
    final name = (g['name'] ?? g['title'] ?? 'Cadeau').toString();
    final price = g['price'];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: img.isNotEmpty
              ? Image.network(img, width: 46, height: 46, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _giftPlaceholder(size: 46))
              : _giftPlaceholder(size: 46),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white)),
            if (price != null && price != 0)
              Text(_eur(price is num ? price : 0),
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54)),
          ]),
        ),
        TextButton(
          onPressed: () => _pickRetained(g),
          style: TextButton.styleFrom(
            backgroundColor: _green.withOpacity(0.15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(context.tr('Retenir', 'Choose'),
              style: GoogleFonts.poppins(
                  fontSize: 12.5, fontWeight: FontWeight.w700, color: _green)),
        ),
      ]),
    );
  }

  Widget _launchCollectionCta(Map<String, dynamic> retained, List<String> members) {
    final total = (retained['price'] as num?)?.toDouble() ?? 0;
    return Column(children: [
      _bigButton(
        context.tr('Répartir & lancer la collecte', 'Split & start collection'),
        () => _openCollectionSetup(total: total, memberUids: members),
        icon: Icons.pie_chart_rounded,
      ),
      const SizedBox(height: 8),
      Text(
        context.tr('${members.length} membre(s) · total ${_eur(total)}',
            '${members.length} member(s) · total ${_eur(total)}'),
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38),
      ),
    ]);
  }

  Widget _collectionSection(
    Map<String, dynamic> collection,
    Map<String, dynamic> payment,
    List<Map<String, dynamic>> participants,
  ) {
    final total = (collection['total'] as num?)?.toDouble() ?? 0;
    final confirmed = participants.where((p) => p['status'] == 'confirmed').toList();
    final collected =
        confirmed.fold<double>(0, (s, p) => s + ((p['share'] as num?)?.toDouble() ?? 0));
    final myPart = participants.where((p) => p['uid'] == (FirebaseDataService.currentUserId ?? currentUserUid)).toList();
    final mine = myPart.isEmpty ? null : myPart.first;

    return Column(children: [
      // Vue d'ensemble (toujours visible)
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(context.tr('Avancement', 'Progress'),
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.white60, fontWeight: FontWeight.w600)),
            Text('${confirmed.length}/${participants.length} · ${_eur(collected)} / ${_eur(total)}',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : (collected / total).clamp(0, 1),
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(_green),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      // Bloc « ma part » (participant redevable)
      if (!_isHost && mine != null) _myPartCard(mine, payment),
      if (_isHost)
        Align(
          alignment: Alignment.centerLeft,
          child: Text(context.tr('Participants', 'Participants'),
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
    ]);
  }

  Widget _myPartCard(Map<String, dynamic> mine, Map<String, dynamic> payment) {
    final status = (mine['status'] ?? 'due').toString();
    final amount = (mine['share'] as num?)?.toDouble() ?? 0;
    final confirmed = status == 'confirmed';
    final declared = status == 'declared';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: confirmed
              ? [_green.withOpacity(0.25), _green.withOpacity(0.08)]
              : [_violet.withOpacity(0.3), _pink.withOpacity(0.12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: confirmed ? _green.withOpacity(0.6) : Colors.white12),
      ),
      child: Column(children: [
        Text(context.tr('Ta part', 'Your share'),
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60)),
        const SizedBox(height: 4),
        Text(_eur(amount),
            style: GoogleFonts.poppins(
                fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 14),
        if (confirmed)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.verified_rounded, color: _green, size: 18),
            const SizedBox(width: 6),
            Text(context.tr('Payé & confirmé', 'Paid & confirmed'),
                style: GoogleFonts.poppins(
                    color: _green, fontWeight: FontWeight.w700, fontSize: 14)),
          ])
        else ...[
          _bigButton(
            context.tr('Payer l\'hôte', 'Pay the host'),
            () => _payHost(payment, amount),
            icon: Icons.account_balance_wallet_rounded,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: declared ? null : _declareSent,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              side: BorderSide(color: declared ? _amber : Colors.white24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: Text(
              declared
                  ? context.tr('Envoyé — en attente de l\'hôte', 'Sent — awaiting host')
                  : context.tr('J\'ai envoyé l\'argent', 'I\'ve sent the money'),
              style: GoogleFonts.poppins(
                  color: declared ? _amber : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _participantsSection(
      Map<String, dynamic> collection, List<Map<String, dynamic>> participants) {
    if (!_isHost) return const SizedBox.shrink();
    return Column(
      children: participants
          .map((p) => _ParticipantTile(
                key: ValueKey(p['uid']),
                data: p,
                eur: _eur,
                onConfirm: () => _confirmParticipant(p['uid'].toString()),
                onRefuse: () => _refuseParticipant(p['uid'].toString()),
                resolveName: _userName,
              ))
          .toList(),
    );
  }

  // ─── petits widgets ───────────────────────────────────────────────────────

  Widget _giftPlaceholder({double size = 60}) => Container(
        width: size,
        height: size,
        color: Colors.white10,
        child: const Icon(Icons.card_giftcard_rounded, color: Colors.white38),
      );

  Widget _infoCard(IconData icon, String title, String sub) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(children: [
          Icon(icon, color: Colors.white38, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 2),
              Text(sub, style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white54)),
            ]),
          ),
        ]),
      );

  Widget _bigButton(String label, VoidCallback onTap, {IconData? icon}) => GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_violet, _pink]),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: _pink.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
      );
}

/// Ligne d'un participant côté hôte : nom, montant, statut, et action de pointage direct.
class _ParticipantTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final String Function(num) eur;
  final VoidCallback onConfirm;
  final VoidCallback onRefuse;
  final Future<String> Function(String) resolveName;

  const _ParticipantTile({
    super.key,
    required this.data,
    required this.eur,
    required this.onConfirm,
    required this.onRefuse,
    required this.resolveName,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF10B981);
    const amber = Color(0xFFF59E0B);
    const pink = Color(0xFFEC4899);
    final status = (data['status'] ?? 'due').toString();
    final amount = (data['share'] as num?)?.toDouble() ?? 0;

    Color dotColor;
    String label;
    switch (status) {
      case 'confirmed':
        dotColor = green;
        label = context.tr('Payé ✓', 'Paid ✓');
        break;
      case 'declared':
        dotColor = amber;
        label = context.tr('En attente de validation', 'Awaiting validation');
        break;
      case 'refused':
        dotColor = Colors.red;
        label = context.tr('Refusé', 'Refused');
        break;
      default:
        dotColor = Colors.white30;
        label = context.tr('En attente', 'Pending');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1622),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'confirmed' ? green.withOpacity(0.5) : Colors.white12,
          width: 1,
        ),
        boxShadow: [
          if (status == 'confirmed')
            BoxShadow(
              color: green.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: status == 'confirmed' ? green : (status == 'declared' ? amber : Colors.transparent),
            border: Border.all(color: dotColor, width: 2),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FutureBuilder<String>(
            future: resolveName(data['uid'].toString()),
            builder: (context, snap) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snap.data ?? 'Membre',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${eur(amount)} · $label',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: status == 'confirmed' ? green : Colors.white54,
                    fontWeight: status == 'confirmed' ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Actions de validation pour l'hôte
        if (status == 'declared') ...[
          GestureDetector(
            onTap: onConfirm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: green),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, color: green, size: 16),
                  const SizedBox(width: 4),
                  Text('Valider', style: GoogleFonts.poppins(color: green, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRefuse,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
              ),
              child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 16),
            ),
          ),
        ] else if (status == 'confirmed')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: green.withOpacity(0.6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, color: green, size: 16),
                const SizedBox(width: 4),
                Text('Reçu ✓', style: GoogleFonts.poppins(color: green, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: onConfirm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF8A2BE2), pink]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: pink.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text('Marquer reçu', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
      ]),
    );
  }
}

/// Feuille de répartition + saisie du moyen de paiement + lancement.
class _CollectionSetupSheet extends StatefulWidget {
  final String collabId;
  final String chatId;
  final String profileName;
  final double total;
  final List<String> memberUids;
  final Map<String, String> names;
  final String hostUid;
  final VoidCallback onDone;

  const _CollectionSetupSheet({
    required this.collabId,
    required this.chatId,
    required this.profileName,
    required this.total,
    required this.memberUids,
    required this.names,
    required this.hostUid,
    required this.onDone,
  });

  @override
  State<_CollectionSetupSheet> createState() => _CollectionSetupSheetState();
}

class _CollectionSetupSheetState extends State<_CollectionSetupSheet> {
  static const _violet = Color(0xFF8A2BE2);
  static const _pink = Color(0xFFEC4899);

  bool _custom = false;
  bool _hostPays = false; // l'hôte avance par défaut → ne paie pas de part
  final Map<String, bool> _included = {};
  final Map<String, TextEditingController> _amountCtrls = {};

  String _method = 'revolut';
  final _handleCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final uid in widget.memberUids) {
      // Par défaut tout le monde est inclus, sauf l'hôte.
      _included[uid] = uid != widget.hostUid;
      _amountCtrls[uid] = TextEditingController();
    }
    // Pas de setState ici : on est dans initState, le build n'a pas eu lieu.
    _computeEqualShares();
  }

  List<String> get _includedUids =>
      widget.memberUids.where((u) => _included[u] == true).toList();

  /// Remplit les champs de montant en parts égales. Ne déclenche PAS de
  /// rebuild — les appelants (hors initState) encadrent déjà par setState.
  void _computeEqualShares() {
    if (_custom) return; // en mode perso, on ne touche pas aux montants saisis
    final uids = _includedUids;
    final split = GroupGiftService.computeEqualSplit(widget.total, uids);
    for (final uid in widget.memberUids) {
      _amountCtrls[uid]!.text =
          split.containsKey(uid) ? (split[uid]!).toStringAsFixed(2) : '';
    }
  }

  double get _sumEntered {
    double s = 0;
    for (final uid in _includedUids) {
      s += double.tryParse(_amountCtrls[uid]!.text.replaceAll(',', '.')) ?? 0;
    }
    return s;
  }

  Future<void> _launch() async {
    final shares = <String, double>{};
    for (final uid in _includedUids) {
      final v = double.tryParse(_amountCtrls[uid]!.text.replaceAll(',', '.')) ?? 0;
      if (v > 0) shares[uid] = v;
    }
    if (shares.isEmpty) return;

    final payment = <String, dynamic>{
      'method': _method,
      'handle': _handleCtrl.text.trim(),
      'iban': _ibanCtrl.text.trim(),
      'holderName': _holderCtrl.text.trim(),
      'url': _urlCtrl.text.trim(),
    };

    setState(() => _saving = true);
    try {
      await GroupGiftService.startCollection(
        collabId: widget.collabId,
        chatId: widget.chatId,
        profileName: widget.profileName,
        total: widget.total,
        splitType: _custom ? 'custom' : 'equal',
        shares: shares,
        payment: payment,
      );
      widget.onDone();
    } catch (_) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.tr('Erreur, réessaie', 'Something went wrong')),
          backgroundColor: Colors.red.shade700,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final diff = (_sumEntered - widget.total);
    final balanced = diff.abs() < 0.01;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text(context.tr('Répartir ${widget.total.toStringAsFixed(2)} €',
              'Split ${widget.total.toStringAsFixed(2)} €'),
              style: GoogleFonts.poppins(
                  fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 14),

          // Bascule égal / perso
          Row(children: [
            _segButton(context.tr('Parts égales', 'Equal'), !_custom, () {
              setState(() => _custom = false);
              _computeEqualShares();
            }),
            const SizedBox(width: 8),
            _segButton(context.tr('Personnalisé', 'Custom'), _custom, () {
              setState(() => _custom = true);
            }),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Checkbox(
              value: _hostPays,
              activeColor: _violet,
              onChanged: (v) {
                setState(() {
                  _hostPays = v ?? false;
                  _included[widget.hostUid] = _hostPays;
                });
                _computeEqualShares();
              },
            ),
            Expanded(
              child: Text(
                context.tr('L\'hôte participe aussi au paiement',
                    'Host also chips in'),
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
              ),
            ),
          ]),
          const SizedBox(height: 6),

          // Liste des membres avec montant
          ...widget.memberUids.map((uid) => _memberRow(uid)),

          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(context.tr('Total réparti', 'Split total'),
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60)),
            Text('${_sumEntered.toStringAsFixed(2)} € / ${widget.total.toStringAsFixed(2)} €',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: balanced ? const Color(0xFF10B981) : const Color(0xFFF59E0B))),
          ]),

          const Divider(color: Colors.white12, height: 28),

          // Moyen de paiement de l'hôte
          Text(context.tr('Comment on te paie', 'How you get paid'),
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _payChip('revolut', 'Revolut', const Color(0xFF0075EB)),
            _payChip('lydia', 'Lydia', const Color(0xFF0066FF)),
            _payChip('paypal', 'PayPal', const Color(0xFF003087)),
            _payChip('wero', 'Wero', const Color(0xFF10B981)),
            _payChip('iban', 'IBAN', Colors.white38),
            _payChip('link', context.tr('Lien', 'Link'), _violet),
          ]),
          const SizedBox(height: 12),
          ..._paymentFields(),

          const SizedBox(height: 20),
          GestureDetector(
            onTap: (_saving || !balanced) ? null : _launch,
            child: Opacity(
              opacity: (_saving || !balanced) ? 0.5 : 1,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_violet, _pink]),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(context.tr('Lancer la collecte', 'Start collection'),
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ),
          if (!balanced)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                context.tr('Le total réparti doit correspondre au prix du cadeau.',
                    'The split must add up to the gift price.'),
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFF59E0B)),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _memberRow(String uid) {
    final included = _included[uid] == true;
    final isHost = uid == widget.hostUid;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Checkbox(
          value: included,
          activeColor: _violet,
          onChanged: isHost
              ? null // géré par la case « l'hôte participe »
              : (v) {
                  setState(() => _included[uid] = v ?? false);
                  _computeEqualShares();
                },
        ),
        Expanded(
          child: Text(
            '${widget.names[uid] ?? 'Membre'}${isHost ? context.tr(' (toi, hôte)', ' (you, host)') : ''}',
            style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: included ? Colors.white : Colors.white38),
          ),
        ),
        SizedBox(
          width: 78,
          child: TextField(
            controller: _amountCtrls[uid],
            enabled: included,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              suffixText: '€',
              suffixStyle: TextStyle(color: Colors.white38),
              isDense: true,
            ),
            onChanged: (_) {
              if (_custom) setState(() {});
            },
          ),
        ),
      ]),
    );
  }

  List<Widget> _paymentFields() {
    switch (_method) {
      case 'revolut':
        return [_field(_handleCtrl, context.tr('Ton @revtag ou revolut.me/…', 'Your @revtag or revolut.me/…'))];
      case 'lydia':
        return [_field(_handleCtrl, context.tr('Ton numéro de téléphone ou lydia.me/…', 'Your phone number or lydia.me/…'))];
      case 'paypal':
        return [_field(_handleCtrl, context.tr('Ton lien paypal.me/… ou email', 'Your paypal.me/… link or email'))];
      case 'wero':
        return [_field(_handleCtrl, context.tr('Ton numéro / identifiant Wero (ex-Paylib)', 'Your Wero / Paylib number'))];
      case 'iban':
        return [
          _field(_ibanCtrl, 'IBAN (FR76...)'),
          const SizedBox(height: 8),
          _field(_holderCtrl, context.tr('Nom du titulaire du compte', 'Account holder name')),
        ];
      default:
        return [_field(_urlCtrl, context.tr('Lien de cagnotte ou paiement (https://…)', 'Pot or payment link (https://…)'))];
    }
  }

  Widget _field(TextEditingController c, String hint) => TextField(
        controller: c,
        cursorColor: _pink,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
          filled: true,
          fillColor: const Color(0xFF140B26),
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
            borderSide: const BorderSide(color: _pink, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      );

  Widget _segButton(String label, bool active, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: active ? const LinearGradient(colors: [_violet, _pink]) : null,
              color: active ? null : Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : Colors.white54)),
            ),
          ),
        ),
      );

  Widget _payChip(String value, String label, [Color? activeColor]) {
    final active = _method == value;
    final color = activeColor ?? _violet;
    return GestureDetector(
      onTap: () => setState(() => _method = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.3) : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : Colors.white24, width: active ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active) ...[
              Icon(Icons.check_circle_rounded, color: color, size: 14),
              const SizedBox(width: 5),
            ],
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.bold : FontWeight.w500,
                    color: active ? Colors.white : Colors.white70)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _handleCtrl.dispose();
    _ibanCtrl.dispose();
    _holderCtrl.dispose();
    _urlCtrl.dispose();
    for (final c in _amountCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }
}
