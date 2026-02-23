#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de Scraping SIMPLIFIÉ pour Replit (SANS Selenium)
Version ultra-rapide et légère
"""

import csv
import time
import random
import re
from datetime import datetime
from urllib.parse import urlparse
import requests
from bs4 import BeautifulSoup
import firebase_admin
from firebase_admin import credentials, firestore

# ============================================
# CONFIGURATION
# ============================================

FIREBASE_PROJECT_ID = "doron-b3011"
CSV_FILE = "links.csv"
LOG_FILE = "scraping_log.txt"

# Headers HTTP réalistes pour éviter les blocages
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7',
    'Accept-Encoding': 'gzip, deflate, br',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
    'Cache-Control': 'max-age=0',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'none',
}

# ============================================
# INITIALISATION FIREBASE
# ============================================

def init_firebase():
    """Initialise Firebase Admin SDK"""
    try:
        cred = credentials.Certificate('serviceAccountKey.json')
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        print("✅ Firebase initialisé avec succès!")
        return db
    except Exception as e:
        print(f"❌ Erreur initialisation Firebase: {e}")
        print("\n⚠️ IMPORTANT: Assurez-vous que serviceAccountKey.json est présent!")
        return None

# ============================================
# EXTRACTION DE DONNÉES
# ============================================

def extract_brand_from_url(url):
    """Extrait la marque depuis l'URL"""
    domain = urlparse(url).netloc.lower()

    if 'goldengoose' in domain:
        return 'Golden Goose'
    elif 'zara' in domain:
        return 'Zara'
    elif 'maje' in domain:
        return 'Maje'
    elif 'miumiu' in domain:
        return 'Miu Miu'
    elif 'rhode' in domain:
        return 'Rhode'
    elif 'sephora' in domain:
        return 'Sephora'
    elif 'lululemon' in domain:
        return 'Lululemon'
    else:
        return 'Unknown'

def fetch_page(url):
    """Récupère une page web avec requests"""
    try:
        response = requests.get(url, headers=HEADERS, timeout=15, allow_redirects=True)
        response.raise_for_status()
        return response.text
    except Exception as e:
        print(f"    ❌ Erreur fetch: {e}")
        return None

def extract_product_data(html, url):
    """Extrait les données du produit depuis le HTML"""
    try:
        soup = BeautifulSoup(html, 'html.parser')

        # ========== EXTRACTION DU NOM ==========
        name = None

        # 1. Meta tags Open Graph
        og_title = soup.find('meta', {'property': 'og:title'})
        if og_title:
            name = og_title.get('content', '').strip()

        # 2. Twitter meta
        if not name:
            twitter_title = soup.find('meta', {'name': 'twitter:title'})
            if twitter_title:
                name = twitter_title.get('content', '').strip()

        # 3. Balise title
        if not name:
            title_tag = soup.find('title')
            if title_tag:
                name = title_tag.get_text(strip=True)

        # 4. H1
        if not name:
            h1 = soup.find('h1')
            if h1:
                name = h1.get_text(strip=True)

        # Nettoyer le nom
        if name:
            name = re.sub(r'\s*[|\-].*$', '', name)  # Enlever "| Site Name" ou "- Site Name"
            name = name[:200]  # Limiter longueur

        # ========== EXTRACTION DU PRIX ==========
        price = None

        # 1. Meta Open Graph price
        og_price = soup.find('meta', {'property': 'og:price:amount'})
        if og_price:
            try:
                price = float(og_price.get('content', '0').replace(',', '.'))
            except:
                pass

        # 2. Meta product:price
        if not price:
            product_price = soup.find('meta', {'property': 'product:price:amount'})
            if product_price:
                try:
                    price = float(product_price.get('content', '0').replace(',', '.'))
                except:
                    pass

        # 3. Chercher dans le texte avec regex
        if not price:
            # Patterns de prix : €29.99, 29,99€, $29.99, etc.
            price_patterns = [
                r'€\s*(\d+[.,]\d{2})',
                r'(\d+[.,]\d{2})\s*€',
                r'\$\s*(\d+[.,]\d{2})',
                r'"price"\s*:\s*"?(\d+\.?\d*)"?',
            ]

            html_text = html[:10000]  # Chercher dans les 10000 premiers caractères
            for pattern in price_patterns:
                match = re.search(pattern, html_text)
                if match:
                    try:
                        price = float(match.group(1).replace(',', '.'))
                        break
                    except:
                        continue

        # ========== EXTRACTION DE L'IMAGE ==========
        image_url = None

        # 1. Meta Open Graph
        og_image = soup.find('meta', {'property': 'og:image'})
        if og_image:
            image_url = og_image.get('content', '')

        # 2. Meta Twitter
        if not image_url:
            twitter_image = soup.find('meta', {'name': 'twitter:image'})
            if twitter_image:
                image_url = twitter_image.get('content', '')

        # 3. Première image avec "product" dans la classe
        if not image_url:
            product_img = soup.find('img', {'class': re.compile(r'product', re.I)})
            if product_img:
                image_url = product_img.get('src') or product_img.get('data-src')

        # Nettoyer l'URL de l'image
        if image_url:
            if image_url.startswith('//'):
                image_url = 'https:' + image_url
            elif image_url.startswith('/'):
                parsed = urlparse(url)
                image_url = f"{parsed.scheme}://{parsed.netloc}{image_url}"

        # ========== EXTRACTION DE LA DESCRIPTION ==========
        description = None

        # 1. Meta description
        meta_desc = soup.find('meta', {'name': 'description'})
        if meta_desc:
            description = meta_desc.get('content', '').strip()

        # 2. Meta og:description
        if not description:
            og_desc = soup.find('meta', {'property': 'og:description'})
            if og_desc:
                description = og_desc.get('content', '').strip()

        if description and len(description) > 500:
            description = description[:500]

        return {
            'name': name,
            'price': price,
            'image': image_url,
            'description': description
        }

    except Exception as e:
        print(f"    ❌ Erreur extraction: {e}")
        return None

# ============================================
# GÉNÉRATION DE TAGS
# ============================================

def generate_tags(product_data, brand):
    """Génère automatiquement les tags basés sur les données du produit"""
    tags = []
    name = (product_data.get('name') or '').lower()
    description = (product_data.get('description') or '').lower()
    price = product_data.get('price') or 0

    full_text = f"{name} {description}"

    # GENRE
    if any(word in full_text for word in ['femme', 'woman', 'women', 'her', 'elle', 'féminin']):
        tags.append('femme')
    if any(word in full_text for word in ['homme', 'man', 'men', 'his', 'lui', 'masculin']):
        tags.append('homme')
    if any(word in full_text for word in ['unisex', 'mixte', 'all']):
        tags.extend(['femme', 'homme'])

    # Par défaut si pas de genre détecté
    if 'femme' not in tags and 'homme' not in tags:
        tags.append('unisexe')

    # ÂGE
    if any(word in full_text for word in ['enfant', 'kid', 'child', 'junior', 'bébé', 'baby']):
        tags.append('enfant')
    else:
        tags.append('adulte')

    # BUDGET
    if price < 50:
        tags.append('budget_petit')
    elif price < 150:
        tags.append('budget_moyen')
    elif price < 400:
        tags.append('budget_luxe')
    else:
        tags.append('budget_premium')

    # STYLE
    if any(word in full_text for word in ['sport', 'athletic', 'running', 'yoga', 'fitness', 'gym']):
        tags.append('sportif')
    if any(word in full_text for word in ['casual', 'décontracté', 'relaxed', 'everyday']):
        tags.append('casual')
    if any(word in full_text for word in ['elegant', 'élégant', 'chic', 'formal', 'luxe', 'luxury']):
        tags.append('elegant')
    if any(word in full_text for word in ['vintage', 'retro', 'classic', 'classique']):
        tags.append('vintage')
    if any(word in full_text for word in ['modern', 'moderne', 'contemporary', 'trend']):
        tags.append('moderne')

    # OCCASIONS
    if any(word in full_text for word in ['travail', 'work', 'office', 'business', 'professional']):
        tags.append('travail')
    if any(word in full_text for word in ['soirée', 'party', 'evening', 'cocktail', 'gala']):
        tags.append('soiree')
    if any(word in full_text for word in ['quotidien', 'daily', 'everyday', 'casual']):
        tags.append('quotidien')

    # MARQUE SPÉCIFIQUE
    if brand == 'Golden Goose':
        tags.extend(['luxe', 'italien', 'sneakers'])
    elif brand == 'Zara':
        tags.extend(['tendance', 'accessible'])
    elif brand == 'Sephora' or brand == 'Rhode':
        tags.extend(['beaute', 'skincare'])
    elif brand == 'Lululemon':
        tags.extend(['sportif', 'yoga', 'qualite'])
    elif brand == 'Miu Miu':
        tags.extend(['luxe', 'haute_couture', 'italien'])

    return list(set(tags))  # Éliminer les doublons

def generate_categories(product_data, brand):
    """Génère les catégories du produit"""
    categories = []
    name = (product_data.get('name') or '').lower()
    description = (product_data.get('description') or '').lower()

    full_text = f"{name} {description}"

    # CATÉGORIES PRINCIPALES
    if any(word in full_text for word in ['sneakers', 'chaussures', 'shoes', 'boots', 'sandales']):
        categories.append('chaussures')
    if any(word in full_text for word in ['sac', 'bag', 'purse', 'handbag', 'tote']):
        categories.append('accessoires')
    if any(word in full_text for word in ['pull', 'sweater', 'sweat', 'hoodie', 'cardigan', 'top', 'shirt', 'chemise']):
        categories.append('vetements')
    if any(word in full_text for word in ['parfum', 'fragrance', 'perfume', 'eau de toilette']):
        categories.append('parfums')
    if any(word in full_text for word in ['maquillage', 'makeup', 'lipstick', 'mascara', 'foundation']):
        categories.append('maquillage')
    if any(word in full_text for word in ['skincare', 'soin', 'cream', 'serum', 'moisturizer']):
        categories.append('beaute')
    if any(word in full_text for word in ['sport', 'yoga', 'legging', 'brassiere', 'athletic']):
        categories.append('sport')

    # Catégories basées sur la marque
    if brand in ['Sephora', 'Rhode']:
        if 'beaute' not in categories and 'maquillage' not in categories:
            categories.append('beaute')
    elif brand == 'Lululemon':
        if 'sport' not in categories:
            categories.append('sport')
    elif brand in ['Golden Goose', 'Zara', 'Maje', 'Miu Miu']:
        if 'mode' not in categories:
            categories.append('mode')

    return categories if categories else ['mode']

# ============================================
# UPLOAD FIREBASE
# ============================================

def upload_to_firebase(db, product):
    """Upload un produit dans Firebase Firestore"""
    try:
        doc_ref = db.collection('gifts').document()
        doc_ref.set(product)
        print(f"    ✅ Uploadé dans Firebase (ID: {doc_ref.id})")
        return True
    except Exception as e:
        print(f"    ❌ Erreur upload Firebase: {e}")
        return False

# ============================================
# FONCTION PRINCIPALE
# ============================================

def scrape_and_upload():
    """Fonction principale de scraping et upload"""

    print("=" * 60)
    print("🕷️  SCRAPING SIMPLIFIÉ DES PRODUITS DORÕN")
    print("=" * 60)
    print()

    # Initialiser Firebase
    db = init_firebase()
    if not db:
        print("❌ Impossible de continuer sans Firebase!")
        return

    # Lire les URLs depuis le CSV
    try:
        with open(CSV_FILE, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            urls = [row[0] for row in reader if row and row[0].startswith('http')]
    except Exception as e:
        print(f"❌ Erreur lecture CSV: {e}")
        return

    print(f"📋 {len(urls)} URLs à scraper\n")

    # Ouvrir le fichier de log
    with open(LOG_FILE, 'a', encoding='utf-8') as log:
        log.write(f"\n\n{'='*60}\n")
        log.write(f"SCRAPING DÉMARRÉ: {datetime.now()}\n")
        log.write(f"{'='*60}\n\n")

        success_count = 0
        fail_count = 0

        # Scraper chaque URL
        for index, url in enumerate(urls, 1):
            print(f"\n[{index}/{len(urls)}] 🔍 Scraping: {url[:80]}...")
            log.write(f"\n[{index}/{len(urls)}] URL: {url}\n")

            # Extraire la marque
            brand = extract_brand_from_url(url)
            print(f"    🏷️  Marque: {brand}")

            # Délai anti-blocage
            if index > 1:
                delay = random.uniform(2, 5)
                print(f"    ⏳ Pause {delay:.1f}s...")
                time.sleep(delay)

            # Fetch la page
            html = fetch_page(url)
            if not html:
                print(f"    ❌ Impossible de charger la page")
                log.write(f"    ❌ ÉCHEC: Impossible de charger la page\n")
                fail_count += 1
                continue

            print(f"    ✅ HTML récupéré ({len(html) // 1024}KB)")

            # Extraire les données
            product_data = extract_product_data(html, url)

            if not product_data or not product_data.get('name'):
                print(f"    ❌ Nom du produit non trouvé")
                log.write(f"    ❌ ÉCHEC: Nom non trouvé\n")
                fail_count += 1
                continue

            print(f"    ✅ {product_data['name'][:60]}...")

            if product_data.get('price'):
                print(f"    💰 Prix: {product_data['price']}€")
            else:
                print(f"    ⚠️  Prix non trouvé (défaut: 0)")

            if product_data.get('image'):
                print(f"    🖼️  Image: OK")
            else:
                print(f"    ⚠️  Image non trouvée")

            # Générer tags et catégories
            tags = generate_tags(product_data, brand)
            categories = generate_categories(product_data, brand)

            print(f"    🏷️  Tags: {', '.join(tags[:5])}...")
            print(f"    📂 Catégories: {', '.join(categories)}")

            # Créer l'objet produit complet
            product = {
                'name': product_data['name'],
                'brand': brand,
                'price': product_data.get('price') or 0,
                'url': url,
                'image': product_data.get('image') or '',
                'description': product_data.get('description') or f"Produit {brand}",
                'categories': categories,
                'tags': tags,
                'active': True,
                'source': 'real_scraping',
                'created_at': firestore.SERVER_TIMESTAMP,
                'popularity': 0,
                # Champs compatibles avec ancien schema
                'product_photo': product_data.get('image') or '',
                'product_title': product_data['name'],
                'product_url': url,
                'product_price': str(product_data.get('price') or 0),
            }

            # Logger les données
            log.write(f"    ✅ Nom: {product['name']}\n")
            log.write(f"    💰 Prix: {product['price']}€\n")
            log.write(f"    🖼️ Image: {product['image'][:80] if product['image'] else 'N/A'}...\n")
            log.write(f"    🏷️ Tags: {', '.join(tags)}\n")
            log.write(f"    📂 Catégories: {', '.join(categories)}\n")

            # Upload dans Firebase
            if upload_to_firebase(db, product):
                success_count += 1
                log.write(f"    ✅ UPLOADÉ DANS FIREBASE\n")
            else:
                fail_count += 1
                log.write(f"    ❌ ÉCHEC UPLOAD FIREBASE\n")

        # Résumé final
        print("\n")
        print("=" * 60)
        print("📊 RÉSULTATS FINAUX:")
        print(f"   ✅ {success_count} produits scrapés et uploadés avec succès")
        print(f"   ❌ {fail_count} échecs")
        print("=" * 60)

        log.write(f"\n\n{'='*60}\n")
        log.write(f"RÉSUMÉ:\n")
        log.write(f"   ✅ Succès: {success_count}\n")
        log.write(f"   ❌ Échecs: {fail_count}\n")
        log.write(f"{'='*60}\n")

    print("\n🎉 SCRAPING TERMINÉ!")
    print(f"📝 Logs sauvegardés dans: {LOG_FILE}")

# ============================================
# POINT D'ENTRÉE
# ============================================

if __name__ == "__main__":
    scrape_and_upload()
