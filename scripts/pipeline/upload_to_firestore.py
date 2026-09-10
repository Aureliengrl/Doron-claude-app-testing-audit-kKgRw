"""
Étape 5 — Écriture idempotente dans Firestore.
Prend les données de scripts/pipeline/final_doron_catalog.json et les uploade
dans la collection 'gifts' de Firebase Firestore.

Usage :
    python scripts/pipeline/upload_to_firestore.py --key path/to/serviceAccountKey.json
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent.parent
CATALOG_JSON = BASE_DIR / "scripts" / "pipeline" / "final_doron_catalog.json"

def find_service_account_key(cli_path: str = None) -> Path:
    if cli_path and Path(cli_path).exists():
        return Path(cli_path)
        
    env_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if env_path and Path(env_path).exists():
        return Path(env_path)
        
    candidates = [
        BASE_DIR / "serviceAccountKey.json",
        BASE_DIR / "scripts" / "serviceAccountKey.json",
        BASE_DIR / "scripts" / "pipeline" / "serviceAccountKey.json",
        Path.home() / "serviceAccountKey.json",
        Path.home() / "Documents" / "serviceAccountKey.json",
        Path.home() / "Downloads" / "serviceAccountKey.json",
    ]
    for c in candidates:
        if c.exists():
            return c
            
    return None

def upload_catalog(key_path: Path, collection_name: str = "gifts", dry_run: bool = False):
    import firebase_admin
    from firebase_admin import credentials, firestore
    
    print("=" * 60)
    print(f"🔥 INITIALISATION FIREBASE FIRESTORE")
    print("=" * 60)
    print(f"🔑 Clé Service Account : {key_path}")
    print(f"📂 Collection cible    : {collection_name}")
    print(f"📦 Fichier catalogue   : {CATALOG_JSON}")
    
    if not CATALOG_JSON.exists():
        print(f"❌ Erreur : fichier introuvable {CATALOG_JSON}")
        return
        
    with CATALOG_JSON.open("r", encoding="utf-8") as f:
        products = json.load(f)
        
    print(f"📋 Total produits à synchroniser : {len(products)}")
    
    if dry_run:
        print("\n🔍 MODE DRY-RUN : aucun document écrit dans Firestore.")
        return
        
    if not firebase_admin._apps:
        cred = credentials.Certificate(str(key_path))
        firebase_admin.initialize_app(cred)
        
    db = firestore.client()
    
    batch = db.batch()
    batch_count = 0
    total_written = 0
    
    print("\n🚀 Écriture des fiches produits dans Firestore...\n")
    for i, p in enumerate(products, 1):
        doc_id = p["id"]
        doc_ref = db.collection(collection_name).document(doc_id)
        
        # Merge pour idempotence
        batch.set(doc_ref, p, merge=True)
        batch_count += 1
        total_written += 1
        
        if batch_count >= 400:
            batch.commit()
            print(f"  💾 Commit batch de {batch_count} produits ({total_written}/{len(products)})...")
            batch = db.batch()
            batch_count = 0
            time.sleep(0.5)
            
    if batch_count > 0:
        batch.commit()
        print(f"  💾 Commit final de {batch_count} produits ({total_written}/{len(products)})...")
        
    print("\n" + "=" * 60)
    print(f"🎉 SUCCÈS ! {total_written} fiches produits synchronisées dans '{collection_name}'.")
    print("=" * 60)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Upload du catalogue DORÕN dans Firestore")
    parser.add_argument("--key", help="Chemin vers le fichier serviceAccountKey.json")
    parser.add_argument("--collection", default="gifts", help="Nom de la collection (par défaut 'gifts')")
    parser.add_argument("--dry-run", action="store_true", help="Simule l'envoi sans écrire")
    args = parser.parse_args()
    
    key = find_service_account_key(args.key)
    if not key and not args.dry_run:
        print("⚠️ Aucun fichier 'serviceAccountKey.json' trouvé automatiquement.")
        print("Usage: python upload_to_firestore.py --key /chemin/vers/serviceAccountKey.json")
        sys.exit(1)
        
    upload_catalog(key, collection_name=args.collection, dry_run=args.dry_run)
