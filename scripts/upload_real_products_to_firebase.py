#!/usr/bin/env python3
"""
Script pour uploader les 379 VRAIS produits directement dans Firebase Firestore
"""

import json
import firebase_admin
from firebase_admin import credentials, firestore
import time

def upload_products():
    """Upload les produits RÉELS dans Firebase"""

    print("🔥 CONNEXION À FIREBASE...")

    # Initialiser Firebase Admin
    try:
        cred = credentials.Certificate('/home/user/Doron/serviceAccountKey.json')
        firebase_admin.initialize_app(cred)
        print("✅ Firebase Admin SDK initialisé")
    except Exception as e:
        print(f"❌ Erreur initialisation Firebase: {e}")
        return

    db = firestore.client()

    print("\n📦 CHARGEMENT DES PRODUITS RÉELS...")

    # Charger les produits depuis le fichier
    with open('/home/user/Doron/scripts/affiliate/websearch_real_products.json', 'r', encoding='utf-8') as f:
        products = json.load(f)

    print(f"✅ {len(products)} produits chargés depuis websearch_real_products.json")

    print("\n🗑️  SUPPRESSION DES ANCIENS PRODUITS...")

    # Supprimer tous les anciens produits
    deleted_count = 0
    batch = db.batch()
    batch_count = 0

    # Récupérer tous les documents pour suppression
    docs = db.collection('products').stream()

    for doc in docs:
        batch.delete(doc.reference)
        batch_count += 1
        deleted_count += 1

        # Firestore limite à 500 opérations par batch
        if batch_count >= 500:
            batch.commit()
            print(f"   Supprimé {deleted_count} produits...")
            batch = db.batch()
            batch_count = 0
            time.sleep(0.5)  # Petite pause pour éviter rate limiting

    # Commit le dernier batch
    if batch_count > 0:
        batch.commit()

    print(f"✅ {deleted_count} anciens produits supprimés")

    print("\n📤 UPLOAD DES NOUVEAUX PRODUITS RÉELS...")

    # Uploader les nouveaux produits
    uploaded_count = 0
    batch = db.batch()
    batch_count = 0

    for product in products:
        # Créer une référence avec l'ID du produit
        product_id = str(product['id'])
        doc_ref = db.collection('products').document(product_id)

        # Préparer les données (enlever l'ID car il sera dans le document ID)
        product_data = {k: v for k, v in product.items() if k != 'id'}

        # Ajouter au batch
        batch.set(doc_ref, product_data)
        batch_count += 1
        uploaded_count += 1

        # Commit tous les 500 produits
        if batch_count >= 500:
            batch.commit()
            print(f"   ✅ Uploadé {uploaded_count}/{len(products)} produits...")
            batch = db.batch()
            batch_count = 0
            time.sleep(0.5)

    # Commit le dernier batch
    if batch_count > 0:
        batch.commit()

    print(f"\n✅ {uploaded_count} produits RÉELS uploadés dans Firebase!")

    print("\n📊 VÉRIFICATION...")

    # Vérifier quelques produits
    sample_products = db.collection('products').limit(5).stream()

    print("\n🎁 Exemples de produits dans Firebase:")
    for doc in sample_products:
        data = doc.to_dict()
        print(f"   • {data.get('name')} - {data.get('brand')}")
        print(f"     Image: {data.get('image', '')[:80]}...")

    print("\n🎉 UPLOAD TERMINÉ!")
    print("🚀 Les produits RÉELS sont maintenant dans Firebase!")
    print("📱 Tu peux maintenant rafraîchir ton app TestFlight pour voir les vrais produits!")

if __name__ == '__main__':
    upload_products()
