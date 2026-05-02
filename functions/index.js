/**
 * Doron Cloud Functions
 *
 * S1: sendChatNotification          — nouveau message dans un chat
 * S2: sendFriendRequestNotification — demande d'ami reçue
 * S3: sendCollabInviteNotification  — invitation à collaborer sur une liste cadeaux
 * S4: sendCollabMemberAddNotification — ajout direct comme membre d'une collaboration
 *
 * Deploy: firebase deploy --only functions
 */

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();
const db = getFirestore();

// ─────────────────────────────────────────────────────────────────────────────
// S1: Push notification pour les nouveaux messages de chat
// Trigger: nouveau document dans chats/{chatId}/messages/{messageId}
// ─────────────────────────────────────────────────────────────────────────────
exports.sendChatNotification = onDocumentCreated(
  'chats/{chatId}/messages/{messageId}',
  async (event) => {
    const messageData = event.data?.data();
    if (!messageData) return;

    const chatId = event.params.chatId;
    const senderId = messageData.senderId;
    const messageType = messageData.type || 'text';
    
    // Texte de preview selon le type de message
    let previewText = messageData.text || '';
    if (messageType === 'product_card') {
      try {
        const parsed = JSON.parse(previewText);
        previewText = `📦 ${parsed.name || 'Produit partagé'}`;
      } catch (_) {
        previewText = '📦 Produit partagé';
      }
    } else if (messageType === 'wishlist_card') {
      try {
        const parsed = JSON.parse(previewText);
        previewText = `🎁 ${parsed.name || 'Wishlist partagée'}`;
      } catch (_) {
        previewText = '🎁 Wishlist partagée';
      }
    }

    // Récupérer le chat pour avoir les participants
    const chatSnap = await db.collection('chats').doc(chatId).get();
    if (!chatSnap.exists) return;

    const chatData = chatSnap.data();
    const participants = chatData.participants || [];
    const isGroup = chatData.isGroup === true;
    const chatName = chatData.name || 'Message';

    // Récupérer le nom de l'expéditeur
    let senderName = 'Quelqu\'un';
    try {
      const senderSnap = await db.collection('users').doc(senderId).get();
      if (senderSnap.exists) {
        const senderData = senderSnap.data();
        senderName = senderData.first_name || senderData.display_name || senderData.name || 'Quelqu\'un';
      }
    } catch (_) {}

    // Notifier tous les participants sauf l'expéditeur
    const tokens = [];
    for (const uid of participants) {
      if (uid === senderId) continue;
      try {
        const userSnap = await db.collection('users').doc(uid).get();
        if (userSnap.exists) {
          const token = userSnap.data().fcmToken;
          if (token) tokens.push({ token, uid });
        }
      } catch (_) {}
    }

    if (tokens.length === 0) return;

    const notifTitle = isGroup ? `${senderName} dans ${chatName}` : senderName;
    const notifBody = previewText.length > 100 ? previewText.substring(0, 100) + '...' : previewText;

    // Envoyer les notifications en batch (max 500 par batch FCM)
    const messages = tokens.map(({ token }) => ({
      token,
      notification: {
        title: notifTitle,
        body: notifBody,
      },
      data: {
        chatId,
        type: 'chat_message',
        senderId,
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'chat_messages',
          priority: 'high',
          defaultSound: true,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    }));

    try {
      const batchResponse = await getMessaging().sendEach(messages);
      console.log(
        `sendChatNotification: sent=${batchResponse.successCount}, failed=${batchResponse.failureCount}`,
      );
    } catch (err) {
      console.error('sendChatNotification error:', err);
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// S2: Push notification pour les nouvelles demandes d'amis
// Trigger: nouveau document dans friend_requests/{requestId}
// ─────────────────────────────────────────────────────────────────────────────
exports.sendFriendRequestNotification = onDocumentCreated(
  'friend_requests/{requestId}',
  async (event) => {
    const requestData = event.data?.data();
    if (!requestData) return;

    const fromUid = requestData.fromUid || requestData.from;
    const toUid = requestData.toUid || requestData.to;
    if (!fromUid || !toUid) return;

    // Récupérer le nom de l'expéditeur
    let senderName = 'Quelqu\'un';
    try {
      const senderSnap = await db.collection('users').doc(fromUid).get();
      if (senderSnap.exists) {
        const data = senderSnap.data();
        senderName = data.first_name || data.display_name || data.name || 'Quelqu\'un';
      }
    } catch (_) {}

    // Récupérer le token FCM du destinataire
    let fcmToken = null;
    try {
      const toSnap = await db.collection('users').doc(toUid).get();
      if (toSnap.exists) {
        fcmToken = toSnap.data().fcmToken;
      }
    } catch (_) {}

    if (!fcmToken) return;

    try {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: 'Nouvelle demande d\'ami 👥',
          body: `${senderName} veut être votre ami sur Doron`,
        },
        data: {
          type: 'friend_request',
          fromUid,
          requestId: event.params.requestId,
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'social',
            priority: 'default',
            defaultSound: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      });
      console.log(`sendFriendRequestNotification: notified ${toUid} from ${senderName}`);
    } catch (err) {
      console.error('sendFriendRequestNotification error:', err);
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// S3: Push notification pour les invitations à collaborer
// Trigger: nouveau document dans collab_invites/{inviteId}
// (créé par CollaborationService.inviteUser quand l'ami n'est pas encore membre)
// ─────────────────────────────────────────────────────────────────────────────
exports.sendCollabInviteNotification = onDocumentCreated(
  'collab_invites/{inviteId}',
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const fromUid    = data.fromUid;
    const toUid      = data.toUid;
    const collabId   = data.collabId;
    const profileName = data.profileName || 'quelqu\'un';
    if (!fromUid || !toUid) return;

    // Nom de l'expéditeur
    let senderName = 'Quelqu\'un';
    try {
      const snap = await db.collection('users').doc(fromUid).get();
      if (snap.exists) {
        const d = snap.data();
        senderName = d.first_name || d.display_name || d.name || 'Quelqu\'un';
      }
    } catch (_) {}

    // Token FCM du destinataire
    let fcmToken = null;
    try {
      const snap = await db.collection('users').doc(toUid).get();
      if (snap.exists) fcmToken = snap.data().fcmToken;
    } catch (_) {}

    if (!fcmToken) return;

    // Récupérer le chatId lié à cette collaboration
    let chatId = '';
    try {
      const collabSnap = await db.collection('collaborations').doc(collabId).get();
      if (collabSnap.exists) chatId = collabSnap.data().chatId || '';
    } catch (_) {}

    try {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: '🎁 Nouvelle collaboration !',
          body: `${senderName} t'invite à collaborer sur la liste de cadeaux pour ${profileName}`,
        },
        data: {
          type: 'collab_invite',
          fromUid,
          collabId,
          chatId,
          profileName,
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'social',
            priority: 'high',
            defaultSound: true,
          },
        },
        apns: {
          payload: {
            aps: { sound: 'default', badge: 1 },
          },
        },
      });
      console.log(`sendCollabInviteNotification: notified ${toUid} from ${senderName} for collab ${collabId}`);
    } catch (err) {
      console.error('sendCollabInviteNotification error:', err);
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// S4: Push notification pour l'ajout direct comme membre d'une collaboration
// Trigger: nouveau document dans notifications/{uid}/items/{itemId}
//          où type == 'collab_invite' (écrit par _addFriendToCollab dans Flutter)
// ─────────────────────────────────────────────────────────────────────────────
exports.sendCollabMemberAddNotification = onDocumentCreated(
  'notifications/{uid}/items/{itemId}',
  async (event) => {
    const data = event.data?.data();
    if (!data || data.type !== 'collab_invite') return;

    const toUid      = event.params.uid;
    const fromUid    = data.fromUid;
    const collabId   = data.collabId;
    const profileName = data.profileName || 'quelqu\'un';
    const message    = data.message || '';
    if (!fromUid || !toUid) return;

    // Nom de l'expéditeur
    let senderName = 'Quelqu\'un';
    try {
      const snap = await db.collection('users').doc(fromUid).get();
      if (snap.exists) {
        const d = snap.data();
        senderName = d.first_name || d.display_name || d.name || 'Quelqu\'un';
      }
    } catch (_) {}

    // Token FCM du destinataire
    let fcmToken = null;
    try {
      const snap = await db.collection('users').doc(toUid).get();
      if (snap.exists) fcmToken = snap.data().fcmToken;
    } catch (_) {}

    if (!fcmToken) return;

    // Récupérer le chatId de la collaboration
    let chatId = '';
    try {
      if (collabId) {
        const collabSnap = await db.collection('collaborations').doc(collabId).get();
        if (collabSnap.exists) chatId = collabSnap.data().chatId || '';
      }
    } catch (_) {}

    try {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: '🎁 Ajouté à une liste de cadeaux !',
          body: message || `${senderName} t'a ajouté à la liste pour ${profileName}`,
        },
        data: {
          type: 'collab_invite',
          fromUid,
          collabId: collabId || '',
          chatId,
          profileName,
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'social',
            priority: 'high',
            defaultSound: true,
          },
        },
        apns: {
          payload: {
            aps: { sound: 'default', badge: 1 },
          },
        },
      });
      console.log(`sendCollabMemberAddNotification: notified ${toUid} added to collab by ${senderName}`);
    } catch (err) {
      console.error('sendCollabMemberAddNotification error:', err);
    }
  },
);

