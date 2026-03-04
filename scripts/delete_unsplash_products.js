const PROJECT_ID = 'doron-b3011';
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/gifts`;

async function deleteUnsplashProducts() {
    console.log('🗑️ Fetching gifts from Firebase to identify generic (Unsplash) images...');

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

    console.log(`Fetched ${allGifts.length} gifts. Starting deletion process...`);

    let deletedCount = 0;

    for (const doc of allGifts) {
        const fields = doc.fields || {};
        const title = fields.name?.stringValue || fields.product_title?.stringValue || '';
        const image = fields.image?.stringValue || fields.imageUrl?.stringValue || fields.productPhoto?.stringValue || '';

        if (image.includes('unsplash.com') || image.includes('placeholder')) {
            console.log(`Generic image found, deleting document: ${doc.name} (${title}) -> ${image}`);
            try {
                const deleteRes = await fetch(`https://firestore.googleapis.com/v1/${doc.name}`, {
                    method: 'DELETE'
                });

                if (deleteRes.ok) {
                    deletedCount++;
                    console.log(`✅ Deleted ${title}`);
                } else {
                    console.error(`❌ Failed to delete ${title}: ${deleteRes.statusText}`);
                }
            } catch (e) {
                console.error(`❌ Exception deleting ${title}:`, e);
            }
        }
    }

    console.log(`\n🎉 Process complete. Deleted ${deletedCount} products with generic images.`);
}

deleteUnsplashProducts();
