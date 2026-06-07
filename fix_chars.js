const fs = require('fs');

const path = "lib/pages/new_pages/search_page/search_page_widget.dart";
let content = fs.readFileSync(path, "utf8");

// Replace iconly
content = content.replace("import 'package:flutter_iconly/flutter_iconly.dart';", "import '/utils/iconly_compat.dart';");

// Find "Too many positional arguments" around Container
// lines 714, 1668, 1765
let lines = content.split('\n');
console.log("Line 713 char codes: " + [...lines[713]].map(c => c.charCodeAt(0)).join(','));

// Let's strip ALL invisible characters like \u200B, \u00A0
content = content.replace(/[\u200B\u00A0]/g, ' ');

// Fix bracket issue
// Error: Expected an identifier, but got ']' at 254, 881, 1756, 1780.
// Is it `] ,` ? No, Dart allows trailing commas.
// Wait! Dart allows trailing commas in collections. BUT does it allow it in `Stack(children: [ ... , ])` ? YES.
// Does it allow `[ , ]` ? NO.
// Is it possible the lines look like `          ],` but there's a missing `child:` or something?
// Let's replace `],` with `]` just in case? No, it shouldn't matter.
// Wait! If the error is "Expected an identifier, but got ']'", maybe it's `Positioned(..., child: Container(...), ), ]`?
// If it's `Positioned( ..., child: Container(...), , ]` ? (Double comma)
content = content.replace(/,,/g, ',');

fs.writeFileSync(path, content, "utf8");
console.log('Fixed imports and invisible chars');
