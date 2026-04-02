const fs = require('fs');
const https = require('https');

const PROJECT_ID = 'doron-b3011';
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/gifts`;

async function fetchAllGifts() {
    let allGifts = [];
    let pageToken = '';

    console.log('Fetching gifts from Firebase...');

    do {
        let url = `${BASE_URL}?pageSize=300`;
        if (pageToken) url += `&pageToken=${encodeURIComponent(pageToken)}`;

        try {
            const response = await fetch(url);
            const data = await response.json();

            if (data.documents) {
                allGifts = allGifts.concat(data.documents);
            }
            pageToken = data.nextPageToken;
        } catch (e) {
            console.error('Error fetching data:', e);
            break;
        }
    } while (pageToken);

    console.log(`Fetched ${allGifts.length} gifts.`);

    const formattedGifts = allGifts.map(doc => {
        const fields = doc.fields || {};
        const name = fields.name?.stringValue || fields.product_title?.stringValue || 'Unknown';
        const price = fields.price?.doubleValue || fields.price?.integerValue || 0;
        const image = fields.image?.stringValue || fields.imageUrl?.stringValue || fields.productPhoto?.stringValue || '';
        const url = fields.url?.stringValue || '';

        return { name, price, image, url };
    });

    // Calculate some basic text-based heuristic checks
    const potentiallyGenericImages = formattedGifts.filter(g =>
        !g.image ||
        g.image.includes('placeholder') ||
        g.image.includes('amazon.com/images/I/01') ||
        g.image.endsWith('.svg')
    );

    const potentiallyBadPrices = formattedGifts.filter(g =>
        g.price <= 0 || g.price > 5000
    );

    console.log(`Found ${potentiallyGenericImages.length} potentially generic images based on URL patterns.`);
    console.log(`Found ${potentiallyBadPrices.length} potentially bad prices (<=0 or >5000).`);

    // Generate HTML Report
    let html = `
  <html>
  <head>
    <title>Gifts Audit Report</title>
    <style>
      body { font-family: sans-serif; padding: 20px; }
      .gift-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(250px, 1fr)); gap: 20px; }
      .gift-card { border: 1px solid #ccc; padding: 10px; border-radius: 8px; }
      .gift-card img { max-width: 100%; height: 200px; object-fit: contain; }
      .warning { color: red; font-weight: bold; }
    </style>
  </head>
  <body>
    <h1>Gifts Audit Report (${formattedGifts.length} items)</h1>
    <div class="gift-grid">
  `;

    formattedGifts.forEach(g => {
        let warning = '';
        if (!g.image) warning += '<div class="warning">MISSING IMAGE</div>';
        if (g.price <= 0) warning += '<div class="warning">PRICE IS <= 0</div>';

        html += `
      <div class="gift-card">
        <h3>${g.name}</h3>
        ${g.image ? `<img src="${g.image}" alt="${g.name}" loading="lazy"/>` : ''}
        <p><strong>Price:</strong> ${g.price}€</p>
        ${warning}
      </div>
    `;
    });

    html += `
    </div>
  </body>
  </html>
  `;

    fs.writeFileSync('C:/Users/marcg/.gemini/antigravity/brain/ceb69f80-d5cc-4e00-ac2a-11f9a057789e/gifts_report.html', html);
    console.log('Generated gifts_report.html at C:/Users/marcg/.gemini/antigravity/brain/ceb69f80-d5cc-4e00-ac2a-11f9a057789e/gifts_report.html');

    // Also save a JSON summary for easy reading
    fs.writeFileSync('C:/Users/marcg/.gemini/antigravity/brain/ceb69f80-d5cc-4e00-ac2a-11f9a057789e/gifts_summary.json', JSON.stringify({
        total: formattedGifts.length,
        missingOrGenericImages: potentiallyGenericImages.map(g => g.name),
        badPrices: potentiallyBadPrices.map(g => ({ name: g.name, price: g.price }))
    }, null, 2));
}

fetchAllGifts();
