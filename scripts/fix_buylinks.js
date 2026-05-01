/**
 * fix_buylinks.js
 * ─────────────────────────────────────────────────────────────────
 * Remplace automatiquement les buyLinks cassés (404/410/5xx)
 * par des liens de recherche Amazon.fr + Fnac.com toujours valides.
 *
 * Stratégie :
 *   1. Conserve les liens existants encore valides (ex: Amazon déjà OK)
 *   2. Pour les produits entièrement cassés → génère des liens de recherche
 *      Amazon.fr + Fnac.com basés sur le nom du produit (toujours valides)
 *   3. Pour certaines marques premium, ajoute un lien direct sur le site officiel
 *
 * USAGE :
 *   node scripts/fix_buylinks.js --dry-run   → simulation, rien n'est écrit
 *   node scripts/fix_buylinks.js             → correction en base
 */

const admin = require('firebase-admin');
const fetch  = require('node-fetch');

const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const DRY_RUN = process.argv.includes('--dry-run');

// ── Générateurs de liens de recherche (toujours fonctionnels) ─────

function amazonSearchUrl(query) {
  return `https://www.amazon.fr/s?k=${encodeURIComponent(query)}`;
}

function fnacSearchUrl(query) {
  return `https://www.fnac.com/SearchResult/ResultList.aspx?Search=${encodeURIComponent(query)}`;
}

function sephora(query) {
  return `https://www.sephora.fr/search/?q=${encodeURIComponent(query)}`;
}

function idealo(query) {
  return `https://www.idealo.fr/prechcat.html?q=${encodeURIComponent(query)}`;
}

// ── Catalogue de liens fixes par marque/produit ───────────────────
// Pour les marques premium dont les produits ne sont pas sur Amazon,
// on utilise les pages catégorie du site officiel (toujours valides).

const BRAND_LINKS = {
  // Zara → page recherche Zara (toujours valide)
  'zara': (name) => [
    `https://www.zara.com/fr/fr/search?searchTerm=${encodeURIComponent(name)}`,
    amazonSearchUrl(`${name} Zara`),
  ],
  // Golden Goose → page collection officielle
  'golden goose': (name) => [
    'https://www.goldengoose.com/fr/fr/',
    `https://www.farfetch.com/fr/shopping/search/?q=${encodeURIComponent(name + ' Golden Goose')}`,
    amazonSearchUrl(`Golden Goose ${name}`),
  ],
  // Jacquemus → Farfetch
  'jacquemus': (name) => [
    `https://www.farfetch.com/fr/shopping/search/?q=${encodeURIComponent(name + ' Jacquemus')}`,
    `https://www.mytheresa.com/fr-fr/search.html?q=${encodeURIComponent('Jacquemus ' + name)}`,
    amazonSearchUrl(`Jacquemus ${name}`),
  ],
  // Lululemon → site FR
  'lululemon': (name) => [
    `https://www.lululemon.fr/fr-fr/c/all-products?q=${encodeURIComponent(name)}`,
    amazonSearchUrl(`Lululemon ${name}`),
  ],
  // Van Cleef → Net-a-Porter
  'van cleef': (name) => [
    `https://www.net-a-porter.com/fr-fr/shop/designer/van-cleef-arpels`,
    `https://www.farfetch.com/fr/shopping/search/?q=${encodeURIComponent(name + ' Van Cleef')}`,
    amazonSearchUrl(`Van Cleef Arpels ${name}`),
  ],
  // Versace → Farfetch
  'versace': (name) => [
    `https://www.farfetch.com/fr/shopping/search/?q=${encodeURIComponent(name + ' Versace')}`,
    `https://www.versace.com/fr/fr/`,
    amazonSearchUrl(`Versace ${name}`),
  ],
  // Taschen → Amazon directement
  'taschen': (name) => [
    amazonSearchUrl(name + ' Taschen livre'),
    fnacSearchUrl(name + ' Taschen'),
  ],
  // Muji → site officiel FR
  'muji': (name) => [
    `https://www.muji.com/fr/search?keyword=${encodeURIComponent(name)}`,
    amazonSearchUrl(`Muji ${name}`),
  ],
  // Assouline → Amazon/Fnac (livres)
  'assouline': (name) => [
    amazonSearchUrl(name + ' Assouline'),
    fnacSearchUrl(name + ' Assouline'),
  ],
  // Veja → site officiel FR
  'veja': (name) => [
    `https://www.veja-store.com/fr/recherche/?q=${encodeURIComponent(name)}`,
    amazonSearchUrl(`Veja ${name}`),
  ],
  // A.P.C. → Farfetch
  'a.p.c.': (name) => [
    `https://www.farfetch.com/fr/shopping/search/?q=${encodeURIComponent(name + ' APC')}`,
    amazonSearchUrl(`APC ${name}`),
  ],
  'a.p.c. x': (name) => [
    `https://www.farfetch.com/fr/shopping/search/?q=${encodeURIComponent(name + ' APC')}`,
    amazonSearchUrl(`APC ${name}`),
  ],
  // Monbento → site officiel
  'monbento': (name) => [
    `https://www.monbento.com/fr/search/?q=${encodeURIComponent(name)}`,
    amazonSearchUrl(`Monbento ${name}`),
  ],
  // Hay → site officiel + Fleux
  'hay': (name) => [
    `https://www.hay.com/fr-fr/search?q=${encodeURIComponent(name)}`,
    `https://www.fleux.com/search?type=product&q=${encodeURIComponent('Hay ' + name)}`,
    amazonSearchUrl(`Hay ${name}`),
  ],
  // Gorjana → bijoux → Amazon/Farfetch
  'gorjana': (name) => [
    `https://gorjana.com/collections/rings`,
    amazonSearchUrl(`Gorjana ${name}`),
    idealo(name),
  ],
  // We Are Knitters → site officiel FR
  'we are knitters': (name) => [
    'https://www.weareknitters.fr/',
    amazonSearchUrl(`We Are Knitters ${name}`),
  ],
  // Relais & Châteaux → site officiel
  'relais': (name) => [
    'https://www.relaischateaux.com/fr/gift-boxes/',
    amazonSearchUrl(`coffret cadeau gastronomie luxe`),
  ],
  'relais & châteaux': (name) => [
    'https://www.relaischateaux.com/fr/gift-boxes/',
    amazonSearchUrl(`coffret cadeau gastronomie luxe`),
  ],
  // Moët & Chandon → Nicolas.fr (bon lien) ou Lavinia
  'moët': (name) => [
    'https://www.lavinia.fr/nos-producteurs/moet-et-chandon/',
    amazonSearchUrl(`Moët Chandon champagne`),
    'https://www.nicolas.com/fr/recherche?query=moet%20chandon',
  ],
  'moët & chandon': (name) => [
    'https://www.lavinia.fr/nos-producteurs/moet-et-chandon/',
    amazonSearchUrl(`Moët Chandon champagne`),
  ],
  // Citadelle Gin → Lavinia / Amazon
  'citadelle': (name) => [
    'https://www.lavinia.fr/rechercher/citadelle/',
    amazonSearchUrl('Citadelle Gin 70cl'),
    'https://www.maison-citadelle.com/',
  ],
  // Terres de Café → site officiel
  'terres de café': (name) => [
    'https://www.terresdecafe.com/fr/cafe',
    amazonSearchUrl('café en grains arabica 1kg'),
  ],
  // Pierre Hermé → site officiel
  'pierre hermé': (name) => [
    'https://www.pierreherme.com/macarons',
    amazonSearchUrl(`Pierre Hermé macarons coffret`),
  ],
  // Petrossian → site officiel
  'petrossian': (name) => [
    'https://www.petrossian.fr/fr_fr/caviar',
    amazonSearchUrl(`Petrossian caviar coffret`),
  ],
  // Dinh Van → Farfetch
  'dinh van': (name) => [
    `https://www.farfetch.com/fr/shopping/search/?q=${encodeURIComponent('Dinh Van ' + name)}`,
    amazonSearchUrl(`Dinh Van ${name}`),
  ],
  // Brun de Vian-Tiran → site officiel
  'brun de vian-tiran': (name) => [
    `https://www.brundeviantiran.com/plaids`,
    amazonSearchUrl(`plaid laine mohair`),
  ],
  // Iwachu / théière japonaise
  'iwachu': (name) => [
    `https://www.palaisdesthes.com/fr/theiere`,
    amazonSearchUrl(`théière fonte japonaise`),
    fnacSearchUrl(`théière fonte japonaise`),
  ],
  // L'Atelier du Vin → Fnac
  "l'atelier du vin": (name) => [
    fnacSearchUrl(`L'Atelier du Vin ${name}`),
    amazonSearchUrl(`coffret sommelier oenologie`),
  ],
  // Default : Amazon search + Fnac search
  'default': (name, brand) => [
    amazonSearchUrl(`${name} ${brand}`.trim()),
    fnacSearchUrl(`${name} ${brand}`.trim()),
  ],
};

// ── Sélection du générateur de liens ─────────────────────────────

function getReplacementLinks(name, brand) {
  const brandLower = (brand || '').toLowerCase();
  const nameLower  = (name  || '').toLowerCase();

  // Chercher correspondance brand
  for (const [key, fn] of Object.entries(BRAND_LINKS)) {
    if (key === 'default') continue;
    if (brandLower.includes(key) || nameLower.includes(key)) {
      return fn(name, brand);
    }
  }

  // Fallback générique
  return BRAND_LINKS.default(name, brand);
}

// ── Main ──────────────────────────────────────────────────────────

async function main() {
  console.log('');
  console.log('╔══════════════════════════════════════════════════════╗');
  console.log('║   🔧 Doron — Fix automatique des buyLinks cassés     ║');
  console.log(`║   Mode : ${DRY_RUN ? '🟡 DRY-RUN (lecture seule)        ' : '🔴 PRODUCTION (écriture Firestore)  '}  ║`);
  console.log('╚══════════════════════════════════════════════════════╝\n');

  // Charger le rapport d'audit
  let report;
  try {
    report = require('./buylinks_audit_report.json');
  } catch (e) {
    console.error('❌ buylinks_audit_report.json introuvable. Lance d\'abord : node scripts/audit_buylinks.js');
    process.exit(1);
  }

  const broken  = report.fullyBrokenProducts  || [];
  const partial = report.partiallyBrokenProducts || [];
  const noLinks = report.noLinksProducts       || [];

  console.log(`📦 Produits à corriger :`);
  console.log(`   🔴 Totalement cassés  : ${broken.length}`);
  console.log(`   🟡 Partiellement      : ${partial.length}`);
  console.log(`   ❌ Sans buyLinks      : ${noLinks.length}`);
  console.log('');

  let fixed = 0, errors = 0;
  const batch = db.batch();
  let batchCount = 0;
  const MAX_BATCH = 490;

  const commitBatch = async () => {
    if (batchCount > 0 && !DRY_RUN) {
      await batch.commit();
      console.log(`   💾 ${batchCount} docs écrits en Firestore`);
    }
  };

  // ── 1. Produits entièrement cassés ─────────────────────────────
  console.log('─'.repeat(60));
  console.log('🔴 CORRECTION DES PRODUITS TOTALEMENT CASSÉS\n');

  for (const product of broken) {
    const { id, name, brand, links: oldLinks } = product;
    const newLinks = getReplacementLinks(name, brand);

    console.log(`  [${fixed + 1}/${broken.length}] "${name.substring(0, 45)}" (${brand})`);
    console.log(`   → ${newLinks[0].substring(0, 75)}`);
    if (newLinks.length > 1) console.log(`   → ${newLinks[1].substring(0, 75)}`);

    if (!DRY_RUN) {
      try {
        batch.update(db.collection('gifts').doc(id), {
          buyLinks: newLinks,
          buyLinksFixed: true,
          buyLinksFixedAt: new Date().toISOString(),
          buyLinksOriginal: oldLinks, // sauvegarde de l'original
        });
        batchCount++;
        fixed++;
        if (batchCount >= MAX_BATCH) await commitBatch();
      } catch (e) {
        errors++;
        console.error(`   ❌ Erreur: ${e.message}`);
      }
    } else {
      fixed++;
    }
  }

  // ── 2. Produits partiellement cassés ───────────────────────────
  console.log('\n' + '─'.repeat(60));
  console.log('🟡 CORRECTION DES PRODUITS PARTIELLEMENT CASSÉS\n');

  for (const product of partial) {
    const { id, name, brand } = product;
    // Garder les liens OK, remplacer les cassés
    const goodLinks = product.links
      .filter(l => !['NOT_FOUND', 'GONE', 'SERVER_ERROR'].includes(l.status))
      .map(l => l.url);
    
    // Ajouter des liens fiables si il en reste peu
    const extraLinks = goodLinks.length < 2 ? getReplacementLinks(name, brand) : [];
    const finalLinks = [...new Set([...goodLinks, ...extraLinks])];

    console.log(`  "${name.substring(0, 45)}" → ${goodLinks.length} lien(s) conservé(s) + ${extraLinks.length} ajouté(s)`);

    if (!DRY_RUN) {
      try {
        batch.update(db.collection('gifts').doc(id), {
          buyLinks: finalLinks,
          buyLinksFixed: true,
          buyLinksFixedAt: new Date().toISOString(),
        });
        batchCount++;
        fixed++;
      } catch (e) {
        errors++;
        console.error(`   ❌ Erreur: ${e.message}`);
      }
    } else {
      fixed++;
    }
  }

  // ── 3. Produits sans buyLinks ───────────────────────────────────
  if (noLinks.length > 0) {
    console.log('\n' + '─'.repeat(60));
    console.log('❌ AJOUT DE LIENS AUX PRODUITS SANS BUYLINKS\n');

    for (const product of noLinks) {
      const { id, name, brand } = product;
      const newLinks = getReplacementLinks(name, brand);
      console.log(`  "${name.substring(0, 45)}" → ${newLinks[0].substring(0, 60)}`);

      if (!DRY_RUN) {
        try {
          batch.update(db.collection('gifts').doc(id), {
            buyLinks: newLinks,
            buyLinksFixed: true,
            buyLinksFixedAt: new Date().toISOString(),
          });
          batchCount++;
          fixed++;
        } catch (e) {
          errors++;
        }
      } else {
        fixed++;
      }
    }
  }

  // Commit final
  await commitBatch();

  // ── Rapport ──────────────────────────────────────────────────────
  console.log('');
  console.log('╔══════════════════════════════════════════════════════╗');
  console.log(`║  ✅ TERMINÉ !${DRY_RUN ? ' (DRY-RUN — aucune écriture)' : ''}`.padEnd(56) + '║');
  console.log('╠══════════════════════════════════════════════════════╣');
  console.log(`║  Produits corrigés    : ${String(fixed).padEnd(30)}║`);
  console.log(`║  Erreurs              : ${String(errors).padEnd(30)}║`);
  console.log('╚══════════════════════════════════════════════════════╝');

  if (DRY_RUN) {
    console.log('\n💡 Tout semble correct. Lance sans --dry-run pour appliquer en base.\n');
  } else {
    console.log('\n🎉 Base mise à jour ! Les liens cassés pointent maintenant vers des recherches valides.\n');
  }

  process.exit(0);
}

main().catch(err => {
  console.error('\n❌ ERREUR CRITIQUE:', err.message || err);
  process.exit(1);
});
