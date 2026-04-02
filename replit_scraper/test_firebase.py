#!/usr/bin/env python3
"""
🔥 Script de test rapide Firebase
Vérifie que la connexion Firebase fonctionne
"""

import firebase_admin
from firebase_admin import credentials, firestore

def test_firebase():
    """Test la connexion Firebase"""
    print("\n🔥 TEST CONNEXION FIREBASE\n")
    print("="*60)

    try:
        # Initialiser Firebase
        print("\n1️⃣  Initialisation Firebase...")
        cred = credentials.Certificate('serviceAccountKey.json')
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        print("✅ Firebase initialisé avec succès!")

        # Lister les collections
        print("\n2️⃣  Récupération des collections...")
        collections = db.collections()
        collection_names = [col.id for col in collections]
        print(f"✅ Collections trouvées: {', '.join(collection_names)}")

        # Compter les produits dans 'gifts'
        if 'gifts' in collection_names:
            print("\n3️⃣  Comptage des produits dans 'gifts'...")
            gifts = db.collection('gifts').limit(10).stream()
            count = sum(1 for _ in gifts)
            print(f"✅ Au moins {count} produits dans 'gifts'")

            # Afficher un exemple
            print("\n4️⃣  Exemple de produit:")
            first_gift = db.collection('gifts').limit(1).get()[0]
            data = first_gift.to_dict()
            print(f"   ID: {first_gift.id}")
            print(f"   Nom: {data.get('name', 'N/A')}")
            print(f"   Marque: {data.get('brand', 'N/A')}")
            print(f"   Prix: {data.get('price', 'N/A')}€")
            print(f"   Image: {data.get('image', 'N/A')[:60]}...")

        print("\n" + "="*60)
        print("✅ TEST RÉUSSI - Firebase fonctionne correctement!")
        print("="*60 + "\n")

        return True

    except FileNotFoundError:
        print("\n❌ ERREUR: serviceAccountKey.json non trouvé!")
        print("\nAssurez-vous que le fichier est à la racine de votre Repl.")
        return False

    except Exception as e:
        print(f"\n❌ ERREUR: {e}")
        print("\nVérifiez que votre fichier serviceAccountKey.json est valide.")
        return False

if __name__ == "__main__":
    test_firebase()
