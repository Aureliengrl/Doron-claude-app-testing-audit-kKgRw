#!/usr/bin/env python3
"""
Script pour que Claude travaille MANUELLEMENT sur Firebase
Pas de scraping robot, juste moi qui analyse et corrige intelligemment
"""

import requests
import json
from typing import Dict, List, Optional

# Configuration Firebase (depuis firebase_config.dart)
FIREBASE_API_KEY = "AIzaSyAl7Jlzgyet26D3zO4pF56BfznA3k3AiTk"
FIREBASE_PROJECT_ID = "doron-b3011"
FIRESTORE_BASE_URL = f"https://firestore.googleapis.com/v1/projects/{FIREBASE_PROJECT_ID}/databases/(default)/documents"

class ManualFirebaseFixer:
    def __init__(self):
        self.base_url = FIRESTORE_BASE_URL
        print("🔗 Connexion à Firebase...")
        print(f"   Projet: {FIREBASE_PROJECT_ID}")
        print()

    def _convert_firestore_value(self, value):
        """Convertit une valeur Firestore en Python"""
        if isinstance(value, dict):
            if 'stringValue' in value:
                return value['stringValue']
            elif 'integerValue' in value:
                return int(value['integerValue'])
            elif 'doubleValue' in value:
                return float(value['doubleValue'])
            elif 'booleanValue' in value:
                return value['booleanValue']
            elif 'arrayValue' in value:
                values = value['arrayValue'].get('values', [])
                return [self._convert_firestore_value(v) for v in values]
            elif 'mapValue' in value:
                fields = value['mapValue'].get('fields', {})
                return {k: self._convert_firestore_value(v) for k, v in fields.items()}
        return value

    def _convert_to_firestore_value(self, value):
        """Convertit une valeur Python en format Firestore"""
        if isinstance(value, str):
            return {'stringValue': value}
        elif isinstance(value, bool):
            return {'booleanValue': value}
        elif isinstance(value, int):
            return {'integerValue': str(value)}
        elif isinstance(value, float):
            return {'doubleValue': value}
        elif isinstance(value, list):
            return {
                'arrayValue': {
                    'values': [self._convert_to_firestore_value(v) for v in value]
                }
            }
        elif isinstance(value, dict):
            return {
                'mapValue': {
                    'fields': {k: self._convert_to_firestore_value(v) for k, v in value.items()}
                }
            }
        return {'nullValue': None}

    def get_all_products(self) -> List[Dict]:
        """Récupère tous les produits de Firebase"""
        print("📖 Récupération de tous les produits...\n")

        url = f"{self.base_url}/gifts"
        params = {'pageSize': 1000}  # Max par page

        try:
            response = requests.get(url, params=params)
            response.raise_for_status()
            data = response.json()

            products = []
            for doc in data.get('documents', []):
                # Extraire l'ID du document
                doc_id = doc['name'].split('/')[-1]

                # Convertir les champs Firestore
                fields = doc.get('fields', {})
                product = {
                    'doc_id': doc_id,
                    'doc_path': doc['name']
                }

                for key, value in fields.items():
                    product[key] = self._convert_firestore_value(value)

                products.append(product)

            print(f"✅ {len(products)} produits récupérés\n")
            return products

        except requests.exceptions.RequestException as e:
            print(f"❌ Erreur API: {e}")
            return []

    def analyze_product(self, product: Dict) -> Dict:
        """Analyse un produit et retourne les problèmes"""
        issues = []

        # Nom
        name = product.get('name') or product.get('product_title') or ''
        if not name or name.strip() == '':
            issues.append('❌ NOM MANQUANT')

        # Marque
        brand = product.get('brand') or ''
        if not brand or brand.strip() == '':
            issues.append('❌ MARQUE MANQUANTE')

        # Prix
        price = product.get('price', 0)
        if not price or price == 0:
            issues.append('❌ PRIX MANQUANT/NUL')

        # Image
        image = product.get('image') or product.get('product_photo') or ''
        if not image or image.strip() == '' or 'placeholder' in image.lower():
            issues.append('❌ IMAGE MANQUANTE')

        # Description
        description = product.get('description') or ''
        if not description or description.strip() == '':
            issues.append('⚠️  Description manquante')

        # URL
        url = product.get('url') or product.get('product_url') or ''
        if not url or url.strip() == '':
            issues.append('🚫 URL MANQUANTE (non réparable)')

        # Catégories
        categories = product.get('categories') or []
        if not categories or len(categories) == 0:
            issues.append('⚠️  Catégories manquantes')

        # Tags
        tags = product.get('tags') or []
        if not tags or len(tags) == 0:
            issues.append('⚠️  Tags manquants')

        return {
            'issues': issues,
            'critical': len([i for i in issues if '❌' in i]) > 0,
            'url': url
        }

    def update_product(self, doc_id: str, updates: Dict) -> bool:
        """Met à jour un produit dans Firebase"""
        print(f"\n📝 Mise à jour du produit {doc_id}...")

        url = f"{self.base_url}/gifts/{doc_id}"

        # Convertir les updates en format Firestore
        fields = {}
        for key, value in updates.items():
            fields[key] = self._convert_to_firestore_value(value)

        payload = {'fields': fields}
        params = {
            'updateMask.fieldPaths': list(updates.keys())
        }

        try:
            response = requests.patch(url, json=payload, params=params)
            response.raise_for_status()
            print(f"✅ Produit {doc_id} mis à jour")
            print(f"   Champs: {', '.join(updates.keys())}")
            return True
        except requests.exceptions.RequestException as e:
            print(f"❌ Erreur mise à jour: {e}")
            if hasattr(e.response, 'text'):
                print(f"   Détails: {e.response.text[:200]}")
            return False

    def show_incomplete_products(self):
        """Affiche tous les produits incomplets"""
        products = self.get_all_products()

        print("=" * 80)
        print("🔍 ANALYSE DES PRODUITS")
        print("=" * 80)
        print()

        incomplete = []
        for product in products:
            analysis = self.analyze_product(product)
            if analysis['issues']:
                incomplete.append({
                    'product': product,
                    'analysis': analysis
                })

        print(f"📊 Résumé:")
        print(f"   Total: {len(products)} produits")
        print(f"   Complets: {len(products) - len(incomplete)}")
        print(f"   Incomplets: {len(incomplete)}")
        print()

        if incomplete:
            print("=" * 80)
            print("⚠️  PRODUITS INCOMPLETS (Top 20)")
            print("=" * 80)
            print()

            for i, item in enumerate(incomplete[:20], 1):
                product = item['product']
                analysis = item['analysis']

                name = product.get('name') or product.get('product_title') or 'SANS NOM'
                print(f"\n{'='*80}")
                print(f"[{i}] {name[:70]}")
                print(f"{'='*80}")
                print(f"ID: {product['doc_id']}")
                print(f"URL: {analysis['url'][:70] if analysis['url'] else 'AUCUNE'}")
                print(f"\nProblèmes:")
                for issue in analysis['issues']:
                    print(f"  {issue}")

                # Afficher les valeurs actuelles
                print(f"\nValeurs actuelles:")
                print(f"  Nom: {product.get('name', 'N/A')}")
                print(f"  Marque: {product.get('brand', 'N/A')}")
                print(f"  Prix: {product.get('price', 'N/A')}€")
                print(f"  Image: {(product.get('image') or 'N/A')[:60]}")
                print(f"  Description: {(product.get('description') or 'N/A')[:60]}")

        return incomplete

    def interactive_fix(self):
        """Mode interactif pour corriger les produits"""
        print("\n" + "=" * 80)
        print("🛠️  MODE INTERACTIF DE CORRECTION")
        print("=" * 80)
        print()
        print("Je vais maintenant pouvoir corriger chaque produit manuellement")
        print("en analysant intelligemment les URLs.")
        print()

        incomplete = self.show_incomplete_products()

        if not incomplete:
            print("\n✨ Aucun produit incomplet ! La base est propre.")
            return

        print(f"\n\n🎯 {len(incomplete)} produits à corriger")
        print("\nClaude va maintenant analyser chaque produit avec WebFetch...")


def main():
    fixer = ManualFirebaseFixer()
    fixer.interactive_fix()


if __name__ == "__main__":
    main()
