import re

file_path = r'lib\pages\new_pages\chat\chat_room_page.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# ============================================================
# S15 FIX: remplacer FutureBuilder<DocumentSnapshot> par cache
# ============================================================
old_s15 = '''                  if (!isMe && isGroup && senderId != null)
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
                    ),'''

new_s15 = '''                  // S15 FIX: cache sender name — un seul fetch Firestore par UID (avant: N appels par scroll)
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
                    ),'''

# Try with \r\n
old_s15_crlf = old_s15.replace('\n', '\r\n')
new_s15_crlf = new_s15.replace('\n', '\r\n')

if old_s15_crlf in content:
    content = content.replace(old_s15_crlf, new_s15_crlf)
    print('S15 CRLF replaced')
elif old_s15 in content:
    content = content.replace(old_s15, new_s15)
    print('S15 LF replaced')
else:
    # Try stripping trailing spaces from each line
    lines_old = [l.rstrip() for l in old_s15.splitlines()]
    lines_content = [l.rstrip() for l in content.splitlines()]
    # Find match
    idx = -1
    for i in range(len(lines_content)):
        if lines_content[i:i+len(lines_old)] == lines_old:
            idx = i
            break
    if idx >= 0:
        # Find actual position in content
        split_content = content.splitlines(keepends=True)
        start_pos = sum(len(l) for l in split_content[:idx])
        end_pos = sum(len(l) for l in split_content[:idx+len(lines_old)])
        content = content[:start_pos] + new_s15_crlf + '\r\n' + content[end_pos:]
        print(f'S15 replaced at line {idx}')
    else:
        print('ERROR: S15 pattern not found')

# ============================================================
# S4 FIX: ajouter long-press sur les messages
# ============================================================
old_s4 = '''                  Row(
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
                  ),'''

new_s4 = '''                  // S4 FIX: long-press pour copier ou supprimer le message
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
                                    content: Text('Message copié', style: GoogleFonts.poppins()),
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
                  ),'''

old_s4_crlf = old_s4.replace('\n', '\r\n')
new_s4_crlf = new_s4.replace('\n', '\r\n')

if old_s4_crlf in content:
    content = content.replace(old_s4_crlf, new_s4_crlf)
    print('S4 CRLF replaced')
elif old_s4 in content:
    content = content.replace(old_s4, new_s4)
    print('S4 LF replaced')
else:
    # Strip trailing spaces from each line comparison
    lines_old4 = [l.rstrip() for l in old_s4.splitlines()]
    lines_content4 = [l.rstrip() for l in content.splitlines()]
    idx4 = -1
    for i in range(len(lines_content4)):
        if lines_content4[i:i+len(lines_old4)] == lines_old4:
            idx4 = i
            break
    if idx4 >= 0:
        split_content4 = content.splitlines(keepends=True)
        start_pos4 = sum(len(l) for l in split_content4[:idx4])
        end_pos4 = sum(len(l) for l in split_content4[:idx4+len(lines_old4)])
        content = content[:start_pos4] + new_s4_crlf + '\r\n' + content[end_pos4:]
        print(f'S4 replaced at line {idx4}')
    else:
        print('ERROR: S4 pattern not found')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Done: S4+S15 complete')
