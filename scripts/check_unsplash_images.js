const PROJECT_ID = 'doron-b3011';
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/gifts`;

async function checkUnsplashImages() {
    let pageToken = '';
    let count = 0;

    do {
        let url = `${BASE_URL}?pageSize=300`;
        if (pageToken) url += `&pageToken=${encodeURIComponent(pageToken)}`;

        try {
            const response = await fetch(url);
            const data = await response.json();

            if (data.documents) {
                for (const doc of data.documents) {
                    const fields = doc.fields || {};
                    const title = fields.name?.stringValue || fields.product_title?.stringValue || '';
                    const _image = fields.image?.stringValue || fields.imageUrl?.stringValue || fields.productPhoto?.stringValue || '';
                    const price = fields.price?.doubleValue || fields.price?.integerValue || fields.product_price?.doubleValue || fields.product_price?.integerValue || 0;

                    if (_image.includes('unsplash.com') || _image.includes('placeholder')) {
                        console.log(`Title: ${title} | Price: ${price} | ID: ${doc.name.split('/').pop()}`);
                        console.log(`Image URL: ${_image}`);
                        console.log('---');
                        count++;
                    }
                }
            }
            pageToken = data.nextPageToken;
        } catch (e) {
            console.error('Error fetching data:', e);
            break;
        }
    } while (pageToken);

    console.log(`Found ${count} products with Unsplash/placeholder images.`);
}

checkUnsplashImages();
