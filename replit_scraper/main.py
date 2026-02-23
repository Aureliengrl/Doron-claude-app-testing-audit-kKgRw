#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de Scraping RÉEL des Produits pour DORÕN
À exécuter sur Replit.com
"""

import csv
import time
import random
import re
from datetime import datetime
from urllib.parse import urlparse
import firebase_admin
from firebase_admin import credentials, firestore
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from bs4 import BeautifulSoup

# ============================================
# CONFIGURATION
# ============================================

FIREBASE_PROJECT_ID = "doron-b3011"
CSV_FILE = "links.csv"
LOG_FILE = "scraping_log.txt"

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
# INITIALISATION SELENIUM
# ============================================

def init_selenium():
    """Initialise Selenium avec Chrome headless"""
    try:
        chrome_options = Options()
        chrome_options.add_argument("--headless")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--disable-blink-features=AutomationControlled")
        chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

        driver = webdriver.Chrome(options=chrome_options)
        print("✅ Selenium initialisé avec succès!")
        return driver
    except Exception as e:
        print(f"❌ Erreur initialisation Selenium: {e}")
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

def extract_product_data(driver, url):
    """Extrait les données du produit depuis la page web"""
    try:
        # Charger la page
        driver.get(url)
        time.sleep(random.uniform(2, 4))  # Délai anti-blocage

        # Parser le HTML
        soup = BeautifulSoup(driver.page_source, 'html.parser')

        # ========== EXTRACTION DU NOM ==========
        name = None
        name_selectors = [
            ('h1', {'class': re.compile(r'product.*title|title.*product', re.I)}),
            ('h1', {'data-testid': 'product-title'}),
            ('h1', {}),
            ('span', {'class': re.compile(r'product.*name|name.*product', re.I)}),
            ('div', {'class': re.compile(r'product.*title', re.I)}),
        ]

        for tag, attrs in name_selectors:
            element = soup.find(tag, attrs)
            if element and element.get_text(strip=True):
                name = element.get_text(strip=True)
                break

        if not name:
            # Fallback: chercher dans meta tags
            meta_title = soup.find('meta', {'property': 'og:title'})
            if meta_title:
                name = meta_title.get('content', '').strip()

        # ========== EXTRACTION DU PRIX ==========
        price = None
        price_selectors = [
            ('span', {'class': re.compile(r'price|prix', re.I)}),
            ('div', {'class': re.compile(r'price|prix', re.I)}),
            ('p', {'class': re.compile(r'price|prix', re.I)}),
            ('span', {'data-testid': 'price'}),
        ]

        for tag, attrs in price_selectors:
            elements = soup.find_all(tag, attrs)
            for element in elements:
                text = element.get_text(strip=True)
                # Chercher un pattern de prix (ex: 29.99, 29,99, €29.99, $29.99)
                price_match = re.search(r'(\d+[.,]\d{2}|\d+)', text)
                if price_match:
                    price_str = price_match.group(1).replace(',', '.')
                    try:
                        price = float(price_str)
                        break
                    except:
                        continue
            if price:
                break

        # ========== EXTRACTION DE L'IMAGE ==========
        image_url = None

        # Méthode 1: Chercher dans meta tags Open Graph
        og_image = soup.find('meta', {'property': 'og:image'})
        if og_image:
            image_url = og_image.get('content', '')

        # Méthode 2: Chercher les images principales du produit
        if not image_url:
            image_selectors = [
                ('img', {'class': re.compile(r'product.*image|main.*image|hero.*image', re.I)}),
                ('img', {'data-testid': 'product-image'}),
                ('img', {'itemprop': 'image'}),
            ]

            for tag, attrs in image_selectors:
                img = soup.find(tag, attrs)
                if img:
                    image_url = img.get('src') or img.get('data-src') or img.get('data-original')
                    if image_url:
                        break

        # Nettoyer l'URL de l'image
        if image_url:
            if image_url.startswith('//'):
                image_url = 'https:' + image_url
            elif image_url.startswith('/'):
                parsed = urlparse(url)
                image_url = f"{parsed.scheme}://{parsed.netloc}{image_url}"

        # ========== EXTRACTION DE LA DESCRIPTION ==========
        description = None
        desc_selectors = [
            ('div', {'class': re.compile(r'description|product.*desc', re.I)}),
            ('p', {'class': re.compile(r'description', re.I)}),
            ('meta', {'name': 'description'}),
            ('meta', {'property': 'og:description'}),
        ]

        for tag, attrs in desc_selectors:
            element = soup.find(tag, attrs)
            if element:
                if tag == 'meta':
                    description = element.get('content', '').strip()
                else:
                    description = element.get_text(strip=True)

                if description and len(description) > 20:
                    description = description[:500]  # Limiter à 500 caractères
                    break

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
    print("🕷️  SCRAPING RÉEL DES PRODUITS DORÕN")
    print("=" * 60)
    print()

    # Initialiser Firebase
    db = init_firebase()
    if not db:
        print("❌ Impossible de continuer sans Firebase!")
        return

    # Initialiser Selenium
    driver = init_selenium()
    if not driver:
        print("❌ Impossible de continuer sans Selenium!")
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
            print(f"\n[{index}/{len(urls)}] 🔍 Scraping: {url}")
            log.write(f"\n[{index}/{len(urls)}] URL: {url}\n")

            # Extraire la marque
            brand = extract_brand_from_url(url)
            print(f"    🏷️  Marque: {brand}")

            # Scraper les données
            product_data = extract_product_data(driver, url)

            if not product_data:
                print(f"    ❌ Échec extraction")
                log.write(f"    ❌ ÉCHEC: Impossible d'extraire les données\n")
                fail_count += 1
                continue

            # Vérifier que les données essentielles sont présentes
            if not product_data.get('name'):
                print(f"    ⚠️  Nom manquant - SKIP")
                log.write(f"    ❌ ÉCHEC: Nom manquant\n")
                fail_count += 1
                continue

            print(f"    ✅ {product_data['name']}")

            if product_data.get('price'):
                print(f"    💰 Prix: {product_data['price']}€")
            else:
                print(f"    ⚠️  Prix non trouvé")

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
            log.write(f"    🖼️ Image: {product['image'][:80]}...\n")
            log.write(f"    🏷️ Tags: {', '.join(tags)}\n")
            log.write(f"    📂 Catégories: {', '.join(categories)}\n")

            # Upload dans Firebase
            if upload_to_firebase(db, product):
                success_count += 1
                log.write(f"    ✅ UPLOADÉ DANS FIREBASE\n")
            else:
                fail_count += 1
                log.write(f"    ❌ ÉCHEC UPLOAD FIREBASE\n")

            # Délai anti-blocage aléatoire
            delay = random.uniform(2, 5)
            print(f"    ⏳ Pause {delay:.1f}s...")
            time.sleep(delay)

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

    # Fermer le navigateur
    driver.quit()
    print("\n🎉 SCRAPING TERMINÉ!")
    print(f"📝 Logs sauvegardés dans: {LOG_FILE}")

# ============================================
# POINT D'ENTRÉE
# ============================================

if __name__ == "__main__":
    scrape_and_upload()
