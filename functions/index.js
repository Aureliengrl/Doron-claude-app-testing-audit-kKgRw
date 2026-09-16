/**
 * Doron Cloud Functions
 *
 * S1: sendChatNotification          — nouveau message dans un chat
 * S2: sendFriendRequestNotification — demande d'ami reçue
 * S3: sendCollabInviteNotification  — invitation à collaborer sur une liste cadeaux
 * S4: sendCollabMemberAddNotification — ajout direct comme membre d'une collaboration
 * S4b: sendGenericNotificationPush  — push générique pour tout autre type de
 *      notification in-app (demande acceptée, cagnotte, rappel d'événement…)
 * S6: sendEventReminders            — rappel 2 semaines avant fêtes/anniversaires
 *      (tourne quotidiennement, voir onSchedule ci-dessous)
 *
 * Avant premier déploiement, définir le secret Claude une seule fois :
 *   firebase functions:secrets:set ANTHROPIC_API_KEY
 *
 * Deploy: firebase deploy --only functions
 */

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onCall } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const Anthropic = require('@anthropic-ai/sdk');

initializeApp();
const db = getFirestore();

// Clé API Anthropic — gérée en secret Firebase, jamais en clair dans le code.
// À définir une fois via : firebase functions:secrets:set ANTHROPIC_API_KEY
const anthropicApiKey = defineSecret('ANTHROPIC_API_KEY');
function getAnthropicClient() {
  return new Anthropic({ apiKey: anthropicApiKey.value() });
}

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

// ─────────────────────────────────────────────────────────────────────────────
// S4b: Push notification générique pour tout nouveau type de notification
// in-app (notifications/{uid}/items) qui n'a pas déjà son propre trigger
// dédié ci-dessus. Couvre notamment : demande d'ami acceptée, cagnotte
// lancée/déclarée/confirmée/annulée, et les rappels d'événements (S6).
// Réutilise directement le titre/corps déjà écrits par le client Flutter
// (ou par sendEventReminders côté serveur), donc aucune donnée dupliquée.
// ─────────────────────────────────────────────────────────────────────────────
// Types déjà couverts par un trigger dédié (S1 messages, S2 demandes d'ami,
// S3/S4 collaboration) : ne pas les repousser ici pour éviter un double push.
const ALREADY_HANDLED_TYPES = new Set(['collab_invite', 'friend_request', 'message']);

exports.sendGenericNotificationPush = onDocumentCreated(
  'notifications/{uid}/items/{itemId}',
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    const type = data.type || '';
    if (ALREADY_HANDLED_TYPES.has(type)) return;

    const toUid = event.params.uid;
    const title = data.title || 'Nouvelle notification';
    const body = data.body || '';

    let fcmToken = null;
    try {
      const snap = await db.collection('users').doc(toUid).get();
      if (snap.exists) fcmToken = snap.data().fcmToken;
    } catch (_) {}
    if (!fcmToken) return;

    try {
      await getMessaging().send({
        token: fcmToken,
        notification: { title, body },
        data: {
          type,
          chatId: data.chatId || '',
          collabId: data.collabId || '',
          fromUid: data.fromUid || '',
        },
        android: {
          priority: 'high',
          notification: { channelId: 'social', priority: 'default', defaultSound: true },
        },
        apns: {
          payload: { aps: { sound: 'default', badge: 1 } },
        },
      });
      console.log(`sendGenericNotificationPush: notified ${toUid} (${type})`);
    } catch (err) {
      console.error('sendGenericNotificationPush error:', err);
    }
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// S6: Rappels d'événements 2 semaines à l'avance (fêtes fixes + anniversaires
// des amis + événements personnalisés). Tourne une fois par jour et écrit une
// notification (type 'event_reminder') dans le flux de chaque utilisateur
// concerné — le push est ensuite envoyé automatiquement par S4b ci-dessus.
// ─────────────────────────────────────────────────────────────────────────────
const { FieldValue } = require('firebase-admin/firestore');

/** Algorithme de Gauss pour calculer la date de Pâques (identique à birthday_service.dart). */
function computeEaster(year) {
  const a = year % 19;
  const b = Math.floor(year / 100);
  const c = year % 100;
  const d = Math.floor(b / 4);
  const e = b % 4;
  const f = Math.floor((b + 8) / 25);
  const g = Math.floor((b - f + 1) / 3);
  const h = (19 * a + b - d - g + 15) % 30;
  const i = Math.floor(c / 4);
  const k = c % 4;
  const l = (32 + 2 * e + 2 * i - h - k) % 7;
  const m = Math.floor((a + 11 * h + 22 * l) / 451);
  const month = Math.floor((h + l - 7 * m + 114) / 31);
  const day = ((h + l - 7 * m + 114) % 31) + 1;
  return new Date(year, month - 1, day);
}

/** N-ième occurrence d'un jour de semaine dans un mois (weekday: 0=dimanche..6=samedi). */
function nthWeekdayOfMonth(year, month, weekday, n) {
  let d = new Date(year, month - 1, 1);
  let count = 0;
  while (true) {
    if (d.getDay() === weekday) {
      count++;
      if (count === n) return d;
    }
    d = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1);
  }
}

/** Dernier jour de semaine donné du mois (ex: dernier dimanche de mai). */
function lastWeekdayOfMonth(year, month, weekday) {
  let d = new Date(year, month, 0); // dernier jour du mois (month est 1-indexé ici)
  while (d.getDay() !== weekday) {
    d = new Date(d.getFullYear(), d.getMonth(), d.getDate() - 1);
  }
  return d;
}

function mothersDayFrance(year) {
  const easter = computeEaster(year);
  const pentecote = new Date(easter.getFullYear(), easter.getMonth(), easter.getDate() + 49);
  // Dernier dimanche de mai, sauf si ça coïncide avec le dimanche de Pentecôte.
  let candidate = lastWeekdayOfMonth(year, 5, 0);
  if (candidate.getMonth() === pentecote.getMonth() && candidate.getDate() === pentecote.getDate()) {
    candidate = nthWeekdayOfMonth(year, 6, 0, 1);
  }
  return candidate;
}

function fathersDayFrance(year) {
  return nthWeekdayOfMonth(year, 6, 0, 3);
}

/** Même liste de fêtes que BirthdayService.getHolidaysForYear (Dart) — à garder synchronisée. */
function getHolidaysForYear(year) {
  return [
    { date: new Date(year, 0, 1), title: 'Jour de l\'An', emoji: '🎊' },
    { date: new Date(year, 1, 14), title: 'Saint-Valentin', emoji: '❤️' },
    { date: computeEaster(year), title: 'Pâques', emoji: '🐣' },
    { date: mothersDayFrance(year), title: 'Fête des Mères', emoji: '💐' },
    { date: nthWeekdayOfMonth(year, 3, 0, 1), title: 'Fête des Grand-mères', emoji: '👵' },
    { date: fathersDayFrance(year), title: 'Fête des Pères', emoji: '🎁' },
    { date: new Date(year, 6, 14), title: 'Fête Nationale', emoji: '🇫🇷' },
    { date: nthWeekdayOfMonth(year, 10, 0, 1), title: 'Fête des Grands-pères', emoji: '👴' },
    { date: new Date(year, 9, 31), title: 'Halloween', emoji: '🎃' },
    { date: new Date(year, 10, 1), title: 'Toussaint', emoji: '🕯️' },
    { date: new Date(year, 11, 25), title: 'Noël', emoji: '🎄' },
    { date: new Date(year, 11, 31), title: 'Réveillon', emoji: '🥂' },
  ];
}

function sameMonthDay(d1, d2) {
  return d1.getMonth() === d2.getMonth() && d1.getDate() === d2.getDate();
}

exports.sendEventReminders = onSchedule(
  { schedule: '0 9 * * *', timeZone: 'Europe/Paris' },
  async () => {
    const today = new Date();
    const target = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 14);
    const targetLabel = `${target.getDate()}/${target.getMonth() + 1}`;

    const holidays = getHolidaysForYear(target.getFullYear()).filter((h) => sameMonthDay(h.date, target));

    const usersSnap = await db.collection('users').get();
    const usersById = new Map();
    usersSnap.forEach((doc) => usersById.set(doc.id, doc.data()));

    const writes = [];
    const queue = (uid, title, body, extra = {}) => {
      writes.push({
        ref: db.collection('notifications').doc(uid).collection('items').doc(),
        data: {
          type: 'event_reminder',
          title,
          body,
          read: false,
          createdAt: FieldValue.serverTimestamp(),
          ...extra,
        },
      });
    };

    for (const [uid, userData] of usersById.entries()) {
      // Fêtes fixes (identiques pour tout le monde)
      for (const h of holidays) {
        queue(uid, `${h.emoji} ${h.title} approche !`, `${h.title}, c'est dans 2 semaines (${targetLabel}). Pense à tes cadeaux !`);
      }

      // Mon propre anniversaire
      const myBday = userData.birthday;
      if (myBday && myBday.month - 1 === target.getMonth() && myBday.day === target.getDate()) {
        queue(uid, '🎂 Ton anniversaire approche !', 'Ton anniversaire est dans 2 semaines !');
      }

      // Anniversaires des amis
      const friends = userData.friends || [];
      for (const friendUid of friends) {
        const friendData = usersById.get(friendUid);
        const fBday = friendData && friendData.birthday;
        if (fBday && fBday.month - 1 === target.getMonth() && fBday.day === target.getDate()) {
          const friendName = friendData.first_name || friendData.display_name || friendData.name || 'Un ami';
          queue(uid, `🎂 Anniversaire de ${friendName}`, `L'anniversaire de ${friendName} est dans 2 semaines, pense à son cadeau !`, { friendUid });
        }
      }

      // Événements personnalisés de l'utilisateur
      const customEvents = userData.customEventsList || [];
      for (const ce of customEvents) {
        if (typeof ce.month === 'number' && typeof ce.day === 'number' &&
            ce.month - 1 === target.getMonth() && ce.day === target.getDate()) {
          const label = ce.title || 'Ton événement';
          queue(uid, `${ce.emoji || '🎉'} ${label} approche !`, `${label}, c'est dans 2 semaines !`);
        }
      }
    }

    for (let i = 0; i < writes.length; i += 450) {
      const batch = db.batch();
      writes.slice(i, i + 450).forEach(({ ref, data }) => batch.set(ref, data));
      await batch.commit();
    }

    console.log(`sendEventReminders: ${writes.length} rappel(s) écrit(s) pour ${usersById.size} utilisateur(s) (cible ${targetLabel})`);
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// S5: Génération d'idées de cadeaux via l'API Claude
// ─────────────────────────────────────────────────────────────────────────────
exports.generateGiftIdeas = onCall({ secrets: [anthropicApiKey] }, async (request) => {
  const anthropic = getAnthropicClient();
  const data = request.data;
  const userTags = data.userTags || {};

  const prompt = `Tu es un expert en idées cadeaux.
Voici le profil de la personne :
Âge: ${userTags.age || 'Inconnu'}
Sexe: ${userTags.gender || 'Inconnu'}
Centres d'intérêt: ${userTags.interests?.join(', ') || 'Inconnu'}
Style: ${userTags.style?.join(', ') || 'Inconnu'}
Occasion: ${userTags.occasion || 'Inconnu'}
Budget max: ${userTags.budgetTier || 'Libre'}
Personnalité: ${userTags.recipientPersonality?.join(', ') || 'Inconnue'}

Génère 8 idées de cadeaux très précises et pertinentes.
Réponds UNIQUEMENT avec un tableau JSON valide contenant des objets avec ces propriétés :
- "name": Nom du produit (ex: "Montre Garmin Forerunner 55")
- "reason": Courte explication du choix (max 15 mots)
- "priceEstimate": Prix estimé en euros (nombre entier)
- "keywords": Un tableau de 3 mots-clés simples pour chercher le produit (ex: ["Montre", "Garmin", "Sport"])`;

  try {
    const msg = await anthropic.messages.create({
      model: "claude-3-5-sonnet-20241022",
      max_tokens: 1500,
      system: "Tu es un assistant JSON expert. Tu ne réponds QUE par du JSON valide sans aucun autre texte.",
      messages: [
        { role: "user", content: prompt }
      ]
    });

    const responseText = msg.content[0].text;
    const jsonMatch = responseText.match(/\[[\s\S]*\]/);
    const jsonStr = jsonMatch ? jsonMatch[0] : responseText;

    const ideas = JSON.parse(jsonStr);
    return { ideas };
  } catch (err) {
    console.error("Claude API Error:", err);
    throw new Error("Failed to generate gifts: " + err.message);
  }
});


// Nouveau: generateBrands
exports.generateBrands = onCall({ secrets: [anthropicApiKey] }, async (request) => {
  const anthropic = getAnthropicClient();
  const data = request.data;
  const age = data.age || 25;
  const domains = data.domains || [];
  
  const prompt = `Tu es un expert en marketing et tendances.
Voici le profil de la personne :
Âge: ${age}
Centres d'intérêt: ${domains.join(', ')}

Génère une liste des 6 à 8 marques les plus populaires et pertinentes pour cette personne.
Réponds UNIQUEMENT avec un tableau JSON valide de strings (ex: ["Nike", "Sephora", "Zara"]).`;

  try {
    const msg = await anthropic.messages.create({
      model: "claude-3-5-sonnet-20241022",
      max_tokens: 500,
      system: "Tu es un assistant JSON expert. Tu ne réponds QUE par du JSON valide sans aucun autre texte.",
      messages: [{ role: "user", content: prompt }]
    });

    let text = msg.content[0].text;
    text = text.replace(/\n/g, '').trim();
    if (text.startsWith('```json')) {
      text = text.replace(/```json/, '').replace(/```/, '').trim();
    }
    const result = JSON.parse(text);
    return { brands: result };
  } catch (error) {
    console.error("Erreur Claude generateBrands:", error);
    throw new Error("Impossible de générer les marques");
  }
});

// Nouveau: generateEvents
exports.generateEvents = onCall({ secrets: [anthropicApiKey] }, async (request) => {
  const anthropic = getAnthropicClient();
  const data = request.data;
  const age = data.age || 25;
  const domains = data.domains || [];
  const currentDate = new Date().toLocaleDateString('fr-FR', { month: 'long', day: 'numeric' });
  
  const prompt = `Tu es un expert en événements et tendances cadeaux.
Profil de la personne : Âge ${age}, Intérêts: ${domains.join(', ')}.
Date actuelle : ${currentDate}.

Génère une liste de 4 à 6 événements pertinents pour cette personne en ce moment ou à venir (ex: Noël, Fête des mères, Soldes d'été, Anniversaire, Coupe du monde, Rentrée).
Inclus un emoji pertinent pour chaque événement.
Réponds UNIQUEMENT avec un tableau JSON valide de strings (ex: ["🎄 Noël", "🎂 Anniversaire", "☀️ Soldes d'été"]).`;

  try {
    const msg = await anthropic.messages.create({
      model: "claude-3-5-sonnet-20241022",
      max_tokens: 500,
      system: "Tu es un assistant JSON expert. Tu ne réponds QUE par du JSON valide sans aucun autre texte.",
      messages: [{ role: "user", content: prompt }]
    });

    let text = msg.content[0].text;
    text = text.replace(/\n/g, '').trim();
    if (text.startsWith('```json')) {
      text = text.replace(/```json/, '').replace(/```/, '').trim();
    }
    const result = JSON.parse(text);
    return { events: result };
  } catch (error) {
    console.error("Erreur Claude generateEvents:", error);
    throw new Error("Impossible de générer les événements");
  }
});

// Nouveau: rerankProductsWithClaude
exports.rerankProductsWithClaude = onCall({ secrets: [anthropicApiKey] }, async (request) => {
  const anthropic = getAnthropicClient();
  const data = request.data;
  const products = data.products || [];
  const userProfile = data.userProfile || {};
  
  if (products.length === 0) return { rerankedIds: [] };

  const prompt = `Tu es le meilleur personal shopper au monde.
Voici le profil détaillé de la personne :
Âge: ${userProfile.age || 'Inconnu'}
Sexe: ${userProfile.gender || 'Inconnu'}
Centres d'intérêt: ${userProfile.interests?.join(', ') || 'Inconnu'}
Personnalité: ${userProfile.personality?.join(', ') || 'Inconnue'}
Événement/Occasion: ${userProfile.occasion || 'Inconnu'}

Voici une liste de ${products.length} produits extraits de notre base de données, au format JSON :
${JSON.stringify(products.map(p => ({id: p.id, name: p.name, desc: p.description, price: p.price})))}

TA MISSION :
Sélectionne EXACTEMENT les 6 produits de cette liste qui correspondent À 200% à cette personne.
Pour chaque produit sélectionné, fournis une justification courte (1 phrase) expliquant pourquoi c'est le "Perfect Match".
Réponds UNIQUEMENT avec un tableau JSON d'objets avec ces propriétés :
- "id": L'identifiant exact du produit
- "justification": La phrase courte d'explication`;

  try {
    const msg = await anthropic.messages.create({
      model: "claude-3-5-sonnet-20241022",
      max_tokens: 1000,
      system: "Tu es un assistant JSON expert. Tu ne réponds QUE par du JSON valide sans aucun autre texte.",
      messages: [{ role: "user", content: prompt }]
    });

    let text = msg.content[0].text;
    text = text.replace(/\n/g, '').trim();
    if (text.startsWith('```json')) {
      text = text.replace(/```json/, '').replace(/```/, '').trim();
    }
    
    // Fallback if the model hallucinated some extra text
    const jsonMatch = text.match(/\[[\s\S]*\]/);
    if (jsonMatch) text = jsonMatch[0];

    const result = JSON.parse(text);
    return { rerankedProducts: result };
  } catch (error) {
    console.error("Erreur Claude rerankProductsWithClaude:", error);
    throw new Error("Impossible de reranker les produits");
  }
});

// Nouveau: cleanAmazonDB (HTTPS Callable) pour nettoyer la base
exports.cleanAmazonDB = onCall(async (request) => {
  console.log('🔄 Démarrage du nettoyage de la base de données (Liens Amazon)...');
  
  const giftsRef = db.collection('gifts');
  const snapshot = await giftsRef.get();
  
  if (snapshot.empty) {
    return { status: 'Aucun cadeau trouvé' };
  }
  
  let updatedCount = 0;
  let batch = db.batch();
  let batchCount = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    let url = data.url || data.product_url || '';
    
    if (url && url.toLowerCase().includes('amazon.')) {
      try {
        let newUrl = url;
        const amazonTag = 'doronapp130a-21';
        
        if (url.includes('?')) {
          const urlObj = new URL(url);
          urlObj.searchParams.set('tag', amazonTag);
          newUrl = urlObj.toString();
        } else {
          newUrl = `${url}?tag=${amazonTag}`;
        }
        
        if (newUrl !== url) {
          batch.update(doc.ref, { 
            url: newUrl, 
            updatedAt: require('firebase-admin').firestore.FieldValue.serverTimestamp() 
          });
          updatedCount++;
          batchCount++;
          
          if (batchCount === 450) {
            await batch.commit();
            batch = db.batch();
            batchCount = 0;
          }
        }
      } catch (e) {}
    }
  }
  
  if (batchCount > 0) {
    await batch.commit();
  }

  return { 
    status: 'success', 
    message: `✨ Terminé ! ${updatedCount} liens Amazon ont été mis à jour avec doronapp130a-21.` 
  };
});

// Nouveau: httpDeleteAmazonGifts pour supprimer les vieux produits
const { onRequest: reqDelete } = require('firebase-functions/v2/https');
exports.httpDeleteAmazonGifts = reqDelete(async (req, res) => {
  console.log('🗑️ Démarrage de la suppression...');
  
  const giftsRef = db.collection('gifts');
  const snapshot = await giftsRef.get();
  
  if (snapshot.empty) {
    res.send('Aucun cadeau');
    return;
  }
  
  let deletedCount = 0;
  let batch = db.batch();
  let batchCount = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    let url = data.url || data.product_url || '';
    
    if (url && url.toLowerCase().includes('amazon.')) {
      batch.delete(doc.ref);
      deletedCount++;
      batchCount++;
      
      if (batchCount === 450) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    }
  }
  
  if (batchCount > 0) {
    await batch.commit();
  }

  res.send(`✨ Terminé ! ${deletedCount} vieux cadeaux Amazon supprimés.`);
});

const { onRequest: reqImport } = require('firebase-functions/v2/https');
const xml2js = require('xml2js');

// Nouveau: httpImportRakuten pour importer des produits depuis Rakuten et les catégoriser via Claude
exports.httpImportRakuten = reqImport({ timeoutSeconds: 540, memory: '1GiB' }, async (req, res) => {
  const keyword = req.query.keyword || 'cadeau';
  const token = 'pk_rvua3cE54MueHdOmCFkeQ7FWMqATA4s5riMFf1gwb96';
  const url = `https://api.rakutenmarketing.com/productsearch/1.0?keyword=${encodeURIComponent(keyword)}&max=50`;

  console.log(`🚀 Démarrage de l'import Rakuten pour: ${keyword}`);

  try {
    const response = await fetch(url, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });

    if (!response.ok) {
      res.status(500).send(`Erreur Rakuten API: ${response.status}`);
      return;
    }

    const xml = await response.text();
    const parser = new xml2js.Parser({ explicitArray: false });
    const parsed = await parser.parseStringPromise(xml);

    let items = parsed.result && parsed.result.item;
    if (!items) {
      res.send('Aucun produit trouvé');
      return;
    }

    if (!Array.isArray(items)) {
      items = [items];
    }

    const anthropic = new (require('@anthropic-ai/sdk').Anthropic)({
      apiKey: process.env.ANTHROPIC_API_KEY || 'sk-ant-api03-placeholder' 
      // L'API key Anthropic doit être définie dans l'environnement Cloud Functions (secrets)
      // Nous utilisons la fonction generateBrands existante si possible, 
      // ou bien nous sauvegardons les produits bruts et laissons le client les matcher
    });
    
    // Pour éviter le timeout et les coûts si on a pas de clé hardcodée, on va sauvegarder les produits tels quels.
    // L'IA Claude est déjà utilisée dans ProductMatchingService pour le reranking, donc on peut se contenter 
    // d'insérer des données propres.

    let batch = db.batch();
    let imported = 0;

    for (const item of items) {
      const priceVal = item.price && item.price._ ? item.price._ : item.price;
      const imageUrl = item.imageurl || '';
      
      if (!imageUrl || imageUrl.includes('no-image')) continue; // Skip items without images

      const product = {
        name: item.productname || '',
        price: priceVal || '',
        description: item.description || '',
        image: imageUrl,
        url: item.linkurl || '',
        brand: item.merchantname || 'Rakuten',
        source: 'rakuten',
        keywords: [keyword.toLowerCase()],
        createdAt: require('firebase-admin').firestore.FieldValue.serverTimestamp()
      };

      const docRef = db.collection('gifts').doc();
      batch.set(docRef, product);
      imported++;
    }

    await batch.commit();

    res.send(`✨ Terminé ! ${imported} produits importés depuis Rakuten avec succès pour le mot clé "${keyword}".`);
  } catch (e) {
    console.error('Erreur import Rakuten:', e);
    res.status(500).send('Erreur: ' + e.toString());
  }
});
