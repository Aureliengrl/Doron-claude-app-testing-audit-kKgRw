#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🎁 DORON Advanced Scraper & Cleaner
Script ultra-robuste avec anti-détection et nettoyage automatique
À exécuter sur Replit.com
"""

import asyncio
import json
import re
import csv
from datetime import datetime
from typing import Dict, List, Optional
from urllib.parse import urlparse
import os
import time
import random

# Imports pour le scraping avancé avec anti-détection
try:
    from playwright.async_api import async_playwright, Browser, Page, TimeoutError as PlaywrightTimeout
    PLAYWRIGHT_AVAILABLE = True
except ImportError:
    PLAYWRIGHT_AVAILABLE = False
    print("⚠️  Playwright non installé. Installez avec: pip install playwright && playwright install chromium")

# Firebase
import firebase_admin
from firebase_admin import credentials, firestore

# ============================================
# CONFIGURATION
# ============================================

# Firebase
FIREBASE_PROJECT_ID = "doron-b3011"
FIREBASE_COLLECTIONS = ['gifts', 'products']

# Scraping
CSV_FILE = "links.csv"
MAX_CONCURRENT_SCRAPERS = 3
MIN_DELAY_SECONDS = 3.0
MAX_DELAY_SECONDS = 8.0
TIMEOUT_MS = 45000
MAX_RETRIES = 3

# User Agents rotatifs pour éviter la détection
USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:122.0) Gecko/20100101 Firefox/122.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
]

# ============================================
# FIREBASE MANAGER
# ============================================

class FirebaseManager:
    """Gère toutes les interactions avec Firebase"""

    def __init__(self):
        """Initialise la connexion Firebase"""
        try:
            # Vérifier si déjà initialisé
            firebase_admin.get_app()
            self.db = firestore.client()
            print("✅ Firebase déjà initialisé")
        except ValueError:
            # Pas encore initialisé
            try:
                cred = credentials.Certificate('serviceAccountKey.json')
                firebase_admin.initialize_app(cred)
                self.db = firestore.client()
                print("✅ Firebase initialisé avec succès")
            except Exception as e:
                print(f"❌ Erreur initialisation Firebase: {e}")
                raise

    def get_all_products(self, collection_name: str = 'gifts') -> List[Dict]:
        """Récupère tous les produits d'une collection"""
        print(f"\n📦 Récupération des produits depuis '{collection_name}'...")
        products = []

        try:
            docs = self.db.collection(collection_name).stream()

            for doc in docs:
                data = doc.to_dict()
                data['_id'] = doc.id
                data['_collection'] = collection_name
                products.append(data)

            print(f"✅ {len(products)} produits récupérés")
            return products
        except Exception as e:
            print(f"❌ Erreur récupération: {e}")
            return []

    def delete_product(self, product_id: str, collection_name: str = 'gifts') -> bool:
        """Supprime un produit de Firebase"""
        try:
            self.db.collection(collection_name).document(product_id).delete()
            return True
        except Exception as e:
            print(f"❌ Erreur suppression {product_id}: {e}")
            return False

    def add_product(self, data: Dict, collection_name: str = 'gifts') -> Optional[str]:
        """Ajoute un nouveau produit à Firebase"""
        try:
            # Vérifier les champs requis
            required = ['name', 'brand', 'price', 'image', 'url']
            for field in required:
                if not data.get(field):
                    print(f"⚠️  Champ '{field}' manquant, produit ignoré")
                    return None

            # Ajouter métadonnées
            data['scrapedAt'] = datetime.now().isoformat()
            data['lastUpdated'] = datetime.now().isoformat()

            # Vérifier si le produit existe déjà (par URL)
            existing = self.db.collection(collection_name).where('url', '==', data['url']).limit(1).get()
            if existing:
                print(f"ℹ️  Produit déjà existant: {data['name'][:50]}")
                return None

            # Ajouter à Firebase
            doc_ref = self.db.collection(collection_name).add(data)
            product_id = doc_ref[1].id
            print(f"✅ Produit ajouté: {data['name'][:50]} (ID: {product_id})")
            return product_id

        except Exception as e:
            print(f"❌ Erreur ajout produit: {e}")
            return None

# ============================================
# PRODUCT CLEANER
# ============================================

class ProductCleaner:
    """Nettoie la base Firebase en supprimant les produits incomplets"""

    def __init__(self, firebase_manager: FirebaseManager):
        self.firebase = firebase_manager
        self.stats = {
            'total': 0,
            'deleted': 0,
            'valid': 0,
            'missing_fields': {},
        }

    def is_product_complete(self, product: Dict) -> tuple[bool, List[str]]:
        """Vérifie si un produit est complet"""
        required_fields = {
            'name': 'Nom',
            'brand': 'Marque',
            'price': 'Prix',
            'image': 'Image',
            'url': 'URL',
        }

        missing = []

        for field, label in required_fields.items():
            value = product.get(field)

            if not value:
                missing.append(label)
                continue

            # Validation par type
            if field == 'price':
                if not isinstance(value, (int, float)) or value <= 0:
                    missing.append(f"{label} invalide")

            elif field in ['image', 'url']:
                if not isinstance(value, str) or len(value) < 10 or not value.startswith('http'):
                    missing.append(f"{label} invalide")

            elif field in ['name', 'brand']:
                if not isinstance(value, str) or len(value) < 2:
                    missing.append(f"{label} trop courte")

        return len(missing) == 0, missing

    def clean_collection(self, collection_name: str = 'gifts') -> Dict:
        """Nettoie une collection"""
        print(f"\n{'='*70}")
        print(f"🧹 NETTOYAGE: {collection_name}")
        print(f"{'='*70}\n")

        products = self.firebase.get_all_products(collection_name)
        self.stats = {'total': len(products), 'deleted': 0, 'valid': 0, 'missing_fields': {}}

        deleted_count = 0

        for product in products:
            product_id = product.get('_id')
            product_name = product.get('name', 'Sans nom')

            is_complete, missing = self.is_product_complete(product)

            if is_complete:
                self.stats['valid'] += 1
            else:
                # Compter les champs manquants
                for field in missing:
                    self.stats['missing_fields'][field] = self.stats['missing_fields'].get(field, 0) + 1

                # Supprimer
                print(f"❌ Suppression: {product_name[:60]}")
                print(f"   ID: {product_id}")
                print(f"   Manquant: {', '.join(missing)}\n")

                if self.firebase.delete_product(product_id, collection_name):
                    self.stats['deleted'] += 1
                    deleted_count += 1

        # Résumé
        print(f"\n{'─'*70}")
        print(f"📊 Résumé: {collection_name}")
        print(f"{'─'*70}")
        print(f"Total: {self.stats['total']}")
        print(f"✅ Valides: {self.stats['valid']}")
        print(f"🗑️  Supprimés: {self.stats['deleted']}")

        if self.stats['missing_fields']:
            print(f"\n📋 Champs manquants fréquents:")
            sorted_fields = sorted(self.stats['missing_fields'].items(), key=lambda x: x[1], reverse=True)
            for field, count in sorted_fields[:5]:
                print(f"   • {field}: {count}x")

        return self.stats

# ============================================
# ADVANCED SCRAPER (Playwright + Anti-Bot)
# ============================================

class AdvancedScraper:
    """Scraper avancé avec anti-détection Playwright"""

    def __init__(self, firebase_manager: FirebaseManager):
        self.firebase = firebase_manager
        self.browser: Optional[Browser] = None
        self.stats = {
            'attempted': 0,
            'success': 0,
            'failed': 0,
            'duplicates': 0,
        }

    async def init_browser(self):
        """Initialise Playwright avec anti-détection maximale"""
        if not PLAYWRIGHT_AVAILABLE:
            raise Exception("Playwright non installé!")

        playwright = await async_playwright().start()

        # Lancer Chrome avec paramètres anti-détection
        self.browser = await playwright.chromium.launch(
            headless=True,
            args=[
                '--disable-blink-features=AutomationControlled',
                '--disable-dev-shm-usage',
                '--disable-accelerated-2d-canvas',
                '--no-sandbox',
                '--disable-setuid-sandbox',
                '--disable-gpu',
                '--window-size=1920,1080',
            ],
        )
        print("✅ Navigateur Playwright initialisé")

    async def close_browser(self):
        """Ferme le navigateur"""
        if self.browser:
            await self.browser.close()

    async def create_stealth_page(self) -> Page:
        """Crée une page avec anti-détection maximale"""
        # Créer un contexte avec headers réalistes
        context = await self.browser.new_context(
            user_agent=random.choice(USER_AGENTS),
            viewport={'width': 1920, 'height': 1080},
            locale='fr-FR',
            timezone_id='Europe/Paris',
            geolocation={'latitude': 48.8566, 'longitude': 2.3522},  # Paris
            permissions=['geolocation'],
        )

        page = await context.new_page()

        # Injecter JavaScript pour masquer l'automatisation
        await page.add_init_script("""
            // Supprimer webdriver
            Object.defineProperty(navigator, 'webdriver', {
                get: () => undefined
            });

            // Chrome object
            window.chrome = {
                runtime: {},
                loadTimes: function() {},
                csi: function() {},
                app: {}
            };

            // Plugins
            Object.defineProperty(navigator, 'plugins', {
                get: () => [1, 2, 3, 4, 5]
            });

            // Languages
            Object.defineProperty(navigator, 'languages', {
                get: () => ['fr-FR', 'fr', 'en-US', 'en']
            });

            // Permissions
            const originalQuery = window.navigator.permissions.query;
            window.navigator.permissions.query = (parameters) => (
                parameters.name === 'notifications' ?
                    Promise.resolve({ state: Notification.permission }) :
                    originalQuery(parameters)
            );
        """)

        return page

    async def scrape_amazon_product(self, url: str) -> Optional[Dict]:
        """Scrape un produit Amazon avec anti-détection"""
        print(f"\n🔍 Amazon: {url[:80]}...")

        page = None
        try:
            page = await self.create_stealth_page()

            # Aller sur la page
            await page.goto(url, wait_until='domcontentloaded', timeout=TIMEOUT_MS)

            # Délai aléatoire (comportement humain)
            await asyncio.sleep(random.uniform(MIN_DELAY_SECONDS, MAX_DELAY_SECONDS))

            # Extraire les données
            product_data = {}

            # NOM
            try:
                product_data['name'] = await page.locator('#productTitle').inner_text(timeout=5000)
                product_data['name'] = product_data['name'].strip()
            except:
                print("⚠️  Nom non trouvé")
                return None

            # MARQUE
            try:
                brand_selectors = ['#bylineInfo', 'a#brand', '.po-brand .po-break-word']
                for selector in brand_selectors:
                    try:
                        brand_text = await page.locator(selector).first.inner_text(timeout=2000)
                        brand_text = re.sub(r'^(Marque\s*:\s*|Visit\s+the\s+|Visiter\s+)', '', brand_text, flags=re.IGNORECASE)
                        brand_text = brand_text.strip()
                        if brand_text and len(brand_text) > 1:
                            product_data['brand'] = brand_text
                            break
                    except:
                        continue

                if 'brand' not in product_data:
                    # Fallback: premier mot du titre
                    product_data['brand'] = product_data['name'].split()[0] if product_data.get('name') else 'Amazon'
            except:
                product_data['brand'] = 'Amazon'

            # PRIX
            try:
                price_selectors = ['.a-price .a-offscreen', '#priceblock_ourprice', '.a-price-whole']
                for selector in price_selectors:
                    try:
                        price_text = await page.locator(selector).first.inner_text(timeout=2000)
                        price_match = re.search(r'(\d+(?:[.,]\d{1,2})?)', price_text.replace(' ', ''))
                        if price_match:
                            price_str = price_match.group(1).replace(',', '.')
                            product_data['price'] = float(price_str)
                            break
                    except:
                        continue

                if 'price' not in product_data:
                    print("⚠️  Prix non trouvé")
                    return None
            except:
                return None

            # IMAGE
            try:
                image_selectors = ['#landingImage', '#imgBlkFront', '.a-dynamic-image']
                for selector in image_selectors:
                    try:
                        img_elem = await page.locator(selector).first
                        image_url = await img_elem.get_attribute('src')
                        if not image_url:
                            image_url = await img_elem.get_attribute('data-old-hires')
                        if not image_url:
                            dynamic = await img_elem.get_attribute('data-a-dynamic-image')
                            if dynamic:
                                try:
                                    image_dict = json.loads(dynamic)
                                    image_url = list(image_dict.keys())[0]
                                except:
                                    pass

                        if image_url and image_url.startswith('http'):
                            product_data['image'] = image_url
                            break
                    except:
                        continue

                if 'image' not in product_data:
                    print("⚠️  Image non trouvée")
                    return None
            except:
                return None

            # URL propre (ASIN)
            asin_match = re.search(r'/dp/([A-Z0-9]{10})', url)
            if asin_match:
                product_data['url'] = f"https://www.amazon.fr/dp/{asin_match.group(1)}"
            else:
                product_data['url'] = url

            # Métadonnées
            product_data['source'] = 'Amazon'

            # Catégories
            try:
                categories = []
                breadcrumbs = await page.locator('#wayfinding-breadcrumbs_container a').all()
                for item in breadcrumbs[:3]:
                    cat_text = await item.inner_text()
                    categories.append(cat_text.strip())
                product_data['categories'] = categories if categories else []
            except:
                product_data['categories'] = []

            # Tags (auto-générés)
            product_data['tags'] = self.generate_tags(product_data)

            print(f"✅ Scrapé: {product_data['name'][:50]}")
            print(f"   Marque: {product_data['brand']}")
            print(f"   Prix: {product_data['price']}€")

            return product_data

        except Exception as e:
            print(f"❌ Erreur: {e}")
            return None
        finally:
            if page:
                await page.close()

    def generate_tags(self, product_data: Dict) -> List[str]:
        """Génère les tags automatiquement"""
        tags = []
        text = f"{product_data.get('name', '')} {product_data.get('brand', '')}".lower()
        price = product_data.get('price', 0)

        # Genre
        if any(w in text for w in ['femme', 'woman', 'women', 'her', 'elle']):
            tags.append('femme')
        if any(w in text for w in ['homme', 'man', 'men', 'his', 'lui']):
            tags.append('homme')

        # Budget
        if price < 50:
            tags.append('budget_petit')
        elif price < 150:
            tags.append('budget_moyen')
        else:
            tags.append('budget_luxe')

        # Style
        if any(w in text for w in ['sport', 'yoga', 'gym', 'running']):
            tags.append('sportif')
        if any(w in text for w in ['elegant', 'chic', 'luxe']):
            tags.append('elegant')

        return list(set(tags))

    async def scrape_csv(self, csv_file: str):
        """Scrape tous les produits d'un CSV"""
        print(f"\n{'='*70}")
        print(f"🎯 SCRAPING DES PRODUITS")
        print(f"{'='*70}\n")

        # Lire le CSV
        try:
            with open(csv_file, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                urls = [row for row in reader if row.get('url')]
        except Exception as e:
            print(f"❌ Erreur lecture CSV: {e}")
            return

        print(f"📋 {len(urls)} URLs à scraper\n")

        # Initialiser le navigateur
        await self.init_browser()

        try:
            for i, row in enumerate(urls, 1):
                url = row.get('url', '').strip()
                if not url:
                    continue

                print(f"\n{'─'*70}")
                print(f"Produit {i}/{len(urls)}")
                print(f"{'─'*70}")

                self.stats['attempted'] += 1

                # Scraper selon le domaine
                domain = urlparse(url).netloc.lower()
                product_data = None

                if 'amazon' in domain:
                    product_data = await self.scrape_amazon_product(url)
                else:
                    print(f"⚠️  Domaine non supporté: {domain}")
                    self.stats['failed'] += 1
                    continue

                # Ajouter à Firebase
                if product_data:
                    product_id = self.firebase.add_product(product_data, 'gifts')
                    if product_id:
                        self.stats['success'] += 1
                    else:
                        self.stats['duplicates'] += 1
                else:
                    self.stats['failed'] += 1

                # Délai entre requêtes
                if i < len(urls):
                    delay = random.uniform(MIN_DELAY_SECONDS, MAX_DELAY_SECONDS)
                    print(f"\n⏳ Pause {delay:.1f}s...")
                    await asyncio.sleep(delay)

        finally:
            await self.close_browser()

        # Stats
        print(f"\n{'='*70}")
        print(f"📊 STATISTIQUES")
        print(f"{'='*70}")
        print(f"Tentées: {self.stats['attempted']}")
        print(f"✅ Succès: {self.stats['success']}")
        print(f"❌ Échecs: {self.stats['failed']}")
        print(f"⏭️  Doublons: {self.stats['duplicates']}")

# ============================================
# MAIN
# ============================================

async def main():
    """Point d'entrée principal"""
    print("""
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║              🎁 DORON ADVANCED SCRAPER & CLEANER 🎁               ║
║                                                                   ║
║  Script ultra-robuste avec anti-détection Playwright             ║
║  + Nettoyage automatique de la base Firebase                     ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
    """)

    # Initialiser Firebase
    try:
        firebase = FirebaseManager()
    except Exception as e:
        print(f"❌ Erreur Firebase: {e}")
        return

    # Menu
    print("\n📋 Que voulez-vous faire?\n")
    print("1. 🧹 Nettoyer la base (supprimer produits incomplets)")
    print("2. 🔍 Scraper nouveaux produits (depuis links.csv)")
    print("3. 🎯 Les deux (nettoyer + scraper)")
    print()

    choice = input("Choix (1/2/3): ").strip()

    if choice in ['1', '3']:
        # Nettoyer
        for collection in FIREBASE_COLLECTIONS:
            try:
                cleaner = ProductCleaner(firebase)
                cleaner.clean_collection(collection)
            except Exception as e:
                print(f"⚠️  Erreur nettoyage {collection}: {e}")

    if choice in ['2', '3']:
        # Scraper
        if not PLAYWRIGHT_AVAILABLE:
            print("\n❌ Playwright non installé!")
            print("Installez avec: pip install playwright && playwright install chromium")
            return

        if not os.path.exists(CSV_FILE):
            print(f"\n❌ Fichier {CSV_FILE} non trouvé!")
            return

        scraper = AdvancedScraper(firebase)
        await scraper.scrape_csv(CSV_FILE)

    print("\n✅ Terminé!")

if __name__ == "__main__":
    asyncio.run(main())
