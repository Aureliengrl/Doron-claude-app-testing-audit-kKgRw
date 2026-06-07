const fs = require('fs');

// 1. home_pinterest_widget.dart
const homePath = 'lib/pages/new_pages/home_pinterest/home_pinterest_widget.dart';
let homeContent = fs.readFileSync(homePath, 'utf8');
homeContent = homeContent.replace(/await showConnectionRequiredDialog\([\s\S]*?\);/g, '// await showConnectionRequiredDialog bypassed');
fs.writeFileSync(homePath, homeContent, 'utf8');

// 2. search_page_widget.dart
const searchPath = 'lib/pages/new_pages/search_page/search_page_widget.dart';
let searchContent = fs.readFileSync(searchPath, 'utf8');
searchContent = searchContent.replace(/builder: \(context\) => ShareListBottomSheet\(profile: profile\),/g, 'builder: (context) => Container(), // bypassed ShareListBottomSheet');
// Remove the bad import
searchContent = searchContent.replace(/import 'share_list.dart';/g, '// import share_list.dart bypassed');
fs.writeFileSync(searchPath, searchContent, 'utf8');

// 3. favourites_model.dart
const favModelPath = 'lib/pages/pages/favourites/favourites_model.dart';
let favContent = fs.readFileSync(favModelPath, 'utf8');
// remove the bad import
favContent = favContent.replace(/import 'fav_widget.dart' show FavouritesWidget;/g, '// import fav_widget.dart bypassed');
// replace FlutterFlowModel<FavouritesWidget> with FlutterFlowModel<StatefulWidget> or dynamic
favContent = favContent.replace(/extends FlutterFlowModel<FavouritesWidget>/g, 'extends FlutterFlowModel<dynamic>');
fs.writeFileSync(favModelPath, favContent, 'utf8');

console.log('Bypassed all problematic code blocks.');
