const PROJECT_ID = 'doron-b3011';
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/gifts`;

async function checkSpecificProduct() {
    let pageToken = '';

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

                    if (title.toLowerCase().includes('bambu lab') || title.toLowerCase().includes('imprimante')) {
                        console.log(`Title: ${title}`);
                        console.log(`Image URL: ${_image}`);
                        console.log(`Categories:`, fields.categories?.arrayValue?.values?.map(v => v.stringValue));
                        console.log('---');
                    }
                }
            }
            pageToken = data.nextPageToken;
        } catch (e) {
            console.error('Error fetching data:', e);
            break;
        }
    } while (pageToken);
}

checkSpecificProduct();
