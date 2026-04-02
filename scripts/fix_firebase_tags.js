/**
 * Script de correction des tags Firebase pour l'app Doron
 *
 * UTILISATION SUR REPLIT:
 * 1. Créer un nouveau Repl Node.js
 * 2. Copier ce fichier
 * 3. Installer les dépendances: npm install firebase-admin
 * 4. Ajouter votre fichier serviceAccountKey.json dans Secrets
 * 5. Exécuter: node fix_firebase_tags.js
 *
 * Ce script CORRIGE et NORMALISE les tags existants:
 * - Remplace les tirets par des underscores (budget_100-200 → budget_100_200)
 * - Corrige les incohérences (gender: "unisex" vs tags: ["gender_femme"])
 * - Ajoute les tags manquants
 * - Garantit que TOUS les produits ont les tags requis
 */

const admin = require('firebase-admin');

// Configuration Firebase - MODIFIER SELON VOTRE PROJET
// Sur Replit, mettez votre serviceAccountKey.json dans les Secrets
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Statistiques
let stats = {
  total: 0,
  updated: 0,
  errors: 0,
  normalized: 0,
  fixed: 0,
  byIssue: {
    dashToUnderscore: 0,
    genderConflict: 0,
    missingGender: 0,
    missingCategory: 0,
    missingBudget: 0,
    missingAge: 0
  }
};

/**
 * Normalise un tag : remplace les tirets par des underscores
 */
function normalizeTag(tag) {
  return tag.toLowerCase().replace(/-/g, '_');
}

/**
 * Détecte le genre depuis le champ "gender" et le nom/description
 * IMPORTANT: Il n'y a PAS de mixte - seulement homme OU femme
 */
function detectGenderFromProduct(product) {
  const genderField = (product.gender || '').toLowerCase();
  const productName = (product.name || product.product_title || '').toLowerCase();
  const productDescription = (product.description || '').toLowerCase();
  const text = `${productName} ${productDescription}`;
  const categories = Array.isArray(product.categories) ? product.categories.map(c => c.toLowerCase()) : [];

  // Mots-clés TRÈS SPÉCIFIQUES pour FEMME
  const feminineKeywords = [
    'robe', 'jupe', 'lingerie', 'soutien-gorge', 'brassière', 'culotte femme',
    'collant', 'maquillage', 'rouge à lèvres', 'mascara', 'vernis', 'nail polish',
    'sac à main', 'pour elle', 'féminin', 'talons', 'femme', 'woman', 'women',
    'miss', 'lady', 'dress', 'skirt', 'heels', 'makeup', 'she', 'her'
  ];

  // Mots-clés TRÈS SPÉCIFIQUES pour HOMME
  const masculineKeywords = [
    'cravate', 'rasoir électrique', 'tondeuse barbe', 'after shave', 'aftershave',
    'costume homme', 'pour lui', 'masculin', 'barbe', 'homme', 'man', 'men',
    'monsieur', 'mister', 'tie', 'beard', 'he', 'him', 'male'
  ];

  // Analyser les mots-clés dans le texte
  const feminineMatches = feminineKeywords.filter(kw => text.includes(kw)).length;
  const masculineMatches = masculineKeywords.filter(kw => text.includes(kw)).length;

  // 1. Si le champ gender est explicite
  if (genderField === 'male' || genderField === 'homme' || genderField === 'man') {
    return 'gender_homme';
  }
  if (genderField === 'female' || genderField === 'femme' || genderField === 'woman') {
    return 'gender_femme';
  }

  // 2. Si des mots-clés féminins/masculins sont trouvés
  if (feminineMatches > masculineMatches) {
    return 'gender_femme';
  }
  if (masculineMatches > feminineMatches) {
    return 'gender_homme';
  }

  // 3. Analyser la catégorie
  const feminineCats = ['beauty', 'beaute', 'makeup'];
  const masculineCats = ['tech', 'sport', 'gaming'];

  const hasFeminineCat = categories.some(cat => feminineCats.some(fc => cat.includes(fc)));
  const hasMasculineCat = categories.some(cat => masculineCats.some(mc => cat.includes(mc)));

  if (hasFeminineCat && !hasMasculineCat) {
    return 'gender_femme';
  }
  if (hasMasculineCat && !hasFeminineCat) {
    return 'gender_homme';
  }

  // 4. Pour les produits UNISEX - Répartition 50/50 homme/femme
  if (genderField === 'unisex') {
    const nameHash = productName.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
    return nameHash % 2 === 0 ? 'gender_homme' : 'gender_femme';
  }

  // 5. Conserver le tag existant s'il est valide
  const existingTags = Array.isArray(product.tags) ? product.tags : [];
  const existingGenderTag = existingTags.find(t => t.startsWith('gender_'));

  if (existingGenderTag === 'gender_femme' || existingGenderTag === 'gender_homme') {
    return existingGenderTag;
  }

  // 6. Par défaut : répartition 50/50
  const nameHash = productName.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
  return nameHash % 2 === 0 ? 'gender_homme' : 'gender_femme';
}

/**
 * Détecte la catégorie d'un produit
 */
function detectCategory(productName, productDescription, existingCategories) {
  const text = `${productName} ${productDescription}`.toLowerCase();

  const categoryKeywords = {
    'cat_tech': ['tech', 'électronique', 'gadget', 'usb', 'bluetooth', 'écouteurs', 'casque', 'smartphone', 'tablette', 'ordinateur', 'souris', 'clavier', 'cable', 'chargeur', 'powerbank', 'enceinte', 'speaker'],
    'cat_mode': ['vêtement', 't-shirt', 'pull', 'sweat', 'pantalon', 'jean', 'chaussure', 'basket', 'sneaker', 'mode', 'fashion', 'hoodie', 'chemise', 'polo', 'short', 'robe', 'jupe', 'pants'],
    'cat_beaute': ['beauté', 'maquillage', 'parfum', 'crème', 'soin', 'cosmétique', 'huile', 'sérum', 'shampoing', 'après-shampoing', 'gel douche', 'lotion', 'masque', 'gommage'],
    'cat_maison': ['maison', 'déco', 'décoration', 'coussin', 'lampe', 'bougie', 'vase', 'cadre', 'plante', 'tapis', 'rideau', 'horloge'],
    'cat_sport': ['sport', 'fitness', 'yoga', 'running', 'musculation', 'gym', 'training', 'basket', 'football', 'vélo', 'natation', 'tennis', 'haltère', 'tapis de sport'],
    'cat_food': ['cuisine', 'gastronomie', 'chocolat', 'thé', 'café', 'vin', 'gourmet', 'food', 'bouteille', 'confiserie', 'biscuit', 'alcool', 'whisky', 'champagne'],
    'cat_livre': ['livre', 'roman', 'bd', 'manga', 'lecture', 'bouquin', 'polar'],
    'cat_jeux': ['jeu', 'jouet', 'puzzle', 'board game', 'société', 'carte', 'lego', 'playmobil']
  };

  // Vérifier si une catégorie existante correspond déjà
  if (existingCategories && existingCategories.length > 0) {
    const catLower = existingCategories[0].toLowerCase();
    if (catLower.includes('tech') || catLower === 'technology') return 'cat_tech';
    if (catLower.includes('mode') || catLower === 'fashion') return 'cat_mode';
    if (catLower.includes('beaute') || catLower === 'beauty') return 'cat_beaute';
    if (catLower.includes('maison') || catLower === 'home') return 'cat_maison';
    if (catLower.includes('sport')) return 'cat_sport';
    if (catLower.includes('food') || catLower.includes('cuisine')) return 'cat_food';
  }

  for (const [categoryTag, keywords] of Object.entries(categoryKeywords)) {
    if (keywords.some(kw => text.includes(kw))) {
      return categoryTag;
    }
  }

  return 'cat_tendances'; // Par défaut
}

/**
 * Calcule le tag de budget basé sur le prix
 * IMPORTANT: Doit correspondre EXACTEMENT aux tags de l'app
 * Voir lib/services/tags_definitions.dart ligne 33-38
 */
function getBudgetTag(price) {
  if (price < 50) return 'budget_0_50';
  if (price < 100) return 'budget_50_100';
  if (price < 200) return 'budget_100_200';
  return 'budget_200+';  // ← EXACTEMENT comme dans l'app
}

/**
 * Détecte le tag d'âge
 */
function detectAge(productName, productDescription) {
  const text = `${productName} ${productDescription}`.toLowerCase();

  if (text.includes('enfant') || text.includes('bébé') || text.includes('kid') || text.includes('child')) {
    return 'age_enfant';
  } else if (text.includes('ado') || text.includes('teenager') || text.includes('teen')) {
    return 'age_jeune';
  } else if (text.includes('senior') || text.includes('retraite') || text.includes('elderly')) {
    return 'age_senior';
  }

  return 'age_adulte'; // Par défaut
}

/**
 * Traite un produit et corrige/normalise ses tags
 */
async function processProduct(doc) {
  try {
    const data = doc.data();
    const productName = data.name || data.product_title || '';
    const productDescription = data.description || '';
    const price = typeof data.price === 'number' ? data.price : parseInt(data.price || '0');
    const currentTags = Array.isArray(data.tags) ? data.tags : [];
    const currentCategories = Array.isArray(data.categories) ? data.categories : [];

    let newTags = new Set();
    let modified = false;
    let issuesFound = [];

    // 1. NORMALISER tous les tags existants (tirets → underscores)
    currentTags.forEach(tag => {
      const normalized = normalizeTag(tag);
      if (normalized !== tag) {
        stats.byIssue.dashToUnderscore++;
        issuesFound.push(`Normalisé: ${tag} → ${normalized}`);
        modified = true;
      }
      newTags.add(normalized);
    });

    // 2. VÉRIFIER ET CORRIGER LE GENRE
    const existingGenderTags = Array.from(newTags).filter(t => t.startsWith('gender_'));
    const correctGender = detectGenderFromProduct(data);

    if (existingGenderTags.length === 0) {
      // Pas de tag genre → ajouter
      newTags.add(correctGender);
      modified = true;
      stats.byIssue.missingGender++;
      issuesFound.push(`Ajout genre: ${correctGender}`);
      console.log(`  ➕ "${productName}" → ${correctGender} (manquant)`);
    } else if (existingGenderTags[0] !== correctGender) {
      // Tag genre existe mais est incorrect
      existingGenderTags.forEach(tag => newTags.delete(tag));
      newTags.add(correctGender);
      modified = true;
      stats.byIssue.genderConflict++;
      issuesFound.push(`Correction genre: ${existingGenderTags[0]} → ${correctGender}`);
      console.log(`  🔧 "${productName}" → ${correctGender} (était ${existingGenderTags[0]})`);
    }

    // 3. VÉRIFIER ET CORRIGER LA CATÉGORIE
    const existingCategoryTags = Array.from(newTags).filter(t => t.startsWith('cat_'));

    if (existingCategoryTags.length === 0) {
      const categoryTag = detectCategory(productName, productDescription, currentCategories);
      newTags.add(categoryTag);
      modified = true;
      stats.byIssue.missingCategory++;
      issuesFound.push(`Ajout catégorie: ${categoryTag}`);
    }

    // 4. VÉRIFIER ET CORRIGER LE BUDGET
    const existingBudgetTags = Array.from(newTags).filter(t => t.startsWith('budget_'));

    if (existingBudgetTags.length === 0 && price > 0) {
      const budgetTag = getBudgetTag(price);
      newTags.add(budgetTag);
      modified = true;
      stats.byIssue.missingBudget++;
      issuesFound.push(`Ajout budget: ${budgetTag}`);
    } else if (existingBudgetTags.length > 0 && price > 0) {
      // Vérifier si le budget est cohérent avec le prix
      const correctBudget = getBudgetTag(price);

      // IMPORTANT: Corriger les anciens formats incorrects
      // budget_200_500, budget_500_plus → budget_200+
      const needsCorrection = existingBudgetTags.some(tag =>
        tag === 'budget_200_500' ||
        tag === 'budget_500_plus' ||
        tag === 'budget_500+' ||
        !existingBudgetTags.includes(correctBudget)
      );

      if (needsCorrection) {
        existingBudgetTags.forEach(tag => newTags.delete(tag));
        newTags.add(correctBudget);
        modified = true;
        issuesFound.push(`Correction budget: ${existingBudgetTags[0]} → ${correctBudget} (${price}€)`);
        console.log(`  💰 "${productName}" → ${correctBudget} (était ${existingBudgetTags[0]}, prix: ${price}€)`);
      }
    }

    // 5. VÉRIFIER ET AJOUTER L'ÂGE
    const existingAgeTags = Array.from(newTags).filter(t => t.startsWith('age_'));

    if (existingAgeTags.length === 0) {
      const ageTag = detectAge(productName, productDescription);
      newTags.add(ageTag);
      modified = true;
      stats.byIssue.missingAge++;
      issuesFound.push(`Ajout âge: ${ageTag}`);
    }

    // Mettre à jour le document si modifié
    if (modified) {
      await doc.ref.update({
        tags: Array.from(newTags)
      });
      stats.updated++;

      if (issuesFound.length > 0) {
        stats.fixed++;
        if (stats.fixed <= 10) {
          console.log(`  ✅ "${productName}"`);
          issuesFound.forEach(issue => console.log(`     - ${issue}`));
        }
      }

      return true;
    } else {
      stats.normalized++;
      return false;
    }
  } catch (error) {
    console.error(`❌ Erreur sur produit ${doc.id}:`, error.message);
    stats.errors++;
    return false;
  }
}

/**
 * Fonction principale
 */
async function main() {
  console.log('🔧 Script de correction et normalisation des tags Firebase');
  console.log('===========================================================\n');

  try {
    // Charger tous les produits
    console.log('📦 Chargement des produits depuis Firebase...');
    const snapshot = await db.collection('gifts').get();
    stats.total = snapshot.size;
    console.log(`✅ ${stats.total} produits chargés\n`);

    if (snapshot.empty) {
      console.log('❌ Aucun produit dans la collection "gifts" !');
      process.exit(1);
    }

    // Afficher un échantillon AVANT
    const firstDoc = snapshot.docs[0];
    const firstData = firstDoc.data();
    console.log('📋 ÉCHANTILLON AVANT CORRECTION:');
    console.log(`  Produit: ${firstData.name || firstData.product_title}`);
    console.log(`  Tags: ${JSON.stringify(firstData.tags)}`);
    console.log(`  Gender field: ${firstData.gender}`);
    console.log(`  Prix: ${firstData.price}€\n`);

    // Traiter tous les produits
    console.log('🔄 Correction et normalisation en cours...\n');
    let processed = 0;

    for (const doc of snapshot.docs) {
      await processProduct(doc);
      processed++;

      // Afficher la progression tous les 25 produits
      if (processed % 25 === 0) {
        console.log(`   📊 Progression: ${processed}/${stats.total} produits traités...`);
      }
    }

    // Résumé final
    console.log('\n✅ TERMINÉ !');
    console.log('═══════════════════════════════════════');
    console.log(`📊 Total produits analysés: ${stats.total}`);
    console.log(`✅ Produits corrigés: ${stats.updated}`);
    console.log(`✔️  Produits déjà OK: ${stats.normalized}`);
    console.log(`❌ Erreurs: ${stats.errors}`);
    console.log('\n🔍 Corrections effectuées par type:');
    console.log(`  🔤 Tirets → Underscores: ${stats.byIssue.dashToUnderscore}`);
    console.log(`  ⚠️  Conflits genre corrigés: ${stats.byIssue.genderConflict}`);
    console.log(`  ➕ Genre manquant ajouté: ${stats.byIssue.missingGender}`);
    console.log(`  ➕ Catégorie manquante ajoutée: ${stats.byIssue.missingCategory}`);
    console.log(`  ➕ Budget manquant ajouté: ${stats.byIssue.missingBudget}`);
    console.log(`  ➕ Âge manquant ajouté: ${stats.byIssue.missingAge}`);

    // Afficher un échantillon APRÈS
    const updatedSnapshot = await db.collection('gifts').doc(firstDoc.id).get();
    const updatedData = updatedSnapshot.data();
    console.log('\n📋 ÉCHANTILLON APRÈS CORRECTION:');
    console.log(`  Produit: ${updatedData.name || updatedData.product_title}`);
    console.log(`  Tags: ${JSON.stringify(updatedData.tags)}`);
    console.log(`  Gender field: ${updatedData.gender}`);

    console.log('\n✨ Votre base Firebase est maintenant normalisée et corrigée !');
    console.log('\n🎯 PROCHAINE ÉTAPE: Testez votre app');
    console.log('   1. Ouvrez l\'app Doron');
    console.log('   2. Allez dans "Recherche"');
    console.log('   3. Cliquez sur "+ Ajouter une personne"');
    console.log('   4. Remplissez le formulaire (ex: Homme, 30 ans)');
    console.log('   5. ✅ Vous devriez voir des produits homme/mixte !');

  } catch (error) {
    console.error('\n❌ ERREUR CRITIQUE:', error);
    console.error('Stack trace:', error.stack);
    process.exit(1);
  }

  process.exit(0);
}

// Lancer le script
main();
