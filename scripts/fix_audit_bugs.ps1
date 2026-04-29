# Script de correction des bugs restants — chat_room_page.dart et friends_page.dart
$BaseDir = "C:\Users\marcg\Desktop\Doron-claude-app-testing-audit-kKgRw-claude-app-audit-improvements-9FNM2\lib"

function Replace-InFile {
    param([string]$FilePath, [hashtable]$Replacements)
    if (-not (Test-Path $FilePath)) { Write-Warning "Not found: $FilePath"; return }
    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
    $changed = $false
    foreach ($key in $Replacements.Keys) {
        if ($content.Contains($key)) {
            $content = $content.Replace($key, $Replacements[$key])
            $changed = $true
            Write-Host "  ✓ Fixed: $($key.Substring(0, [Math]::Min(60,$key.Length)))"
        } else {
            Write-Host "  ⚠ Not found: $($key.Substring(0, [Math]::Min(60,$key.Length)))"
        }
    }
    if ($changed) {
        Set-Content -Path $FilePath -Value $content -Encoding UTF8 -NoNewline
        Write-Host "✅ Saved: $FilePath"
    }
}

# ── chat_room_page.dart ──────────────────────────────────────────────────────
$chatRoomFile = "$BaseDir\pages\new_pages\chat\chat_room_page.dart"
Replace-InFile -FilePath $chatRoomFile -Replacements @{
    "'Dites bonjour a `$otherName !'" = "context.tr('Dites bonjour à `$otherName !', 'Say hi to `$otherName!')"
    "'Envoyez votre premier message'" = "context.tr('Envoyez votre premier message', 'Send your first message')"
    "'Charger plus'" = "context.tr('Charger plus', 'Load more')"
    "'Message copie'" = "context.tr('Message copié', 'Message copied')"
    "'Vu `$readBy'" = "context.tr('Vu `$readBy', 'Seen by `$readBy')"
    "'Associer une liste à ce groupe'" = "context.tr('Associer une liste à ce groupe', 'Link a list to this group')"
    "Text('Créer', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))" = "Text(context.tr('Créer', 'Create'), style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))"
    "'Voir la fiche produit'" = "context.tr('Voir la fiche produit', 'View product')"
    "label: 'Partager un produit'" = "label: context.tr('Partager un produit', 'Share a product')"
    "sublabel: 'Envoie une fiche produit dans le chat'" = "sublabel: context.tr('Envoie une fiche produit dans le chat', 'Send a product card in chat')"
    "label: 'Partager une wishlist'" = "label: context.tr('Partager une wishlist', 'Share a wishlist')"
    "sublabel: 'Envoie un album complet'" = "sublabel: context.tr('Envoie un album complet', 'Send a full album')"
    "'Choisir un produit'" = "context.tr('Choisir un produit', 'Choose a product')"
    "'Aucun favori pour le moment'" = "context.tr('Aucun favori pour le moment', 'No favourites yet')"
    "'Choisir une wishlist'" = "context.tr('Choisir une wishlist', 'Choose a wishlist')"
    "'Aucune wishlist pour le moment'" = "context.tr('Aucune wishlist pour le moment', 'No wishlists yet')"
    "Text('Voir →'," = "Text(context.tr('Voir →', 'View →'),"
    "Text('Partager'," = "Text(context.tr('Partager', 'Share'),"
    "'`$name ecrit...'" = "context.tr('`$name écrit...', '`$name is typing...')"
    "'Quelqu un ecrit...'" = "context.tr('Quelqu\'un écrit...', 'Someone is typing...')"
    "'Plusieurs personnes ecrivent...'" = "context.tr('Plusieurs personnes écrivent...', 'Several people are typing...')"
}

# ── friends_page.dart ────────────────────────────────────────────────────────
$friendsFile = "$BaseDir\pages\new_pages\social\friends_page.dart"
Replace-InFile -FilePath $friendsFile -Replacements @{
    "hintText: 'Rechercher par @pseudo ou prénom…'" = "hintText: context.tr('Rechercher par @pseudo ou prénom…', 'Search by @username or name…')"
    "'👥 Amis'" = "context.tr('👥 Amis', '👥 Friends')"
    "'🔍 Rechercher'" = "context.tr('🔍 Rechercher', '🔍 Search')"
    "'📬 Demandes'" = "context.tr('📬 Demandes', '📬 Requests')"
    "'Aucun ami pour l'instant'" = "context.tr('Aucun ami pour l\'instant', 'No friends yet')"
    "'Aucun ami pour l\\'instant'" = "context.tr('Aucun ami pour l\'instant', 'No friends yet')"
    "'Recherche des utilisateurs et ajoute-les !'" = "context.tr('Recherche des utilisateurs et ajoute-les !', 'Search users and add them!')"
    "'Retirer cet ami ?'" = "context.tr('Retirer cet ami ?', 'Remove this friend?')"
    "Text('Retirer', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600))" = "Text(context.tr('Retirer', 'Remove'), style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600))"
    "'Suggestions pour toi'" = "context.tr('Suggestions pour toi', 'Suggestions for you')"
    "'Cherche par @pseudo ou prénom'" = "context.tr('Cherche par @pseudo ou prénom', 'Search by @username or name')"
    "'Aucun utilisateur trouvé'" = "context.tr('Aucun utilisateur trouvé', 'No users found')"
    "'👥 Vous êtes maintenant amis !'" = "context.tr('👥 Vous êtes maintenant amis !', '👥 You are now friends!')"
    "'✅ Demande envoyée !'" = "context.tr('✅ Demande envoyée !', '✅ Request sent!')"
    "'Demande annulée'" = "context.tr('Demande annulée', 'Request cancelled')"
    "'Impossible d\\'ouvrir le chat.'" = "context.tr('Impossible d\'ouvrir le chat.', 'Unable to open chat.')"
    "'🎁 Tu as rejoint la liste !'" = "context.tr('🎁 Tu as rejoint la liste !', '🎁 You joined the list!')"
}

Write-Host ""
Write-Host "🎉 Corrections de bugs terminées !" -ForegroundColor Green
