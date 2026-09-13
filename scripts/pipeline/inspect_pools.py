import json
import subprocess
import re

# 1. Load official subcategories mapping from tags_definitions.dart
with open("lib/services/tags_definitions.dart", "r", encoding="utf-8") as f:
    text = f.read()

subcat_map = {}
current_cat = None
for line in text.splitlines():
    if "'cat_" in line and ": [" in line:
        current_cat = line.split("'")[1]
        subcat_map[current_cat] = []
    elif current_cat and "'subcat_" in line:
        sub = line.split("'")[1]
        subcat_map[current_cat].append(sub)

# 2. Load original 496 products from git commit ac90443
out_ac = subprocess.check_output(["git", "show", "ac90443:assets/jsons/fallback_products.json"]).decode("utf-8")
ac_products = json.loads(out_ac)

# 3. Load doron_products (1545 items)
with open("scripts/affiliate/doron_products.json", "r", encoding="utf-8") as f:
    doron_products = json.load(f)

# 4. Load websearch_real_products (379 items)
with open("scripts/affiliate/websearch_real_products.json", "r", encoding="utf-8") as f:
    web_products = json.load(f)

print(f"Loaded: ac={len(ac_products)}, doron={len(doron_products)}, web={len(web_products)}")

# Combine all official products
all_raw = ac_products + doron_products + web_products

# Filter out Unsplash or placeholder images
official_pool = []
seen_names = set()

for p in all_raw:
    img = p.get("image") or p.get("product_photo") or p.get("imageUrl") or ""
    if not img or not img.startswith("http"):
        continue
    if "unsplash.com" in img or "placeholder" in img:
        continue
    
    name = (p.get("name") or p.get("title") or p.get("product_title") or "").strip()
    if not name or name in seen_names:
        continue
    seen_names.add(name)
    
    brand = p.get("brand") or "DORÕN Selection"
    price = p.get("price") or 50.0
    if isinstance(price, str):
        try:
            price = float(re.sub(r"[^\d.]", "", price.replace(",", ".")))
        except:
            price = 50.0
    
    url = p.get("url") or p.get("buyUrl") or p.get("product_url") or "https://www.amazon.fr"
    desc = p.get("description") or f"Produit officiel de haute qualité par {brand}."
    
    official_pool.append({
        "id": p.get("id") or f"prod_{len(official_pool)+1}",
        "name": name,
        "brand": brand,
        "price": float(price),
        "url": url,
        "image": img,
        "description": desc,
        "categories": p.get("categories") or [],
        "tags": p.get("tags") or [],
        "keywords": p.get("keywords") or [],
        "popularity": p.get("popularity") or 90,
        "active": True,
        "source": "official_catalog"
    })

print(f"Total unique official products from pools: {len(official_pool)}")
