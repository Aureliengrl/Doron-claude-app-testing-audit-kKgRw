#!/usr/bin/env node
/**
 * auto_clean_imports.js
 * Supprime automatiquement les imports inutilisés signalés par flutter analyze.
 * Usage: node auto_clean_imports.js
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const FLUTTER = 'C:\\Users\\marcg\\Desktop\\DORON\\code\\flutter_sdk\\flutter\\bin\\flutter.bat';

console.log('🔍 Lancement de flutter analyze...');
let analyzeOutput = '';
try {
  analyzeOutput = execSync(`"${FLUTTER}" analyze --no-fatal-infos 2>&1`, {
    maxBuffer: 50 * 1024 * 1024,
    timeout: 300000,
    cwd: process.cwd(),
  }).toString();
} catch (e) {
  analyzeOutput = (e.stdout || '').toString() + (e.stderr || '').toString();
}

// Parser les warnings unused_import
// Format: "  warning - Unused import: 'xxx' - lib\path\file.dart:7:8 - unused_import"
const unusedImportRegex = /warning - Unused import: '([^']+)' - (lib[^\s:]+\.dart):(\d+):\d+ - unused_import/g;

const toRemove = {}; // { filePath: Set<lineNumber> }

let match;
while ((match = unusedImportRegex.exec(analyzeOutput)) !== null) {
  const [, importPath, filePath, lineStr] = match;
  const lineNum = parseInt(lineStr, 10);
  const absPath = path.resolve(process.cwd(), filePath);

  if (!toRemove[absPath]) toRemove[absPath] = new Set();
  toRemove[absPath].add(lineNum);
}

const files = Object.keys(toRemove);

if (files.length === 0) {
  console.log('✅ Aucun import inutilisé trouvé !');
  process.exit(0);
}

console.log(`\n📦 ${files.length} fichiers avec des imports inutilisés à nettoyer...\n`);

let totalRemoved = 0;
const report = [];

for (const absPath of files) {
  const lines = toRemove[absPath];
  if (!fs.existsSync(absPath)) {
    console.log(`  ⚠️  Fichier introuvable: ${absPath}`);
    continue;
  }

  const content = fs.readFileSync(absPath, 'utf8');
  const fileLines = content.split('\n');
  const removedLines = [];

  // Construire le nouveau contenu en sautant les lignes à supprimer (1-indexed)
  const newLines = fileLines.filter((line, idx) => {
    const lineNum = idx + 1;
    if (lines.has(lineNum)) {
      // Vérification de sécurité : s'assurer que c'est bien un import
      const trimmed = line.trim();
      if (trimmed.startsWith('import ') && trimmed.endsWith(';')) {
        removedLines.push({ lineNum, content: trimmed });
        return false; // supprimer
      }
      // Sinon on garde (sécurité)
      console.log(`  ⚠️  L${lineNum} n'est pas un import, ignoré: ${trimmed.substring(0, 60)}`);
      return true;
    }
    return true;
  });

  if (removedLines.length > 0) {
    fs.writeFileSync(absPath, newLines.join('\n'), 'utf8');
    const relPath = path.relative(process.cwd(), absPath);
    console.log(`  ✅ ${relPath} — ${removedLines.length} import(s) supprimé(s)`);
    removedLines.forEach(({ lineNum, content }) => {
      console.log(`     L${lineNum}: ${content.substring(0, 80)}`);
    });
    totalRemoved += removedLines.length;
    report.push({ file: relPath, removed: removedLines });
  }
}

console.log(`\n🎉 Terminé ! ${totalRemoved} imports inutilisés supprimés dans ${files.length} fichiers.`);

// Vérification post-nettoyage
console.log('\n🔍 Re-analyse pour vérifier...');
let verify = '';
try {
  verify = execSync(`"${FLUTTER}" analyze --no-fatal-infos 2>&1`, {
    maxBuffer: 50 * 1024 * 1024,
    timeout: 300000,
    cwd: process.cwd(),
  }).toString();
} catch (e) {
  verify = (e.stdout || '').toString() + (e.stderr || '').toString();
}

const remainingWarnings = (verify.match(/unused_import/g) || []).length;
const remainingErrors = (verify.match(/\nerror - /g) || []).filter(
  l => !l.includes('test\\') && !l.includes('scripts\\')
).length;

const totalLine = verify.split('\n').find(l => /^\d+ issues found/.test(l.trim()));
console.log(`\n📊 Résultat final: ${totalLine || 'N/A'}`);
console.log(`   🟠 Unused imports restants : ${remainingWarnings}`);
console.log(`   🔴 Erreurs lib restantes   : ${remainingErrors}`);
