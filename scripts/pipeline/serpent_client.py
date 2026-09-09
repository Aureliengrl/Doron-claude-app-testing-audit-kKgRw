"""
Client Serpent API (wrapper Google Shopping — apiserpent.com).

⚠️ À FINALISER : cet environnement n'a pas d'accès réseau sortant vers
apiserpent.com, donc les 5 constantes ci-dessous (endpoint, méthode HTTP,
nom des paramètres, style d'authentification, forme de la réponse JSON)
sont posées sur la base d'un wrapper Google Shopping "standard" mais n'ont
PAS été vérifiées contre la vraie doc. Avant le premier run réel :

    python scripts/pipeline/serpent_client.py --test-query "Apple écouteurs"

... et compare la réponse brute affichée avec ce que documente
apiserpent.com. Ajuste ensuite SEARCH_PATH / QUERY_PARAM / AUTH_STYLE /
parse_response() en conséquence. Rien d'autre dans le pipeline n'a besoin
de changer : tout le reste consomme uniquement la sortie de
`SerpentClient.search()`.

Variables d'environnement :
    SERPENT_API_KEY       (obligatoire)
    SERPENT_API_BASE_URL  (défaut : https://api.apiserpent.com)
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
# ⚠️ CONFIG À CONFIRMER CONTRE LA DOC OFFICIELLE (voir docstring ci-dessus)
# ============================================================================
DEFAULT_BASE_URL = "https://api.apiserpent.com"
SEARCH_PATH = "/search"  # TODO: confirmer le chemin exact
QUERY_PARAM = "q"  # TODO: confirmer le nom du paramètre de requête
AUTH_STYLE = "bearer_header"  # "bearer_header" | "api_key_header" | "query_param"
API_KEY_QUERY_PARAM_NAME = "api_key"  # utilisé seulement si AUTH_STYLE == "query_param"
API_KEY_HEADER_NAME = "X-API-Key"  # utilisé seulement si AUTH_STYLE == "api_key_header"
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

    def _build_request(self, query: str, country: str, language: str) -> dict:
        params = {QUERY_PARAM: query, "gl": country, "hl": language}
        headers = {}

        if AUTH_STYLE == "bearer_header":
            headers["Authorization"] = f"Bearer {self.api_key}"
        elif AUTH_STYLE == "api_key_header":
            headers[API_KEY_HEADER_NAME] = self.api_key
        elif AUTH_STYLE == "query_param":
            params[API_KEY_QUERY_PARAM_NAME] = self.api_key
        else:
            raise SerpentApiError(f"AUTH_STYLE inconnu: {AUTH_STYLE}")

        return {"url": f"{self.base_url}{SEARCH_PATH}", "params": params, "headers": headers}

    def search(self, query: str, country: str = "fr", language: str = "fr") -> SerpentResult:
        """Lance une recherche Google Shopping via Serpent API pour `query`.

        Retry avec backoff exponentiel sur 429/5xx. Lève SerpentApiError
        sur échec définitif ou sur toute autre erreur HTTP.
        """
        req = self._build_request(query, country, language)
        last_exc: Optional[Exception] = None

        for attempt in range(1, self.max_retries + 1):
            try:
                resp = requests.get(
                    req["url"], params=req["params"], headers=req["headers"], timeout=self.timeout_s
                )
                if resp.status_code == 200:
                    return SerpentResult(
                        query=query,
                        http_status=200,
                        raw_response=resp.json(),
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
    def parse_response(raw: Any) -> list[dict]:
        """Normalise la réponse brute Serpent en liste de produits plats.

        ⚠️ À adapter selon la forme réelle du JSON retourné par l'API.
        Hypothèse actuelle (wrapper Google Shopping typique) : une clé
        top-level "shopping_results" contenant une liste d'objets avec
        title / thumbnail / extracted_price / source / link.
        """
        items = raw.get("shopping_results") or raw.get("results") or []
        products = []
        for item in items:
            products.append(
                {
                    "title": item.get("title"),
                    "image": item.get("thumbnail") or item.get("image"),
                    "price": item.get("extracted_price") or item.get("price"),
                    "merchant": item.get("source") or item.get("merchant"),
                    "link": item.get("link") or item.get("product_link"),
                }
            )
        return products


def _now_iso() -> str:
    import datetime

    return datetime.datetime.now(datetime.timezone.utc).isoformat()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Test manuel d'une requête Serpent API — sert à valider "
        "le contrat exact (endpoint/auth/forme de réponse) avant le run batch."
    )
    parser.add_argument("--test-query", required=True, help='Ex: "Apple écouteurs"')
    args = parser.parse_args()

    client = SerpentClient()
    result = client.search(args.test_query)
    print(json.dumps(result.raw_response, indent=2, ensure_ascii=False)[:4000])
    print("\n--- Parsé (à vérifier / ajuster parse_response) ---")
    print(json.dumps(SerpentClient.parse_response(result.raw_response), indent=2, ensure_ascii=False))
