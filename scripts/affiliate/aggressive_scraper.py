#!/usr/bin/env python3
"""
Script de scraping agressif pour récupérer les VRAIES images de produits
Utilise plusieurs techniques pour contourner les blocages
"""

import requests
from bs4 import BeautifulSoup
import json
import time
import random
from urllib.parse import urljoin, urlparse
import re

class AggressiveScraper:
    def __init__(self):
        self.session = requests.Session()
        self.user_agents = [
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15'
        ]
        self.products = []

    def get_headers(self):
        """Génère des headers réalistes"""
        return {
            'User-Agent': random.choice(self.user_agents),
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7',
            'Accept-Encoding': 'gzip, deflate, br',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
            'Sec-Fetch-Dest': 'document',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Site': 'none',
            'Cache-Control': 'max-age=0'
        }

    def fetch_page(self, url, retries=3):
        """Fetch une page avec retry et gestion des erreurs"""
        for attempt in range(retries):
            try:
                time.sleep(random.uniform(1.5, 3.5))  # Délai aléatoire
                response = self.session.get(url, headers=self.get_headers(), timeout=15)

                if response.status_code == 200:
                    return response
                elif response.status_code == 403:
                    print(f"⚠️  403 Forbidden sur {url}, tentative via revendeur...")
                    return None
                elif response.status_code == 429:
                    print(f"⚠️  Rate limited, attente de {(attempt + 1) * 5}s...")
                    time.sleep((attempt + 1) * 5)
                else:
                    print(f"⚠️  Status {response.status_code} sur {url}")

            except Exception as e:
                print(f"❌ Erreur sur {url}: {e}")
                if attempt < retries - 1:
                    time.sleep(random.uniform(2, 5))

        return None

    def scrape_nike_product(self, product_code):
        """Scrape un produit Nike spécifique"""
        url = f"https://www.nike.com/fr/t/product/{product_code}"

        try:
            response = self.fetch_page(url)
            if not response:
                # Essayer via Zalando
                return self.scrape_zalando("Nike", product_code)

            soup = BeautifulSoup(response.text, 'html.parser')

            # Extraire les données
            name = soup.find('h1', {'data-test': 'product-title'})
            price = soup.find('div', {'data-test': 'product-price'})
            images = soup.find_all('img', {'data-test': 'product-image'})

            if name and price and images:
                return {
                    'name': name.text.strip(),
                    'brand': 'Nike',
                    'price': self.extract_price(price.text),
                    'url': url,
                    'image': images[0].get('src') or images[0].get('data-src'),
                    'description': f"Produit Nike {name.text.strip()}"
                }
        except Exception as e:
            print(f"❌ Erreur Nike {product_code}: {e}")

        return None

    def scrape_zalando(self, brand, search_term):
        """Scrape via Zalando (plus permissif)"""
        search_url = f"https://www.zalando.fr/catalog/?q={brand}+{search_term}"

        try:
            response = self.fetch_page(search_url)
            if not response:
                return None

            soup = BeautifulSoup(response.text, 'html.parser')

            # Trouver le premier produit
            product_cards = soup.find_all('article', class_=re.compile('.*product.*', re.I))

            if product_cards:
                card = product_cards[0]

                # Extraire nom
                name_elem = card.find(['h3', 'div'], class_=re.compile('.*name.*|.*title.*', re.I))
                # Extraire prix
                price_elem = card.find(['span', 'div'], class_=re.compile('.*price.*', re.I))
                # Extraire image
                img_elem = card.find('img')
                # Extraire lien
                link_elem = card.find('a', href=True)

                if name_elem and price_elem and img_elem:
                    return {
                        'name': name_elem.text.strip(),
                        'brand': brand,
                        'price': self.extract_price(price_elem.text),
                        'url': urljoin('https://www.zalando.fr', link_elem['href']) if link_elem else search_url,
                        'image': img_elem.get('src') or img_elem.get('data-src') or img_elem.get('data-lazy-src'),
                        'description': f"{brand} - {name_elem.text.strip()}"
                    }
        except Exception as e:
            print(f"❌ Erreur Zalando {brand} {search_term}: {e}")

        return None

    def scrape_farfetch(self, brand, search_term):
        """Scrape via Farfetch (pour le luxe)"""
        search_url = f"https://www.farfetch.com/fr/shopping/{brand.lower()}/items.aspx"

        try:
            response = self.fetch_page(search_url)
            if not response:
                return None

            soup = BeautifulSoup(response.text, 'html.parser')

            # Trouver produits
            product_cards = soup.find_all(['li', 'div'], attrs={'data-component': re.compile('.*ProductCard.*', re.I)})

            if product_cards:
                card = product_cards[0]

                name_elem = card.find(['p', 'span'], attrs={'data-component': 'ProductCardDescription'})
                price_elem = card.find(['span'], attrs={'data-component': 'Price'})
                img_elem = card.find('img')
                link_elem = card.find('a', href=True)

                if name_elem and img_elem:
                    return {
                        'name': name_elem.text.strip(),
                        'brand': brand,
                        'price': self.extract_price(price_elem.text) if price_elem else 0,
                        'url': urljoin('https://www.farfetch.com', link_elem['href']) if link_elem else search_url,
                        'image': img_elem.get('src') or img_elem.get('data-src'),
                        'description': f"{brand} - {name_elem.text.strip()}"
                    }
        except Exception as e:
            print(f"❌ Erreur Farfetch {brand}: {e}")

        return None

    def extract_price(self, price_text):
        """Extrait le prix d'un texte"""
        try:
            # Chercher les nombres avec virgule ou point
            match = re.search(r'[\d\s]+[,.]?\d*', price_text.replace(' ', ''))
            if match:
                price_str = match.group().replace(',', '.').replace(' ', '')
                return float(price_str)
        except:
            pass
        return 0

    def scrape_popular_products(self):
        """Scrape les produits les plus populaires de plusieurs marques"""

        print("🚀 DÉMARRAGE DU SCRAPING AGRESSIF")
        print("=" * 60)

        # Liste de produits populaires à scraper
        targets = [
            # Nike (via Zalando car Nike bloque souvent)
            {'brand': 'Nike', 'search': 'Air Force 1', 'category': 'sport'},
            {'brand': 'Nike', 'search': 'Air Max 90', 'category': 'sport'},
            {'brand': 'Nike', 'search': 'Dunk Low', 'category': 'sport'},
            {'brand': 'Nike', 'search': 'Jordan 1', 'category': 'sport'},
            {'brand': 'Nike', 'search': 'Blazer', 'category': 'sport'},

            # Adidas
            {'brand': 'Adidas', 'search': 'Stan Smith', 'category': 'sport'},
            {'brand': 'Adidas', 'search': 'Samba', 'category': 'sport'},
            {'brand': 'Adidas', 'search': 'Superstar', 'category': 'sport'},
            {'brand': 'Adidas', 'search': 'Gazelle', 'category': 'sport'},
            {'brand': 'Adidas', 'search': 'Ultraboost', 'category': 'sport'},

            # New Balance
            {'brand': 'New Balance', 'search': '550', 'category': 'sport'},
            {'brand': 'New Balance', 'search': '574', 'category': 'sport'},
            {'brand': 'New Balance', 'search': '990', 'category': 'sport'},

            # Vans
            {'brand': 'Vans', 'search': 'Old Skool', 'category': 'sport'},
            {'brand': 'Vans', 'search': 'Authentic', 'category': 'sport'},

            # Converse
            {'brand': 'Converse', 'search': 'Chuck Taylor', 'category': 'sport'},
            {'brand': 'Converse', 'search': 'Chuck 70', 'category': 'sport'},

            # Marques Luxe (via Farfetch/Zalando)
            {'brand': 'Gucci', 'search': 'Ace Sneakers', 'category': 'fashion'},
            {'brand': 'Gucci', 'search': 'Marmont Bag', 'category': 'fashion'},
            {'brand': 'Balenciaga', 'search': 'Triple S', 'category': 'fashion'},
            {'brand': 'Balenciaga', 'search': 'City Bag', 'category': 'fashion'},
            {'brand': 'Saint Laurent', 'search': 'Court Classic', 'category': 'fashion'},
            {'brand': 'Prada', 'search': 'Re-Edition', 'category': 'fashion'},
            {'brand': 'Dior', 'search': 'B23', 'category': 'fashion'},

            # Mode street
            {'brand': 'Stone Island', 'search': 'Hoodie', 'category': 'fashion'},
            {'brand': 'Carhartt WIP', 'search': 'Detroit Jacket', 'category': 'fashion'},
            {'brand': 'The North Face', 'search': 'Nuptse', 'category': 'fashion'},
            {'brand': 'Canada Goose', 'search': 'Chilliwack', 'category': 'fashion'},
        ]

        product_id = 1

        for target in targets:
            print(f"\n🔍 Scraping: {target['brand']} - {target['search']}")

            # Essayer Zalando d'abord (plus permissif)
            product = self.scrape_zalando(target['brand'], target['search'])

            # Si échec, essayer Farfetch pour le luxe
            if not product and target['category'] == 'fashion':
                product = self.scrape_farfetch(target['brand'], target['search'])

            if product:
                product['id'] = product_id
                product['categories'] = [target['category']]
                product['tags'] = self.generate_tags(product)
                product['popularity'] = 75
                product['source'] = 'scraped_real'

                self.products.append(product)
                print(f"✅ Trouvé: {product['name']} - {product['price']}€")
                print(f"   Image: {product['image'][:80]}...")
                product_id += 1
            else:
                print(f"❌ Échec pour {target['brand']} {target['search']}")

        print(f"\n✅ SCRAPING TERMINÉ: {len(self.products)} produits récupérés")
        return self.products

    def generate_tags(self, product):
        """Génère les tags automatiques"""
        tags = []
        price = product.get('price', 0)
        category = product.get('categories', [''])[0].lower()
        name = product.get('name', '').lower()

        # Genre
        if any(word in name for word in ['femme', 'women', 'woman', 'ladies']):
            tags.append('femme')
        elif any(word in name for word in ['homme', 'men', 'man', 'mens']):
            tags.append('homme')
        else:
            tags.extend(['homme', 'femme'])

        # Age basé sur le prix
        if price < 50:
            tags.append('20-30ans')
        elif price < 200:
            tags.extend(['20-30ans', '30-50ans'])
        else:
            tags.extend(['30-50ans', '50+'])

        # Budget
        if price < 50:
            tags.append('budget_0-50')
        elif price < 100:
            tags.append('budget_50-100')
        elif price < 200:
            tags.append('budget_100-200')
        else:
            tags.append('budget_200+')

        # Catégorie
        if category in ['sport', 'sports']:
            tags.append('sports')
        elif category in ['tech', 'technology']:
            tags.append('tech')
        elif category in ['fashion', 'mode']:
            tags.append('mode')

        return list(set(tags))

    def save_to_file(self, filename='scraped_real_products.json'):
        """Sauvegarde les produits dans un fichier"""
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(self.products, f, indent=2, ensure_ascii=False)
        print(f"\n💾 Sauvegardé dans {filename}")


if __name__ == '__main__':
    scraper = AggressiveScraper()
    products = scraper.scrape_popular_products()
    scraper.save_to_file('/home/user/Doron/scripts/affiliate/scraped_real_products.json')

    print(f"\n📊 RÉSUMÉ:")
    print(f"   Total produits: {len(products)}")
    print(f"   Avec images: {sum(1 for p in products if p.get('image'))}")
    print(f"   Avec prix: {sum(1 for p in products if p.get('price', 0) > 0)}")
