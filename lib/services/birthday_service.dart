import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service gérant les anniversaires et les fêtes importantes
/// F3: Utilisé par la BirthdayCalendarPage et le profil public
class BirthdayService {
  static final _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────────────────────────────
  // Sauvegarde / lecture de l'anniversaire d'un utilisateur
  // Stocké sans l'année pour respecter la vie privée (RGPD)
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> saveBirthday(int day, int month) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set({
      'birthday': {'day': day, 'month': month}
    }, SetOptions(merge: true));
  }

  static Future<Map<String, int>?> getMyBirthday() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return getBirthday(uid);
  }

  static Future<Map<String, int>?> getBirthday(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      final b = doc.data()?['birthday'] as Map<String, dynamic>?;
      if (b == null) return null;
      return {'day': (b['day'] as num).toInt(), 'month': (b['month'] as num).toInt()};
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Anniversaires des amis
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getFriendsBirthdays() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      final friends = List<String>.from(userDoc.data()?['friends'] ?? []);
      if (friends.isEmpty) return [];

      // FIX F8: Parallélisation — avant: N requêtes séquentielles (1 par ami)
      // Après: toutes lancées simultanément → temps = max(1 requête) au lieu de somme
      final docs = await Future.wait(
        friends.map((friendUid) => _db.collection('users').doc(friendUid).get()),
      );

      final result = <Map<String, dynamic>>[];
      for (final doc in docs) {
        if (!doc.exists) continue;
        final data = doc.data()!;
        final b = data['birthday'] as Map<String, dynamic>?;
        if (b == null) continue;
        result.add({
          'uid': doc.id,
          'name': data['first_name'] ?? data['display_name'] ?? 'Ami',
          'handle': data['handle'] ?? '',
          'photoUrl': data['photoUrl'] ?? '',
          'day': (b['day'] as num).toInt(),
          'month': (b['month'] as num).toInt(),
        });
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Génération des fêtes importantes pour une année donnée
  // ─────────────────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> getHolidaysForYear(int year) {
    // Calcul de Pâques (algorithme de Gauss anonyme)
    final easter = _computeEaster(year);
    final easterMs = easter.millisecondsSinceEpoch;

    return [
      _holiday(year, 1, 1,  'Jour de l\'An', '🎊'),
      _holiday(year, 2, 14, 'Saint-Valentin', '❤️'),
      // Mardi Gras = 47 jours avant Pâques
      {'date': DateTime.fromMillisecondsSinceEpoch(easterMs - 47 * 86400000), 'title': 'Mardi Gras', 'emoji': '🎭', 'type': 'holiday'},
      // Pâques (dimanche)
      {'date': easter, 'title': 'Pâques', 'emoji': '🐣', 'type': 'holiday'},
      // Lundi de Pâques
      {'date': DateTime.fromMillisecondsSinceEpoch(easterMs + 86400000), 'title': 'Lundi de Pâques', 'emoji': '🐣', 'type': 'holiday'},
      _holiday(year, 5, 1,  'Fête du Travail', '💼'),
      _holiday(year, 5, 8,  'Victoire 1945', '🕊️'),
      // Ascension = 39 jours après Pâques
      {'date': DateTime.fromMillisecondsSinceEpoch(easterMs + 39 * 86400000), 'title': 'Ascension', 'emoji': '✨', 'type': 'holiday'},
      // Fête des Mères = 2e dimanche de mai (ou 1er dimanche de juin si Pentecôte)
      {'date': _mothersDayFrance(year), 'title': 'Fête des Mères', 'emoji': '👩', 'type': 'holiday'},
      // Pentecôte = 49 jours après Pâques
      {'date': DateTime.fromMillisecondsSinceEpoch(easterMs + 49 * 86400000), 'title': 'Pentecôte', 'emoji': '☁️', 'type': 'holiday'},
      // Lundi de Pentecôte
      {'date': DateTime.fromMillisecondsSinceEpoch(easterMs + 50 * 86400000), 'title': 'Lundi de Pentecôte', 'emoji': '☁️', 'type': 'holiday'},
      _holiday(year, 6, 21, 'Fête de la Musique', '🎵'),
      // Fête des Pères = 3e dimanche de juin
      {'date': _fathersDayFrance(year), 'title': 'Fête des Pères', 'emoji': '👨', 'type': 'holiday'},
      _holiday(year, 7, 14, 'Fête Nationale', '🇫🇷'),
      _holiday(year, 10, 31,'Halloween', '🎃'),
      _holiday(year, 11, 1, 'Toussaint', '🕯️'),
      _holiday(year, 11, 11,'Armistice', '🕊️'),
      _holiday(year, 12, 25,'Noël', '🎄'),
      _holiday(year, 12, 31,'Réveillon', '🥂'),
    ];
  }

  static Map<String, dynamic> _holiday(int year, int month, int day, String title, String emoji) {
    return {
      'date': DateTime(year, month, day),
      'title': title,
      'emoji': emoji,
      'type': 'holiday',
    };
  }

  /// Algorithme de Gauss pour calculer la date de Pâques
  static DateTime _computeEaster(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  /// Fête des Mères en France: 2e dimanche de mai
  /// Sauf si coïncide avec Pentecôte → 1er dimanche de juin
  static DateTime _mothersDayFrance(int year) {
    final easter = _computeEaster(year);
    final pentecote = easter.add(const Duration(days: 49));

    DateTime candidate = _nthWeekdayOfMonth(year, 5, DateTime.sunday, 2);
    if (candidate.month == pentecote.month &&
        candidate.day == pentecote.day) {
      // Décalage au 1er dimanche de juin
      candidate = _nthWeekdayOfMonth(year, 6, DateTime.sunday, 1);
    }
    return candidate;
  }

  /// Fête des Pères en France: 3e dimanche de juin
  static DateTime _fathersDayFrance(int year) {
    return _nthWeekdayOfMonth(year, 6, DateTime.sunday, 3);
  }

  /// Retourne le Nième jour de la semaine du mois donné
  static DateTime _nthWeekdayOfMonth(int year, int month, int weekday, int n) {
    DateTime d = DateTime(year, month, 1);
    int count = 0;
    while (true) {
      if (d.weekday == weekday) {
        count++;
        if (count == n) return d;
      }
      d = d.add(const Duration(days: 1));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Construire la map des événements pour TableCalendar
  // ─────────────────────────────────────────────────────────────────────────

  /// Retourne une Map<DateTime, List<CalendarEvent>> pour l'année en cours et suivante
  static Future<Map<DateTime, List<CalendarEvent>>> buildCalendarEvents() async {
    final now = DateTime.now();
    final Map<DateTime, List<CalendarEvent>> events = {};

    void addEvent(DateTime date, CalendarEvent event) {
      final key = DateTime(date.year, date.month, date.day);
      events[key] = [...(events[key] ?? []), event];
    }

    // 1. Mon anniversaire
    final myBirthday = await getMyBirthday();
    if (myBirthday != null) {
      for (final y in [now.year, now.year + 1]) {
        addEvent(DateTime(y, myBirthday['month']!, myBirthday['day']!),
          CalendarEvent(title: 'Mon anniversaire 🎂', type: EventType.myBirthday, emoji: '🎂'));
      }
    }

    // 2. Anniversaires des amis
    final friendsBirthdays = await getFriendsBirthdays();
    for (final friend in friendsBirthdays) {
      for (final y in [now.year, now.year + 1]) {
        final d = DateTime(y, friend['month'] as int, friend['day'] as int);
        addEvent(d, CalendarEvent(
          title: '${friend['name']} 🎁',
          type: EventType.friendBirthday,
          emoji: '🎁',
          uid: friend['uid'] as String,
          friendName: friend['name'] as String,
          friendPhotoUrl: friend['photoUrl'] as String,
        ));
      }
    }

    // 3. Fêtes importantes
    for (final y in [now.year, now.year + 1]) {
      final holidays = getHolidaysForYear(y);
      for (final h in holidays) {
        final date = h['date'] as DateTime;
        addEvent(date, CalendarEvent(
          title: '${h['emoji']} ${h['title']}',
          type: EventType.holiday,
          emoji: h['emoji'] as String,
        ));
      }
    }

    return events;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Types de données du calendrier
// ─────────────────────────────────────────────────────────────────────────────

enum EventType { myBirthday, friendBirthday, holiday }

class CalendarEvent {
  final String title;
  final EventType type;
  final String emoji;
  final String? uid;
  final String? friendName;
  final String? friendPhotoUrl;

  const CalendarEvent({
    required this.title,
    required this.type,
    required this.emoji,
    this.uid,
    this.friendName,
    this.friendPhotoUrl,
  });

  Color get color {
    switch (type) {
      case EventType.myBirthday:
        return const Color(0xFF8A2BE2);
      case EventType.friendBirthday:
        return const Color(0xFFEC4899);
      case EventType.holiday:
        return const Color(0xFFF59E0B);
    }
  }
}
