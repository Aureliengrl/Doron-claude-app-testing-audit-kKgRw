const fs = require('fs');
const file = 'lib/pages/new_pages/chat/chat_room_page.dart';
let c = fs.readFileSync(file, 'utf8');

// Direct CRLF replacement
const old = 'hild: Column(\r\n          children: [\r\n            _buildHeader(title, isGroup),\r\n            Expanded(\r\n              child: _buildMessagesList(),\r\n            ),\r\n            _buildTypingIndicator(),\r\n            _buildMessageInput(),\r\n          ],\r\n        ),';

const neu = 'hild: Column(\r\n          children: [\r\n            _buildHeader(title, isGroup),\r\n            // F6: Banner wishlist épinglée (groupes)\r\n            _buildPinnedWishlistBanner(),\r\n            Expanded(\r\n              child: _buildMessagesList(),\r\n            ),\r\n            _buildTypingIndicator(),\r\n            _buildMessageInput(),\r\n          ],\r\n        ),';

if (c.includes(old)) {
  c = c.replace(old, neu);
  fs.writeFileSync(file, c, 'utf8');
  console.log('F6-chat-build-banner OK');
} else {
  console.log('ERROR: not found');
}
