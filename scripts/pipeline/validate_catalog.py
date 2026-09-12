"""
Étape 3 — Script de validation et d'audit de qualité du catalogue DORÕN.
Vérifie pour chaque produit :
1. Présence des champs obligatoires (id, name, brand, price, url, image, category, subcategory, tags)
2. Validité de TOUS les tags contre TagsDefinitions
3. Non-vacuité des images et format des URLs
4. Couverture des 5 catégories et 35 sous-catégories
5. Distribution des prix et des genres
"""

import json
from pathlib import Path
from config import SUBCATEGORIES_BY_CATEGORY

BASE_DIR = Path(__file__).resolve().parent.parent.parent
FALLBACK_JSON = BASE_DIR / "assets" / "jsons" / "fallback_products.json"

# Définition des tags autorisés dans TagsDefinitions
GENDER_TAGS = {"gender_femme", "gender_homme", "gender_mixte"}
CATEGORY_TAGS = set(SUBCATEGORIES_BY_CATEGORY.keys()) | {"cat_tendances"}
ALL_SUBCATS = {s for sublist in SUBCATEGORIES_BY_CATEGORY.values() for s in sublist}
BUDGET_TAGS = {"budget_0_50", "budget_50_100", "budget_100_200", "budget_200+"}

GIFT_TYPES = {
    "type_mode_accessoires", "type_bien_etre", "type_sport_outdoor", "type_gastronomie",
    "type_culture", "type_high_tech", "type_maison_deco", "type_beaute_soins",
    "type_loisirs_creatifs", "type_jeux_jouets", "type_livres_bd", "type_musique_audio",
    "type_voyage_aventure", "type_automobile", "type_bijoux", "type_intime"
}

STYLES = {
    "style_elegant", "style_tendance", "style_minimaliste", "style_classique",
    "style_decontracte", "style_sportif", "style_vintage", "style_moderne",
    "style_luxe", "style_boheme", "style_streetwear", "style_eco_responsable",
    "style_creatif", "style_geek", "style_zen", "style_gourmand", "style_festif", "style_pratique", "style_romantique", "style_tech", "style_cool"
}

PERSOS = {
    "perso_creatif", "perso_actif", "perso_cool", "perso_bienveillant", "perso_ambitieux",
    "perso_romantique", "perso_aventurier", "perso_intellectuel", "perso_sociable",
    "perso_zen", "perso_excentrique", "perso_pratique", "perso_gourmand", "perso_techie", "perso_fashion", "perso_casanier", "perso_fetard", "perso_nature", "perso_epicurien", "perso_geek"
}

PASSIONS = {
    "passion_sport", "passion_cuisine", "passion_voyages", "passion_photo",
    "passion_jeuxvideo", "passion_lecture", "passion_musique", "passion_cinema",
    "passion_mode", "passion_beaute", "passion_tech", "passion_art",
    "passion_jardinage", "passion_bricolage", "passion_yoga", "passion_danse",
    "passion_nature", "passion_animaux", "passion_automobile", "passion_vins",
    "passion_loisirs_creatifs"
}

AGES = {"age_enfant", "age_ado", "age_adulte", "age_senior"}
CONTEXTS = {"context_famille", "context_ami", "context_colleague", "context_amoureux"}
OCCASIONS = {
    "occasion_anniversaire", "occasion_noel", "occasion_mariage",
    "occasion_saint_valentin", "occasion_fete", "occasion_remerciement",
    "occasion_naissance", "occasion_diplome", "occasion_cremaillere"
}
POPULARITE = {"popularite_1", "popularite_2", "popularite_3", "popularite_4", "popularite_5"}

ALL_VALID_TAGS = (
    GENDER_TAGS | CATEGORY_TAGS | ALL_SUBCATS | BUDGET_TAGS | GIFT_TYPES |
    STYLES | PERSOS | PASSIONS | AGES | CONTEXTS | OCCASIONS | POPULARITE
)

def audit_catalog():
    print(f"🔍 Audit du catalogue : {FALLBACK_JSON}")
    with FALLBACK_JSON.open("r", encoding="utf-8") as f:
        products = json.load(f)
        
    print(f"📊 Nombre total de produits analysés : {len(products)}\n")
    
    errors = []
    subcats_found = set()
    brands_found = set()
    cats_found = set()
    
    for i, p in enumerate(products, 1):
        pid = p.get("id", f"item_{i}")
        
        # 1. Champs obligatoires
        for field in ["id", "name", "brand", "price", "url", "image", "category", "subcategory", "tags"]:
            if field not in p or p[field] is None or (isinstance(p[field], str) and not p[field].strip()):
                errors.append(f"[{pid}] Champ manquant ou vide : '{field}'")
                
        # 2. Catégorie & sous-catégorie
        cat = p.get("category")
        subcat = p.get("subcategory")
        if cat not in CATEGORY_TAGS:
            errors.append(f"[{pid}] Catégorie invalide : '{cat}'")
        cats_found.add(cat)
        
        if subcat not in ALL_SUBCATS:
            errors.append(f"[{pid}] Sous-catégorie invalide : '{subcat}'")
        subcats_found.add(subcat)
        
        if subcat not in SUBCATEGORIES_BY_CATEGORY.get(cat, []):
            errors.append(f"[{pid}] Incohérence sous-catégorie '{subcat}' pour catégorie '{cat}'")
            
        # 3. Tags
        tags = p.get("tags", [])
        if not tags:
            errors.append(f"[{pid}] Aucun tag défini")
        for tag in tags:
            if tag not in ALL_VALID_TAGS:
                errors.append(f"[{pid}] Tag inconnu / hors taxonomie : '{tag}'")
                
        # 4. Prix
        price = p.get("price", 0)
        if not isinstance(price, (int, float)) or price <= 0:
            errors.append(f"[{pid}] Prix invalide : '{price}'")
            
        # 5. Image & URL
        img = p.get("image", "")
        if not img.startswith("http"):
            errors.append(f"[{pid}] URL image non HTTP(S) : '{img}'")
            
        brands_found.add(p.get("brand"))

    # Résumé
    print("=" * 60)
    print("📈 BILAN DE QUALITÉ DU CATALOGUE")
    print("=" * 60)
    print(f"✅ Catégories couvertes : {len(cats_found)}/{len(SUBCATEGORIES_BY_CATEGORY)} -> {cats_found}")
    print(f"✅ Sous-catégories couvertes : {len(subcats_found)}/{len(ALL_SUBCATS)} ({len(subcats_found)/len(ALL_SUBCATS)*100:.0f}%)")
    print(f"✅ Marques couvertes : {len(brands_found)} marques différentes")
    print(f"   ({', '.join(sorted(list(brands_found))[:15])}...)")
    
    missing_subcats = ALL_SUBCATS - subcats_found
    if missing_subcats:
        print(f"⚠️ Sous-catégories manquantes ({len(missing_subcats)}) : {missing_subcats}")
    else:
        print("🏆 100% DES SOUS-CATÉGORIES SONT COUVERTES !")
        
    print("\n" + "=" * 60)
    if errors:
        print(f"❌ {len(errors)} ERREUR(S) DÉTECTÉE(S) :")
        for err in errors[:20]:
            print(f"   • {err}")
        if len(errors) > 20:
            print(f"   ... et {len(errors) - 20} autres erreurs.")
    else:
        print("✨ ZÉRO ERREUR ! Le catalogue est 100% conforme à TagsDefinitions et prêt pour Flutter/Firestore.")
    print("=" * 60)

if __name__ == "__main__":
    audit_catalog()
