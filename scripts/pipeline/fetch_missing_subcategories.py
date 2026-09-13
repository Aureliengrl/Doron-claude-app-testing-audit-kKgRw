#!/usr/bin/env python3
"""
Complément d'extraction ciblée pour couvrir 100% des sous-catégories restantes.
"""

import json
import os
import sys
import time
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

SERPAPI_KEY = os.environ.get("SERPAPI_KEY", "ee929df881bc08d5503cd04618757498c11ace09179b80fd8b0a2a20838b8ed1")
RAW_FILE = Path(__file__).resolve().parent / "raw_data" / "google_shopping_raw.json"

TARGET_QUERIES = [
    # Lecture
    {"q": "Roman best seller litterature", "cat": "cat_lecture", "subcat": "subcat_romans_litterature"},
    {"q": "Manga Demon Slayer coffret", "cat": "cat_lecture", "subcat": "subcat_mangas_comics"},
    {"q": "BD roman graphique Astérix", "cat": "cat_lecture", "subcat": "subcat_bd_romans_graphiques"},
    {"q": "Livre developpement personnel", "cat": "cat_lecture", "subcat": "subcat_developpement_personnel_essais"},
    {"q": "Liseuse Kobo Clara eReader", "cat": "cat_lecture", "subcat": "subcat_liseuses_accessoires_lecture"},
    {"q": "Beau livre photo coffee table", "cat": "cat_lecture", "subcat": "subcat_beaux_livres_coffee_table"},
    
    # Voyage
    {"q": "Valise Samsonite cabine", "cat": "cat_voyage", "subcat": "subcat_valises_bagagerie"},
    {"q": "Sac a dos Osprey voyage", "cat": "cat_voyage", "subcat": "subcat_sacs_a_dos_voyage"},
    {"q": "Adaptateur universel voyage nomade", "cat": "cat_voyage", "subcat": "subcat_accessoires_nomades"},
    {"q": "Organisateur bagage rangement valise", "cat": "cat_voyage", "subcat": "subcat_organisation_bagages"},
    {"q": "Equipement bivouac rechaud rando", "cat": "cat_voyage", "subcat": "subcat_equipement_bivouac_aventure"},
    {"q": "Carnet voyage Moleskine cuir", "cat": "cat_voyage", "subcat": "subcat_guides_carnets_voyage"},

    # Jardinage
    {"q": "Plante interieur Ficus pot", "cat": "cat_jardinage", "subcat": "subcat_plantes_interieur_cache_pots"},
    {"q": "Potager interieur autonome Pret a Pousser", "cat": "cat_jardinage", "subcat": "subcat_potager_interieur_connecte"},
    {"q": "Outils jardinage Opinel inox", "cat": "cat_jardinage", "subcat": "subcat_outils_jardinage_ergonomiques"},
    {"q": "Kit graines aromatiques bio a semer", "cat": "cat_jardinage", "subcat": "subcat_graines_kits_plantation"},
    {"q": "Brasero jardin exterieur fonte", "cat": "cat_jardinage", "subcat": "subcat_mobilier_deco_jardin"},
    {"q": "Arrosoir cuivre design interieur", "cat": "cat_jardinage", "subcat": "subcat_arrosage_entretien_plantes"},

    # Art & Créativité
    {"q": "Coffret peinture aquarelle Sennelier", "cat": "cat_art", "subcat": "subcat_peinture_dessin"},
    {"q": "Kit sculpture modelage argile", "cat": "cat_art", "subcat": "subcat_sculpture_modelage"},
    {"q": "Kit loisirs creatifs broderie diy", "cat": "cat_art", "subcat": "subcat_loisirs_creatifs_diy"},
    {"q": "Affiche art serigraphie encadree", "cat": "cat_art", "subcat": "subcat_affiches_tirages_dart"},

    # Maison & Déco
    {"q": "Plaid grosse maille laine maison", "cat": "cat_maison", "subcat": "subcat_linge_maison"},
    {"q": "Boite rangement bijoux cuir", "cat": "cat_maison", "subcat": "subcat_rangement_organisation"},
    {"q": "Miroir soleil dore design", "cat": "cat_maison", "subcat": "subcat_deco_murale_objets"},

    # Sport
    {"q": "Matériel fitness halterophilie musculation", "cat": "cat_sport", "subcat": "subcat_fitness_musculation"},
    {"q": "Paddle gonflable complet stand up", "cat": "cat_sport", "subcat": "subcat_sports_glisse_eau"},
    {"q": "Tenue sport technique compression", "cat": "cat_sport", "subcat": "subcat_vetements_techniques_sport"},
    {"q": "Gourde isotherme inox sport", "cat": "cat_sport", "subcat": "subcat_nutrition_recuperation_sport"},

    # Food & Boissons
    {"q": "Coffret degustation miel confitures", "cat": "cat_food", "subcat": "subcat_epicerie_fine"},
    {"q": "Coffret degustation spiritueux whisky rhum", "cat": "cat_food", "subcat": "subcat_coffrets_degustation"},
    {"q": "Carafe a decanter vin sommelier", "cat": "cat_food", "subcat": "subcat_accessoires_sommellerie_bar"},

    # Mécanique & Aéronautique
    {"q": "Support smartphone moto quad lock", "cat": "cat_mecanique_auto", "subcat": "subcat_accessoires_moto_motard"},
    {"q": "Valise diagnostic OBD2 multimarque auto", "cat": "cat_mecanique_auto", "subcat": "subcat_outils_mecanique_diagnostic"},
    {"q": "Organisateur coffre voiture cuir", "cat": "cat_mecanique_auto", "subcat": "subcat_accessoires_auto_interieur"},
    {"q": "Telescope astronomie Celestron", "cat": "cat_aeronautique", "subcat": "subcat_astronomie_espace"},
    {"q": "Beau livre histoire aviation pilote", "cat": "cat_aeronautique", "subcat": "subcat_livres_histoire_aviation"},
    {"q": "Lunettes de soleil aviateur pilote", "cat": "cat_aeronautique", "subcat": "subcat_accessoires_lifestyle_aviateur"},
]

def fetch_q(qinfo):
    query = qinfo["q"]
    params = {
        "engine": "google_shopping",
        "q": query,
        "gl": "fr",
        "hl": "fr",
        "num": 40,
        "api_key": SERPAPI_KEY
    }
    try:
        r = requests.get("https://serpapi.com/search.json", params=params, timeout=45)
        if r.status_code == 200:
            res = r.json().get("shopping_results", [])
            extracted = []
            for it in res:
                t = it.get("title", "")
                p = it.get("extracted_price") or it.get("price")
                img = it.get("thumbnail")
                link = it.get("product_link") or it.get("link")
                src = it.get("source", "Google Shopping")
                if t and img and link:
                    extracted.append({
                        "title": t,
                        "price": p,
                        "thumbnail": img,
                        "link": link,
                        "source": src,
                        "query": query,
                        "target_cat": qinfo["cat"],
                        "target_subcat": qinfo["subcat"]
                    })
            print(f"✅ '{query}' -> {len(extracted)} items", flush=True)
            return extracted
    except Exception as e:
        print(f"⚠️ '{query}' err: {e}", flush=True)
    return []

def main():
    existing = []
    if RAW_FILE.exists():
        with open(RAW_FILE, "r", encoding="utf-8") as f:
            existing = json.load(f)
    seen = {it["title"].lower().strip() for it in existing}
    all_items = list(existing)
    
    with ThreadPoolExecutor(max_workers=4) as ex:
        futures = {ex.submit(fetch_q, q): q for q in TARGET_QUERIES}
        for fut in as_completed(futures):
            items = fut.result()
            for it in items:
                if it["title"].lower().strip() not in seen:
                    seen.add(it["title"].lower().strip())
                    all_items.append(it)
                    
    with open(RAW_FILE, "w", encoding="utf-8") as f:
        json.dump(all_items, f, indent=2, ensure_ascii=False)
        
    print(f"🎉 Terminé ! Total brut : {len(all_items)} items dans {RAW_FILE}", flush=True)

if __name__ == "__main__":
    main()
