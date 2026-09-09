"""
Configuration du pipeline d'enrichissement catalogue DORON.

Définit :
  - la taxonomie de sous-catégories (doit rester synchro avec
    lib/services/tags_definitions.dart -> subcategoryTagsByCategory)
  - les termes de recherche associés à chaque sous-catégorie
  - la liste de marques du run de TEST (petite, volontairement limitée)
  - la liste de marques du run COMPLET (à activer une fois le test validé)
"""

# ============================================================================
# Sous-catégories (miroir de tags_definitions.dart)
# ============================================================================

SUBCATEGORIES_BY_CATEGORY = {
    "cat_tech": [
        "subcat_smartphones_tablettes",
        "subcat_ordinateurs_accessoires",
        "subcat_audio",
        "subcat_wearables",
        "subcat_photo_video",
        "subcat_gaming",
        "subcat_maison_connectee",
        "subcat_gadgets_divers",
    ],
    "cat_mode": [
        "subcat_vetements_femme",
        "subcat_vetements_homme",
        "subcat_chaussures",
        "subcat_sacs_maroquinerie",
        "subcat_bijoux",
        "subcat_montres_classiques",
        "subcat_accessoires_mode",
        "subcat_lingerie_nuit",
    ],
    "cat_maison": [
        "subcat_deco_murale_objets",
        "subcat_linge_maison",
        "subcat_cuisine_arts_de_la_table",
        "subcat_ambiance_bougies_senteurs",
        "subcat_rangement_organisation",
        "subcat_jardin_exterieur",
        "subcat_electromenager",
    ],
    "cat_beaute": [
        "subcat_parfum",
        "subcat_soin_visage",
        "subcat_soin_corps",
        "subcat_maquillage",
        "subcat_cheveux_coiffure",
        "subcat_rasage_barbe",
        "subcat_bienetre_spa",
        "subcat_appareils_beaute",
    ],
    "cat_food": [
        "subcat_epicerie_fine",
        "subcat_vins_spiritueux",
        "subcat_chocolats_confiseries",
        "subcat_cafe_the",
        "subcat_coffrets_degustation",
    ],
}

# Terme de recherche générique (français) associé à chaque sous-catégorie.
# Utilisé pour construire les requêtes "<marque> <terme>".
QUERY_TERM_BY_SUBCATEGORY = {
    "subcat_smartphones_tablettes": "smartphone",
    "subcat_ordinateurs_accessoires": "ordinateur portable",
    "subcat_audio": "écouteurs",
    "subcat_wearables": "montre connectée",
    "subcat_photo_video": "appareil photo",
    "subcat_gaming": "console de jeux",
    "subcat_maison_connectee": "enceinte connectée",
    "subcat_gadgets_divers": "gadget high-tech",
    "subcat_vetements_femme": "robe",
    "subcat_vetements_homme": "pull homme",
    "subcat_chaussures": "chaussures",
    "subcat_sacs_maroquinerie": "sac à main",
    "subcat_bijoux": "bijou",
    "subcat_montres_classiques": "montre",
    "subcat_accessoires_mode": "ceinture",
    "subcat_lingerie_nuit": "lingerie",
    "subcat_deco_murale_objets": "cadre décoratif",
    "subcat_linge_maison": "plaid",
    "subcat_cuisine_arts_de_la_table": "vaisselle",
    "subcat_ambiance_bougies_senteurs": "bougie parfumée",
    "subcat_rangement_organisation": "boîte de rangement",
    "subcat_jardin_exterieur": "coussin extérieur",
    "subcat_electromenager": "cafetière",
    "subcat_parfum": "parfum",
    "subcat_soin_visage": "crème visage",
    "subcat_soin_corps": "soin corps",
    "subcat_maquillage": "palette maquillage",
    "subcat_cheveux_coiffure": "lisseur cheveux",
    "subcat_rasage_barbe": "tondeuse barbe",
    "subcat_bienetre_spa": "coffret spa",
    "subcat_appareils_beaute": "brosse nettoyante visage",
    "subcat_epicerie_fine": "coffret gourmand",
    "subcat_vins_spiritueux": "coffret vin",
    "subcat_chocolats_confiseries": "chocolats",
    "subcat_cafe_the": "coffret thé",
    "subcat_coffrets_degustation": "coffret dégustation",
}

# ============================================================================
# Run de TEST — 3 marques x ~4 sous-catégories chacune (≈12 requêtes)
# À valider avant de passer au run complet.
# ============================================================================

TEST_BRAND_SUBCATEGORIES = {
    "Apple": [
        "subcat_smartphones_tablettes",
        "subcat_audio",
        "subcat_wearables",
        "subcat_ordinateurs_accessoires",
    ],
    "Zara": [
        "subcat_vetements_femme",
        "subcat_vetements_homme",
        "subcat_chaussures",
        "subcat_accessoires_mode",
    ],
    "IKEA": [
        "subcat_deco_murale_objets",
        "subcat_rangement_organisation",
        "subcat_ambiance_bougies_senteurs",
        "subcat_cuisine_arts_de_la_table",
    ],
}

# ============================================================================
# Run COMPLET — à compléter/décommenter une fois le test validé.
# Chaque marque est associée aux sous-catégories pertinentes pour elle
# (pas de cross-produit brute marque x TOUTES les sous-catégories : ça
# générerait des requêtes absurdes comme "Apple robe été").
# ============================================================================

FULL_BRAND_SUBCATEGORIES = {
    # Tech
    "Apple": SUBCATEGORIES_BY_CATEGORY["cat_tech"],
    "Samsung": SUBCATEGORIES_BY_CATEGORY["cat_tech"],
    "Sony": ["subcat_audio", "subcat_photo_video", "subcat_gaming"],
    "Bose": ["subcat_audio"],
    "JBL": ["subcat_audio", "subcat_maison_connectee"],
    "Garmin": ["subcat_wearables"],
    # Mode
    "Zara": SUBCATEGORIES_BY_CATEGORY["cat_mode"],
    "Zalando": SUBCATEGORIES_BY_CATEGORY["cat_mode"],
    "Mango": SUBCATEGORIES_BY_CATEGORY["cat_mode"],
    "Nike": ["subcat_chaussures", "subcat_vetements_femme", "subcat_vetements_homme"],
    # Maison
    "IKEA": SUBCATEGORIES_BY_CATEGORY["cat_maison"],
    "Maison du Monde": SUBCATEGORIES_BY_CATEGORY["cat_maison"],
    "Alinéa": SUBCATEGORIES_BY_CATEGORY["cat_maison"],
    # Beauté
    "Sephora": SUBCATEGORIES_BY_CATEGORY["cat_beaute"],
    "Nocibé": SUBCATEGORIES_BY_CATEGORY["cat_beaute"],
    # Food
    "Fauchon": SUBCATEGORIES_BY_CATEGORY["cat_food"],
    "Nespresso": ["subcat_cafe_the"],
}


def build_queries(brand_subcategories: dict) -> list[dict]:
    """Transforme un mapping {marque: [subcat, ...]} en liste de requêtes.

    Retourne une liste de dicts {brand, subcategory, query}.
    """
    queries = []
    for brand, subcats in brand_subcategories.items():
        for subcat in subcats:
            term = QUERY_TERM_BY_SUBCATEGORY.get(subcat)
            if not term:
                continue
            queries.append(
                {
                    "brand": brand,
                    "subcategory": subcat,
                    "query": f"{brand} {term}",
                }
            )
    return queries
