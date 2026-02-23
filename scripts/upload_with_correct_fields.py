#!/usr/bin/env python3
"""
Upload les 379 produits RÉELS dans Firebase avec les BONS champs Flutter
"""

import json
import sys
import os

# Ajouter le chemin pour importer firebase_admin
sys.path.insert(0, '/root/.local/lib/python3.11/site-packages')

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    print("✅ Firebase Admin SDK importé")
except ImportError as e:
    print(f"❌ Erreur import Firebase: {e}")
    print("\n💡 SOLUTION ALTERNATIVE:")
    print("   Utilise la page Admin dans TestFlight après rebuild de l'app")
    sys.exit(1)

def upload_products():
    """Upload les produits avec les bons champs"""

    print("\n🔥 UPLOAD DIRECT DANS FIREBASE")
    print("=" * 60)

    # Initialiser Firebase
    try:
        cred = credentials.Certificate('serviceAccountKey.json')
        if not firebase_admin._apps:
            firebase_admin.initialize_app(cred)
        print("✅ Firebase initialisé")
    except Exception as e:
        print(f"❌ Erreur Firebase: {e}")
        return False

    db = firestore.client()

    # Charger les produits
    print("\n📦 CHARGEMENT DES PRODUITS...")
    with open('scripts/affiliate/websearch_real_products.json', 'r', encoding='utf-8') as f:
        products = json.load(f)

    print(f"✅ {len(products)} produits chargés\n")

    # Supprimer les anciens produits
    print("🗑️  SUPPRESSION DES ANCIENS PRODUITS...")
    try:
        deleted = 0
        batch = db.batch()
        batch_count = 0

        docs = db.collection('products').stream()
        for doc in docs:
            batch.delete(doc.reference)
            batch_count += 1
            deleted += 1

            if batch_count >= 500:
                batch.commit()
                print(f"   Supprimé {deleted} produits...")
                batch = db.batch()
                batch_count = 0

        if batch_count > 0:
            batch.commit()

        print(f"✅ {deleted} anciens produits supprimés\n")
    except Exception as e:
        print(f"⚠️  Erreur suppression: {e}\n")

    # Uploader les nouveaux produits AVEC LES BONS CHAMPS
    print("📤 UPLOAD DES NOUVEAUX PRODUITS...")
    print("   ⚠️  AVEC LES BONS CHAMPS FLUTTER!\n")

    uploaded = 0
    batch = db.batch()
    batch_count = 0

    for product in products:
        product_id = str(product['id'])
        doc_ref = db.collection('products').doc(product_id)

        # TRANSFORMER avec les champs que Flutter attend
        data = {
            'name': product['name'],
            'brand': product['brand'],
            'price': product['price'],
            'url': product['url'],
            'image': product['image'],
            'product_photo': product['image'],  # ← CRUCIAL!
            'product_title': product['name'],
            'product_url': product['url'],
            'product_price': str(product['price']),
            'description': product.get('description', ''),
            'categories': product.get('categories', []),
            'tags': product.get('tags', []),
            'popularity': product.get('popularity', 50),
            'source': product.get('source', 'websearch_verified')
        }

        batch.set(doc_ref, data)
        batch_count += 1
        uploaded += 1

        if batch_count >= 500:
            try:
                batch.commit()
                print(f"   ✅ Uploadé {uploaded}/{len(products)} produits...")
                batch = db.batch()
                batch_count = 0
            except Exception as e:
                print(f"   ❌ Erreur batch: {e}")
                return False

    # Dernier batch
    if batch_count > 0:
        try:
            batch.commit()
        except Exception as e:
            print(f"❌ Erreur dernier batch: {e}")
            return False

    print(f"\n✅ {uploaded} produits uploadés avec SUCCÈS!")

    # Vérification
    print("\n🔍 VÉRIFICATION...")
    sample = db.collection('products').limit(3).stream()

    print("\n📋 Exemples de produits dans Firebase:")
    for doc in sample:
        data = doc.to_dict()
        print(f"\n   • {data.get('name')} - {data.get('brand')}")
        print(f"     product_photo: {data.get('product_photo', 'MANQUANT')[:80]}...")
        print(f"     image: {data.get('image', 'MANQUANT')[:80]}...")

    print("\n" + "=" * 60)
    print("🎉 UPLOAD TERMINÉ!")
    print("=" * 60)
    print("\n📱 DANS TESTFLIGHT:")
    print("   1. Ferme complètement l'app (swipe up)")
    print("   2. Rouvre l'app")
    print("   3. Les images devraient maintenant apparaître!")
    print("\n✅ Les produits ont maintenant le champ 'product_photo' !\n")

    return True

if __name__ == '__main__':
    try:
        success = upload_products()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n❌ ERREUR FATALE: {e}")
        print("\n💡 Si ça ne marche pas, rebuild l'app avec le nouveau")
        print("   fallback_products.json et re-upload sur TestFlight")
        sys.exit(1)
