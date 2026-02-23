#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de Transformation des Tags pour DORÕN
Adapte les tags du scraping aux tags de l'application
"""

import firebase_admin
from firebase_admin import credentials, firestore

# ============================================
# CONFIGURATION
# ============================================

FIREBASE_PROJECT_ID = "doron-b3011"

# ============================================
# MAPPINGS DE TAGS
# ============================================

# Budget mapping
BUDGET_MAPPING = {
    'budget_petit': 'budget_0-50',
    'budget_moyen': 'budget_50-100',
    'budget_luxe': 'budget_100-200',
    'budget_premium': 'budget_200+',
}

# Catégories mapping (pour normaliser)
CATEGORIES_MAPPING = {
    'mode': 'fashion',
    'chaussures': 'fashion',
    'accessoires': 'fashion',
    'beaute': 'beauty',
    'parfums': 'beauty',
    'maquillage': 'beauty',
    'vetements': 'fashion',
    'skincare': 'beauty',
    'soin': 'beauty',
    'soins': 'beauty',
}

# Intérêts/Hobbies normalisés (pour ajouter)
INTERESTS_MAPPING = {
    'sportif': ['sport', 'fitness'],
    'beaute': ['beauty', 'soin'],
    'mode': ['fashion', 'style'],
    'tech': ['tech', 'moderne'],
    'luxe': ['luxe', 'premium'],
    'casual': ['casual', 'décontracté'],
    'elegant': ['chic', 'elegant'],
    'vintage': ['vintage', 'classique'],
    'moderne': ['moderne', 'tendance'],
}

# Tags de marque spécifiques
BRAND_TAGS = {
    'Golden Goose': ['luxe', 'italien', 'sneakers', 'fashion'],
    'Zara': ['tendance', 'accessible', 'fashion', 'moderne'],
    'Sephora': ['beauty', 'beaute', 'soin'],
    'Rhode': ['beauty', 'beaute', 'skincare', 'soin'],
    'Lululemon': ['sport', 'yoga', 'fitness', 'qualite'],
    'Miu Miu': ['luxe', 'haute_couture', 'italien', 'fashion'],
    'Maje': ['fashion', 'chic', 'français'],
}

# ============================================
# INITIALISATION FIREBASE
# ============================================

def init_firebase():
    """Initialise Firebase Admin SDK"""
    try:
        cred = credentials.Certificate('serviceAccountKey.json')
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        print("✅ Firebase initialisé avec succès!")
        return db
    except Exception as e:
        print(f"❌ Erreur initialisation Firebase: {e}")
        return None

# ============================================
# TRANSFORMATION DES TAGS
# ============================================

def transform_tags(product):
    """Transforme les tags d'un produit pour correspondre à l'app"""

    original_tags = product.get('tags', [])
    original_categories = product.get('categories', [])
    brand = product.get('brand', '')
    price = product.get('price', 0)

    new_tags = set()
    new_categories = set()

    # 1. CONSERVER LES TAGS DE BASE (genre)
    for tag in original_tags:
        tag_lower = tag.lower()

        # Genre : conserver tel quel
        if tag_lower in ['homme', 'femme', 'unisexe']:
            new_tags.add(tag_lower)

        # Mapper les budgets
        elif tag_lower in BUDGET_MAPPING:
            new_tags.add(BUDGET_MAPPING[tag_lower])

        # Mapper les intérêts
        elif tag_lower in INTERESTS_MAPPING:
            new_tags.update(INTERESTS_MAPPING[tag_lower])

        # Autres tags à conserver
        else:
            new_tags.add(tag_lower)

    # 2. AJOUTER DES TAGS D'ÂGE PAR DÉFAUT
    # Si pas d'âge spécifié, ajouter adulte
    has_age = any(tag in new_tags for tag in ['enfant', '20-30ans', '30-50ans', '50+'])
    if not has_age:
        # Par défaut : adultes jeunes et moyens
        new_tags.update(['20-30ans', '30-50ans', 'adulte'])

    # Si tag "adulte", ajouter les tranches d'âge
    if 'adulte' in new_tags:
        new_tags.update(['20-30ans', '30-50ans'])

    # 3. RECALCULER LE TAG BUDGET DEPUIS LE PRIX
    if price > 0:
        if price <= 50:
            new_tags.add('budget_0-50')
        elif price <= 100:
            new_tags.add('budget_50-100')
        elif price <= 200:
            new_tags.add('budget_100-200')
        else:
            new_tags.add('budget_200+')

    # 4. NORMALISER LES CATÉGORIES
    for cat in original_categories:
        cat_lower = cat.lower()

        # Mapper si nécessaire
        if cat_lower in CATEGORIES_MAPPING:
            new_categories.add(CATEGORIES_MAPPING[cat_lower])

            # Ajouter des tags correspondants
            mapped = CATEGORIES_MAPPING[cat_lower]
            new_tags.add(mapped)

            # Tags spécifiques pour certaines catégories
            if cat_lower == 'chaussures':
                new_tags.add('chaussures')
            elif cat_lower == 'parfums':
                new_tags.add('parfum')
            elif cat_lower == 'maquillage':
                new_tags.add('maquillage')
            elif cat_lower == 'accessoires':
                new_tags.add('accessoires')
        else:
            new_categories.add(cat_lower)
            new_tags.add(cat_lower)

    # 5. AJOUTER DES TAGS BASÉS SUR LA MARQUE
    if brand in BRAND_TAGS:
        new_tags.update(BRAND_TAGS[brand])

    # 6. AJOUTER DES TAGS BASÉS SUR LE NOM DU PRODUIT
    name = product.get('name', '').lower()
    description = product.get('description', '').lower()
    full_text = f"{name} {description}"

    # Tech
    if any(word in full_text for word in ['tech', 'smart', 'électronique', 'gadget']):
        new_tags.add('tech')
        new_categories.add('tech')

    # Sport
    if any(word in full_text for word in ['sport', 'fitness', 'yoga', 'running', 'gym']):
        new_tags.add('sport')
        new_categories.add('sport')

    # Beauty
    if any(word in full_text for word in ['beauté', 'beauty', 'soin', 'cosmétique', 'parfum', 'crème']):
        new_tags.add('beauty')
        new_categories.add('beauty')

    # Fashion
    if any(word in full_text for word in ['mode', 'fashion', 'vêtement', 'robe', 'pantalon', 'chemise']):
        new_tags.add('fashion')
        new_categories.add('fashion')

    # Home
    if any(word in full_text for word in ['maison', 'déco', 'décoration', 'intérieur', 'meubles']):
        new_tags.add('home')
        new_categories.add('home')

    # Gaming
    if any(word in full_text for word in ['game', 'gaming', 'console', 'jeu', 'playstation', 'xbox']):
        new_tags.add('gaming')
        new_categories.add('gaming')

    # 7. S'ASSURER QU'IL Y A AU MOINS UNE CATÉGORIE
    if not new_categories:
        new_categories.add('mode')  # Défaut

    # 8. NETTOYER ET RETOURNER
    # Enlever les accents et normaliser
    new_tags = {tag.replace('é', 'e').replace('è', 'e').replace('ê', 'e') for tag in new_tags}
    new_categories = {cat.replace('é', 'e').replace('è', 'e').replace('ê', 'e') for cat in new_categories}

    return {
        'tags': sorted(list(new_tags)),
        'categories': sorted(list(new_categories))
    }

# ============================================
# FONCTION PRINCIPALE
# ============================================

def update_all_gifts():
    """Met à jour tous les cadeaux dans Firebase"""

    print("=" * 60)
    print("🔄 TRANSFORMATION DES TAGS DES CADEAUX DORÕN")
    print("=" * 60)
    print()

    # Initialiser Firebase
    db = init_firebase()
    if not db:
        print("❌ Impossible de continuer sans Firebase!")
        return

    # Charger tous les cadeaux
    print("📦 Chargement des cadeaux depuis Firebase...")
    gifts_ref = db.collection('gifts')
    gifts = gifts_ref.stream()

    gifts_list = []
    for gift in gifts:
        gift_data = gift.to_dict()
        gift_data['id'] = gift.id
        gifts_list.append(gift_data)

    print(f"✅ {len(gifts_list)} cadeaux chargés\n")

    if len(gifts_list) == 0:
        print("⚠️ Aucun cadeau trouvé dans la collection 'gifts'")
        return

    # Mettre à jour chaque cadeau
    updated_count = 0
    error_count = 0

    for index, gift in enumerate(gifts_list, 1):
        gift_id = gift['id']
        gift_name = gift.get('name', 'Sans nom')[:50]

        print(f"[{index}/{len(gifts_list)}] 🎁 {gift_name}...")

        # Afficher tags actuels
        print(f"    📋 Tags actuels: {gift.get('tags', [])}")
        print(f"    📂 Catégories actuelles: {gift.get('categories', [])}")

        try:
            # Transformer les tags
            transformed = transform_tags(gift)

            # Afficher les nouveaux tags
            print(f"    ✨ Nouveaux tags: {transformed['tags']}")
            print(f"    ✨ Nouvelles catégories: {transformed['categories']}")

            # Mettre à jour dans Firebase
            doc_ref = gifts_ref.document(gift_id)
            doc_ref.update({
                'tags': transformed['tags'],
                'categories': transformed['categories'],
            })

            print(f"    ✅ Mis à jour dans Firebase\n")
            updated_count += 1

        except Exception as e:
            print(f"    ❌ Erreur: {e}\n")
            error_count += 1

    # Résumé
    print()
    print("=" * 60)
    print("📊 RÉSULTATS FINAUX:")
    print(f"   ✅ {updated_count} cadeaux mis à jour")
    print(f"   ❌ {error_count} erreurs")
    print("=" * 60)
    print()
    print("🎉 TRANSFORMATION TERMINÉE!")
    print("🚀 L'application peut maintenant afficher les cadeaux correctement!")

# ============================================
# POINT D'ENTRÉE
# ============================================

if __name__ == "__main__":
    update_all_gifts()
