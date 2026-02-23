/**
 * Doron — Seed Firebase v4 via REST API
 * 
 * Utilise l'API REST Firestore directement — pas d'authentification requise
 * car les règles Firestore permettent allow create/write: if true pour /gifts
 * 
 * Usage (depuis firebase/scripts/) :
 *   node seed.js
 */

const https = require('https');

const PROJECT_ID = 'doron-b3011';
const COLLECTION = 'gifts';
const BASE_URL = `firestore.googleapis.com`;
const API_PATH = `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${COLLECTION}`;

// ── Convertit un objet JS en document Firestore (format REST) ──────────────
function toFirestoreValue(val) {
    if (val === null || val === undefined) return { nullValue: null };
    if (typeof val === 'boolean') return { booleanValue: val };
    if (typeof val === 'number') {
        return Number.isInteger(val) ? { integerValue: String(val) } : { doubleValue: val };
    }
    if (typeof val === 'string') return { stringValue: val };
    if (Array.isArray(val)) {
        return { arrayValue: { values: val.map(toFirestoreValue) } };
    }
    if (typeof val === 'object') {
        const fields = {};
        for (const [k, v] of Object.entries(val)) {
            fields[k] = toFirestoreValue(v);
        }
        return { mapValue: { fields } };
    }
    return { stringValue: String(val) };
}

function toFirestoreDoc(obj) {
    const fields = {};
    for (const [k, v] of Object.entries(obj)) {
        fields[k] = toFirestoreValue(v);
    }
    return { fields };
}

// ── POST un document dans Firestore ───────────────────────────────────────
function postDocument(doc) {
    return new Promise((resolve, reject) => {
        const body = JSON.stringify(toFirestoreDoc(doc));
        const options = {
            hostname: BASE_URL,
            path: API_PATH,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(body),
            },
        };
        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    resolve(JSON.parse(data));
                } else {
                    reject(new Error(`HTTP ${res.statusCode}: ${data.substring(0, 300)}`));
                }
            });
        });
        req.on('error', reject);
        req.write(body);
        req.end();
    });
}

// ── Produits v4 ──────────────────────────────────────────────────────────
const products = [
    // ADO FILLE
    { name: 'Stanley Quencher Flowstate 1.18L Rose Flamingo', brand: 'Stanley', price: 55, image: 'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=400', source: 'stanley.com', active: true, tags: ['gender_femme', 'cat_tendances', 'budget_50_100', 'type_sport_outdoor', 'style_tendance', 'perso_cool', 'passion_sport', 'age_ado', 'occasion_anniversaire', 'occasion_noel', 'popularite_5', 'saison_ete'] },
    { name: 'Crocs Classic Clog Taffy Pink', brand: 'Crocs', price: 55, image: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400', source: 'crocs.eu', active: true, tags: ['gender_femme', 'cat_mode', 'budget_50_100', 'type_mode_accessoires', 'style_tendance', 'style_decontracte', 'passion_mode', 'age_ado', 'occasion_anniversaire', 'popularite_5'] },
    { name: 'Polaroid Go Appareil Photo Instantané Rose', brand: 'Polaroid', price: 79, image: 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=400', source: 'polaroid.com', active: true, tags: ['gender_femme', 'cat_tech', 'budget_50_100', 'type_high_tech', 'type_loisirs_creatifs', 'style_tendance', 'style_vintage', 'passion_photo', 'perso_creatif', 'age_ado', 'occasion_anniversaire', 'occasion_noel', 'popularite_5'] },
    { name: 'UGG Classic Mini Platform Chestnut', brand: 'UGG', price: 175, image: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400', source: 'ugg.com', active: true, tags: ['gender_femme', 'cat_mode', 'budget_100_200', 'type_mode_accessoires', 'style_tendance', 'style_decontracte', 'passion_mode', 'age_ado', 'occasion_noel', 'popularite_5', 'saison_hiver'] },
    { name: 'Palette Fenty Beauty Snap Shadows', brand: 'Fenty Beauty', price: 38, image: 'https://images.unsplash.com/photo-1522338140262-f46f5913618a?w=400', source: 'fentybeauty.com', active: true, tags: ['gender_femme', 'cat_beaute', 'budget_0_50', 'type_beaute_soins', 'style_tendance', 'passion_beaute', 'perso_creatif', 'age_ado', 'occasion_anniversaire', 'popularite_5'] },
    { name: 'Sweat Crop Top Stüssy Femme Blanc', brand: 'Stüssy', price: 89, image: 'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=400', source: 'stussy.com', active: true, tags: ['gender_femme', 'cat_mode', 'budget_50_100', 'type_mode_accessoires', 'style_streetwear', 'style_tendance', 'passion_mode', 'perso_cool', 'age_ado', 'occasion_anniversaire'] },
    { name: 'AirPods 4 en 2 Blanc', brand: 'Apple', price: 179, image: 'https://images.unsplash.com/photo-1603351154351-5e2d0600bb77?w=400', source: 'apple.com', active: true, tags: ['gender_femme', 'cat_tech', 'budget_100_200', 'type_high_tech', 'type_musique_audio', 'style_moderne', 'passion_musique', 'passion_tech', 'perso_cool', 'age_ado', 'occasion_anniversaire', 'occasion_noel', 'popularite_5'] },
    { name: 'Basket Nike Dunk Low Femme Triple White', brand: 'Nike', price: 115, image: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400', source: 'nike.com', active: true, tags: ['gender_femme', 'cat_mode', 'budget_100_200', 'type_mode_accessoires', 'style_tendance', 'style_streetwear', 'passion_mode', 'passion_sport', 'age_ado', 'occasion_anniversaire', 'popularite_5'] },
    { name: 'Kit Nail Art Gel Manucurist Green', brand: 'Manucurist', price: 35, image: 'https://images.unsplash.com/photo-1604654894610-df63bc536371?w=400', source: 'manucurist.com', active: true, tags: ['gender_femme', 'cat_beaute', 'budget_0_50', 'type_beaute_soins', 'style_tendance', 'passion_beaute', 'perso_creatif', 'age_ado', 'popularite_4'] },
    { name: 'Romans Sarah J. Maas Enemies to Lovers x5', brand: 'Bloomsbury', price: 45, image: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=400', source: 'amazon.fr', active: true, tags: ['gender_femme', 'cat_tendances', 'budget_0_50', 'type_livres_bd', 'style_tendance', 'passion_lecture', 'perso_romantique', 'age_ado', 'occasion_anniversaire'] },
    // HOMME 55+
    { name: 'Stylo Plume Montblanc Meisterstück Platinum', brand: 'Montblanc', price: 430, image: 'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?w=400', source: 'montblanc.com', active: true, tags: ['gender_homme', 'cat_mode', 'budget_200+', 'type_mode_accessoires', 'style_elegant', 'style_luxe', 'perso_ambitieux', 'age_senior', 'occasion_anniversaire', 'occasion_remerciement', 'popularite_4'] },
    { name: 'Whisky Glenfiddich 18 ans Single Malt 70cl', brand: 'Glenfiddich', price: 85, image: 'https://images.unsplash.com/photo-1474722883778-792e7990302f?w=400', source: 'glenfiddich.com', active: true, tags: ['gender_homme', 'cat_food', 'budget_50_100', 'type_gastronomie', 'style_classique', 'style_luxe', 'passion_vins', 'perso_gourmand', 'age_senior', 'age_adulte', 'occasion_anniversaire', 'occasion_noel', 'popularite_4'] },
    { name: 'Montre Longines HydroConquest 39mm Bleu', brand: 'Longines', price: 890, image: 'https://images.unsplash.com/photo-1461141346587-763ab02bced9?w=400', source: 'longines.com', active: true, tags: ['gender_homme', 'cat_mode', 'budget_200+', 'type_bijoux', 'style_elegant', 'style_classique', 'perso_ambitieux', 'age_senior', 'age_adulte', 'occasion_anniversaire', 'occasion_mariage', 'popularite_4'] },
    { name: 'Fauteuil Massant Shiatsu Medisana MC 826', brand: 'Medisana', price: 349, image: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=400', source: 'amazon.fr', active: true, tags: ['gender_mixte', 'cat_maison', 'budget_200+', 'type_bien_etre', 'style_moderne', 'perso_zen', 'perso_pratique', 'age_senior', 'context_famille', 'occasion_anniversaire', 'popularite_4'] },
    { name: 'Encyclopédie Larousse Gastronomique 2024', brand: 'Larousse', price: 65, image: 'https://images.unsplash.com/photo-1466637574441-749b8f19452f?w=400', source: 'amazon.fr', active: true, tags: ['gender_mixte', 'cat_food', 'budget_50_100', 'type_gastronomie', 'type_livres_bd', 'style_classique', 'passion_cuisine', 'perso_gourmand', 'age_senior', 'age_adulte', 'occasion_anniversaire', 'occasion_noel'] },
    // EXPÉRIENCES COUPLE
    { name: 'Cours Cuisine Gordon Ramsay MasterClass', brand: 'MasterClass', price: 120, image: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=400', source: 'masterclass.com', active: true, tags: ['gender_mixte', 'cat_tendances', 'budget_100_200', 'type_gastronomie', 'type_culture', 'style_moderne', 'perso_creatif', 'perso_gourmand', 'passion_cuisine', 'age_adulte', 'context_amoureux', 'context_ami', 'occasion_anniversaire', 'occasion_saint_valentin'] },
    { name: 'Spa en Duo Cinq Mondes 2h Rituel Sensoriel', brand: 'Cinq Mondes', price: 280, image: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=400', source: 'cinqmondes.com', active: true, tags: ['gender_mixte', 'cat_tendances', 'budget_200+', 'type_bien_etre', 'style_luxe', 'style_elegant', 'perso_zen', 'perso_romantique', 'passion_beaute', 'age_adulte', 'context_amoureux', 'occasion_saint_valentin', 'occasion_anniversaire', 'popularite_4'] },
    { name: 'Escape Game Privé Paris 2 joueurs', brand: 'Time Breakers', price: 99, image: 'https://images.unsplash.com/photo-1591267990532-e5bdb1b0ceb8?w=400', source: 'timebreakers.fr', active: true, tags: ['gender_mixte', 'cat_tendances', 'budget_50_100', 'type_jeux_jouets', 'style_tendance', 'perso_aventurier', 'perso_sociable', 'age_adulte', 'context_amoureux', 'context_ami', 'occasion_anniversaire', 'occasion_saint_valentin'] },
    { name: 'Vol Montgolfière Duo Beaujolais Sunrise', brand: 'Air Escargot', price: 380, image: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400', source: 'airescargot.com', active: true, tags: ['gender_mixte', 'cat_tendances', 'budget_200+', 'type_voyage_aventure', 'style_boheme', 'perso_aventurier', 'perso_romantique', 'passion_voyages', 'passion_nature', 'age_adulte', 'context_amoureux', 'occasion_anniversaire', 'occasion_saint_valentin'] },
    { name: 'Nuit Romantique Relais et Châteaux Seine', brand: 'Relais et Châteaux', price: 350, image: 'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=400', source: 'relaischateaux.com', active: true, tags: ['gender_mixte', 'cat_tendances', 'budget_200+', 'type_voyage_aventure', 'type_bien_etre', 'style_luxe', 'style_elegant', 'perso_romantique', 'passion_voyages', 'age_adulte', 'context_amoureux', 'occasion_anniversaire', 'occasion_saint_valentin', 'popularite_4'] },
    { name: 'Atelier Poterie Duo Paris 3h', brand: 'Le Marais Poterie', price: 95, image: 'https://images.unsplash.com/photo-1567696153798-9111f9cd3d0d?w=400', source: 'amazon.fr', active: true, tags: ['gender_mixte', 'cat_tendances', 'budget_50_100', 'type_loisirs_creatifs', 'style_boheme', 'perso_creatif', 'perso_sociable', 'passion_art', 'age_adulte', 'context_amoureux', 'context_ami', 'occasion_anniversaire', 'occasion_noel'] },
    // ANIMAUX PREMIUM
    { name: 'GPS Tracker Tractive DOG 4 LTE Bleu', brand: 'Tractive', price: 49, image: 'https://images.unsplash.com/photo-1548767797-d8c844163c4a?w=400', source: 'tractive.com', active: true, tags: ['gender_mixte', 'cat_tech', 'budget_0_50', 'type_high_tech', 'style_moderne', 'passion_animaux', 'perso_bienveillant', 'age_adulte', 'popularite_5'] },
    { name: 'Fontaine à Eau CATIT Flower 3L Filtrante', brand: 'Catit', price: 39, image: 'https://images.unsplash.com/photo-1548767797-d8c844163c4a?w=400', source: 'catit.com', active: true, tags: ['gender_mixte', 'cat_maison', 'budget_0_50', 'type_maison_deco', 'style_moderne', 'passion_animaux', 'perso_bienveillant', 'age_adulte', 'popularite_4'] },
    { name: 'Caméra Petcube Bites 2 Lite Chat/Chien', brand: 'Petcube', price: 89, image: 'https://images.unsplash.com/photo-1573865526739-10659fec78a5?w=400', source: 'petcube.com', active: true, tags: ['gender_mixte', 'cat_tech', 'budget_50_100', 'type_high_tech', 'style_moderne', 'passion_animaux', 'passion_tech', 'perso_bienveillant', 'age_adulte', 'popularite_4'] },
    { name: 'Arbre à Chat Trixie Parla 145cm', brand: 'Trixie', price: 99, image: 'https://images.unsplash.com/photo-1548767797-d8c844163c4a?w=400', source: 'trixie.de', active: true, tags: ['gender_mixte', 'cat_maison', 'budget_50_100', 'type_maison_deco', 'style_minimaliste', 'passion_animaux', 'perso_bienveillant', 'age_adulte'] },
    { name: 'Collier GPS Lumineux LED Waterproof PetSafe', brand: 'PetSafe', price: 28, image: 'https://images.unsplash.com/photo-1535930891776-0c2dfb7fda1a?w=400', source: 'petsafe.com', active: true, tags: ['gender_mixte', 'cat_tendances', 'budget_0_50', 'type_sport_outdoor', 'style_moderne', 'passion_animaux', 'perso_actif', 'age_adulte'] },
    // GREEN / ECO
    { name: 'Kit Potager Balcon 6 Plantes Aromatiques', brand: 'Jardin Factory', price: 42, image: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400', source: 'jardinfactory.fr', active: true, tags: ['gender_mixte', 'cat_maison', 'budget_0_50', 'type_maison_deco', 'type_bien_etre', 'style_eco_responsable', 'style_boheme', 'perso_bienveillant', 'passion_jardinage', 'passion_cuisine', 'passion_nature', 'age_adulte', 'popularite_4'] },
    { name: 'Veste Patagonia Down Sweater Femme', brand: 'Patagonia', price: 299, image: 'https://images.unsplash.com/photo-1552902865-b72c031ac5ea?w=400', source: 'patagonia.com', active: true, tags: ['gender_femme', 'cat_mode', 'budget_200+', 'type_mode_accessoires', 'type_sport_outdoor', 'style_eco_responsable', 'style_sportif', 'perso_actif', 'perso_bienveillant', 'passion_sport', 'passion_nature', 'age_adulte', 'saison_hiver', 'saison_automne'] },
    { name: 'Sneakers Ecoalf Quartz Barcelona Blanc', brand: 'Ecoalf', price: 120, image: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400', source: 'ecoalf.com', active: true, tags: ['gender_mixte', 'cat_mode', 'budget_100_200', 'type_mode_accessoires', 'style_eco_responsable', 'style_minimaliste', 'passion_mode', 'passion_nature', 'age_adulte', 'popularite_4'] },
    { name: 'Zero Waste Starter Kit Bambou 12 pièces', brand: 'Package Free Shop', price: 45, image: 'https://images.unsplash.com/photo-1542601906897-b1b1e5dfa6d9?w=400', source: 'amazon.fr', active: true, tags: ['gender_mixte', 'cat_tendances', 'budget_0_50', 'type_bien_etre', 'type_maison_deco', 'style_eco_responsable', 'style_minimaliste', 'perso_bienveillant', 'passion_nature', 'age_adulte', 'age_ado'] },
    { name: 'Bougie Cire Soja Bergamote Maison Margiela', brand: 'Maison Margiela', price: 55, image: 'https://images.unsplash.com/photo-1602028915047-37269d1a73f7?w=400', source: 'maisonmargiela.com', active: true, tags: ['gender_mixte', 'cat_maison', 'budget_50_100', 'type_maison_deco', 'type_bien_etre', 'style_elegant', 'style_eco_responsable', 'perso_zen', 'passion_nature', 'age_adulte', 'popularite_4'] },
    // PASSION AUTO
    { name: 'Expérience Circuit Ferrari 458 Italia 3 tours', brand: 'Prestige Auto Driving', price: 299, image: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=400', source: 'amazon.fr', active: true, tags: ['gender_homme', 'cat_tendances', 'budget_200+', 'type_voyage_aventure', 'style_luxe', 'style_moderne', 'perso_aventurier', 'perso_ambitieux', 'passion_automobile', 'passion_sport', 'age_adulte', 'occasion_anniversaire', 'popularite_4'] },
    { name: 'Livre Collector Porsche 911 Anthologie', brand: 'Taschen', price: 150, image: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=400', source: 'taschen.com', active: true, tags: ['gender_homme', 'cat_tendances', 'budget_100_200', 'type_livres_bd', 'style_luxe', 'style_classique', 'perso_intellectuel', 'passion_automobile', 'age_adulte', 'age_senior'] },
    { name: 'Circuit Scalextric Advance DTM Racing 1:32', brand: 'Scalextric', price: 189, image: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400', source: 'amazon.fr', active: true, tags: ['gender_homme', 'cat_tendances', 'budget_100_200', 'type_jeux_jouets', 'style_classique', 'perso_creatif', 'passion_automobile', 'age_enfant', 'age_ado', 'age_adulte'] },
    { name: 'Coffret Premium Detailing Voiture Meguiar\'s 7p', brand: 'Meguiar\'s', price: 65, image: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400', source: 'amazon.fr', active: true, tags: ['gender_homme', 'cat_tendances', 'budget_50_100', 'style_moderne', 'passion_automobile', 'perso_pratique', 'age_adulte', 'occasion_anniversaire'] },
    // DIY / MAKER
    { name: 'Imprimante 3D Bambu Lab A1 Mini Combo', brand: 'Bambu Lab', price: 499, image: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400', source: 'bambulab.com', active: true, tags: ['gender_mixte', 'cat_tech', 'budget_200+', 'type_high_tech', 'type_loisirs_creatifs', 'style_moderne', 'perso_creatif', 'perso_techie', 'passion_tech', 'passion_loisirs_creatifs', 'age_adulte', 'age_ado', 'popularite_5'] },
    { name: 'Kit Arduino Uno R4 WiFi Starter Electronics', brand: 'Arduino', price: 45, image: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400', source: 'arduino.cc', active: true, tags: ['gender_mixte', 'cat_tech', 'budget_0_50', 'type_high_tech', 'type_loisirs_creatifs', 'style_moderne', 'perso_creatif', 'perso_techie', 'passion_tech', 'passion_bricolage', 'age_adulte', 'age_ado'] },
    { name: 'Machine Découpe Vinyle Cricut Joy Xtra', brand: 'Cricut', price: 229, image: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400', source: 'cricut.com', active: true, tags: ['gender_femme', 'cat_tech', 'budget_200+', 'type_high_tech', 'type_loisirs_creatifs', 'style_moderne', 'style_tendance', 'perso_creatif', 'passion_loisirs_creatifs', 'passion_art', 'age_adulte', 'popularite_4'] },
    { name: 'Raspberry Pi 5 Starter Kit 8GB', brand: 'Raspberry Pi', price: 120, image: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400', source: 'raspberrypi.com', active: true, tags: ['gender_mixte', 'cat_tech', 'budget_100_200', 'type_high_tech', 'style_moderne', 'perso_techie', 'passion_tech', 'passion_bricolage', 'age_adulte', 'age_ado'] },
    { name: 'Kit Lutherie Ukulélé à monter soi-même', brand: 'Luthendo', price: 65, image: 'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=400', source: 'amazon.fr', active: true, tags: ['gender_mixte', 'cat_tendances', 'budget_50_100', 'type_loisirs_creatifs', 'type_musique_audio', 'style_boheme', 'perso_creatif', 'passion_musique', 'passion_loisirs_creatifs', 'age_adulte', 'age_ado'] },
    // SAISON HIVER
    { name: 'Forfait Ski Val Thorens 7 jours Adulte', brand: 'Val Thorens', price: 350, image: 'https://images.unsplash.com/photo-1548777123-e216912df7d8?w=400', source: 'valthorens.com', active: true, tags: ['gender_mixte', 'cat_tendances', 'budget_200+', 'type_sport_outdoor', 'type_voyage_aventure', 'style_sportif', 'perso_actif', 'perso_aventurier', 'passion_sport', 'passion_voyages', 'age_adulte', 'saison_hiver', 'occasion_noel'] },
    { name: 'Gants Ski Hestra Army Leather Heli Noir', brand: 'Hestra', price: 135, image: 'https://images.unsplash.com/photo-1547592180-85f173990554?w=400', source: 'hestra.com', active: true, tags: ['gender_mixte', 'cat_mode', 'budget_100_200', 'type_sport_outdoor', 'style_sportif', 'perso_actif', 'passion_sport', 'age_adulte', 'saison_hiver'] },
    { name: 'Bonnet Laine Mérinos Icebreaker Ski', brand: 'Icebreaker', price: 45, image: 'https://images.unsplash.com/photo-1521369909029-2afed882baee?w=400', source: 'icebreaker.com', active: true, tags: ['gender_mixte', 'cat_mode', 'budget_0_50', 'type_sport_outdoor', 'type_mode_accessoires', 'style_sportif', 'style_eco_responsable', 'perso_actif', 'passion_sport', 'age_adulte', 'age_ado', 'saison_hiver'] },
    { name: 'Chaufferette Mains Zippo Rechargeable Noir', brand: 'Zippo', price: 45, image: 'https://images.unsplash.com/photo-1547092251-37f9d0f0e50e?w=400', source: 'amazon.fr', active: true, tags: ['gender_mixte', 'cat_tendances', 'budget_0_50', 'type_sport_outdoor', 'type_bien_etre', 'style_classique', 'passion_nature', 'passion_sport', 'age_adulte', 'saison_hiver', 'occasion_noel'] },
    { name: 'Coffret Chocolats Chauds Artisanaux Rivière', brand: 'Rivière', price: 32, image: 'https://images.unsplash.com/photo-1549007994-cb92caebd54b?w=400', source: 'amazon.fr', active: true, tags: ['gender_mixte', 'cat_food', 'budget_0_50', 'type_gastronomie', 'style_classique', 'perso_gourmand', 'passion_cuisine', 'age_adulte', 'age_enfant', 'saison_hiver', 'occasion_noel', 'context_famille', 'popularite_4'] },
    { name: 'Tenue Ski Rossignol Femme Blazing Suit', brand: 'Rossignol', price: 320, image: 'https://images.unsplash.com/photo-1548777123-e216912df7d8?w=400', source: 'rossignol.com', active: true, tags: ['gender_femme', 'cat_mode', 'budget_200+', 'type_sport_outdoor', 'type_mode_accessoires', 'style_sportif', 'style_tendance', 'perso_actif', 'passion_sport', 'age_adulte', 'age_ado', 'saison_hiver'] },
    { name: 'Télescope Celestron StarSense Explorer DX 130AZ', brand: 'Celestron', price: 349, image: 'https://images.unsplash.com/photo-1532094349884-543559244a41?w=400', source: 'celestron.com', active: true, tags: ['gender_mixte', 'cat_tech', 'budget_200+', 'type_high_tech', 'style_moderne', 'perso_intellectuel', 'perso_aventurier', 'passion_nature', 'passion_tech', 'age_adulte', 'age_ado', 'saison_hiver', 'occasion_noel'] },
    { name: 'Bouillotte Luxe Velours Housse Cousue', brand: 'Fashy', price: 28, image: 'https://images.unsplash.com/photo-1631049421450-348ccd7f8949?w=400', source: 'amazon.fr', active: true, tags: ['gender_femme', 'cat_maison', 'budget_0_50', 'type_bien_etre', 'style_decontracte', 'perso_zen', 'age_adulte', 'age_senior', 'saison_hiver', 'occasion_noel', 'context_famille'] },
];

// ── Main ─────────────────────────────────────────────────────────────────
async function seed() {
    const total = products.length;
    let success = 0;
    let errors = 0;

    console.log(`🌱 Seed v4 — ${total} produits vers Firebase...`);
    console.log(`📡 Projet: ${PROJECT_ID} | Collection: ${COLLECTION}\n`);

    for (let i = 0; i < products.length; i++) {
        const p = products[i];
        try {
            await postDocument(p);
            success++;
            if (success % 5 === 0 || success === total) {
                process.stdout.write(`\r💾 ${success}/${total} insérés...`);
            }
        } catch (err) {
            errors++;
            console.error(`\n❌ Erreur "${p.name}": ${err.message.substring(0, 100)}`);
        }
        // Small delay to avoid rate limiting
        if (i < products.length - 1) {
            await new Promise(r => setTimeout(r, 50));
        }
    }

    console.log(`\n\n✅ SEED V4 TERMINÉ!`);
    console.log(`   ${success} produits insérés avec succès`);
    if (errors > 0) console.log(`   ${errors} erreurs`);
    console.log(`\n🔗 Firebase Console: https://console.firebase.google.com/project/${PROJECT_ID}/firestore`);
    process.exit(0);
}

seed().catch(err => {
    console.error('❌ Erreur fatale:', err);
    process.exit(1);
});
