const admin = require('firebase-admin');

// Initialisation Firebase
if (!admin.apps.length) {
    const serviceAccount = require('./serviceAccountKey.json');
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
}
const db = admin.firestore();

// ============================================================================
// SIMULATEUR DU MOTEUR DE RECHERCHE (Strictement identique au Dart)
// ============================================================================
function calculateMatchScore(product, searchTagsArray, userTags, mode = 'person') {
    let score = 0;
    const allProductTags = product.tags || [];

    // 1. GENRE
    const userGenderTags = searchTagsArray.filter(t => t.startsWith('gender_'));
    const productGenderTags = allProductTags.filter(t => t.startsWith('gender_'));

    if (userGenderTags.length > 0) {
        const userGender = userGenderTags[0];
        if (productGenderTags.length === 0) {
            score += 50.0;
        } else if (productGenderTags.includes(userGender)) {
            score += 100.0;
        } else if (productGenderTags.includes('gender_mixte')) {
            score += 70.0;
        } else {
            if (mode === 'person' || mode === 'home') {
                return -10000.0; // EXCLUSION STRICTE
            } else {
                score -= 30.0;
            }
        }
    } else {
        score += 50.0;
    }

    // 2. ÂGE
    const age = userTags.age || userTags.recipientAge;
    if (age) {
        const ageInt = parseInt(age, 10) || 0;
        if (ageInt > 0) {
            let userAgeTag;
            if (ageInt < 13) userAgeTag = 'age_enfant';
            else if (ageInt < 25) userAgeTag = 'age_ado';
            else if (ageInt < 55) userAgeTag = 'age_adulte';
            else userAgeTag = 'age_senior';

            const productAgeTags = allProductTags.filter(t => t.startsWith('age_'));
            if (productAgeTags.length > 0) {
                if (productAgeTags.includes(userAgeTag)) {
                    score += 50.0;
                } else {
                    score -= 15.0;
                }
            } else {
                score += 10.0;
            }
        }
    }

    // 3. CATÉGORIE
    const userCategoryTags = searchTagsArray.filter(t => t.startsWith('cat_'));
    if (userCategoryTags.length > 0) {
        const userCategory = userCategoryTags[0];
        const productCategoryTags = allProductTags.filter(t => t.startsWith('cat_'));

        if (productCategoryTags.length === 0) {
            score += 20.0;
        } else if (productCategoryTags.includes(userCategory.toLowerCase())) {
            score += 80.0;
        } else {
            score -= (mode === 'home') ? 45.0 : 30.0;
        }
    }

    // 4. BUDGET
    const userBudgetTags = searchTagsArray.filter(t => t.startsWith('budget_'));
    if (userBudgetTags.length > 0) {
        const userBudget = userBudgetTags[0];
        const productBudgetTags = allProductTags.filter(t => t.startsWith('budget_'));

        if (productBudgetTags.length === 0) {
            const price = product.price || 0;
            let calculatedBudget = 'budget_0_50';
            if (price >= 50 && price <= 100) calculatedBudget = 'budget_50_100';
            else if (price > 100 && price <= 200) calculatedBudget = 'budget_100_200';
            else if (price > 200) calculatedBudget = 'budget_200+';

            if (calculatedBudget === userBudget) score += 60.0;
            else score -= (mode === 'home') ? 30.0 : 20.0;
        } else if (productBudgetTags.includes(userBudget.toLowerCase())) {
            score += 60.0;
        } else {
            score -= (mode === 'home') ? 30.0 : 20.0;
        }
    }

    // 5. STYLES
    const userStyleTags = searchTagsArray.filter(t => t.startsWith('style_'));
    if (userStyleTags.length > 0) {
        let matches = 0;
        for (let s of userStyleTags) {
            if (allProductTags.includes(s.toLowerCase())) matches++;
        }
        score += Math.min(matches * 20.0, 40.0);
    }

    // 6. PERSONNALITÉS
    const userPersoTags = searchTagsArray.filter(t => t.startsWith('perso_'));
    if (userPersoTags.length > 0) {
        let matches = 0;
        for (let s of userPersoTags) {
            if (allProductTags.includes(s.toLowerCase())) matches++;
        }
        score += Math.min(matches * 15.0, 30.0);
    }

    // 7. PASSIONS
    const userPassionTags = searchTagsArray.filter(t => t.startsWith('passion_'));
    if (userPassionTags.length > 0) {
        let matches = 0;
        for (let s of userPassionTags) {
            if (allProductTags.includes(s.toLowerCase())) matches++;
        }
        score += Math.min(matches * 25.0, 50.0);
    }

    // 8. TYPES
    const userTypeTags = searchTagsArray.filter(t => t.startsWith('type_'));
    if (userTypeTags.length > 0) {
        let matches = 0;
        for (let s of userTypeTags) {
            if (allProductTags.includes(s.toLowerCase())) matches++;
        }
        score += Math.min(matches * 15.0, 30.0);
    }

    // 9. LOCATION
    const loc = userTags.location;
    if (loc) {
        const locStr = loc.toLowerCase();
        const isActivity = allProductTags.some(t =>
            ['type_voyage_aventure', 'type_bien_etre', 'type_gastronomie', 'type_culture'].includes(t)
        );
        if (isActivity) {
            const n = (product.name || '').toLowerCase();
            const d = (product.description || '').toLowerCase();
            const parts = locStr.replace(/[()]/g, ' ').split(' ').filter(p => p.length > 3);
            for (let part of parts) {
                if (n.includes(part) || d.includes(part) || allProductTags.includes(part)) {
                    score += 150.0;
                    break;
                }
            }
        }
    }

    // Popularity
    const pop = product.popularity || 0;
    if (pop > 0) {
        score += Math.min(pop * 0.2, 20.0);
    }

    return score;
}

// ============================================================================
// TESTS (PERSONAS)
// ============================================================================
const TEST_CASES = [
    {
        name: "Persona 1 : Homme, 25 ans, Budget 100-200€, Passion Gaming/Tech",
        tags: ["gender_homme", "budget_100_200", "cat_tech", "passion_gaming", "passion_high_tech"],
        userDict: { age: 25 }
    },
    {
        name: "Persona 2 : Femme, 42 ans, Budget 200€+, L'Épicurienne, Luxe",
        tags: ["gender_femme", "budget_200+", "cat_luxe", "perso_epicurien", "passion_gastronomie", "style_elegant"],
        userDict: { age: 42 }
    },
    {
        name: "Persona 3 : Ado Mixte, 16 ans, Budget 0-50€, Lecture, Culture",
        tags: ["gender_mixte", "budget_0_50", "cat_culture", "passion_lecture", "perso_casanier"],
        userDict: { age: 16 }
    },
    {
        name: "Persona 4 : Femme, 28 ans, Budget 50-100€, Voyage (Recherche 'Paris')",
        tags: ["gender_femme", "budget_50_100", "type_voyage_aventure", "passion_voyage"],
        userDict: { age: 28, location: "Paris" }
    }
];

async function runTests() {
    console.log("📦 Chargement des produits depuis Firebase...");
    const snapshot = await db.collection('gifts').get();
    const products = [];
    snapshot.forEach(doc => {
        let data = doc.data();
        data.id = doc.id;
        products.push(data);
    });
    console.log(`✅ ${products.length} produits chargés.\n`);

    const alcoolProducts = products.filter(p => p.tags.includes('cat_alcool'));
    console.log(`🍷 Produits Alcool : ${alcoolProducts.length}`);

    const voyageProducts = products.filter(p => p.tags.includes('type_voyage_aventure'));
    console.log(`✈️ Produits Voyage/Aventure : ${voyageProducts.length}`);

    process.exit(0);
}

runTests().catch(console.error);
