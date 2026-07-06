$path = "lib\components\wishlist_picker_sheet.dart"
$content = Get-Content -Path $path -Raw -Encoding UTF8

if (-not $content.Contains("import 'package:doron/services/firebase_data_service.dart';")) {
    $content = $content -replace "import 'package:cloud_firestore/cloud_firestore.dart';", "import 'package:cloud_firestore/cloud_firestore.dart';`nimport 'package:doron/services/firebase_data_service.dart';"
}

$newAddToWishlist = @"
  bool _isSaving = false;

  Future<void> _addToWishlist(String wishlistId, String wishlistName) async {
    if (_isSaving) return;
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    // Cache les objets liÃ©s au context
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    
    // Ferme la modale immÃ©diatement
    nav.pop();

    try {
      // FIX: Utilise le service global pour ajouter dans "products" avec le mÃªme format
      await FirebaseDataService.addProductToWishlist(wishlistId, widget.product);

      messenger.showSnackBar(SnackBar(
        content: Text('AjoutÃ© Ã  $wishlistName !', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF8A2BE2),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Erreur lors de l''ajout', style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
      ));
    }
  }
"@
$content = $content -replace "(?s)  Future<void> _addToWishlist\(String wishlistId, String wishlistName\) async \{.*?  \}" , $newAddToWishlist

Set-Content -Path $path -Value $content -Encoding UTF8
