const fs = require('fs');

const path = "lib/pages/new_pages/search_page/search_page_widget.dart";
let lines = fs.readFileSync(path, "utf8").split('\n');

// Find start
let startIdx = lines.findIndex(l => l.includes('for (int i = 0; i < products.length; i++)'));
let endIdx = lines.findIndex((l, i) => i > startIdx && l.includes('void _showProductDetail(Map<String, dynamic> product)'));

if (startIdx !== -1 && endIdx !== -1) {
  lines.splice(startIdx + 1, endIdx - startIdx - 1,
    "              SharedProductCard(product: products[i], index: i),",
    "          ],",
    "        ),",
    "      ),",
    "    );",
    "  }",
    ""
  );
  fs.writeFileSync(path, lines.join('\n'));
  console.log("Replaced successfully!");
} else {
  console.log("Could not find boundaries.");
}
