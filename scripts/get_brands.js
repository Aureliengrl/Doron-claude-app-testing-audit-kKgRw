const PROJECT_ID = 'doron-b3011';
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/gifts`;

async function getBrands() {
    console.log('Fetching gifts from Firebase to extract brands...');

    let allGifts = [];
    let pageToken = '';

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

    const brands = new Set();

    for (const doc of allGifts) {
        const fields = doc.fields || {};
        let brand = fields.brand?.stringValue || fields.product_brand?.stringValue || '';
        if (brand) brands.add(brand);
    }

    console.log(`\nFound ${brands.size} unique brands:`);
    console.log(Array.from(brands).sort().join(', '));
}

getBrands();
