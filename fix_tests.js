const fs = require('fs');

// Fix 1: Corriger les appels _topN avec argument manquant dans matching_engine_test.dart
{
  const f = 'test/matching/matching_engine_test.dart';
  let c = fs.readFileSync(f, 'utf8');
  
  // Remplacer _topN(tags, {}) par _topN(tags, {}, 5) (là où n n'est pas spécifié)  
  // La fonction _topN requiert 3 args positionnels: tags, profile, n
  c = c.replace(/final top5 = _topN\(tags, \{\}\);/g, 'final top5 = _topN(tags, {}, 5);');
  
  fs.writeFileSync(f, c, 'utf8');
  console.log('✅ Fix test: _topN calls with missing n=5 added');
}

// Fix 2: Ajouter 'test' dans dev_dependencies de pubspec.yaml
{
  const f = 'pubspec.yaml';
  let c = fs.readFileSync(f, 'utf8');
  if (!c.includes("\n  test:") && !c.includes("  test: ")) {
    // Ajouter après flutter_test
    c = c.replace(
      '  flutter_test:\n    sdk: flutter',
      '  flutter_test:\n    sdk: flutter\n  test: any'
    );
    fs.writeFileSync(f, c, 'utf8');
    console.log('✅ Fix pubspec: test package added to dev_dependencies');
  } else {
    console.log('ℹ️  pubspec: test already in dev_dependencies');
  }
}

console.log('\n✅ Tous les fixes de tests appliqués.');
