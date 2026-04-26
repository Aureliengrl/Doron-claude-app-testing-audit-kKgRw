const fs = require('fs');
let c = fs.readFileSync('lib/components/product_detail_modal.dart', 'utf8');

// Find the buy button and replace the whole section
const buyBtnStart = c.indexOf('// Bouton Voir sur...');
if (buyBtnStart === -1) { console.log('NOT FOUND'); process.exit(1); }

// Find the end: closing of the SizedBox that contains the ElevatedButton for buy
// It ends at the closing of the Column children section
// We look for: the end of the ElevatedButton, then close SizedBox
// Strategy: find next occurrence of the section end markers
// The section is: const SizedBox(height:20), // Bouton Voir sur... SizedBox( ... ), ],  ),  ],
// End is just before the closing ],  ),  ],  that ends the Column from Padding

// Find 4 lines back from buyBtnStart to get the SizedBox(height:20)
const sizedBoxHeight20 = c.lastIndexOf('const SizedBox(height: 20),', buyBtnStart);
const sectionStart = sizedBoxHeight20;

// Find section end: after the ElevatedButton closes, there's ],  ),  ],  ),  ],
// The buy button is followed by ],  (closes children of Column)  ),  (closes Column)  ],  (closes children of Stack or outer Column)
// We need to find where the section ends - it's after the last '),' of the ElevatedButton
// Let's find the text just after the buy button section

const afterBuyPattern = '\r\n                      ],\r\n                    ),\r\n                  ),\r\n                ],\r\n              ),\r\n            ),\r\n          );\r\n        },\r\n      ),\r\n    );\r\n  }';

const afterBuyIdx = c.indexOf(afterBuyPattern, buyBtnStart);
console.log('sectionStart (SizedBox h20):', sectionStart);
console.log('afterBuyPattern found:', afterBuyIdx !== -1, 'at:', afterBuyIdx);

if (sectionStart === -1 || afterBuyIdx === -1) {
  console.log('Could not find markers');
  // Print context around buy button
  console.log(JSON.stringify(c.substring(buyBtnStart-100, buyBtnStart+50)));
  process.exit(1);
}

// Build the replacement
const newSection = `const SizedBox(height: 20),
                        // ── Comparateur de prix / Liens d'achat ──────────
                        _buildBuyLinksSection(context, product),`;

const before = c.substring(0, sectionStart);
const after = c.substring(afterBuyIdx);

c = before + newSection + after;

fs.writeFileSync('lib/components/product_detail_modal.dart', c, 'utf8');
console.log('✅ Buy section replaced. File length:', c.length);
console.log('Contains _buildBuyLinksSection:', c.includes('_buildBuyLinksSection'));
