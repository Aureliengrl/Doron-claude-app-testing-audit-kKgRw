async function runPipeline() {
  const baseUrl = 'https://us-central1-doron-b3011.cloudfunctions.net';

  async function fetchWithRetry(url, retries = 5) {
    for (let i = 0; i < retries; i++) {
      try {
        const res = await fetch(url);
        if (res.ok) return await res.text();
        if (res.status === 404 || res.status === 403) throw new Error(`Status ${res.status}`);
      } catch (e) {
        if (i === retries - 1) throw e;
        console.log(`En attente du déploiement... (Essai ${i+1}/${retries})`);
        await new Promise(r => setTimeout(r, 10000));
      }
    }
  }

  console.log('1. Lancement de la suppression des anciens cadeaux Amazon...');
  try {
    const textDelete = await fetchWithRetry(`${baseUrl}/httpDeleteAmazonGifts`);
    console.log('Résultat suppression:', textDelete);
  } catch(e) {
    console.error('Erreur suppression:', e);
  }

  console.log('2. Lancement de l\'importation Rakuten (mots-clés: cadeau, montre, parfum, jouet)...');
  const keywords = ['cadeau', 'montre', 'parfum', 'jouet', 'high-tech', 'décoration'];
  
  for (const kw of keywords) {
    try {
      console.log(`Importation pour le mot-clé: ${kw}`);
      const textImport = await fetchWithRetry(`${baseUrl}/httpImportRakuten?keyword=${encodeURIComponent(kw)}`);
      console.log(`Résultat ${kw}:`, textImport);
      
      // Pause de 2 secondes pour ne pas spammer l'API
      await new Promise(resolve => setTimeout(resolve, 2000));
    } catch(e) {
      console.error(`Erreur import ${kw}:`, e);
    }
  }

  console.log('🎉 Pipeline complet terminé !');
}

runPipeline();
