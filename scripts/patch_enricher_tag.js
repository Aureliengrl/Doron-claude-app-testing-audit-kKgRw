const fs = require('fs');
let c = fs.readFileSync('doron_enricher.js', 'utf8');

// 1. Ajouter la constante du tag affilié Amazon après les imports
const afterDotenv = `require('dotenv').config();\n`;
const withTag = `require('dotenv').config();\n\n// ─── Affiliate Tags ──────────────────────────────────────────────────────────\nconst AMAZON_TAG = process.env.AMAZON_ASSOCIATE_TAG || 'doron072004-21';\n`;
c = c.replace(afterDotenv, withTag);

// 2. Fonction pour ajouter le tag Amazon sur les liens trouvés par Claude
const helperInsert = `const sleep = ms => new Promise(r => setTimeout(r, ms));\n`;
const helperWithAffiliate = `const sleep = ms => new Promise(r => setTimeout(r, ms));\n\nfunction applyAmazonTag(url) {\n  if (!url) return url;\n  try {\n    const u = new URL(url);\n    if (!u.hostname.includes('amazon.')) return url;\n    u.searchParams.delete('tag');\n    u.searchParams.set('tag', AMAZON_TAG);\n    return u.toString();\n  } catch { return url; }\n}\n`;
c = c.replace(helperInsert, helperWithAffiliate);

// 3. Dans processProduct, après claudeResult.buyLinks, appliquer le tag aux liens Amazon
const buyLinksMap = `allLinks.push({\n          site:       l.site || getSiteName(l.url),\n          url:        l.url,\n          price:      l.price || null,\n          affiliated: false,\n          priority:   1,\n          source:     'claude',\n        });`;
const buyLinksMapWithTag = `const finalUrl = applyAmazonTag(l.url);\n        const isAffiliated = finalUrl.includes('tag=' + AMAZON_TAG);\n        allLinks.push({\n          site:       l.site || getSiteName(l.url),\n          url:        finalUrl,\n          price:      l.price || null,\n          affiliated: isAffiliated,\n          affiliateTag: isAffiliated ? AMAZON_TAG : undefined,\n          priority:   1,\n          source:     'claude',\n        });`;
c = c.replace(buyLinksMap, buyLinksMapWithTag);

fs.writeFileSync('doron_enricher.js', c, 'utf8');
console.log('✅ Tag affilié Amazon ajouté dans doron_enricher.js');
console.log('   AMAZON_TAG:', c.includes("'doron072004-21'") ? 'doron072004-21 ✓' : 'ERREUR');
console.log('   applyAmazonTag:', c.includes('applyAmazonTag') ? 'présente ✓' : 'ERREUR');
