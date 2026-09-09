"""
Étape 2 — Récupération produit brute via Serpent API.

Génère la liste de requêtes (marque x sous-catégorie), interroge Serpent API,
et stocke CHAQUE réponse brute sur disque avant tout traitement — pour
pouvoir déboguer / auditer sans re-payer des appels.

Usage :
    # 1. Toujours commencer par un dry-run pour vérifier la liste de requêtes
    #    (aucun appel API, gratuit) :
    python scripts/pipeline/fetch_raw.py --mode test --dry-run

    # 2. Une fois la liste validée, lance le vrai test (≈12 requêtes) :
    python scripts/pipeline/fetch_raw.py --mode test

    # 3. Inspecte scripts/pipeline/raw_data/ et logs/manifest.jsonl,
    #    valide la qualité des résultats, PUIS seulement :
    python scripts/pipeline/fetch_raw.py --mode full

Le cache est automatique : une requête déjà récupérée (même chaîne exacte)
n'est pas relancée, sauf avec --force. Ça protège contre le re-paiement
accidentel d'appels lors d'un re-run.
"""

from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path

from config import FULL_BRAND_SUBCATEGORIES, TEST_BRAND_SUBCATEGORIES, build_queries
from serpent_client import SerpentApiError, SerpentClient

PIPELINE_DIR = Path(__file__).parent
RAW_DATA_DIR = PIPELINE_DIR / "raw_data"
LOGS_DIR = PIPELINE_DIR / "logs"
MANIFEST_PATH = LOGS_DIR / "manifest.jsonl"


def slugify(text: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")
    return slug[:120]


def raw_file_path(query: str) -> Path:
    return RAW_DATA_DIR / f"{slugify(query)}.json"


def append_manifest(entry: dict) -> None:
    LOGS_DIR.mkdir(parents=True, exist_ok=True)
    with MANIFEST_PATH.open("a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def run(mode: str, dry_run: bool, force: bool) -> None:
    brand_subcats = TEST_BRAND_SUBCATEGORIES if mode == "test" else FULL_BRAND_SUBCATEGORIES
    queries = build_queries(brand_subcats)

    print(f"📋 {len(queries)} requêtes générées (mode={mode})\n")
    for q in queries:
        print(f"   • [{q['brand']:20s}] {q['subcategory']:35s} → \"{q['query']}\"")

    if dry_run:
        print("\n🔍 DRY-RUN — aucun appel API effectué.")
        return

    RAW_DATA_DIR.mkdir(parents=True, exist_ok=True)
    client = SerpentClient()

    fetched, skipped, failed = 0, 0, 0

    print(f"\n🚀 Lancement des appels Serpent API ({len(queries)} requêtes)...\n")
    for i, q in enumerate(queries, 1):
        out_path = raw_file_path(q["query"])
        print(f"[{i}/{len(queries)}] \"{q['query']}\"")

        if out_path.exists() and not force:
            print(f"  ⏭  Déjà en cache ({out_path.name}) — utilise --force pour re-fetch")
            skipped += 1
            continue

        try:
            result = client.search(q["query"])
        except SerpentApiError as e:
            print(f"  ❌ Échec: {e}")
            append_manifest(
                {
                    "query": q["query"],
                    "brand": q["brand"],
                    "subcategory": q["subcategory"],
                    "status": "error",
                    "error": str(e),
                    "fetched_at": datetime.now(timezone.utc).isoformat(),
                }
            )
            failed += 1
            continue

        parsed = SerpentClient.parse_response(result.raw_response)
        record = {
            "query": q["query"],
            "brand": q["brand"],
            "subcategory": q["subcategory"],
            "fetched_at": result.fetched_at,
            "http_status": result.http_status,
            "num_results_parsed": len(parsed),
            "raw_response": result.raw_response,
        }
        out_path.write_text(json.dumps(record, indent=2, ensure_ascii=False), encoding="utf-8")

        print(f"  ✅ {len(parsed)} résultats bruts → {out_path.relative_to(PIPELINE_DIR)}")
        append_manifest(
            {
                "query": q["query"],
                "brand": q["brand"],
                "subcategory": q["subcategory"],
                "status": "ok",
                "num_results_parsed": len(parsed),
                "raw_file": str(out_path.relative_to(PIPELINE_DIR)),
                "fetched_at": result.fetched_at,
            }
        )
        fetched += 1

        if i < len(queries):
            import time

            time.sleep(client.request_delay_s)

    print("\n╔══════════════════════════════════════════╗")
    print(f"║  ✅ Récupérées : {fetched:<4} requêtes            ║")
    print(f"║  ⏭  Cache      : {skipped:<4} requêtes            ║")
    print(f"║  ❌ Échecs      : {failed:<4} requêtes            ║")
    print("╚══════════════════════════════════════════╝")
    print(f"\nRésultats bruts : {RAW_DATA_DIR}")
    print(f"Journal complet : {MANIFEST_PATH}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--mode", choices=["test", "full"], default="test", help="test = 3 marques/~12 requêtes, full = catalogue complet (config.py)")
    parser.add_argument("--dry-run", action="store_true", help="Affiche les requêtes sans appeler l'API (gratuit)")
    parser.add_argument("--force", action="store_true", help="Re-fetch même si un résultat en cache existe déjà")
    args = parser.parse_args()

    run(mode=args.mode, dry_run=args.dry_run, force=args.force)
