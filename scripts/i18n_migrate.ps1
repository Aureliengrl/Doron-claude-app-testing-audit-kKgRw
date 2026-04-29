# Script de migration i18n complet pour Doron App
# Remplace toutes les strings hardcodées FR par context.tr(fr, en)
# Execute: pwsh -File scripts/i18n_migrate.ps1

$BaseDir = "C:\Users\marcg\Desktop\Doron-claude-app-testing-audit-kKgRw-claude-app-audit-improvements-9FNM2\lib"

function Replace-InFile {
    param([string]$FilePath, [hashtable]$Replacements)
    if (-not (Test-Path $FilePath)) {
        Write-Warning "File not found: $FilePath"
        return
    }
    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
    $changed = $false
    foreach ($key in $Replacements.Keys) {
        if ($content.Contains($key)) {
            $content = $content.Replace($key, $Replacements[$key])
            $changed = $true
        }
    }
    if ($changed) {
        Set-Content -Path $FilePath -Value $content -Encoding UTF8 -NoNewline
        Write-Host "✅ Updated: $FilePath"
    } else {
        Write-Host "⏭️  No changes: $FilePath"
    }
}

# ─── user_profile_widget.dart ────────────────────────────────────────────────
$userProfileFile = "$BaseDir\pages\new_pages\user_profile\user_profile_widget.dart"
Replace-InFile -FilePath $userProfileFile -Replacements @{
    "export 'user_profile_model.dart';" = "export 'user_profile_model.dart';`nimport '/utils/app_tr.dart';"
    "_buildProfileStat('Amis', '`$_friendsCount')," = "_buildProfileStat(context.tr('Amis', 'Friends'), '`$_friendsCount'),"
    "_buildProfileStat('Wishlists', '`${_wishlists.length}')," = "_buildProfileStat(context.tr('Wishlists', 'Wishlists'), '`${_wishlists.length}'),"
    "_buildProfileStat('Cadeaux', '`${_model.favourites.length}')," = "_buildProfileStat(context.tr('Cadeaux', 'Gifts'), '`${_model.favourites.length}'),"
    "Text('Modifier le profil'," = "Text(context.tr('Modifier le profil', 'Edit profile'),"
    "Text('Amis'," = "Text(context.tr('Amis', 'Friends'),"
    "Text('Partager'," = "Text(context.tr('Partager', 'Share'),"
    "Text('Wishlists')," = "Text(context.tr('Wishlists', 'Wishlists')),"
    "Text('Se connecter'," = "Text(context.tr('Se connecter', 'Sign in'),"
    "Text('Annuler', style: GoogleFonts.poppins(color: Colors.white54))," = "Text(context.tr('Annuler', 'Cancel'), style: GoogleFonts.poppins(color: Colors.white54)),"
    "Text('Photo', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF00D4FF)))" = "Text(context.tr('Photo', 'Photo'), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF00D4FF)))"
}

# ─── home_pinterest_widget.dart ───────────────────────────────────────────────
$homeFile = "$BaseDir\pages\new_pages\home_pinterest\home_pinterest_widget.dart"
Replace-InFile -FilePath $homeFile -Replacements @{
    "import 'home_pinterest_model.dart';" = "import 'home_pinterest_model.dart';`nimport '/utils/app_tr.dart';"
    "'Ajouté aux favoris (connectez-vous pour synchroniser)'" = "context.tr('Ajouté aux favoris (connectez-vous pour synchroniser)', 'Added to favourites (sign in to sync)')"
    "'Retiré des favoris (connectez-vous pour synchroniser)'" = "context.tr('Retiré des favoris (connectez-vous pour synchroniser)', 'Removed from favourites (sign in to sync)')"
    "label: 'Connexion'," = "label: context.tr('Connexion', 'Sign in'),"
    "Text('❤️ Ajouté aux favoris !'," = "Text(context.tr('❤️ Ajouté aux favoris !', '❤️ Added to favourites!'),"
    "'Pour toi'" = "context.tr('Pour toi', 'For you')"
}

# ─── search_page_widget.dart ──────────────────────────────────────────────────
$searchFile = "$BaseDir\pages\new_pages\search_page\search_page_widget.dart"
Replace-InFile -FilePath $searchFile -Replacements @{
    "import 'search_page_model.dart';" = "import 'search_page_model.dart';`nimport '/utils/app_tr.dart';"
    "text: 'Réessayer'," = "text: context.tr('Réessayer', 'Retry'),"
    "Text('Chargement...'," = "Text(context.tr('Chargement...', 'Loading...'),"
    "Text('Recherche'," = "Text(context.tr('Recherche', 'Search'),"
    "'Trouvez le cadeau parfait pour vos proches'" = "context.tr('Trouvez le cadeau parfait pour vos proches', 'Find the perfect gift for your loved ones')"
    "'Sélectionne une personne pour voir ses cadeaux'" = "context.tr('Sélectionne une personne pour voir ses cadeaux', 'Select a person to see their gifts')"
    "Text('Ajouter'," = "Text(context.tr('Ajouter', 'Add'),"
    "'Supprimer cette personne ?'" = "context.tr('Supprimer cette personne ?', 'Remove this person?')"
    "Text('Annuler'," = "Text(context.tr('Annuler', 'Cancel'),"
    "Text('Supprimer'," = "Text(context.tr('Supprimer', 'Delete'),"
    "label: 'Annuler', textColor: Colors.white" = "label: context.tr('Annuler', 'Cancel'), textColor: Colors.white"
    "'Cadeaux pour " = "context.tr('Cadeaux pour ', 'Gifts for ') + "
    "Text('Partager'," = "Text(context.tr('Partager', 'Share'),"
    "Text('Modifier'," = "Text(context.tr('Modifier', 'Edit'),"
    "'Génération du PDF en cours...'" = "context.tr('Génération du PDF en cours...', 'Generating PDF...')"
    "'Erreur lors de la génération du PDF'" = "context.tr('Erreur lors de la génération du PDF', 'PDF generation error')"
    "Text('Aucun cadeau sauvegardé'," = "Text(context.tr('Aucun cadeau sauvegardé', 'No saved gifts'),"
    "Text('Suggestions'," = "Text(context.tr('Suggestions', 'Suggestions'),"
    "'supprimé(e)'" = "context.tr('supprimé(e)', 'removed')"
}

# ─── birthday_calendar_page.dart ──────────────────────────────────────────────
$calendarFile = "$BaseDir\pages\new_pages\birthday_calendar\birthday_calendar_page.dart"
Replace-InFile -FilePath $calendarFile -Replacements @{
    "import '/services/birthday_service.dart';" = "import '/services/birthday_service.dart';`nimport '/utils/app_tr.dart';"
    "'Calendrier'" = "context.tr('Calendrier', 'Calendar')"
    "'Anniversaires'" = "context.tr('Anniversaires', 'Birthdays')"
    "'Ajouter un événement'" = "context.tr('Ajouter un événement', 'Add an event')"
    "'À venir'" = "context.tr('À venir', 'Upcoming')"
    "'Aucun événement'" = "context.tr('Aucun événement', 'No events')"
    "'Fêtes françaises'" = "context.tr('Fêtes françaises', 'French holidays')"
    "'Anniversaires amis'" = "context.tr('Anniversaires amis', 'Friends birthdays')"
    "'Mon anniversaire'" = "context.tr('Mon anniversaire', 'My birthday')"
    "Text('Annuler')" = "Text(context.tr('Annuler', 'Cancel'))"
    "Text('Ajouter')" = "Text(context.tr('Ajouter', 'Add'))"
    "Text('Enregistrer')" = "Text(context.tr('Enregistrer', 'Save'))"
    "'Nom de l'événement'" = "context.tr('Nom de l\\'événement', 'Event name')"
    "'Note (optionnelle)'" = "context.tr('Note (optionnelle)', 'Note (optional)')"
    "locale: 'fr_FR'" = "locale: context.isEn ? 'en_US' : 'fr_FR'"
}

# ─── setup_profile_page.dart ──────────────────────────────────────────────────
$setupFile = "$BaseDir\pages\new_pages\setup_profile\setup_profile_page.dart"
Replace-InFile -FilePath $setupFile -Replacements @{
    "import '/backend/backend.dart';" = "import '/backend/backend.dart';`nimport '/utils/app_tr.dart';"
    "'Créer mon profil'" = "context.tr('Créer mon profil', 'Create my profile')"
    "'Choisis ton pseudo'" = "context.tr('Choisis ton pseudo', 'Choose your username')"
    "'Ton prénom'" = "context.tr('Ton prénom', 'Your first name')"
    "'Continuer'" = "context.tr('Continuer', 'Continue')"
    "'Ton anniversaire'" = "context.tr('Ton anniversaire', 'Your birthday')"
    "'Jour'" = "context.tr('Jour', 'Day')"
    "'Mois'" = "context.tr('Mois', 'Month')"
    "'Janvier'" = "context.tr('Janvier', 'January')"
    "'Février'" = "context.tr('Février', 'February')"
    "'Mars'" = "context.tr('Mars', 'March')"
    "'Avril'" = "context.tr('Avril', 'April')"
    "'Mai'" = "context.tr('Mai', 'May')"
    "'Juin'" = "context.tr('Juin', 'June')"
    "'Juillet'" = "context.tr('Juillet', 'July')"
    "'Août'" = "context.tr('Août', 'August')"
    "'Septembre'" = "context.tr('Septembre', 'September')"
    "'Octobre'" = "context.tr('Octobre', 'October')"
    "'Novembre'" = "context.tr('Novembre', 'November')"
    "'Décembre'" = "context.tr('Décembre', 'December')"
}

# ─── chat_list_page.dart ──────────────────────────────────────────────────────
$chatListFile = "$BaseDir\pages\new_pages\chat\chat_list_page.dart"
Replace-InFile -FilePath $chatListFile -Replacements @{
    "'Cadeau commun'" = "context.isEn ? 'Group gift' : 'Cadeau commun'"
    "'Groupe Famille'" = "context.isEn ? 'Family Group' : 'Groupe Famille'"
    "'Déjeuner surprise'" = "context.isEn ? 'Surprise lunch' : 'Déjeuner surprise'"
    "return '__yesterday__';" = "return context.tr('Hier', 'Yesterday');"
    "return '__day_`${date.weekday}__';" = "return context.isEn ? ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][date.weekday-1] : ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'][date.weekday-1];"
}

# ─── friends_page.dart ────────────────────────────────────────────────────────
$friendsFile = "$BaseDir\pages\new_pages\social\friends_page.dart"
Replace-InFile -FilePath $friendsFile -Replacements @{
    "import 'package:flutter/material.dart';" = "import 'package:flutter/material.dart';`nimport '/utils/app_tr.dart';"
    "'Amis'" = "context.tr('Amis', 'Friends')"
    "'Demandes d'amis'" = "context.tr('Demandes d\\'amis', 'Friend requests')"
    "'Trouver des amis'" = "context.tr('Trouver des amis', 'Find friends')"
    "'Aucun ami'" = "context.tr('Aucun ami', 'No friends')"
    "'Aucune demande'" = "context.tr('Aucune demande', 'No requests')"
    "'Accepter'" = "context.tr('Accepter', 'Accept')"
    "'Refuser'" = "context.tr('Refuser', 'Decline')"
    "'Ajouter'" = "context.tr('Ajouter', 'Add')"
    "'Annuler'" = "context.tr('Annuler', 'Cancel')"
    "'Supprimer'" = "context.tr('Supprimer', 'Remove')"
}

# ─── public_profile_page.dart ─────────────────────────────────────────────────
$publicProfileFile = "$BaseDir\pages\new_pages\public_profile\public_profile_page.dart"
Replace-InFile -FilePath $publicProfileFile -Replacements @{
    "import 'package:flutter/material.dart';" = "import 'package:flutter/material.dart';`nimport '/utils/app_tr.dart';"
    "'Profil'" = "context.tr('Profil', 'Profile')"
    "'Ajouter en ami'" = "context.tr('Ajouter en ami', 'Add as friend')"
    "'Ami(e)'" = "context.tr('Ami(e)', 'Friend')"
    "'Demande envoyée'" = "context.tr('Demande envoyée', 'Request sent')"
    "'Message'" = "context.tr('Message', 'Message')"
    "'Wishlists'" = "context.tr('Wishlists', 'Wishlists')"
    "'Aucune wishlist publique'" = "context.tr('Aucune wishlist publique', 'No public wishlists')"
    "'Anniversaire'" = "context.tr('Anniversaire', 'Birthday')"
    "'Annuler'" = "context.tr('Annuler', 'Cancel')"
    "'Signaler'" = "context.tr('Signaler', 'Report')"
    "'Bloquer'" = "context.tr('Bloquer', 'Block')"
}

# ─── product_detail_modal.dart ────────────────────────────────────────────────
$modalFile = "$BaseDir\components\product_detail_modal.dart"
Replace-InFile -FilePath $modalFile -Replacements @{
    "import 'package:flutter/material.dart';" = "import 'package:flutter/material.dart';`nimport '/utils/app_tr.dart';"
    "'Ajouter à une liste'" = "context.tr('Ajouter à une liste', 'Add to a list')"
    "'Voir le produit'" = "context.tr('Voir le produit', 'View product')"
    "'Partager'" = "context.tr('Partager', 'Share')"
    "'Ajouter pour quelqu'un'" = "context.tr('Ajouter pour quelqu\\'un', 'Add for someone')"
    "'Trouver en magasin'" = "context.tr('Trouver en magasin', 'Find in store')"
    "'Annuler'" = "context.tr('Annuler', 'Cancel')"
    "'Enregistrer'" = "context.tr('Enregistrer', 'Save')"
}

# ─── wishlist_picker_sheet.dart ───────────────────────────────────────────────
$wishlistPickerFile = "$BaseDir\components\wishlist_picker_sheet.dart"
Replace-InFile -FilePath $wishlistPickerFile -Replacements @{
    "import 'package:flutter/material.dart';" = "import 'package:flutter/material.dart';`nimport '/utils/app_tr.dart';"
    "'Choisir une liste'" = "context.tr('Choisir une liste', 'Choose a list')"
    "'Créer une nouvelle liste'" = "context.tr('Créer une nouvelle liste', 'Create a new list')"
    "'Ajouter'" = "context.tr('Ajouter', 'Add')"
    "'Annuler'" = "context.tr('Annuler', 'Cancel')"
}

# ─── connection_required_dialog.dart ──────────────────────────────────────────
$connDialogFile = "$BaseDir\components\connection_required_dialog.dart"
Replace-InFile -FilePath $connDialogFile -Replacements @{
    "import 'package:flutter/material.dart';" = "import 'package:flutter/material.dart';`nimport '/utils/app_tr.dart';"
    "'Connexion requise'" = "context.tr('Connexion requise', 'Sign in required')"
    "'Se connecter'" = "context.tr('Se connecter', 'Sign in')"
    "'Continuer sans connexion'" = "context.tr('Continuer sans connexion', 'Continue without signing in')"
    "'Annuler'" = "context.tr('Annuler', 'Cancel')"
}

# ─── block_report_sheet.dart ──────────────────────────────────────────────────
$blockReportFile = "$BaseDir\components\block_report_sheet.dart"
Replace-InFile -FilePath $blockReportFile -Replacements @{
    "import 'package:flutter/material.dart';" = "import 'package:flutter/material.dart';`nimport '/utils/app_tr.dart';"
    "'Signaler'" = "context.tr('Signaler', 'Report')"
    "'Bloquer'" = "context.tr('Bloquer', 'Block')"
    "'Annuler'" = "context.tr('Annuler', 'Cancel')"
}

# ─── store_finder_bottom_sheet.dart ───────────────────────────────────────────
$storeFinderFile = "$BaseDir\components\store_finder_bottom_sheet.dart"
Replace-InFile -FilePath $storeFinderFile -Replacements @{
    "import 'package:flutter/material.dart';" = "import 'package:flutter/material.dart';`nimport '/utils/app_tr.dart';"
    "'Trouver en magasin'" = "context.tr('Trouver en magasin', 'Find in store')"
    "'Magasins à proximité'" = "context.tr('Magasins à proximité', 'Nearby stores')"
    "'Aucun magasin trouvé'" = "context.tr('Aucun magasin trouvé', 'No stores found')"
}

# ─── moment_type_page.dart ────────────────────────────────────────────────────
$momentFile = "$BaseDir\pages\new_pages\moment_type_page.dart"
Replace-InFile -FilePath $momentFile -Replacements @{
    "import 'package:flutter/material.dart';" = "import 'package:flutter/material.dart';`nimport '/utils/app_tr.dart';"
    "'Quel est l'occasion ?'" = "context.tr('Quel est l\\'occasion ?', 'What is the occasion?')"
    "'Continuer'" = "context.tr('Continuer', 'Continue')"
    "'Annuler'" = "context.tr('Annuler', 'Cancel')"
}

# ─── occasion_question_page.dart ──────────────────────────────────────────────
$occasionFile = "$BaseDir\pages\new_pages\occasion_question_page.dart"
Replace-InFile -FilePath $occasionFile -Replacements @{
    "import 'package:flutter/material.dart';" = "import 'package:flutter/material.dart';`nimport '/utils/app_tr.dart';"
    "'Continuer'" = "context.tr('Continuer', 'Continue')"
    "'Précédent'" = "context.tr('Précédent', 'Back')"
}

# ─── join_collab_page.dart ────────────────────────────────────────────────────
$collabFile = "$BaseDir\pages\new_pages\join_collab_page.dart"
Replace-InFile -FilePath $collabFile -Replacements @{
    "import 'package:flutter/material.dart';" = "import 'package:flutter/material.dart';`nimport '/utils/app_tr.dart';"
    "'Rejoindre'" = "context.tr('Rejoindre', 'Join')"
    "'Annuler'" = "context.tr('Annuler', 'Cancel')"
}

# ─── gift_results_widget.dart ─────────────────────────────────────────────────
$giftResultsFile = "$BaseDir\pages\new_pages\gift_results\gift_results_widget.dart"
Replace-InFile -FilePath $giftResultsFile -Replacements @{
    "import 'package:flutter/material.dart';" = "import 'package:flutter/material.dart';`nimport '/utils/app_tr.dart';"
    "'Résultats'" = "context.tr('Résultats', 'Results')"
    "'Aucun résultat'" = "context.tr('Aucun résultat', 'No results')"
    "'Sauvegarder'" = "context.tr('Sauvegarder', 'Save')"
    "'Voir plus'" = "context.tr('Voir plus', 'See more')"
}

# ─── create_chat_bottom_sheet.dart ────────────────────────────────────────────
$createChatFile = "$BaseDir\pages\new_pages\chat\create_chat_bottom_sheet.dart"
Replace-InFile -FilePath $createChatFile -Replacements @{
    "import 'package:flutter/material.dart';" = "import 'package:flutter/material.dart';`nimport '/utils/app_tr.dart';"
    "'Nouveau message'" = "context.tr('Nouveau message', 'New message')"
    "'Nouveau groupe'" = "context.tr('Nouveau groupe', 'New group')"
    "'Chercher un ami...'" = "context.tr('Chercher un ami...', 'Search a friend...')"
    "'Nom du groupe'" = "context.tr('Nom du groupe', 'Group name')"
    "'Créer'" = "context.tr('Créer', 'Create')"
    "'Annuler'" = "context.tr('Annuler', 'Cancel')"
}

# ─── chat_room_page.dart ──────────────────────────────────────────────────────
$chatRoomFile = "$BaseDir\pages\new_pages\chat\chat_room_page.dart"
Replace-InFile -FilePath $chatRoomFile -Replacements @{
    "import 'package:flutter/material.dart';" = "import 'package:flutter/material.dart';`nimport '/utils/app_tr.dart';"
    "'Écrire un message...'" = "context.tr('Écrire un message...', 'Write a message...')"
    "'Supprimer'" = "context.tr('Supprimer', 'Delete')"
    "'Annuler'" = "context.tr('Annuler', 'Cancel')"
    "'Répondre'" = "context.tr('Répondre', 'Reply')"
    "'Copier'" = "context.tr('Copier', 'Copy')"
    "'Modifier'" = "context.tr('Modifier', 'Edit')"
}

# ─── onboarding_advanced_widget.dart ──────────────────────────────────────────
$onboardingFile = "$BaseDir\pages\new_pages\onboarding_advanced\onboarding_advanced_widget.dart"
Replace-InFile -FilePath $onboardingFile -Replacements @{
    "import 'package:flutter/material.dart';" = "import 'package:flutter/material.dart';`nimport '/utils/app_tr.dart';"
    "'Continuer'" = "context.tr('Continuer', 'Continue')"
    "'Précédent'" = "context.tr('Précédent', 'Back')"
    "'Terminer'" = "context.tr('Terminer', 'Finish')"
    "'Annuler'" = "context.tr('Annuler', 'Cancel')"
    "'Passer'" = "context.tr('Passer', 'Skip')"
}

# ─── chat_info_page.dart ──────────────────────────────────────────────────────
$chatInfoFile = "$BaseDir\pages\new_pages\chat\chat_info_page.dart"
Replace-InFile -FilePath $chatInfoFile -Replacements @{
    "import 'package:flutter/material.dart';" = "import 'package:flutter/material.dart';`nimport '/utils/app_tr.dart';"
    "'Infos du groupe'" = "context.tr('Infos du groupe', 'Group info')"
    "'Membres'" = "context.tr('Membres', 'Members')"
    "'Quitter le groupe'" = "context.tr('Quitter le groupe', 'Leave group')"
    "'Annuler'" = "context.tr('Annuler', 'Cancel')"
}

Write-Host ""
Write-Host "🎉 Migration i18n terminée !" -ForegroundColor Green
Write-Host "Tous les fichiers ont été traités." -ForegroundColor Cyan
