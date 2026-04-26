const fs = require('fs');

// Fix #10a: sort + Fix #4: réservations dans profil public
{
  const file = 'lib/pages/new_pages/home_pinterest/home_pinterest_widget.dart';
  let c = fs.readFileSync(file, 'utf8');
  
  // On trouve la ligne par index de caractères spécifiques
  const marker = '}).toList();\r\n\r\n      AppLogger.debug(';
  const idx = c.lastIndexOf(marker, c.indexOf('Sauvegarder les nouveaux IDs'));
  
  if (idx !== -1) {
    const before = c.substring(0, idx + marker.length);
    const after = c.substring(idx + marker.length);
    const sortCode = `\r\n      // #FIX-10a: produits avec image en premier, puis par score de match\r\n      products.sort((a, b) {\r\n        final aHasImage = (a['image']?.toString() ?? '').isNotEmpty ? 0 : 1;\r\n        final bHasImage = (b['image']?.toString() ?? '').isNotEmpty ? 0 : 1;\r\n        if (aHasImage != bHasImage) return aHasImage.compareTo(bHasImage);\r\n        return ((b['match'] as int?) ?? 0).compareTo((a['match'] as int?) ?? 0);\r\n      });\r\n      `;
    c = before + sortCode + after;
    fs.writeFileSync(file, c, 'utf8');
    console.log('✅ Fix #10a: tri produits enrichis en premier appliqué');
  } else {
    // Try alternative - find Dart source around the area using simpler string
    const alt = `}).toList();`;
    const occurrences = [];
    let searchFrom = 0;
    while (true) {
      const pos = c.indexOf(alt, searchFrom);
      if (pos === -1) break;
      occurrences.push(pos);
      searchFrom = pos + 1;
    }
    console.log(`⚠️  Fix #10a: found ${occurrences.length} occurrences of }).toList()`);
    console.log('   Chars around position 360:', JSON.stringify(c.substring(c.indexOf('Sauvegarder les nouveaux') - 80, c.indexOf('Sauvegarder les nouveaux') + 20)));
  }
}

// Fix #11: Chat read receipts — ajouter readBy update quand on ouvre un chat
{
  const file = 'lib/pages/new_pages/chat/chat_room_page.dart';
  let c = fs.readFileSync(file, 'utf8');
  
  if (c.includes('readBy') && !c.includes('_markMessagesAsRead')) {
    console.log('ℹ️  Fix #11: readBy existe mais pas de markAsRead — ajout manuel requis');
  } else if (c.includes('_markMessagesAsRead')) {
    console.log('ℹ️  Fix #11: _markMessagesAsRead déjà présent');
  } else {
    // Chercher où les messages sont affichés pour ajouter la mise à jour
    console.log('⚠️  Fix #11: structure chat à analyser manuellement');
  }
}

console.log('\nDone.');
