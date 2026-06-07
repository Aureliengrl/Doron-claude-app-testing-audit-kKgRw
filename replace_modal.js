const fs = require('fs');
const path = 'lib/components/product_detail_modal.dart';
let content = fs.readFileSync(path, 'utf8');

// 1. Add import 'dart:ui';
if (!content.includes("import 'dart:ui';")) {
  content = content.replace("import 'package:flutter/material.dart';", "import 'dart:ui';\nimport 'package:flutter/material.dart';");
}

// 2. Wrap Container in ClipRRect and BackdropFilter
const oldDialog = `          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.10),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 60,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),`;

const newDialog = `          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Colors.white.withOpacity(0.14), Colors.white.withOpacity(0.06)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 40,
                        offset: Offset(0, 20),
                      ),
                    ],
                  ),`;

content = content.replace(oldDialog, newDialog);

// 3. Close the new wrappers
const oldClose = `                ],
              ),
            ),
          );
        },`;

const newClose = `                ],
              ),
            ),
            ),
            ),
          );
        },`;

content = content.replace(oldClose, newClose);

fs.writeFileSync(path, content, 'utf8');
console.log('Replaced successfully!');
