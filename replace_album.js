const fs = require('fs');

const path = "lib/pages/wishlists/wishlist_details_widget.dart";
let lines = fs.readFileSync(path, "utf8").split('\n');

// 1. Add import if not present
let content = lines.join('\n');
if (!content.includes("import '/components/shared_product_card.dart';")) {
  content = content.replace("import '/components/product_detail_modal.dart';", "import '/components/product_detail_modal.dart';\nimport '/components/shared_product_card.dart';");
}

// 2. Replace _WishlistProductCard usage
content = content.replace(/_WishlistProductCard\(/g, "SharedProductCard(");

// 3. Delete _WishlistProductCard class
const classIndex = content.indexOf('class _WishlistProductCard extends StatelessWidget');
if (classIndex !== -1) {
  content = content.substring(0, classIndex);
}

// 4. Update childAspectRatio to 0.70
content = content.replace(/childAspectRatio: 0\.60,/g, 'childAspectRatio: 0.70,');

fs.writeFileSync(path, content, "utf8");
console.log("Replaced successfully!");
