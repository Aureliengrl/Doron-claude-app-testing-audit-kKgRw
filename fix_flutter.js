const fs = require('fs');

const path = "lib/pages/new_pages/search_page/search_page_widget.dart";
let content = fs.readFileSync(path, "utf8");
let lines = content.split('\n');

// Fix 1: arrowDown2
lines = lines.map(line => line.replace('IconlyLight.arrowDown2', 'IconlyLight.arrowDown'));

// For line 254: "Expected an identifier, but got ']'"
// Let's print out lines 250 to 260
console.log("Lines 250-260:");
for(let i=249; i<=259; i++) {
    console.log(i+1 + ": " + lines[i]);
}

// Same for line 714
console.log("\nLines 710-720:");
for(let i=709; i<=719; i++) {
    console.log(i+1 + ": " + lines[i]);
}

// Let's fix missing commas before `]`?
// If line 254 is `],`, why does it expect an identifier?
// Because Dart arrays can have trailing commas. But what if it's `,,]`? Or `[ ]` but there's an extra comma?
// Ah! If it's a map `{ }` or if it's named arguments in a function call!
// `children: [ ... ],` -> if there's no comma after the previous element? That's fine.
// What if it's `Container(...)` without `child:`?
// `lib/pages/new_pages/search_page/search_page_widget.dart:714:23: Error: Too many positional arguments`
// Line 714: `      child: Container(`
// wait, maybe the `Container` is `Container( ... )` instead of `Container(child: ...)`? No, `Container()` has NO positional arguments. It takes named arguments: `Container({Key? key, AlignmentGeometry? alignment, EdgeInsetsGeometry? padding, Color? color, Decoration? decoration, Decoration? foregroundDecoration, double? width, double? height, BoxConstraints? constraints, EdgeInsetsGeometry? margin, Matrix4? transform, AlignmentGeometry? transformAlignment, Widget? child, Clip clipBehavior})`

fs.writeFileSync('temp_debug.txt', lines.join('\n'));
