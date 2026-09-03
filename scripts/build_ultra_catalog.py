import json

catalog = [
    # ══════════════════════════════════════════════════════════════════════
    # ZARA (Marque & Mode)
    # ══════════════════════════════════════════════════════════════════════
    {
        "id": "zara_blazer_croise_homme",
        "name": "Zara Blazer Croisé Coupe Relax",
        "brand": "Zara",
        "price": 89.95,
        "url": "https://www.zara.com/fr/",
        "image": "https://static.zara.net/assets/public/7e02/e8cb/df2b4c10a129/66a4f910408d/02008320800-p/02008320800-p.jpg?ts=1708682782782&w=800",
        "description": "Veste de costume croisée Zara à col à revers pointu et boutons contrastés.",
        "categories": ["fashion", "zara", "trending"],
        "keywords": ["zara", "blazer", "veste", "costume", "mode", "homme", "luxe", "streetwear", "vetements", "chic"],
        "tags": ["gender_homme", "age_adulte", "budget_75-150", "fashion"],
        "popularity": 96, "active": True
    },
    {
        "id": "zara_robe_longue_satinee",
        "name": "Zara Robe Longue Satinée Dos Nu",
        "brand": "Zara",
        "price": 49.95,
        "url": "https://www.zara.com/fr/",
        "image": "https://static.zara.net/assets/public/043b/eb90/9b9745dbbbdf/b645938bf8c9/03152200800-p/03152200800-p.jpg?ts=1710408544837&w=800",
        "description": "Robe fluide satinée Zara à encolure américaine et dos dégagé somptueux.",
        "categories": ["fashion", "zara", "trending"],
        "keywords": ["zara", "robe", "satinee", "soiree", "mode", "femme", "luxe", "vetements", "mariage", "st_valentin"],
        "tags": ["gender_femme", "age_adulte", "budget_25-75", "fashion"],
        "popularity": 98, "active": True
    },
    {
        "id": "zara_trench_oversize",
        "name": "Zara Trench Double Boutonnage Oversize",
        "brand": "Zara",
        "price": 99.95,
        "url": "https://www.zara.com/fr/",
        "image": "https://static.zara.net/assets/public/6ff1/5db0/3cf94bb3a0b8/c18fb9ea7da8/00518330712-p/00518330712-p.jpg?ts=1705658602905&w=800",
        "description": "Trench intemporel beige Zara en gabardine de coton avec ceinture à boucle.",
        "categories": ["fashion", "zara"],
        "keywords": ["zara", "trench", "manteau", "veste", "mode", "streetwear", "femme", "homme", "accessoires"],
        "tags": ["gender_mixte", "age_adulte", "budget_75-150", "fashion"],
        "popularity": 95, "active": True
    },
    {
        "id": "zara_parfum_red_temptation",
        "name": "Zara Red Temptation Eau de Parfum 80ml",
        "brand": "Zara",
        "price": 22.95,
        "url": "https://www.zara.com/fr/",
        "image": "https://static.zara.net/assets/public/4b5b/98bf/e94e43e790a3/8beea42674e2/00110410999-p/00110410999-p.jpg?ts=1698226065576&w=800",
        "description": "Fragrance florale boisée et ambrée Zara devenue virale pour ses notes d'épices chaudes.",
        "categories": ["beauty", "fashion", "zara", "trending"],
        "keywords": ["zara", "parfum", "red temptation", "parfums", "beaute", "viral tiktok", "secret santa", "cadeau"],
        "tags": ["gender_femme", "age_ado", "age_adulte", "budget_0_25", "beauty", "parfums"],
        "popularity": 99, "active": True
    },
    {
        "id": "zara_jean_wide_leg",
        "name": "Zara Jean Wide Leg Taille Haute",
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

    # ══════════════════════════════════════════════════════════════════════
    # TECH > ORDINATEURS
    # ══════════════════════════════════════════════════════════════════════
    {
        "id": "apple_macbook_air_m3_13",
        "name": "Apple MacBook Air 13\" Puce M3 (512 Go)",
        "brand": "Apple",
        "price": 1299.0,
        "url": "https://www.apple.com/fr/macbook-air/",
        "image": "https://m.media-amazon.com/images/I/71ItMeqpN3L._AC_SL1500_.jpg",
        "description": "Ordinateur portable Apple ultra-fin avec puce M3 surpuissante, écran Retina et autonomie de 18 heures.",
        "categories": ["tech", "apple", "trending"],
        "keywords": ["ordinateurs", "macbook", "ordinateur", "laptop", "apple", "pc", "tech", "professionnel", "macbook air"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "tech", "ordinateurs"],
        "popularity": 99, "active": True
    },
    {
        "id": "apple_macbook_pro_16_m3_max",
        "name": "Apple MacBook Pro 16\" Puce M3 Max",
        "brand": "Apple",
        "price": 2999.0,
        "url": "https://www.apple.com/fr/macbook-pro/",
        "image": "https://m.media-amazon.com/images/I/61FD2oCr2kL._AC_SL1500_.jpg",
        "description": "La station de travail portable ultime pour les créatifs et développeurs avec écran Liquid Retina XDR 120Hz.",
        "categories": ["tech", "apple"],
        "keywords": ["ordinateurs", "macbook", "ordinateur", "laptop", "apple", "pc", "professionnel", "macbook pro", "tech"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "tech", "ordinateurs"],
        "popularity": 97, "active": True
    },
    {
        "id": "dell_xps_15_laptop",
        "name": "Dell XPS 15 Ordinateur Portable OLED 3.5K",
        "brand": "Dell",
        "price": 1899.0,
        "url": "https://www.dell.com/fr-fr",
        "image": "https://m.media-amazon.com/images/I/81x1R0VqI0L._AC_SL1500_.jpg",
        "description": "PC portable Windows d'élite en aluminium usiné et fibre de carbone avec écran tactile OLED InfinityEdge.",
        "categories": ["tech"],
        "keywords": ["ordinateurs", "dell", "xps", "ordinateur", "laptop", "pc", "windows", "tech", "professionnel"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "tech", "ordinateurs"],
        "popularity": 95, "active": True
    },
    {
        "id": "asus_rog_zephyrus_g16_gaming_pc",
        "name": "ASUS ROG Zephyrus G16 PC Portable Gamer",
        "brand": "Asus",
        "price": 2199.0,
        "url": "https://rog.asus.com/fr/",
        "image": "https://m.media-amazon.com/images/I/71Zt0iXp2eL._AC_SL1500_.jpg",
        "description": "Ordinateur portable gaming ultra-fin avec écran OLED 240Hz, Intel Core Ultra 9 et NVIDIA RTX 4080.",
        "categories": ["tech", "gaming"],
        "keywords": ["ordinateurs", "asus", "rog", "gaming", "pc gamer", "ordinateur", "laptop", "jeux pc", "tech"],
        "tags": ["gender_mixte", "age_ado", "age_adulte", "budget_150_plus", "tech", "gaming", "ordinateurs"],
        "popularity": 96, "active": True
    },

    # ══════════════════════════════════════════════════════════════════════
    # TECH > SMARTPHONES
    # ══════════════════════════════════════════════════════════════════════
    {
        "id": "apple_iphone_15_pro_max",
        "name": "Apple iPhone 15 Pro Max Titane Bleu",
        "brand": "Apple",
        "price": 1479.0,
        "url": "https://www.apple.com/fr/iphone-15-pro/",
        "image": "https://m.media-amazon.com/images/I/81+GIkwqLIL._AC_SL1500_.jpg",
        "description": "Châssis titane ultraléger, puce A17 Pro, téléobjectif 5x optique et autonomie record.",
        "categories": ["tech", "apple", "trending"],
        "keywords": ["smartphones", "iphone", "apple", "telephone", "mobile", "smartphone", "tech", "photo"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "tech", "smartphones"],
        "popularity": 99, "active": True
    },
    {
        "id": "samsung_galaxy_s24_ultra",
        "name": "Samsung Galaxy S24 Ultra 5G avec Galaxy AI",
        "brand": "Samsung",
        "price": 1469.0,
        "url": "https://www.samsung.com/fr/smartphones/galaxy-s24-ultra/",
        "image": "https://m.media-amazon.com/images/I/71w3oJ7aFmL._AC_SL1500_.jpg",
        "description": "Smartphone haut de gamme avec intelligence artificielle intégrée, S-Pen et capteur photo 200 Mpx.",
        "categories": ["tech", "trending"],
        "keywords": ["smartphones", "samsung", "galaxy", "s24", "smartphone", "telephone", "mobile", "tech", "android"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "tech", "smartphones"],
        "popularity": 98, "active": True
    },
    {
        "id": "google_pixel_8_pro",
        "name": "Google Pixel 8 Pro avec Tensor G3",
        "brand": "Google",
        "price": 899.0,
        "url": "https://store.google.com/fr/product/pixel_8_pro",
        "image": "https://m.media-amazon.com/images/I/71S8-v+Q91L._AC_SL1500_.jpg",
        "description": "Le meilleur smartphone photo boosté à l'IA avec écran Super Actua 120Hz.",
        "categories": ["tech"],
        "keywords": ["smartphones", "google", "pixel", "smartphone", "telephone", "mobile", "photo", "tech"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "tech", "smartphones"],
        "popularity": 96, "active": True
    },

    # ══════════════════════════════════════════════════════════════════════
    # TECH > AUDIO
    # ══════════════════════════════════════════════════════════════════════
    {
        "id": "sony_wh1000xm5_silver",
        "name": "Sony WH-1000XM5 Casque Réduction de Bruit Argent",
        "brand": "Sony",
        "price": 349.0,
        "url": "https://www.sony.fr/",
        "image": "https://m.media-amazon.com/images/I/61+btxzpfDL._AC_SL1500_.jpg",
        "description": "Le roi des casques audio avec deux processeurs de réduction de bruit et son Hi-Res Audio.",
        "categories": ["tech", "music", "sony", "trending"],
        "keywords": ["audio", "casque", "sony", "ecouteurs", "musique", "wh-1000xm5", "bluetooth", "sons", "hi-fi"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "tech", "audio", "music"],
        "popularity": 99, "active": True
    },
    {
        "id": "bose_quietcomfort_ultra_headphones",
        "name": "Bose QuietComfort Ultra Casque Audio Spatial",
        "brand": "Bose",
        "price": 449.0,
        "url": "https://www.bose.fr/",
        "image": "https://m.media-amazon.com/images/I/51051FiD9UL._AC_SL1000_.jpg",
        "description": "Audio immersif Bose CustomTune et réduction de bruit de classe mondiale pour un confort absolu.",
        "categories": ["tech", "music"],
        "keywords": ["audio", "bose", "casque", "quietcomfort", "musique", "bluetooth", "sons", "hi-fi"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "tech", "audio"],
        "popularity": 97, "active": True
    },
    {
        "id": "jbl_charge_5_speaker",
        "name": "JBL Charge 5 Enceinte Bluetooth Étanche",
        "brand": "JBL",
        "price": 149.0,
        "url": "https://fr.jbl.com/",
        "image": "https://m.media-amazon.com/images/I/71Y9L3d6QBL._AC_SL1500_.jpg",
        "description": "Son JBL Original Pro puissant avec haut-parleur de graves longue portée et 20h d'autonomie.",
        "categories": ["tech", "music", "sport"],
        "keywords": ["audio", "enceinte", "jbl", "charge 5", "musique", "bluetooth", "sons", "enceintes portables"],
        "tags": ["gender_mixte", "age_ado", "age_adulte", "budget_75-150", "tech", "audio"],
        "popularity": 98, "active": True
    },

    # ══════════════════════════════════════════════════════════════════════
    # TECH > OBJETS CONNECTÉS
    # ══════════════════════════════════════════════════════════════════════
    {
        "id": "philips_hue_starter_kit",
        "name": "Philips Hue Pack de Démarrage 3 Ampoules E27 White & Color",
        "brand": "Philips Hue",
        "price": 149.99,
        "url": "https://www.philips-hue.com/fr-fr",
        "image": "https://m.media-amazon.com/images/I/71XMTLtZd5L._AC_SL1500_.jpg",
        "description": "Éclairage connecté intelligent 16 millions de couleurs avec pont Hue et télécommande variateur.",
        "categories": ["tech", "home"],
        "keywords": ["objets connectes", "philips hue", "ampoules", "domotique", "maison", "salon", "chambre", "connecte"],
        "tags": ["gender_mixte", "age_adulte", "budget_75-150", "tech", "home", "objets_connectes"],
        "popularity": 96, "active": True
    },
    {
        "id": "garmin_forerunner_265",
        "name": "Garmin Forerunner 265 Montre GPS de Running AMOLED",
        "brand": "Garmin",
        "price": 449.99,
        "url": "https://www.garmin.com/fr-FR/",
        "image": "https://m.media-amazon.com/images/I/61SUj2aKoEL._AC_SL1500_.jpg",
        "description": "Écran tactile AMOLED ultra-lumineux, métriques avancées d'entraînement et suggestions quotidiennes.",
        "categories": ["tech", "sport"],
        "keywords": ["objets connectes", "garmin", "montre", "sport", "running", "fitness", "gps", "montres"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "tech", "sport"],
        "popularity": 97, "active": True
    },

    # ══════════════════════════════════════════════════════════════════════
    # TECH > PHOTO
    # ══════════════════════════════════════════════════════════════════════
    {
        "id": "sony_alpha_7_iv_camera",
        "name": "Sony Alpha 7 IV Appareil Photo Hybride Plein Format",
        "brand": "Sony",
        "price": 2399.0,
        "url": "https://www.sony.fr/",
        "image": "https://m.media-amazon.com/images/I/81+GIkwqLIL._AC_SL1500_.jpg",
        "description": "Capteur 33 Mpx rétroéclairé, autofocus en temps réel avec IA et enregistrement vidéo 4K 60p.",
        "categories": ["tech", "art", "sony"],
        "keywords": ["photo", "appareil photo", "sony", "alpha 7", "video", "hybride", "professionnel", "tech"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "tech", "photo"],
        "popularity": 98, "active": True
    },
    {
        "id": "dji_mini_4_pro_drone",
        "name": "DJI Mini 4 Pro Drone Ultra-Léger 4K HDR",
        "brand": "DJI",
        "price": 799.0,
        "url": "https://www.dji.com/fr/mini-4-pro",
        "image": "https://m.media-amazon.com/images/I/71K0hHqQ4tL._AC_SL1500_.jpg",
        "description": "Drone de moins de 249g avec détection d'obstacles omnidirectionnelle et vidéo verticale native.",
        "categories": ["tech", "travel", "aeronautic", "trending"],
        "keywords": ["photo", "drone", "dji", "mini 4", "video", "voyage", "aeronautic", "tech"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "tech", "photo"],
        "popularity": 99, "active": True
    }
]

# Charger le fichier existant
with open('assets/jsons/fallback_products.json', 'r') as f:
    existing = json.load(f)

# Créer un dictionnaire par ID pour éviter tout doublon
merged_dict = {}
for p in existing:
    merged_dict[p.get('id')] = p

for p in catalog:
    merged_dict[p['id']] = p

final_list = list(merged_dict.values())
print(f"Total catalogue final : {len(final_list)} produits ultra-qualifiés !")

with open('assets/jsons/fallback_products.json', 'w') as f:
    json.dump(final_list, f, indent=2, ensure_ascii=False)

print("assets/jsons/fallback_products.json mis à jour !")
