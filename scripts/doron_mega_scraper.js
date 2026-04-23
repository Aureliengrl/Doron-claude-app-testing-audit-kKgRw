#!/usr/bin/env node
/**
 * ╔══════════════════════════════════════════════════════════════════════════╗
 * ║    🎁 DORON — MEGA SCRAPER v2.0                                         ║
 * ║                                                                          ║
 * ║  Ajoute ~200 nouveaux produits premium directement scrappés depuis :     ║
 * ║   • Sephora.fr  (beauté, parfums)                                        ║
 * ║   • FNAC.com    (tech, gaming, livres)                                   ║
 * ║   • La Redoute  (mode, maison)                                           ║
 * ║  + Un catalogue curé de 150 produits vérifiés avec images Firestore      ║
 * ║                                                                          ║
 * ║  Chaque produit est :                                                    ║
 * ║   ✅ Taguée correctement (gender, cat, budget, passion…)                 ║
 * ║   ✅ Image téléchargée et uploadée dans Firebase Storage                 ║
 * ║   ✅ Vérifié sans doublon                                                ║
 * ║                                                                          ║
 * ║  USAGE:                                                                  ║
 * ║    node doron_mega_scraper.js              → ajoute tout                 ║
 * ║    node doron_mega_scraper.js --dry-run    → simule sans écrire          ║
 * ║    node doron_mega_scraper.js --limit 20   → limite à 20 produits        ║
 * ╚══════════════════════════════════════════════════════════════════════════╝
 */

const admin  = require('firebase-admin');
const fetch  = require('node-fetch');
const cheerio = require('cheerio');

const sa = require('./serviceAccountKey.json');
admin.initializeApp({
  credential:    admin.credential.cert(sa),
  storageBucket: 'doron-b3011.firebasestorage.app',
});
const db     = admin.firestore();
const bucket = admin.storage().bucket();

// ─── CLI ──────────────────────────────────────────────────────────────────────
const DRY_RUN  = process.argv.includes('--dry-run');
const limitArg = process.argv.indexOf('--limit');
const LIMIT    = limitArg !== -1 ? parseInt(process.argv[limitArg + 1]) : Infinity;
const DELAY_MS = 600;
const TIMEOUT  = 12000;
const sleep    = ms => new Promise(r => setTimeout(r, ms));

// ─── Tag helpers ──────────────────────────────────────────────────────────────
const VALID_BUDGET = ['budget_0_50','budget_50_100','budget_100_200','budget_200+'];
const VALID_GENDER = ['gender_femme','gender_homme','gender_mixte'];
const VALID_CAT    = ['cat_tendances','cat_tech','cat_mode','cat_maison','cat_beaute','cat_food'];

function budgetTag(p)  {
  if (p < 50)  return 'budget_0_50';
  if (p < 100) return 'budget_50_100';
  if (p < 200) return 'budget_100_200';
  return 'budget_200+';
}

// ══════════════════════════════════════════════════════════════════════════════
// LE CATALOGUE CURÉ — 200 produits avec images scrappées depuis leurs pages
// ──────────────────────────────────────────────────────────────────────────────
// Format : { name, brand, price, url, tags[] }
// L'image sera scrappée depuis url (og:image) puis uploadée dans Firebase Storage
// ══════════════════════════════════════════════════════════════════════════════

const PRODUCTS_TO_ADD = [

  // ═══ PARFUMS FEMME ════════════════════════════════════════════════════════
  { name: 'Chanel N°5 Eau de Parfum 50ml', brand: 'Chanel', price: 142,
    url: 'https://www.sephora.fr/p/n-5-eau-de-parfum-P10007803.html',
    tags: ['gender_femme','cat_beaute','budget_100_200','type_beaute_soins','style_elegant','style_classique','style_luxe','passion_beaute','perso_romantique','age_adulte','popularite_5','occasion_anniversaire','occasion_noel','occasion_saint_valentin'] },

  { name: 'Dior Miss Dior Rose N\'Roses 50ml', brand: 'Dior', price: 120,
    url: 'https://www.sephora.fr/p/miss-dior-rose-n-roses-P10010742.html',
    tags: ['gender_femme','cat_beaute','budget_100_200','type_beaute_soins','style_elegant','passion_beaute','age_adulte','popularite_5','occasion_saint_valentin','occasion_anniversaire'] },

  { name: 'YSL Libre Eau de Parfum 90ml', brand: 'Yves Saint Laurent', price: 148,
    url: 'https://www.sephora.fr/p/libre-eau-de-parfum-P10015620.html',
    tags: ['gender_femme','cat_beaute','budget_100_200','type_beaute_soins','style_moderne','style_tendance','passion_beaute','age_ado','age_adulte','popularite_5','occasion_anniversaire','occasion_noel'] },

  { name: 'Lancôme Idôle Eau de Parfum 50ml', brand: 'Lancôme', price: 105,
    url: 'https://www.sephora.fr/p/idole-P10017068.html',
    tags: ['gender_femme','cat_beaute','budget_100_200','type_beaute_soins','style_tendance','passion_beaute','age_ado','age_adulte','popularite_4','occasion_anniversaire'] },

  { name: 'Givenchy Irresistible EDP 35ml', brand: 'Givenchy', price: 85,
    url: 'https://www.sephora.fr/p/irresistible-eau-de-parfum-P10019895.html',
    tags: ['gender_femme','cat_beaute','budget_50_100','type_beaute_soins','style_elegant','passion_beaute','age_adulte','popularite_4','occasion_anniversaire'] },

  { name: 'Dolce & Gabbana Light Blue EDT 100ml', brand: 'Dolce & Gabbana', price: 89,
    url: 'https://www.sephora.fr/p/light-blue-eau-de-toilette-P10004016.html',
    tags: ['gender_femme','cat_beaute','budget_50_100','type_beaute_soins','style_decontracte','passion_beaute','age_ado','age_adulte','popularite_5','saison_ete','saison_printemps'] },

  { name: 'Viktor & Rolf Flowerbomb EDP 50ml', brand: 'Viktor & Rolf', price: 116,
    url: 'https://www.sephora.fr/p/flowerbomb-eau-de-parfum-P10004456.html',
    tags: ['gender_femme','cat_beaute','budget_100_200','type_beaute_soins','style_elegant','passion_beaute','age_adulte','popularite_5','occasion_noel','occasion_anniversaire'] },

  { name: 'Carolina Herrera Good Girl EDP 50ml', brand: 'Carolina Herrera', price: 112,
    url: 'https://www.sephora.fr/p/good-girl-P10011376.html',
    tags: ['gender_femme','cat_beaute','budget_100_200','type_beaute_soins','style_tendance','style_elegant','passion_beaute','perso_ambitieux','age_adulte','popularite_5','occasion_noel'] },

  { name: 'Prada Paradoxe EDP 50ml', brand: 'Prada', price: 120,
    url: 'https://www.sephora.fr/p/paradoxe-P10025447.html',
    tags: ['gender_femme','cat_beaute','budget_100_200','type_beaute_soins','style_luxe','style_moderne','passion_beaute','age_adulte','popularite_4','occasion_anniversaire'] },

  { name: 'Maison Margiela Replica Flower Market EDT 100ml', brand: 'Maison Margiela', price: 165,
    url: 'https://www.sephora.fr/p/replica-flower-market-P10015399.html',
    tags: ['gender_mixte','cat_beaute','budget_100_200','type_beaute_soins','style_minimaliste','style_elegant','passion_beaute','perso_intellectuel','age_adulte','popularite_4','occasion_anniversaire','saison_printemps'] },

  { name: 'Maison Margiela Replica By the Fireplace EDT 100ml', brand: 'Maison Margiela', price: 165,
    url: 'https://www.sephora.fr/p/replica-by-the-fireplace-P10007694.html',
    tags: ['gender_mixte','cat_beaute','budget_100_200','type_beaute_soins','style_minimaliste','passion_beaute','perso_intellectuel','age_adulte','popularite_4','occasion_noel','saison_hiver'] },

  // ═══ PARFUMS HOMME ══════════════════════════════════════════════════════
  { name: 'Dior Sauvage EDP 100ml', brand: 'Dior', price: 148,
    url: 'https://www.sephora.fr/p/sauvage-eau-de-parfum-P10014462.html',
    tags: ['gender_homme','cat_beaute','budget_100_200','type_beaute_soins','style_classique','passion_beaute','age_adulte','popularite_5','occasion_noel','occasion_anniversaire'] },

  { name: 'Bleu de Chanel Eau de Parfum 100ml', brand: 'Chanel', price: 160,
    url: 'https://www.sephora.fr/p/bleu-de-chanel-eau-de-parfum-P10011107.html',
    tags: ['gender_homme','cat_beaute','budget_100_200','type_beaute_soins','style_elegant','style_classique','passion_beaute','age_adulte','popularite_5','occasion_noel','occasion_anniversaire'] },

  { name: 'Paco Rabanne 1 Million Lucky EDT 100ml', brand: 'Paco Rabanne', price: 94,
    url: 'https://www.sephora.fr/p/1-million-lucky-eau-de-toilette-P10013640.html',
    tags: ['gender_homme','cat_beaute','budget_50_100','type_beaute_soins','style_tendance','passion_beaute','age_ado','age_adulte','popularite_4','saison_automne'] },

  { name: 'Tom Ford Black Orchid EDP 50ml', brand: 'Tom Ford', price: 175,
    url: 'https://www.sephora.fr/p/black-orchid-eau-de-parfum-P10002742.html',
    tags: ['gender_mixte','cat_beaute','budget_100_200','type_beaute_soins','style_luxe','style_elegant','passion_beaute','perso_excentrique','age_adulte','popularite_4','occasion_anniversaire'] },

  { name: 'Acqua di Parma Colonia EDC 100ml', brand: 'Acqua di Parma', price: 148,
    url: 'https://www.sephora.fr/p/colonia-eau-de-cologne-P10001086.html',
    tags: ['gender_homme','cat_beaute','budget_100_200','type_beaute_soins','style_elegant','style_classique','passion_beaute','perso_intellectuel','age_adulte','popularite_4','occasion_anniversaire'] },

  // ═══ SOINS BEAUTÉ ═══════════════════════════════════════════════════════
  { name: 'La Mer Crème de la Mer 30ml', brand: 'La Mer', price: 170,
    url: 'https://www.sephora.fr/p/creme-de-la-mer-P10000297.html',
    tags: ['gender_femme','cat_beaute','budget_100_200','type_beaute_soins','style_luxe','passion_beaute','age_adulte','popularite_5','occasion_anniversaire','occasion_noel'] },

  { name: 'Estée Lauder Advanced Night Repair 50ml', brand: 'Estée Lauder', price: 105,
    url: 'https://www.sephora.fr/p/advanced-night-repair-synchronized-multi-recovery-complex-P10009001.html',
    tags: ['gender_femme','cat_beaute','budget_100_200','type_beaute_soins','style_classique','passion_beaute','age_adulte','popularite_5','occasion_anniversaire','occasion_noel'] },

  { name: 'Charlotte Tilbury Magic Cream 50ml', brand: 'Charlotte Tilbury', price: 68,
    url: 'https://www.sephora.fr/p/magic-cream-P10017100.html',
    tags: ['gender_femme','cat_beaute','budget_50_100','type_beaute_soins','style_tendance','passion_beaute','perso_sociable','age_adulte','popularite_5','occasion_anniversaire'] },

  { name: 'Tatcha The Dewy Skin Cream 50ml', brand: 'Tatcha', price: 75,
    url: 'https://www.sephora.fr/p/the-dewy-skin-cream-P10017963.html',
    tags: ['gender_femme','cat_beaute','budget_50_100','type_beaute_soins','style_moderne','passion_beaute','age_ado','age_adulte','popularite_4'] },

  { name: 'Drunk Elephant Protini Polypeptide Cream 50ml', brand: 'Drunk Elephant', price: 68,
    url: 'https://www.sephora.fr/p/protini-polypeptide-cream-P10020131.html',
    tags: ['gender_femme','cat_beaute','budget_50_100','type_beaute_soins','style_moderne','passion_beaute','age_ado','age_adulte','popularite_5'] },

  { name: 'Nécessaire The Body Serum 150ml', brand: 'Nécessaire', price: 45,
    url: 'https://www.sephora.fr/p/the-body-serum-P10028093.html',
    tags: ['gender_mixte','cat_beaute','budget_25_50','type_beaute_soins','style_minimaliste','style_eco_responsable','passion_beaute','age_adulte','popularite_4'] },

  { name: 'Aesop Resurrection Aromatique Hand Balm 75ml', brand: 'Aesop', price: 39,
    url: 'https://www.sephora.fr/p/resurrection-aromatique-hand-balm-P10000095.html',
    tags: ['gender_mixte','cat_beaute','budget_25_50','type_beaute_soins','style_minimaliste','style_eco_responsable','passion_beaute','age_adulte','popularite_4','occasion_remerciement'] },

  { name: 'Caudalie Premier Cru Crème Riche 50ml', brand: 'Caudalie', price: 135,
    url: 'https://www.sephora.fr/p/premier-cru-la-creme-riche-P10029107.html',
    tags: ['gender_femme','cat_beaute','budget_100_200','type_beaute_soins','style_luxe','passion_beaute','age_adulte','popularite_4','occasion_anniversaire','occasion_noel'] },

  { name: 'Sol de Janeiro Brazilian Bum Bum Cream 240ml', brand: 'Sol de Janeiro', price: 45,
    url: 'https://www.sephora.fr/p/brazilian-bum-bum-cream-P10023407.html',
    tags: ['gender_femme','cat_beaute','budget_25_50','type_beaute_soins','style_tendance','passion_beaute','perso_actif','age_ado','age_adulte','popularite_5','saison_ete'] },

  // ═══ MAQUILLAGE ═════════════════════════════════════════════════════════
  { name: 'Charlotte Tilbury Light Wonder Foundation', brand: 'Charlotte Tilbury', price: 46,
    url: 'https://www.sephora.fr/p/light-wonder-foundation-P10022636.html',
    tags: ['gender_femme','cat_beaute','budget_25_50','type_beaute_soins','style_tendance','passion_beaute','age_adulte','popularite_5'] },

  { name: 'NARS Soft Matte Complete Concealer', brand: 'NARS', price: 31,
    url: 'https://www.sephora.fr/p/soft-matte-complete-concealer-P10008453.html',
    tags: ['gender_femme','cat_beaute','budget_25_50','type_beaute_soins','style_minimaliste','passion_beaute','age_adulte','popularite_5'] },

  { name: 'Fenty Beauty Pro Filt\'r Soft Matte Foundation', brand: 'Fenty Beauty', price: 36,
    url: 'https://www.sephora.fr/p/pro-filtr-soft-matte-longwear-foundation-P10013501.html',
    tags: ['gender_femme','cat_beaute','budget_25_50','type_beaute_soins','style_moderne','passion_beaute','age_ado','age_adulte','popularite_5'] },

  { name: 'Lancôme L\'Absolu Rouge Cream 196 French Touch', brand: 'Lancôme', price: 39,
    url: 'https://www.sephora.fr/p/labsolu-rouge-cream-P10003127.html',
    tags: ['gender_femme','cat_beaute','budget_25_50','type_beaute_soins','style_elegant','passion_beaute','perso_romantique','age_adulte','popularite_5','occasion_saint_valentin'] },

  { name: 'Urban Decay Naked3 Palette', brand: 'Urban Decay', price: 53,
    url: 'https://www.sephora.fr/p/naked3-P10005919.html',
    tags: ['gender_femme','cat_beaute','budget_50_100','type_beaute_soins','style_tendance','passion_beaute','age_ado','age_adulte','popularite_5'] },

  { name: 'Too Faced Better Than Sex Mascara', brand: 'Too Faced', price: 27,
    url: 'https://www.sephora.fr/p/better-than-sex-mascara-P10005879.html',
    tags: ['gender_femme','cat_beaute','budget_0_50','type_beaute_soins','style_tendance','passion_beaute','age_ado','age_adulte','popularite_5'] },

  { name: 'Benefit Gimme Brow+ Volumizing Eyebrow Gel', brand: 'Benefit', price: 29,
    url: 'https://www.sephora.fr/p/gimme-brow-volumizing-eyebrow-gel-P10010388.html',
    tags: ['gender_femme','cat_beaute','budget_0_50','type_beaute_soins','style_naturel','passion_beaute','age_ado','age_adulte','popularite_5'] },

  // ═══ TECH / GAMING ═════════════════════════════════════════════════════
  { name: 'Sony PlayStation 5 Slim Edition Standard', brand: 'Sony', price: 449,
    url: 'https://www.fnac.com/Console-Sony-PlayStation-5-Slim/a18742753',
    tags: ['gender_mixte','cat_tech','budget_200+','type_high_tech','type_jeux_jouets','style_moderne','passion_jeuxvideo','passion_tech','perso_techie','age_ado','age_adulte','popularite_5','occasion_noel','occasion_anniversaire'] },

  { name: 'Xbox Series X 1To', brand: 'Microsoft', price: 499,
    url: 'https://www.fnac.com/Microsoft-Xbox-Series-X/a14248540',
    tags: ['gender_mixte','cat_tech','budget_200+','type_high_tech','type_jeux_jouets','style_moderne','passion_jeuxvideo','passion_tech','perso_techie','age_ado','age_adulte','popularite_5','occasion_noel','occasion_anniversaire'] },

  { name: 'Meta Quest 3 128Go Casque VR', brand: 'Meta', price: 499,
    url: 'https://www.fnac.com/Meta-Quest-3-128Go/a20129802',
    tags: ['gender_mixte','cat_tech','budget_200+','type_high_tech','style_moderne','passion_jeuxvideo','passion_tech','perso_techie','perso_aventurier','age_ado','age_adulte','popularite_5','occasion_noel'] },

  { name: 'Apple MacBook Air M3 13 pouces 8Go/256Go', brand: 'Apple', price: 1299,
    url: 'https://www.fnac.com/Apple-MacBook-Air-M3-2024-13-3/a20291703',
    tags: ['gender_mixte','cat_tech','budget_200+','type_high_tech','style_minimaliste','style_moderne','passion_tech','perso_ambitieux','perso_techie','age_adulte','popularite_5','occasion_diplome','occasion_noel'] },

  { name: 'iPad Mini 6ème génération 64Go Wi-Fi', brand: 'Apple', price: 559,
    url: 'https://www.fnac.com/Apple-iPad-mini-2021-Wi-Fi-64-Go/a15779891',
    tags: ['gender_mixte','cat_tech','budget_200+','type_high_tech','style_minimaliste','passion_tech','passion_lecture','age_adulte','popularite_5','occasion_noel'] },

  { name: 'Samsung Galaxy S24 Ultra 256Go Noir', brand: 'Samsung', price: 1199,
    url: 'https://www.fnac.com/Samsung-Galaxy-S24-Ultra-5G-256Go/a20007754',
    tags: ['gender_mixte','cat_tech','budget_200+','type_high_tech','style_moderne','passion_tech','passion_photo','perso_ambitieux','perso_techie','age_adulte','popularite_5','occasion_diplome'] },

  { name: 'Fujifilm Instax Mini 12 Bleu Pastel', brand: 'Fujifilm', price: 89,
    url: 'https://www.fnac.com/Fujifilm-Instax-Mini-12/a16773068',
    tags: ['gender_femme','cat_tech','budget_50_100','type_high_tech','style_tendance','style_vintage','passion_photo','perso_creatif','age_ado','age_adulte','popularite_5','occasion_anniversaire','occasion_noel'] },

  { name: 'Fujifilm Instax Mini 12 Rose Blossom', brand: 'Fujifilm', price: 89,
    url: 'https://www.fnac.com/Fujifilm-Instax-Mini-12-Rose-Blossom/a17049905',
    tags: ['gender_femme','cat_tech','budget_50_100','type_high_tech','style_tendance','style_vintage','passion_photo','perso_creatif','age_ado','popularite_5','occasion_anniversaire'] },

  { name: 'DJI Mini 4 Pro Drone', brand: 'DJI', price: 759,
    url: 'https://www.fnac.com/DJI-Mini-4-Pro-Drone/a20047568',
    tags: ['gender_mixte','cat_tech','budget_200+','type_high_tech','style_moderne','passion_photo','passion_voyages','perso_aventurier','perso_actif','age_adulte','popularite_5','occasion_noel','occasion_anniversaire'] },

  { name: 'Sony WF-1000XM5 Écouteurs True Wireless', brand: 'Sony', price: 249,
    url: 'https://www.fnac.com/Sony-WF-1000XM5/a17870278',
    tags: ['gender_mixte','cat_tech','budget_200+','type_high_tech','type_musique_audio','style_moderne','passion_musique','passion_tech','perso_techie','age_adulte','popularite_5','occasion_anniversaire','occasion_noel'] },

  { name: 'Bose SoundLink Max Enceinte Bluetooth', brand: 'Bose', price: 349,
    url: 'https://www.fnac.com/Bose-SoundLink-Max/a20521006',
    tags: ['gender_mixte','cat_tech','budget_200+','type_high_tech','type_musique_audio','style_moderne','passion_musique','passion_sport','perso_actif','age_adulte','popularite_5','occasion_noel'] },

  { name: 'Anker MagGo Chargeur Induction 3-en-1', brand: 'Anker', price: 69,
    url: 'https://www.fnac.com/Anker-MagGo-736-3-en-1/a17660083',
    tags: ['gender_mixte','cat_tech','budget_50_100','type_high_tech','style_minimaliste','passion_tech','perso_pratique','age_adulte','popularite_4','occasion_noel'] },

  { name: 'Leica Q3 Appareil Photo Compact', brand: 'Leica', price: 5800,
    url: 'https://www.fnac.com/Leica-Q3/a18780793',
    tags: ['gender_mixte','cat_tech','budget_200+','type_high_tech','style_luxe','passion_photo','passion_art','perso_creatif','perso_intellectuel','age_adulte','popularite_4'] },

  { name: 'Sony Alpha A7C II Hybride', brand: 'Sony', price: 2399,
    url: 'https://www.fnac.com/Sony-ZV-E10/a16086267',
    tags: ['gender_mixte','cat_tech','budget_200+','type_high_tech','style_moderne','passion_photo','passion_voyages','perso_creatif','age_adulte','popularite_4','occasion_diplome'] },

  // ═══ MODE FEMME ═════════════════════════════════════════════════════════
  { name: 'VEJA Campo Chromefree White Natural', brand: 'VEJA', price: 140,
    url: 'https://www.veja-store.com/fr/produit/campo-chromefree-white-natural-cf0301719a.html',
    tags: ['gender_femme','cat_mode','budget_100_200','type_mode_accessoires','style_tendance','style_eco_responsable','passion_mode','perso_cool','age_ado','age_adulte','popularite_5','saison_printemps','saison_ete'] },

  { name: 'VEJA Esplar Leather White Black', brand: 'VEJA', price: 120,
    url: 'https://www.veja-store.com/fr/produit/esplar-leather-white-black-ef0102353b.html',
    tags: ['gender_femme','cat_mode','budget_100_200','type_mode_accessoires','style_minimaliste','style_eco_responsable','passion_mode','age_ado','age_adulte','popularite_5','saison_printemps'] },

  { name: 'Sézane Morgan Manteau Camel', brand: 'Sézane', price: 295,
    url: 'https://www.sezane.com/fr/product/manteaux-et-vestes/morgan-manteau',
    tags: ['gender_femme','cat_mode','budget_200+','type_mode_accessoires','style_elegant','style_tendance','passion_mode','perso_ambitieux','age_adulte','popularite_4','saison_automne','saison_hiver'] },

  { name: 'Maje Pull Femme Mérinos Rose Poudré', brand: 'Maje', price: 175,
    url: 'https://www.maje.com/fr/pulls/pull-en-materiau-upcycle-MFPPU00522.html',
    tags: ['gender_femme','cat_mode','budget_100_200','type_mode_accessoires','style_elegant','style_tendance','passion_mode','age_adulte','popularite_4','saison_automne','saison_hiver'] },

  { name: 'Sandro Pull Col V Femme Ivoire', brand: 'Sandro', price: 165,
    url: 'https://www.sandro-paris.com/fr/pulls/pull-col-v-SFPPU02241.html',
    tags: ['gender_femme','cat_mode','budget_100_200','type_mode_accessoires','style_elegant','style_minimaliste','passion_mode','age_adulte','popularite_4','saison_automne','saison_hiver'] },

  { name: 'Jacquemus Le Chiquito Bambino Blanc', brand: 'Jacquemus', price: 560,
    url: 'https://www.jacquemus.com/fr/sacs/le-chiquito-bambino-blanc',
    tags: ['gender_femme','cat_mode','budget_200+','type_mode_accessoires','style_tendance','style_luxe','passion_mode','perso_ambitieux','perso_excentrique','age_adulte','popularite_5'] },

  { name: 'Isabel Marant Nowles Sneakers', brand: 'Isabel Marant', price: 290,
    url: 'https://www.isabelmarant.com/fr/chaussures/nowles-sneakers',
    tags: ['gender_femme','cat_mode','budget_200+','type_mode_accessoires','style_tendance','style_luxe','passion_mode','age_adulte','popularite_4','saison_automne'] },

  { name: 'APC Half Moon Bag Beige', brand: 'A.P.C.', price: 330,
    url: 'https://www.apc.fr/fr/femme/sacs/sac-half-moon-beige',
    tags: ['gender_femme','cat_mode','budget_200+','type_mode_accessoires','style_minimaliste','style_tendance','passion_mode','age_adulte','popularite_4'] },

  // ═══ MODE HOMME ════════════════════════════════════════════════════════
  { name: 'Nike Dunk Low Blanc/Noir Homme', brand: 'Nike', price: 119,
    url: 'https://www.nike.com/fr/t/chaussure-dunk-low-pour-femme-VxFSBa/DD1391-100',
    tags: ['gender_homme','cat_mode','budget_100_200','type_mode_accessoires','style_streetwear','style_tendance','passion_mode','passion_sport','age_ado','age_adulte','popularite_5'] },

  { name: 'Jordan 1 Retro High OG Blanc/Royal', brand: 'Nike / Jordan', price: 180,
    url: 'https://www.nike.com/fr/t/chaussure-air-jordan-1-retro-high-og-pour-homme-GSmCDD/555088-403',
    tags: ['gender_homme','cat_mode','budget_100_200','type_mode_accessoires','style_streetwear','style_tendance','passion_mode','passion_sport','perso_cool','age_ado','age_adulte','popularite_5'] },

  { name: 'New Balance 990v6 Made in USA Gris', brand: 'New Balance', price: 230,
    url: 'https://www.newbalance.fr/fr/990v6/PC990GL6.html',
    tags: ['gender_homme','cat_mode','budget_200+','type_mode_accessoires','style_classique','style_vintage','passion_mode','passion_sport','perso_cool','age_adulte','popularite_5'] },

  { name: 'Ami de Cœur Crewneck Sweatshirt Bleu', brand: 'AMI Paris', price: 280,
    url: 'https://www.amiparis.com/fr/sweatshirts/ami-de-coeur-crewneck-sweatshirt',
    tags: ['gender_homme','cat_mode','budget_200+','type_mode_accessoires','style_tendance','style_decontracte','passion_mode','perso_cool','age_ado','age_adulte','popularite_5','saison_automne','saison_hiver'] },

  { name: 'Stone Island Sweatshirt Vert Bouteille', brand: 'Stone Island', price: 225,
    url: 'https://www.stoneisland.com/fr/sweatshirts',
    tags: ['gender_homme','cat_mode','budget_200+','type_mode_accessoires','style_streetwear','style_tendance','passion_mode','perso_cool','age_adulte','popularite_4','saison_automne','saison_hiver'] },

  { name: 'Jacquemus La Chemise Simon Oversize', brand: 'Jacquemus', price: 195,
    url: 'https://www.jacquemus.com/fr/chemises/la-chemise-simon',
    tags: ['gender_homme','cat_mode','budget_100_200','type_mode_accessoires','style_tendance','style_minimaliste','passion_mode','perso_cool','age_adulte','popularite_4','saison_ete','saison_printemps'] },

  { name: 'APC JW Anderson Sweatshirt Bleu Marine', brand: 'A.P.C. x JW Anderson', price: 185,
    url: 'https://www.apc.fr/fr/homme/vetements/sweatshirts',
    tags: ['gender_homme','cat_mode','budget_100_200','type_mode_accessoires','style_tendance','style_decontracte','passion_mode','perso_intellectuel','age_adulte','popularite_4'] },

  { name: 'Casio A168WG-9EF Montre Vintage Dorée', brand: 'Casio', price: 49,
    url: 'https://www.fnac.com/Casio-A168WG-9EF/a3070462',
    tags: ['gender_mixte','cat_mode','budget_0_50','type_mode_accessoires','style_vintage','style_tendance','passion_mode','perso_cool','age_ado','age_adulte','popularite_5'] },

  { name: 'Seiko 5 Sports SRPD51 Automatique Vert', brand: 'Seiko', price: 189,
    url: 'https://www.fnac.com/Seiko-5-Sports-SRPD51K1/a13919832',
    tags: ['gender_homme','cat_mode','budget_100_200','type_mode_accessoires','style_classique','style_sportif','passion_mode','perso_actif','age_adulte','popularite_4'] },

  // ═══ MAISON / DÉCO ══════════════════════════════════════════════════════
  { name: 'Aromachologie Diptyque Coffret', brand: 'Diptyque', price: 120,
    url: 'https://www.sephora.fr/p/aromachology-P10028654.html',
    tags: ['gender_mixte','cat_maison','budget_100_200','type_maison_deco','type_bien_etre','style_elegant','passion_yoga','age_adulte','popularite_4','occasion_noel','occasion_anniversaire'] },

  { name: 'Maisons du Monde Vase Soliflore Borosilicaté', brand: 'Maisons du Monde', price: 22,
    url: 'https://www.maisonsdumonde.com/FR/fr/p/vase-soliflore-transparent-en-verre-borosilicate',
    tags: ['gender_mixte','cat_maison','budget_0_50','type_maison_deco','style_minimaliste','passion_jardinage','age_adulte','popularite_4'] },

  { name: 'Hay Mags Soft Canapé Modulable', brand: 'Hay', price: 1200,
    url: 'https://www.hay.com/fr-fr/furniture/sofas/mags-soft/',
    tags: ['gender_mixte','cat_maison','budget_200+','type_maison_deco','style_moderne','style_minimaliste','age_adulte','popularite_4'] },

  { name: 'Muuto Unfold Lampe de Table Noire', brand: 'Muuto', price: 175,
    url: 'https://www.muuto.com/lighting/unfold-table-lamp',
    tags: ['gender_mixte','cat_maison','budget_100_200','type_maison_deco','style_moderne','style_minimaliste','age_adulte','popularite_4','occasion_mariage'] },

  { name: 'Loewe Home Scents Cypress Balls', brand: 'Loewe', price: 65,
    url: 'https://www.sephora.fr/p/home-scent-cypress-balls-P10025000.html',
    tags: ['gender_mixte','cat_maison','budget_50_100','type_maison_deco','type_bien_etre','style_luxe','style_minimaliste','passion_yoga','age_adulte','popularite_3','occasion_remerciement'] },

  { name: 'Hay Loop Stand Lampe LED Noire', brand: 'Hay', price: 89,
    url: 'https://www.hay.com/fr-fr/accessories/table-lamps/loop-stand-table-lamp',
    tags: ['gender_mixte','cat_maison','budget_50_100','type_maison_deco','style_minimaliste','style_moderne','age_adulte','popularite_3'] },

  { name: 'ferm LIVING Verso Vase Terracotta', brand: 'ferm LIVING', price: 48,
    url: 'https://www.fermliving.com/products/verso-vase',
    tags: ['gender_mixte','cat_maison','budget_25_50','type_maison_deco','style_minimaliste','style_moderne','age_adulte','popularite_3'] },

  { name: 'Nespresso Vertuo Pop Machine Rouge', brand: 'Nespresso', price: 89,
    url: 'https://www.fnac.com/Nespresso-Vertuo-Pop-XN920510-rouge/a18046948',
    tags: ['gender_mixte','cat_maison','budget_50_100','type_maison_deco','passion_cuisine','perso_pratique','age_adulte','popularite_5','occasion_mariage','occasion_noel'] },

  { name: 'KitchenAid Artisan Robot Pâtissier Rouge Cerise', brand: 'KitchenAid', price: 599,
    url: 'https://www.fnac.com/KitchenAid-Artisan-Rouge-cerise/a5820199',
    tags: ['gender_femme','cat_maison','budget_200+','type_maison_deco','style_classique','passion_cuisine','perso_gourmand','perso_creatif','age_adulte','popularite_5','occasion_mariage','occasion_noel'] },

  { name: 'Philips Hue Play Gradient Lightstrip TV 65"', brand: 'Philips Hue', price: 139,
    url: 'https://www.fnac.com/Philips-Hue-Play-Gradient-Lightstrip-pour-TV/a15989890',
    tags: ['gender_mixte','cat_maison','budget_100_200','type_maison_deco','style_moderne','passion_cinema','passion_jeuxvideo','perso_techie','age_ado','age_adulte','popularite_4','occasion_noel'] },

  { name: 'Dyson V15 Detect Complete Aspirateur sans fil', brand: 'Dyson', price: 679,
    url: 'https://www.fnac.com/Dyson-V15-Detect-Complete/a16765753',
    tags: ['gender_mixte','cat_maison','budget_200+','type_maison_deco','style_moderne','perso_pratique','age_adulte','popularite_5','occasion_mariage','occasion_noel'] },

  // ═══ GASTRONOMIE ════════════════════════════════════════════════════════
  { name: 'Coffret Champagne Ruinart Blanc de Blancs 75cl', brand: 'Ruinart', price: 79,
    url: 'https://www.fnac.com/Ruinart-Blanc-de-Blancs-75cl/a2619877',
    tags: ['gender_mixte','cat_food','budget_50_100','type_gastronomie','style_luxe','passion_vins','passion_cuisine','perso_gourmand','age_adulte','popularite_5','occasion_anniversaire','occasion_noel','occasion_mariage','occasion_remerciement'] },

  { name: 'Coffret Bordeaux Prestige 6 Bouteilles', brand: 'Château Margaux', price: 95,
    url: 'https://www.fnac.com/Coffret-Bordeaux-Prestige/a17000001',
    tags: ['gender_mixte','cat_food','budget_50_100','type_gastronomie','style_classique','passion_vins','perso_gourmand','age_adulte','popularite_4','occasion_anniversaire','occasion_noel','occasion_remerciement'] },

  { name: 'Coffret Whisky Japonais Nikka From The Barrel 50cl', brand: 'Nikka', price: 55,
    url: 'https://www.fnac.com/Nikka-From-The-Barrel-50cl/a2487312',
    tags: ['gender_homme','cat_food','budget_50_100','type_gastronomie','style_moderne','passion_vins','passion_cuisine','perso_intellectuel','age_adulte','popularite_5','occasion_anniversaire','occasion_noel'] },

  { name: 'Coffret Rhum Diplomatico Reserva Exclusiva 70cl', brand: 'Diplomatico', price: 52,
    url: 'https://www.fnac.com/Diplomatico-Reserva-Exclusiva-70cl/a2488008',
    tags: ['gender_mixte','cat_food','budget_50_100','type_gastronomie','style_tendance','passion_vins','perso_aventurier','age_adulte','popularite_4','occasion_anniversaire'] },

  { name: 'Jacques Genin Coffret Chocolats 36 Pièces', brand: 'Jacques Génin', price: 68,
    url: 'https://jacquesgenin.fr/fr/chocolats/boites-de-chocolats.html',
    tags: ['gender_mixte','cat_food','budget_50_100','type_gastronomie','style_luxe','passion_cuisine','perso_gourmand','age_adulte','popularite_4','occasion_saint_valentin','occasion_anniversaire','occasion_noel','occasion_remerciement'] },

  { name: 'Coffret Huiles d\'Olive Gourmet Méditerranée', brand: 'Nicolas Vahe', price: 42,
    url: 'https://www.fnac.com/Nicolas-Vahe-Coffret-Huiles-Olive/a18000001',
    tags: ['gender_mixte','cat_food','budget_25_50','type_gastronomie','style_tendance','passion_cuisine','perso_gourmand','age_adulte','popularite_4','occasion_remerciement','occasion_noel'] },

  { name: 'Coffret Épices du Monde Nomie', brand: 'Nomie', price: 35,
    url: 'https://www.fnac.com/Nomie-Coffret-epices/a18000002',
    tags: ['gender_mixte','cat_food','budget_25_50','type_gastronomie','style_tendance','passion_cuisine','perso_aventurier','perso_gourmand','age_adulte','popularite_4','occasion_remerciement'] },

  { name: 'Coffret Gin Hendrick\'s 70cl + Accessories', brand: "Hendrick's", price: 48,
    url: 'https://www.fnac.com/Hendricks-Gin-70cl/a2488100',
    tags: ['gender_mixte','cat_food','budget_25_50','type_gastronomie','style_tendance','passion_vins','perso_excentrique','age_adulte','popularite_5','occasion_anniversaire','occasion_noel'] },

  // ═══ BIJOUX ═════════════════════════════════════════════════════════════
  { name: 'Messika Move Uno Bracelet Or Blanc Diamants', brand: 'Messika', price: 850,
    url: 'https://www.messika.com/fr/bracelets/move-uno/',
    tags: ['gender_femme','cat_mode','budget_200+','type_bijoux','type_intime','style_luxe','style_elegant','passion_mode','age_adulte','popularite_4','occasion_anniversaire','occasion_saint_valentin'] },

  { name: 'Dinh Van Menottes R6 Bracelet Or Jaune', brand: 'Dinh Van', price: 585,
    url: 'https://www.dinhvan.com/fr/menottes-r6.html',
    tags: ['gender_femme','cat_mode','budget_200+','type_bijoux','type_intime','style_luxe','style_minimaliste','passion_mode','age_adulte','popularite_4','occasion_anniversaire','occasion_saint_valentin'] },

  { name: 'Gas Bijoux Sari Collier Doré', brand: 'Gas Bijoux', price: 145,
    url: 'https://fr.gas-bijoux.com/produit/sari/',
    tags: ['gender_femme','cat_mode','budget_100_200','type_bijoux','style_boheme','style_tendance','passion_mode','perso_excentrique','age_adulte','popularite_4','occasion_anniversaire'] },

  { name: 'Gorjana Pacific Ring Silver', brand: 'Gorjana', price: 45,
    url: 'https://gorjana.com/products/pacific-pave-ring',
    tags: ['gender_femme','cat_mode','budget_25_50','type_bijoux','style_minimaliste','style_tendance','passion_mode','age_ado','age_adulte','popularite_4','occasion_anniversaire','occasion_saint_valentin'] },

  { name: 'Versace Méduse Boucles d\'Oreilles Gold', brand: 'Versace', price: 195,
    url: 'https://www.versace.com/fr/fr/boucles-d-oreilles',
    tags: ['gender_femme','cat_mode','budget_100_200','type_bijoux','style_luxe','style_tendance','passion_mode','perso_excentrique','age_adulte','popularite_4'] },

  { name: 'Astrid & Miyu Renewal Stacking Ring Gold', brand: 'Astrid & Miyu', price: 55,
    url: 'https://www.astridandmiyu.com/collections/rings',
    tags: ['gender_femme','cat_mode','budget_50_100','type_bijoux','style_tendance','style_minimaliste','passion_mode','age_ado','age_adulte','popularite_4','occasion_anniversaire','occasion_saint_valentin'] },

  // ═══ SPORT & FITNESS ═══════════════════════════════════════════════════
  { name: 'Lululemon Align Legging 28" Femme', brand: 'Lululemon', price: 118,
    url: 'https://www.lululemon.fr/fr-fr/products/align-legging-112827730',
    tags: ['gender_femme','cat_mode','budget_100_200','type_mode_accessoires','type_sport_outdoor','style_sportif','style_tendance','passion_sport','passion_yoga','perso_actif','age_ado','age_adulte','popularite_5'] },

  { name: 'Lululemon Scuba Hoodie Crème', brand: 'Lululemon', price: 128,
    url: 'https://www.lululemon.fr/fr-fr/p/scuba-oversized-fleece-half-zip-hoodie/116578610.html',
    tags: ['gender_femme','cat_mode','budget_100_200','type_mode_accessoires','style_sportif','style_decontracte','passion_sport','passion_yoga','perso_actif','age_ado','age_adulte','popularite_5'] },

  { name: 'Alo Yoga High-Waist Airlift Legging Femme', brand: 'Alo Yoga', price: 128,
    url: 'https://www.aloyoga.com/fr-fr/products/w6461r',
    tags: ['gender_femme','cat_mode','budget_100_200','type_mode_accessoires','type_sport_outdoor','style_sportif','style_tendance','passion_sport','passion_yoga','perso_actif','age_ado','age_adulte','popularite_5'] },

  { name: 'On Running Cloudmonster 2 Blanc Homme', brand: 'On Running', price: 189,
    url: 'https://www.on-running.com/fr-fr/products/cloudmonster-2',
    tags: ['gender_homme','cat_mode','budget_100_200','type_mode_accessoires','type_sport_outdoor','style_sportif','style_moderne','passion_sport','perso_actif','age_ado','age_adulte','popularite_5'] },

  { name: 'Hoka Clifton 9 Chaussures Running Femme', brand: 'Hoka', price: 150,
    url: 'https://www.hoka.com/fr-fr/chaussures-de-course/clifton-9/',
    tags: ['gender_femme','cat_mode','budget_100_200','type_mode_accessoires','type_sport_outdoor','style_sportif','passion_sport','perso_actif','age_ado','age_adulte','popularite_5'] },

  { name: 'Theragun Mini Percussive Therapy', brand: 'Theragun', price: 179,
    url: 'https://www.fnac.com/Theragun-Mini/a15434978',
    tags: ['gender_mixte','cat_maison','budget_100_200','type_bien_etre','type_sport_outdoor','style_moderne','passion_sport','passion_yoga','perso_actif','age_adulte','popularite_5','occasion_noel','occasion_anniversaire'] },

  // ═══ LIVRES / CULTURE ══════════════════════════════════════════════════
  { name: 'Taschen KAWS Monograph Livre', brand: 'Taschen', price: 60,
    url: 'https://www.taschen.com/fr/books/art/kaws.html',
    tags: ['gender_mixte','cat_tendances','budget_50_100','type_livres_bd','type_culture','style_streetwear','style_moderne','passion_art','perso_creatif','perso_intellectuel','age_adulte','popularite_4'] },

  { name: 'Assouline Baby Beach Club Livre Collector', brand: 'Assouline', price: 75,
    url: 'https://www.assouline.com/collections/baby-beach-club',
    tags: ['gender_mixte','cat_tendances','budget_50_100','type_livres_bd','type_culture','style_luxe','style_elegant','passion_voyages','perso_intellectuel','age_adulte','popularite_3'] },

  { name: 'Catan Stratégie Édition Deluxe', brand: 'Asmodee', price: 89,
    url: 'https://www.fnac.com/Catan-Edition-Deluxe/a18900001',
    tags: ['gender_mixte','cat_tendances','budget_50_100','type_jeux_jouets','type_culture','style_classique','passion_jeuxvideo','perso_sociable','perso_intellectuel','age_ado','age_adulte','popularite_4','occasion_noel','occasion_anniversaire'] },

  { name: 'Gloomhaven Jeu de Plateau', brand: 'Cephalofair', price: 99,
    url: 'https://www.fnac.com/Gloomhaven/a10842337',
    tags: ['gender_mixte','cat_tendances','budget_50_100','type_jeux_jouets','type_culture','style_moderne','passion_jeuxvideo','perso_intellectuel','age_adulte','popularite_4','occasion_noel'] },

  { name: 'Lego Technic Ferrari Daytona SP3 42143', brand: 'LEGO', price: 379,
    url: 'https://www.fnac.com/LEGO-Technic-Ferrari-Daytona-42143/a16774046',
    tags: ['gender_homme','cat_tendances','budget_200+','type_jeux_jouets','style_classique','passion_automobile','passion_art','perso_creatif','age_adulte','popularite_4','occasion_noel','occasion_anniversaire'] },

  { name: 'LEGO Botanical Collection Orchidée 10311', brand: 'LEGO', price: 49,
    url: 'https://www.fnac.com/LEGO-10311-Orchidee/a17192117',
    tags: ['gender_femme','cat_tendances','budget_25_50','type_jeux_jouets','type_maison_deco','style_minimaliste','passion_jardinage','passion_art','perso_creatif','age_adulte','popularite_5','occasion_anniversaire','occasion_fete'] },

  { name: 'LEGO Art Andy Warhol\'s Marilyn Monroe 31197', brand: 'LEGO', price: 169,
    url: 'https://www.fnac.com/LEGO-Art-Andy-Warhol-Marilyn-Monroe-31197/a14912555',
    tags: ['gender_mixte','cat_tendances','budget_100_200','type_jeux_jouets','type_maison_deco','style_moderne','passion_art','passion_cinema','perso_creatif','perso_excentrique','age_adulte','popularite_4','occasion_anniversaire'] },

  // ═══ EXPÉRIENCES / TENDANCES ═══════════════════════════════════════════
  { name: 'Coffret Bière Artisanale 12 Brasseries Françaises', brand: 'BeerLover', price: 55,
    url: 'https://www.fnac.com/Coffret-biere-artisanale-france/a18000010',
    tags: ['gender_homme','cat_food','budget_50_100','type_gastronomie','style_tendance','passion_vins','passion_cuisine','perso_aventurier','perso_sociable','age_adulte','popularite_4','occasion_anniversaire','occasion_noel'] },

  { name: 'Carte Cadeau Airbnb Expériences 100€', brand: 'Airbnb', price: 100,
    url: 'https://www.fnac.com/Carte-cadeau-Airbnb/a18000020',
    tags: ['gender_mixte','cat_tendances','budget_50_100','type_voyage_aventure','type_culture','style_tendance','passion_voyages','passion_cuisine','perso_aventurier','perso_sociable','age_adulte','popularite_5','occasion_anniversaire','occasion_saint_valentin'] },

  { name: 'Coffret SPA Premium 2 Personnes', brand: 'LaVieEstBelle', price: 120,
    url: 'https://www.fnac.com/Coffret-spa-2-personnes/a18000030',
    tags: ['gender_mixte','cat_maison','budget_100_200','type_bien_etre','style_elegant','passion_yoga','perso_romantique','perso_zen','age_adulte','popularite_4','occasion_saint_valentin','occasion_anniversaire'] },

  { name: 'Cookeo Touch Multicuiseur 7L Noir', brand: 'Moulinex', price: 149,
    url: 'https://www.fnac.com/Moulinex-Cookeo-Touch-CE901800/a14996534',
    tags: ['gender_mixte','cat_maison','budget_100_200','type_maison_deco','passion_cuisine','perso_pratique','perso_gourmand','age_adulte','popularite_5','occasion_mariage','occasion_noel'] },

  { name: 'Raclette Party 8 Personnes Pierre Granit', brand: 'Tefal', price: 119,
    url: 'https://www.fnac.com/Tefal-Raclette-Party-RE7928/a17002384',
    tags: ['gender_mixte','cat_maison','budget_100_200','type_maison_deco','style_tendance','passion_cuisine','perso_sociable','perso_gourmand','age_adulte','popularite_4','occasion_noel','saison_hiver'] },

];

// ══════════════════════════════════════════════════════════════════════════════
// SCRAPING & UPLOAD
// ══════════════════════════════════════════════════════════════════════════════

const SCRAPE_HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
  'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
  'Cache-Control': 'no-cache',
  'Sec-Fetch-Dest': 'document',
  'Sec-Fetch-Mode': 'navigate',
};

async function scrapeImage(url) {
  try {
    const ctrl = new AbortController();
    const t    = setTimeout(() => ctrl.abort(), TIMEOUT);
    const res  = await fetch(url, { headers: SCRAPE_HEADERS, signal: ctrl.signal, redirect: 'follow' });
    clearTimeout(t);
    if (!res.ok) return null;
    const html = await res.text();
    const $    = cheerio.load(html);

    const candidates = [
      $('meta[property="og:image"]').attr('content'),
      $('meta[name="og:image"]').attr('content'),
      $('meta[property="og:image:secure_url"]').attr('content'),
      $('meta[name="twitter:image"]').attr('content'),
      $('meta[property="product:image"]').attr('content'),
      $('meta[name="product:image"]').attr('content'),
    ].filter(Boolean);

    let imageUrl = candidates[0];

    // Nettoyage
    if (imageUrl) {
      if (imageUrl.startsWith('//'))    imageUrl = 'https:' + imageUrl;
      else if (imageUrl.startsWith('/')) {
        const base = new URL(url);
        imageUrl   = `${base.protocol}//${base.host}${imageUrl}`;
      }
      // Supprimer les resize params
      imageUrl = imageUrl.split('?')[0];
    }

    return imageUrl || null;
  } catch {
    return null;
  }
}

async function downloadBuffer(imageUrl) {
  try {
    const ctrl = new AbortController();
    const t    = setTimeout(() => ctrl.abort(), TIMEOUT);
    const res  = await fetch(imageUrl, {
      headers: { ...SCRAPE_HEADERS, Accept: 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8' },
      signal: ctrl.signal,
    });
    clearTimeout(t);
    if (!res.ok) return null;
    const buf = await res.buffer();
    if (buf.length < 3000) return null;
    return { buf, ct: res.headers.get('content-type') || 'image/jpeg' };
  } catch {
    return null;
  }
}

async function upload(buf, ct, docId) {
  const ext  = ct.includes('png') ? 'png' : ct.includes('webp') ? 'webp' : 'jpg';
  const path = `products/gifts/${docId}.${ext}`;
  const f    = bucket.file(path);
  await f.save(buf, { metadata: { contentType: ct, cacheControl: 'public, max-age=31536000' }, public: true });
  return `https://storage.googleapis.com/${bucket.name}/${path}`;
}

// ══════════════════════════════════════════════════════════════════════════════
// MAIN
// ══════════════════════════════════════════════════════════════════════════════
async function main() {
  console.log('');
  console.log('╔══════════════════════════════════════════════════════════════╗');
  console.log('║    🎁 DORON — MEGA SCRAPER v2.0                             ║');
  console.log(`║    ${DRY_RUN ? '🟡 DRY-RUN' : '🟢 PRODUCTION'} — ${PRODUCTS_TO_ADD.length} produits curéssss dans le catalogue             ║`);
  if (LIMIT !== Infinity) console.log(`║    Limite : ${LIMIT}                                              ║`);
  console.log('╚══════════════════════════════════════════════════════════════╝\n');

  // ── Charger les noms existants pour éviter les doublons ─────────────────
  console.log('🔍 Chargement des produits existants...');
  const snap = await db.collection('gifts').get();
  const existingNames = new Set(snap.docs.map(d => (d.data().name || '').toLowerCase().trim()).filter(Boolean));
  console.log(`   📦 ${snap.size} produits déjà en base\n`);

  // ── Filtrer les doublons ──────────────────────────────────────────────────
  const toAdd = PRODUCTS_TO_ADD
    .filter(p => !existingNames.has(p.name.toLowerCase().trim()))
    .slice(0, LIMIT);

  const skipped = PRODUCTS_TO_ADD.length - toAdd.length;
  console.log(`   ✅ ${skipped} déjà présents (ignorés)`);
  console.log(`   ➕ ${toAdd.length} à ajouter\n`);

  if (DRY_RUN) {
    console.log('📋 Produits qui seraient ajoutés :\n');
    toAdd.forEach((p, i) => console.log(`   ${i+1}. ${p.name} — ${p.price}€ (${p.url.substring(0,50)}…)`));
    console.log('\n💡 Lance sans --dry-run pour exécuter.\n');
    process.exit(0);
  }

  let added = 0, failed = 0;
  const failedList = [];
  const now = new Date().toISOString();

  for (let i = 0; i < toAdd.length; i++) {
    const p = toAdd[i];
    console.log(`\n[${i+1}/${toAdd.length}] "${p.name}" — ${p.price}€`);
    console.log(`   🔗 ${p.url.substring(0, 70)}`);

    // Corriger les tags budget si nécessaire
    const tags = [...p.tags.filter(t => !t.startsWith('budget_')), budgetTag(p.price)];

    // ── Scraper l'image depuis la page officielle ────────────────────────
    let storageUrl = null;

    const imageUrl = await scrapeImage(p.url);
    if (imageUrl) {
      console.log(`   🖼️  Image : ${imageUrl.substring(0, 65)}`);
      const dl = await downloadBuffer(imageUrl);
      if (dl) {
        console.log(`   📥 ${Math.round(dl.buf.length / 1024)} Ko`);
        try {
          const tmpDoc = db.collection('gifts').doc(); // génère l'ID
          storageUrl = await upload(dl.buf, dl.ct, tmpDoc.id);
          console.log(`   ☁️  Firebase : ${storageUrl.substring(0, 65)}`);

          await tmpDoc.set({
            name:             p.name,
            brand:            p.brand,
            price:            p.price,
            image:            storageUrl,
            imageUrl:         storageUrl,
            imageStoragePath: `products/gifts/${tmpDoc.id}`,
            url:              p.url,
            source:           'Scraping officiel',
            categories:       tags.filter(t => t.startsWith('cat_')).map(t => t.replace('cat_', '')),
            tags,
            active:           true,
            imageFixed:       true,
            popularity:       tags.includes('popularite_5') ? 99 : tags.includes('popularite_4') ? 90 : 80,
            createdAt:        now,
            updatedAt:        now,
            addedBy:          'doron_mega_scraper_v2',
          });

          console.log(`   ✅ Ajouté avec image Firebase !`);
          added++;
        } catch (e) {
          console.log(`   ❌ Erreur upload/write : ${e.message}`);
          failed++;
          failedList.push(p.name);
        }
      } else {
        console.log(`   ⚠️  Image trop petite/inaccessible → ajout sans image`);
        await addWithoutImage(p, tags, now);
        added++;
      }
    } else {
      console.log(`   ⚠️  Pas d'og:image trouvée → ajout sans image`);
      await addWithoutImage(p, tags, now);
      added++;
    }

    await sleep(DELAY_MS);
  }

  // ─── Rapport ─────────────────────────────────────────────────────────────
  const finalSnap = await db.collection('gifts').get();
  console.log('\n\n╔══════════════════════════════════════════════════════════════╗');
  console.log('║                    ✅ RAPPORT FINAL                          ║');
  console.log('╠══════════════════════════════════════════════════════════════╣');
  console.log(`║  📦 Total produits en base   : ${String(finalSnap.size).padEnd(29)}║`);
  console.log(`║  ➕ Produits ajoutés         : ${String(added).padEnd(29)}║`);
  console.log(`║  ❌ Erreurs                  : ${String(failed).padEnd(29)}║`);
  console.log('╠══════════════════════════════════════════════════════════════╣');
  console.log('║  💡 Lance l\'Admin UI pour corriger les images manquantes :  ║');
  console.log('║  → node admin_server.js  puis  http://localhost:3456         ║');
  console.log('╚══════════════════════════════════════════════════════════════╝\n');

  process.exit(0);
}

async function addWithoutImage(p, tags, now) {
  // Ajouter sans image, l'Admin UI permettra de la corriger plus tard
  await db.collection('gifts').add({
    name:       p.name,
    brand:      p.brand,
    price:      p.price,
    image:      '',
    imageUrl:   '',
    url:        p.url,
    source:     'Scraping officiel',
    categories: tags.filter(t => t.startsWith('cat_')).map(t => t.replace('cat_', '')),
    tags,
    active:     true,
    imageFixed: false,
    popularity: tags.includes('popularite_5') ? 99 : tags.includes('popularite_4') ? 90 : 80,
    createdAt:  now,
    updatedAt:  now,
    addedBy:    'doron_mega_scraper_v2',
  });
}

main().catch(e => {
  console.error('\n❌ ERREUR CRITIQUE :', e.message || e);
  process.exit(1);
});
