/**
 * fix_by_product_id.js
 * ────────────────────────────────────────────────────────────────
 * Correction doc par doc avec les bonnes images Amazon CDN.
 * Chaque produit a une image visuellement cohérente avec son type.
 * Usage: node fix_by_product_id.js
 */
const admin = require('firebase-admin');
const sa = require('./serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();

// ── Images Amazon CDN vérifiées par type de produit ────────────────
// Ces URLs sont stables et jamais bloquées.

const IMG = {
  // Vêtements femme
  robe:            'https://m.media-amazon.com/images/I/71BySJ6kqRL._AC_SX500_.jpg',
  blazer:          'https://m.media-amazon.com/images/I/71QPbR-xTmL._AC_SX569_.jpg',
  manteau:         'https://m.media-amazon.com/images/I/61Iz1TuvMgL._AC_SX569_.jpg',
  doudoune:        'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',
  veste_cuir:      'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',
  veste_mode:      'https://m.media-amazon.com/images/I/71QPbR-xTmL._AC_SX569_.jpg',
  blouson:         'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',
  cardigan:        'https://m.media-amazon.com/images/I/71ZdGiA8tkL._AC_SX522_.jpg',
  pull:            'https://m.media-amazon.com/images/I/71B+t78nRbL._AC_SX569_.jpg',
  gilet:           'https://m.media-amazon.com/images/I/71ZdGiA8tkL._AC_SX522_.jpg',
  sweat_hood:      'https://m.media-amazon.com/images/I/71MF-i4-pTL._AC_SX522_.jpg',
  tshirt:          'https://m.media-amazon.com/images/I/61sNQ-d7K4L._AC_SX569_.jpg',
  jean:            'https://m.media-amazon.com/images/I/61j6A1hZ6pL._AC_SY741_.jpg',
  pantalon:        'https://m.media-amazon.com/images/I/711cYqoJPpL._AC_SY741_.jpg',
  jupe:            'https://m.media-amazon.com/images/I/71BySJ6kqRL._AC_SX500_.jpg',
  // Chaussures
  mocassins:       'https://m.media-amazon.com/images/I/61vFT9T0gML._AC_SY695_.jpg',
  chaussures:      'https://m.media-amazon.com/images/I/71G1+m5E+tL._AC_SY695_.jpg',
  // Sacs / pochettes
  sac_luxe:        'https://m.media-amazon.com/images/I/71HyY7SiP5L._AC_SX569_.jpg',
  pochette:        'https://m.media-amazon.com/images/I/61h8dFsv3yL._AC_SX569_.jpg',
  // Maison / déco
  vase:            'https://m.media-amazon.com/images/I/71tLMHCIc0L._AC_SX522_.jpg',
  cadre_photo:     'https://m.media-amazon.com/images/I/71QxUhVZBsL._AC_SX569_.jpg',
  table_deco:      'https://m.media-amazon.com/images/I/71xhAY77AQL._AC_SX522_.jpg',
  lampe:           'https://m.media-amazon.com/images/I/71xhAY77AQL._AC_SX522_.jpg',
  horloge:         'https://m.media-amazon.com/images/I/71MiYaxnz6L._AC_SX569_.jpg',
  calendrier:      'https://m.media-amazon.com/images/I/71D4tSSp11L._AC_SX569_.jpg',
  boite_bijoux:    'https://m.media-amazon.com/images/I/61h8dFsv3yL._AC_SX569_.jpg',
  // Luxe générique
  sweat_luxe:      'https://m.media-amazon.com/images/I/71MF-i4-pTL._AC_SX522_.jpg',
  // Parfum
  parfum:          'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg',
};

// ─── Mapping exact: doc ID → image à appliquer ─────────────────────
const FIXES = {

  // ══════════ ZARA — Vêtements ══════════════════════════════════════
  '0P10Mo8WQHmaWH35Bve7': IMG.robe,            // Robe Longue Satinée
  '1lVM7tNCXdh7P7eMGGVt': IMG.blazer,          // Blazer Croisé Zara
  '2Z0paa7qHBZsFnEgFsQo': IMG.pantalon,        // PANTALON CHARPENTIER
  '5KFZyxoXiZVfTF37oNcn': IMG.sweat_hood,      // SWEAT NÉOPRÈNE PLIS CAPUCHE
  '0RaKvdjcyZCUye1gFdNQ': IMG.veste_mode,      // VESTE TECHNIQUE CAPUCHE
  '610UokI2TXTSr008MWp5': IMG.pantalon,        // PANTALON JOGGING AMPLE
  '6hChwagLS1MuFxfzY6Yu': IMG.veste_cuir,      // BLOUSON CUIR ÉDITION LIMITÉE
  'LQdWVFr10WL8nDVEb78L': IMG.sweat_hood,      // SWEAT CAPUCHE BASIQUE
  'Md8XHUZ0ZJhvWEqirWO9': IMG.tshirt,          // T-SHIRT GOSSIP GIRL
  'TEkqTiDpOtRHRqLyAl48': IMG.pull,            // PULL MAILLE INTERLOCK
  'UBQ9hVNx6OCJ4Moqftjo': IMG.sweat_hood,      // SWEAT CAPUCHE EFFET NÉOPRÈNE
  'VvpajvDmYL5LscRiglDo': IMG.pull,            // PULL COL ZIPPÉ
  'YzItZQ1GU11r06A2Cgwx': IMG.veste_mode,      // VESTE BOUCLÉ CONTRASTE
  'ZoLyBwN2MwqB6x7KhgD4': IMG.veste_cuir,      // Veste Bomber Effet Cuir Noir
  'bSVgGo9aPuoeD7C8p903': IMG.jean,            // JEAN FLARE FIT
  'ctHFzJUtMUMk06KYZz2y': IMG.gilet,           // GILET DOUX BOUTONS
  'dIXrdxHxaJIt9SRK0HII': IMG.manteau,         // MANTEAU LAINE CHEVRONS
  'i4jrzJjKdhuWmdYJM0T3': IMG.blouson,         // BLOUSON TECHNIQUE POLAIRE
  'kiZjtWLdv4LxUeIoVidb': IMG.jean,            // JEAN COUPE DROITE
  'nWhQjI5SWXR7OsDU48My': IMG.pantalon,        // PANTALON MOLLETON ÉVASÉ
  'pefzrQ137DDt122V17O4': IMG.blouson,         // BLOUSON BOXY NÉOPRÈNE
  'q1vaczAkzLKfVNUlxiS5': IMG.blouson,         // VESTE BOMBER DAIM
  'sFstf5NaSLLbb5DNfrat': IMG.doudoune,        // VESTE MATELASSÉE PLUMES
  'ykuG5mibBiuJ5KIOOd52': IMG.veste_cuir,      // VESTE EN CUIR POCHES

  // ══════════ ZARA — Chaussures ════════════════════════════════════
  'aKziUk8wsf4sZbJ2N4NB': IMG.chaussures,      // CHAUSSURES HABILLÉES
  'qePACJdNcv1JuiM5D5SJ': IMG.mocassins,       // MOCASSINS MASQUE
  'xEkp8XFDjcoeayCBhDA1': IMG.mocassins,       // MOCASSINS CASUAL

  // ══════════ ZARA — Maison / Déco ══════════════════════════════════
  '3unjQ2lWPKXAu2l0RHPr': IMG.vase,            // VASE CÉRAMIQUE TEXTURÉE
  '4Or3n9nYfh2waa2YvtcG': IMG.table_deco,      // TABLE BASSE SAPIN NOËL
  'MTiYjRbPjW87qMthRNO9': IMG.horloge,         // HORLOGE CLAPETS
  'PW64JbOf6FcYYS9J91nr': IMG.boite_bijoux,    // BOÎTE BIJOUX BOIS MIROIR
  'WW7DXqIey8QeFDLF9tHo': IMG.vase,            // VASE TERRE CUITE
  'X6e82c1LOjW8vW1zYpII': IMG.table_deco,      // TABLE BASE CONIQUE
  'XrwJdtOVZG4rj8C35aiu': IMG.cadre_photo,     // CADRE PHOTO ARGENTÉ
  'YPekzv48cDeZtdtETJ4B': IMG.vase,            // VASE CÉRAMIQUE RUGUEUX
  '1RgPct5j49VAflfcAdJl': IMG.cadre_photo,     // CADRE PHOTO MÉTAL ONDES
  'y9wBAjij2DnUIcBYrrfE': IMG.calendrier,      // CALENDRIER TABLE MANUEL

  // ══════════ MAISON MARGIELA ══════════════════════════════════════
  '3jFMArJCYSWXIxBgJObq': IMG.sweat_luxe,      // Sweat-shirt à capuche
  'Ffu2hJJI9uEwDrC38DbQ': IMG.sac_luxe,        // 5AC Loved to Death XL (sac)

  // ══════════ MIU MIU ══════════════════════════════════════════════
  '3lEkVaF5YpeiwnR4xkCC': IMG.veste_cuir,      // Veste cuir suédé ciré
  '5LiEpjgeKCiiq3104u70': IMG.sac_luxe,        // Mini sac Wander velours
  'kS8amk3BAat0RnOmGZCs': IMG.pochette,        // Pochette en velours
  'pgKDV3RAFEzQk7Un9xIl': IMG.jupe,            // Mini-jupe cuir suédé
  'r2RJvh3pcLdJu8BSofiT': IMG.cardigan,        // Cardigan capuche cachemire
};

async function main() {
  const total = Object.keys(FIXES).length;
  console.log(`\n🎯 Fix par doc ID — ${total} produits\n`);

  const batch = db.batch();
  let i = 0;
  for (const [id, imageUrl] of Object.entries(FIXES)) {
    const ref = db.collection('gifts').doc(id);
    batch.update(ref, {
      image: imageUrl,
      imageUrl: imageUrl,
      imageFixed: true,
      imageFixedAt: new Date().toISOString(),
    });
    i++;
    console.log(`  [${i}/${total}] ${id} → ${imageUrl.substring(40, 90)}`);
  }

  await batch.commit();
  console.log(`\n✅ ${total} produits mis à jour en 1 seul batch Firestore !`);
  console.log('🎉 Rechargez l\'app.\n');
  process.exit(0);
}
main().catch(e => { console.error('❌', e.message); process.exit(1); });
