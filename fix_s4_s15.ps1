$file = 'lib\pages\new_pages\chat\chat_room_page.dart'
$content = Get-Content $file -Raw -Encoding UTF8

# =============================================================
# S15 FIX: Remplacer le FutureBuilder par message par le cache
# Le FutureBuilder qui charge le profil de l'expediteur pour chaque message de groupe
# =============================================================
$oldS15 = "                  if (!isMe && isGroup && senderId != null)" + "`r`n" +
"                    FutureBuilder<DocumentSnapshot>(" + "`r`n" +
"                      future: FirebaseFirestore.instance.collection('users').doc(senderId).get()," + "`r`n" +
"                      builder: (context, userSnap) {" + "`r`n" +
"                        if (!userSnap.hasData) return const SizedBox();" + "`r`n" +
"                        final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};" + "`r`n" +
"                        return Padding(" + "`r`n" +
"                          padding: const EdgeInsets.only(left: 12, bottom: 4)," + "`r`n" +
"                          child: Text(" + "`r`n" +
"                            userData['first_name'] as String? ??  " + "`r`n" +
"                            userData['display_name'] as String? ?? " + "`r`n" +
"                            userData['name'] as String? ?? " + "`r`n" +
"                            'Utilisateur'," + "`r`n" +
"                            style: GoogleFonts.poppins(" + "`r`n" +
"                              fontSize: 11," + "`r`n" +
"                              color: Colors.white.withOpacity(0.5)," + "`r`n" +
"                              fontWeight: FontWeight.w500," + "`r`n" +
"                            )," + "`r`n" +
"                          )," + "`r`n" +
"                        );" + "`r`n" +
"                      }" + "`r`n" +
"                    ),"

$newS15 = "                  // S15 FIX: cache sender name — evite un FutureBuilder par message" + "`r`n" +
"                  if (!isMe && isGroup && senderId != null)" + "`r`n" +
"                    FutureBuilder<String>(" + "`r`n" +
"                      future: _getSenderName(senderId)," + "`r`n" +
"                      builder: (context, snap) {" + "`r`n" +
"                        if (!snap.hasData) return const SizedBox();" + "`r`n" +
"                        return Padding(" + "`r`n" +
"                          padding: const EdgeInsets.only(left: 12, bottom: 4)," + "`r`n" +
"                          child: Text(" + "`r`n" +
"                            snap.data!," + "`r`n" +
"                            style: GoogleFonts.poppins(" + "`r`n" +
"                              fontSize: 11," + "`r`n" +
"                              color: Colors.white.withOpacity(0.5)," + "`r`n" +
"                              fontWeight: FontWeight.w500," + "`r`n" +
"                            )," + "`r`n" +
"                          )," + "`r`n" +
"                        );" + "`r`n" +
"                      }," + "`r`n" +
"                    ),"

if ($content.Contains($oldS15)) {
  $content = $content.Replace($oldS15, $newS15)
  Write-Host "S15 replaced"
} else {
  Write-Host "S15: trying character-by-character search"
  $idx15 = $content.IndexOf("FutureBuilder<DocumentSnapshot>(")
  Write-Host "FutureBuilder<DocumentSnapshot> at idx $idx15"
  if ($idx15 -gt 0) {
    # Find the end of this FutureBuilder block
    $endMarker15 = "                    ),"
    $endIdx15 = $content.IndexOf($endMarker15, $idx15)
    if ($endIdx15 -gt 0) {
      $startBlock = $content.LastIndexOf("                  if (!isMe", $idx15)
      $beforeBlock = $content.Substring(0, $startBlock)
      $afterBlock = $content.Substring($endIdx15 + $endMarker15.Length)
      $content = $beforeBlock + $newS15 + $afterBlock
      Write-Host "S15 replaced via index"
    }
  }
}

# =============================================================
# S4 FIX: Long-press sur les bulles de message pour copier/supprimer
# Wrapper la Row principale des messages dans un GestureDetector
# =============================================================
$oldBubbleRow = "                  Row(" + "`r`n" +
"                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start," + "`r`n" +
"                    crossAxisAlignment: CrossAxisAlignment.end," + "`r`n" +
"                    children: [" + "`r`n" +
"                      if (messageData['type'] == 'product_card')" + "`r`n" +
"                        _buildProductCardMessage(text, isMe)" + "`r`n" +
"                      else if (messageData['type'] == 'wishlist_card')" + "`r`n" +
"                        _buildWishlistCardMessage(text, isMe)" + "`r`n" +
"                      else" + "`r`n" +
"                        Container("

$newBubbleRow = "                  // S4 FIX: Long-press pour copier/supprimer" + "`r`n" +
"                  GestureDetector(" + "`r`n" +
"                    onLongPress: () {" + "`r`n" +
"                      HapticFeedback.heavyImpact();" + "`r`n" +
"                      final msgId = messages[index].id;" + "`r`n" +
"                      showModalBottomSheet(" + "`r`n" +
"                        context: context," + "`r`n" +
"                        backgroundColor: Colors.transparent," + "`r`n" +
"                        builder: (_) => Container(" + "`r`n" +
"                          decoration: BoxDecoration(" + "`r`n" +
"                            color: const Color(0xFF1A0030)," + "`r`n" +
"                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20))," + "`r`n" +
"                            border: Border.all(color: Colors.white.withOpacity(0.1))," + "`r`n" +
"                          )," + "`r`n" +
"                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32)," + "`r`n" +
"                          child: Column(" + "`r`n" +
"                            mainAxisSize: MainAxisSize.min," + "`r`n" +
"                            children: [" + "`r`n" +
"                              Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))," + "`r`n" +
"                              const SizedBox(height: 16)," + "`r`n" +
"                              ListTile(" + "`r`n" +
"                                leading: const Icon(Icons.copy_rounded, color: Colors.white)," + "`r`n" +
"                                title: Text('Copier', style: GoogleFonts.poppins(color: Colors.white))," + "`r`n" +
"                                onTap: () {" + "`r`n" +
"                                  Navigator.pop(context);" + "`r`n" +
"                                  Clipboard.setData(ClipboardData(text: text));" + "`r`n" +
"                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(" + "`r`n" +
"                                    content: Text('Message copie', style: GoogleFonts.poppins())," + "`r`n" +
"                                    backgroundColor: const Color(0xFF8A2BE2)," + "`r`n" +
"                                    behavior: SnackBarBehavior.floating," + "`r`n" +
"                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))," + "`r`n" +
"                                    duration: const Duration(seconds: 2)," + "`r`n" +
"                                  ));" + "`r`n" +
"                                }," + "`r`n" +
"                              )," + "`r`n" +
"                              if (isMe) ListTile(" + "`r`n" +
"                                leading: const Icon(Icons.delete_rounded, color: Colors.red)," + "`r`n" +
"                                title: Text('Supprimer', style: GoogleFonts.poppins(color: Colors.red))," + "`r`n" +
"                                onTap: () async {" + "`r`n" +
"                                  Navigator.pop(context);" + "`r`n" +
"                                  await FirebaseFirestore.instance" + "`r`n" +
"                                      .collection('chats')" + "`r`n" +
"                                      .doc(widget.chatId)" + "`r`n" +
"                                      .collection('messages')" + "`r`n" +
"                                      .doc(msgId)" + "`r`n" +
"                                      .delete();" + "`r`n" +
"                                }," + "`r`n" +
"                              )," + "`r`n" +
"                            ]," + "`r`n" +
"                          )," + "`r`n" +
"                        )," + "`r`n" +
"                      );" + "`r`n" +
"                    }," + "`r`n" +
"                    child: Row(" + "`r`n" +
"                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start," + "`r`n" +
"                    crossAxisAlignment: CrossAxisAlignment.end," + "`r`n" +
"                    children: [" + "`r`n" +
"                      if (messageData['type'] == 'product_card')" + "`r`n" +
"                        _buildProductCardMessage(text, isMe)" + "`r`n" +
"                      else if (messageData['type'] == 'wishlist_card')" + "`r`n" +
"                        _buildWishlistCardMessage(text, isMe)" + "`r`n" +
"                      else" + "`r`n" +
"                        Container("

if ($content.Contains($oldBubbleRow)) {
  $content = $content.Replace($oldBubbleRow, $newBubbleRow)
  Write-Host "S4 bubble row replaced"
} else {
  # Search by index
  $idxBubble = $content.IndexOf("mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,")
  Write-Host "S4 bubble at idx $idxBubble"
}

# Close the GestureDetector after the Row's closing bracket
# Find "]," after "crossAxisAlignment: CrossAxisAlignment.end,"
# The row ends at: "                    ]," after the last child
# We need to close it with ")," for GestureDetector
# Find the pattern "                    ]," followed by "                  ),"
$oldRowEnd = "                    ]," + "`r`n" + "                  )," + "`r`n" + "                  Padding("
$newRowEnd = "                    ]," + "`r`n" + "                  )," + "`r`n" + "                  )," + "`r`n" + "                  Padding("
if ($content.Contains($oldRowEnd)) {
  $content = $content.Replace($oldRowEnd, $newRowEnd)
  Write-Host "S4 GestureDetector closed"
} else {
  Write-Host "S4: row end not found"
}

Set-Content $file $content -Encoding UTF8
Write-Host "S4+S15 done"
