const fs = require('fs');
const path = require('path');

// Check 1: files using Iconly but missing the import
console.log('\n=== Files with Iconly but missing import ===');
let orphans = 0;
function checkDir(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) { checkDir(full); continue; }
    if (!entry.name.endsWith('.dart')) continue;
    const c = fs.readFileSync(full, 'utf8');
    const hasIconly = /IconlyLight\.|IconlyBold\./.test(c);
    const hasImport = c.includes("import 'package:flutter_iconly/flutter_iconly.dart'");
    if (hasIconly && !hasImport) {
      console.log('❌ MISSING IMPORT:', entry.name);
      orphans++;
    }
  }
}
checkDir('lib');
if (orphans === 0) console.log('✅ All good - no orphan files');

// Check 2: unlock icon (doesn't exist in Iconly)
console.log('\n=== Files using IconlyLight.unlock (invalid) ===');
let unlocks = 0;
function checkUnlock(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) { checkUnlock(full); continue; }
    if (!entry.name.endsWith('.dart')) continue;
    const c = fs.readFileSync(full, 'utf8');
    if (c.includes('IconlyLight.unlock') || c.includes('IconlyBold.unlock')) {
      console.log('⚠️ unlock in:', entry.name);
      // Fix it
      const fixed = c.replace(/Iconly(Light|Bold)\.unlock/g, 'IconlyLight.lock');
      fs.writeFileSync(full, fixed, 'utf8');
      console.log('  → fixed to IconlyLight.lock');
      unlocks++;
    }
  }
}
checkUnlock('lib');
if (unlocks === 0) console.log('✅ No invalid unlock references');

// Summary of remaining Material icons
console.log('\n=== Remaining Material Icons (not replaced, intentional) ===');
const remaining = {};
function countRemaining(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) { countRemaining(full); continue; }
    if (!entry.name.endsWith('.dart')) continue;
    const c = fs.readFileSync(full, 'utf8');
    const matches = c.match(/Icons\.[a-zA-Z_]+/g) || [];
    for (const m of matches) {
      remaining[m] = (remaining[m] || 0) + 1;
    }
  }
}
countRemaining('lib');
const sorted = Object.entries(remaining).sort((a,b) => b[1]-a[1]);
for (const [k,v] of sorted) console.log(`  ${v}x  ${k}`);
