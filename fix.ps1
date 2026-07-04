$path = "lib\pages\new_pages\gift_results\gift_results_widget.dart"
$content = Get-Content -Path $path -Raw -Encoding UTF8

$content = $content.Replace("_model.likedGifts.contains(gift['id'])", "_model.likedGifts.contains(gift['id']?.toString())")

$oldToggle = "final idRaw = gift['id'];
                                  final giftId = idRaw is int ? idRaw : (int.tryParse(idRaw.toString()) ?? 0);
                                  _model.toggleLike(giftId);"
$newToggle = "_model.toggleLike(gift['id']?.toString() ?? '');"

$content = $content.Replace($oldToggle, $newToggle)

$oldToggleInline = "final idRaw = gift['id']; final giftId = idRaw is int ? idRaw : (int.tryParse(idRaw.toString()) ?? 0); _model.toggleLike(giftId);"
$newToggleInline = "_model.toggleLike(gift['id']?.toString() ?? '');"

$content = $content.Replace($oldToggleInline, $newToggleInline)

Set-Content -Path $path -Value $content -Encoding UTF8
