#!/usr/bin/env python3
"""
Script pour supprimer TOUS les produits de Firebase
"""

import requests
import time

FIREBASE_PROJECT_ID = "doron-b3011"
FIRESTORE_BASE_URL = f"https://firestore.googleapis.com/v1/projects/{FIREBASE_PROJECT_ID}/databases/(default)/documents"

def delete_all_products():
    """Supprime tous les produits de la collection gifts"""
    print("🗑️  SUPPRESSION DE TOUS LES PRODUITS\n")
    print("=" * 70)

    # Récupérer tous les produits
    url = f"{FIRESTORE_BASE_URL}/gifts"
    params = {'pageSize': 1000}

    try:
        response = requests.get(url, params=params)
        response.raise_for_status()
        data = response.json()

        documents = data.get('documents', [])
        total = len(documents)

        if total == 0:
            print("✅ Aucun produit à supprimer\n")
            return

        print(f"📊 {total} produits à supprimer\n")

        # Supprimer chaque produit
        deleted = 0
        failed = 0

        for i, doc in enumerate(documents, 1):
            doc_path = doc['name']
            doc_id = doc_path.split('/')[-1]

            try:
                # Supprimer le document (ajouter https:// si manquant)
                if not doc_path.startswith('http'):
                    doc_path = f"https://firestore.googleapis.com/v1/{doc_path}"
                delete_response = requests.delete(doc_path)
                delete_response.raise_for_status()

                deleted += 1
                print(f"[{i}/{total}] ✅ Supprimé: {doc_id}")

                # Pause pour éviter de surcharger l'API
                if i % 10 == 0:
                    time.sleep(0.5)

            except Exception as e:
                failed += 1
                print(f"[{i}/{total}] ❌ Erreur: {doc_id} - {e}")

        # Résumé
        print("\n" + "=" * 70)
        print("📊 RÉSUMÉ")
        print("=" * 70)
        print(f"Total:      {total}")
        print(f"Supprimés:  {deleted} ✅")
        print(f"Échecs:     {failed} ❌")
        print()

        if deleted == total:
            print("✨ Tous les produits ont été supprimés avec succès!\n")
        else:
            print(f"⚠️  {failed} produits n'ont pas pu être supprimés\n")

    except Exception as e:
        print(f"❌ Erreur lors de la récupération: {e}\n")

if __name__ == "__main__":
    print("\n⚠️  ATTENTION: Cette opération va supprimer TOUS les produits!")
    print("   Appuie sur Ctrl+C pour annuler dans les 5 secondes...\n")

    try:
        time.sleep(5)
        delete_all_products()
    except KeyboardInterrupt:
        print("\n\n❌ Annulé par l'utilisateur\n")
