#!/usr/bin/env python3
"""
DORÕN - Google Shopping & Activités Mass Extractor Multi-Threadé via SerpApi.
Requêtes optimisées (2-3 mots-clés) pour extraire 40+ items par requête avec 100% de succès.
"""

import json
import os
import sys
import time
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

SERPAPI_KEY = os.environ.get("SERPAPI_KEY", "ee929df881bc08d5503cd04618757498c11ace09179b80fd8b0a2a20838b8ed1")
BASE_DIR = Path(__file__).resolve().parent.parent.parent
RAW_DIR = Path(__file__).resolve().parent / "raw_data"
RAW_FILE = RAW_DIR / "google_shopping_raw.json"

# Matrice de requêtes optimisées à haut rendement (40 items par appel)
SEARCH_QUERIES = [
    # === ACTIVITÉS & EXPÉRIENCES ===
    {"q": "Smartbox pilotage circuit", "cat": "cat_activites_experiences", "subcat": "subcat_activites_sensations_fortes"},
    {"q": "Wonderbox sejour insolite", "cat": "cat_activites_experiences", "subcat": "subcat_activites_sejours_insolites"},
    {"q": "Wonderbox thalasso spa duo", "cat": "cat_activites_experiences", "subcat": "subcat_activites_bienetre_spas_duo"},
    {"q": "GetYourGuide Paris visite", "cat": "cat_activites_experiences", "subcat": "subcat_activites_culture_visites_guidees"},
    {"q": "Wecandoo atelier maroquinerie", "cat": "cat_activites_experiences", "subcat": "subcat_activites_ateliers_diy"},
    {"q": "Wecandoo atelier ceramique", "cat": "cat_activites_experiences", "subcat": "subcat_activites_ateliers_diy"},
    {"q": "Coffret saut parachute tandem", "cat": "cat_activites_experiences", "subcat": "subcat_activites_sensations_fortes"},
    {"q": "Coffret bapteme helicoptere", "cat": "cat_activites_experiences", "subcat": "subcat_activites_sensations_fortes"},
    {"q": "Coffret cours oenologie vin", "cat": "cat_activites_experiences", "subcat": "subcat_activites_gastronomie_oenologie"},
    {"q": "Coffret cours cuisine chef", "cat": "cat_activites_experiences", "subcat": "subcat_activites_gastronomie_oenologie"},
    {"q": "Smartbox nuit chateau gourmande", "cat": "cat_activites_experiences", "subcat": "subcat_activites_sejours_insolites"},
    {"q": "Smartbox bien etre massage", "cat": "cat_activites_experiences", "subcat": "subcat_activites_bienetre_spas_duo"},

    # === TECH & GADGETS ===
    {"q": "Apple iPhone 15 Pro", "cat": "cat_tech", "subcat": "subcat_smartphones_tablettes"},
    {"q": "Apple iPad Air", "cat": "cat_tech", "subcat": "subcat_smartphones_tablettes"},
    {"q": "Apple MacBook Air", "cat": "cat_tech", "subcat": "subcat_ordinateurs_accessoires"},
    {"q": "Apple AirPods Pro 2", "cat": "cat_tech", "subcat": "subcat_audio"},
    {"q": "Apple Watch Series 9", "cat": "cat_tech", "subcat": "subcat_wearables"},
    {"q": "Sony WH 1000XM5 casque", "cat": "cat_tech", "subcat": "subcat_audio"},
    {"q": "Bose QuietComfort Ultra", "cat": "cat_tech", "subcat": "subcat_audio"},
    {"q": "DJI Mini 4 Pro drone", "cat": "cat_tech", "subcat": "subcat_photo_video"},
    {"q": "GoPro Hero 12", "cat": "cat_tech", "subcat": "subcat_photo_video"},
    {"q": "Kindle Paperwhite liseuse", "cat": "cat_tech", "subcat": "subcat_gadgets_divers"},
    {"q": "Philips Hue pack demarrage", "cat": "cat_tech", "subcat": "subcat_maison_connectee"},
    {"q": "Marshall Acton 3 enceinte", "cat": "cat_tech", "subcat": "subcat_audio"},
    {"q": "Samsung Galaxy S24", "cat": "cat_tech", "subcat": "subcat_smartphones_tablettes"},

    # === MODE & ACCESSOIRES ===
    {"q": "Nike Dunk Low sneakers", "cat": "cat_mode", "subcat": "subcat_chaussures"},
    {"q": "Nike Air Jordan 1", "cat": "cat_mode", "subcat": "subcat_chaussures"},
    {"q": "Adidas Samba OG", "cat": "cat_mode", "subcat": "subcat_chaussures"},
    {"q": "Jacquemus sac Le Chiquito", "cat": "cat_mode", "subcat": "subcat_sacs_maroquinerie"},
    {"q": "Polene sac cuir femme", "cat": "cat_mode", "subcat": "subcat_sacs_maroquinerie"},
    {"q": "Lacoste polo homme classique", "cat": "cat_mode", "subcat": "subcat_vetements_homme"},
    {"q": "Ralph Lauren pull homme", "cat": "cat_mode", "subcat": "subcat_vetements_homme"},
    {"q": "Sandro robe femme soiree", "cat": "cat_mode", "subcat": "subcat_vetements_femme"},
    {"q": "Maje robe courte femme", "cat": "cat_mode", "subcat": "subcat_vetements_femme"},
    {"q": "Ray Ban Wayfarer lunettes", "cat": "cat_mode", "subcat": "subcat_accessoires_mode"},
    {"q": "Tissot PRX automatique", "cat": "cat_mode", "subcat": "subcat_montres_classiques"},
    {"q": "Seiko 5 Sports montre", "cat": "cat_mode", "subcat": "subcat_montres_classiques"},
    {"q": "Pandora bracelet charm argent", "cat": "cat_mode", "subcat": "subcat_bijoux"},
    {"q": "APM Monaco boucles oreilles", "cat": "cat_mode", "subcat": "subcat_bijoux"},
    {"q": "Montblanc portefeuille cuir", "cat": "cat_mode", "subcat": "subcat_sacs_maroquinerie"},

    # === BEAUTÉ & SOINS ===
    {"q": "Dior Sauvage eau parfum", "cat": "cat_beaute", "subcat": "subcat_parfum"},
    {"q": "Chanel Coco Mademoiselle", "cat": "cat_beaute", "subcat": "subcat_parfum"},
    {"q": "YSL Libre eau parfum", "cat": "cat_beaute", "subcat": "subcat_parfum"},
    {"q": "Dyson Airwrap complet", "cat": "cat_beaute", "subcat": "subcat_cheveux_coiffure"},
    {"q": "Dyson Supersonic seche cheveux", "cat": "cat_beaute", "subcat": "subcat_cheveux_coiffure"},
    {"q": "Rare Beauty blush liquide", "cat": "cat_beaute", "subcat": "subcat_maquillage"},
    {"q": "Sephora Collection coffret", "cat": "cat_beaute", "subcat": "subcat_maquillage"},
    {"q": "La Roche Posay Hyalu B5", "cat": "cat_beaute", "subcat": "subcat_soin_visage"},
    {"q": "Braun Series 9 Pro rasoir", "cat": "cat_beaute", "subcat": "subcat_rasage_barbe"},
    {"q": "Rituals coffret Sakura", "cat": "cat_beaute", "subcat": "subcat_soin_corps"},

    # === MAISON & DESIGN ===
    {"q": "Diptyque bougie Baies", "cat": "cat_maison", "subcat": "subcat_ambiance_bougies_senteurs"},
    {"q": "Diptyque bougie Figuier", "cat": "cat_maison", "subcat": "subcat_ambiance_bougies_senteurs"},
    {"q": "Le Creuset cocotte fonte", "cat": "cat_maison", "subcat": "subcat_cuisine_arts_de_la_table"},
    {"q": "DeLonghi Magnifica S", "cat": "cat_maison", "subcat": "subcat_electromenager"},
    {"q": "Ninja Foodi Dual Zone airfryer", "cat": "cat_maison", "subcat": "subcat_electromenager"},
    {"q": "Kartell Bourgie lampe", "cat": "cat_maison", "subcat": "subcat_luminaire_ambiance"},
    {"q": "KitchenAid robot artisan", "cat": "cat_maison", "subcat": "subcat_electromenager"},
    {"q": "Dyson V15 Detect aspirateur", "cat": "cat_maison", "subcat": "subcat_electromenager"},
    {"q": "Alessi tire bouchon Anna G", "cat": "cat_maison", "subcat": "subcat_cuisine_arts_de_la_table"},

    # === FOOD & GASTRONOMIE ===
    {"q": "Coffret vin Bordeaux Grand Cru", "cat": "cat_food", "subcat": "subcat_vins_spiritueux"},
    {"q": "Champagne Ruinart Blanc Blancs", "cat": "cat_food", "subcat": "subcat_vins_spiritueux"},
    {"q": "Panier gourmand foie gras truffe", "cat": "cat_food", "subcat": "subcat_epicerie_fine"},
    {"q": "Maison du Chocolat coffret", "cat": "cat_food", "subcat": "subcat_chocolats_confiseries"},
    {"q": "Mariage Freres the coffret", "cat": "cat_food", "subcat": "subcat_cafe_the"},
    {"q": "Kusmi Tea coffret the", "cat": "cat_food", "subcat": "subcat_cafe_the"},
    {"q": "Peugeot Saveurs moulin poivre", "cat": "cat_food", "subcat": "subcat_accessoires_sommellerie_bar"},

    # === SPORT & OUTDOOR ===
    {"q": "Garmin Forerunner 265", "cat": "cat_sport", "subcat": "subcat_running_athletisme"},
    {"q": "Theragun Pro pistolet massage", "cat": "cat_sport", "subcat": "subcat_nutrition_recuperation_sport"},
    {"q": "Wilson Pro Staff raquette", "cat": "cat_sport", "subcat": "subcat_sports_raquette"},
    {"q": "Babolat Pure Aero raquette", "cat": "cat_sport", "subcat": "subcat_sports_raquette"},
    {"q": "The North Face Nuptse veste", "cat": "cat_sport", "subcat": "subcat_sports_outdoor_rando"},
    {"q": "Salomon Speedcross trail", "cat": "cat_sport", "subcat": "subcat_sports_outdoor_rando"},

    # === GAMING & JEUX ===
    {"q": "PlayStation 5 Slim console", "cat": "cat_jeuxvideo", "subcat": "subcat_consoles_gaming"},
    {"q": "Nintendo Switch OLED", "cat": "cat_jeuxvideo", "subcat": "subcat_consoles_gaming"},
    {"q": "Manette DualSense PS5", "cat": "cat_jeuxvideo", "subcat": "subcat_manettes_accessoires_gaming"},
    {"q": "Logitech G Pro X casque", "cat": "cat_jeuxvideo", "subcat": "subcat_casques_audio_gaming"},
    {"q": "Lego Icons Faucon Millenium", "cat": "cat_jeuxvideo", "subcat": "subcat_goodies_figurines_gaming"},
    {"q": "Jeu PS5 EA Sports FC 25", "cat": "cat_jeuxvideo", "subcat": "subcat_jeux_video_hits"},
    {"q": "Jeu Switch Zelda Tears Kingdom", "cat": "cat_jeuxvideo", "subcat": "subcat_jeux_video_hits"},

    # === MUSIQUE & CULTURE ===
    {"q": "Fender Player Stratocaster", "cat": "cat_musique", "subcat": "subcat_instruments_cordes"},
    {"q": "Yamaha guitare acoustique", "cat": "cat_musique", "subcat": "subcat_instruments_cordes"},
    {"q": "Yamaha piano numerique P145", "cat": "cat_musique", "subcat": "subcat_claviers_pianos"},
    {"q": "Audio Technica platine vinyle LP120", "cat": "cat_musique", "subcat": "subcat_platines_vinyles"},
    {"q": "Shure SM7B micro podcast", "cat": "cat_musique", "subcat": "subcat_home_studio_mao"},
    {"q": "Taschen beau livre art", "cat": "cat_art", "subcat": "subcat_livres_art_monographies"},
    {"q": "Wacom tablette graphique Intuos", "cat": "cat_art", "subcat": "subcat_materiel_arts_graphiques"},
    {"q": "Coffret manga One Piece integrale", "cat": "cat_lecture", "subcat": "subcat_mangas_comics"},

    # === MÉCANIQUE AUTO & AÉRONAUTIQUE ===
    {"q": "Garmin Dash Cam 67W", "cat": "cat_mecanique_auto", "subcat": "subcat_dashcam_securite_auto"},
    {"q": "Meguiars kit detailing auto", "cat": "cat_mecanique_auto", "subcat": "subcat_entretien_nettoyage_auto_prestige"},
    {"q": "Thrustmaster T300 RS volant", "cat": "cat_mecanique_auto", "subcat": "subcat_lifestyle_passion_automobile"},
    {"q": "Logitech G Saitek palonnier vol", "cat": "cat_aeronautique", "subcat": "subcat_simulation_vol_pilotage"},
    {"q": "Celestron telescope astronomie", "cat": "cat_aeronautique", "subcat": "subcat_astronomie_espace"},
    {"q": "Maquette avion Concorde metal", "cat": "cat_aeronautique", "subcat": "subcat_maquettes_avions_collection"},

    # === BIEN-ÊTRE & JARDINAGE ===
    {"q": "Diffuseur huiles essentielles ceramique", "cat": "cat_bienetre", "subcat": "subcat_aromatherapie_diffuseurs"},
    {"q": "Philips Somneo reveil aube", "cat": "cat_bienetre", "subcat": "subcat_sommeil_reveils_lumiere"},
    {"q": "Tapis champ fleurs acupression", "cat": "cat_bienetre", "subcat": "subcat_thermotherapie_acupression"},
    {"q": "Potager interieur autonome Veritable", "cat": "cat_jardinage", "subcat": "subcat_potager_interieur_connecte"},
    {"q": "Plante Monstera pot ceramique", "cat": "cat_jardinage", "subcat": "subcat_plantes_interieur_cache_pots"},

    # === TENDANCES & VIRAL ===
    {"q": "Stanley Cup gourde isotherme", "cat": "cat_tendances", "subcat": "subcat_tendances_gadgets_viraux"},
    {"q": "Fujifilm Instax Mini 12", "cat": "cat_tendances", "subcat": "subcat_tendances_gadgets_viraux"},
    {"q": "Sunset Lamp projection", "cat": "cat_tendances", "subcat": "subcat_tendances_gadgets_viraux"},
    {"q": "Ember Ceramic Mug connecte", "cat": "cat_tendances", "subcat": "subcat_tendances_tech_futuriste"},
]

def fetch_single_query(qinfo: dict, max_results: int = 40):
    query = qinfo["q"]
    cat = qinfo["cat"]
    subcat = qinfo["subcat"]
    
    params = {
        "engine": "google_shopping",
        "q": query,
        "gl": "fr",
        "hl": "fr",
        "num": max_results,
        "api_key": SERPAPI_KEY
    }
    
    for attempt in range(2):
        try:
            resp = requests.get("https://serpapi.com/search.json", params=params, timeout=60)
            if resp.status_code != 200:
                print(f"⚠️ [Tentative {attempt+1}] Erreur {resp.status_code} sur '{query}'", flush=True)
                time.sleep(1)
                continue
                
            data = resp.json()
            results = data.get("shopping_results", [])
            extracted = []
            
            for item in results:
                title = item.get("title", "")
                price = item.get("extracted_price") or item.get("price")
                thumbnail = item.get("thumbnail")
                link = item.get("product_link") or item.get("link")
                source = item.get("source", "Google Shopping")
                rating = item.get("rating")
                reviews = item.get("reviews")
                
                if not title or not thumbnail or not link:
                    continue
                    
                extracted.append({
                    "title": title,
                    "price": price,
                    "thumbnail": thumbnail,
                    "link": link,
                    "source": source,
                    "rating": rating,
                    "reviews": reviews,
                    "query": query,
                    "target_cat": cat,
                    "target_subcat": subcat
                })
                
            print(f"✅ '{query}' ➔ {len(extracted)} items extraits", flush=True)
            return extracted
        except Exception as e:
            print(f"⚠️ [Tentative {attempt+1}] Exception sur '{query}': {e}", flush=True)
            time.sleep(1)
            
    return []

def main():
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    
    existing = []
    if RAW_FILE.exists():
        try:
            with open(RAW_FILE, "r", encoding="utf-8") as f:
                existing = json.load(f)
            print(f"📦 {len(existing)} items déjà en cache dans {RAW_FILE}", flush=True)
        except Exception:
            existing = []
            
    seen_titles = {item["title"].lower().strip() for item in existing}
    all_items = list(existing)
    
    # Filtrer requêtes non encore faites
    queries_to_run = [q for q in SEARCH_QUERIES if not any(it.get("query") == q["q"] for it in all_items)]
    print(f"🚀 Lancement de l'extraction sur {len(queries_to_run)} requêtes ciblées (parallélisme 4 workers)...", flush=True)
    
    with ThreadPoolExecutor(max_workers=4) as executor:
        future_to_query = {executor.submit(fetch_single_query, qinfo): qinfo for qinfo in queries_to_run}
        
        for future in as_completed(future_to_query):
            qinfo = future_to_query[future]
            try:
                items = future.result()
                added = 0
                for it in items:
                    t_norm = it["title"].lower().strip()
                    if t_norm not in seen_titles:
                        seen_titles.add(t_norm)
                        all_items.append(it)
                        added += 1
                
                # Sauvegarde en temps réel
                with open(RAW_FILE, "w", encoding="utf-8") as f:
                    json.dump(all_items, f, indent=2, ensure_ascii=False)
                    
                print(f"💾 Progression : {len(all_items)} items au total (+{added})", flush=True)
            except Exception as exc:
                print(f"❌ Erreur sur {qinfo['q']}: {exc}", flush=True)
                
    print("=" * 60, flush=True)
    print(f"🎉 Extraction terminée ! Total brut : {len(all_items)} produits et activités uniques.", flush=True)
    print(f"💾 Sauvegardé dans {RAW_FILE}", flush=True)
    print("=" * 60, flush=True)

if __name__ == "__main__":
    main()
