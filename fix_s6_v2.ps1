$file = 'lib\pages\new_pages\chat\chat_room_page.dart'
$content = Get-Content $file -Raw -Encoding UTF8

# S6 FIX: vrai nom dans le typing indicator
# Remplacer le bloc Text( simple par une version qui resout le nom
$oldTyp = "          const SizedBox(width: 8),`r`n          Text(`r`n            othersTyping.length == 1 ? 'Quelqu"
$idx = $content.IndexOf("const SizedBox(width: 8),`r`n          Text(`r`n            othersTyping.length == 1")
if ($idx -lt 0) {
  # Try without CRLF
  $idx = $content.IndexOf("const SizedBox(width: 8),")
  Write-Host "idx2 = $idx"
}
Write-Host "idx = $idx"

# Approche directe: replacer toute la section du Widget typing indicator
$oldTypingWidget = @'
  Widget _buildTypingIndicator() {
    if (_chatDocData.isEmpty || !_chatDocData.containsKey('typingUsers')) return const SizedBox.shrink();
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();
    
    final typingUsers = _chatDocData['typingUsers'] as Map<String, dynamic>;
    final othersTyping = typingUsers.entries.where((e) {
      if (e.key == currentUser.uid) return false;
      final time = e.value as int?;
      if (time == null) return false;
      // if it's older than 3 seconds, ignore
      return DateTime.now().millisecondsSinceEpoch - time < 3000;
    }).toList();
    
    if (othersTyping.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Row(
            children: [
              _buildTypingDot(0),
              const SizedBox(width: 4),
              _buildTypingDot(200),
              const SizedBox(width: 4),
              _buildTypingDot(400),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            othersTyping.length == 1 ? 'Quelqu\'un ' + String.fromCharCode(0xE9) + 'crit...' : 'Plusieurs personnes ' + String.fromCharCode(0xE9) + 'crivent...',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }
'@

$newTypingWidget = @'
  // S6 FIX: affiche le vrai prenom de la personne qui ecrit
  Widget _buildTypingIndicator() {
    if (_chatDocData.isEmpty || !_chatDocData.containsKey('typingUsers')) return const SizedBox.shrink();
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();
    
    final typingUsers = _chatDocData['typingUsers'] as Map<String, dynamic>;
    final othersTyping = typingUsers.entries.where((e) {
      if (e.key == currentUser.uid) return false;
      final time = e.value as int?;
      if (time == null) return false;
      return DateTime.now().millisecondsSinceEpoch - time < 3000;
    }).toList();
    
    if (othersTyping.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: FutureBuilder<String>(
        future: (() async {
          if (othersTyping.isEmpty) return '';
          final uid = othersTyping.first.key;
          return await _getSenderName(uid);
        })(),
        builder: (ctx, snap) {
          final name = snap.data ?? '';
          final typingText = othersTyping.length == 1
              ? (name.isNotEmpty ? '$name ecrit...' : 'Quelqu un ecrit...')
              : 'Plusieurs personnes ecrivent...';
          return Row(
            children: [
              Row(
                children: [
                  _buildTypingDot(0),
                  const SizedBox(width: 4),
                  _buildTypingDot(200),
                  const SizedBox(width: 4),
                  _buildTypingDot(400),
                ],
              ),
              const SizedBox(width: 8),
              Text(
                typingText,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ).animate().fadeIn();
        },
      ),
    );
  }
'@

# Find and replace using index-based approach
$startMarker = "  Widget _buildTypingIndicator() {"
$endMarker = "  Widget _buildTypingDot(int delayMs) {"
$startIdx = $content.IndexOf($startMarker)
$endIdx = $content.IndexOf($endMarker)
if ($startIdx -gt 0 -and $endIdx -gt 0) {
  $before = $content.Substring(0, $startIdx)
  $after = $content.Substring($endIdx)
  $content = $before + $newTypingWidget + "`r`n`r`n  " + $after
  Write-Host "S6 typing indicator replaced"
} else {
  Write-Host "ERROR: markers not found startIdx=$startIdx endIdx=$endIdx"
}

Set-Content $file $content -Encoding UTF8
Write-Host "S6 done"
