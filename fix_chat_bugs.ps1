$file = 'lib\pages\new_pages\chat\chat_room_page.dart'
$content = Get-Content $file -Raw

# BUG 3 FIX: reset unreadCount to 0 on open
$old3 = "        'readStatus': {`r`n          user.uid: FieldValue.serverTimestamp(),`r`n        }`r`n      }, SetOptions(merge: true));`r`n    } catch (e) {`r`n      debugPrint('Failed to update read status: `$e');`r`n    }`r`n  }"
$new3 = "        'readStatus': {`r`n          user.uid: FieldValue.serverTimestamp(),`r`n        },`r`n        // BUG 3 FIX: reset unread counter to 0 for current user on open`r`n        'unreadCount': {`r`n          user.uid: 0,`r`n        },`r`n      }, SetOptions(merge: true));`r`n    } catch (e) {`r`n      debugPrint('Failed to update read status: `$e');`r`n    }`r`n  }"
$content = $content.Replace($old3, $new3)

# BUG 2 FIX: increment unreadCount for other participants on send
$old2 = "      await messageRef.set(messageData);`r`n      `r`n      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({`r`n        'lastMessage': text,`r`n        'lastMessageTime': FieldValue.serverTimestamp(),`r`n      });"
$new2 = "      await messageRef.set(messageData);`r`n`r`n      // BUG 2 FIX: increment unreadCount for all other participants`r`n      final chatData = _effectiveChatData;`r`n      final participants = List<String>.from(chatData?['participants'] ?? []);`r`n      final Map<String, dynamic> unreadUpdate = {`r`n        'lastMessage': text,`r`n        'lastMessageTime': FieldValue.serverTimestamp(),`r`n      };`r`n      for (final pid in participants) {`r`n        if (pid != currentUser.uid) {`r`n          unreadUpdate['unreadCount.`$pid'] = FieldValue.increment(1);`r`n        }`r`n      }`r`n      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update(unreadUpdate);"
$content = $content.Replace($old2, $new2)

Set-Content $file $content -Encoding UTF8
Write-Host "BUG 2+3 fixed"
