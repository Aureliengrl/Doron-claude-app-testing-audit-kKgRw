"""
Enrichisseur étendu pour couvrir 100% des sous-catégories dont les accessoires auto,
le bricolage, la sommellerie/bar, et le sportswear.
"""
import json
from pathlib import Path
from build_massive_perfect_catalog import CATALOG_DEFINITIONS, format_product_entry, PIPELINE_JSON, FALLBACK_JSON
from config import SUBCATEGORIES_BY_CATEGORY

NEW_CATEGORIES_PRODUCTS = {
    # =========================================================================
    # ACCESSOIRES AUTO TECH (subcat_accessoires_auto_tech)
    # =========================================================================
    "subcat_accessoires_auto_tech": [
        {
            "id": "garmin_dash_cam_mini_2",
            "name": "Garmin Dash Cam Mini 2 Caméra Embarquée 1080p Ultra-Compacte",
            "brand": "Garmin",
            "price": 129.99,
            "url": "https://www.garmin.com/fr-FR/p/731428",
            "image": "https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=1000&auto=format&fit=crop&q=80",
            "description": "Format clé de voiture invisible avec commande vocale, vision nocturne et enregistrement automatique des incidents.",
            "gender": "gender_mixte",
            "ages": ["age_ado", "age_adulte", "age_senior"],
            "styles": ["style_minimaliste", "style_moderne"],
            "persos": ["perso_pratique", "perso_techie", "perso_aventurier"],
            "passions": ["passion_automobile", "passion_tech", "passion_voyages"],
            "types": ["type_automobile", "type_high_tech"],
            "occasions": ["occasion_anniversaire", "occasion_fete", "occasion_noel"],
            "popularity": 96,
        },
        {
            "id": "belkin_support_voiture_magsafe",
            "name": "Belkin Support de Voiture Grille d'Aération MagSafe Sans Fil 15W",
            "brand": "Belkin",
            "price": 44.99,
            "url": "https://www.belkin.com/fr/",
            "image": "https://images.unsplash.com/photo-1584438784894-089d6a62b8fa?w=1000&auto=format&fit=crop&q=80",
            "description": "Fixation magnétique puissante certifiée MagSafe avec rotation portrait/paysage et charge induction rapide.",
            "gender": "gender_mixte",
            "ages": ["age_ado", "age_adulte", "age_senior"],
            "styles": ["style_minimaliste", "style_moderne"],
            "persos": ["perso_pratique", "perso_techie"],
            "passions": ["passion_automobile", "passion_tech"],
            "types": ["type_automobile", "type_high_tech"],
            "occasions": ["occasion_anniversaire", "occasion_noel", "occasion_remerciement"],
            "popularity": 94,
        },
        {
            "id": "xiaomi_compresseur_pneu_portatif_2",
            "name": "Xiaomi Compresseur d'Air Électrique Portable 2 pour Pneus Auto",
            "brand": "Xiaomi",
            "price": 49.99,
            "url": "https://www.mi.com/fr/",
            "image": "https://images.unsplash.com/photo-1486006920555-c77dce18193b?w=1000&auto=format&fit=crop&q=80",
            "description": "Gonflage rapide numérique avec capteur de pression automatique jusqu'à 150 PSI et lampe torche intégrée.",
            "gender": "gender_mixte",
            "ages": ["age_ado", "age_adulte", "age_senior"],
            "styles": ["style_moderne", "style_pratique"],
            "persos": ["perso_pratique", "perso_aventurier"],
            "passions": ["passion_automobile", "passion_bricolage"],
            "types": ["type_automobile", "type_high_tech"],
            "occasions": ["occasion_fete", "occasion_anniversaire", "occasion_noel"],
            "popularity": 95,
        },
        {
            "id": "anker_chargeur_allume_cigare_67w",
            "name": "Anker Chargeur Voiture Rapide 67W 3 Ports USB-C & USB-A",
            "brand": "Anker",
            "price": 35.99,
            "url": "https://www.anker.com/",
            "image": "https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=1000&auto=format&fit=crop&q=80",
            "description": "Recharge ultra-rapide pour MacBook, iPad et iPhone simultanément sur l'allume-cigare de la voiture.",
            "gender": "gender_mixte",
            "ages": ["age_ado", "age_adulte"],
            "styles": ["style_minimaliste", "style_moderne"],
            "persos": ["perso_pratique", "perso_techie"],
            "passions": ["passion_automobile", "passion_tech", "passion_voyages"],
            "types": ["type_automobile", "type_high_tech"],
            "occasions": ["occasion_anniversaire", "occasion_remerciement"],
            "popularity": 91,
        },
    ],

    # =========================================================================
    # SPORTSWEAR & OUTDOOR (subcat_sportswear_outdoor)
    # =========================================================================
    "subcat_sportswear_outdoor": [
        {
            "id": "nike_tech_fleece_hoodie",
            "name": "Nike Sportswear Tech Fleece Sweat à Capuche Zip Intégral",
            "brand": "Nike",
            "price": 129.99,
            "url": "https://www.nike.com/fr/",
            "image": "https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=1000&auto=format&fit=crop&q=80",
            "description": "Le molleton thermique premium et léger assurant chaleur et look streetwear avant-gardiste.",
            "gender": "gender_mixte",
            "ages": ["age_ado", "age_adulte"],
            "styles": ["style_streetwear", "style_sportif", "style_tendance"],
            "persos": ["perso_actif", "perso_cool"],
            "passions": ["passion_sport", "passion_mode"],
            "types": ["type_mode_accessoires", "type_sport_outdoor"],
            "occasions": ["occasion_anniversaire", "occasion_noel"],
            "popularity": 98,
        },
        {
            "id": "patagonia_sac_banane_black_hole",
            "name": "Patagonia Sac Banane Ultralight Black Hole 1L",
            "brand": "Patagonia",
            "price": 35.0,
            "url": "https://eu.patagonia.com/fr/fr/",
            "image": "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=1000&auto=format&fit=crop&q=80",
            "description": "100% nylon recyclé ripstop ultra-léger et résistant pour emporter l'essentiel en randonnée ou en ville.",
            "gender": "gender_mixte",
            "ages": ["age_ado", "age_adulte"],
            "styles": ["style_eco_responsable", "style_sportif", "style_decontracte"],
            "persos": ["perso_aventurier", "perso_nature", "perso_actif"],
            "passions": ["passion_sport", "passion_nature", "passion_voyages"],
            "types": ["type_sport_outdoor", "type_mode_accessoires", "type_voyage_aventure"],
            "occasions": ["occasion_anniversaire", "occasion_fete"],
            "popularity": 95,
        },
        {
            "id": "the_north_face_doudoune_nuptse_1996",
            "name": "The North Face Doudoune Rétro Nuptse 1996 en Duvet d'Oie",
            "brand": "The North Face",
            "price": 330.0,
            "url": "https://www.thenorthface.fr/",
            "image": "https://images.unsplash.com/photo-1544923246-77307dd654cb?w=1000&auto=format&fit=crop&q=80",
            "description": "Silhouette carrée légendaire avec garnissage en duvet d'oie indice 700 et finition déperlante.",
            "gender": "gender_mixte",
            "ages": ["age_ado", "age_adulte"],
            "styles": ["style_streetwear", "style_tendance", "style_luxe"],
            "persos": ["perso_fashion", "perso_aventurier", "perso_cool"],
            "passions": ["passion_mode", "passion_sport", "passion_voyages"],
            "types": ["type_mode_accessoires", "type_sport_outdoor"],
            "occasions": ["occasion_noel", "occasion_anniversaire"],
            "popularity": 97,
        },
    ],

    # =========================================================================
    # BRICOLAGE & OUTILLAGE (subcat_bricolage_outillage)
    # =========================================================================
    "subcat_bricolage_outillage": [
        {
            "id": "victorinox_couteau_suisse_huntsman",
            "name": "Victorinox Couteau Suisse Officiel Huntsman 15 Fonctions",
            "brand": "Victorinox",
            "price": 49.0,
            "url": "https://www.victorinox.com/fr-FR/",
            "image": "https://images.unsplash.com/photo-1593618998160-e34014e67546?w=1000&auto=format&fit=crop&q=80",
            "description": "Fabriqué en Suisse avec scie à bois, ciseaux, tire-bouchon et acier inoxydable légendaire.",
            "gender": "gender_mixte",
            "ages": ["age_ado", "age_adulte", "age_senior"],
            "styles": ["style_classique", "style_pratique"],
            "persos": ["perso_aventurier", "perso_pratique", "perso_nature", "perso_pratique"],
            "passions": ["passion_bricolage", "passion_nature", "passion_sport", "passion_voyages"],
            "types": ["type_sport_outdoor", "type_maison_deco"],
            "occasions": ["occasion_fete", "occasion_anniversaire", "occasion_noel"],
            "popularity": 98,
        },
        {
            "id": "bosch_tournevis_sans_fil_ixo_7",
            "name": "Bosch Visseuse Sans Fil IXO 7 Coffret Set avec Embouts",
            "brand": "Bosch",
            "price": 64.99,
            "url": "https://www.bosch-diy.com/fr/fr",
            "image": "https://images.unsplash.com/photo-1504148455328-c376907d081c?w=1000&auto=format&fit=crop&q=80",
            "description": "20% de couple en plus, éclairage LED 360° et batterie Li-Ion pour monter tous les meubles et réparer facilement.",
            "gender": "gender_mixte",
            "ages": ["age_adulte", "age_senior"],
            "styles": ["style_moderne", "style_pratique"],
            "persos": ["perso_pratique", "perso_pratique", "perso_casanier"],
            "passions": ["passion_bricolage", "passion_jardinage"],
            "types": ["type_maison_deco"],
            "occasions": ["occasion_cremaillere", "occasion_fete", "occasion_anniversaire"],
            "popularity": 94,
        },
        {
            "id": "opinel_coffret_nomade_cuisine",
            "name": "Opinel Coffret Nomade Cuisine & Pique-Nique Couteaux & Planche",
            "brand": "Opinel",
            "price": 65.0,
            "url": "https://www.opinel.com/fr/",
            "image": "https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?w=1000&auto=format&fit=crop&q=80",
            "description": "Manches en hêtre de Savoie avec tire-bouchon, éplucheur, couteau cranté et planche à découper.",
            "gender": "gender_mixte",
            "ages": ["age_adulte", "age_senior"],
            "styles": ["style_vintage", "style_eco_responsable"],
            "persos": ["perso_epicurien", "perso_nature", "perso_aventurier"],
            "passions": ["passion_cuisine", "passion_nature", "passion_vins"],
            "types": ["type_gastronomie", "type_maison_deco", "type_sport_outdoor"],
            "occasions": ["occasion_fete", "occasion_anniversaire", "occasion_cremaillere"],
            "popularity": 95,
        },
    ],

    # =========================================================================
    # ACCESSOIRES SOMMELLERIE & BAR (subcat_accessoires_sommellerie_bar)
    # =========================================================================
    "subcat_accessoires_sommellerie_bar": [
        {
            "id": "peugeot_tire_bouchon_electrique_elis_touch",
            "name": "Peugeot Tire-Bouchon Électrique Rechargeable Elis Touch Inox",
            "brand": "Peugeot Saveurs",
            "price": 109.0,
            "url": "https://fr.peugeot-saveurs.com/",
            "image": "https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=1000&auto=format&fit=crop&q=80",
            "description": "Extraction automatique du bouchon par simple pression avec indicateur LED de charge et coupe-capsule.",
            "gender": "gender_mixte",
            "ages": ["age_adulte", "age_senior"],
            "styles": ["style_luxe", "style_moderne", "style_elegant"],
            "persos": ["perso_epicurien", "perso_sociable"],
            "passions": ["passion_vins", "passion_cuisine"],
            "types": ["type_gastronomie", "type_maison_deco"],
            "occasions": ["occasion_cremaillere", "occasion_anniversaire", "occasion_noel", "occasion_fete"],
            "popularity": 97,
        },
        {
            "id": "riedel_carafe_a_decanter_cabernet",
            "name": "Riedel Carafe à Décanter le Vin en Cristal Soufflé Cabernet",
            "brand": "Riedel",
            "price": 49.90,
            "url": "https://www.riedel.com/fr-fr",
            "image": "https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=1000&auto=format&fit=crop&q=80",
            "description": "Design élégant autrichien en cristal pour aérer les vins jeunes et séparer les sédiments des vins mûrs.",
            "gender": "gender_mixte",
            "ages": ["age_adulte", "age_senior"],
            "styles": ["style_elegant", "style_luxe"],
            "persos": ["perso_epicurien", "perso_intellectuel"],
            "passions": ["passion_vins", "passion_cuisine"],
            "types": ["type_gastronomie", "type_maison_deco"],
            "occasions": ["occasion_mariage", "occasion_cremaillere", "occasion_anniversaire"],
            "popularity": 94,
        },
        {
            "id": "coffret_mixologie_shaker_barman_12_pieces",
            "name": "Coffret Mixologie Shaker Boston & Accessoires Cocktail Inox",
            "brand": "Barman Pro",
            "price": 59.90,
            "url": "https://www.amazon.fr/",
            "image": "https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=1000&auto=format&fit=crop&q=80",
            "description": "Shaker Boston, pilon, passoire Hawthorne, jigger gradué et livre de 50 recettes de cocktails.",
            "gender": "gender_mixte",
            "ages": ["age_ado", "age_adulte"],
            "styles": ["style_festif", "style_moderne"],
            "persos": ["perso_fetard", "perso_sociable", "perso_creatif"],
            "passions": ["passion_cuisine", "passion_vins"],
            "types": ["type_gastronomie", "type_maison_deco"],
            "occasions": ["occasion_anniversaire", "occasion_cremaillere", "occasion_noel"],
            "popularity": 96,
        },
    ],
}

# Fusion
for subcat, prods in NEW_CATEGORIES_PRODUCTS.items():
    if subcat in CATALOG_DEFINITIONS:
        CATALOG_DEFINITIONS[subcat].extend(prods)
    else:
        CATALOG_DEFINITIONS[subcat] = prods

# Regénération
full_catalog = []
for subcat, prods in CATALOG_DEFINITIONS.items():
    for p in prods:
        full_catalog.append(format_product_entry(p, subcat))

print(f"📦 Total catalogue DORÕN : {len(full_catalog)} produits")
with FALLBACK_JSON.open("w", encoding="utf-8") as f:
    json.dump(full_catalog, f, indent=2, ensure_ascii=False)
with PIPELINE_JSON.open("w", encoding="utf-8") as f:
    json.dump(full_catalog, f, indent=2, ensure_ascii=False)

print("✅ Fichiers mis à jour !")
