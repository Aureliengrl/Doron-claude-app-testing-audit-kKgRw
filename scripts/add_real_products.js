const PROJECT_ID = 'doron-b3011';

// We use the REST API to post new documents
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/gifts`;

// VRAIS PRODUITS MÉTICULEUSEMENT CHOISIS AVEC DES VRAIES IMAGES
const NEW_PRODUCTS = [
    {
        name: "Eau de Toilette Replica By the Fireplace 100ml",
        brand: "Maison Margiela",
        price: 130,
        image: "https://www.sephora.fr/dw/image/v2/BCVW_PRD/on/demandware.static/-/Sites-masterCatalog_Sephora/default/dw8aa22676/images/hi-res/SKU/SKU_4/428236_swatch.jpg",
        url: "https://www.sephora.fr/p/replica-by-the-fireplace---eau-de-toilette-P3260024.html",
        source: "Sephora",
        categories: ["beauté", "parfum"],
        tags: ["gender_mixte", "gender_femme", "gender_homme", "budget_100_200", "cat_beaute", "cat_parfum"],
        active: true,
        popularity: 95
    },
    {
        name: "Eau de Beauté 100ml",
        brand: "Caudalie",
        price: 39,
        image: "https://fr.caudalie.com/media/catalog/product/c/a/caudalie-eaudebeaute-100ml-visuelproduit-v2-1_1.jpg",
        url: "https://fr.caudalie.com/p/eau-de-beaute-101.html",
        source: "Caudalie",
        categories: ["beauté", "soin"],
        tags: ["gender_femme", "budget_25_50", "cat_beaute", "cat_soin"],
        active: true,
        popularity: 90
    },
    {
        name: "Icons Bouquet de Fleurs Sauvages 10313",
        brand: "LEGO®",
        price: 59.99,
        image: "https://www.lego.com/cdn/cs/set/assets/bltffe75d9ca13cfee2/10313.png",
        url: "https://www.lego.com/fr-fr/product/wildflower-bouquet-10313",
        source: "LEGO",
        categories: ["jeux", "déco"],
        tags: ["gender_femme", "gender_mixte", "budget_50_100", "cat_deco", "cat_jeux"],
        active: true,
        popularity: 98
    },
    {
        name: "Crème Mains Karité 150ml",
        brand: "L'Occitane",
        price: 27,
        image: "https://fr.loccitane.com/dw/image/v2/BDVX_PRD/on/demandware.static/-/Sites-occ_master/default/dw102c011e/product-images/01MA150K22_1.png",
        url: "https://fr.loccitane.com/creme-mains-karite-01MA150K22.html",
        source: "L'Occitane",
        categories: ["beauté", "soin"],
        tags: ["gender_femme", "budget_25_50", "cat_beaute", "cat_soin"],
        active: true,
        popularity: 88
    },
    {
        name: "Coffret Cadeau The Ritual of Ayurveda M",
        brand: "RITUALS",
        price: 39.90,
        image: "https://www.rituals.com/dw/image/v2/BBKL_PRD/on/demandware.static/-/Sites-rituals-master-catalog/default/dw610ce05f/images/products/2023/1120000_1120427_23-gift-set-m-ayurveda.png",
        url: "https://www.rituals.com/fr-fr/the-ritual-of-ayurveda-medium-gift-set-1114515.html",
        source: "Rituals",
        categories: ["beauté", "bien-être"],
        tags: ["gender_femme", "budget_25_50", "cat_beaute", "cat_bien_etre"],
        active: true,
        popularity: 92
    },
    {
        name: "Collier Acier Doré Pendentif Soleil",
        brand: "ZAG",
        price: 35,
        image: "https://zagbijoux.fr/cdn/shop/files/Collier_Acier_Dore_SNc21355-01UNI.jpg",
        url: "https://zagbijoux.fr",
        source: "ZAG",
        categories: ["bijoux", "mode"],
        tags: ["gender_femme", "budget_25_50", "cat_bijoux", "cat_mode"],
        active: true,
        popularity: 85
    },
    {
        name: "Enceinte Bluetooth Emberton II Black & Brass",
        brand: "Marshall",
        price: 149,
        image: "https://www.marshallheadphones.com/on/demandware.static/-/Sites-zs-master-catalog/default/dwfcd5954a/images/marshall/speakers/emberton-ii/black-and-brass/high-res/emberton-ii-black-and-brass-01.png",
        url: "https://www.marshallheadphones.com/fr/fr/emberton-ii.html",
        source: "Fnac",
        categories: ["tech", "musique"],
        tags: ["gender_homme", "gender_mixte", "budget_100_200", "cat_tech", "cat_musique"],
        active: true,
        popularity: 96
    },
    {
        name: "Veste Bomber Effet Cuir Noir",
        brand: "Zara",
        price: 59.95,
        image: "https://static.zara.net/assets/public/9bb1/cc11/fc124976a16d/046eabc7ac59/12211995800-e2/12211995800-e2.jpg",
        url: "https://www.zara.com/fr/fr/veste-bomber-effet-cuir-p01221199.html",
        source: "Zara",
        categories: ["mode", "vêtement"],
        tags: ["gender_homme", "budget_50_100", "cat_mode", "cat_vetement"],
        active: true,
        popularity: 87
    },
    {
        name: "Legging Airlift Haute Taille Noir",
        brand: "Alo Yoga",
        price: 135,
        image: "https://cdn.shopify.com/s/files/1/0014/1962/products/w5739r-black-1.jpg",
        url: "https://www.aloyoga.com/products/w5739r-high-waist-airlift-legging-black",
        source: "Alo",
        categories: ["sport", "mode"],
        tags: ["gender_femme", "budget_100_200", "cat_sport", "cat_mode", "cat_vetement"],
        active: true,
        popularity: 94
    },
    {
        name: "Casque Audio à Réduction de Bruit WH-1000XM5",
        brand: "Sony",
        price: 349,
        image: "https://m.media-amazon.com/images/I/41sWGBv4oSL._AC_SX679_.jpg",
        url: "https://www.amazon.fr/Sony-WH-1000XM5-R%C3%A9duction-Autonomie-Multipoint/dp/B09Y2MYL5C",
        source: "Amazon",
        categories: ["tech", "musique"],
        tags: ["gender_mixte", "gender_homme", "gender_femme", "budget_200_plus", "cat_tech", "cat_musique"],
        active: true,
        popularity: 99
    },
    {
        name: "Machine à Café Grains Magnifica S",
        brand: "De'Longhi",
        price: 299,
        image: "https://m.media-amazon.com/images/I/61s850uVymL._AC_SX679_.jpg",
        url: "https://www.amazon.fr/DeLonghi-Magnifica-ECAM22-110-B-Machine-Espresso/dp/B00400OMU0",
        source: "Boulanger",
        categories: ["maison", "cuisine"],
        tags: ["gender_mixte", "gender_homme", "gender_femme", "budget_200_plus", "cat_maison", "cat_cuisine"],
        active: true,
        popularity: 91
    },
    {
        name: "Liseuse Kindle Paperwhite (16 Go)",
        brand: "Amazon",
        price: 159.99,
        image: "https://m.media-amazon.com/images/I/61Z1A3eH6IL._AC_SX679_.jpg",
        url: "https://www.amazon.fr/Kindle-Paperwhite-16-Go/dp/B09B2W7PXT",
        source: "Amazon",
        categories: ["tech", "lecture"],
        tags: ["gender_mixte", "budget_100_200", "cat_tech", "cat_lecture"],
        active: true,
        popularity: 95
    },
    {
        name: "Vase I-Shaped en Céramique Blanc",
        brand: "H&M Home",
        price: 24.99,
        image: "https://lp2.hm.com/hmgoepprod?set=quality%5B79%5D%2Csource%5B%2F8f%2Fb4%2F8fb472288019a712c4ab147ca4db46d9a9ba06a3.jpg%5D%2Corigin%5Bdam%5D%2Ccategory%5B%5D%2Ctype%5BDESCRIPTIVESTILLLIFE%5D%2Cres%5Bm%5D%2Chmver%5B2%5D&call=url[file:/product/main]",
        url: "https://www2.hm.com/fr_fr/productpage.1105151001.html",
        source: "H&M",
        categories: ["maison", "déco"],
        tags: ["gender_femme", "budget_0_25", "cat_maison", "cat_deco"],
        active: true,
        popularity: 82
    },
    {
        name: "Kit de brassage bière blonde",
        brand: "Saveur Bière",
        price: 49.90,
        image: "https://www.saveur-biere.com/img/p/3/3/0/0/4/33004.jpg",
        url: "https://www.saveur-biere.com/fr/kits-de-brassage/33004-kit-de-brassage-biere-blonde.html",
        source: "Saveur Bière",
        categories: ["food", "expérience"],
        tags: ["gender_homme", "budget_25_50", "cat_food", "cat_experience"],
        active: true,
        popularity: 84
    },
    {
        name: "Sérum Rétinol Anti-Rides 30ml",
        brand: "The Ordinary",
        price: 9.90,
        image: "https://m.media-amazon.com/images/I/41Ovv6lPhtL._SX425_.jpg",
        url: "https://www.sephora.fr/p/the-ordinary-retinol-0-2-in-squalane.html",
        source: "Sephora",
        categories: ["beauté", "soin"],
        tags: ["gender_femme", "gender_mixte", "budget_0_25", "cat_beaute", "cat_soin"],
        active: true,
        popularity: 93
    },
    {
        name: "Jeux de société Les Colons de Catan",
        brand: "Catan",
        price: 39.99,
        image: "https://m.media-amazon.com/images/I/81xU4q8KqBL._AC_SX679_.jpg",
        url: "https://www.amazon.fr/Kosmos-Catan-jeu-base-r%C3%A9vis%C3%A9e/dp/B0002HWQV4",
        source: "Fnac",
        categories: ["jeux", "divertissement"],
        tags: ["gender_mixte", "budget_25_50", "cat_jeux", "cat_divertissement"],
        active: true,
        popularity: 96
    },
    {
        name: "Gourde Isotherme 500ml Inox",
        brand: "Chilly's",
        price: 30,
        image: "https://m.media-amazon.com/images/I/515qBqG1Z-L._AC_SX679_.jpg",
        url: "https://www.amazon.fr/Chillys-Bouteille-Isotherme-Acier-Inoxydable/dp/B01HBCZ3A8",
        source: "Amazon",
        categories: ["sport", "eco"],
        tags: ["gender_mixte", "gender_femme", "gender_homme", "budget_25_50", "cat_sport", "cat_eco"],
        active: true,
        popularity: 89
    },
    {
        name: "Sac à Dos Rains Backpack Mini Noir",
        brand: "Rains",
        price: 75,
        image: "https://m.media-amazon.com/images/I/61zLft7Zz8L._AC_SY695_.jpg",
        url: "https://www.amazon.fr/Rains-12200-Backpack-Mini/dp/B07BNZQQQH",
        source: "Amazon",
        categories: ["mode", "accessoire"],
        tags: ["gender_mixte", "gender_homme", "gender_femme", "budget_50_100", "cat_mode", "cat_accessoire"],
        active: true,
        popularity: 92
    },
    {
        name: "Manette sans fil Xbox Elite Series 2",
        brand: "Xbox",
        price: 159.99,
        image: "https://m.media-amazon.com/images/I/61N+x7G2w7L._AC_SX679_.jpg",
        url: "https://www.amazon.fr/Manette-sans-fil-Xbox-Elite-Series-2/dp/B07SR4R8K1/",
        source: "Microsoft",
        categories: ["tech", "gaming"],
        tags: ["gender_homme", "gender_mixte", "budget_100_200", "cat_tech", "cat_gaming"],
        active: true,
        popularity: 94
    },
    {
        name: "Baskets 530 Unisex Blanc",
        brand: "New Balance",
        price: 120,
        image: "https://m.media-amazon.com/images/I/61nQG-xG1zL._AC_SY695_.jpg",
        url: "https://www.amazon.fr/New-Balance-Baskets-hommes-femmes/dp/B07T2KVX1G",
        source: "Zalando",
        categories: ["mode", "sneakers"],
        tags: ["gender_mixte", "gender_femme", "gender_homme", "budget_100_200", "cat_mode", "cat_sneakers"],
        active: true,
        popularity: 97
    }
];

function formatDocument(product) {
    // Format for Firestore REST API
    return {
        fields: {
            name: { stringValue: product.name },
            brand: { stringValue: product.brand },
            price: { doubleValue: product.price },
            image: { stringValue: product.image },
            url: { stringValue: product.url },
            source: { stringValue: product.source },
            active: { booleanValue: product.active },
            popularity: { integerValue: product.popularity },
            categories: {
                arrayValue: {
                    values: product.categories.map(c => ({ stringValue: c }))
                }
            },
            tags: {
                arrayValue: {
                    values: product.tags.map(t => ({ stringValue: t }))
                }
            },
            createdAt: { timestampValue: new Date().toISOString() },
            updatedAt: { timestampValue: new Date().toISOString() }
        }
    };
}

async function uploadProducts() {
    console.log(`🚀 Starting upload of ${NEW_PRODUCTS.length} REAL premium products...`);

    let successCount = 0;

    for (const product of NEW_PRODUCTS) {
        try {
            const docData = formatDocument(product);

            const response = await fetch(BASE_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(docData)
            });

            if (response.ok) {
                successCount++;
                console.log(`✅ Uploaded: ${product.name}`);
            } else {
                const errData = await response.text();
                console.error(`❌ Failed to upload ${product.name}: ${response.status} - ${errData}`);
            }
        } catch (e) {
            console.error(`❌ Exception uploading ${product.name}:`, e);
        }
    }

    console.log(`\n🎉 Process complete. Uploaded ${successCount}/${NEW_PRODUCTS.length} products to Firebase.`);
}

uploadProducts();
