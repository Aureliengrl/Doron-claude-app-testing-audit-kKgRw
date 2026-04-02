/**
 * Script IA de Génération de Cadeaux (Doron)
 *
 * Exécution:
 * 1. npm install firebase-admin openai dotenv
 * 2. Mettez votre serviceAccountKey.json dans ce dossier
 * 3. Créez un fichier .env avec OPENAI_API_KEY=sk-votreclé
 * 4. node ai_gifts_generator.js
 */

const admin = require('firebase-admin');
const { OpenAI } = require('openai');
require('dotenv').config();

// Initialisation Firebase
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});
const db = admin.firestore();

// Initialisation OpenAI
const openai = new OpenAI({
    apiKey: process.env.OPENAI_API_KEY,
});

const BATCH_SIZE = 20; // 20 cadeaux par batch
const TOTAL_TO_GENERATE = 1000;

// Prompt de génération
const SYSTEM_PROMPT = `
Tu es un expert mondial en e-commerce et en idées cadeaux pour l'application Doron.
Génère une liste JSON de ${BATCH_SIZE} idées de cadeaux uniques, PREMIUM et originaux (pas de banalité comme une tasse classique).
Ton JSON doit UNIQUEMENT contenir un tableau d'objets, aucun texte additionnel, aucune balise de code markdown.

Chaque objet doit respecter ce schéma exact :
{
  "name": "Nom du Produit Court et Accrocheur (Marque + Produit)",
  "description": "Description premium, évoquant l'émotion ou l'utilité du cadeau en 2 phrases max.",
  "price": 120, // Nombre entier (en euros)
  "brand": "Nom de la marque",
  "url": "https://www.exemple.com", // Une URL PLAUSIBLE vers le produit officiel
  "image": "https://images.unsplash.com/photo-1...", // Une image Unsplash valide en rapport avec le produit
  "active": true,
  "popularity": 85, // Entre 60 et 100
  "isAIGenerated": true,
  "tags": [
    "gender_femme", 
    "age_adulte", 
    "cat_mode", 
    "budget_100_200", 
    "type_mode_accessoires", 
    "style_elegant"
  ] // MINIMUM 6 tags valides obligatoires parmi les tags officiels (gender, age, budget, cat, type, style, perso, passion). N'invente AUCUN tag qui ne respecte pas le dictionnaire officiel de Doron (ex: gender_femme, gender_homme, gender_mixte / cat_tendances, cat_tech, cat_mode, cat_maison, cat_beaute, cat_food / budget_0_50, budget_50_100, budget_100_200, budget_200+).
}

Varier les budgets (0-50, 50-100, 100-200, 200+), les genres (homme, femme, mixte, enfant) et les catégories (tech, mode, beauté, maison, food).
`;

async function generateBatch(batchNumber) {
    console.log(`\n🧠 Génération du batch ${batchNumber} via OpenAI...`);
    try {
        const response = await openai.chat.completions.create({
            model: "gpt-4o",
            messages: [
                { role: "system", content: SYSTEM_PROMPT },
                { role: "user", content: `Génère ${BATCH_SIZE} nouveaux cadeaux exclusifs pour ce batch. Évite les doublons avec ce qui a déjà été produit.` }
            ],
            temperature: 0.8,
        });

        let content = response.choices[0].message.content.trim();
        if (content.startsWith('\`\`\`json')) {
            content = content.replace('\`\`\`json', '').replace('\`\`\`', '').trim();
        } else if (content.startsWith('\`\`\`')) {
            content = content.replace(/\`\`\`/g, '').trim();
        }

        const products = JSON.parse(content);

        console.log(`✅ ${products.length} produits générés par l'IA. Enregistrement dans Firebase...`);

        let saved = 0;
        for (const p of products) {
            if (!p.name || !p.price || !p.tags || p.tags.length < 5) continue;

            p.createdAt = admin.firestore.FieldValue.serverTimestamp();
            await db.collection('gifts').add(p);
            saved++;
        }

        console.log(`🔥 ${saved} produits insérés correctement dans Firestore.`);
        return saved;

    } catch (e) {
        console.error(`❌ Erreur IA pour le batch ${batchNumber}:`, e.message);
        return 0;
    }
}

async function main() {
    console.log('🚀 Démarrage de la Génération Massive de Cadeaux IA...');

    if (!process.env.OPENAI_API_KEY) {
        console.error('❌ OPENAI_API_KEY manquante dans le fichier .env');
        process.exit(1);
    }

    const numBatches = Math.ceil(TOTAL_TO_GENERATE / BATCH_SIZE);
    let totalSaved = 0;

    for (let i = 1; i <= numBatches; i++) {
        const saved = await generateBatch(i);
        totalSaved += saved;
        console.log(`📊 Progression globale : ${totalSaved}/${TOTAL_TO_GENERATE} cadeaux.`);

        // Pause pour éviter les rate limits (5 secondes)
        console.log('⏳ Pause de sécurité pour les quotas OpenAI...');
        await new Promise(r => setTimeout(r, 5000));
    }

    console.log('🎉 Terminé ! ' + totalSaved + ' nouveaux cadeaux ajoutés.');
}

main();
