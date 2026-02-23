const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  let firestore = admin.firestore();
  let userRef = firestore.doc("Users/" + user.uid);
  await firestore.collection("Users").doc(user.uid).delete();
});

/**
 * Fonction pour supprimer TOUS les utilisateurs (Auth + Firestore)
 * ⚠️ ATTENTION: Cette fonction est DANGEREUSE et supprime TOUS les utilisateurs!
 * ⚠️ À n'utiliser que pendant le développement!
 *
 * Pour l'appeler:
 * curl -X POST https://us-central1-<PROJECT_ID>.cloudfunctions.net/deleteAllUsers \
 *   -H "Content-Type: application/json" \
 *   -d '{"confirmationKey": "DELETE_ALL_USERS_CONFIRMED"}'
 */
exports.deleteAllUsers = functions.https.onRequest(async (req, res) => {
  // CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  // Vérification de sécurité - nécessite une clé de confirmation
  const confirmationKey = req.body.confirmationKey;
  if (confirmationKey !== 'DELETE_ALL_USERS_CONFIRMED') {
    console.log('❌ Tentative de suppression sans clé de confirmation valide');
    res.status(403).json({
      error: 'Forbidden',
      message: 'Clé de confirmation manquante ou invalide'
    });
    return;
  }

  try {
    console.log('🗑️ DÉBUT SUPPRESSION DE TOUS LES UTILISATEURS');

    const firestore = admin.firestore();
    let totalAuthUsersDeleted = 0;
    let totalFirestoreDocsDeleted = 0;
    let errors = [];

    // 1. Supprimer tous les utilisateurs de Firebase Authentication
    console.log('🔄 Récupération de tous les utilisateurs Auth...');
    const listAllUsers = async (nextPageToken) => {
      try {
        const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);

        for (const userRecord of listUsersResult.users) {
          try {
            await admin.auth().deleteUser(userRecord.uid);
            totalAuthUsersDeleted++;
            console.log(`✅ Auth user supprimé: ${userRecord.email || userRecord.uid}`);
          } catch (error) {
            errors.push(`Erreur suppression Auth user ${userRecord.uid}: ${error.message}`);
            console.error(`❌ Erreur suppression ${userRecord.uid}:`, error);
          }
        }

        if (listUsersResult.pageToken) {
          await listAllUsers(listUsersResult.pageToken);
        }
      } catch (error) {
        errors.push(`Erreur lors de la récupération des utilisateurs: ${error.message}`);
        console.error('❌ Erreur récupération utilisateurs:', error);
      }
    };

    await listAllUsers();

    // 2. Supprimer tous les documents de la collection Users dans Firestore
    console.log('🔄 Suppression des documents Firestore Users...');
    const usersSnapshot = await firestore.collection('Users').get();

    const batch = firestore.batch();
    let batchCount = 0;

    for (const doc of usersSnapshot.docs) {
      batch.delete(doc.ref);
      batchCount++;

      // Firestore batch a une limite de 500 opérations
      if (batchCount === 500) {
        await batch.commit();
        totalFirestoreDocsDeleted += batchCount;
        console.log(`✅ Batch de ${batchCount} documents Firestore supprimés`);
        batchCount = 0;
      }
    }

    // Commit du dernier batch s'il reste des opérations
    if (batchCount > 0) {
      await batch.commit();
      totalFirestoreDocsDeleted += batchCount;
      console.log(`✅ Batch final de ${batchCount} documents Firestore supprimés`);
    }

    console.log('✅ SUPPRESSION TERMINÉE');
    console.log(`   - Utilisateurs Auth supprimés: ${totalAuthUsersDeleted}`);
    console.log(`   - Documents Firestore supprimés: ${totalFirestoreDocsDeleted}`);

    res.status(200).json({
      success: true,
      message: 'Tous les utilisateurs ont été supprimés',
      details: {
        authUsersDeleted: totalAuthUsersDeleted,
        firestoreDocsDeleted: totalFirestoreDocsDeleted,
        errors: errors.length > 0 ? errors : null
      }
    });

  } catch (error) {
    console.error('❌ ERREUR CRITIQUE lors de la suppression:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});
