#!/usr/bin/env python3
"""
Script pour corriger les images des produits
Assigne des images Unsplash pertinentes basées sur le nom et la catégorie du produit
"""

import json
import re

# Banque d'images Unsplash par type de produit (IDs vérifiés)
PRODUCT_IMAGES = {
    # TECH & AUDIO
    'airpods': [
        'https://images.unsplash.com/photo-1606841837239-c5a1a4a07af7?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1610438235354-a6ae5528385c?w=600&auto=format&fit=crop',
    ],
    'écouteurs': [
        'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1484704849700-f032a568e944?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1545127398-14699f92334b?w=600&auto=format&fit=crop',
    ],
    'casque': [
        'https://images.unsplash.com/photo-1618366712010-f4ae9c647dcb?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1546435770-a3e426bf2a98?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1487215078519-e21cc028cb29?w=600&auto=format&fit=crop',
    ],
    'montre': [
        'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1524805444758-089113d48a6d?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1511370235399-1802cae1d32f?w=600&auto=format&fit=crop',
    ],
    'smartphone': [
        'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1592286927505-ed7a0b43d7bd?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=600&auto=format&fit=crop',
    ],
    'tablette': [
        'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1585789575780-9e91aa6e47a8?w=600&auto=format&fit=crop',
    ],
    'ordinateur': [
        'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=600&auto=format&fit=crop',
    ],
    'clavier': [
        'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1595225476474-87563907a212?w=600&auto=format&fit=crop',
    ],
    'souris': [
        'https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1586249725355-7faf89a05f47?w=600&auto=format&fit=crop',
    ],
    'console': [
        'https://images.unsplash.com/photo-1486401899868-0e435ed85128?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1622297845775-5ff3fef71d13?w=600&auto=format&fit=crop',
    ],
    'manette': [
        'https://images.unsplash.com/photo-1592840062661-773610bae35b?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1612287230202-1ff1d85d1bdf?w=600&auto=format&fit=crop',
    ],
    'appareil photo': [
        'https://images.unsplash.com/photo-1502920917128-1aa500764cbd?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1606920503603-28f972812193?w=600&auto=format&fit=crop',
    ],
    'caméra': [
        'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1505739998589-00fc191ce01d?w=600&auto=format&fit=crop',
    ],

    # BEAUTÉ
    'parfum': [
        'https://images.unsplash.com/photo-1541643600914-78b084683601?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1592945403244-b3fbafd7f539?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1594035910387-fea47794261f?w=600&auto=format&fit=crop',
    ],
    'maquillage': [
        'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=600&auto=format&fit=crop',
    ],
    'rouge': [
        'https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?w=600&auto=format&fit=crop',
    ],
    'crème': [
        'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=600&auto=format&fit=crop',
    ],
    'sérum': [
        'https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=600&auto=format&fit=crop',
    ],

    # MODE & ACCESSOIRES
    'sac': [
        'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1591561954555-607968c989ab?w=600&auto=format&fit=crop',
    ],
    'lunettes': [
        'https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1473496169904-658ba7c44d8a?w=600&auto=format&fit=crop',
    ],
    'portefeuille': [
        'https://images.unsplash.com/photo-1627123424574-724758594e93?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600&auto=format&fit=crop',
    ],
    'ceinture': [
        'https://images.unsplash.com/photo-1624222247344-550fb60583aa?w=600&auto=format&fit=crop',
    ],
    'écharpe': [
        'https://images.unsplash.com/photo-1520903920243-00d872a2d1c9?w=600&auto=format&fit=crop',
    ],
    'bijou': [
        'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=600&auto=format&fit=crop',
    ],
    'collier': [
        'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=600&auto=format&fit=crop',
    ],
    'bracelet': [
        'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=600&auto=format&fit=crop',
    ],
    'bague': [
        'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=600&auto=format&fit=crop',
    ],

    # MAISON & DÉCO
    'bougie': [
        'https://images.unsplash.com/photo-1602874801006-5a647e2fa6d7?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1603006905003-be475563bc59?w=600&auto=format&fit=crop',
    ],
    'coussin': [
        'https://images.unsplash.com/photo-1584100936595-c0654b55a2e2?w=600&auto=format&fit=crop',
    ],
    'lampe': [
        'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1543198126-a8b1c6b3d6c0?w=600&auto=format&fit=crop',
    ],
    'cadre': [
        'https://images.unsplash.com/photo-1513519245088-0e12902e35ca?w=600&auto=format&fit=crop',
    ],
    'vase': [
        'https://images.unsplash.com/photo-1578500494198-246f612d3b3d?w=600&auto=format&fit=crop',
    ],
    'plante': [
        'https://images.unsplash.com/photo-1459156212016-c812468e2115?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1470058869958-2a77ade41c02?w=600&auto=format&fit=crop',
    ],

    # LIVRES & CULTURE
    'livre': [
        'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=600&auto=format&fit=crop',
    ],
    'manga': [
        'https://images.unsplash.com/photo-1609829880172-d23e6dcf0ec5?w=600&auto=format&fit=crop',
    ],
    'bd': [
        'https://images.unsplash.com/photo-1612036782180-6f0b6cd846fe?w=600&auto=format&fit=crop',
    ],

    # GASTRONOMIE
    'vin': [
        'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?w=600&auto=format&fit=crop',
    ],
    'champagne': [
        'https://images.unsplash.com/photo-1547595628-c61a29f496f0?w=600&auto=format&fit=crop',
    ],
    'chocolat': [
        'https://images.unsplash.com/photo-1511381939415-e44015466834?w=600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1606312619070-d48b4a3eb53e?w=600&auto=format&fit=crop',
    ],
    'thé': [
        'https://images.unsplash.com/photo-1564890369478-c89ca6d9cde9?w=600&auto=format&fit=crop',
    ],
    'café': [
        'https://images.unsplash.com/photo-1511920170033-f8396924c348?w=600&auto=format&fit=crop',
    ],

    # SPORT & LOISIRS
    'ballon': [
        'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=600&auto=format&fit=crop',
    ],
    'yoga': [
        'https://images.unsplash.com/photo-1588286840104-8957b019727f?w=600&auto=format&fit=crop',
    ],
    'vélo': [
        'https://images.unsplash.com/photo-1532298229144-0ec0c57515c7?w=600&auto=format&fit=crop',
    ],
    'trottinette': [
        'https://images.unsplash.com/photo-1596215143922-eebd0b7af710?w=600&auto=format&fit=crop',
    ],
}

# Image par défaut par catégorie
DEFAULT_IMAGES = {
    'tech': 'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=600&auto=format&fit=crop',
    'beauty': 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=600&auto=format&fit=crop',
    'fashion': 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=600&auto=format&fit=crop',
    'home': 'https://images.unsplash.com/photo-1556228453-efd6c1ff04f6?w=600&auto=format&fit=crop',
    'food': 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=600&auto=format&fit=crop',
    'gaming': 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=600&auto=format&fit=crop',
    'books': 'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=600&auto=format&fit=crop',
    'sports': 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=600&auto=format&fit=crop',
}

def find_matching_image(product):
    """Trouve l'image la plus pertinente pour un produit"""
    name_lower = product['name'].lower()
    desc_lower = product.get('description', '').lower()
    search_text = f"{name_lower} {desc_lower}"

    # Chercher par mots-clés spécifiques
    for keyword, images in PRODUCT_IMAGES.items():
        if keyword in search_text:
            # Utiliser l'index du produit pour varier les images
            idx = product['id'] % len(images)
            return images[idx]

    # Si pas de match, utiliser l'image par défaut de la catégorie
    categories = product.get('categories', [])
    if categories:
        for cat in categories:
            if cat in DEFAULT_IMAGES:
                return DEFAULT_IMAGES[cat]

    # Dernière option: image tech par défaut
    return DEFAULT_IMAGES['tech']

def main():
    print("🖼️  Correction des images des produits...")

    # Lire le fichier
    with open('assets/jsons/fallback_products.json', 'r', encoding='utf-8') as f:
        products = json.load(f)

    print(f"📦 {len(products)} produits chargés")

    # Corriger les images
    updated = 0
    for product in products:
        old_image = product.get('image', '')
        new_image = find_matching_image(product)

        if new_image != old_image:
            product['image'] = new_image
            updated += 1

    # Sauvegarder
    with open('assets/jsons/fallback_products.json', 'w', encoding='utf-8') as f:
        json.dump(products, f, ensure_ascii=False, indent=2)

    print(f"✅ {updated} images mises à jour")
    print(f"💾 Fichier sauvegardé: assets/jsons/fallback_products.json")

if __name__ == '__main__':
    main()
