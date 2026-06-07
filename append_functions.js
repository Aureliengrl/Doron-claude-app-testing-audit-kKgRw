const fs = require('fs');
const path = 'functions/index.js';
let content = fs.readFileSync(path, 'utf8');

const newFunctions = `
// Nouveau: generateBrands
exports.generateBrands = onCall(async (request) => {
  const data = request.data;
  const age = data.age || 25;
  const domains = data.domains || [];
  
  const prompt = \`Tu es un expert en marketing et tendances.
Voici le profil de la personne :
Âge: \${age}
Centres d'intérêt: \${domains.join(', ')}

Génère une liste des 6 à 8 marques les plus populaires et pertinentes pour cette personne.
Réponds UNIQUEMENT avec un tableau JSON valide de strings (ex: ["Nike", "Sephora", "Zara"]).\`;

  try {
    const msg = await anthropic.messages.create({
      model: "claude-3-5-sonnet-20241022",
      max_tokens: 500,
      system: "Tu es un assistant JSON expert. Tu ne réponds QUE par du JSON valide sans aucun autre texte.",
      messages: [{ role: "user", content: prompt }]
    });

    let text = msg.content[0].text;
    text = text.replace(/\\n/g, '').trim();
    if (text.startsWith('\`\`\`json')) {
      text = text.replace(/\`\`\`json/, '').replace(/\`\`\`/, '').trim();
    }
    const result = JSON.parse(text);
    return { brands: result };
  } catch (error) {
    console.error("Erreur Claude generateBrands:", error);
    throw new Error("Impossible de générer les marques");
  }
});

// Nouveau: generateEvents
exports.generateEvents = onCall(async (request) => {
  const data = request.data;
  const age = data.age || 25;
  const domains = data.domains || [];
  const currentDate = new Date().toLocaleDateString('fr-FR', { month: 'long', day: 'numeric' });
  
  const prompt = \`Tu es un expert en événements et tendances cadeaux.
Profil de la personne : Âge \${age}, Intérêts: \${domains.join(', ')}.
Date actuelle : \${currentDate}.

Génère une liste de 4 à 6 événements pertinents pour cette personne en ce moment ou à venir (ex: Noël, Fête des mères, Soldes d'été, Anniversaire, Coupe du monde, Rentrée).
Inclus un emoji pertinent pour chaque événement.
Réponds UNIQUEMENT avec un tableau JSON valide de strings (ex: ["🎄 Noël", "🎂 Anniversaire", "☀️ Soldes d'été"]).\`;

  try {
    const msg = await anthropic.messages.create({
      model: "claude-3-5-sonnet-20241022",
      max_tokens: 500,
      system: "Tu es un assistant JSON expert. Tu ne réponds QUE par du JSON valide sans aucun autre texte.",
      messages: [{ role: "user", content: prompt }]
    });

    let text = msg.content[0].text;
    text = text.replace(/\\n/g, '').trim();
    if (text.startsWith('\`\`\`json')) {
      text = text.replace(/\`\`\`json/, '').replace(/\`\`\`/, '').trim();
    }
    const result = JSON.parse(text);
    return { events: result };
  } catch (error) {
    console.error("Erreur Claude generateEvents:", error);
    throw new Error("Impossible de générer les événements");
  }
});
`;

if (!content.includes('exports.generateBrands')) {
  content += newFunctions;
  fs.writeFileSync(path, content, 'utf8');
  console.log('Firebase functions added locally.');
} else {
  console.log('Firebase functions already exist.');
}
