#!/usr/bin/env python3
"""
Script intelligent pour nettoyer et compléter la base Firebase
Analyse chaque produit, détecte les champs manquants, scrape les URLs et met à jour Firebase
"""

import firebase_admin
from firebase_admin import credentials, firestore
import requests
from bs4 import BeautifulSoup
import re
import time
import json
from urllib.parse import urlparse
from typing import Dict, List, Optional

# Configuration
FIREBASE_CREDENTIALS = "firebase-credentials.json"
COLLECTION_NAME = "gifts"

# User agents pour éviter les blocages
USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
]

class IntelligentProductCleaner:
    def __init__(self):
        # Initialiser Firebase
        try:
            cred = credentials.Certificate(FIREBASE_CREDENTIALS)
            firebase_admin.initialize_app(cred)
            self.db = firestore.client()
            print("✅ Firebase initialisé\n")
        except Exception as e:
            print(f"❌ Erreur Firebase: {e}")
            raise

    def get_all_products(self) -> List[Dict]:
        """Récupère tous les produits de Firebase"""
        print("📖 Lecture de tous les produits...\n")
        products = []
        docs = self.db.collection(COLLECTION_NAME).stream()

        for doc in docs:
            data = doc.to_dict()
            data['doc_id'] = doc.id
            products.append(data)

        print(f"   Total: {len(products)} produits\n")
        return products

    def analyze_product(self, product: Dict) -> Dict:
        """Analyse un produit et détecte les champs manquants"""
        missing = {}

        # Champs critiques
        name = product.get('name') or product.get('product_title') or ''
        if not name or name.strip() == '':
            missing['name'] = True

        brand = product.get('brand') or ''
        if not brand or brand.strip() == '':
            missing['brand'] = True

        price = product.get('price') or product.get('product_price')
        if not price or price == 0 or price == '0' or price == '':
            missing['price'] = True

        image = product.get('image') or product.get('product_photo') or ''
        if not image or image.strip() == '' or 'placeholder' in image.lower():
            missing['image'] = True

        description = product.get('description') or ''
        if not description or description.strip() == '':
            missing['description'] = True

        categories = product.get('categories') or []
        if not categories or len(categories) == 0:
            missing['categories'] = True

        tags = product.get('tags') or []
        if not tags or len(tags) == 0:
            missing['tags'] = True

        return missing

    def scrape_amazon_product(self, url: str) -> Optional[Dict]:
        """Scrape intelligemment un produit Amazon"""
        print(f"   🌐 Scraping: {url[:60]}...")

        try:
            headers = {
                'User-Agent': USER_AGENTS[0],
                'Accept-Language': 'fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            }

            response = requests.get(url, headers=headers, timeout=15)
            response.raise_for_status()

            soup = BeautifulSoup(response.content, 'html.parser')

            data = {}

            # Titre/Nom
            title_elem = soup.find('span', {'id': 'productTitle'})
            if title_elem:
                data['name'] = title_elem.get_text().strip()

            # Marque
            brand_elem = soup.find('a', {'id': 'bylineInfo'})
            if brand_elem:
                brand_text = brand_elem.get_text().strip()
                # Extraire juste le nom de la marque
                if 'Marque' in brand_text or 'Visiter' in brand_text:
                    brand_text = brand_text.split(':')[-1].strip()
                data['brand'] = brand_text

            # Prix
            price_elem = (
                soup.find('span', {'class': 'a-price-whole'}) or
                soup.find('span', {'class': 'a-price'}) or
                soup.find('span', {'class': 'a-offscreen'})
            )
            if price_elem:
                price_text = price_elem.get_text().strip()
                # Extraire le nombre
                price_match = re.search(r'(\d+[,.]?\d*)', price_text)
                if price_match:
                    price_str = price_match.group(1).replace(',', '.')
                    data['price'] = float(price_str)

            # Image
            img_elem = soup.find('img', {'id': 'landingImage'})
            if not img_elem:
                img_elem = soup.find('img', {'class': 'a-dynamic-image'})
            if img_elem and img_elem.get('src'):
                data['image'] = img_elem['src']

            # Description
            desc_elem = soup.find('div', {'id': 'feature-bullets'})
            if desc_elem:
                bullets = desc_elem.find_all('li')
                desc_text = ' '.join([li.get_text().strip() for li in bullets])
                data['description'] = desc_text[:500]  # Limiter à 500 chars

            # Catégories (depuis le breadcrumb)
            categories = []
            breadcrumb = soup.find('div', {'id': 'wayfinding-breadcrumbs_feature_div'})
            if breadcrumb:
                cats = breadcrumb.find_all('a', {'class': 'a-link-normal'})
                categories = [c.get_text().strip() for c in cats if c.get_text().strip()]

            if categories:
                data['categories'] = categories[:5]  # Max 5 catégories

            # Tags intelligents basés sur les catégories et le titre
            tags = self._generate_intelligent_tags(data)
            if tags:
                data['tags'] = tags

            print(f"   ✅ Scraped: {data.get('name', 'Unknown')[:40]}")
            return data

        except requests.exceptions.RequestException as e:
            print(f"   ❌ Erreur réseau: {e}")
            return None
        except Exception as e:
            print(f"   ❌ Erreur scraping: {e}")
            return None

    def _generate_intelligent_tags(self, product_data: Dict) -> List[str]:
        """Génère des tags intelligents basés sur le produit"""
        tags = set()

        # Analyser le nom et la description
        text = (product_data.get('name', '') + ' ' +
                product_data.get('description', '')).lower()

        # Tags de genre
        if any(word in text for word in ['homme', 'men', 'masculin', 'monsieur']):
            tags.add('homme')
        if any(word in text for word in ['femme', 'women', 'féminin', 'madame']):
            tags.add('femme')
        if any(word in text for word in ['enfant', 'kid', 'junior', 'bébé', 'baby']):
            tags.add('enfant')

        # Tags de catégories
        categories = product_data.get('categories', [])
        for cat in categories:
            cat_lower = cat.lower()
            if 'tech' in cat_lower or 'électron' in cat_lower:
                tags.add('tech')
            if 'mode' in cat_lower or 'vêtement' in cat_lower:
                tags.add('mode')
            if 'beauté' in cat_lower or 'cosmétique' in cat_lower:
                tags.add('beauté')
            if 'maison' in cat_lower or 'déco' in cat_lower:
                tags.add('maison')
            if 'sport' in cat_lower:
                tags.add('sport')
            if 'livre' in cat_lower:
                tags.add('livre')
            if 'jouet' in cat_lower or 'jeu' in cat_lower:
                tags.add('jeux')

        # Si aucun tag de genre, essayer de deviner
        if not any(t in tags for t in ['homme', 'femme', 'enfant']):
            # Par défaut, considérer comme unisexe
            tags.add('unisexe')

        return list(tags)

    def update_product_in_firebase(self, doc_id: str, updates: Dict) -> bool:
        """Met à jour un produit dans Firebase"""
        try:
            doc_ref = self.db.collection(COLLECTION_NAME).document(doc_id)
            doc_ref.update(updates)
            return True
        except Exception as e:
            print(f"   ❌ Erreur mise à jour: {e}")
            return False

    def clean_all_products(self):
        """Nettoie tous les produits de la base"""
        print("🧹 NETTOYAGE INTELLIGENT DE LA BASE FIREBASE")
        print("=" * 60)
        print()

        # Récupérer tous les produits
        products = self.get_all_products()

        # Statistiques
        total = len(products)
        incomplete = 0
        fixed = 0
        errors = 0
        skipped = 0

        print("🔍 Analyse des produits...\n")

        for i, product in enumerate(products, 1):
            doc_id = product['doc_id']
            url = product.get('url') or product.get('product_url') or ''

            print(f"[{i}/{total}] Produit {doc_id}")

            # Analyser les champs manquants
            missing = self.analyze_product(product)

            if not missing:
                print(f"   ✅ Complet\n")
                continue

            incomplete += 1
            print(f"   ⚠️  Champs manquants: {', '.join(missing.keys())}")

            # Si pas d'URL, on ne peut rien faire
            if not url or url.strip() == '':
                print(f"   ⏭️  Pas d'URL, skipped\n")
                skipped += 1
                continue

            # Scraper le produit
            scraped_data = self.scrape_amazon_product(url)

            if not scraped_data:
                print(f"   ❌ Échec scraping\n")
                errors += 1
                time.sleep(2)  # Pause avant le suivant
                continue

            # Préparer les mises à jour
            updates = {}

            if 'name' in missing and scraped_data.get('name'):
                updates['name'] = scraped_data['name']
                updates['product_title'] = scraped_data['name']

            if 'brand' in missing and scraped_data.get('brand'):
                updates['brand'] = scraped_data['brand']

            if 'price' in missing and scraped_data.get('price'):
                updates['price'] = scraped_data['price']
                updates['product_price'] = str(scraped_data['price'])

            if 'image' in missing and scraped_data.get('image'):
                updates['image'] = scraped_data['image']
                updates['product_photo'] = scraped_data['image']

            if 'description' in missing and scraped_data.get('description'):
                updates['description'] = scraped_data['description']

            if 'categories' in missing and scraped_data.get('categories'):
                updates['categories'] = scraped_data['categories']

            if 'tags' in missing and scraped_data.get('tags'):
                updates['tags'] = scraped_data['tags']

            # Assurer qu'il y a une source
            if not product.get('source'):
                if 'amazon' in url.lower():
                    updates['source'] = 'Amazon'

            # Mettre à jour Firebase
            if updates:
                if self.update_product_in_firebase(doc_id, updates):
                    print(f"   ✅ Mis à jour: {', '.join(updates.keys())}")
                    fixed += 1
                else:
                    errors += 1

            print()

            # Pause pour éviter les blocages
            time.sleep(3)

        # Résumé final
        print("\n" + "=" * 60)
        print("📊 RÉSUMÉ")
        print("=" * 60)
        print(f"Total produits:      {total}")
        print(f"Incomplets:          {incomplete}")
        print(f"Corrigés:            {fixed}")
        print(f"Erreurs:             {errors}")
        print(f"Skippés:             {skipped}")
        print(f"Taux de succès:      {(fixed / incomplete * 100) if incomplete > 0 else 0:.1f}%")
        print("\n✨ Nettoyage terminé!\n")


def main():
    try:
        cleaner = IntelligentProductCleaner()
        cleaner.clean_all_products()
    except KeyboardInterrupt:
        print("\n\n⚠️  Arrêt demandé par l'utilisateur")
    except Exception as e:
        print(f"\n❌ Erreur fatale: {e}")
        raise


if __name__ == "__main__":
    main()
