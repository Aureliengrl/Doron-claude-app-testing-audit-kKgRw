#!/usr/bin/env python3
"""
Moteur d'Auto-Tagging DORÕN (Questionnaire & Accueil & Navigation).
Transforme chaque produit ou activité brut en une fiche ultra-enrichie avec 100% de cohérence sur le genre, les âges, le budget, les catégories, sous-catégories, événements et marques.
"""

import json
import re
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent.parent
RAW_FILE = Path(__file__).resolve().parent / "raw_data" / "google_shopping_raw.json"
OUTPUT_CATALOG = Path(__file__).resolve().parent / "final_doron_catalog.json"
FALLBACK_JSON = BASE_DIR / "assets" / "jsons" / "fallback_products.json"

FEMALE_KEYWORDS = [
    "femme", "femmes", "féminin", "féminine", "pour elle", "robe", "jupe", "escarpin", "escarpins", "talons", 
    "sac à main", "sac cabas", "sac seau", "pochette soirée", "sac bandoulière femme", "rouge à lèvres", 
    "maquillage", "blush", "mascara", "vernis", "lingerie", "soutien-gorge", "culotte", "dentelle", 
    "maman", "fête des mères", "grossesse", "maternité", "boucles d'oreilles", "collier", "bague", 
    "mademoiselle", "blouse femme", "palette maquillage", "soin anti-rides femme", "lisseur", "boucleur", 
    "dyson airwrap", "airwrap", "brosse soufflante", "parfum femme", "polène", "polene", "jacquemus", 
    "chiquito", "bambino", "miss dior", "j'adore", "jadore", "coco mademoiselle", "gabrielle chanel", 
    "black opium", "la vie est belle", "prada paradoxe", "fond de teint", "fard à paupières", "gloss"
]

MALE_KEYWORDS = [
    "homme", "hommes", "masculin", "pour lui", "pour homme", "barbe", "rasage", "tondeuse barbe", 
    "cravate", "nœud papillon", "caleçon", "boxer", "costume homme", "chemise homme", "polo homme", 
    "papa", "fête des pères", "montre homme", "aftershave", "after shave", "blaireau", "blouson homme", 
    "chaussures homme", "parfum homme", "sauvage", "bleu de chanel", "terre d'hermès", "terre d'hermes", 
    "boss bottled", "boutons de manchette"
]

KIDS_KEYWORDS = [
    "enfant", "enfants", "junior", "bébé", "3-6 ans", "6-12 ans", "doudou", "peluche", 
    "jouet", "lego juniors", "lego duplo", "playmobil", "puzzle enfant", "draisienne", "trottinette enfant"
]

TEEN_KEYWORDS = [
    "ado", "adolescent", "manga", "one piece", "demon slayer", "naruto", "gaming", "switch", 
    "ps5", "xbox", "skate", "sweat à capuche", "hoodie", "sneakers", "figurine"
]

YOUNG_ADULT_KEYWORDS = [
    "airpods", "sneakers", "dunk", "jordan", "streetwear", "cocktail", "enceinte bluetooth", 
    "sono", "jbl", "apéro", "festival", "escape game", "pilotage", "drone", "insta", "vinyle"
]

SENIOR_KEYWORDS = [
    "senior", "grand-mère", "grand-père", "mamie", "papy", "beaux livres", "pléiade", "jardinage", 
    "fauteuil relax", "sommelier", "grand cru", "opéra", "thalasso", "artisanat", "porcelaine"
]

BRAND_PATTERNS = [
    ("Apple", r"\b(apple|iphone|ipad|macbook|airpods|apple watch)\b"),
    ("Nike", r"\b(nike|dunk|air force|air jordan)\b"),
    ("Adidas", r"\b(adidas|samba|gazelle|spezial|ultraboost)\b"),
    ("Sony", r"\b(sony|playstation|ps5|wh-1000xm|dualsense)\b"),
    ("Nintendo", r"\b(nintendo|switch|zelda|mario|pokemon)\b"),
    ("Dyson", r"\b(dyson|airwrap|supersonic|v15|v12)\b"),
    ("Sephora", r"\b(sephora|rare beauty|fenty|huda)\b"),
    ("Dior", r"\b(dior|sauvage|jadore|miss dior)\b"),
    ("Chanel", r"\b(chanel|coco mademoiselle|bleu de chanel|n°5)\b"),
    ("Yves Saint Laurent", r"\b(yves saint laurent|ysl|libre|black opium)\b"),
    ("Le Creuset", r"\b(le creuset|cocotte)\b"),
    ("Diptyque", r"\b(diptyque|baies|figuier|tubereuse)\b"),
    ("Jacquemus", r"\b(jacquemus|chiquito|bambino)\b"),
    ("Polène", r"\b(polène|polene)\b"),
    ("Lego", r"\b(lego|star wars|technic|icons)\b"),
    ("Fender", r"\b(fender|stratocaster|telecaster)\b"),
    ("Yamaha", r"\b(yamaha|piano|guitare)\b"),
    ("Garmin", r"\b(garmin|forerunner|fenix|dashcam)\b"),
    ("DJI", r"\b(dji|mini 4|mavic|osmo)\b"),
    ("GoPro", r"\b(gopro|hero 12|hero 13)\b"),
    ("DeLonghi", r"\b(delonghi|magnifica|dedica)\b"),
    ("GetYourGuide", r"\b(getyourguide|visite guidée|pass musée)\b"),
    ("Wonderbox", r"\b(wonderbox|coffret cadeau wonderbox)\b"),
    ("Smartbox", r"\b(smartbox)\b"),
    ("Wecandoo", r"\b(wecandoo|atelier artisan)\b"),
    ("Booking", r"\b(booking|séjour insolite|nuit château)\b"),
    ("Lacoste", r"\b(lacoste)\b"),
    ("Ralph Lauren", r"\b(ralph lauren|polo ralph)\b"),
    ("Ray-Ban", r"\b(ray-ban|rayban|wayfarer|aviator)\b"),
    ("Tissot", r"\b(tissot|prx)\b"),
    ("Seiko", r"\b(seiko)\b"),
    ("Rituals", r"\b(rituals|sakura|karma)\b"),
    ("The North Face", r"\b(the north face|north face|nuptse)\b"),
    ("Salomon", r"\b(salomon)\b"),
    ("Theragun", r"\b(theragun|therabody)\b"),
    ("Audio-Technica", r"\b(audio-technica|lp120)\b"),
    ("Shure", r"\b(shure|sm7b)\b"),
    ("Taschen", r"\b(taschen)\b"),
    ("Wacom", r"\b(wacom|cintiq|intuos)\b"),
]

def clean_price(price_raw) -> float:
    if price_raw is None:
        return 49.99
    if isinstance(price_raw, (int, float)):
        return float(price_raw)
    
    # Ex: "129,99 €" -> 129.99
    txt = str(price_raw).replace(" ", "").replace("€", "").replace("\xa0", "").replace(",", ".")
    match = re.search(r"\d+(\.\d+)?", txt)
    if match:
        try:
            return round(float(match.group(0)), 2)
        except Exception:
            return 49.99
    return 49.99

def determine_brand(title: str, default_source: str) -> str:
    title_low = title.lower()
    for brand_name, pattern in BRAND_PATTERNS:
        if re.search(pattern, title_low):
            return brand_name
    
    # Fallback to source
    src = (default_source or "").strip()
    if src and len(src) > 2 and src.lower() not in ["google", "google shopping"]:
        return src
    return "DORÕN Prestige"

def determine_gender(title: str, cat: str, subcat: str, brand: str = "") -> str:
    t_low = f"{title} {brand}".lower()
    
    # Nettoyage des expressions pièges (ex: écouteurs "mains libres" vs parfum Libre)
    t_clean = t_low.replace("mains libres", "").replace("mains-libres", "").replace("libre de droit", "")
    
    is_fem = any(w in t_clean for w in FEMALE_KEYWORDS) or subcat in [
        "subcat_vetements_femme", "subcat_maquillage", "subcat_lingerie_nuit"
    ] or (brand in ["Polène", "Jacquemus", "Rare Beauty"] and subcat in ["subcat_sacs_maroquinerie", "subcat_maquillage", "subcat_bijoux"])
    
    is_mal = any(w in t_clean for w in MALE_KEYWORDS) or subcat in [
        "subcat_vetements_homme", "subcat_rasage_barbe"
    ]
    
    if is_fem and not is_mal:
        return "gender_femme"
    if is_mal and not is_fem:
        return "gender_homme"
    return "gender_mixte"

def determine_age_groups(title: str, price: float, cat: str, subcat: str) -> list:
    t_low = title.lower()
    ages = []
    
    if any(w in t_low for w in KIDS_KEYWORDS) or "jouet" in t_low:
        ages.append("age_enfant")
    if any(w in t_low for w in TEEN_KEYWORDS) or cat in ["cat_jeuxvideo"] or "manga" in t_low:
        ages.append("age_ado")
    if any(w in t_low for w in YOUNG_ADULT_KEYWORDS) or cat in ["cat_tech", "cat_mode", "cat_jeuxvideo", "cat_musique", "cat_tendances"]:
        ages.append("age_jeune_adulte")
    if price >= 50 or cat in ["cat_maison", "cat_food", "cat_beaute", "cat_voyage", "cat_mecanique_auto", "cat_activites_experiences"]:
        ages.append("age_adulte")
    if any(w in t_low for w in SENIOR_KEYWORDS) or cat in ["cat_jardinage", "cat_lecture", "cat_bienetre", "cat_food"]:
        ages.append("age_senior")
        
    if not ages:
        ages = ["age_jeune_adulte", "age_adulte"]
    return list(set(ages))

def determine_budget_tag(price: float) -> str:
    if price < 25:
        return "budget_0-25"
    elif price < 50:
        return "budget_25-50"
    elif price < 100:
        return "budget_50-100"
    elif price < 200:
        return "budget_100-200"
    else:
        return "budget_200+"

def determine_personalities(title: str, cat: str) -> list:
    t_low = title.lower()
    persos = []
    
    if cat in ["cat_tech", "cat_jeuxvideo", "cat_aeronautique"]:
        persos.append("perso_techie")
    if cat in ["cat_jeuxvideo"]:
        persos.append("perso_gamer")
    if cat in ["cat_food"]:
        persos.append("perso_epicurien")
    if cat in ["cat_art", "cat_musique"]:
        persos.append("perso_creatif")
    if cat in ["cat_sport", "cat_voyage", "cat_activites_experiences"]:
        persos.append("perso_aventurier")
    if cat in ["cat_maison", "cat_bienetre", "cat_lecture"]:
        persos.append("perso_cocooning")
    if cat in ["cat_mode", "cat_beaute"]:
        persos.append("perso_coquet")
    if cat in ["cat_mecanique_auto"]:
        persos.append("perso_auto_meca")
    if cat in ["cat_jardinage"]:
        persos.append("perso_jardinier")
        
    if not persos:
        persos.append("perso_epicurien")
    return list(set(persos))

JUNK_EXCLUSIONS = [
    "bras et moteur", "nacelle", "câble ptz", "écran lcd", "pour pièces", 
    "pièce détachée", "reconditionné", "reconditionne", "d'occasion", "seconde main", 
    "boîtier de charge seul", "boitier de charge seul", "coque seule", "câble seul", 
    "chargeur seul", "boîte vide", "boite vide", "débloqué grade", "grade a+", 
    "grade a", "grade b", "grade c", "très bon état", "tres bon etat", "bon état", 
    "comme neuf", "fluted bezel upgrade", "bracelet seul", "batterie seule", 
    "pièce de rechange", "verre trempé seul", "adaptateur secteur seul", "état correct",
    "batterie d'origine", "à réviser", "débloqué", "sans prix de réserve"
]

def is_junk_product(title: str) -> bool:
    t_low = title.lower()
    # Exceptions pour les ateliers d'artisanat Wecandoo ("Décorez votre pièce en céramique")
    if any(k in t_low for k in ["céramique", "poterie", "artisan", "atelier cuisine", "maroquinerie"]):
        if any(j in t_low for j in ["reconditionné", "reconditionne", "grade", "d'occasion", "bon état", "grade a"]):
            return True
        return False
    return any(j in t_low for j in JUNK_EXCLUSIONS)

def determine_events_and_subfilters(title: str, gender: str, cat: str, subcat: str, price: float) -> list:
    events = ["occasion_anniversaire", "occasion_noel"]
    t_low = title.lower()
    
    # =========================================================================
    # 🌹 SAINT-VALENTIN : STRICTEMENT ROMANTIQUE & LUXE & DUO (ZÉRO ÉLECTROMÉNAGER/MÉCA/BIÈRE/GAMING/OUTIL)
    # =========================================================================
    valentin_disallowed_cats = [
        "cat_mecanique_auto", "cat_jardinage", "cat_jeuxvideo", "cat_aeronautique", "cat_tech"
    ]
    valentin_disallowed_subcats = [
        "subcat_electromenager", "subcat_accessoires_auto_interieur", "subcat_outils_mecanique_diagnostic",
        "subcat_dashcam_securite_auto", "subcat_ordinateurs_accessoires", "subcat_gadgets_divers",
        "subcat_consoles_gaming", "subcat_manettes_accessoires_gaming", "subcat_casques_audio_gaming",
        "subcat_accessoires_sommellerie_bar"
    ]
    valentin_forbidden_keywords = [
        "aspirateur", "bière", "biere", "tireuse", "perceuse", "outil", "coffre", "moteur", "pneu", 
        "manette", "switch", "ps5", "xbox", "clavier gaming", "souris", "reconditionné", "reconditionne",
        "câble", "cable", "auto", "vidange", "support de table", "xlr", "pack micros", "seiko 5", "tissot prs"
    ]

    is_valentin_disallowed = (cat in valentin_disallowed_cats) or \
                             (subcat in valentin_disallowed_subcats) or \
                             any(w in t_low for w in valentin_forbidden_keywords)

    if not is_valentin_disallowed:
        is_valentin_subcat = subcat in [
            "subcat_bijoux", "subcat_parfum", "subcat_lingerie_nuit", "subcat_chocolats_confiseries",
            "subcat_ambiance_bougies_senteurs", "subcat_sacs_maroquinerie", "subcat_soin_visage",
            "subcat_soin_corps"
        ]
        
        valentin_patterns = [
            r"\b(romantique|amour|duo|couple|massage duo|spa duo|nuit insolite|château|chateau|lingerie)\b",
            r"\b(collier|bague|solitaire|diamant|pendentif|boucles d'oreilles|or 18k|or blanc|or rose|plaqué or)\b",
            r"\b(champagne|ruinart|dom perignon|chocolats fins|boîte de chocolats)\b",
            r"\b(polène|polene|jacquemus|diptyque|miss dior|j'adore|coco mademoiselle|libre ysl|black opium)\b"
        ]
        is_valentin_keyword = any(re.search(pat, t_low) for pat in valentin_patterns)
        
        is_valentin_experience = (cat == "cat_activites_experiences") and any(
            re.search(pat, t_low) for pat in [
                r"\b(duo|couple|spa|massage|nuit insolite|château|gastronomique|dîner aux chandelles|degustation vin|oenologie|maroquinerie|joaillerie)\b"
            ]
        )

        if is_valentin_subcat or is_valentin_keyword or is_valentin_experience:
            events.append("occasion_st_valentin")
            events.append("occasion_saint_valentin")
            if "duo" in t_low or "séjour" in t_low or "spa" in t_low or "massage" in t_low or is_valentin_experience:
                events.append("st_valentin_experience_duo")
            elif "personnalis" in t_low or "gravure" in t_low or subcat == "subcat_bijoux" or "collier" in t_low or "bague" in t_low:
                events.append("st_valentin_personnalise")
            else:
                events.append("st_valentin_romantique")

    # =========================================================================
    # 🌸 FÊTE DES MÈRES : STRICTEMENT FÉMININ & BIEN-ÊTRE (ZÉRO PRODUIT HOMME)
    # =========================================================================
    if gender in ["gender_femme", "gender_mixte"] and cat not in ["cat_mecanique_auto", "cat_jeuxvideo", "cat_aeronautique"]:
        is_meres_subcat = subcat in [
            "subcat_bijoux", "subcat_parfum", "subcat_soin_visage", "subcat_soin_corps", "subcat_cheveux_coiffure",
            "subcat_maquillage", "subcat_ambiance_bougies_senteurs", "subcat_sacs_maroquinerie", "subcat_cafe_the",
            "subcat_chocolats_confiseries", "subcat_cuisine_arts_de_la_table", "subcat_activites_ateliers_diy"
        ]
        if is_meres_subcat or any(w in t_low for w in ["maman", "mère", "femme", "soin", "beauté", "détente", "fleurs", "thé", "diptyque"]):
            events.append("occasion_fete_meres")
            events.append("occasion_fete")
            if cat in ["cat_bienetre", "cat_beaute"] or "spa" in t_low or "massage" in t_low or "soin" in t_low:
                events.append("fete_meres_detente")
            elif subcat == "subcat_bijoux" or "collier" in t_low or "bracelet" in t_low or "bague" in t_low:
                events.append("fete_meres_bijoux")
            elif cat == "cat_food" or "chocolat" in t_low or "thé" in t_low or "gourmand" in t_low:
                events.append("fete_meres_gourmandise")

    # =========================================================================
    # 👔 FÊTE DES PÈRES : STRICTEMENT MASCULIN & GASTRO & TECH (ZÉRO PRODUIT FEMME)
    # =========================================================================
    if (gender in ["gender_homme", "gender_mixte"] and cat not in ["cat_beaute", "cat_bienetre"]) or subcat in ["subcat_rasage_barbe", "subcat_parfum"]:
        is_peres_subcat = subcat in [
            "subcat_vins_spiritueux", "subcat_accessoires_sommellerie_bar", "subcat_montres_classiques",
            "subcat_vetements_homme", "subcat_rasage_barbe", "subcat_smartphones_tablettes", "subcat_audio",
            "subcat_wearables", "subcat_outils_mecanique_diagnostic", "subcat_simulation_vol_pilotage",
            "subcat_activites_sensations_fortes", "subcat_activites_gastronomie_oenologie"
        ]
        if is_peres_subcat or any(w in t_low for w in ["papa", "père", "homme", "whisky", "vin", "barbe", "rasage", "pilotage", "montre"]):
            events.append("occasion_fete_peres")
            events.append("occasion_fete")
            if cat in ["cat_tech", "cat_jeuxvideo", "cat_aeronautique"]:
                events.append("fete_peres_hightech")
            elif cat == "cat_food" or "vin" in t_low or "whisky" in t_low or "spiritueux" in t_low:
                events.append("fete_peres_gastronomie")
            elif cat == "cat_mecanique_auto" or "bricolage" in t_low or "outil" in t_low:
                events.append("fete_peres_bricolage_meca")

    # =========================================================================
    # 🏡 CRÉMAILLÈRE / MARIAGE / NAISSANCE / DIPLÔME
    # =========================================================================
    if cat in ["cat_maison", "cat_food", "cat_jardinage"] and subcat not in ["subcat_lingerie_nuit"]:
        events.append("occasion_cremaillere")
        
    if ("mariage" in t_low or "couple" in t_low or (cat in ["cat_maison", "cat_food", "cat_activites_experiences"] and price >= 80)) and not is_valentin_disallowed:
        events.append("occasion_mariage")
        
    if "bébé" in t_low or "naissance" in t_low or "maternité" in t_low or "doudou" in t_low:
        events.append("occasion_naissance")
        
    if "diplôme" in t_low or "stylo" in t_low or (cat in ["cat_tech", "cat_lecture", "cat_mode"] and price >= 50):
        events.append("occasion_diplome")
        
    return list(set(events))

FLAGSHIP_PATTERNS = [
    # Smartphones & High-Tech Stars (98-100)
    (r"\b(iphone 1[5-7]|airpods pro|airpods max|apple watch ultra|apple watch series|macbook air|macbook pro|ipad pro)\b", 100),
    (r"\b(dyson airwrap|dyson supersonic|dyson airstrait|dyson corrale|dyson v15|dyson v12)\b", 100),
    (r"\b(playstation 5|ps5|ps5 slim|dualsense)\b", 99),
    (r"\b(switch oled|zelda|mario kart|mario wonder|pokemon)\b", 98),
    (r"\b(wh-1000xm[45]|wf-1000xm5)\b", 98),
    (r"\b(dji mini [34]|gopro hero 1[23])\b", 98),
    # Fashion & Streetwear Hits (98-100)
    (r"\b(dunk low|air jordan 1|air force 1|travis scott|vomero)\b", 99),
    (r"\b(samba og|gazelle indoor|spezial|campus 00s)\b", 99),
    (r"\b(zara.*(collection|robe|manteau|blazer|studio)|nouvelle collection zara)\b", 98),
    (r"\b(jacquemus|le chiquito|le bambino|polène|polene)\b", 99),
    (r"\b(tissot prx|seiko presage|seiko 5 sports)\b", 98),
    # Fragrances & Beauty Stars (98-100)
    (r"\b(sauvage|bleu de chanel|coco mademoiselle|libre|black opium|baccarat rouge|j'adore)\b", 99),
    (r"\b(diptyque.*(baies|figuier|tubereuse)|rare beauty.*blush)\b", 98),
    (r"\b(the ritual of sakura|the ritual of karma|the ritual of mehr)\b", 96),
    # Gastronomy & Living (98-100)
    (r"\b(le creuset.*cocotte|magnifica s|delonghi dedica|kitchenaid artisan)\b", 98),
    (r"\b(ruinart blanc de blancs|dom perignon|grand cru|champagne)\b", 98),
    # Experiences & Workshops (98-100)
    (r"\b(wecandoo|atelier artisan|poterie|joaillerie|maroquinerie|soufflage)\b", 99),
    (r"\b(saut en parachute|vol en hélicoptère|stage de pilotage|nuit insolite château|spa cinq mondes)\b", 99),
    (r"\b(shure sm7b|audio-technica lp120|marshall stanmore|marshall emberton)\b", 98),
    (r"\b(lego.*(icons|concorde|faucon|star wars|porsche))\b", 98),
]

def determine_popularity_score(title: str, brand: str, cat: str, subcat: str, price: float, is_activity: bool) -> int:
    t_low = title.lower()
    
    # 1. Correspondance avec un produit Flagship / Trending
    for pattern, score in FLAGSHIP_PATTERNS:
        if re.search(pattern, t_low):
            return score
            
    # 2. Marques très fortes / désirables
    if brand in ["Apple", "Dyson", "Dior", "Chanel", "Jacquemus", "Polène", "Wecandoo", "Sony", "Nike", "Adidas", "Tissot"]:
        if price >= 100 or is_activity:
            return 96
        return 94
        
    if brand in ["Zara", "Rituals", "Sephora", "Lego", "Garmin", "DJI", "Le Creuset", "DeLonghi", "Ray-Ban", "Ralph Lauren", "Lacoste"]:
        return 92
        
    if is_activity:
        return 95
        
    # 3. Barème par défaut selon le positionnement prix
    if price >= 150:
        return 90
    elif price >= 50:
        return 88
    elif price >= 25:
        return 84
    else:
        return 80

BOX_EXCLUSIONS = [
    "smartbox", "wonderbox", "dakotabox", "dakota box", "coffret cadeau smartbox", 
    "coffret cadeau wonderbox", "coffret cadeau multi", "box multi-activités"
]

def is_excluded_box(title: str, source: str) -> bool:
    txt = (title + " " + (source or "")).lower()
    return any(b in txt for b in BOX_EXCLUSIONS)

def tag_raw_catalog():
    if not RAW_FILE.exists():
        print(f"❌ Fichier brut introuvable : {RAW_FILE}")
        return []
        
    with open(RAW_FILE, "r", encoding="utf-8") as f:
        raw_items = json.load(f)
        
    print(f"🔄 Enrichissement & Tagging de {len(raw_items)} items...")
    
    enriched_products = []
    seen_ids = set()
    
    for i, it in enumerate(raw_items, 1):
        title = it.get("title", "").strip()
        price = clean_price(it.get("price"))
        image = it.get("thumbnail", "").strip()
        url = it.get("link", "").strip()
        source = it.get("source", "Google Shopping")
        cat = it.get("target_cat", "cat_tech")
        subcat = it.get("target_subcat", "subcat_gadgets_divers")
        
        if not title or not image or not url:
            continue
            
        # Exclusion stricte des coffrets cadeaux types Smartbox / Wonderbox
        if is_excluded_box(title, source):
            continue
            
        # Exclusion stricte des pièces détachées, reconditionnés, câbles seuls et annonces de mauvaise qualité
        if is_junk_product(title):
            continue
            
        brand = determine_brand(title, source)
        gender = determine_gender(title, cat, subcat, brand)
        age_groups = determine_age_groups(title, price, cat, subcat)
        budget_tag = determine_budget_tag(price)
        persos = determine_personalities(title, cat)
        events = determine_events_and_subfilters(title, gender, cat, subcat, price)
        
        # Tags globaux combinés
        all_tags = [
            gender,
            budget_tag,
            cat,
            subcat,
            f"brand_{brand.lower().replace(' ', '_').replace('-', '_')}"
        ]
        all_tags.extend(age_groups)
        all_tags.extend(persos)
        all_tags.extend(events)
        all_tags = list(set([t for t in all_tags if t]))
        
        # Categories compatibles Flutter
        brand_clean = brand.lower()
        brand_norm = brand_clean.replace("&", "").replace(" ", "").replace("-", "")
        flutter_categories = list(set([
            cat,
            subcat,
            brand_clean,
            brand_norm,
            "trending",
            "curated",
            gender
        ]))
        
        # ID unique propre
        safe_title = re.sub(r"[^a-zA-Z0-9]", "_", title[:30]).lower()
        doc_id = f"doron_{brand_norm}_{safe_title}_{i}"
        
        is_activity = (cat == "cat_activites_experiences") or any(k in title.lower() for k in ["stage", "vol", "atelier", "séjour", "nuit", "visite", "coffret cadeau", "cours", "baptême"])
        
        pop_score = determine_popularity_score(title, brand, cat, subcat, price, is_activity)
        
        product_doc = {
            "id": doc_id,
            "name": title,
            "product_title": title,
            "brand": brand,
            "brandId": brand_clean,
            "price": price,
            "product_price": f"{price:.2f} €",
            "image": image,
            "product_photo": image,
            "url": url,
            "product_url": url,
            "description": f"{title} — Sélection officielle DORÕN {brand}. Idéal pour offrir ou se faire plaisir.",
            "category": cat,
            "subcategory": subcat,
            "categories": flutter_categories,
            "tags": all_tags,
            "gender": gender,
            "age_groups": age_groups,
            "budget": budget_tag,
            "is_activity": is_activity,
            "popularity": pop_score,
            "active": True,
            "source": source
        }
        
        enriched_products.append(product_doc)
        
    print(f"✅ {len(enriched_products)} fiches produits & activités enrichies avec succès !")
    
    with open(OUTPUT_CATALOG, "w", encoding="utf-8") as f:
        json.dump(enriched_products, f, indent=2, ensure_ascii=False)
        
    with open(FALLBACK_JSON, "w", encoding="utf-8") as f:
        json.dump(enriched_products, f, indent=2, ensure_ascii=False)
        
    print(f"💾 Sauvegardé dans {OUTPUT_CATALOG} et {FALLBACK_JSON}")
    return enriched_products

if __name__ == "__main__":
    tag_raw_catalog()
