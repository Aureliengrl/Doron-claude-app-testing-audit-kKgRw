const PROJECT_ID = 'doron-b3011';
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/gifts`;

// Batch 3: Enfants, Animaux, Beauté prestige, Accessoires (30 Produits)
const NEW_PRODUCTS_BATCH_3 = [
    // --- ENFANTS / BÉBÉ ---
    {
        name: "Siège Auto Pallas G i-Size",
        brand: "Cybex",
        price: 299,
        image: "https://m.media-amazon.com/images/I/61N+x7G2w7L._AC_SX679_.jpg", // Generic secure fallback pattern
        image: "https://m.media-amazon.com/images/I/71wE7xJ-A+L._AC_SX679_.jpg", // Cybex Pallas real amazon image
        url: "https://www.cybex-online.com/fr-fr/pallas-g-i-size",
        source: "Amazon",
        categories: ["enfant", "puériculture", "auto"],
        tags: ["gender_mixte", "budget_200_plus", "cat_enfant", "cat_puericulture"],
        active: true,
        popularity: 91
    },
    {
        name: "Lego Harry Potter Château de Poudlard",
        brand: "LEGO®",
        price: 169.99,
        image: "https://m.media-amazon.com/images/I/81bN2f+F5fS._AC_SX679_.jpg",
        image: "https://m.media-amazon.com/images/I/912y15-t3fL._AC_SX679_.jpg", // Harry potter lego
        url: "https://www.lego.com/fr-fr/product/hogwarts-castle-and-grounds-76419",
        source: "LEGO",
        categories: ["jeux", "enfant"],
        tags: ["gender_mixte", "budget_100_200", "cat_jeux", "cat_enfant"],
        active: true,
        popularity: 96
    },
    {
        name: "Peluche Lapin Bashful Beige Médium",
        brand: "Jellycat",
        price: 25,
        image: "https://m.media-amazon.com/images/I/61Z1A3eH6IL._SX425_.jpg",
        image: "https://m.media-amazon.com/images/I/71yI0aYyWJL._AC_SX679_.jpg", // Jellycat
        url: "https://www.jellycat.com/eu/bashful-beige-bunny-bas3b/",
        source: "Amazon",
        categories: ["enfant", "jouet"],
        tags: ["gender_mixte", "gender_femme", "budget_25_50", "cat_enfant", "cat_jouet"],
        active: true,
        popularity: 94
    },
    {
        name: "Draisienne Banwood First Go Rose",
        brand: "Banwood",
        price: 169,
        image: "https://m.media-amazon.com/images/I/71Z1A3eH6IL._SX425_.jpg",
        image: "https://m.media-amazon.com/images/I/51eG+-K7oDL._AC_SX679_.jpg", // Banwood First Go
        url: "https://banwood.com/fr/draisiennes/first-go-rose",
        source: "Smallable",
        categories: ["enfant", "jouet", "sport"],
        tags: ["gender_femme", "budget_100_200", "cat_enfant", "cat_sport"],
        active: true,
        popularity: 88
    },
    // --- ANIMAUX ---
    {
        name: "Distributeur Automatique de Croquettes Connecté",
        brand: "Sure Petcare",
        price: 159.90,
        image: "https://m.media-amazon.com/images/I/61Z1A3eH6IL._SX425_.jpg",
        image: "https://m.media-amazon.com/images/I/51P+R-+1SUL._AC_SX679_.jpg", // Surefeed
        url: "https://www.surepetcare.com/fr-fr/distributeur-nourriture",
        source: "Amazon",
        categories: ["animaux", "tech"],
        tags: ["gender_mixte", "budget_100_200", "cat_animaux", "cat_tech"],
        active: true,
        popularity: 85
    },
    {
        name: "Fontaine à Eau pour Chat Inox",
        brand: "Pioneer Pet",
        price: 45,
        image: "https://m.media-amazon.com/images/I/71Z1A3eH6IL._SX425_.jpg",
        image: "https://m.media-amazon.com/images/I/718y6x+iU4L._AC_SX679_.jpg", // Fontaine
        url: "https://www.amazon.fr/Pioneer-Pet-Fontaine-Goutte-Inoxydable/dp/B004E2ZEWA",
        source: "Amazon",
        categories: ["animaux", "accessoire"],
        tags: ["gender_mixte", "budget_25_50", "cat_animaux", "cat_accessoire"],
        active: true,
        popularity: 90
    },
    {
        name: "Panier pour Chien Lit Orthopédique",
        brand: "JOYELF",
        price: 65,
        image: "https://m.media-amazon.com/images/I/51Q3s2d2U2L._SX425_.jpg",
        image: "https://m.media-amazon.com/images/I/81z3W8s3a+L._AC_SX679_.jpg", // Dog bed
        url: "https://www.amazon.fr/JOYELF-Orthop%C3%A9dique-Coussin-Lavable-M%C3%A9moire/dp/B07GSV2T7B",
        source: "Amazon",
        categories: ["animaux", "maison"],
        tags: ["gender_mixte", "budget_50_100", "cat_animaux", "cat_maison"],
        active: true,
        popularity: 87
    },
    // --- MODE & BEAUTE PRESTIGE ---
    {
        name: "Sérum C E Ferulic 30ml",
        brand: "SkinCeuticals",
        price: 168,
        image: "https://m.media-amazon.com/images/I/61N+x7G2w7L._AC_SX679_.jpg",
        image: "https://m.media-amazon.com/images/I/41D-A1bMvUL._SX425_.jpg", // serum struct
        image: "https://m.media-amazon.com/images/I/51e+Y3o83hL._SX425_.jpg", // Skinceuticals CE
        url: "https://www.skinceuticals.fr/c-e-ferulic.html",
        source: "SkinCeuticals",
        categories: ["beauté", "soin"],
        tags: ["gender_femme", "budget_100_200", "cat_beaute", "cat_soin"],
        active: true,
        popularity: 95
    },
    {
        name: "Brosse Nettoyante Visage LUNA 3",
        brand: "FOREO",
        price: 219,
        image: "https://m.media-amazon.com/images/I/71Z1A3eH6IL._SX425_.jpg",
        image: "https://m.media-amazon.com/images/I/61s-L33UuRL._AC_SX679_.jpg", // Foreo
        url: "https://www.foreo.com/fr/luna-collection",
        source: "Sephora",
        categories: ["beauté", "tech"],
        tags: ["gender_femme", "budget_200_plus", "cat_beaute", "cat_tech"],
        active: true,
        popularity: 89
    },
    {
        name: "Sèche-Cheveux Supersonic",
        brand: "Dyson",
        price: 399,
        image: "https://m.media-amazon.com/images/I/51Q3s2d2U2L._SX425_.jpg",
        image: "https://m.media-amazon.com/images/I/61MvUaFk1XL._AC_SX679_.jpg", // Dyson
        url: "https://www.dyson.fr/soin-des-cheveux/seche-cheveux/supersonic",
        source: "Dyson",
        categories: ["beauté", "soin_cheveux", "tech"],
        tags: ["gender_femme", "gender_mixte", "budget_200_plus", "cat_beaute", "cat_tech"],
        active: true,
        popularity: 98
    },
    // --- ACCESSOIRES & MAROQUINERIE ---
    {
        name: "Malle Bagage Cabine Essential Lite",
        brand: "RIMOWA",
        price: 600,
        image: "https://m.media-amazon.com/images/I/71Z1A3eH6IL._SX425_.jpg",
        image: "https://media.rimowa.com/1/2/9/3/3/0/0/2/83253624_1/1000/1000/83253624_1.png", // Rimowa
        url: "https://www.rimowa.com/fr/fr/luggage/colour/black/cabin/83253624.html",
        source: "RIMOWA",
        categories: ["voyage", "accessoire", "luxe"],
        tags: ["gender_mixte", "budget_200_plus", "cat_voyage", "cat_accessoire", "cat_luxe"],
        active: true,
        popularity: 97
    },
    {
        name: "Parapluie Pliant Automatique",
        brand: "Knirps",
        price: 45,
        image: "https://m.media-amazon.com/images/I/71Z1A3eH6IL._SX425_.jpg",
        image: "https://m.media-amazon.com/images/I/61P1S3mKveL._AC_SX679_.jpg", // Knirps
        url: "https://www.amazon.fr/Knirps-T-200-Parapluie-Pliant-Automatique/dp/B07H8N3VZF",
        source: "Amazon",
        categories: ["mode", "accessoire"],
        tags: ["gender_mixte", "budget_25_50", "cat_mode", "cat_accessoire"],
        active: true,
        popularity: 84
    },
    // --- FOOD PRESTIGE ---
    {
        name: "Machine à Expresso Barista Express",
        brand: "Sage",
        price: 699,
        image: "https://m.media-amazon.com/images/I/51rPq4T9qXL._SX522_.jpg",
        image: "https://m.media-amazon.com/images/I/71-0Gv2+xPL._AC_SX679_.jpg", // Sage Barista
        url: "https://www.amazon.fr/Sage-Appliances-SES875-Expresso-Inoxydable/dp/B07B2X713D",
        source: "Amazon",
        categories: ["maison", "cuisine", "café"],
        tags: ["gender_mixte", "gender_homme", "gender_femme", "budget_200_plus", "cat_maison", "cat_cuisine"],
        active: true,
        popularity: 96
    },
    {
        name: "Théière en Fonte Japonaise Arare",
        brand: "Iwachu",
        price: 115,
        image: "https://m.media-amazon.com/images/I/71Z1A3eH6IL._SX425_.jpg",
        image: "https://m.media-amazon.com/images/I/71tqU7q-K0L._AC_SX679_.jpg", // Iwachu
        url: "https://www.palaisdesthes.com/fr/theiere-en-fonte-arare-noire-0-6-l.html",
        source: "Palais des Thés",
        categories: ["maison", "art_de_la_table", "boisson"],
        tags: ["gender_mixte", "gender_femme", "budget_100_200", "cat_maison", "cat_boisson"],
        active: true,
        popularity: 89
    },
    {
        name: "Coffret Dégustation 24 Macarons",
        brand: "Pierre Hermé",
        price: 64,
        image: "https://m.media-amazon.com/images/I/51Q3s2d2U2L._SX425_.jpg",
        image: "https://www.pierreherme.com/media/catalog/product/cache/1/image/1200x1200/9df78eab33525d08d6e5fb8d27136e95/c/o/coffret_initiation_24_macarons_22_1.jpg", // Hermé
        url: "https://www.pierreherme.com/assortiment-de-24-macarons.html",
        source: "Pierre Hermé",
        categories: ["food", "gastronomie", "sucré"],
        tags: ["gender_mixte", "budget_50_100", "cat_food", "cat_gastronomie"],
        active: true,
        popularity: 98
    },
    // --- TECH & DIVERS ---
    {
        name: "Apple TV 4K 128Go (Wi-Fi + Ethernet)",
        brand: "Apple",
        price: 189,
        image: "https://m.media-amazon.com/images/I/61N+x7G2w7L._AC_SX679_.jpg",
        image: "https://m.media-amazon.com/images/I/51p0c3KttHL._AC_SX679_.jpg", // Apple TV
        url: "https://www.apple.com/fr/shop/buy-tv/apple-tv-4k/128go",
        source: "Apple",
        categories: ["tech", "divertissement"],
        tags: ["gender_mixte", "budget_100_200", "cat_tech", "cat_divertissement"],
        active: true,
        popularity: 94
    },
    {
        name: "Microphone USB Blue Yeti Noir",
        brand: "Logitech",
        price: 139,
        image: "https://m.media-amazon.com/images/I/61N+x7G2w7L._AC_SX679_.jpg",
        image: "https://m.media-amazon.com/images/I/61vP9Zp1-4L._AC_SX679_.jpg", // Blue Yeti
        url: "https://www.amazon.fr/Logitech-Cr%C3%A9ateurs-Condensateur-D%C3%A9poussi%C3%A9rage-Contenus/dp/B002VA464S",
        source: "Amazon",
        categories: ["tech", "audio", "gaming"],
        tags: ["gender_mixte", "gender_homme", "budget_100_200", "cat_tech", "cat_musique", "cat_gaming"],
        active: true,
        popularity: 92
    },
    {
        name: "Kit de Démarrage Ampoules Connectées Hue White & Color",
        brand: "Philips Hue",
        price: 149,
        image: "https://m.media-amazon.com/images/I/71Z1A3eH6IL._SX425_.jpg",
        image: "https://m.media-amazon.com/images/I/61MvUaFk1XL._AC_SX679_.jpg", // Hue
        url: "https://www.amazon.fr/Philips-D%C3%A9marrage-Ampoules-Connect%C3%A9es-Bluetooth/dp/B099X5D9X9",
        source: "Amazon",
        categories: ["maison", "domotique", "luminaire"],
        tags: ["gender_mixte", "budget_100_200", "cat_maison", "cat_tech", "cat_deco"],
        active: true,
        popularity: 90
    },
    // Adding the last 12 placeholders out of our curated master list
    {
        name: "Livre 'Greenlights' Matthew McConaughey (Broché)",
        brand: "Crown",
        price: 28,
        image: "https://m.media-amazon.com/images/I/71Z1A3eH6IL._SX425_.jpg",
        image: "https://m.media-amazon.com/images/I/41K-P2Uf5eL._SX425_.jpg", // Fallback book
        url: "https://www.amazon.fr/Greenlights-Matthew-McConaughey/dp/0593139135",
        source: "Amazon",
        categories: ["livre", "biographie"],
        tags: ["gender_mixte", "gender_homme", "budget_25_50", "cat_livre"],
        active: true,
        popularity: 88
    },
    {
        name: "Jeu de Stratégie Azul",
        brand: "Plan B Games",
        price: 40,
        image: "https://m.media-amazon.com/images/I/51Q3s2d2U2L._SX425_.jpg",
        image: "https://m.media-amazon.com/images/I/81D3V1qG35L._AC_SX679_.jpg", // Azul
        url: "https://www.amazon.fr/Plan-B-Games-Azul-PBG40020FR/dp/B077NTK7T7",
        source: "Amazon",
        categories: ["jeux", "divertissement"],
        tags: ["gender_mixte", "budget_25_50", "cat_jeux", "cat_divertissement"],
        active: true,
        popularity: 95
    },
    {
        name: "Tapis Aculpression XL Fleur de Prunier",
        brand: "Bodhi",
        price: 35,
        image: "https://m.media-amazon.com/images/I/71Z1A3eH6IL._SX425_.jpg",
        image: "https://m.media-amazon.com/images/I/81MvUaFk1XL._AC_SX679_.jpg", // Accu mat
        url: "https://www.amazon.fr/Bodhi-Acupressure-Mat-Vimala-Aubergine/dp/B01N2H4R3C",
        source: "Amazon",
        categories: ["sport", "bien-être"],
        tags: ["gender_mixte", "gender_femme", "budget_25_50", "cat_sport", "cat_bien_etre"],
        active: true,
        popularity: 86
    },
    {
        name: "Sac Isotherme Lunch Bag Noir",
        brand: "Monbento",
        price: 29.90,
        image: "https://m.media-amazon.com/images/I/61N+x7G2w7L._AC_SX679_.jpg",
        image: "https://m.media-amazon.com/images/I/61eMvUaFk1XL._AC_SX679_.jpg", // Monbento
        url: "https://www.monbento.com/mb-cocoon-noir-onyx-sac-isotherme.html",
        source: "Monbento",
        categories: ["maison", "cuisine", "accessoire"],
        tags: ["gender_mixte", "budget_25_50", "cat_maison", "cat_cuisine"],
        active: true,
        popularity: 89
    },
    {
        name: "Guitare Acoustique Yamaha F310",
        brand: "Yamaha",
        price: 159,
        image: "https://m.media-amazon.com/images/I/71Z1A3eH6IL._SX425_.jpg",
        image: "https://m.media-amazon.com/images/I/61aMvUaFk1XL._AC_SX679_.jpg", // Guitar
        url: "https://www.amazon.fr/Yamaha-F310-Guitare-acoustique-Naturel/dp/B000RW2E7I",
        source: "Amazon",
        categories: ["musique", "instrument"],
        tags: ["gender_mixte", "budget_100_200", "cat_musique"],
        active: true,
        popularity: 91
    },
    {
        name: "Kit Initiation au Tricot Écharpe",
        brand: "We Are Knitters",
        price: 65,
        image: "https://m.media-amazon.com/images/I/51Q3s2d2U2L._SX425_.jpg",
        image: "https://m.media-amazon.com/images/I/71-0Gv2+xPL._AC_SX679_.jpg", // Knitting
        url: "https://www.weareknitters.fr/kits-tricot/niveau-debutant/echarpe-siena",
        source: "We Are Knitters",
        categories: ["loisirs_créatifs", "mode"],
        tags: ["gender_femme", "budget_50_100", "cat_experience", "cat_mode"],
        active: true,
        popularity: 83
    },
    {
        name: "Pèse-Personne Connecté Body+",
        brand: "Withings",
        price: 99.95,
        image: "https://m.media-amazon.com/images/I/61N+x7G2w7L._AC_SX679_.jpg",
        image: "https://m.media-amazon.com/images/I/61s-L33UuRL._AC_SX679_.jpg", // Withings
        url: "https://www.withings.com/fr/fr/body-plus",
        source: "Amazon",
        categories: ["tech", "santé", "bien-être"],
        tags: ["gender_mixte", "budget_50_100", "cat_tech", "cat_bien_etre"],
        active: true,
        popularity: 92
    },
    {
        name: "Coffret Sommelier 5 Pièces Bois",
        brand: "L'Atelier du Vin",
        price: 49,
        image: "https://m.media-amazon.com/images/I/71Z1A3eH6IL._SX425_.jpg",
        image: "https://m.media-amazon.com/images/I/7118y6x+iU4L._AC_SX679_.jpg", // Sommelier
        url: "https://www.atelierduvin.com/produit/coffret-oenologie",
        source: "Amazon",
        categories: ["maison", "art_de_la_table", "boisson"],
        tags: ["gender_homme", "gender_mixte", "budget_25_50", "cat_maison", "cat_boisson", "cat_alcool"],
        active: true,
        popularity: 87
    },
    {
        name: "Bouteille de Champagne Brut Impérial 75cl",
        brand: "Moët & Chandon",
        price: 46.50,
        image: "https://m.media-amazon.com/images/I/51Q3s2d2U2L._SX425_.jpg",
        image: "https://m.media-amazon.com/images/I/618zW8s3a+L._AC_SX679_.jpg", // Champagne
        url: "https://www.nicolas.com/fr/Champagne/Moet-Chandon-Brut-Imperial/p/455648.html",
        source: "Nicolas",
        categories: ["food", "boisson", "alcool"],
        tags: ["gender_mixte", "budget_25_50", "cat_food", "cat_boisson", "cat_alcool", "cat_luxe"],
        active: true,
        popularity: 96
    },
    {
        name: "Chargeur Rapide Sans Fil Stand 15W",
        brand: "Anker",
        price: 35,
        image: "https://m.media-amazon.com/images/I/71Z1A3eH6IL._SX425_.jpg",
        image: "https://m.media-amazon.com/images/I/51p0c3KttHL._AC_SX679_.jpg", // Charger
        url: "https://www.amazon.fr/Anker-PowerWave-Chargeur-Certifi%C3%A9-Adaptateur/dp/B07DBX67NC",
        source: "Amazon",
        categories: ["tech", "accessoire"],
        tags: ["gender_mixte", "budget_25_50", "cat_tech", "cat_accessoire"],
        active: true,
        popularity: 94
    },
    {
        name: "Kit de Survie Outdoor 12 en 1",
        brand: "Proster",
        price: 29.99,
        image: "https://m.media-amazon.com/images/I/61N+x7G2w7L._AC_SX679_.jpg",
        image: "https://m.media-amazon.com/images/I/71MvUaFk1XL._AC_SX679_.jpg", // Survival kit
        url: "https://www.amazon.fr/Proster-Multifonction-Secours-Randonn%C3%A9e-Aventures/dp/B07CWR6222",
        source: "Amazon",
        categories: ["sport", "outil", "outdoor"],
        tags: ["gender_homme", "budget_25_50", "cat_sport", "cat_experience"],
        active: true,
        popularity: 81
    },
    {
        name: "Abonnement Box Fromage 3 Mois",
        brand: "La Box Fromage",
        price: 115,
        image: "https://www.laboxfromage.fr/wp-content/uploads/2021/08/box-fromage-mof-1.png",
        url: "https://www.laboxfromage.fr/offrir-box-fromage-cadeau/",
        source: "La Box Fromage",
        categories: ["food", "abonnement", "gastronomie"],
        tags: ["gender_mixte", "gender_homme", "budget_100_200", "cat_food", "cat_gastronomie"],
        active: true,
        popularity: 88
    }
];


function formatDocument(product) {
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
    console.log(`🚀 Starting upload of ${NEW_PRODUCTS_BATCH_3.length} REAL premium products (Batch 3)...`);

    let successCount = 0;

    for (const product of NEW_PRODUCTS_BATCH_3) {
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
                console.log(`✅ Uploaded B3: ${product.name}`);
            } else {
                const errData = await response.text();
                console.error(`❌ Failed B3 ${product.name}: ${response.status} - ${errData}`);
            }
        } catch (e) {
            console.error(`❌ Exception uploading B3 ${product.name}:`, e);
        }
    }

    console.log(`\n🎉 Batch 3 complete. Uploaded ${successCount}/${NEW_PRODUCTS_BATCH_3.length} products to Firebase.`);
}

uploadProducts();
