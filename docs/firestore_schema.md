# Firestore Schema — Normalisation

Ce document décrit le schéma Firestore normalisé de l'application DORÕN,
les inconsistances actuelles identifiées, et les migrations à réaliser.

---

## Collections principales

### `/users/{userId}`

```
users/{uid}
├── displayName: string
├── email: string
├── photoUrl: string?
├── createdAt: timestamp
└── language: string ('fr' | 'en' | 'es')
```

**Sous-collections :**
```
users/{uid}/onboarding/latest
├── answers: map<string, any>   ← profil d'onboarding complet
└── createdAt: timestamp

users/{uid}/favorites/{favoriteId}
├── id: string
├── name: string
├── brand: string
├── price: number
├── image: string               ← champ canonique (à normaliser)
├── url: string
└── createdAt: timestamp

users/{uid}/wishlists/{wishlistId}
├── name: string
├── emoji: string?
├── personId: string?
├── productIds: array<string>   ← liste d'IDs de favoris (chunks of 30)
└── createdAt: timestamp

users/{uid}/people/{personId}   ← Destinataires (nouvelle architecture)
├── tags: map<string, any>      ← profil du destinataire (gender, budget, etc.)
├── isPendingFirstGen: bool
├── createdAt: timestamp
└── updatedAt: timestamp

users/{uid}/people/{personId}/giftLists/{listId}
├── listName: string
├── gifts: array<map>           ← liste de produits sélectionnés
└── createdAt: timestamp
```

---

### `/gifts/{giftId}` — Catalogue produits

```
gifts/{id}
├── name: string                ← REQUIS
├── brand: string
├── price: number
├── image: string               ← champ canonique (normaliser les aliases)
├── url: string
├── tags: array<string>         ← tags officiels Doron (gender_*, cat_*, budget_*, etc.)
├── categories: array<string>   ← catégories (alias de tags, à fusionner)
└── source: string?             ← 'amazon' | 'fnac' | etc.
```

---

## Inconsistances identifiées 🔴

| Problème | Impact | Action |
|----------|--------|--------|
| Champ image multi-nommé (`image`, `imageUrl`, `productPhoto`, `img`, etc.) | Images manquées, fallbacks utilisés | Normaliser vers `image` avec script de migration |
| `categories` et `tags` contiennent des données redondantes | Requêtes Firestore plus lentes | Fusionner dans `tags` uniquement |
| IDs générés par timestamp (collisions possibles) | Race conditions sur écriture concurrente | **✅ Corrigé** : UUID v4 utilisé partout |
| Pas d'index composites déclarés dans `firestore.rules` | Requêtes arrayContains lentes | Ajouter indexes sur `tags` |
| `giftSearches` vs `people` — deux collections pour la même entité | Données dupliquées | Migrer `giftSearches` → `people` |

---

## Index Firestore requis

Ajouter dans `firestore.indexes.json` :

```json
{
  "indexes": [
    {
      "collectionGroup": "gifts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "tags", "arrayConfig": "CONTAINS" },
        { "fieldPath": "price", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "gifts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "tags", "arrayConfig": "CONTAINS" },
        { "fieldPath": "name", "order": "ASCENDING" }
      ]
    }
  ]
}
```

---

## Migration du champ `image`

Script à exécuter via une Cloud Function ou script Node.js admin :

```javascript
// Normalise le champ image vers le champ canonique 'image'
const aliases = ['imageUrl', 'image_url', 'productPhoto', 'product_image', 'photo', 'img', 'thumbnail'];

const gifts = await db.collection('gifts').get();
const batch = db.batch();
let count = 0;

for (const doc of gifts.docs) {
  const data = doc.data();
  if (data.image) continue; // Déjà normalised
  
  let imageUrl = '';
  for (const alias of aliases) {
    if (data[alias]) { imageUrl = data[alias]; break; }
  }
  
  if (imageUrl) {
    const updates = { image: imageUrl };
    for (const alias of aliases) {
      if (data[alias]) updates[alias] = FieldValue.delete(); // Nettoyer les aliases
    }
    batch.update(doc.ref, updates);
    count++;
  }
  
  if (count % 500 === 0) await batch.commit(); // Flush par batches de 500
}
await batch.commit();
console.log(`Migrated ${count} documents`);
```

---

## Plan de migration `giftSearches` → `people`

1. Lire tous les documents `users/{uid}/giftSearches`
2. Pour chaque document, créer un document `users/{uid}/people/{id}` avec les tags correspondants
3. Associer les `gifts` existants à la nouvelle collection `giftLists`
4. Supprimer la collection `giftSearches` après validation

> **Important** : Ne pas supprimer `giftSearches` avant de valider la migration sur un utilisateur test.
