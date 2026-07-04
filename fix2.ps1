$path = "lib\pages\new_pages\gift_results\gift_results_widget.dart"
$content = Get-Content -Path $path -Raw -Encoding UTF8

$oldToggleMultiline = @"
                                  final idRaw = gift['id'];
                                  final giftId = idRaw is int ? idRaw : (int.tryParse(idRaw.toString()) ?? 0);
                                  _model.toggleLike(giftId);
"@

$newToggleMultiline = "_model.toggleLike(gift['id']?.toString() ?? '');"

$content = $content.Replace($oldToggleMultiline, $newToggleMultiline)

Set-Content -Path $path -Value $content -Encoding UTF8
