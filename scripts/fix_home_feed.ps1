$ErrorActionPreference = 'Stop'
$file = "C:\Users\marcg\Desktop\Doron-claude-app-testing-audit-kKgRw-claude-app-audit-improvements-9FNM2\lib\pages\new_pages\home_pinterest\home_pinterest_widget.dart"
$content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)

$fixes = @(
  # BUG FIX 1: _loadPopularProducts - comparaison ID
  @{
    Old = "if (_model.activeCategory != context.tr('Pour toi', 'For you')) {`r`n          final categoryLower = _model.activeCategory.toLowerCase();"
    New = "if (_model.activeCategoryId != 'all') {`r`n          final categoryId = _model.activeCategoryId;"
  },
  # BUG FIX 2: arrayContains avec l'ID (x2 occurrences dans _loadPopularProducts)
  @{ Old = ".where('categories', arrayContains: categoryLower)"; New = ".where('categories', arrayContains: categoryId)"; Allow = $true },
  # BUG FIX 3: _loadProducts sections check
  @{
    Old = "if (_model.activeCategory == context.tr('Pour toi', 'For you') && userProfileTags != null) {"
    New = "if (_model.activeCategoryId == 'all' && userProfileTags != null) {"
  },
  # BUG FIX 4: _loadProducts getPersonalizedProducts
  @{
    Old = "        category: _model.activeCategory != context.tr('Pour toi', 'For you') ? _model.activeCategory : null,"
    New = "        // BUG FIX: utiliser l'ID pour le filtre categorie (independant de la langue)`r`n        category: _model.activeCategoryId != 'all' ? _model.activeCategoryId : null,"
  },
  # SNACKBAR favoris non connecte
  @{
    Old = "            isCurrentlyLiked`r`n                ? 'Retir\u00e9 des favoris (connectez-vous pour synchroniser)'`r`n                : 'Ajout\u00e9 aux favoris (connectez-vous pour synchroniser)',"
    New = "            isCurrentlyLiked`r`n                ? context.tr('Retir\u00e9 des favoris (connectez-vous pour synchroniser)', 'Removed from favourites (sign in to sync)')`r`n                : context.tr('Ajout\u00e9 aux favoris (connectez-vous pour synchroniser)', 'Added to favourites (sign in to sync)'),"
  },
  # SNACKBAR favoris connecte
  @{
    Old = "          content: Text('\u2764\uFE0F Ajout\u00e9 aux favoris !', style: GoogleFonts.poppins()),"
    New = "          content: Text(context.tr('\u2764\uFE0F Ajout\u00e9 aux favoris !', '\u2764\uFE0F Added to favourites!'), style: GoogleFonts.poppins()),"
  },
  # SNACKBAR refresh
  @{
    Old = "                    '? `${_model.products.length} cadeaux charg\u00e9s !'"
    New = "                    context.tr('\u2728 `${_model.products.length} cadeaux charg\u00e9s !', '\u2728 `${_model.products.length} gifts loaded!')"
  },
  # HEADER - isAnonymousMode
  @{
    Old = "                  _model.isAnonymousMode`r`n                      ? 'D\u00e9couvre \u2728'`r`n                      : (_model.firstName.isNotEmpty`r`n                          ? 'Salut `${_model.firstName} ! \u2728'`r`n                          : 'Accueil'),"
    New = "                  _model.isAnonymousMode`r`n                      ? context.tr('D\u00e9couvre \u2728', 'Discover \u2728')`r`n                      : (_model.firstName.isNotEmpty`r`n                          ? context.tr('Salut `${_model.firstName} ! \u2728', 'Hi `${_model.firstName}! \u2728')`r`n                          : context.tr('Accueil', 'Home')),"
  },
  # HEADER sous-titre
  @{
    Old = "                _model.isAnonymousMode`r`n                    ? 'Id\u00e9es cadeaux populaires'`r`n                    : 'Voici tes inspirations cadeaux',"
    New = "                _model.isAnonymousMode`r`n                    ? context.tr('Id\u00e9es cadeaux populaires', 'Popular gift ideas')`r`n                    : context.tr('Voici tes inspirations cadeaux', 'Your personalised gift picks'),"
  },
  # LABEL Categories section
  @{
    Old = "            'Categories',"
    New = "            context.tr('Cat\u00e9gories', 'Categories'),"
  },
  # isActive comparison - use ID
  @{
    Old = "              final isActive = _model.activeCategory == category['name'];"
    New = "              // BUG FIX: isActive utilise l'ID (insensible a la langue)`r`n              final isActive = _model.activeCategoryId == category['id'];"
  },
  # onTap - update activeCategoryId + activeCategory
  @{
    Old = "                  setState(() {`r`n                    _model.activeCategory = category['name'] as String;`r`n                  });`r`n                  _loadProducts(); // Recharger les produits pour la nouvelle cat\u00e9gorie"
    New = "                  setState(() {`r`n                    _model.activeCategoryId = category['id'] as String;`r`n                    _model.activeCategory = _translateCategory(category['id'] as String, category['name'] as String);`r`n                  });`r`n                  _loadProducts();"
  },
  # Label category - use _translateCategory
  @{
    Old = "                        category['name'] as String,"
    New = "                        _translateCategory(category['id'] as String, category['name'] as String),"
  }
)

$count = 0
foreach ($fix in $fixes) {
    $allowMultiple = if ($fix.Allow) { $true } else { $false }
    if ($content.Contains($fix.Old)) {
        if ($allowMultiple) {
            $content = $content.Replace($fix.Old, $fix.New)
        } else {
            $idx = $content.IndexOf($fix.Old)
            $content = $content.Substring(0, $idx) + $fix.New + $content.Substring($idx + $fix.Old.Length)
        }
        Write-Host "OK: $($fix.Old.Substring(0, [Math]::Min(70, $fix.Old.Length)))" -ForegroundColor Green
        $count++
    } else {
        Write-Host "MISS: $($fix.Old.Substring(0, [Math]::Min(70, $fix.Old.Length)))" -ForegroundColor Yellow
    }
}

[System.IO.File]::WriteAllText($file, $content, [System.Text.Encoding]::UTF8)
Write-Host "`n$count/$($fixes.Count) remplacements appliques." -ForegroundColor Cyan
