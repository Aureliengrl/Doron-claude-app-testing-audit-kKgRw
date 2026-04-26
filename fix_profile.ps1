$file = 'lib\pages\new_pages\user_profile\user_profile_widget.dart'
$content = Get-Content $file -Raw

# BUG 11 FIX: recharge le profil complet apres edition (et non juste les favoris)
$old11 = "    }).then((_) {`r`n      _model.loadFavourites(); // Recharge pour sync les infos fraichement editees`r`n    });"
$new11 = "    }).then((_) {`r`n      // BUG 11 FIX: recharger profil complet (pas juste favoris)`r`n      _model.loadFavourites();`r`n      _loadWishlists();`r`n    });"
$content = $content.Replace($old11, $new11)

Set-Content $file $content -Encoding UTF8
Write-Host "BUG 11 fixed"
