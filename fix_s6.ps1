$file = 'lib\pages\new_pages\chat\chat_room_page.dart'
$content = Get-Content $file -Raw -Encoding UTF8

# S6 FIX: nom reel dans le typing indicator
# Remplacer "Quelqu'un ecrit..." par la resolution du vrai nom
$old_typing_text = "          Text(`r`n            othersTyping.length == 1 ? 'Quelqu\\'un ecrit...' : 'Plusieurs personnes ecrivent...',"
if (-not $content.Contains($old_typing_text.Replace('\`r\`n', "`r`n"))) {
  # Try alternate encoding
  $old_typing_text2 = "          Text(`r`n            othersTyping.length == 1 ? 'Quelqu`'un " + [char]0xE9 + "crit...' : 'Plusieurs personnes " + [char]0xE9 + "crivent...',"
  Write-Host "Using alt encoding"
}

# On remplace le Text de typing par un FutureBuilder pour le vrai nom
$old_typing = "        Text(`r`n            othersTyping.length == 1 ? 'Quelqu"
# Find the exact line and we'll do a targeted replace
$idx = $content.IndexOf("othersTyping.length == 1 ? 'Quelqu")
if ($idx -gt 0) {
  Write-Host "Found typing text at idx $idx"
  $endIdx = $content.IndexOf(");", $idx)
  if ($endIdx -gt 0) {
    $before = $content.Substring(0, $idx - 30) # back up to include "Text("
    # Find exact start of "Text(" before the target
    $textStart = $content.LastIndexOf("Text(", $idx)
    $before2 = $content.Substring(0, $textStart)
    $after2 = $content.Substring($endIdx + 2)
    $newTyping = @'
FutureBuilder<String>(
            future: (() async {
              if (othersTyping.isEmpty) return '';
              final uid = othersTyping.first.key;
              return await _getSenderName(uid);
            })(),
            builder: (ctx, snap) {
              final name = snap.data ?? '';
              final text = othersTyping.length == 1
                  ? (name.isNotEmpty ? '$name ecrit...' : 'Quelqu un ecrit...')
                  : 'Plusieurs personnes ecrivent...';
              return Text(text,
'@
    $styleEnd = @'
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              );
            },
          )
'@
    $content = $before2 + $newTyping + $styleEnd + $after2
    Write-Host "S6 typing text replaced"
  }
} else {
  Write-Host "WARNING: typing text not found"
}

Set-Content $file $content -Encoding UTF8
Write-Host "S6 attempt done"
