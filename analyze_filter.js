const { execSync } = require('child_process');
const fs = require('fs');

// Relire le resultat sauvegardé ou en générer un
let output = '';
try {
  output = execSync(
    '"C:\\Users\\marcg\\Desktop\\DORON\\code\\flutter_sdk\\flutter\\bin\\flutter.bat" analyze --no-fatal-infos 2>&1',
    { cwd: process.cwd(), maxBuffer: 50 * 1024 * 1024, timeout: 300000 }
  ).toString();
} catch (e) {
  output = e.stdout ? e.stdout.toString() : e.stderr ? e.stderr.toString() : '';
}

const lines = output.split('\n');

// Séparer les erreurs lib/ des erreurs test/
const libErrors   = lines.filter(l => l.includes('lib\\') && (l.includes('error -') || l.includes('warning -')));
const testErrors  = lines.filter(l => l.includes('test\\') && l.includes('error -'));
const libWarnings = lines.filter(l => l.includes('lib\\') && l.includes('info -'));

console.log(`\n📊 RÉSUMÉ flutter analyze:`);
console.log(`   🔴 Erreurs dans lib/   : ${libErrors.length}`);
console.log(`   🟡 Warnings dans lib/  : ${libWarnings.length}`);
console.log(`   🧪 Erreurs dans test/  : ${testErrors.length} (ignorées — manque import flutter_test)\n`);

console.log(`\n🔴 ERREURS lib/ (à corriger) :`);
libErrors.slice(0, 60).forEach(l => console.log(l.trim()));

console.log(`\n🟡 WARNINGS lib/ (premiers 30) :`);
libWarnings.slice(0, 30).forEach(l => console.log(l.trim()));

// Sauvegarder le rapport complet
fs.writeFileSync('analyze_report.txt', output, 'utf8');
console.log('\n✅ Rapport complet sauvegardé dans analyze_report.txt');
