const fs = require('fs');
let c = fs.readFileSync('doron_enricher.js', 'utf8');

c = c.replace(
  "'claude-3-5-sonnet-20241022',  // Sonnet 3.5 - web_search supporté, bon équilibre vitesse/qualité",
  "'claude-opus-4-5',  // seul modèle accessible sur cette clé, avec web_search"
);

// Forcer concurrency=1 par défaut (séquentiel) pour éviter rate limits + 404
c = c.replace(
  'const CONCURRENCY = CONCURRENCY_ARG ? parseInt(CONCURRENCY_ARG.split(\'=\')[1]) : 2;',
  'const CONCURRENCY = CONCURRENCY_ARG ? parseInt(CONCURRENCY_ARG.split(\'=\')[1]) : 1;'
);

// Réduire pause à 500ms (claude-opus avec 3 web searches = ~20s par produit)
c = c.replace('const PAUSE_MS = 1000;', 'const PAUSE_MS = 500;');

fs.writeFileSync('doron_enricher.js', c, 'utf8');
console.log('✅ Model: claude-opus-4-5 | Concurrency: 1 | Pause: 500ms');
