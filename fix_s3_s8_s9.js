const fs = require('fs');
const path = require('path');

// ============================================================
// S8 FIX: "Vu par" dans les groupes (afficher qui a lu)
// On ajoute un indicateur sous le timestamp du dernier message de l'expéditeur
// ============================================================
const chatFile = path.join('lib', 'pages', 'new_pages', 'chat', 'chat_room_page.dart');
let content = fs.readFileSync(chatFile, 'utf8');

const old8 = `                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            isReadByOthers ? IconlyBold.shieldDone : Icons.check,
                            size: 14,
                            color: isReadByOthers ? const Color(0xFF34D399) : Colors.white.withOpacity(0.4),
                          ),
                        ],
                      ],
                    ),
                  ),`;

const new8 = `                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            isReadByOthers ? IconlyBold.shieldDone : Icons.check,
                            size: 14,
                            color: isReadByOthers ? const Color(0xFF34D399) : Colors.white.withOpacity(0.4),
                          ),
                          // S8 FIX: "Vu par" dans les groupes
                          if (isGroup && isReadByOthers) ...[
                            const SizedBox(width: 4),
                            Builder(builder: (ctx) {
                              final readStatuses = _chatDocData['readStatus'] as Map<String, dynamic>? ?? {};
                              final readBy = readStatuses.keys.where((k) {
                                if (k == currentUser.uid) return false;
                                final t = readStatuses[k] as Timestamp?;
                                return t != null && timestamp != null && t.compareTo(timestamp) >= 0;
                              }).length;
                              if (readBy == 0) return const SizedBox.shrink();
                              return Text(
                                'Vu $readBy',
                                style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF34D399)),
                              );
                            }),
                          ],
                        ],
                      ],
                    ),
                  ),`;

const tryReplace = (content, oldStr, newStr, label) => {
  const oldCRLF = oldStr.replace(/\n/g, '\r\n');
  const newCRLF = newStr.replace(/\n/g, '\r\n');
  if (content.includes(oldCRLF)) { console.log(label + ': replaced CRLF'); return content.replace(oldCRLF, newCRLF); }
  if (content.includes(oldStr))   { console.log(label + ': replaced LF');   return content.replace(oldStr, newStr); }
  // Line-by-line fuzzy
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
  console.log('ERROR: ' + label + ' pattern not found');
  return content;
};

content = tryReplace(content, old8, new8, 'S8');
fs.writeFileSync(chatFile, content, 'utf8');
console.log('chat_room_page.dart S8 done');

// ============================================================
// S3 FIX: Indicateur presence (point vert) sur les tiles d'amis
// ============================================================
const friendsFile = path.join('lib', 'pages', 'new_pages', 'social', 'friends_page.dart');
let friendsContent = fs.readFileSync(friendsFile, 'utf8');

const oldFriendAvatar = `                GestureDetector(
                  onTap: () => _openProfile(uid),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _violet.withOpacity(0.3),
                    backgroundImage: photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? Text(name[0].toUpperCase(),
                            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))`;

const newFriendAvatar = `                // S3 FIX: indicateur de presence en ligne sur l'avatar
                GestureDetector(
                  onTap: () => _openProfile(uid),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: _violet.withOpacity(0.3),
                        backgroundImage: photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
                        child: photoUrl.isEmpty
                            ? Text(name[0].toUpperCase(),
                                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))`;

const oldFriendAvatarEnd = `                        : null,
                  ),
                ),`;

const newFriendAvatarEnd = `                            : null,
                      ),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                        builder: (ctx, snap) {
                          if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();
                          final data = snap.data!.data() as Map<String, dynamic>? ?? {};
                          if (data['isOnline'] != true) return const SizedBox.shrink();
                          return Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF0D0D1A), width: 2),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),`;

friendsContent = tryReplace(friendsContent, oldFriendAvatar, newFriendAvatar, 'S3-friends-avatar');
friendsContent = tryReplace(friendsContent, oldFriendAvatarEnd, newFriendAvatarEnd, 'S3-friends-avatar-end');
fs.writeFileSync(friendsFile, friendsContent, 'utf8');
console.log('friends_page.dart S3 done');

// ============================================================
// S9 FIX: lastSeen sur le profil public
// ============================================================
const publicProfileFile = path.join('lib', 'pages', 'new_pages', 'public_profile', 'public_profile_page.dart');
let ppContent = fs.readFileSync(publicProfileFile, 'utf8');

// Find onde il y a la bio et ajouter le lastSeen en-dessous
const oldBio = `'bio': data['bio'] ?? '',
        }`;
const newBio = `'bio': data['bio'] ?? '',
          'isOnline': data['isOnline'] ?? false,
          'lastSeen': data['lastSeen'],
        }`;

ppContent = tryReplace(ppContent, oldBio, newBio, 'S9-profile-data');
fs.writeFileSync(publicProfileFile, ppContent, 'utf8');
console.log('public_profile_page.dart S9 data done');

console.log('All done: S3 friends + S8 vu par + S9 profile data');
