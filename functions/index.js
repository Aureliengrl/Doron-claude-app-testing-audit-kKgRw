/**
 * Doron Cloud Functions
 * 
 * S1: sendChatNotification  — notifie les destinataires lors d'un nouveau message
 * S2: sendFriendRequestNotification — notifie l'utilisateur cible lors d'une demande d'ami
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
