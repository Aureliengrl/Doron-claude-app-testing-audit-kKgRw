const fs = require('fs');

const path = 'functions/index.js';
let content = fs.readFileSync(path, 'utf8');

const newCode = `
// Nouveau: rerankProductsWithClaude
exports.rerankProductsWithClaude = onCall(async (request) => {
  const data = request.data;
  const products = data.products || [];
  const userProfile = data.userProfile || {};
  
  if (products.length === 0) return { rerankedIds: [] };

  const prompt = \`Tu es le meilleur personal shopper au monde.
Voici le profil détaillé de la personne :
Âge: \${userProfile.age || 'Inconnu'}
Sexe: \${userProfile.gender || 'Inconnu'}
Centres d'intérêt: \${userProfile.interests?.join(', ') || 'Inconnu'}
Personnalité: \${userProfile.personality?.join(', ') || 'Inconnue'}
Événement/Occasion: \${userProfile.occasion || 'Inconnu'}

Voici une liste de \${products.length} produits extraits de notre base de données, au format JSON :
\${JSON.stringify(products.map(p => ({id: p.id, name: p.name, desc: p.description, price: p.price})))}

TA MISSION :
Sélectionne EXACTEMENT les 6 produits de cette liste qui correspondent À 200% à cette personne.
Pour chaque produit sélectionné, fournis une justification courte (1 phrase) expliquant pourquoi c'est le "Perfect Match".
Réponds UNIQUEMENT avec un tableau JSON d'objets avec ces propriétés :
- "id": L'identifiant exact du produit
- "justification": La phrase courte d'explication\`;

  try {
    const msg = await anthropic.messages.create({
      model: "claude-3-5-sonnet-20241022",
      max_tokens: 1000,
      system: "Tu es un assistant JSON expert. Tu ne réponds QUE par du JSON valide sans aucun autre texte.",
      messages: [{ role: "user", content: prompt }]
    });

    let text = msg.content[0].text;
    text = text.replace(/\\n/g, '').trim();
    if (text.startsWith('\`\`\`json')) {
      text = text.replace(/\`\`\`json/, '').replace(/\`\`\`/, '').trim();
    }
    
    // Fallback if the model hallucinated some extra text
    const jsonMatch = text.match(/\\[[\\s\\S]*\\]/);
    if (jsonMatch) text = jsonMatch[0];

    const result = JSON.parse(text);
    return { rerankedProducts: result };
  } catch (error) {
    console.error("Erreur Claude rerankProductsWithClaude:", error);
    throw new Error("Impossible de reranker les produits");
  }
});
`;

if (!content.includes('rerankProductsWithClaude')) {
  fs.appendFileSync(path, newCode);
  console.log('Appended rerankProductsWithClaude to functions/index.js');
} else {
  console.log('Already exists');
}
