# Test Diagnostic - Flux Onboarding vs Ajout de Personne

## FLUX QUI MARCHE (Ajout de personne)

1. User **DÉJÀ CONNECTÉ** → `isLoggedIn = true`
2. Onboarding avec `skipUserQuestions = true`
3. `createPerson()` appelé :
   - Sauvegarde LOCAL (SharedPreferences)
   - Sauvegarde FIREBASE (car isLoggedIn=true)
   - Retourne `personId`
4. Navigation: `/onboarding-gifts-result?personId=X`
5. `loadPersonById(X)` :
   - Cherche dans LOCAL → **TROUVÉ** ✅
   - Ou cherche dans FIREBASE → **TROUVÉ** ✅
6. Tags chargés → Cadeaux affichés ✅

## FLUX QUI NE MARCHE PAS (Premier onboarding)

1. User **PAS CONNECTÉ** → `isLoggedIn = false`
2. Onboarding complet avec `skipUserQuestions = false`
3. `createPerson()` appelé :
   - Sauvegarde LOCAL (SharedPreferences) → ✅ OK
   - **SKIP Firebase** (car isLoggedIn=false) → ⚠️
   - Retourne `personId`
4. Navigation: `/authentification?personId=X`
5. User se connecte (Email/Google/Apple)
6. **SYNC ajouté** : `syncLocalPersonToFirebase(X)` → ⚠️ Est-ce que ça marche ?
7. Navigation: `/onboarding-gifts-result?personId=X`
8. `loadPersonById(X)` :
   - Cherche dans LOCAL → **DEVRAIT TROUVER** ✅
   - Si pas trouvé, cherche FIREBASE → ⚠️
9. **RÉSULTAT** : "Personne non trouvée" ❌

## HYPOTHÈSES DU PROBLÈME

### Hypothèse 1: Local Storage est VIDÉ après connexion
- Peut-être que la connexion Google/Apple/Email **VIDE** le local storage ?
- Ou change l'utilisateur, ce qui change la clé de stockage ?

### Hypothèse 2: personId est PERDU ou CORROMPU
- Le personId n'est pas correctement passé via les paramètres URL ?
- Il y a un decode/encode qui corrompt l'ID ?

### Hypothèse 3: Sync échoue silencieusement
- `syncLocalPersonToFirebase()` échoue mais on continue quand même
- Firebase n'a pas la personne
- Local n'a plus la personne (si vidé)
- Résultat : `loadPersonById()` retourne `null`

### Hypothèse 4: Tags sont NULL ou mal formés
- La personne est trouvée mais `person['tags']` est null
- Ou le format des tags est incorrect

### Hypothèse 5: Problème de TIMING
- Navigation trop rapide avant que le local storage soit écrit ?
- (Non probable car `createPerson()` est `await`)

## TESTS À FAIRE

### Test 1: Vérifier le Local Storage
Ajouter des logs dans `createPerson()` pour confirmer :
```dart
print('💾 SAVING TO LOCAL: personId=$personId');
print('💾 Tags being saved: $tags');
await prefs.setString('local_people', json.encode(people));
print('✅ SAVED TO LOCAL: ${people.length} people total');
```

### Test 2: Vérifier loadPersonById
Ajouter des logs dans `loadPersonById()` :
```dart
print('🔍 SEARCHING LOCAL for personId=$personId');
print('   Found ${localPeople.length} people in local');
print('   Looking for ID: $personId');
if (localPerson.isNotEmpty) {
  print('✅ FOUND in local!');
} else {
  print('❌ NOT FOUND in local, trying Firebase...');
}
```

### Test 3: Vérifier que personId est bien passé
Ajouter des logs dans authentification_widget.dart :
```dart
print('📝 _pendingPersonId = $_pendingPersonId');
print('🔄 Calling syncLocalPersonToFirebase($_pendingPersonId)');
```

### Test 4: Vérifier le format des tags
```dart
print('📋 personTags keys: ${personTags.keys.toList()}');
print('📋 gender value: ${personTags['gender']}');
print('📋 budget value: ${personTags['budget']}');
```

## SOLUTION PROBABLE

Si le local storage est vidé ou la personne n'y est plus, alors:

**Option A: Ne PAS dépendre du sync Firebase**
→ Passer les TAGS directement dans l'URL ou via un Provider global

**Option B: Garantir que local storage persiste**
→ Vérifier que la connexion ne vide pas le storage

**Option C: Créer la personne APRÈS la connexion**
→ Stocker temporairement les réponses, connecter, PUIS créer la personne
