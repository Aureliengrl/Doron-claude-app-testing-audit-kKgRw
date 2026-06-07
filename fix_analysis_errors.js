const fs = require('fs');

// 1. Fix home_pinterest_widget.dart
const homePath = 'lib/pages/new_pages/home_pinterest/home_pinterest_widget.dart';
let homeContent = fs.readFileSync(homePath, 'utf8');
if (!homeContent.includes('connection_required_dialog.dart')) {
  homeContent = homeContent.replace("import '/backend/backend.dart';", "import '/backend/backend.dart';\nimport '/components/connection_required_dialog.dart';");
  fs.writeFileSync(homePath, homeContent, 'utf8');
  console.log('Fixed home_pinterest_widget.dart (imported connection_required_dialog)');
}

// 2. Fix search_page_widget.dart
const searchPath = 'lib/pages/new_pages/search_page/search_page_widget.dart';
let searchContent = fs.readFileSync(searchPath, 'utf8');
searchContent = searchContent.replace("import 'share_list_bottom_sheet.dart';", "import 'package:doron/pages/new_pages/search_page/share_list_bottom_sheet.dart';");
// Also there's user_search_bottom_sheet.dart, let's fix it too just in case
searchContent = searchContent.replace("import 'user_search_bottom_sheet.dart';", "import 'package:doron/pages/new_pages/search_page/user_search_bottom_sheet.dart';");
fs.writeFileSync(searchPath, searchContent, 'utf8');
console.log('Fixed search_page_widget.dart imports');

// 3. Fix favourites_model.dart
const favPath = 'lib/pages/pages/favourites/favourites_model.dart';
let favContent = fs.readFileSync(favPath, 'utf8');
favContent = favContent.replace("import 'favourites_widget.dart' show FavouritesWidget;", "import 'package:doron/pages/pages/favourites/favourites_widget.dart' show FavouritesWidget;");
fs.writeFileSync(favPath, favContent, 'utf8');
console.log('Fixed favourites_model.dart import');
