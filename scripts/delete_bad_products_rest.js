const PROJECT_ID = 'doron-b3011';
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/gifts`;

const BAD_PRODUCTS = [
    "Echarpe Marron Ami De Coeur En Alpaga NOISETTE | AMI PARIS",
    "Porsche 911 10295 | LEGO® Icons | Boutique LEGO® officielle FR ",
    "Haut en Fleece à 1/4 de zip Nike Solo Swoosh pour homme",
    "GOLDILOCKS - Brown",
    "GOLDILOCKS - Grey",
    "Cardigan Bordeaux Ami De Coeur En Laine CERISE/NOIR | AMI PARIS",
    "Sandales Oran",
    "Pochette en cuir nappa matelassé",
    "Bracelet Diamant en Or Blanc Joy | Messika 05337-WG"
];

async function deleteBadProducts() {
    console.log('🗑️ Fetching gifts from Firebase to identify bad ones...');

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
        const price = fields.price?.doubleValue || fields.price?.integerValue || fields.product_price?.doubleValue || fields.product_price?.integerValue || 0;

        const isGenericImage = image.includes('placeholder') ||
            image.includes('amazon.com/images/I/01') ||
            image.endsWith('.svg');

        let shouldDelete = false;

        if (BAD_PRODUCTS.some(badName => title.includes(badName))) {
            shouldDelete = true;
            console.log(`Matching bad name: ${title}`);
        } else if (isGenericImage) {
            shouldDelete = true;
            console.log(`Generic image found: ${title} -> ${image}`);
        } else if (price <= 0) {
            shouldDelete = true;
            console.log(`Price <= 0 found: ${title} -> ${price}`);
        }

        if (shouldDelete) {
            console.log(`Deleting document: ${doc.name} (${title})`);
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

    console.log(`\n🎉 Process complete. Deleted ${deletedCount} bad products.`);
}

deleteBadProducts();
