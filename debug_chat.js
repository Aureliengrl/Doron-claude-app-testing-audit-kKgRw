const fs = require('fs');

const file = 'lib/pages/new_pages/chat/chat_room_page.dart';
let c = fs.readFileSync(file, 'utf8');

// Find the exact column structure by looking at raw content
const idx = c.indexOf('_buildHeader(title, isGroup)');
if (idx < 0) { console.log('ERROR: header not found'); process.exit(1); }
console.log('Found _buildHeader at char', idx);

// Show 200 chars before and after
const snippet = c.substring(idx - 50, idx + 300);
console.log('---SNIPPET---');
console.log(JSON.stringify(snippet));
