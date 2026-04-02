const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

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
    console.log('🗑️ Deleting bad products from Firebase...');

    let deletedCount = 0;

    try {
        const snapshot = await db.collection('gifts').get();
        const batch = db.batch();

        snapshot.docs.forEach((doc) => {
            const data = doc.data();
            const title = data.name || data.product_title || '';

            // We also check if the image has generic patterns just in case
            const image = data.image || data.imageUrl || data.productPhoto || '';
            const isGenericImage = image.includes('placeholder') ||
                image.includes('amazon.com/images/I/01') ||
                image.endsWith('.svg');

            // Also check bad prices <= 0
            const price = data.price || data.product_price || 0;

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
                batch.delete(doc.ref);
                deletedCount++;
                console.log(`Marked for deletion: ${title}`);
            }
        });

        if (deletedCount > 0) {
            await batch.commit();
            console.log(`✅ Successfully deleted ${deletedCount} bad products.`);
        } else {
            console.log('🤷 No bad products found to delete.');
        }

    } catch (error) {
        console.error('❌ Error deleting products:', error);
    }

    process.exit(0);
}

deleteBadProducts();
