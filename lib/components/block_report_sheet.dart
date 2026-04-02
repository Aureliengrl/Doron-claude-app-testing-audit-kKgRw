import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '/components/liquid_glass.dart';
import '/services/block_service.dart';

/// Bottom sheet pour bloquer ou signaler un utilisateur.
///
/// Usage :
/// ```dart
/// BlockReportSheet.show(context, uid: otherUid, handle: 'pseudo');
/// ```
class BlockReportSheet extends StatefulWidget {
  final String uid;
  final String handle;

  const BlockReportSheet({
    super.key,
    required this.uid,
    required this.handle,
  });

  /// Affiche le bottom sheet.
  static Future<void> show(BuildContext context, {required String uid, required String handle}) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlockReportSheet(uid: uid, handle: handle),
    );
  }

  @override
  State<BlockReportSheet> createState() => _BlockReportSheetState();
}

class _BlockReportSheetState extends State<BlockReportSheet> {
  static const _violet = Color(0xFF8A2BE2);
  static const _pink = Color(0xFFEC4899);

  bool _showReasons = false;

  static const _reportReasons = [
    'Spam',
    'Contenu inapproprie',
    'Harcelement',
    'Faux profil',
    'Autre',
  ];

  // Use proper French labels with accents for display
  static const _reportReasonLabels = [
    'Spam',
    'Contenu inappropri\u00e9',
    'Harc\u00e8lement',
    'Faux profil',
    'Autre',
  ];

  Future<void> _blockUser() async {
    HapticFeedback.mediumImpact();
    final ok = await BlockService.blockUser(widget.uid);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        ok ? 'Utilisateur bloqu\u00e9' : 'Erreur lors du blocage',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      backgroundColor: ok ? _violet : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _reportUser(String reason) async {
    HapticFeedback.mediumImpact();
    final ok = await BlockService.reportUser(widget.uid, reason);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        ok ? 'Signalement envoy\u00e9' : 'Erreur lors du signalement',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      backgroundColor: ok ? Colors.orange : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LiquidGlassTokens.pageDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Text(
            _showReasons ? 'Signaler @${widget.handle}' : 'Options',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          if (!_showReasons) ...[
            // Block option
            _buildOption(
              icon: Icons.block_rounded,
              iconColor: Colors.red,
              label: 'Bloquer @${widget.handle}',
              labelColor: Colors.red,
              onTap: _blockUser,
            ),
            const SizedBox(height: 12),
            // Report option
            _buildOption(
              icon: Icons.flag_rounded,
              iconColor: Colors.orange,
              label: 'Signaler @${widget.handle}',
              labelColor: Colors.orange,
              onTap: () => setState(() => _showReasons = true),
            ),
          ] else ...[
            // Report reasons list
            ...List.generate(_reportReasons.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildOption(
                  icon: Icons.chevron_right_rounded,
                  iconColor: Colors.orange,
                  label: _reportReasonLabels[i],
                  labelColor: Colors.white,
                  onTap: () => _reportUser(_reportReasons[i]),
                ),
              );
            }),
            const SizedBox(height: 4),
            // Back button
            GestureDetector(
              onTap: () => setState(() => _showReasons = false),
              child: Text(
                'Retour',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white54,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white54,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Cancel button
          SizedBox(
            width: double.infinity,
            child: LiquidGlassCard(
              blur: LiquidGlassTokens.blurLight,
              padding: const EdgeInsets.symmetric(vertical: 14),
              onTap: () => Navigator.pop(context),
              child: Center(
                child: Text(
                  'Annuler',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color labelColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
