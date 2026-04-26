const fs = require('fs');

// ── Fix 1: /HomePinterest → /home-pinterest (gala_ticket_widget.dart) ───────
{
  const f = 'lib/pages/pages/gala_ticket/gala_ticket_widget.dart';
  if (fs.existsSync(f)) {
    let c = fs.readFileSync(f, 'utf8');
    const before = c.length;
    c = c.replace(/context\.go\('\/HomePinterest'\)/g, "context.go('/home-pinterest')");
    if (c.length !== before || c.includes('/home-pinterest')) {
      fs.writeFileSync(f, c, 'utf8');
      console.log('✅ Fix gala_ticket: /HomePinterest → /home-pinterest');
    }
  }
}

// ── Fix 2: /HomePinterest → /home-pinterest (ticket_success_widget.dart) ───
{
  const f = 'lib/pages/pages/ticket_success/ticket_success_widget.dart';
  if (fs.existsSync(f)) {
    let c = fs.readFileSync(f, 'utf8');
    c = c.replace(/context\.go\('\/HomePinterest'\)/g, "context.go('/home-pinterest')");
    fs.writeFileSync(f, c, 'utf8');
    console.log('✅ Fix ticket_success: /HomePinterest → /home-pinterest');
  }
}

// ── Fix 3: Corriger le Text widget cassé dans voice_results_page_widget ─────
{
  const f = 'lib/pages/voice_assistant/voice_results_page_widget.dart';
  let c = fs.readFileSync(f, 'utf8');
  
  // Remplacer le bloc cassé (avec 'text:' incorrect)
  const badPattern = /child: Text\(\s*text: productPrice == '0' \|\| productPrice\.isEmpty\s*\? 'Prix non renseigné'\s*: '\$\{productPrice\}€',/s;
  const goodReplacement = `child: Text(\n                            productPrice == '0' || productPrice.isEmpty\n                              ? 'Prix non renseigné'\n                              : '\${productPrice}€',`;
  
  if (badPattern.test(c)) {
    c = c.replace(badPattern, goodReplacement);
    fs.writeFileSync(f, c, 'utf8');
    console.log('✅ Fix voice_results: Text widget syntaxe corrigée');
  } else {
    // Essayer de toujours corriger le '${productPrice}€' en string correcte
    if (c.includes("text: productPrice")) {
      c = c.replace(/\s*text: productPrice == '0' \|\| productPrice\.isEmpty[\s\S]*?'Price non renseigné'[\s\S]*?: '.*?€',/,
        "\n                            productPrice == '0' || productPrice.isEmpty ? 'Prix non renseigné' : '\${productPrice}€',");
      fs.writeFileSync(f, c, 'utf8');
      console.log('✅ Fix voice_results: text: → positional arg');
    } else {
      console.log('ℹ️  Fix voice_results: pattern non trouvé (peut-être déjà correct)');
    }
  }
}

// ── Fix 4: Vérifier les imports HapticFeedback dans search_page ─────────────
{
  const f = 'lib/pages/new_pages/search_page/search_page_widget.dart';
  let c = fs.readFileSync(f, 'utf8');
  if (!c.includes('flutter/services.dart') && c.includes('HapticFeedback')) {
    // Ajouter l'import manquant après la première ligne import
    c = c.replace("import 'package:flutter/material.dart';", 
      "import 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';");
    fs.writeFileSync(f, c, 'utf8');
    console.log('✅ Fix search_page: import HapticFeedback ajouté');
  } else {
    console.log('ℹ️  search_page: imports HapticFeedback OK');
  }
}

// ── Fix 5: Vérifier les routes /HomePinterest dans tous les fichiers ─────────
{
  const files = require('child_process')
    .execSync("where /r lib *.dart", { cwd: '.', encoding: 'utf8' })
    .split('\n').map(l => l.trim()).filter(l => l.endsWith('.dart'));
  
  let count = 0;
  for (const f of files) {
    if (!fs.existsSync(f)) continue;
    let c = fs.readFileSync(f, 'utf8');
    if (c.includes("'/HomePinterest'")) {
      c = c.replace(/'\/HomePinterest'/g, "'/home-pinterest'");
      fs.writeFileSync(f, c, 'utf8');
      console.log(`✅ Fixed /HomePinterest in ${f.split('\\').pop()}`);
      count++;
    }
  }
  if (count === 0) console.log('ℹ️  /HomePinterest: aucun autre fichier à corriger');
}

console.log('\n✅ Tous les patches de routes appliqués.');
