const fs = require('fs');
const path = 'lib/pages/wishlists/wishlists_page_widget.dart';
let content = fs.readFileSync(path, 'utf8');

// 1. Wrap BounceCard content with ClipRRect and BackdropFilter
// Actually, BounceCard might be a custom widget. Let's find its implementation. 
// If we add BackdropFilter inside BounceCard decoration, it might look better.
// Let's replace the whole _buildWishlistCard decoration with glassmorphism.

const oldDecoration = `        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradientColors[0].withOpacity(0.1),
              gradientColors[1].withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: gradientColors[0].withOpacity(0.2),
            width: 1,
          ),
        ),`;

const newDecoration = `        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.14),
              Colors.white.withOpacity(0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),`;

if (content.includes(oldDecoration)) {
  content = content.replace(oldDecoration, newDecoration);
  // Also add BackdropFilter to its child if possible
  const oldChild = `        child: Row(`;
  const newChild = `        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: dart_ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(`;
            
  if (content.includes(oldChild)) {
    content = content.replace(oldChild, newChild);
    // Add import dart:ui
    if (!content.includes("import 'dart:ui' as dart_ui;")) {
      content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'dart:ui' as dart_ui;");
    }
    
    // Close the widgets at the end of the return Padding
    const oldClose = `              ],
            ),
          ],
        ),
      ),
    );
  }`;
  
    const newClose = `              ],
            ),
          ],
        ),
        ),
        ),
      ),
    );
  }`;
    if (content.includes(oldClose)) {
      content = content.replace(oldClose, newClose);
    }
  }
}

fs.writeFileSync(path, content, 'utf8');
console.log('Replaced albums successfully!');
