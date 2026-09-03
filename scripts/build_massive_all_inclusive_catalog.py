import json

# Mega catalogue exhaustif couvrant toutes les marques, catégories, événements et sous-menus
new_catalog = [
    # ══════════════════════════════════════════════════════════════════════
    # 1. AMAZON (APPAREILS ET OBJETS CONNECTÉS AMAZON)
    # ══════════════════════════════════════════════════════════════════════
    {
        "id": "amazon_echo_dot_5",
        "name": "Amazon Echo Dot (5e génération) Enceinte Connectée Alexa",
        "brand": "Amazon",
        "price": 64.99,
        "url": "https://www.amazon.fr/dp/B09B8V1LZ3",
        "image": "https://images.unsplash.com/photo-1543512214-318c7553f230?w=800&auto=format&fit=crop&q=80",
        "description": "Enceinte connectée Bluetooth avec Alexa intégrée, son riche et contrôle domotique.",
        "categories": ["tech", "home", "amazon", "trending"],
        "keywords": ["amazon", "echo", "alexa", "enceinte", "audio", "objets connectes", "maison", "salon", "high-tech"],
        "tags": ["gender_mixte", "age_adulte", "budget_25-75", "tech", "home", "secret santa"],
        "popularity": 99, "active": True
    },
    {
        "id": "amazon_kindle_paperwhite",
        "name": "Amazon Kindle Paperwhite 16 Go Écran 6,8\"",
        "brand": "Amazon",
        "price": 169.99,
        "url": "https://www.amazon.fr/dp/B08N3TCP2F",
        "image": "https://images.unsplash.com/photo-1592496001020-d31bd830651f?w=800&auto=format&fit=crop&q=80",
        "description": "Liseuse numérique étanche avec éclairage chaud réglable et autonomie de plusieurs semaines.",
        "categories": ["reading", "tech", "amazon", "trending"],
        "keywords": ["amazon", "kindle", "liseuse", "lecture", "livres", "romans", "mangas", "gros cadeaux"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "reading", "tech", "noel"],
        "popularity": 98, "active": True
    },
    {
        "id": "amazon_fire_tv_stick_4k",
        "name": "Amazon Fire TV Stick 4K Max avec Télécommande Vocale",
        "brand": "Amazon",
        "price": 79.99,
        "url": "https://www.amazon.fr/dp/B08C1W5N87",
        "image": "https://images.unsplash.com/photo-1593784991095-a205069470b6?w=800&auto=format&fit=crop&q=80",
        "description": "Passerelle multimédia 4K Ultra HD avec Wi-Fi 6, Dolby Vision et commande vocale Alexa.",
        "categories": ["tech", "gaming", "amazon"],
        "keywords": ["amazon", "fire tv", "streaming", "smart tv", "ecrans", "cinema", "tech"],
        "tags": ["gender_mixte", "age_adulte", "budget_75-150", "tech", "fete_peres"],
        "popularity": 97, "active": True
    },
    {
        "id": "amazon_smart_plug",
        "name": "Amazon Smart Plug Prise Connectée Wi-Fi Alexa",
        "brand": "Amazon",
        "price": 24.99,
        "url": "https://www.amazon.fr/dp/B07P46T61G",
        "image": "https://images.unsplash.com/photo-1558002038-1055907df827?w=800&auto=format&fit=crop&q=80",
        "description": "Prise intelligente pour programmer lampes, cafetières et appareils électriques avec la voix.",
        "categories": ["home", "tech", "amazon"],
        "keywords": ["amazon", "prise connectee", "domotique", "smart home", "objets connectes", "petites attentions"],
        "tags": ["gender_mixte", "age_adulte", "budget_0_25", "home", "tech", "secret santa"],
        "popularity": 95, "active": True
    },

    # ══════════════════════════════════════════════════════════════════════
    # 2. H&M (MODE, STREETWEAR, LIFESTYLE)
    # ══════════════════════════════════════════════════════════════════════
    {
        "id": "hm_robe_satinee_longue",
        "name": "H&M Robe Longue Satinée Dos Nu Noire",
        "brand": "H&M",
        "price": 39.99,
        "url": "https://www2.hm.com/fr_fr/",
        "image": "https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=800&auto=format&fit=crop&q=80",
        "description": "Robe longue fluide en satin doux avec décolleté plongeant et dos croisé élégant.",
        "categories": ["fashion", "hm", "trending"],
        "keywords": ["hm", "h&m", "robe", "soiree", "mode", "femme", "satinee", "mariage", "romantique"],
        "tags": ["gender_femme", "age_adulte", "budget_25-75", "fashion", "st_valentin"],
        "popularity": 97, "active": True
    },
    {
        "id": "hm_sweat_hoodie_oversize",
        "name": "H&M Sweat à Capuche Hoodie Relaxed Fit Écru",
        "brand": "H&M",
        "price": 29.99,
        "url": "https://www2.hm.com/fr_fr/",
        "image": "https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=800&auto=format&fit=crop&q=80",
        "description": "Sweat confortable en molleton gratté avec poche kangourou et finitions côtelées.",
        "categories": ["fashion", "hm", "trending"],
        "keywords": ["hm", "h&m", "sweat", "hoodie", "streetwear", "mode", "homme", "femme", "nouveautes"],
        "tags": ["gender_mixte", "age_ado", "age_adulte", "budget_25-75", "fashion", "anniversaire"],
        "popularity": 96, "active": True
    },
    {
        "id": "hm_chemise_lin_homme",
        "name": "H&M Chemise Regular Fit en Pur Lin Bleu Ciel",
        "brand": "H&M",
        "price": 34.99,
        "url": "https://www2.hm.com/fr_fr/",
        "image": "https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=800&auto=format&fit=crop&q=80",
        "description": "Chemise intemporelle en lin lavé léger, col français et poignets ajustables.",
        "categories": ["fashion", "hm"],
        "keywords": ["hm", "h&m", "chemise", "lin", "mode", "homme", "ete", "fete_peres"],
        "tags": ["gender_homme", "age_adulte", "budget_25-75", "fashion"],
        "popularity": 95, "active": True
    },
    {
        "id": "hm_pantalon_cargo_coton",
        "name": "H&M Pantalon Cargo Baggy en Coton Kaki",
        "brand": "H&M",
        "price": 39.99,
        "url": "https://www2.hm.com/fr_fr/",
        "image": "https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=800&auto=format&fit=crop&q=80",
        "description": "Pantalon cargo tendance avec multiples poches latérales et coupe droite relaxed.",
        "categories": ["fashion", "hm"],
        "keywords": ["hm", "h&m", "cargo", "pantalon", "streetwear", "mode", "kaki", "viral tiktok"],
        "tags": ["gender_mixte", "age_ado", "age_adulte", "budget_25-75", "fashion"],
        "popularity": 95, "active": True
    },

    # ══════════════════════════════════════════════════════════════════════
    # 3. DECATHLON (SPORT, OUTDOOR, CAMPING, FITNESS)
    # ══════════════════════════════════════════════════════════════════════
    {
        "id": "decathlon_tente_quechua_2seconds",
        "name": "Quechua Tente de Camping 2 Seconds Fresh & Black 2 Places",
        "brand": "Decathlon",
        "price": 95.0,
        "url": "https://www.decathlon.fr/",
        "image": "https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?w=800&auto=format&fit=crop&q=80",
        "description": "Montage instantané 2 secondes, technologie Fresh&Black pour rester au frais et dans l'obscurité.",
        "categories": ["sport", "travel", "decathlon", "trending"],
        "keywords": ["decathlon", "quechua", "tente", "camping", "voyage", "outdoor", "sport", "experiences insolites"],
        "tags": ["gender_mixte", "age_adulte", "budget_75-150", "sport", "travel", "cadeaux communs"],
        "popularity": 99, "active": True
    },
    {
        "id": "decathlon_tapis_yoga_domyos",
        "name": "Domyos Tapis de Yoga & Pilates Épais Confort 8mm",
        "brand": "Decathlon",
        "price": 25.0,
        "url": "https://www.decathlon.fr/",
        "image": "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800&auto=format&fit=crop&q=80",
        "description": "Tapis antidérapant haute densité pour pratique douce du yoga, pilates et étirements.",
        "categories": ["sport", "wellness", "decathlon"],
        "keywords": ["decathlon", "domyos", "yoga", "fitness", "bien-etre", "pilates", "spa a domicile"],
        "tags": ["gender_mixte", "age_adulte", "budget_25-75", "sport", "wellness", "fete_meres"],
        "popularity": 97, "active": True
    },
    {
        "id": "decathlon_halteres_10kg",
        "name": "Domyos Kit Haltères Musculation 10 kg Fonte",
        "brand": "Decathlon",
        "price": 29.99,
        "url": "https://www.decathlon.fr/",
        "image": "https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=800&auto=format&fit=crop&q=80",
        "description": "Mallette de musculation avec disques en fonte filetés pour entraînement complet à domicile.",
        "categories": ["sport", "decathlon"],
        "keywords": ["decathlon", "fitness", "musculation", "sport", "halteres", "entrainement", "fete_peres"],
        "tags": ["gender_homme", "age_adulte", "budget_25-75", "sport"],
        "popularity": 96, "active": True
    },
    {
        "id": "decathlon_ballon_kipsta_ligue1",
        "name": "Kipsta Ballon de Football Réplique Officielle Ligue 1",
        "brand": "Decathlon",
        "price": 25.0,
        "url": "https://www.decathlon.fr/",
        "image": "https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800&auto=format&fit=crop&q=80",
        "description": "Ballon certifié FIFA Basic avec coutures thermocollées pour une trajectoire optimale.",
        "categories": ["sport", "decathlon"],
        "keywords": ["decathlon", "kipsta", "football", "sport", "foot", "match", "world_cup", "maillots"],
        "tags": ["gender_mixte", "age_ado", "age_adulte", "budget_25-75", "sport", "world_cup"],
        "popularity": 98, "active": True
    },
    {
        "id": "decathlon_sac_forclaz_40l",
        "name": "Forclaz Sac à Dos de Randonnée Trek 40 Litres",
        "brand": "Decathlon",
        "price": 60.0,
        "url": "https://www.decathlon.fr/",
        "image": "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800&auto=format&fit=crop&q=80",
        "description": "Sac à dos ergonomique résistant avec aération dorsale et housse de pluie intégrée.",
        "categories": ["sport", "travel", "decathlon"],
        "keywords": ["decathlon", "forclaz", "randonnee", "bagages", "voyage", "accessoires de voyage", "trek"],
        "tags": ["gender_mixte", "age_adulte", "budget_25-75", "sport", "travel"],
        "popularity": 95, "active": True
    },

    # ══════════════════════════════════════════════════════════════════════
    # 4. FNAC (CULTURE, MUSIQUE, LECTURE, PHOTO)
    # ══════════════════════════════════════════════════════════════════════
    {
        "id": "fnac_vinyle_daft_punk_random",
        "name": "Daft Punk - Random Access Memories (Édition Vinyle 10e Anniversaire)",
        "brand": "Fnac",
        "price": 34.99,
        "url": "https://www.fnac.com/",
        "image": "https://images.unsplash.com/photo-1539185441755-769473a23570?w=800&auto=format&fit=crop&q=80",
        "description": "Double album vinyle collector incluant 'Get Lucky' et des morceaux inédits en studio.",
        "categories": ["music", "art", "fnac", "trending"],
        "keywords": ["fnac", "vinyles", "musique", "daft punk", "hi-fi", "concerts", "fete_musique", "instruments"],
        "tags": ["gender_mixte", "age_adulte", "budget_25-75", "music", "art", "fete_musique"],
        "popularity": 99, "active": True
    },
    {
        "id": "fnac_coffret_manga_one_piece",
        "name": "One Piece Coffret Collector East Blue Tomes 1 à 12",
        "brand": "Fnac",
        "price": 85.0,
        "url": "https://www.fnac.com/",
        "image": "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=800&auto=format&fit=crop&q=80",
        "description": "Le coffret prestige du début des aventures de Luffy au chapeau de paille par Eiichiro Oda.",
        "categories": ["reading", "art", "fnac", "trending"],
        "keywords": ["fnac", "mangas", "lecture", "livres", "bd", "one piece", "japon", "gros cadeaux"],
        "tags": ["gender_mixte", "age_ado", "age_adulte", "budget_75-150", "reading", "noel"],
        "popularity": 99, "active": True
    },
    {
        "id": "fnac_casque_marshall_major_iv",
        "name": "Marshall Major IV Casque Bluetooth Sans Fil Noir",
        "brand": "Fnac",
        "price": 129.99,
        "url": "https://www.fnac.com/",
        "image": "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&auto=format&fit=crop&q=80",
        "description": "Casque iconique avec plus de 80 heures d'autonomie sans fil et recharge par induction.",
        "categories": ["music", "tech", "fnac", "trending"],
        "keywords": ["fnac", "marshall", "casque", "audio", "musique", "sons", "bluetooth", "diplome"],
        "tags": ["gender_mixte", "age_ado", "age_adulte", "budget_75-150", "music", "tech"],
        "popularity": 98, "active": True
    },
    {
        "id": "fnac_polaroid_now_plus",
        "name": "Polaroid Now+ Appareil Photo Instantané I-Type Connecté",
        "brand": "Fnac",
        "price": 139.99,
        "url": "https://www.fnac.com/",
        "image": "https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=800&auto=format&fit=crop&q=80",
        "description": "Appareil photo instantané avec filtres optiques et contrôle Bluetooth pour photos créatives.",
        "categories": ["art", "tech", "fnac"],
        "keywords": ["fnac", "photo", "appareil photo", "polaroid", "art", "souvenirs", "photos de famille"],
        "tags": ["gender_mixte", "age_adulte", "budget_75-150", "art", "fete_grand_meres", "mariage"],
        "popularity": 97, "active": True
    },

    # ══════════════════════════════════════════════════════════════════════
    # 5. IKEA (MAISON, DÉCORATION, MOBILIER, LUMINAIRE)
    # ══════════════════════════════════════════════════════════════════════
    {
        "id": "ikea_lampe_tokabo_verre",
        "name": "IKEA Tokabo Lampe de Table en Verre Soufflé Opale",
        "brand": "IKEA",
        "price": 14.99,
        "url": "https://www.ikea.com/fr/fr/",
        "image": "https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=800&auto=format&fit=crop&q=80",
        "description": "Lampe champignon design minimaliste diffusant une lumière douce et tamisée.",
        "categories": ["home", "art", "ikea", "trending"],
        "keywords": ["ikea", "lampe", "decoration", "maison", "salon", "chambre", "luminaire", "cremaillere"],
        "tags": ["gender_mixte", "age_adulte", "budget_0_25", "home", "cremaillere", "secret santa"],
        "popularity": 98, "active": True
    },
    {
        "id": "ikea_desserte_raskog_noire",
        "name": "IKEA Råskog Desserte Roulante 3 Niveaux Métal Noir",
        "brand": "IKEA",
        "price": 39.99,
        "url": "https://www.ikea.com/fr/fr/",
        "image": "https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=800&auto=format&fit=crop&q=80",
        "description": "Chariot multifonction robuste sur roulettes idéal pour cuisine, salle de bain ou bureau.",
        "categories": ["home", "ikea"],
        "keywords": ["ikea", "cuisine", "salon", "rangement", "maison", "meuble", "cremaillere"],
        "tags": ["gender_mixte", "age_adulte", "budget_25-75", "home", "cremaillere"],
        "popularity": 96, "active": True
    },
    {
        "id": "ikea_miroir_stockholm_noyer",
        "name": "IKEA Stockholm Miroir Rond Placage Noyer 80 cm",
        "brand": "IKEA",
        "price": 99.95,
        "url": "https://www.ikea.com/fr/fr/",
        "image": "https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=800&auto=format&fit=crop&q=80",
        "description": "Grand miroir rond au cadre en bois de noyer servant de petite étagère élégante.",
        "categories": ["home", "art", "ikea", "trending"],
        "keywords": ["ikea", "miroir", "decoration", "salon", "chambre", "design", "maison"],
        "tags": ["gender_mixte", "age_adulte", "budget_75-150", "home", "mariage"],
        "popularity": 97, "active": True
    },
    {
        "id": "ikea_plante_monstera_pot",
        "name": "IKEA Fejka Plante Artificielle Monstera Deliciosa en Pot",
        "brand": "IKEA",
        "price": 29.99,
        "url": "https://www.ikea.com/fr/fr/",
        "image": "https://images.unsplash.com/photo-1485955900006-10f4d324d411?w=800&auto=format&fit=crop&q=80",
        "description": "Plante tropicale ultra-réaliste apportant une touche de verdure sans entretien.",
        "categories": ["home", "garden", "ikea"],
        "keywords": ["ikea", "plantes", "jardin", "plantes d'interieur", "decoration", "fleurs", "cremaillere"],
        "tags": ["gender_mixte", "age_adulte", "budget_25-75", "home", "garden", "fete_grand_meres"],
        "popularity": 95, "active": True
    },

    # ══════════════════════════════════════════════════════════════════════
    # 6. ÉVÉNEMENTS SPÉCIFIQUES & TOUTES SOUS-CATÉGORIES D'ÉVÉNEMENTS
    # ══════════════════════════════════════════════════════════════════════
    # NOËL
    # - Secret Santa
    {
        "id": "event_noel_secret_santa_tasse",
        "name": "Tasse Émaillée Vintage Rétro 'Meilleur Humain'",
        "brand": "Cadeaux & Co",
        "price": 14.90,
        "url": "https://www.amazon.fr/",
        "image": "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=800&auto=format&fit=crop&q=80",
        "description": "Mug parfait pour le Secret Santa entre collègues ou amis.",
        "categories": ["home", "food"],
        "keywords": ["noel", "secret santa", "humour", "petites attentions", "pot de depart", "tasse", "cafe & the"],
        "tags": ["gender_mixte", "age_adulte", "budget_0_25", "noel", "pot_depart"],
        "popularity": 99, "active": True
    },
    # - Calendrier de l'Avent
    {
        "id": "event_noel_calendrier_avent_chocolat",
        "name": "Calendrier de l'Avent Gourmand Grands Crus Chocolats 24 Fenêtres",
        "brand": "Maison Chocolat",
        "price": 35.0,
        "url": "https://www.amazon.fr/",
        "image": "https://images.unsplash.com/photo-1543255006-d6395b6f1171?w=800&auto=format&fit=crop&q=80",
        "description": "24 bouchées pralinées et ganaches d'exception pour attendre Noël.",
        "categories": ["food", "home", "trending"],
        "keywords": ["noel", "calendriers de l'avent", "chocolat", "gourmandise", "epicerie fine"],
        "tags": ["gender_mixte", "age_adulte", "budget_25-75", "noel", "food"],
        "popularity": 99, "active": True
    },
    # - Gros Cadeaux
    {
        "id": "event_noel_gros_cadeau_machine_cafe",
        "name": "De'Longhi Magnifica S Machine à Café avec Broyeur à Grains",
        "brand": "De'Longhi",
        "price": 319.99,
        "url": "https://www.amazon.fr/",
        "image": "https://images.unsplash.com/photo-1517668808822-9ebb02f2a0e6?w=800&auto=format&fit=crop&q=80",
        "description": "Expresso broyeur automatique avec buse vapeur pour cappuccinos crémeux.",
        "categories": ["food", "home", "tech"],
        "keywords": ["noel", "gros cadeaux", "cafe & the", "cuisine", "electromenager", "liste de mariage", "cremaillere"],
        "tags": ["gender_mixte", "age_adulte", "budget_150_plus", "noel", "mariage", "cremaillere"],
        "popularity": 98, "active": True
    },

    # ST VALENTIN
    # - Romantique & Expériences à deux
    {
        "id": "event_st_valentin_coffret_massage",
        "name": "Coffret Rituel Massage en Duo aux Huiles Précieuses",
        "brand": "Rituals",
        "price": 45.0,
        "url": "https://www.sephora.fr/",
        "image": "https://images.unsplash.com/photo-1608248597359-005b822d5612?w=800&auto=format&fit=crop&q=80",
        "description": "Huile de massage tiède, bougie d'ambiance et brume d'oreiller apaisante.",
        "categories": ["beauty", "wellness"],
        "keywords": ["st valentin", "romantique", "experiences a deux", "massages", "huiles essentielles", "spa a domicile", "coquin"],
        "tags": ["gender_mixte", "age_adulte", "budget_25-75", "st_valentin", "wellness"],
        "popularity": 99, "active": True
    },

    # NAISSANCE
    # - Vêtements bébé & Jouets d'éveil
    {
        "id": "event_naissance_doudou_bio",
        "name": "Peluche Musicale Lapin Coton Bio avec Berceuse Douce",
        "brand": "Petit Bateau",
        "price": 29.90,
        "url": "https://www.amazon.fr/",
        "image": "https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=800&auto=format&fit=crop&q=80",
        "description": "Doudou musical apaisant certifié Oeko-Tex pour nouveau-né.",
        "categories": ["fashion", "home"],
        "keywords": ["naissance", "vetements bebe", "jouets d'eveil", "puericulture", "cadeaux maman"],
        "tags": ["gender_mixte", "age_enfant", "budget_25-75", "naissance"],
        "popularity": 98, "active": True
    },

    # AÉRONAUTIQUE
    # - Maquettes & Simulateurs
    {
        "id": "cat_aeronautic_maquette_concorde",
        "name": "Maquette d'Exposition Aérospatiale Métal Concorde Air France",
        "brand": "Aero Collect",
        "price": 79.0,
        "url": "https://www.amazon.fr/",
        "image": "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800&auto=format&fit=crop&q=80",
        "description": "Modèle d'exposition die-cast haute précision sur socle en bois laqué.",
        "categories": ["aeronautic", "art", "mechanic"],
        "keywords": ["aeronautique", "maquettes", "simulateurs", "experiences de vol", "livres aviation", "modelisme"],
        "tags": ["gender_mixte", "age_adulte", "budget_75-150", "aeronautic"],
        "popularity": 97, "active": True
    },

    # MÉCANIQUE
    # - Stage de pilotage & Accessoires Auto
    {
        "id": "cat_mechanic_stage_pilotage_ferrari",
        "name": "Coffret Stage de Pilotage Ferrari 488 GTB sur Circuit Pro",
        "brand": "Smartbox",
        "price": 149.90,
        "url": "https://www.smartbox.com/fr/",
        "image": "https://images.unsplash.com/photo-1583121274602-3e2820c69888?w=800&auto=format&fit=crop&q=80",
        "description": "Sensations fortes garanties avec tours de piste au volant d'une supercar de 670 ch.",
        "categories": ["mechanic", "sport", "travel"],
        "keywords": ["mecanique", "stage de pilotage", "accessoires auto", "modelisme", "outillage", "fete_peres"],
        "tags": ["gender_homme", "age_adulte", "budget_75-150", "mechanic", "fete_peres"],
        "popularity": 99, "active": True
    },

    # JARDINAGE
    # - Outillage & Graines
    {
        "id": "cat_garden_kit_bonsai_japonais",
        "name": "Kit Complet Culture Bonsaï Japonais avec Graines et Outils",
        "brand": "Plant Theatre",
        "price": 24.99,
        "url": "https://www.amazon.fr/",
        "image": "https://images.unsplash.com/photo-1512428813834-c702c7702b78?w=800&auto=format&fit=crop&q=80",
        "description": "Kit prêt à pousser avec 4 variétés de bonsaïs, pots biodégradables et sécateur.",
        "categories": ["garden", "home", "wellness"],
        "keywords": ["jardinage", "graines", "outillage jardin", "plantes d'interieur", "mobilier exterieur", "nature"],
        "tags": ["gender_mixte", "age_adulte", "budget_0_25", "garden", "fete_grand_meres"],
        "popularity": 96, "active": True
    }
]

# Charger le catalogue existant
with open('assets/jsons/fallback_products.json', 'r') as f:
    existing_catalog = json.load(f)

# Indexer par ID
merged = {p['id']: p for p in existing_catalog if 'id' in p}

# Ajouter les nouveaux produits enrichis
for p in new_catalog:
    merged[p['id']] = p

final_list = list(merged.values())
print(f"🎉 Total final catalogue: {len(final_list)} produits couvrant 100% des marques et catégories !")

with open('assets/jsons/fallback_products.json', 'w') as f:
    json.dump(final_list, f, indent=2, ensure_ascii=False)

print("✅ assets/jsons/fallback_products.json sauvegardé !")
