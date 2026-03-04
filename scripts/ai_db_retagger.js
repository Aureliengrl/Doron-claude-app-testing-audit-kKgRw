/**
 * Script IA de Retagging Firebase (Doron)
 *
 * Exécution:
 * 1. npm install firebase-admin openai dotenv
 * 2. Mettez votre serviceAccountKey.json dans ce dossier
 * 3. Créez un fichier .env avec OPENAI_API_KEY=sk-votreclé
 * 4. node ai_db_retagger.js
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

// Prompt système pour l'IA
const SYSTEM_PROMPT = `
Tu es un expert en e-commerce et catégorisation pour l'application Doron.
Ta mission est d'assigner les tags exacts à un produit donné en te basant sur son nom, sa description et son prix.

Voici les règles STRICTES pour les tags :

1. Sexe (1 seul) : gender_femme, gender_homme, gender_mixte
2. Âge (1 max) : age_enfant (<13), age_ado (13-24), age_adulte (25-54), age_senior (55+)
3. Budget (1 seul, basé sur le prix) : budget_0_50 (<50€), budget_50_100 (50-100€), budget_100_200 (100-200€), budget_200+
4. Catégorie principale (1 seul) : cat_tendances, cat_tech, cat_mode, cat_maison, cat_beaute, cat_food
5. Type de cadeau (1 à 3 max) : type_mode_accessoires, type_bien_etre, type_sport_outdoor, type_gastronomie, type_culture, type_high_tech, type_maison_deco, type_beaute_soins, type_loisirs_creatifs, type_jeux_jouets, type_livres_bd, type_musique_audio, type_voyage_aventure, type_automobile, type_bijoux, type_intime
6. Style (1 à 3 max) : style_elegant, style_tendance, style_minimaliste, style_classique, style_decontracte, style_sportif, style_vintage, style_moderne, style_luxe, style_boheme, style_streetwear, style_eco_responsable

Retourne UNIQUEMENT un tableau JSON valide contenant les strings des tags applicables. Pas de markdown, pas d'explication.
Exemple de sortie : ["gender_femme", "age_adulte", "budget_50_100", "cat_beaute", "type_beaute_soins", "style_elegant"]
`;

async function retagProduct(doc) {
    const data = doc.data();
    const title = data.name || data.product_title || '';
    const desc = data.description || '';
    const price = data.price || 0;

    const prompt = `Produit: ${title}\nDescription: ${desc}\nPrix: ${price}€\nAssigne les tags.`;

    try {
        const response = await openai.chat.completions.create({
            model: "gpt-4o-mini",
            messages: [
                { role: "system", content: SYSTEM_PROMPT },
                { role: "user", content: prompt }
            ],
            temperature: 0.1,
        });

        const content = response.choices[0].message.content.trim();
        const tagsArray = JSON.parse(content);

        // Mettre à jour Firebase
        await doc.ref.update({
            tags: tagsArray,
            ai_retagged: true,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log(`✅ [${doc.id}] ${title} → ${tagsArray.length} tags assignés`);
    } catch (e) {
        console.error(`❌ Erreur IA pour [${doc.id}] ${title}:`, e.message);
    }
}

async function main() {
    console.log('🚀 Démarrage du Retagging IA...');

    if (!process.env.OPENAI_API_KEY) {
        console.error('❌ OPENAI_API_KEY manquante dans le fichier .env');
        process.exit(1);
    }

    const snapshot = await db.collection('gifts').where('ai_retagged', '!=', true).get();
    console.log(`📦 ${snapshot.size} produits à retagger.`);

    for (const doc of snapshot.docs) {
        await retagProduct(doc);
        // Pause pour éviter les rate limits (facultatif si usage de batch)
        await new Promise(r => setTimeout(r, 500));
    }

    console.log('🎉 Terminé !');
}

main();
