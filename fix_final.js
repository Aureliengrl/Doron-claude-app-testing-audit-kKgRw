const fs = require('fs');

// 1. home_pinterest_widget.dart
const homePath = 'lib/pages/new_pages/home_pinterest/home_pinterest_widget.dart';
let homeContent = fs.readFileSync(homePath, 'utf8');

// remove ALL mentions of connection_required_dialog.dart import
homeContent = homeContent.replace(/import '\/components\/connection_required_dialog\.dart';/g, "// removed connection_required_dialog");

// fix DoronTheme
homeContent = homeContent.replace(/DoronTheme/g, "FlutterFlowTheme");

fs.writeFileSync(homePath, homeContent, 'utf8');

// 2. favourites_model.dart
const favModelPath = 'lib/pages/pages/favourites/favourites_model.dart';
let favContent = fs.readFileSync(favModelPath, 'utf8');
// replace FlutterFlowModel<dynamic> with FlutterFlowModel<StatefulWidget>
favContent = favContent.replace(/extends FlutterFlowModel<dynamic>/g, 'extends FlutterFlowModel<StatefulWidget>');
fs.writeFileSync(favModelPath, favContent, 'utf8');

console.log('Final fixes applied.');
