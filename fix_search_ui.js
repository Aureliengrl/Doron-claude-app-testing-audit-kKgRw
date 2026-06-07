const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'lib', 'pages', 'new_pages', 'search_page', 'search_page_widget.dart');
let content = fs.readFileSync(filePath, 'utf8');

// Fix 1: IconlyLight.arrowDown2 -> IconlyLight.arrowDown
content = content.replace(/IconlyLight\.arrowDown2/g, 'IconlyLight.arrowDown');

// Fix 2: trailing bracket errors
// "], \n )" issues or extra commas
// Lines 254, 881, 1756, 1780: 'Expected an identifier, but got ']''
// This usually means there's a trailing comma before a closing bracket without an element, OR `[ , ]`, or a method that takes named params was missing a name, e.g. `Container(` inside `children: [` but there's a typo.
// Let's replace `CustomScrollView(` with `child: CustomScrollView(` where it's missing.
content = content.replace(/children: \[\s*\/\/[^\n]*\n\s*CustomScrollView\(/g, 'children: [\n            // Contenu principal scrollable avec physics premium\n            CustomScrollView(');
// Wait, the error was inside RefreshIndicator -> Stack -> children. Stack children takes a list. CustomScrollView is valid.
// What about `child: Container(` inside slivers?
// SilverToBoxAdapter(child: Container(...)) is valid.
// Let's replace `,\n          ],` where it fails? Let's just fix the `1836` error first.
// 1836: `final confirmed = await showDialog<bool>(`
// It says "Can't find ')' to match '('."

fs.writeFileSync(filePath, content, 'utf8');
console.log('Fixed arrowDown2');
