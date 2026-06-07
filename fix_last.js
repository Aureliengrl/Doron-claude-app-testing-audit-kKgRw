const fs = require('fs');

// 1. home_pinterest_widget.dart
const homePath = 'lib/pages/new_pages/home_pinterest/home_pinterest_widget.dart';
let homeContent = fs.readFileSync(homePath, 'utf8');

// Fix missing violetColor argument
homeContent = homeContent.replace(
  /SearchBarWidget\([\s\S]*?controller: _searchController,/g,
  'SearchBarWidget(\n                          violetColor: DoronTheme.of(context).primary,\n                          controller: _searchController,'
);

fs.writeFileSync(homePath, homeContent, 'utf8');

console.log('Fixed home_pinterest_widget.dart violetColor.');
