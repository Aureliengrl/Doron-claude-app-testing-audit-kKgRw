$path = "lib\pages\new_pages\onboarding_advanced\onboarding_advanced_widget.dart"
$content = Get-Content -Path $path -Raw -Encoding UTF8

$content = $content -replace '(?s)if \(exact\.isNotEmpty\) \{[\r\n\s]*_foundDoronUser = exact\.first;[\r\n\s]*\}', "if (exact.isNotEmpty) {
                            _foundDoronUser = exact.first;
                            _model.answers['isHandleValid'] = true;
                          } else {
                            _model.answers['isHandleValid'] = false;
                          }"

$content = $content -replace '(?s)onTap: \(\) \{[\r\n\s]*setLocal\(\(\) \{[\r\n\s]*_model\.answers\[field\] = user\[''handle''\] as String;[\r\n\s]*_foundDoronUser = user;', "onTap: () {
                        setLocal(() {
                          _model.answers[field] = user['handle'] as String;
                          _model.answers['isHandleValid'] = true;
                          _foundDoronUser = user;"

$content = $content -replace '(?s)// Info optionnel[\r\n\s]*if \(_foundDoronUser == null && _handleSuggestions\.isEmpty\) \.\.\.\[[\r\n\s]*const SizedBox\(height: 4\),[\r\n\s]*Text\([\r\n\s]*''Si cette personne a un compte Doron, ses wishlists seront incluses dans les suggestions'',[\r\n\s]*style: GoogleFonts\.poppins\(fontSize: 11, color: Colors\.white38\),[\r\n\s]*\),[\r\n\s]*\],', "// Info optionnel et erreur
            if (_foundDoronUser == null && _handleSuggestions.isEmpty) ...[
              if (controller.text.replaceAll('@', '').trim().length >= 2 && !_isSearchingHandle) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ce pseudo n''existe pas',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 4),
                Text(
                  'Si cette personne a un compte Doron, ses wishlists seront incluses dans les suggestions',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.white38),
                ),
              ],
            ],"

Set-Content -Path $path -Value $content -Encoding UTF8
