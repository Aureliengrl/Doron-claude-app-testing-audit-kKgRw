const fs = require('fs');
let c = fs.readFileSync('lib/components/product_detail_modal.dart', 'utf8');

// Find the buy button block start and end
const startMarker = '                        const SizedBox(height: 20),\r\n                        // Bouton Voir sur...';
const endMarker = "                        ),\r\n                      ],\r\n                    ),\r\n                  ),\r\n                ],\r\n              ),\r\n            ),\r\n          );\r\n        },\r\n      ),\r\n    );\r\n  }";

const startIdx = c.indexOf(startMarker);
const endIdx = c.indexOf(endMarker);

console.log('startMarker found:', startIdx !== -1, 'at', startIdx);
console.log('end found:', endIdx !== -1, 'at', endIdx);

if (startIdx === -1) {
  // Try to find it differently
  const i = c.indexOf('// Bouton Voir sur');
  console.log('// Bouton Voir sur found at:', i);
  console.log(JSON.stringify(c.substring(i-50, i+20)));
}
