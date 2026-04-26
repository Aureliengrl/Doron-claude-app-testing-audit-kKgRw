const fs = require('fs');
let c = fs.readFileSync('lib/components/product_detail_modal.dart', 'utf8');

const insertBefore = "  /// Fonction globale de favoris";
const insertIdx = c.indexOf(insertBefore);
if (insertIdx === -1) { console.log('ERROR: insert marker not found'); process.exit(1); }

const newMethod = `
  // ─── Site colors & icons ────────────────────────────────────────────────────
  static Color _siteColor(String site) {
    final s = site.toLowerCase();
    if (s.contains('amazon')) return const Color(0xFFFF9900);
    if (s.contains('fnac'))   return const Color(0xFFFFCC00);
    if (s.contains('darty'))  return const Color(0xFFE30613);
    if (s.contains('cdiscount')) return const Color(0xFF0070C0);
    if (s.contains('zalando')) return const Color(0xFFFF6600);
    if (s.contains('la redoute')) return const Color(0xFFE91E63);
    if (s.contains('galeries')) return const Color(0xFF1A237E);
    if (s.contains('sephora')) return const Color(0xFF000000);
    if (s.contains('boulanger')) return const Color(0xFF003DA5);
    if (s.contains('decathlon')) return const Color(0xFF007DBA);
    if (s.contains('monoprix')) return const Color(0xFFE30613);
    return const Color(0xFF6B7280);
  }

  static String _siteEmoji(String site) {
    final s = site.toLowerCase();
    if (s.contains('amazon'))   return '🟠';
    if (s.contains('fnac'))     return '🟡';
    if (s.contains('darty'))    return '🔴';
    if (s.contains('zalando'))  return '🟧';
    if (s.contains('cdiscount'))return '🔷';
    if (s.contains('sephora'))  return '⚫';
    if (s.contains('boulanger'))return '🔵';
    if (s.contains('decathlon'))return '💙';
    return '🌐';
  }

  /// Mini comparateur de prix — affiche tous les buyLinks[]
  static Widget _buildBuyLinksSection(BuildContext context, Map<String, dynamic> product) {
    // Récupérer buyLinks depuis le produit
    final rawLinks = product['buyLinks'];
    List<Map<String, dynamic>> buyLinks = [];

    if (rawLinks is List && rawLinks.isNotEmpty) {
      buyLinks = rawLinks
          .whereType<Map>()
          .map((l) => Map<String, dynamic>.from(l))
          .toList();
      // Trier : affiliés d'abord, puis par priorité, puis par prix
      buyLinks.sort((a, b) {
        final aAff = a['affiliated'] == true ? 0 : 1;
        final bAff = b['affiliated'] == true ? 0 : 1;
        if (aAff != bAff) return aAff - bAff;
        final aPrio = (a['priority'] as num?)?.toInt() ?? 99;
        final bPrio = (b['priority'] as num?)?.toInt() ?? 99;
        if (aPrio != bPrio) return aPrio - bPrio;
        final aPrice = (a['price'] as num?)?.toDouble() ?? 9999;
        final bPrice = (b['price'] as num?)?.toDouble() ?? 9999;
        return aPrice.compareTo(bPrice);
      });
    }

    // Pas de buyLinks → fallback bouton simple
    if (buyLinks.isEmpty) {
      final url = (product['product_url'] ?? product['url'] ?? '').toString();
      final brand = (product['brand'] ?? product['source'] ?? 'Boutique').toString();
      if (url.isEmpty) {
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Aucun lien disponible',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white38),
            textAlign: TextAlign.center,
          ),
        );
      }
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            try { await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); } catch (_) {}
          },
          icon: const Icon(Icons.open_in_new, color: Colors.white, size: 18),
          label: Text('Voir sur $brand', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: violetColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
          ),
        ),
      );
    }

    // Trouver le prix min pour le badge
    final prices = buyLinks.map((l) => (l['price'] as num?)?.toDouble()).whereType<double>().toList();
    final priceMin = prices.isNotEmpty ? prices.reduce((a, b) => a < b ? a : b) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              'Où acheter',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            if (priceMin != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                ),
                child: Text(
                  'Dès \${priceMin.toStringAsFixed(priceMin == priceMin.roundToDouble() ? 0 : 2)}€',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        // Liste des liens
        ...buyLinks.take(6).map((link) {
          final site    = (link['site'] as String?) ?? 'Boutique';
          final url     = (link['url'] as String?) ?? '';
          final price   = (link['price'] as num?)?.toDouble();
          final isAffiliated = link['affiliated'] == true;
          final isBest  = price != null && price == priceMin;
          final siteColor = _siteColor(site);
          final emoji = _siteEmoji(site);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: url.isNotEmpty ? () async {
                HapticFeedback.lightImpact();
                try { await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); } catch (_) {}
              } : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: isBest
                      ? const Color(0xFF10B981).withOpacity(0.08)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isBest
                        ? const Color(0xFF10B981).withOpacity(0.4)
                        : Colors.white.withOpacity(0.08),
                    width: isBest ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Emoji site
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    // Nom du site
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                site,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              if (isBest) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Meilleur prix',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                              if (isAffiliated) ...[
                                const SizedBox(width: 4),
                                const Text('💰', style: TextStyle(fontSize: 10)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Prix
                    if (price != null)
                      Text(
                        '\${price.toStringAsFixed(price == price.roundToDouble() ? 0 : 2)}€',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isBest ? const Color(0xFF10B981) : Colors.white,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.white38,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 4),
      ],
    );
  }

`;

c = c.substring(0, insertIdx) + newMethod + c.substring(insertIdx);
fs.writeFileSync('lib/components/product_detail_modal.dart', c, 'utf8');
console.log('✅ _buildBuyLinksSection added. File length:', c.length);
console.log('Contains _siteColor:', c.includes('_siteColor'));
console.log('Contains _siteEmoji:', c.includes('_siteEmoji'));
