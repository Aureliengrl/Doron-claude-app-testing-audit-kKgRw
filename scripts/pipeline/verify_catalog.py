#!/usr/bin/env python3
"""
Auditeur & Validateur Qualité DORÕN (Zéro Image Brisée / Zéro Défaut).
Vérifie le statut HTTP 200 de chaque image de manière concurrente avec ThreadPoolExecutor,
élimine tout doublon ou URL morte, et génère le fichier final de production.
"""

import json
import os
import sys
import time
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent.parent
sys.path.append(str(Path(__file__).resolve().parent))
from doron_tagging_engine import determine_popularity_score, determine_gender, clean_price

CATALOG_FILE = Path(__file__).resolve().parent / "final_doron_catalog.json"
FALLBACK_JSON = BASE_DIR / "assets" / "jsons" / "fallback_products.json"
OFFICIAL_CDN_FILE = BASE_DIR / "scripts" / "affiliate" / "doron_products.json"

def check_image_url(url: str, timeout: int = 4) -> bool:
    if not url or not url.startswith("http"):
        return False
    try:
        headers = {
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        }
        resp = requests.head(url, headers=headers, timeout=timeout, allow_redirects=True)
        if resp.status_code == 200:
            return True
        # Fallback get if head is blocked
        if resp.status_code in [403, 405]:
            resp = requests.get(url, headers=headers, timeout=timeout, stream=True)
            return resp.status_code == 200
        return False
    except Exception:
        return False

def audit_and_clean_catalog():
    if not CATALOG_FILE.exists():
        print(f"❌ Fichier catalogue introuvable : {CATALOG_FILE}")
        return []
        
    with open(CATALOG_FILE, "r", encoding="utf-8") as f:
        products = json.load(f)
        
    print(f"🔍 Début de l'audit de {len(products)} produits...")
    
    # Intégrer également les produits officiels existants si disponibles
    if OFFICIAL_CDN_FILE.exists():
        try:
            with open(OFFICIAL_CDN_FILE, "r", encoding="utf-8") as f:
                official_items = json.load(f)
            print(f"📦 Intégration de {len(official_items)} produits officiels certifiés...")
            seen_titles = {p["name"].lower().strip() for p in products}
            for it in official_items:
                name = (it.get("name") or it.get("product_title") or "").strip()
                if name and name.lower() not in seen_titles:
                    seen_titles.add(name.lower())
                    products.append(it)
        except Exception as e:
            print(f"Note: {e}")
            
    print(f"⚡ Test HTTP 200 sur {len(products)} images (30 workers)...")
    valid_products = []
    broken_count = 0
    
    def verify_single(p):
        img = p.get("image") or p.get("product_photo") or ""
        ok = check_image_url(img)
        return (p, ok)
        
    with ThreadPoolExecutor(max_workers=30) as executor:
        futures = [executor.submit(verify_single, p) for p in products]
        done_cnt = 0
        for fut in as_completed(futures):
            p, ok = fut.result()
            done_cnt += 1
            if ok:
                valid_products.append(p)
            else:
                broken_count += 1
            if done_cnt % 500 == 0:
                print(f"  Audit en cours : {done_cnt}/{len(products)} images vérifiées...")
                
    print("=" * 60)
    print(f"✅ RÉSULTATS DE L'AUDIT QUALITÉ :")
    print(f"  - Total testés   : {len(products)}")
    print(f"  - Images valides : {len(valid_products)} (100% HTTP 200)")
    print(f"  - Rejetés (morts): {broken_count}")
    print("=" * 60)
    
    # Recalcul de popularité, genre et tendance uniforme
    for p in valid_products:
        name = p.get("name") or p.get("product_title") or ""
        brand = p.get("brand") or "DORÕN Prestige"
        cat = p.get("category") or "cat_tech"
        subcat = p.get("subcategory") or "subcat_gadgets_divers"
        price = clean_price(p.get("price") or p.get("product_price"))
        is_act = p.get("is_activity", False)
        gender = determine_gender(name, cat, subcat, brand)
        
        p["category"] = cat
        p["subcategory"] = subcat
        p["gender"] = gender
        p["popularity"] = determine_popularity_score(name, brand, cat, subcat, price, is_act)
        
        # Tags de genre stricts
        raw_tags = [t for t in p.get("tags", []) if not str(t).startswith("gender_")]
        raw_tags.append(gender)
        p["tags"] = list(set(raw_tags))
        
        raw_cats = [c for c in p.get("categories", []) if not str(c).startswith("gender_")]
        raw_cats.append(gender)
        p["categories"] = list(set(raw_cats))

    # Sauvegarde des produits 100% validés
    with open(CATALOG_FILE, "w", encoding="utf-8") as f:
        json.dump(valid_products, f, indent=2, ensure_ascii=False)
        
    with open(FALLBACK_JSON, "w", encoding="utf-8") as f:
        json.dump(valid_products, f, indent=2, ensure_ascii=False)
        
    print(f"💾 Fichiers mis à jour :\n  - {CATALOG_FILE}\n  - {FALLBACK_JSON}")
    return valid_products

if __name__ == "__main__":
    audit_and_clean_catalog()
