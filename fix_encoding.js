const fs = require('fs');

const file = './lib/pages/new_pages/user_profile/user_profile_widget.dart';
let content = fs.readFileSync(file, 'utf8');

content = content.replace(/âà¢â"šÂ¬Ã‚Â à¢ââ‚¬Å¡Ã‚Â¬/g, '-');
content = content.replace(/âà¢ââ‚¬Å¡Ã‚Â¬à¢â"šÂ¬Ã‚Â /g, '-');
content = content.replace(/-{4,}/g, '---');
content = content.replace(/\/\/ ---+/g, '// ---');
content = content.replace(/\/\/ --/g, '// ---');
content = content.replace(/--- ---/g, '---');

fs.writeFileSync(file, content, 'utf8');
console.log('Done 5');
