const fs = require('fs');
const path = 'lib/repositories/src/catalog_repository.dart';
let content = fs.readFileSync(path, 'utf8');

content = content.replace(
  'FirebaseDataService.getGifts(category: category, limit: limit)',
  'FirebaseDataService.getGifts(categories: category != null ? [category] : null, limit: limit)'
);

content = content.replace(
  'FirebaseDataService.saveGiftSuggestions(\n        profileId: profileId,\n        gifts: gifts,\n      )',
  'FirebaseDataService.saveGiftSuggestions(\n        searchId: profileId,\n        gifts: gifts,\n      )'
);

// If the above replace didn't work due to whitespace:
content = content.replace(/profileId:\s*profileId,\s*gifts:\s*gifts/m, 'searchId: profileId,\n        gifts: gifts');

fs.writeFileSync(path, content, 'utf8');
console.log('Fixed catalog_repository.dart');
