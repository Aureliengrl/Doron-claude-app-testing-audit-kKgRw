import re
import sys

path = 'lib/pages/new_pages/onboarding_advanced/onboarding_advanced_widget.dart'
try:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
except FileNotFoundError:
    print("File not found.")
    sys.exit(1)

# 1. Update _handleSuggestions loop (Exact match logic)
old_exact = """                          if (exact.isNotEmpty) {
                            _foundDoronUser = exact.first;
                          }"""

new_exact = """                          if (exact.isNotEmpty) {
                            _foundDoronUser = exact.first;
                            _model.answers['isHandleValid'] = true;
                          } else {
                            _model.answers['isHandleValid'] = false;
                          }"""
content = content.replace(old_exact, new_exact)

# 2. Add handling for empty values resetting validation
old_value_length = """                  if (value.length >= 2) {"""
new_value_length = """                  if (value.isEmpty) {
                    _model.answers['isHandleValid'] = true;
                  }
                  if (value.length >= 2) {"""
content = content.replace(old_value_length, new_value_length)

# 3. Handle onTap suggestions
old_on_tap = """                      onTap: () {
                        setLocal(() {
                          _model.answers[field] = user['handle'] as String;
                          _foundDoronUser = user;
                          _handleSuggestions = [];
                          controller.text = user['handle'] as String;
                        });
                      },"""
new_on_tap = """                      onTap: () {
                        setLocal(() {
                          _model.answers[field] = user['handle'] as String;
                          _model.answers['isHandleValid'] = true;
                          _foundDoronUser = user;
                          _handleSuggestions = [];
                          controller.text = user['handle'] as String;
                        });
                      },"""
content = content.replace(old_on_tap, new_on_tap)

# 4. Add the Red Badge and Update the Info optionnel
old_info = """            // Info optionnel
            if (_foundDoronUser == null && _handleSuggestions.isEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Si cette personne a un compte Doron, ses wishlists seront incluses dans les suggestions',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.white38),
              ),
            ],"""

new_info = """            // Info optionnel et erreur
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
                          'Ce pseudo n\\'existe pas',
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
            ],"""
content = content.replace(old_info, new_info)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Widget updated successfully.")
