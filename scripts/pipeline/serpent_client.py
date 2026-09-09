"""
Client Serpent API (apiserpent.com) — endpoint Deep Search.

Contrat confirmé contre la doc officielle (apiserpent.com) :
    - Endpoint  : GET https://apiserpent.com/api/search  (Deep Search)
                  (/api/search/quick existe aussi, /api/shopping n'est PAS actif — 404)
    - Auth      : header "X-API-Key: <clé>"
    - Params    : q, country, language, engine (google|bing|yahoo|ddg|brave), num
    - Réponse   : { success, query, results: { organic: [...], shopping: [...] }, meta }

⚠️ Point important non couvert par la doc : ce n'est PAS une API produit
dédiée mais un wrapper de résultats de recherche multi-moteurs. Les
produits (titre/image/prix/marchand/lien) ne sont présents que dans
`results.shopping[]`, qui peut être vide si Google ne déclenche pas de
carrousel shopping pour la requête (c'est le cas dans l'exemple officiel
pour "Apple écouteurs" — shopping: []). `results.organic[]` ne contient
que title/url/snippet/position/displayedUrl, pas de prix ni d'image :
inutilisable comme fiche produit, donc ignoré par parse_response().

Conséquence pratique : il faut s'attendre à un taux de requêtes "vides"
(0 résultat shopping) non négligeable, et potentiellement reformuler les
requêtes (ex. ajouter "acheter" ou "prix") pour augmenter les chances que
Google affiche un carrousel shopping. À valider sur le run de test avant
de lancer le run complet.

La doc ne précise pas les champs exacts des éléments de `results.shopping`
(seul l'exemple avec shopping: [] est fourni) — parse_response() essaie
plusieurs noms de champs courants (title/price/source/thumbnail/link et
variantes) et log les clés brutes du premier item au premier run réel
pour permettre un ajustement rapide si besoin.

Variables d'environnement :
    SERPENT_API_KEY         (obligatoire)
    SERPENT_API_BASE_URL    (défaut : https://apiserpent.com)
    SERPENT_REQUEST_DELAY_S (défaut : 1.0 — pause entre 2 requêtes)
"""

from __future__ import annotations

import argparse
import json
import os
import time
from dataclasses import dataclass
from typing import Any, Optional

import requests
from dotenv import load_dotenv

load_dotenv()

# ============================================================================
# Contrat API confirmé (apiserpent.com)
# ============================================================================
DEFAULT_BASE_URL = "https://apiserpent.com"
SEARCH_PATH = "/api/search"  # Deep Search (recommandé par la doc)
QUERY_PARAM = "q"
API_KEY_HEADER_NAME = "X-API-Key"
DEFAULT_ENGINE = "google"
DEFAULT_NUM_RESULTS = 50  # plus de résultats = plus de chances d'avoir un carrousel shopping
# ============================================================================


class SerpentApiError(Exception):
    pass


@dataclass
class SerpentResult:
    query: str
    http_status: int
    raw_response: Any
    fetched_at: str


class SerpentClient:
    def __init__(
        self,
        api_key: Optional[str] = None,
        base_url: Optional[str] = None,
        timeout_s: float = 20.0,
        max_retries: int = 3,
    ):
        self.api_key = api_key or os.environ.get("SERPENT_API_KEY")
        if not self.api_key:
            raise SerpentApiError(
                "SERPENT_API_KEY manquant. Ajoute-le dans ton .env "
                "(jamais en dur dans le code)."
            )
        self.base_url = (base_url or os.environ.get("SERPENT_API_BASE_URL") or DEFAULT_BASE_URL).rstrip("/")
        self.timeout_s = timeout_s
        self.max_retries = max_retries
        self.request_delay_s = float(os.environ.get("SERPENT_REQUEST_DELAY_S", "1.0"))

    def _build_request(
        self, query: str, country: str, language: str, engine: str, num: int
    ) -> dict:
        params = {
            QUERY_PARAM: query,
            "country": country,
            "language": language,
            "engine": engine,
            "num": num,
        }
        headers = {API_KEY_HEADER_NAME: self.api_key}
        return {"url": f"{self.base_url}{SEARCH_PATH}", "params": params, "headers": headers}

    def search(
        self,
        query: str,
        country: str = "fr",
        language: str = "fr",
        engine: str = DEFAULT_ENGINE,
        num: int = DEFAULT_NUM_RESULTS,
    ) -> SerpentResult:
        """Lance une recherche via Serpent API pour `query`.

        Retry avec backoff exponentiel sur 429/5xx. Lève SerpentApiError
        sur échec définitif ou sur toute autre erreur HTTP.
        """
        req = self._build_request(query, country, language, engine, num)
        last_exc: Optional[Exception] = None

        for attempt in range(1, self.max_retries + 1):
            try:
                resp = requests.get(
                    req["url"], params=req["params"], headers=req["headers"], timeout=self.timeout_s
                )
                if resp.status_code == 200:
                    data = resp.json()
                    if not data.get("success", True):
                        raise SerpentApiError(f"success=false sur '{query}': {json.dumps(data)[:300]}")
                    return SerpentResult(
                        query=query,
                        http_status=200,
                        raw_response=data,
                        fetched_at=_now_iso(),
                    )
                if resp.status_code in (429, 500, 502, 503, 504):
                    wait = 2 ** attempt
                    print(f"  ⚠️  HTTP {resp.status_code} sur '{query}' — retry dans {wait}s ({attempt}/{self.max_retries})")
                    time.sleep(wait)
                    continue
                raise SerpentApiError(
                    f"HTTP {resp.status_code} sur '{query}': {resp.text[:300]}"
                )
            except requests.RequestException as e:
                last_exc = e
                wait = 2 ** attempt
                print(f"  ⚠️  Erreur réseau sur '{query}' ({e}) — retry dans {wait}s")
                time.sleep(wait)

        raise SerpentApiError(f"Échec définitif sur '{query}': {last_exc}")

    @staticmethod
    def parse_response(raw: Any, warn_unknown_fields: bool = True) -> list[dict]:
        """Extrait les produits de `results.shopping[]`.

        `results.organic[]` est délibérément ignoré : il n'a ni image ni
        prix ni marchand (juste title/url/snippet), donc inexploitable
        comme fiche produit pour ce pipeline.
        """
        shopping = ((raw or {}).get("results") or {}).get("shopping") or []
        products = []
        for item in shopping:
            product = {
                "title": item.get("title") or item.get("name"),
                "image": item.get("thumbnail") or item.get("image") or item.get("imageUrl"),
                "price": item.get("price") or item.get("extracted_price") or item.get("extractedPrice"),
                "merchant": item.get("source") or item.get("merchant") or item.get("seller"),
                "link": item.get("link") or item.get("url") or item.get("productLink"),
            }
            if warn_unknown_fields and not any(product.values()):
                print(f"  ⚠️  Item shopping avec champs inconnus, clés brutes: {list(item.keys())}")
            products.append(product)
        return products


def _now_iso() -> str:
    import datetime

    return datetime.datetime.now(datetime.timezone.utc).isoformat()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Test manuel d'une requête Serpent API — permet de vérifier "
        "la forme exacte de results.shopping[] avant le run batch."
    )
    parser.add_argument("--test-query", required=True, help='Ex: "Apple écouteurs"')
    args = parser.parse_args()

    client = SerpentClient()
    result = client.search(args.test_query)
    print(json.dumps(result.raw_response, indent=2, ensure_ascii=False)[:4000])

    shopping = ((result.raw_response or {}).get("results") or {}).get("shopping") or []
    print(f"\n--- results.shopping: {len(shopping)} item(s) ---")
    if shopping:
        print("Clés du premier item :", list(shopping[0].keys()))

    print("\n--- Parsé (à vérifier / ajuster parse_response) ---")
    print(json.dumps(SerpentClient.parse_response(result.raw_response), indent=2, ensure_ascii=False))
