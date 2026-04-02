#!/usr/bin/env python3
"""
Script d'analyse SEULEMENT (sans modification)
Affiche un rapport détaillé de l'état de la base Firebase
"""

import firebase_admin
from firebase_admin import credentials, firestore
from typing import Dict, List

FIREBASE_CREDENTIALS = "firebase-credentials.json"
COLLECTION_NAME = "gifts"

class FirebaseAnalyzer:
    def __init__(self):
        try:
            cred = credentials.Certificate(FIREBASE_CREDENTIALS)
            firebase_admin.initialize_app(cred)
            self.db = firestore.client()
            print("✅ Firebase initialisé\n")
        except Exception as e:
            print(f"❌ Erreur Firebase: {e}")
            raise

    def analyze_product(self, product: Dict) -> Dict:
        """Analyse un produit et retourne les stats"""
        issues = []

        # Nom
        name = product.get('name') or product.get('product_title') or ''
        if not name or name.strip() == '':
            issues.append('❌ Nom manquant')

        # Marque
        brand = product.get('brand') or ''
        if not brand or brand.strip() == '':
            issues.append('❌ Marque manquante')

        # Prix
        price = product.get('price') or product.get('product_price')
        if not price or price == 0 or price == '0' or price == '':
            issues.append('❌ Prix manquant/nul')

        # Image
        image = product.get('image') or product.get('product_photo') or ''
        if not image or image.strip() == '' or 'placeholder' in image.lower():
            issues.append('❌ Image manquante')

        # Description
        description = product.get('description') or ''
        if not description or description.strip() == '':
            issues.append('⚠️  Description manquante')

        # Catégories
        categories = product.get('categories') or []
        if not categories or len(categories) == 0:
            issues.append('⚠️  Catégories manquantes')

        # Tags
        tags = product.get('tags') or []
        if not tags or len(tags) == 0:
            issues.append('⚠️  Tags manquants')

        # URL
        url = product.get('url') or product.get('product_url') or ''
        if not url or url.strip() == '':
            issues.append('🚫 URL manquante (non réparable)')

        return {
            'issues': issues,
            'critical': any('❌' in i for i in issues),
            'fixable': url.strip() != ''
        }

    def analyze_all(self):
        """Analyse complète de la base"""
        print("🔍 ANALYSE DE LA BASE FIREBASE")
        print("=" * 70)
        print()

        # Récupérer tous les produits
        print("📖 Lecture des produits...")
        docs = self.db.collection(COLLECTION_NAME).stream()

        products = []
        for doc in docs:
            data = doc.to_dict()
            data['doc_id'] = doc.id
            products.append(data)

        total = len(products)
        print(f"   Total: {total} produits\n")

        # Statistiques
        stats = {
            'total': total,
            'complete': 0,
            'incomplete': 0,
            'critical_issues': 0,
            'fixable': 0,
            'not_fixable': 0,
            'issues_by_type': {
                'nom': 0,
                'marque': 0,
                'prix': 0,
                'image': 0,
                'description': 0,
                'categories': 0,
                'tags': 0,
                'url': 0
            }
        }

        incomplete_products = []

        # Analyser chaque produit
        print("🔍 Analyse en cours...")
        for product in products:
            analysis = self.analyze_product(product)

            if not analysis['issues']:
                stats['complete'] += 1
            else:
                stats['incomplete'] += 1
                incomplete_products.append({
                    'id': product['doc_id'],
                    'name': product.get('name') or product.get('product_title') or 'Sans nom',
                    'issues': analysis['issues']
                })

                if analysis['critical']:
                    stats['critical_issues'] += 1

                if analysis['fixable']:
                    stats['fixable'] += 1
                else:
                    stats['not_fixable'] += 1

                # Compter par type
                for issue in analysis['issues']:
                    if 'Nom' in issue:
                        stats['issues_by_type']['nom'] += 1
                    elif 'Marque' in issue:
                        stats['issues_by_type']['marque'] += 1
                    elif 'Prix' in issue:
                        stats['issues_by_type']['prix'] += 1
                    elif 'Image' in issue:
                        stats['issues_by_type']['image'] += 1
                    elif 'Description' in issue:
                        stats['issues_by_type']['description'] += 1
                    elif 'Catégories' in issue:
                        stats['issues_by_type']['categories'] += 1
                    elif 'Tags' in issue:
                        stats['issues_by_type']['tags'] += 1
                    elif 'URL' in issue:
                        stats['issues_by_type']['url'] += 1

        # Afficher le rapport
        print()
        print("=" * 70)
        print("📊 RAPPORT D'ANALYSE")
        print("=" * 70)
        print()
        print(f"Total produits:           {stats['total']}")
        print(f"✅ Complets:              {stats['complete']} ({stats['complete']/stats['total']*100:.1f}%)")
        print(f"⚠️  Incomplets:            {stats['incomplete']} ({stats['incomplete']/stats['total']*100:.1f}%)")
        print(f"❌ Problèmes critiques:   {stats['critical_issues']}")
        print()
        print("🛠️  Réparabilité:")
        print(f"   ✅ Réparables:         {stats['fixable']}")
        print(f"   🚫 Non réparables:     {stats['not_fixable']} (pas d'URL)")
        print()
        print("📋 Problèmes par type:")
        for issue_type, count in stats['issues_by_type'].items():
            if count > 0:
                print(f"   • {issue_type.capitalize():15} {count:4} produit(s)")

        # Top 10 des produits les plus problématiques
        if incomplete_products:
            print()
            print("=" * 70)
            print("🔴 TOP 10 DES PRODUITS LES PLUS PROBLÉMATIQUES")
            print("=" * 70)
            incomplete_products.sort(key=lambda x: len(x['issues']), reverse=True)

            for i, prod in enumerate(incomplete_products[:10], 1):
                print(f"\n{i}. {prod['name'][:50]}")
                print(f"   ID: {prod['id']}")
                for issue in prod['issues']:
                    print(f"   {issue}")

        print()
        print("=" * 70)
        print()

        if stats['incomplete'] > 0:
            print(f"💡 Tu peux corriger {stats['fixable']} produits avec le script:")
            print(f"   python3 intelligent_firebase_cleaner.py")
            print()
        else:
            print("✨ Ta base est nickel ! Tous les produits sont complets.")
            print()


def main():
    try:
        analyzer = FirebaseAnalyzer()
        analyzer.analyze_all()
    except KeyboardInterrupt:
        print("\n\n⚠️  Arrêt demandé par l'utilisateur")
    except Exception as e:
        print(f"\n❌ Erreur fatale: {e}")
        raise


if __name__ == "__main__":
    main()
