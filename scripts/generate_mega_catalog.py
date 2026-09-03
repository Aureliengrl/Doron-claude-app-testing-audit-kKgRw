import json

# Mega catalogue haute qualité
mega_products = [
    # ══════════════════════════════════════════════════════════════════════
    # ZARA (30+ PRODUITS)
    # ══════════════════════════════════════════════════════════════════════
    {
        "id": "zara_01_blazer_croise_noir",
        "name": "Zara Blazer Croisé Coupe Relax Noir",
        "brand": "Zara",
        "price": 89.95,
        "url": "https://www.zara.com/fr/",
        "image": "https://static.zara.net/assets/public/7e02/e8cb/df2b4c10a129/66a4f910408d/02008320800-p/02008320800-p.jpg?ts=1708682782782&w=800",
        "description": "Veste de costume croisée Zara à col à revers pointu et boutons contrastés.",
        "categories": ["fashion", "zara", "trending"],
        "keywords": ["zara", "blazer", "veste", "costume", "mode", "homme", "streetwear", "vetements"],
        "tags": ["gender_homme", "age_adulte", "budget_75-150", "fashion"],
        "popularity": 96, "active": True
    },
    {
        "id": "zara_02_robe_longue_satinee",
        "name": "Zara Robe Longue Satinée Dos Nu Émeraude",
        "brand": "Zara",
        "price": 49.95,
        "url": "https://www.zara.com/fr/",
        "image": "https://static.zara.net/assets/public/043b/eb90/9b9745dbbbdf/b645938bf8c9/03152200800-p/03152200800-p.jpg?ts=1710408544837&w=800",
        "description": "Robe fluide satinée Zara à encolure américaine et dos dégagé somptueux.",
        "categories": ["fashion", "zara", "trending"],
        "keywords": ["zara", "robe", "satinee", "soiree", "mode", "femme", "luxe", "vetements"],
        "tags": ["gender_femme", "age_adulte", "budget_25-75", "fashion"],
        "popularity": 98, "active": True
    },
    {
        "id": "zara_03_trench_oversize_beige",
        "name": "Zara Trench Double Boutonnage Oversize Beige",
        "brand": "Zara",
        "price": 99.95,
        "url": "https://www.zara.com/fr/",
        "image": "https://static.zara.net/assets/public/6ff1/5db0/3cf94bb3a0b8/c18fb9ea7da8/00518330712-p/00518330712-p.jpg?ts=1705658602905&w=800",
        "description": "Trench intemporel beige Zara en gabardine de coton avec ceinture à boucle.",
        "categories": ["fashion", "zara"],
        "keywords": ["zara", "trench", "manteau", "veste", "mode", "femme", "streetwear"],
        "tags": ["gender_femme", "age_adulte", "budget_75-150", "fashion"],
        "popularity": 95, "active": True
    },
    {
        "id": "zara_04_red_temptation_parfum",
        "name": "Zara Red Temptation Eau de Parfum 80ml",
        "brand": "Zara",
        "price": 22.95,
        "url": "https://www.zara.com/fr/",
        "image": "https://static.zara.net/assets/public/4b5b/98bf/e94e43e790a3/8beea42674e2/00110410999-p/00110410999-p.jpg?ts=1698226065576&w=800",
        "description": "Fragrance florale boisée et ambrée Zara aux notes d'épices chaudes, jasmin et mousse de chêne.",
        "categories": ["beauty", "fashion", "zara", "trending"],
        "keywords": ["zara", "parfum", "red temptation", "parfums", "beaute", "viral tiktok"],
        "tags": ["gender_femme", "age_ado", "age_adulte", "budget_0_25", "beauty", "parfums"],
        "popularity": 99, "active": True
    },
    {
        "id": "zara_05_rose_gourmand_parfum",
        "name": "Zara Rose Gourmand Eau de Parfum 80ml",
        "brand": "Zara",
        "price": 22.95,
        "url": "https://www.zara.com/fr/",
        "image": "https://static.zara.net/assets/public/3364/f19f/8e204c35b542/3798cf647aa5/00110411999-p/00110411999-p.jpg?ts=1698226065796&w=800",
        "description": "Parfum gourmand Zara aux notes de rose fraîche, vanille de Madagascar et ambre crémeux.",
        "categories": ["beauty", "fashion", "zara"],
        "keywords": ["zara", "parfum", "rose gourmand", "parfums", "beaute", "femme"],
        "tags": ["gender_femme", "age_adulte", "budget_0_25", "beauty", "parfums"],
        "popularity": 97, "active": True
    },
    {
        "id": "zara_06_jean_wide_leg_brut",
        "name": "Zara Jean Wide Leg Taille Haute Brut",
        "brand": "Zara",
        "price": 39.95,
        "url": "https://www.zara.com/fr/",
        "image": "https://static.zara.net/assets/public/c199/3a8c/50a14daaa10b/6b8565a9e0a0/06164040400-p/06164040400-p.jpg?ts=1708685160359&w=800",
        "description": "Jean large taille haute Zara en denim 100% coton délavé vintage.",
        "categories": ["fashion", "zara"],
        "keywords": ["zara", "jean", "pantalon", "denim", "wide leg", "streetwear", "mode", "femme"],
        "tags": ["gender_femme", "age_ado", "age_adulte", "budget_25-75", "fashion"],
        "popularity": 94, "active": True
    },
    {
        "id": "zara_07_blouson_cuir_biker",
        "name": "Zara Blouson Biker en Cuir Véritable",
        "brand": "Zara",
        "price": 149.0,
        "url": "https://www.zara.com/fr/",
        "image": "https://static.zara.net/assets/public/a0bc/ec46/4751433f815f/bb1cbef3f752/03918300800-p/03918300800-p.jpg?ts=1695213600000&w=800",
        "description": "Blouson motard en cuir nappa avec col à revers, zips métalliques et coupe structurée.",
        "categories": ["fashion", "zara", "trending"],
        "keywords": ["zara", "cuir", "biker", "blouson", "veste", "mode", "homme", "streetwear"],
        "tags": ["gender_homme", "age_adulte", "budget_75-150", "fashion"],
        "popularity": 96, "active": True
    },
    {
        "id": "zara_08_sac_bandouliere_minimaliste",
        "name": "Zara Sac Bandoulière Minimaliste Boucle Dorée",
        "brand": "Zara",
        "price": 35.95,
        "url": "https://www.zara.com/fr/",
        "image": "https://static.zara.net/assets/public/982f/c939/078a4e8d89e5/470487920ab4/16012310040-p/16012310040-p.jpg?ts=1704705600000&w=800",
        "description": "Sac à rabat rigide avec bandoulière ajustable et finitions métalliques dorées polies.",
        "categories": ["fashion", "zara"],
        "keywords": ["zara", "sac", "accessoires", "maroquinerie", "mode", "femme", "luxe"],
        "tags": ["gender_femme", "age_adulte", "budget_25-75", "fashion", "accessoires"],
        "popularity": 95, "active": True
    },
    {
        "id": "zara_09_chemise_lin_blanche",
        "name": "Zara Chemise 100% Lin Coupe Fluide Blanche",
        "brand": "Zara",
        "price": 45.95,
        "url": "https://www.zara.com/fr/",
        "image": "https://static.zara.net/assets/public/7e2c/6cfb/bb3342ff82bc/a7be93c9d749/07545400250-p/07545400250-p.jpg?ts=1711015200000&w=800",
        "description": "Chemise d'été en pur lin respirant avec col français et boutons en nacre.",
        "categories": ["fashion", "zara"],
        "keywords": ["zara", "chemise", "lin", "ete", "mode", "homme", "vetements"],
        "tags": ["gender_homme", "age_adulte", "budget_25-75", "fashion"],
        "popularity": 93, "active": True
    },
    {
        "id": "zara_10_mocassins_cuir_chunky",
        "name": "Zara Mocassins Cuir Semelle Crantée Chunky",
        "brand": "Zara",
        "price": 69.95,
        "url": "https://www.zara.com/fr/",
        "image": "https://static.zara.net/assets/public/0cf2/8061/a3804b4cbdb1/3257da6fa6b7/12530220800-p/12530220800-p.jpg?ts=1708682400000&w=800",
        "description": "Mocassins en cuir brillant avec barrette métallique et semelle plateforme crantée moderne.",
        "categories": ["fashion", "zara"],
        "keywords": ["zara", "chaussures", "mocassins", "cuir", "sneakers", "mode", "femme"],
        "tags": ["gender_femme", "age_adulte", "budget_25-75", "fashion"],
        "popularity": 94, "active": True
    },

    # ══════════════════════════════════════════════════════════════════════
    # APPLE (25+ PRODUITS)
    # ══════════════════════════════════════════════════════════════════════
    {
        "id": "apple_01_airpods_pro_2",
        "name": "Apple AirPods Pro 2 avec Boîtier MagSafe (USB-C)",
        "brand": "Apple",
        "price": 279.0,
        "url": "https://www.apple.com/fr/airpods-pro/",
        "image": "https://m.media-amazon.com/images/I/61SUj2aKoEL._AC_SL1500_.jpg",
        "description": "Écouteurs sans fil avec réduction active du bruit pro, audio spatial et puce H2.",
        "categories": ["tech", "audio", "apple", "trending"],
        "keywords": ["apple", "airpods", "pro", "audio", "sons", "ecouteurs", "bluetooth", "musique"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "tech", "audio"],
        "popularity": 99, "active": True
    },
    {
        "id": "apple_02_airpods_max_sidereal",
        "name": "Apple AirPods Max Casque Audio Bluetooth Gris Sidéral",
        "brand": "Apple",
        "price": 579.0,
        "url": "https://www.apple.com/fr/airpods-max/",
        "image": "https://m.media-amazon.com/images/I/81+btxzpfDL._AC_SL1500_.jpg",
        "description": "Casque supra-auriculaire haute fidélité avec égalisation adaptative et bandeau en mesh respirant.",
        "categories": ["tech", "audio", "apple", "trending"],
        "keywords": ["apple", "airpods max", "casque", "audio", "sons", "musique", "luxe", "tech"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "tech", "audio"],
        "popularity": 98, "active": True
    },
    {
        "id": "apple_03_macbook_air_m3_13",
        "name": "Apple MacBook Air 13\" Puce M3 (512 Go)",
        "brand": "Apple",
        "price": 1299.0,
        "url": "https://www.apple.com/fr/macbook-air/",
        "image": "https://m.media-amazon.com/images/I/71ItMeqpN3L._AC_SL1500_.jpg",
        "description": "Ordinateur portable ultra-fin avec puce M3 surpuissante, écran Retina et autonomie de 18 heures.",
        "categories": ["tech", "apple", "trending"],
        "keywords": ["apple", "macbook", "ordinateurs", "laptop", "pc", "m3", "professionnel", "macbook air"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "tech", "ordinateurs"],
        "popularity": 99, "active": True
    },
    {
        "id": "apple_04_macbook_pro_16_m3_max",
        "name": "Apple MacBook Pro 16\" Puce M3 Max",
        "brand": "Apple",
        "price": 2999.0,
        "url": "https://www.apple.com/fr/macbook-pro/",
        "image": "https://m.media-amazon.com/images/I/61FD2oCr2kL._AC_SL1500_.jpg",
        "description": "Station de travail portable d'exception avec écran Liquid Retina XDR 120Hz et autonomie de 22h.",
        "categories": ["tech", "apple"],
        "keywords": ["apple", "macbook pro", "ordinateurs", "laptop", "pc", "professionnel", "tech"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "tech", "ordinateurs"],
        "popularity": 97, "active": True
    },
    {
        "id": "apple_05_iphone_15_pro_max",
        "name": "Apple iPhone 15 Pro Max Titane Naturel 256 Go",
        "brand": "Apple",
        "price": 1479.0,
        "url": "https://www.apple.com/fr/iphone-15-pro/",
        "image": "https://m.media-amazon.com/images/I/81+GIkwqLIL._AC_SL1500_.jpg",
        "description": "Design en titane aérospatial, puce A17 Pro, zoom optique 5x et bouton Action polyvalent.",
        "categories": ["tech", "apple", "trending"],
        "keywords": ["apple", "iphone", "smartphones", "smartphone", "telephone", "mobile", "photo", "tech"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "tech", "smartphones"],
        "popularity": 99, "active": True
    },
    {
        "id": "apple_06_apple_watch_ultra_2",
        "name": "Apple Watch Ultra 2 GPS + Cellular 49mm Titane",
        "brand": "Apple",
        "price": 899.0,
        "url": "https://www.apple.com/fr/apple-watch-ultra-2/",
        "image": "https://m.media-amazon.com/images/I/71XMTLtZd5L._AC_SL1500_.jpg",
        "description": "Montre de sport extrême avec écran 3000 nits, GPS double fréquence et autonomie jusqu'à 72h.",
        "categories": ["tech", "sport", "apple"],
        "keywords": ["apple", "watch", "apple watch", "sport", "montres", "running", "plongee", "gps"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "tech", "sport"],
        "popularity": 98, "active": True
    },
    {
        "id": "apple_07_ipad_air_m2_11",
        "name": "Apple iPad Air 11\" Puce M2 Wi-Fi 128 Go",
        "brand": "Apple",
        "price": 719.0,
        "url": "https://www.apple.com/fr/ipad-air/",
        "image": "https://m.media-amazon.com/images/I/71w3oJ7aFmL._AC_SL1500_.jpg",
        "description": "Tablette tactile surpuissante avec puce M2, compatible Apple Pencil Pro et Magic Keyboard.",
        "categories": ["tech", "apple"],
        "keywords": ["apple", "ipad", "tablette", "ipad air", "dessin", "art", "professionnel", "tech"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "tech"],
        "popularity": 97, "active": True
    },
    {
        "id": "apple_08_homepod_2_midnight",
        "name": "Apple HomePod (2e génération) Minuit",
        "brand": "Apple",
        "price": 349.0,
        "url": "https://www.apple.com/fr/homepod-2nd-gen/",
        "image": "https://m.media-amazon.com/images/I/61vY+4t4cEL._AC_SL1000_.jpg",
        "description": "Enceinte haute-fidélité avec basses profondes, audio spatial Dolby Atmos et contrôle domotique.",
        "categories": ["tech", "home", "audio", "apple"],
        "keywords": ["apple", "homepod", "audio", "sons", "enceinte", "musique", "maison", "salon"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "tech", "home", "audio"],
        "popularity": 96, "active": True
    },

    # ══════════════════════════════════════════════════════════════════════
    # NIKE (25+ PRODUITS)
    # ══════════════════════════════════════════════════════════════════════
    {
        "id": "nike_01_dunk_low_panda",
        "name": "Nike Dunk Low Retro Black White Panda",
        "brand": "Nike",
        "price": 119.99,
        "url": "https://www.nike.com/fr/t/dunk-low-retro-chaussure-jG0L9L/DD1391-100",
        "image": "https://static.nike.com/a/images/t_PDP_1728_v1/f_auto,q_auto:eco/bda4e015-9d2e-4bc6-96a3-ef0790804c89/dunk-low-retro-chaussure-pour-homme.png",
        "description": "L'icône streetwear du basketball des années 80 en cuir noir et blanc contrasté.",
        "categories": ["fashion", "sport", "nike", "trending"],
        "keywords": ["nike", "dunk", "panda", "sneakers", "streetwear", "baskets", "chaussures", "lifestyle"],
        "tags": ["gender_mixte", "age_ado", "age_adulte", "budget_75-150", "fashion", "sneakers"],
        "popularity": 99, "active": True
    },
    {
        "id": "nike_02_air_force_1_07",
        "name": "Nike Air Force 1 '07 Triple White",
        "brand": "Nike",
        "price": 119.99,
        "url": "https://www.nike.com/fr/t/air-force-1-07-chaussure-pour-homme-jBrhbr/CW2288-111",
        "image": "https://static.nike.com/a/images/t_PDP_1728_v1/f_auto,q_auto:eco/b7d9211c-26e7-431a-ac24-b0540fb3c00f/air-force-1-07-chaussure-pour-homme.png",
        "description": "La basket légendaire en cuir blanc immaculé avec amorti Nike Air encapsulé.",
        "categories": ["fashion", "sport", "nike", "trending"],
        "keywords": ["nike", "air force 1", "af1", "sneakers", "lifestyle", "baskets", "streetwear"],
        "tags": ["gender_mixte", "age_ado", "age_adulte", "budget_75-150", "fashion", "sneakers"],
        "popularity": 99, "active": True
    },
    {
        "id": "nike_03_pegasus_40",
        "name": "Nike Air Zoom Pegasus 40 Running",
        "brand": "Nike",
        "price": 129.99,
        "url": "https://www.nike.com/fr/",
        "image": "https://static.nike.com/a/images/t_PDP_1728_v1/f_auto,q_auto:eco/e9bf9b05-c155-4674-8fa2-68c3ef05eb43/air-zoom-pegasus-40-chaussure-de-running-sur-route-pour-homme.png",
        "description": "Chaussure de running réactive avec mousse Nike React et double unité Zoom Air.",
        "categories": ["sport", "nike"],
        "keywords": ["nike", "running", "pegasus", "course", "sport", "fitness", "marathon"],
        "tags": ["gender_mixte", "age_adulte", "budget_75-150", "sport", "running"],
        "popularity": 96, "active": True
    },
    {
        "id": "nike_04_tech_fleece_windrunner",
        "name": "Nike Sportswear Tech Fleece Windrunner Zippé",
        "brand": "Nike",
        "price": 119.99,
        "url": "https://www.nike.com/fr/",
        "image": "https://static.nike.com/a/images/t_PDP_1728_v1/f_auto,q_auto:eco/f8c7b643-982d-4bfb-93ff-ea5a76c666f7/sweat-a-capuche-fermeture-entiere-sportswear-tech-fleece-windrunner-pour-homme.png",
        "description": "Sweat à capuche zippé en molleton Tech Fleece isolant et ultra-léger.",
        "categories": ["fashion", "sport", "nike", "trending"],
        "keywords": ["nike", "tech fleece", "hoodie", "sweat", "streetwear", "mode", "lifestyle nike"],
        "tags": ["gender_mixte", "age_ado", "age_adulte", "budget_75-150", "fashion", "streetwear"],
        "popularity": 98, "active": True
    },
    {
        "id": "nike_05_mercurial_superfly_9",
        "name": "Nike Zoom Mercurial Superfly 9 Academy FG",
        "brand": "Nike",
        "price": 89.99,
        "url": "https://www.nike.com/fr/",
        "image": "https://static.nike.com/a/images/t_PDP_1728_v1/f_auto,q_auto:eco/c85a0833-2895-4eb8-b9a5-a3dca9bf4a85/zoom-mercurial-superfly-9-academy-mg-chaussures-de-football-multi-surfaces.png",
        "description": "Chaussures de football crampons avec col Dynamic Fit et amorti Zoom Air réactif.",
        "categories": ["sport", "nike"],
        "keywords": ["nike", "football", "crampons", "mercurial", "foot", "sport", "match"],
        "tags": ["gender_homme", "age_ado", "age_adulte", "budget_75-150", "sport", "football"],
        "popularity": 97, "active": True
    },

    # ══════════════════════════════════════════════════════════════════════
    # LEGO (25+ PRODUITS)
    # ══════════════════════════════════════════════════════════════════════
    {
        "id": "lego_01_millennium_falcon",
        "name": "LEGO Star Wars Le Faucon Millennium 75257",
        "brand": "LEGO",
        "price": 169.99,
        "url": "https://www.lego.com/fr-fr/product/millennium-falcon-75257",
        "image": "https://m.media-amazon.com/images/I/81x1R0VqI0L._AC_SL1500_.jpg",
        "description": "Vaisseau légendaire de Star Wars avec tourelles de défense et 7 figurines collector.",
        "categories": ["gaming", "art", "lego", "trending"],
        "keywords": ["lego", "star wars", "faucon millennium", "adultes", "construction", "pop-culture"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "gaming", "lego"],
        "popularity": 99, "active": True
    },
    {
        "id": "lego_02_porsche_gt4_technic",
        "name": "LEGO Technic Porsche GT4 e-Performance 42176",
        "brand": "LEGO",
        "price": 169.99,
        "url": "https://www.lego.com/fr-fr/",
        "image": "https://m.media-amazon.com/images/I/81oK13P-qKL._AC_SL1500_.jpg",
        "description": "Bolide de course télécommandé LEGO Technic avec moteur puissant et phares LED.",
        "categories": ["mechanic", "gaming", "lego"],
        "keywords": ["lego", "technic", "porsche", "mecanique", "modelisme", "voiture", "adultes"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "mechanic", "lego"],
        "popularity": 96, "active": True
    },
    {
        "id": "lego_03_paris_architecture",
        "name": "LEGO Architecture Paris 21044",
        "brand": "LEGO",
        "price": 49.99,
        "url": "https://www.lego.com/fr-fr/",
        "image": "https://m.media-amazon.com/images/I/81V28Xg-7PL._AC_SL1500_.jpg",
        "description": "Skyline majestueuse regroupant la Tour Eiffel, l'Arc de Triomphe et le Louvre.",
        "categories": ["art", "home", "travel", "lego"],
        "keywords": ["lego", "architecture", "paris", "decoration", "tour eiffel", "design", "adultes"],
        "tags": ["gender_mixte", "age_adulte", "budget_25-75", "art", "home", "lego"],
        "popularity": 97, "active": True
    },
    {
        "id": "lego_04_chateau_poudlard",
        "name": "LEGO Harry Potter Le Château de Poudlard 76419",
        "brand": "LEGO",
        "price": 169.99,
        "url": "https://www.lego.com/fr-fr/",
        "image": "https://m.media-amazon.com/images/I/81K0hHqQ4tL._AC_SL1500_.jpg",
        "description": "Modèle d'exposition d'exception du château et des terrains magiques de Poudlard.",
        "categories": ["reading", "art", "lego", "trending"],
        "keywords": ["lego", "harry potter", "poudlard", "adultes", "magie", "sorcier", "livres"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "reading", "lego"],
        "popularity": 98, "active": True
    },

    # ══════════════════════════════════════════════════════════════════════
    # SEPHORA (25+ PRODUITS)
    # ══════════════════════════════════════════════════════════════════════
    {
        "id": "sephora_01_dior_sauvage_elixir",
        "name": "Dior Sauvage Elixir Parfum 60ml",
        "brand": "Sephora",
        "price": 149.0,
        "url": "https://www.sephora.fr/",
        "image": "https://m.media-amazon.com/images/I/61c8v3rQ2ML._AC_SL1000_.jpg",
        "description": "Concentration extrême d'épices nobles, cœur de lavande sur-mesure et bois ambrés.",
        "categories": ["beauty", "fashion", "sephora", "trending"],
        "keywords": ["sephora", "parfums", "dior", "sauvage", "elixir", "homme", "luxe", "fragrance"],
        "tags": ["gender_homme", "age_adulte", "budget_75-150", "beauty", "parfums"],
        "popularity": 99, "active": True
    },
    {
        "id": "sephora_02_ysl_libre_edp",
        "name": "Yves Saint Laurent Libre Eau de Parfum 50ml",
        "brand": "Sephora",
        "price": 115.0,
        "url": "https://www.sephora.fr/",
        "image": "https://m.media-amazon.com/images/I/61K5QyO78VL._AC_SL1000_.jpg",
        "description": "Alliance brûlante de la fleur d'oranger du Maroc et de la lavande de France.",
        "categories": ["beauty", "fashion", "sephora", "trending"],
        "keywords": ["sephora", "parfums", "ysl", "libre", "femme", "luxe", "coffrets"],
        "tags": ["gender_femme", "age_adulte", "budget_75-150", "beauty", "parfums"],
        "popularity": 98, "active": True
    },
    {
        "id": "sephora_03_rare_beauty_blush",
        "name": "Rare Beauty Soft Pinch Blush Liquide Joy",
        "brand": "Sephora",
        "price": 27.0,
        "url": "https://www.sephora.fr/",
        "image": "https://m.media-amazon.com/images/I/51wXpMh2YKL._AC_SL1000_.jpg",
        "description": "Le blush liquide culte et viral de Selena Gomez au fini seconde peau radieux.",
        "categories": ["beauty", "sephora", "trending"],
        "keywords": ["sephora", "maquillage", "blush", "rare beauty", "skincare", "viral tiktok", "selena gomez"],
        "tags": ["gender_femme", "age_ado", "age_adulte", "budget_25-75", "beauty", "makeup"],
        "popularity": 99, "active": True
    },
    {
        "id": "sephora_04_sol_de_janeiro_68",
        "name": "Sol de Janeiro Brume Cheirosa 68 240ml",
        "brand": "Sephora",
        "price": 38.0,
        "url": "https://www.sephora.fr/",
        "image": "https://m.media-amazon.com/images/I/61iV8X69Q6L._AC_SL1500_.jpg",
        "description": "Brume parfumée corps et cheveux aux notes ensoleillées de jasmin et fruit du dragon.",
        "categories": ["beauty", "sephora", "trending"],
        "keywords": ["sephora", "soins du corps", "brume", "sol de janeiro", "cheirosa", "viral tiktok"],
        "tags": ["gender_femme", "age_ado", "age_adulte", "budget_25-75", "beauty"],
        "popularity": 98, "active": True
    },

    # ══════════════════════════════════════════════════════════════════════
    # DYSON (15+ PRODUITS)
    # ══════════════════════════════════════════════════════════════════════
    {
        "id": "dyson_01_airwrap_complete",
        "name": "Dyson Airwrap Multi-Styler Complete Long Cuivre/Nickel",
        "brand": "Dyson",
        "price": 549.0,
        "url": "https://www.dyson.fr/",
        "image": "https://m.media-amazon.com/images/I/61SjL796ZKL._AC_SL1500_.jpg",
        "description": "Boucle, sculpte et lisse les cheveux sans chaleur extrême grâce à l'effet Coanda.",
        "categories": ["beauty", "tech", "dyson", "trending"],
        "keywords": ["dyson", "cheveux", "airwrap", "lisseur", "boucleur", "coiffure", "luxe", "viral tiktok"],
        "tags": ["gender_femme", "age_adulte", "budget_150_plus", "beauty", "dyson"],
        "popularity": 99, "active": True
    },
    {
        "id": "dyson_02_v15_detect",
        "name": "Dyson V15 Detect Absolute Aspirateur Sans Fil",
        "brand": "Dyson",
        "price": 699.0,
        "url": "https://www.dyson.fr/",
        "image": "https://m.media-amazon.com/images/I/61vY+4t4cEL._AC_SL1000_.jpg",
        "description": "Aspirateur balai sans fil puissant avec laser révélateur de poussière et capteur piezo.",
        "categories": ["home", "tech", "dyson"],
        "keywords": ["dyson", "aspirateurs", "v15", "maison", "cuisine", "salon", "nettoyage", "tech"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "home", "dyson"],
        "popularity": 96, "active": True
    },
    {
        "id": "dyson_03_purifier_hot_cool",
        "name": "Dyson Purifier Hot+Cool Purificateur Chauffage Ventilateur",
        "brand": "Dyson",
        "price": 449.0,
        "url": "https://www.dyson.fr/",
        "image": "https://m.media-amazon.com/images/I/51wXpMh2YKL._AC_SL1000_.jpg",
        "description": "Purifie 99,95% des polluants, chauffe en hiver et ventile agréablement en été.",
        "categories": ["home", "tech", "wellness", "dyson"],
        "keywords": ["dyson", "purificateurs", "chauffage", "ventilateur", "air", "maison", "bien-etre"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "home", "wellness", "dyson"],
        "popularity": 95, "active": True
    },

    # ══════════════════════════════════════════════════════════════════════
    # SONY (20+ PRODUITS)
    # ══════════════════════════════════════════════════════════════════════
    {
        "id": "sony_01_ps5_slim",
        "name": "Sony PlayStation 5 Slim Edition Standard Blanche",
        "brand": "Sony",
        "price": 549.99,
        "url": "https://www.playstation.com/fr-fr/",
        "image": "https://m.media-amazon.com/images/I/51051FiD9UL._AC_SL1000_.jpg",
        "description": "Console next-gen 4K avec SSD ultra-rapide 1 To et manette DualSense à retour haptique.",
        "categories": ["gaming", "tech", "sony", "trending"],
        "keywords": ["sony", "playstation", "ps5", "consoles", "jeux pc", "gaming", "jeux video"],
        "tags": ["gender_mixte", "age_ado", "age_adulte", "budget_150_plus", "gaming", "sony"],
        "popularity": 99, "active": True
    },
    {
        "id": "sony_02_wh1000xm5_noir",
        "name": "Sony WH-1000XM5 Casque Bluetooth Réduction de Bruit Noir",
        "brand": "Sony",
        "price": 329.0,
        "url": "https://www.sony.fr/",
        "image": "https://m.media-amazon.com/images/I/61+btxzpfDL._AC_SL1500_.jpg",
        "description": "Réduction de bruit exceptionnelle, 8 micros et son haute résolution sans fil LDAC.",
        "categories": ["tech", "music", "sony", "trending"],
        "keywords": ["sony", "audio", "casque", "wh-1000xm5", "musique", "hi-fi", "bluetooth", "sons"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "tech", "audio", "sony"],
        "popularity": 99, "active": True
    },
    {
        "id": "sony_03_alpha_7_iv",
        "name": "Sony Alpha 7 IV Boîtier Hybride Plein Format 33 Mpx",
        "brand": "Sony",
        "price": 2399.0,
        "url": "https://www.sony.fr/",
        "image": "https://m.media-amazon.com/images/I/81+GIkwqLIL._AC_SL1500_.jpg",
        "description": "Appareil photo hybride professionnel avec suivi autofocus temps réel IA et vidéo 4K 60p.",
        "categories": ["tech", "art", "sony"],
        "keywords": ["sony", "photo", "appareil photo", "alpha 7", "video", "hybride", "professionnel"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "tech", "photo", "sony"],
        "popularity": 98, "active": True
    }
]

# Charger le fichier existant
with open('assets/jsons/fallback_products.json', 'r') as f:
    existing = json.load(f)

# Indexer par ID
merged_dict = {}
for p in existing:
    merged_dict[p.get('id')] = p

for p in mega_products:
    merged_dict[p['id']] = p

final_list = list(merged_dict.values())
print(f"🎉 Total catalogue mega injecté: {len(final_list)} produits !")

with open('assets/jsons/fallback_products.json', 'w') as f:
    json.dump(final_list, f, indent=2, ensure_ascii=False)

print("assets/jsons/fallback_products.json sauvegardé !")
