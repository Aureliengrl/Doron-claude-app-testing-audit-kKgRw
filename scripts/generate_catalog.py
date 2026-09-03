import json

products = [
    # ── APPLE ──
    {
        "id": "apple_airpods_pro_2",
        "name": "Apple AirPods Pro 2 (USB-C)",
        "brand": "Apple",
        "price": 279.0,
        "url": "https://www.apple.com/fr/airpods-pro/",
        "image": "https://m.media-amazon.com/images/I/61SUj2aKoEL._AC_SL1500_.jpg",
        "description": "Écouteurs sans fil avec réduction active du bruit de niveau pro, audio spatial personnalisé et boîtier MagSafe USB-C.",
        "categories": ["tech", "audio", "trending", "apple"],
        "keywords": ["apple", "airpods", "pro", "sons", "homepod", "audio", "musique", "écouteurs", "sans fil", "bluetooth", "cadeau tech", "noel", "anniversaire", "diplome"],
        "tags": ["gender_mixte", "age_adulte", "age_ado", "budget_200-300", "tech", "audio", "lifestyle"],
        "popularity": 99,
        "active": True
    },
    {
        "id": "apple_watch_series_9",
        "name": "Apple Watch Series 9 GPS 45mm",
        "brand": "Apple",
        "price": 479.0,
        "url": "https://www.apple.com/fr/apple-watch-series-9/",
        "image": "https://m.media-amazon.com/images/I/71XMTLtZd5L._AC_SL1500_.jpg",
        "description": "Montre connectée avec puce S9 puissante, geste toucher deux fois, écran ultra-lumineux et suivi d'entraînement de pointe.",
        "categories": ["tech", "sport", "fashion", "apple"],
        "keywords": ["apple", "watch", "sport", "apple watch", "montre", "connectée", "fitness", "running", "santé", "gps", "noel", "anniversaire"],
        "tags": ["gender_mixte", "age_adulte", "budget_plus_300", "tech", "sport", "montres"],
        "popularity": 98,
        "active": True
    },
    {
        "id": "apple_macbook_air_m3",
        "name": "Apple MacBook Air 13\" Puce M3",
        "brand": "Apple",
        "price": 1299.0,
        "url": "https://www.apple.com/fr/macbook-air/",
        "image": "https://m.media-amazon.com/images/I/71ItMeqpN3L._AC_SL1500_.jpg",
        "description": "Ordinateur portable ultra-fin et ultra-rapide avec puce Apple M3, écran Liquid Retina et jusqu'à 18h d'autonomie.",
        "categories": ["tech", "apple", "trending"],
        "keywords": ["apple", "macbook", "air", "m3", "professionnel", "macbook air", "ordinateurs", "laptop", "pc", "bureau", "diplome", "mariage"],
        "tags": ["gender_mixte", "age_adulte", "budget_plus_300", "tech", "ordinateurs", "bureau"],
        "popularity": 97,
        "active": True
    },
    {
        "id": "apple_homepod_mini",
        "name": "Apple HomePod mini Bleu",
        "brand": "Apple",
        "price": 109.0,
        "url": "https://www.apple.com/fr/homepod-mini/",
        "image": "https://m.media-amazon.com/images/I/61vY+4t4cEL._AC_SL1000_.jpg",
        "description": "Enceinte intelligente avec son immersif à 360°, assistant Siri et hub domotique pour toute la maison.",
        "categories": ["tech", "home", "audio", "apple"],
        "keywords": ["apple", "homepod", "mini", "sons", "homepod airpods", "audio", "enceinte", "maison", "salon", "musique", "domotique", "cremaillere", "noel"],
        "tags": ["gender_mixte", "age_adulte", "budget_100-200", "tech", "home", "audio"],
        "popularity": 94,
        "active": True
    },
    {
        "id": "apple_iphone_15_pro",
        "name": "Apple iPhone 15 Pro Titane Naturel",
        "brand": "Apple",
        "price": 1199.0,
        "url": "https://www.apple.com/fr/iphone-15-pro/",
        "image": "https://m.media-amazon.com/images/I/81+GIkwqLIL._AC_SL1500_.jpg",
        "description": "Design en titane aérospatial, puce A17 Pro révolutionnaire, bouton Action et système photo pro surpuissant.",
        "categories": ["tech", "trending", "apple"],
        "keywords": ["apple", "iphone", "smartphones", "iphone 15 pro", "mobile", "téléphone", "photo", "technologie", "diplome", "anniversaire"],
        "tags": ["gender_mixte", "age_adulte", "budget_plus_300", "tech", "smartphones"],
        "popularity": 99,
        "active": True
    },

    # ── NIKE ──
    {
        "id": "nike_dunk_low_panda",
        "name": "Nike Dunk Low Retro Black White Panda",
        "brand": "Nike",
        "price": 119.99,
        "url": "https://www.nike.com/fr/t/dunk-low-retro-chaussure-jG0L9L/DD1391-100",
        "image": "https://static.nike.com/a/images/t_PDP_1728_v1/f_auto,q_auto:eco/bda4e015-9d2e-4bc6-96a3-ef0790804c89/dunk-low-retro-chaussure-pour-homme.png",
        "description": "L'icône du basketball des années 80 revient avec son coloris bicolore intemporel et son cuir premium.",
        "categories": ["fashion", "sport", "trending", "nike"],
        "keywords": ["nike", "dunk", "panda", "sneakers", "lifestyle", "streetwear", "chaussures", "baskets", "mode", "viral tiktok", "anniversaire", "noel"],
        "tags": ["gender_mixte", "age_ado", "age_adulte", "budget_100-200", "fashion", "sneakers"],
        "popularity": 99,
        "active": True
    },
    {
        "id": "nike_pegasus_40_running",
        "name": "Nike Air Zoom Pegasus 40",
        "brand": "Nike",
        "price": 129.99,
        "url": "https://www.nike.com/fr/t/air-zoom-pegasus-40-chaussure-de-running-sur-route-1F1hN6",
        "image": "https://static.nike.com/a/images/t_PDP_1728_v1/f_auto,q_auto:eco/e9bf9b05-c155-4674-8fa2-68c3ef05eb43/air-zoom-pegasus-40-chaussure-de-running-sur-route-pour-homme.png",
        "description": "Chaussure de running réactive et confortable avec mousse Nike React et double unité Zoom Air.",
        "categories": ["sport", "nike"],
        "keywords": ["nike", "running", "pegasus", "course", "sport", "marathon", "fitness", "entrainement", "baskets", "fete_peres"],
        "tags": ["gender_mixte", "age_adulte", "budget_100-200", "sport", "running"],
        "popularity": 95,
        "active": True
    },
    {
        "id": "nike_mercurial_football",
        "name": "Nike Zoom Mercurial Superfly 9 Academy",
        "brand": "Nike",
        "price": 89.99,
        "url": "https://www.nike.com/fr/t/zoom-mercurial-superfly-9-academy-mg-chaussure-de-football-multi-surfaces-lZ9mN9",
        "image": "https://static.nike.com/a/images/t_PDP_1728_v1/f_auto,q_auto:eco/c85a0833-2895-4eb8-b9a5-a3dca9bf4a85/zoom-mercurial-superfly-9-academy-mg-chaussures-de-football-multi-surfaces.png",
        "description": "Crampons de football avec unité Zoom Air pour dominer le terrain et accélérer dans les moments décisifs.",
        "categories": ["sport", "nike"],
        "keywords": ["nike", "football", "crampons", "mercurial", "foot", "sport", "match", "world cup", "finale coupe du monde", "anniversaire"],
        "tags": ["gender_homme", "age_ado", "age_adulte", "budget_50-100", "sport", "football"],
        "popularity": 96,
        "active": True
    },
    {
        "id": "nike_tech_fleece_hoodie",
        "name": "Nike Sportswear Tech Fleece Windrunner",
        "brand": "Nike",
        "price": 119.99,
        "url": "https://www.nike.com/fr/t/sweat-a-capuche-fermeture-entiere-sportswear-tech-fleece-windrunner-pour-homme-XGq9c8",
        "image": "https://static.nike.com/a/images/t_PDP_1728_v1/f_auto,q_auto:eco/f8c7b643-982d-4bfb-93ff-ea5a76c666f7/sweat-a-capuche-fermeture-entiere-sportswear-tech-fleece-windrunner-pour-homme.png",
        "description": "Sweat à capuche zippé en molleton Tech Fleece léger et isolant, coupe moderne et style urbain.",
        "categories": ["fashion", "sport", "trending", "nike"],
        "keywords": ["nike", "streetwear", "tech fleece", "hoodie", "sweat", "mode", "lifestyle", "lifestyle nike", "vetements", "noel", "anniversaire"],
        "tags": ["gender_mixte", "age_ado", "age_adulte", "budget_100-200", "fashion", "streetwear"],
        "popularity": 98,
        "active": True
    },

    # ── LEGO ──
    {
        "id": "lego_star_wars_millennium_falcon",
        "name": "LEGO Star Wars Faucon Millennium 75257",
        "brand": "LEGO",
        "price": 169.99,
        "url": "https://www.lego.com/fr-fr/product/millennium-falcon-75257",
        "image": "https://m.media-amazon.com/images/I/81x1R0VqI0L._AC_SL1500_.jpg",
        "description": "Vaisseau culte de Star Wars avec tourelles rotatives, cockpit ouvrant et 7 figurines collector.",
        "categories": ["gaming", "art", "trending", "lego"],
        "keywords": ["lego", "star wars", "faucon millennium", "adultes", "jeux", "construction", "vaisseau", "pop-culture", "noel", "anniversaire", "gros cadeaux"],
        "tags": ["gender_mixte", "age_adulte", "age_ado", "budget_100-200", "gaming", "star_wars"],
        "popularity": 99,
        "active": True
    },
    {
        "id": "lego_technic_porsche_gt4",
        "name": "LEGO Technic Porsche GT4 e-Performance",
        "brand": "LEGO",
        "price": 169.99,
        "url": "https://www.lego.com/fr-fr/product/porsche-gt4-e-performance-42176",
        "image": "https://m.media-amazon.com/images/I/81oK13P-qKL._AC_SL1500_.jpg",
        "description": "Voiture de course télécommandée LEGO Technic ultra-détaillée avec direction fonctionnelle et phares LED.",
        "categories": ["mechanic", "gaming", "lego"],
        "keywords": ["lego", "technic", "porsche", "mecanique", "modelisme", "accessoires auto", "voiture", "circuit", "pilotage", "adultes", "fete_peres"],
        "tags": ["gender_mixte", "age_adulte", "budget_100-200", "mechanic", "technic"],
        "popularity": 96,
        "active": True
    },
    {
        "id": "lego_architecture_paris",
        "name": "LEGO Architecture Paris 21044",
        "brand": "LEGO",
        "price": 49.99,
        "url": "https://www.lego.com/fr-fr/product/paris-21044",
        "image": "https://m.media-amazon.com/images/I/81V28Xg-7PL._AC_SL1500_.jpg",
        "description": "Skyline majestueuse de Paris regroupant la Tour Eiffel, l'Arc de Triomphe, le Louvre et les Champs-Élysées.",
        "categories": ["art", "home", "travel", "lego"],
        "keywords": ["lego", "architecture", "paris", "decoration", "monuments", "tour eiffel", "salon", "design", "voyage", "adultes", "cremaillere"],
        "tags": ["gender_mixte", "age_adulte", "budget_25-50", "art", "home", "architecture"],
        "popularity": 97,
        "active": True
    },
    {
        "id": "lego_harry_potter_hogwarts_castle",
        "name": "LEGO Harry Potter Le Château de Poudlard",
        "brand": "LEGO",
        "price": 169.99,
        "url": "https://www.lego.com/fr-fr/product/hogwarts-castle-and-grounds-76419",
        "image": "https://m.media-amazon.com/images/I/81K0hHqQ4tL._AC_SL1500_.jpg",
        "description": "Modèle d'exposition somptueux du château de Poudlard et de ses terrains magiques pour adultes et passionnés.",
        "categories": ["reading", "art", "trending", "lego"],
        "keywords": ["lego", "harry potter", "poudlard", "adultes", "magie", "sorcier", "livres", "pop-culture", "chateau", "noel", "anniversaire"],
        "tags": ["gender_mixte", "age_adulte", "budget_100-200", "reading", "harry_potter"],
        "popularity": 98,
        "active": True
    },

    # ── SEPHORA & BEAUTÉ ──
    {
        "id": "dior_sauvage_elixir",
        "name": "Dior Sauvage Elixir 60ml",
        "brand": "Sephora",
        "price": 149.0,
        "url": "https://www.sephora.fr/p/sauvage-elixir---parfum-P10018590.html",
        "image": "https://m.media-amazon.com/images/I/61c8v3rQ2ML._AC_SL1000_.jpg",
        "description": "Parfum d'une concentration et d'une intensité rares, mêlant notes d'épices nobles et cœur de lavande sur-mesure.",
        "categories": ["beauty", "fashion", "sephora"],
        "keywords": ["sephora", "parfums", "dior", "sauvage", "elixir", "homme", "luxe", "fragrance", "soins visage", "st_valentin", "fete_peres", "noel"],
        "tags": ["gender_homme", "age_adulte", "budget_100-200", "beauty", "parfums"],
        "popularity": 99,
        "active": True
    },
    {
        "id": "ysl_libre_eau_de_parfum",
        "name": "Yves Saint Laurent Libre Eau de Parfum 50ml",
        "brand": "Sephora",
        "price": 115.0,
        "url": "https://www.sephora.fr/p/libre---eau-de-parfum-P3850020.html",
        "image": "https://m.media-amazon.com/images/I/61K5QyO78VL._AC_SL1000_.jpg",
        "description": "La fragrance d'une femme forte et audacieuse, alliance brûlante de la fleur d'oranger du Maroc et de la lavande de France.",
        "categories": ["beauty", "fashion", "sephora"],
        "keywords": ["sephora", "parfums", "ysl", "libre", "femme", "luxe", "coffrets", "beaute", "st_valentin", "fete_meres", "anniversaire"],
        "tags": ["gender_femme", "age_adulte", "budget_100-200", "beauty", "parfums"],
        "popularity": 98,
        "active": True
    },
    {
        "id": "rare_beauty_soft_pinch_blush",
        "name": "Rare Beauty Soft Pinch Blush Liquide",
        "brand": "Sephora",
        "price": 27.0,
        "url": "https://www.sephora.fr/p/soft-pinch---blush-liquide-P10015570.html",
        "image": "https://m.media-amazon.com/images/I/51wXpMh2YKL._AC_SL1000_.jpg",
        "description": "Le blush liquide culte et viral de Selena Gomez à la pigmentation aérienne et au fini seconde peau radieux.",
        "categories": ["beauty", "trending", "sephora"],
        "keywords": ["sephora", "maquillage", "blush", "rare beauty", "skincare", "viral tiktok", "selena gomez", "beaute", "petites attentions", "secret santa"],
        "tags": ["gender_femme", "age_ado", "age_adulte", "budget_25-50", "beauty", "makeup"],
        "popularity": 99,
        "active": True
    },
    {
        "id": "sol_de_janeiro_cheirosa_68",
        "name": "Sol de Janeiro Brume Cheirosa 68 240ml",
        "brand": "Sephora",
        "price": 38.0,
        "url": "https://www.sephora.fr/p/cheirosa-68---brume-parfumee-corps-et-cheveux-P10023770.html",
        "image": "https://m.media-amazon.com/images/I/61iV8X69Q6L._AC_SL1500_.jpg",
        "description": "Brume parfumée corps et cheveux aux notes ensoleillées de jasmin brésilien et de fruit du dragon.",
        "categories": ["beauty", "trending", "sephora"],
        "keywords": ["sephora", "soins du corps", "brume", "sol de janeiro", "cheirosa", "viral tiktok", "parfums", "soins", "anniversaire"],
        "tags": ["gender_femme", "age_ado", "age_adulte", "budget_25-50", "beauty", "bodycare"],
        "popularity": 98,
        "active": True
    },

    # ── DYSON ──
    {
        "id": "dyson_airwrap_multi_styler",
        "name": "Dyson Airwrap Multi-Styler Complete Long",
        "brand": "Dyson",
        "price": 549.0,
        "url": "https://www.dyson.fr/soin-des-cheveux/dyson-airwrap",
        "image": "https://m.media-amazon.com/images/I/61SjL796ZKL._AC_SL1500_.jpg",
        "description": "Boucle, sculpte, lisse et maîtrise les cheveux rebelles grâce à l'effet Coanda sans chaleur extrême.",
        "categories": ["beauty", "tech", "trending", "dyson"],
        "keywords": ["dyson", "cheveux", "airwrap", "lisseur", "boucleur", "coiffure", "beaute", "luxe", "viral tiktok", "gros cadeaux", "noel", "anniversaire"],
        "tags": ["gender_femme", "age_adulte", "budget_plus_300", "beauty", "haircare"],
        "popularity": 99,
        "active": True
    },
    {
        "id": "dyson_v15_detect_aspirateur",
        "name": "Dyson V15 Detect Absolute Sans Fil",
        "brand": "Dyson",
        "price": 699.0,
        "url": "https://www.dyson.fr/aspirateurs/sans-fil/dyson-v15-detect",
        "image": "https://m.media-amazon.com/images/I/61vY+4t4cEL._AC_SL1000_.jpg",
        "description": "Aspirateur sans fil le plus puissant avec laser pour révéler la poussière invisible et écran LCD intelligent.",
        "categories": ["home", "tech", "dyson"],
        "keywords": ["dyson", "aspirateurs", "v15", "maison", "cuisine", "salon", "nettoyage", "technologie", "cremaillere", "mariage"],
        "tags": ["gender_mixte", "age_adulte", "budget_plus_300", "home", "cleaning"],
        "popularity": 96,
        "active": True
    },
    {
        "id": "dyson_purifier_hot_cool",
        "name": "Dyson Purifier Hot+Cool Gen1",
        "brand": "Dyson",
        "price": 449.0,
        "url": "https://www.dyson.fr/traitement-de-l-air/purificateurs-chauffage-ventilateur",
        "image": "https://m.media-amazon.com/images/I/51wXpMh2YKL._AC_SL1000_.jpg",
        "description": "Purifie toute la pièce, chauffe en hiver et ventile en été tout en capturant 99,95% des polluants.",
        "categories": ["home", "tech", "wellness", "dyson"],
        "keywords": ["dyson", "purificateurs", "chauffage", "ventilateur", "air", "maison", "salon", "chambre", "bien-etre", "cremaillere"],
        "tags": ["gender_mixte", "age_adulte", "budget_plus_300", "home", "wellness"],
        "popularity": 94,
        "active": True
    },

    # ── SONY & GAMING ──
    {
        "id": "sony_playstation_5_slim",
        "name": "Sony PlayStation 5 Slim Edition Standard",
        "brand": "Sony",
        "price": 549.99,
        "url": "https://www.playstation.com/fr-fr/ps5/",
        "image": "https://m.media-amazon.com/images/I/51051FiD9UL._AC_SL1000_.jpg",
        "description": "Console de jeux next-gen avec SSD ultra-rapide, retour haptique DualSense et graphismes 4K éblouissants.",
        "categories": ["gaming", "tech", "trending", "sony"],
        "keywords": ["sony", "playstation", "ps5", "consoles", "jeux pc", "gaming", "jeux video", "manette", "gros cadeaux", "noel", "anniversaire"],
        "tags": ["gender_mixte", "age_ado", "age_adulte", "budget_plus_300", "gaming", "consoles"],
        "popularity": 99,
        "active": True
    },
    {
        "id": "sony_wh_1000xm5_casque",
        "name": "Sony WH-1000XM5 Casque Bluetooth ANC",
        "brand": "Sony",
        "price": 329.0,
        "url": "https://www.sony.fr/electronics/casque-bandeau/wh-1000xm5",
        "image": "https://m.media-amazon.com/images/I/61+btxzpfDL._AC_SL1500_.jpg",
        "description": "Casque audio circum-aural avec réduction de bruit leader du marché, 8 micros et confort longue durée.",
        "categories": ["tech", "music", "travel", "sony"],
        "keywords": ["sony", "audio", "casque", "wh-1000xm5", "musique", "hi-fi", "voyage", "bagages", "bluetooth", "diplome", "anniversaire"],
        "tags": ["gender_mixte", "age_adulte", "budget_plus_300", "tech", "audio", "music"],
        "popularity": 98,
        "active": True
    },

    # ── FOOD & GASTRONOMIE ──
    {
        "id": "nespresso_vertuo_pop",
        "name": "Nespresso Machine Vertuo Pop Jaune Mangue",
        "brand": "Nespresso",
        "price": 79.0,
        "url": "https://www.nespresso.com/fr/fr/order/machines/vertuo/machine-vertuo-pop-yellow",
        "image": "https://m.media-amazon.com/images/I/71Y9L3d6QBL._AC_SL1500_.jpg",
        "description": "Machine à café design et compacte, extraction Centrifusion pour 4 tailles de tasses avec crème onctueuse.",
        "categories": ["food", "home", "trending"],
        "keywords": ["food", "cafe & the", "cuisine", "nespresso", "machine a cafe", "gastronomie", "maison", "cremaillere", "noel", "fete_meres", "fete_peres"],
        "tags": ["gender_mixte", "age_adulte", "budget_50-100", "food", "coffee", "home"],
        "popularity": 97,
        "active": True
    },
    {
        "id": "le_creuset_cocotte_fonte",
        "name": "Le Creuset Cocotte Ronde en Fonte Émaillée 24cm",
        "brand": "Le Creuset",
        "price": 289.0,
        "url": "https://www.lecreuset.fr/fr_FR/p/cocotte-ronde-en-fonte-emaillee/CI0177.html",
        "image": "https://m.media-amazon.com/images/I/71LqK6-6T8L._AC_SL1500_.jpg",
        "description": "La référence culinaire française pour mijoter les meilleurs plats, garantie à vie et couleur Cerise iconique.",
        "categories": ["food", "home"],
        "keywords": ["food", "cuisine", "le creuset", "cocotte", "vaisselle", "gastronomie", "epicerie fine", "mariage", "fete_meres", "cremaillere"],
        "tags": ["gender_mixte", "age_adulte", "budget_200-300", "food", "kitchen", "home"],
        "popularity": 95,
        "active": True
    },
    {
        "id": "coffret_vin_bordeaux_grand_cru",
        "name": "Coffret Dégustation Grands Crus de Bordeaux (3 Bouteilles)",
        "brand": "Millésimes",
        "price": 89.0,
        "url": "https://www.millesimes.com/",
        "image": "https://m.media-amazon.com/images/I/81A6Q3wEwSL._AC_SL1500_.jpg",
        "description": "Coffret en bois précieux réunissant trois millésimes d'exception issus des plus grands terroirs bordelais.",
        "categories": ["food"],
        "keywords": ["food", "vin & spiritueux", "bordeaux", "coffret vin", "gastronomie", "epicerie fine", "fete_peres", "pot_depart", "mariage", "noel"],
        "tags": ["gender_mixte", "age_adulte", "budget_50-100", "food", "wine"],
        "popularity": 96,
        "active": True
    },
    {
        "id": "chocolats_marcolini_coffret",
        "name": "Pierre Marcolini Coffret Découverte Pralinés & Ganaches",
        "brand": "Pierre Marcolini",
        "price": 39.0,
        "url": "https://eu.marcolini.com/",
        "image": "https://m.media-amazon.com/images/I/71e9T9v2xKL._AC_SL1500_.jpg",
        "description": "Sélection de 24 chocolats haute couture confectionnés à partir de fèves de cacao d'origine pure.",
        "categories": ["food", "trending"],
        "keywords": ["food", "chocolat", "box culinaires", "marcolini", "gourmandises", "st_valentin", "fete_meres", "noel", "secret santa"],
        "tags": ["gender_mixte", "age_adulte", "budget_25-50", "food", "chocolate"],
        "popularity": 97,
        "active": True
    },

    # ── AÉRONAUTIQUE & MÉCANIQUE ──
    {
        "id": "maquette_concorde_airfrance",
        "name": "Maquette Officielle Concorde Air France 1/200",
        "brand": "Heller",
        "price": 69.0,
        "url": "https://www.airfrance.fr/",
        "image": "https://m.media-amazon.com/images/I/71zN0fG3aKL._AC_SL1500_.jpg",
        "description": "Reproduction de haute précision en métal du légendaire avion supersonique Concorde avec socle d'exposition en bois.",
        "categories": ["aeronautic", "art"],
        "keywords": ["aeronautic", "maquettes", "concorde", "avions", "simulateurs", "livres aviation", "aviation", "fete_peres", "anniversaire", "passion"],
        "tags": ["gender_mixte", "age_adulte", "budget_50-100", "aeronautic"],
        "popularity": 93,
        "active": True
    },
    {
        "id": "stage_pilotage_ferrari",
        "name": "Stage de Pilotage Ferrari F8 Tributo sur Circuit (Coffret)",
        "brand": "Smartbox",
        "price": 149.90,
        "url": "https://www.smartbox.com/fr/",
        "image": "https://m.media-amazon.com/images/I/81x1R0VqI0L._AC_SL1500_.jpg",
        "description": "Prenez le volant d'un bolide de 720 chevaux sur circuit encadré par des pilotes instructeurs professionnels.",
        "categories": ["mechanic", "sport", "trending"],
        "keywords": ["mechanic", "stage de pilotage", "ferrari", "accessoires auto", "modelisme", "outillage", "voiture", "vitesse", "fete_peres", "anniversaire", "diplome"],
        "tags": ["gender_mixte", "age_adulte", "budget_100-200", "mechanic", "experience"],
        "popularity": 97,
        "active": True
    },

    # ── LECTURE & MANGAS ──
    {
        "id": "kindle_paperwhite_signature",
        "name": "Amazon Kindle Paperwhite Signature Edition 32 Go",
        "brand": "Amazon",
        "price": 189.99,
        "url": "https://www.amazon.fr/dp/B08N3TCP2F",
        "image": "https://m.media-amazon.com/images/I/71W8hP2Q4zL._AC_SL1500_.jpg",
        "description": "Liseuse sans reflets avec écran 6,8\", éclairage chaud réglable automatiquement et charge sans fil.",
        "categories": ["reading", "tech"],
        "keywords": ["reading", "liseuses", "kindle", "romans", "mangas", "bd", "developpement personnel", "livres", "lecture", "noel", "voyage"],
        "tags": ["gender_mixte", "age_adulte", "budget_100-200", "reading", "tech"],
        "popularity": 96,
        "active": True
    },
    {
        "id": "one_piece_coffret_tomes_1_23",
        "name": "Coffret Manga One Piece Tomes 1 à 23 - Saga East Blue",
        "brand": "Glénat",
        "price": 160.0,
        "url": "https://www.glenat.com/",
        "image": "https://m.media-amazon.com/images/I/81vP7f6mYIL._AC_SL1500_.jpg",
        "description": "Le coffret collector officiel de l'embarquement de Luffy et de son équipage pour Grand Line.",
        "categories": ["reading", "art", "trending"],
        "keywords": ["reading", "mangas", "one piece", "bd", "romans", "luffy", "anime", "pop-culture", "livres", "anniversaire", "noel"],
        "tags": ["gender_mixte", "age_ado", "age_adulte", "budget_100-200", "reading", "manga"],
        "popularity": 99,
        "active": True
    },

    # ── VOYAGE & OUTDOOR ──
    {
        "id": "valise_samsonite_s_cure_spinner",
        "name": "Samsonite S'Cure Spinner 75cm Valise Rigide",
        "brand": "Samsonite",
        "price": 199.0,
        "url": "https://www.samsonite.fr/",
        "image": "https://m.media-amazon.com/images/I/71iZ5R9G5lL._AC_SL1500_.jpg",
        "description": "Fabriquée en Europe avec le matériau révolutionnaire Flowlite, serrure 3 points et roulettes silencieuses 360°.",
        "categories": ["travel", "fashion"],
        "keywords": ["travel", "bagages", "accessoires de voyage", "valise", "samsonite", "voyage de noces", "mariage", "diplome", "vacances"],
        "tags": ["gender_mixte", "age_adulte", "budget_100-200", "travel", "luggage"],
        "popularity": 95,
        "active": True
    },

    # ── MUSIQUE ──
    {
        "id": "platine_vinyle_audio_technica",
        "name": "Audio-Technica AT-LP60XBT Platine Vinyle Bluetooth",
        "brand": "Audio-Technica",
        "price": 199.0,
        "url": "https://www.audio-technica.com/",
        "image": "https://m.media-amazon.com/images/I/71eX3r6Pq5L._AC_SL1500_.jpg",
        "description": "Platine tourne-disque entièrement automatique avec préampli commutable et connexion sans fil Bluetooth.",
        "categories": ["music", "home", "trending"],
        "keywords": ["music", "vinyles", "instruments", "hi-fi", "platine", "musique", "salon", "concerts", "fete_musique", "anniversaire", "cremaillere"],
        "tags": ["gender_mixte", "age_adulte", "budget_100-200", "music", "audio", "vintage"],
        "popularity": 97,
        "active": True
    },
    {
        "id": "marshall_stanmore_iii",
        "name": "Marshall Stanmore III Enceinte Stéréo Maison",
        "brand": "Marshall",
        "price": 369.0,
        "url": "https://www.marshallheadphones.com/",
        "image": "https://m.media-amazon.com/images/I/81x1R0VqI0L._AC_SL1500_.jpg",
        "description": "Le son légendaire Marshall avec scène sonore élargie, boutons cuivrés iconiques et connectivité Bluetooth 5.2.",
        "categories": ["music", "home", "tech"],
        "keywords": ["music", "hi-fi", "enceintes portables", "marshall", "rock", "salon", "decoration", "fete_musique", "noel", "gros cadeaux"],
        "tags": ["gender_mixte", "age_adulte", "budget_plus_300", "music", "home", "design"],
        "popularity": 98,
        "active": True
    },

    # ── JARDINAGE & MAISON ──
    {
        "id": "potager_interieur_veritable",
        "name": "Véritable Smart Potager d'Intérieur Connecté",
        "brand": "Véritable",
        "price": 149.0,
        "url": "https://www.veritable-potager.fr/",
        "image": "https://m.media-amazon.com/images/I/71K0hHqQ4tL._AC_SL1500_.jpg",
        "description": "Cultivez vos herbes aromatiques et petits légumes frais toute l'année dans votre cuisine sans effort.",
        "categories": ["garden", "home", "wellness"],
        "keywords": ["garden", "plantes d'interieur", "graines", "outillage jardin", "cuisine", "plantes", "maison", "fete_grand_meres", "fete_meres", "cremaillere"],
        "tags": ["gender_mixte", "age_adulte", "budget_100-200", "garden", "home"],
        "popularity": 94,
        "active": True
    },

    # ── BIEN-ÊTRE & YOGA ──
    {
        "id": "tapis_yoga_manduka_pro",
        "name": "Manduka PRO Tapis de Yoga Haute Densité 6mm",
        "brand": "Manduka",
        "price": 120.0,
        "url": "https://www.manduka.com/",
        "image": "https://m.media-amazon.com/images/I/61K5QyO78VL._AC_SL1000_.jpg",
        "description": "Le tapis plébiscité par les professeurs de yoga du monde entier pour son amorti inégalé et son adhérence.",
        "categories": ["wellness", "sport"],
        "keywords": ["wellness", "yoga", "massages", "huiles essentielles", "spa a domicile", "fitness", "detente", "relaxation", "fete_meres", "anniversaire"],
        "tags": ["gender_mixte", "age_adulte", "budget_100-200", "wellness", "fitness"],
        "popularity": 95,
        "active": True
    },
    {
        "id": "diffuseur_huiles_essentielles_ultrasonique",
        "name": "Diffuseur d'Huiles Essentielles en Céramique & Bois",
        "brand": "Pranarôm",
        "price": 59.0,
        "url": "https://www.pranarom.fr/",
        "image": "https://m.media-amazon.com/images/I/61vY+4t4cEL._AC_SL1000_.jpg",
        "description": "Diffusion ultrasonique à froid préservant les vertus des huiles, veilleuse chaleureuse et design scandinave.",
        "categories": ["wellness", "home"],
        "keywords": ["wellness", "huiles essentielles", "spa a domicile", "detente", "chambre", "salon", "decoration", "noel", "cremaillere"],
        "tags": ["gender_mixte", "age_adulte", "budget_50-100", "wellness", "home"],
        "popularity": 96,
        "active": True
    },

    # ── ART & CRÉATION ──
    {
        "id": "posca_mallette_60_marqueurs",
        "name": "Mallette Métallique 60 Marqueurs POSCA Multisupports",
        "brand": "POSCA",
        "price": 139.0,
        "url": "https://www.posca.com/",
        "image": "https://m.media-amazon.com/images/I/81oK13P-qKL._AC_SL1500_.jpg",
        "description": "Assortiment complet des célèbres feutres peinture acrylique à base d'eau, pointes fines, moyennes et larges.",
        "categories": ["art", "reading"],
        "keywords": ["art", "materiel de dessin", "peinture", "tableaux", "sculpture", "livres d'art", "creativite", "illustration", "anniversaire", "noel"],
        "tags": ["gender_mixte", "age_ado", "age_adulte", "budget_100-200", "art", "drawing"],
        "popularity": 97,
        "active": True
    }
]

# Enrichissement & fusion avec le catalogue existant pour atteindre plus de 400 produits complets
with open('assets/jsons/fallback_products.json', 'r') as f:
    existing = json.load(f)

# Mapper et enrichir les produits existants
for idx, p in enumerate(existing):
    p_id = f"fallback_{idx}_{p.get('id', idx)}"
    p['id'] = p_id
    p['active'] = True
    if 'popularity' not in p or not p['popularity']:
        p['popularity'] = 85
    if 'categories' not in p or not p['categories']:
        p['categories'] = ['trending']
    if 'keywords' not in p:
        p['keywords'] = [p.get('name', '').lower(), p.get('brand', '').lower()] + p.get('categories', [])

# Combiner
combined = products + existing
print(f"Total catalogue généré: {len(combined)} produits")

with open('assets/jsons/fallback_products.json', 'w') as f:
    json.dump(combined, f, indent=2, ensure_ascii=False)

print("assets/jsons/fallback_products.json mis à jour avec succès !")
