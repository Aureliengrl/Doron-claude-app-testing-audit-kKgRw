$file = 'lib\pages\new_pages\social\friends_page.dart'
$content = Get-Content $file -Raw

# BUG 5+10: Fix remove friend icon and add setState
$old = "                    if (confirm == true) {`r`n                      await FriendService.removeFriend(uid);`r`n                      _statusCache.remove(uid);`r`n                    }`r`n                  },`r`n                  child: const Padding(`r`n                    padding: EdgeInsets.all(4),`r`n                    child: Icon(IconlyLight.profile, color: Colors.white38, size: 20),`r`n                  ),`r`n                ),"
$new = "                    if (confirm == true) {`r`n                      await FriendService.removeFriend(uid);`r`n                      // BUG 10 FIX: setState pour update UI imm\u00e9diatement`r`n                      if (mounted) setState(() => _statusCache.remove(uid));`r`n                    }`r`n                  },`r`n                  child: const Padding(`r`n                    padding: EdgeInsets.all(4),`r`n                    // BUG 5 FIX: ic\u00f4ne distincte rouge pour supprimer un ami`r`n                    child: Icon(Icons.person_remove_rounded, color: Colors.red, size: 20),`r`n                  ),`r`n                ),"
$content = $content.Replace($old, $new)
Set-Content $file $content -Encoding UTF8
Write-Host "BUG 5+10 fixed"
