const fs = require('fs');
const output = fs.readFileSync('analyze_report.txt', 'utf8');
const lines = output.split('\n');

const libErrors = lines.filter(l => {
  const trim = l.trim();
  return trim.startsWith('error -') && !l.includes('test\\') && !l.includes('test/');
});

const libWarnings = lines.filter(l => {
  const trim = l.trim();
  return trim.startsWith('warning -') && !l.includes('test\\') && !l.includes('test/');
});

console.log(`\n🔴 ERREURS lib/ (${libErrors.length}):\n`);
libErrors.forEach(l => console.log('  ' + l.trim()));

console.log(`\n🟠 WARNINGS lib/ (${libWarnings.length}):\n`);
libWarnings.slice(0, 40).forEach(l => console.log('  ' + l.trim()));
