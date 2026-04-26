$file = 'lib\pages\new_pages\user_profile\user_profile_widget.dart'
$content = Get-Content $file -Raw -Encoding UTF8

# On cherche le debut de _showSettingsBottomSheet jusqu'a la fin de _showEditProfileSheet
# et on remplace par la nouvelle version avec edit complet + suppression de compte

$newFunctions = @'
  // ─── Paramètres ─────────────────────────────────────────────────────────────
  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: LiquidGlassTokens.pageDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text('Paramètres', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              LiquidGlassSurface(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(IconlyLight.filter, color: Colors.white),
                      title: Text('Modifier mes préférences (IA)', style: GoogleFonts.outfit(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.pushNamed('OnboardingAdvancedWidget', extra: {
                          'skipUserQuestions': true,
                          'onlyUserQuestions': true,
                          'returnTo': '/user-profile',
                        });
                      },
                    ),
                    Divider(color: Colors.white.withOpacity(0.1), height: 1),
                    ListTile(
                      leading: const Icon(IconlyLight.lock, color: Colors.white),
                      title: Text('Changer le mot de passe', style: GoogleFonts.outfit(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await showModalBottomSheet(
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          context: context,
                          builder: (c) => Padding(padding: MediaQuery.viewInsetsOf(c), child: const ChangePasswordWidget()),
                        );
                      },
                    ),
                    Divider(color: Colors.white.withOpacity(0.1), height: 1),
                    ListTile(
                      leading: const Icon(IconlyLight.discovery, color: Colors.white),
                      title: Text('Changer de langue', style: GoogleFonts.outfit(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await showModalBottomSheet(
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          context: context,
                          builder: (c) => Padding(padding: MediaQuery.viewInsetsOf(c), child: const ChangeLanguageWidget()),
                        );
                      },
                    ),
                    Divider(color: Colors.white.withOpacity(0.1), height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                      title: Text('Supprimer mon compte', style: GoogleFonts.outfit(color: Colors.red)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.red),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _deleteAccount(context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              LiquidGlassPill(
                height: 56,
                activeColor: const Color(0xFFE53935),
                isActive: true,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: ctx,
                    builder: (alertCtx) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      title: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
                      content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?', style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(alertCtx, false), child: const Text('Annuler', style: TextStyle(color: Colors.white54))),
                        TextButton(onPressed: () => Navigator.pop(alertCtx, true), child: const Text('Se déconnecter', style: TextStyle(color: Color(0xFFE53935)))),
                      ],
                    ),
                  ) ?? false;
                  if (confirm) {
                    await authManager.signOut();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('anonymous_mode');
                    if (ctx.mounted) ctx.go('/authentification');
                  }
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(IconlyLight.logout, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Text('Se déconnecter', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  // BUG 9 FIX: Suppression du compte (Firebase Auth uniquement)
  Future<void> _deleteAccount(BuildContext context) async {
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer le compte', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Cette action est irréversible. Votre compte sera définitivement supprimé.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Annuler', style: GoogleFonts.poppins(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Continuer', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600))),
        ],
      ),
    ) ?? false;
    if (!confirm1 || !context.mounted) return;

    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirmation finale', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('Êtes-vous ABSOLUMENT sûr ? Vous ne pourrez plus récupérer votre compte.', style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Non, garder mon compte', style: GoogleFonts.poppins(color: Colors.white))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Oui, supprimer', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600))),
        ],
      ),
    ) ?? false;
    if (!confirm2 || !context.mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await user.delete();
      await authManager.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('anonymous_mode');
      if (context.mounted) context.go('/authentification');
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Reconnectez-vous pour supprimer votre compte.', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
        ));
        await authManager.signOut();
        context.go('/authentification');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : ${e.message}', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur inattendue : $e', style: GoogleFonts.poppins()),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // BUG 8 FIX: Édition complète du profil (nom, pseudo, bio)
  void _showEditProfileSheet(BuildContext context) {
    final nameCtrl = TextEditingController(text: _model.userProfile?['first_name'] as String? ?? '');
    final handleCtrl = TextEditingController(text: _model.userProfile?['handle'] as String? ?? '');
    final bioCtrl = TextEditingController(text: _model.userProfile?['bio'] as String? ?? '');

    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          bool isSaving = false;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: LiquidGlassTokens.pageDark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Text('Modifier le profil', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Text('Prénom', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _buildEditField(nameCtrl, 'Votre prénom', IconlyLight.profile),
                  const SizedBox(height: 16),
                  Text('Pseudo', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _buildEditField(handleCtrl, 'votre_pseudo', IconlyLight.user1, prefix: '@'),
                  const SizedBox(height: 16),
                  Text('Bio', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: TextField(
                      controller: bioCtrl,
                      style: GoogleFonts.poppins(color: Colors.white),
                      maxLines: 3,
                      maxLength: 150,
                      decoration: InputDecoration(
                        hintText: 'Parlez de vous en quelques mots…',
                        hintStyle: GoogleFonts.poppins(color: Colors.white38),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(12),
                        counterStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        setModal(() => isSaving = true);
                        try {
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid != null) {
                            final newHandle = handleCtrl.text.trim().replaceAll('@', '').toLowerCase();
                            await FirebaseFirestore.instance.collection('users').doc(uid).update({
                              'first_name': nameCtrl.text.trim(),
                              'display_name': nameCtrl.text.trim(),
                              if (newHandle.isNotEmpty) 'handle': newHandle,
                              'bio': bioCtrl.text.trim(),
                            });
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          _model.loadFavourites();
                          _loadWishlists();
                        } catch (_) {
                          setModal(() => isSaving = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: violetColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Sauvegarder', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditField(TextEditingController ctrl, String hint, IconData icon, {String? prefix}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, color: Colors.white54, size: 18),
          if (prefix != null) ...[
            const SizedBox(width: 4),
            Text(prefix, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 15)),
          ],
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.poppins(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
'@

# Trouver le debut de _showSettingsBottomSheet
$startMarker = "  void _showSettingsBottomSheet(BuildContext context) {"
# Trouver la fin (la classe _SliverTabBarDelegate)
$endMarker = "// D"

$startIdx = $content.IndexOf($startMarker)

# On cherche le commentaire du delegate qui vient apres la fin du widget state
$delegateStart = $content.IndexOf("// D", $startIdx)

if ($startIdx -gt 0 -and $delegateStart -gt 0) {
    $before = $content.Substring(0, $startIdx)
    $after = $content.Substring($delegateStart)
    $content = $before + $newFunctions + "`r`n`r`n" + $after
    Set-Content $file $content -Encoding UTF8
    Write-Host "BUG 8+9 fixed"
} else {
    Write-Host "ERROR: Markers not found. startIdx=$startIdx delegateStart=$delegateStart"
}
