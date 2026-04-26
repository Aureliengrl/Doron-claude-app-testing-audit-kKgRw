const fs = require('fs');
const path = require('path');

const filePath = path.join('lib', 'pages', 'new_pages', 'chat', 'chat_room_page.dart');
let content = fs.readFileSync(filePath, 'utf8');

// ============================================================
// S15 FIX: Replace FutureBuilder<DocumentSnapshot> with cached version
// ============================================================
const old15 = `                  if (!isMe && isGroup && senderId != null)
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(senderId).get(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData) return const SizedBox();
                        final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
                        return Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 4),
                          child: Text(
                            userData['first_name'] as String? ??  
                            userData['display_name'] as String? ?? 
                            userData['name'] as String? ?? 
                            'Utilisateur',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                    ),`;

const new15 = `                  // S15 FIX: cache sender name - un seul fetch Firestore par UID (evite N appels par scroll)
                  if (!isMe && isGroup && senderId != null)
                    FutureBuilder<String>(
                      future: _getSenderName(senderId),
                      builder: (context, snap) {
                        if (!snap.hasData) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 4),
                          child: Text(
                            snap.data!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),`;

// Try both CRLF and LF
let replaced15 = false;
if (content.includes(old15.replace(/\n/g, '\r\n'))) {
  content = content.replace(old15.replace(/\n/g, '\r\n'), new15.replace(/\n/g, '\r\n'));
  console.log('S15: replaced CRLF');
  replaced15 = true;
} else if (content.includes(old15)) {
  content = content.replace(old15, new15);
  console.log('S15: replaced LF');
  replaced15 = true;
} else {
  // Line-by-line fuzzy match
  const contentLines = content.split('\n').map(l => l.replace(/\r$/, ''));
  const oldLines = old15.split('\n').map(l => l.trimEnd());
  let startIdx = -1;
  outer: for (let i = 0; i < contentLines.length; i++) {
    for (let j = 0; j < oldLines.length; j++) {
      if (contentLines[i + j]?.trimEnd() !== oldLines[j]) break;
      if (j === oldLines.length - 1) { startIdx = i; break outer; }
    }
  }
  if (startIdx >= 0) {
    const allLines = content.split('\n');
    const before = allLines.slice(0, startIdx);
    const after = allLines.slice(startIdx + oldLines.length);
    allLines.splice(startIdx, oldLines.length, ...new15.split('\n'));
    content = allLines.join('\n');
    console.log('S15: replaced via line match at line ' + startIdx);
    replaced15 = true;
  } else {
    console.log('ERROR: S15 pattern not found');
  }
}

// ============================================================
// S4 FIX: Wrap message Row in GestureDetector for long-press
// ============================================================
const old4 = `                  Row(
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (messageData['type'] == 'product_card')
                        _buildProductCardMessage(text, isMe)
                      else if (messageData['type'] == 'wishlist_card')
                        _buildWishlistCardMessage(text, isMe)
                      else
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isMe ? violetColor : Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(isMe ? 20 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 20),
                            ),
                            border: isMe ? null : Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            text,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),`;

const new4 = `                  // S4 FIX: long-press pour copier ou supprimer le message
                  GestureDetector(
                    onLongPress: () {
                      HapticFeedback.heavyImpact();
                      final msgId = messages[index].id;
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A0030),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: const Icon(Icons.copy_rounded, color: Colors.white),
                                title: Text('Copier', style: GoogleFonts.poppins(color: Colors.white)),
                                onTap: () {
                                  Navigator.pop(context);
                                  Clipboard.setData(ClipboardData(text: text));
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Message copie', style: GoogleFonts.poppins()),
                                    backgroundColor: const Color(0xFF8A2BE2),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    duration: const Duration(seconds: 2),
                                  ));
                                },
                              ),
                              if (isMe) ListTile(
                                leading: const Icon(Icons.delete_rounded, color: Colors.red),
                                title: Text('Supprimer', style: GoogleFonts.poppins(color: Colors.red)),
                                onTap: () async {
                                  Navigator.pop(context);
                                  await FirebaseFirestore.instance
                                      .collection('chats')
                                      .doc(widget.chatId)
                                      .collection('messages')
                                      .doc(msgId)
                                      .delete();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Row(
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (messageData['type'] == 'product_card')
                        _buildProductCardMessage(text, isMe)
                      else if (messageData['type'] == 'wishlist_card')
                        _buildWishlistCardMessage(text, isMe)
                      else
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isMe ? violetColor : Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(isMe ? 20 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 20),
                            ),
                            border: isMe ? null : Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            text,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                    ),
                  ),`;

if (content.includes(old4.replace(/\n/g, '\r\n'))) {
  content = content.replace(old4.replace(/\n/g, '\r\n'), new4.replace(/\n/g, '\r\n'));
  console.log('S4: replaced CRLF');
} else if (content.includes(old4)) {
  content = content.replace(old4, new4);
  console.log('S4: replaced LF');
} else {
  const contentLines = content.split('\n').map(l => l.replace(/\r$/, ''));
  const oldLines4 = old4.split('\n').map(l => l.trimEnd());
  let startIdx4 = -1;
  outer4: for (let i = 0; i < contentLines.length; i++) {
    for (let j = 0; j < oldLines4.length; j++) {
      if (contentLines[i + j]?.trimEnd() !== oldLines4[j]) break;
      if (j === oldLines4.length - 1) { startIdx4 = i; break outer4; }
    }
  }
  if (startIdx4 >= 0) {
    const allLines4 = content.split('\n');
    allLines4.splice(startIdx4, oldLines4.length, ...new4.split('\n'));
    content = allLines4.join('\n');
    console.log('S4: replaced via line match at line ' + startIdx4);
  } else {
    console.log('ERROR: S4 pattern not found');
  }
}

fs.writeFileSync(filePath, content, 'utf8');
console.log('Done: S4+S15 complete');
