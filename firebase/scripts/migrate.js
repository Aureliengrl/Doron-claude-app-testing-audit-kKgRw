/**
 * Doron — Migration Firebase via REST API
 *
 * Lit tous les documents /gifts et ajoute les tags manquants:
 * occasion_*, saison_*, popularite_*, type_intime
 *
 * Pas d'authentification requise — règles Firestore allow write: if true
 *
 * Usage:
 *   node migrate.js
 */

const https = require('https');

const PROJECT_ID = 'doron-b3011';
const COLLECTION = 'gifts';
const BASE = 'firestore.googleapis.com';
const DB_PATH = `/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

// ── Firestore REST helpers ────────────────────────────────────────────────
function toFSValue(val) {
    if (val === null || val === undefined) return { nullValue: null };
    if (typeof val === 'boolean') return { booleanValue: val };
    if (typeof val === 'number') return Number.isInteger(val) ? { integerValue: String(val) } : { doubleValue: val };
    if (typeof val === 'string') return { stringValue: val };
    if (Array.isArray(val)) return { arrayValue: { values: val.map(toFSValue) } };
    if (typeof val === 'object') {
        const fields = {};
        for (const [k, v] of Object.entries(val)) fields[k] = toFSValue(v);
        return { mapValue: { fields } };
    }
    return { stringValue: String(val) };
}

function parseTagsFromDoc(doc) {
    const tagsVal = doc.fields && doc.fields.tags;
    if (!tagsVal || !tagsVal.arrayValue) return [];
    return (tagsVal.arrayValue.values || []).map(v => v.stringValue || '').filter(Boolean);
}

function httpsRequest(options, body = null) {
    return new Promise((resolve, reject) => {
        const req = https.request(options, res => {
            let data = '';
            res.on('data', c => data += c);
            res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    resolve(JSON.parse(data));
                } else {
                    reject(new Error(`HTTP ${res.statusCode}: ${data.substring(0, 400)}`));
                }
            });
        });
        req.on('error', reject);
        if (body) req.write(body);
        req.end();
    });
}

// ── Lister tous les documents (avec pagination) ───────────────────────────
async function listAllDocs() {
    const docs = [];
    let pageToken = '';
    do {
        const path = `${DB_PATH}/${COLLECTION}?pageSize=300${pageToken ? `&pageToken=${pageToken}` : ''}`;
        const resp = await httpsRequest({ hostname: BASE, path, method: 'GET' });
        if (resp.documents) docs.push(...resp.documents);
        pageToken = resp.nextPageToken || '';
    } while (pageToken);
    return docs;
}

// ── Patch un document (mise à jour des tags uniquement) ───────────────────
function patchDocument(docName, newTags) {
    const body = JSON.stringify({
        fields: { tags: toFSValue(newTags) }
    });
    const path = `/v1/${docName}?updateMask.fieldPaths=tags`;
    return httpsRequest({
        hostname: BASE, path, method: 'PATCH',
        headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) }
    }, body);
}

// ── Inférence de popularité ───────────────────────────────────────────────
function inferPopularite(tags, name, brand) {
    const n = (name || '').toLowerCase();
    const b = (brand || '').toLowerCase();
    const viral = ['apple', 'chanel', 'dior', 'nike', 'airpods', 'lego', 'stanley', 'crocs', 'ugg', 'nespresso', 'diptyque', 'rituals', 'lululemon'];
    const popular = ['sony', 'samsung', 'lancôme', 'garmin', 'jbl', 'veja', 'sézane', 'clarins', 'nuxe', 'kitchenaid', 'dyson', 'montblanc', 'longines', 'tractive'];
    if (viral.some(v => b.includes(v) || n.includes(v))) return 'popularite_5';
    if (popular.some(v => b.includes(v))) return 'popularite_4';
    return 'popularite_3';
}

// ── Inférence de saison ───────────────────────────────────────────────────
function inferSaison(name) {
    const n = (name || '').toLowerCase();
    const kHiver = ['ski', 'snow', 'neige', 'bonnet', 'écharpe', 'manteau', 'doudoune', 'bouillotte', 'chocolat chaud', 'hiver', 'gants', 'chaufferette', 'cachemire', 'polaire', 'couverture', 'plaid', 'ugg', 'apres-ski', 'fourrure'];
    const kEte = ['solaire', 'soleil', 'plage', 'bikini', 'été', 'barbecue', 'piscine', 'sunscreen', 'tanning', 'parasol', 'ventilateur', 'tong'];
    const kPrintemps = ['fleurs', 'printemps', 'jardin', 'jardinage', 'semences', 'potager'];
    const kAutomne = ['automne', 'citrouille', 'truffes', 'champagne', 'rentrée'];
    if (kHiver.some(k => n.includes(k))) return 'saison_hiver';
    if (kEte.some(k => n.includes(k))) return 'saison_ete';
    if (kPrintemps.some(k => n.includes(k))) return 'saison_printemps';
    if (kAutomne.some(k => n.includes(k))) return 'saison_automne';
    return null;
}

// ── Inférence d'occasion ──────────────────────────────────────────────────
function inferOccasions(name, existingTags, price) {
    const n = (name || '').toLowerCase();
    const occ = new Set();
    const hasTech = existingTags.includes('type_high_tech');
    const hasJoyaux = existingTags.includes('type_bijoux');
    const hasBienEtre = existingTags.includes('type_bien_etre');
    const hasGastro = existingTags.includes('type_gastronomie');
    const hasJouets = existingTags.includes('type_jeux_jouets') || existingTags.includes('age_enfant');

    if (hasJoyaux || n.includes('bague') || n.includes('collier') || n.includes('montre'))
        occ.add('occasion_anniversaire'), occ.add('occasion_mariage'), occ.add('occasion_saint_valentin');
    if (hasTech)
        occ.add('occasion_noel'), occ.add('occasion_anniversaire');
    if (hasGastro && price >= 40)
        occ.add('occasion_noel'), occ.add('occasion_anniversaire');
    if (hasBienEtre && (n.includes('bougie') || n.includes('bain') || n.includes('spa')))
        occ.add('occasion_saint_valentin');
    if (n.includes('carnet') || n.includes('stylo') || n.includes('plume'))
        occ.add('occasion_remerciement'), occ.add('occasion_anniversaire');
    if (hasJouets)
        occ.add('occasion_noel');
    return [...occ];
}

// ── Script principal ──────────────────────────────────────────────────────
async function migrate() {
    console.log('🔄 Chargement des produits Firebase...');
    const docs = await listAllDocs();
    console.log(`📦 ${docs.length} produits trouvés.\n`);

    let updated = 0;
    let skipped = 0;
    let errors = 0;

    for (const doc of docs) {
        try {
            const tags = parseTagsFromDoc(doc);
            const name = doc.fields?.name?.stringValue || '';
            const brand = doc.fields?.brand?.stringValue || '';
            const price = parseInt(doc.fields?.price?.integerValue || doc.fields?.price?.doubleValue || 0, 10);

            const newTags = [...tags];
            let changed = false;

            // 1. Popularité
            if (!tags.some(t => t.startsWith('popularite_'))) {
                newTags.push(inferPopularite(tags, name, brand));
                changed = true;
            }
            // 2. Saison
            if (!tags.some(t => t.startsWith('saison_'))) {
                const s = inferSaison(name);
                if (s) { newTags.push(s); changed = true; }
            }
            // 3. Occasion
            if (!tags.some(t => t.startsWith('occasion_'))) {
                const occs = inferOccasions(name, tags, price);
                if (occs.length > 0) { newTags.push(...occs); changed = true; }
            }
            // 4. type_intime
            if (!tags.includes('type_intime')) {
                const intimeMots = ['lingerie', 'soutien-gorge', 'culotte', 'string', 'boxer', 'slip', 'sexy'];
                if (intimeMots.some(k => name.toLowerCase().includes(k))) {
                    newTags.push('type_intime');
                    changed = true;
                }
            }

            if (changed) {
                const unique = [...new Set(newTags)];
                await patchDocument(doc.name, unique);
                updated++;
                process.stdout.write(`\r✏️  ${updated} produits migrés...`);
                await new Promise(r => setTimeout(r, 30));
            } else {
                skipped++;
            }
        } catch (err) {
            errors++;
            console.error(`\n❌ Erreur doc ${doc.name?.split('/').pop()}: ${err.message.substring(0, 80)}`);
        }
    }

    console.log(`\n\n✅ MIGRATION TERMINÉE!`);
    console.log(`   ${updated} produits mis à jour`);
    console.log(`   ${skipped} produits déjà à jour (ignorés)`);
    if (errors > 0) console.log(`   ${errors} erreurs`);
    process.exit(0);
}

migrate().catch(err => {
    console.error('❌ Erreur fatale:', err.message);
    process.exit(1);
});
