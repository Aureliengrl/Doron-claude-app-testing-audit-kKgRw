$path = "lib\pages\new_pages\gift_results\gift_results_widget.dart"
$content = Get-Content -Path $path -Raw -Encoding UTF8

$content = $content -replace '(?s)final idRaw = gift\[''id''\];\s*final giftId = idRaw is int \? idRaw : \(int.tryParse\(idRaw.toString\(\)\) \?\? 0\);\s*_model.toggleLike\(giftId\);', "_model.toggleLike(gift['id']?.toString() ?? '');"

Set-Content -Path $path -Value $content -Encoding UTF8
