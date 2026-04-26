const fs = require('fs');
const path = require('path');

const tryReplace = (content, oldStr, newStr, label) => {
  const oldCRLF = oldStr.replace(/\n/g, '\r\n');
  const newCRLF = newStr.replace(/\n/g, '\r\n');
  if (content.includes(oldCRLF)) { console.log(label + ': replaced CRLF'); return content.replace(oldCRLF, newCRLF); }
  if (content.includes(oldStr))   { console.log(label + ': replaced LF');   return content.replace(oldStr, newStr); }
  const cLines = content.split('\n').map(l => l.replace(/\r$/, ''));
  const oLines = oldStr.split('\n').map(l => l.trimEnd());
  let startIdx = -1;
  outer: for (let i = 0; i < cLines.length; i++) {
    for (let j = 0; j < oLines.length; j++) {
      if (cLines[i+j]?.trimEnd() !== oLines[j]) break;
      if (j === oLines.length - 1) { startIdx = i; break outer; }
    }
  }
  if (startIdx >= 0) {
    const allLines = content.split('\n');
    allLines.splice(startIdx, oLines.length, ...newCRLF.split('\r\n'));
    console.log(label + ': replaced via line match at line ' + startIdx);
    return allLines.join('\n');
  }
  console.log('ERROR: ' + label + ' not found');
  return content;
};

// S9 FIX: Afficher isOnline/lastSeen sur le profil public, sous le handle
const ppFile = path.join('lib', 'pages', 'new_pages', 'public_profile', 'public_profile_page.dart');
let ppContent = fs.readFileSync(ppFile, 'utf8');

const old9 = `                  if (handle.isNotEmpty)
                    Text(
                      '@$handle',
                      style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
                    ),
                  if (bio.isNotEmpty)`;

const new9 = `                  if (handle.isNotEmpty)
                    Text(
                      '@$handle',
                      style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
                    ),
                  // S9 FIX: afficher la presence en ligne sur le profil public
                  if (!_isMyProfile) Builder(builder: (ctx) {
                    final isOnline = _profile?['isOnline'] == true;
                    final lastSeen = _profile?['lastSeen'];
                    String statusText = '';
                    Color statusColor = Colors.white38;
                    if (isOnline) {
                      statusText = 'En ligne';
                      statusColor = const Color(0xFF10B981);
                    } else if (lastSeen != null) {
                      final seen = (lastSeen as dynamic).toDate() as DateTime;
                      final diff = DateTime.now().difference(seen);
                      if (diff.inMinutes < 1) { statusText = 'Vu a l instant'; statusColor = Colors.white54; }
                      else if (diff.inMinutes < 60) { statusText = 'Vu il y a \${diff.inMinutes} min'; statusColor = Colors.white38; }
                      else if (diff.inHours < 24) { statusText = 'Vu il y a \${diff.inHours}h'; statusColor = Colors.white38; }
                    }
                    if (statusText.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Container(width: 7, height: 7, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text(statusText, style: GoogleFonts.outfit(fontSize: 12, color: statusColor)),
                        ],
                      ),
                    );
                  }),
                  if (bio.isNotEmpty)`;

ppContent = tryReplace(ppContent, old9, new9, 'S9-presence-ui');
fs.writeFileSync(ppFile, ppContent, 'utf8');
console.log('S9 public profile presence UI done');
