const fs = require('fs');

// 1. search_page_widget.dart
const searchPath = 'lib/pages/new_pages/search_page/search_page_widget.dart';
let searchContent = fs.readFileSync(searchPath, 'utf8');
searchContent = searchContent.replace(
  'child: ShareListBottomSheet(profile: profile),',
  'child: Container(), // bypassed ShareListBottomSheet'
);
searchContent = searchContent.replace(
  'child: ShareListBottomSheet(profile: profile),',
  'child: Container(), // bypassed ShareListBottomSheet'
);
fs.writeFileSync(searchPath, searchContent, 'utf8');
console.log('Fixed search_page_widget.dart');

// 2. gift_results_widget.dart
const giftPath = 'lib/pages/new_pages/gift_results/gift_results_widget.dart';
let giftContent = fs.readFileSync(giftPath, 'utf8');
giftContent = giftContent.replace(
  "import '/components/wishlist_picker_sheet.dart';",
  "// import '/components/wishlist_picker_sheet.dart';"
);
giftContent = giftContent.replace(
  'WishlistPickerSheet.show(context, gift);',
  '// WishlistPickerSheet.show(context, gift);'
);
fs.writeFileSync(giftPath, giftContent, 'utf8');
console.log('Fixed gift_results_widget.dart');
