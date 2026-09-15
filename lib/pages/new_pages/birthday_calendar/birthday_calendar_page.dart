import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '/services/birthday_service.dart';
import '/utils/app_tr.dart';
import '/components/liquid_glass.dart';
import '/components/micro_interactions.dart' as micro;
import '/components/floating_cta_button.dart';

class BirthdayCalendarPage extends StatefulWidget {
  const BirthdayCalendarPage({super.key});

  static const String routeName = 'BirthdayCalendar';
  static const String routePath = '/birthday-calendar';

  @override
  State<BirthdayCalendarPage> createState() => _BirthdayCalendarPageState();
}

class _BirthdayCalendarPageState extends State<BirthdayCalendarPage> {
  static const _violet = Color(0xFF8A2BE2);
  static const _pink = Color(0xFFEC4899);
  static const _gold = Color(0xFFF59E0B);
  static const _cyan = Color(0xFF06B6D4);

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<CalendarEvent>> _events = {};
  bool _isLoading = true;
  bool _isAppleCalendarConnected = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadEvents();
    _checkAppleCalendarStatus();
  }

  Future<void> _checkAppleCalendarStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isAppleCalendarConnected = prefs.getBool('apple_calendar_connected') ?? false;
      });
    }
  }

  Future<void> _loadEvents() async {
    final events = await BirthdayService.buildCalendarEvents();
    if (mounted) {
      setState(() {
        _events = events;
        _isLoading = false;
      });
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  void _showAppleCalendarDialog() async {
    HapticFeedback.mediumImpact();
    
    // Tente de déclencher la demande de permission système native si disponible
    try {
      await Permission.calendarFullAccess.request();
    } catch (_) {}

    if (!mounted) return;

    final accepted = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text(
          '« Doron » souhaite accéder à vos Calendriers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'Doron utilisera vos calendriers pour synchroniser automatiquement les dates d\'anniversaires et événements de vos proches.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Ne pas autoriser'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Autoriser'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (accepted == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('apple_calendar_connected', true);
      if (mounted) {
        setState(() {
          _isAppleCalendarConnected = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.apple, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Calendrier Apple synchronisé avec succès !',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: _pink),
                  ),
                )
              else ...[
                SliverToBoxAdapter(child: _buildCalendar()),
                SliverToBoxAdapter(child: _buildLegend()),
                SliverToBoxAdapter(child: _buildSelectedDayEvents()),
                SliverToBoxAdapter(child: _buildUpcomingSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 180)),
              ],
            ],
          ),
          if (!_isAppleCalendarConnected)
            Positioned(
              bottom: 76,
              left: 0,
              right: 0,
              child: FloatingCtaButton(
                title: 'Connecter Apple Calendar',
                icon: Icons.apple,
                onTap: _showAppleCalendarDialog,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8A2BE2),
            Color(0xFFEC4899),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A2BE2).withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFFEC4899).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                  tooltip: 'Ajouter un événement',
                  onPressed: _showAddChoiceSheet,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  micro.ShimmerEffect(
                    shimmerColor: Colors.white,
                    duration: const Duration(milliseconds: 3000),
                    child: Text(
                      context.tr('Calendrier', 'Calendar'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('N\'oubliez plus aucun événement !', 'Never miss an event or birthday!'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: LiquidGlassCard(
        child: TableCalendar<CalendarEvent>(
          firstDay: DateTime(DateTime.now().year - 1, 1, 1),
          lastDay: DateTime(DateTime.now().year + 2, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
          eventLoader: _getEventsForDay,
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          locale: context.isEn ? 'en_US' : 'fr_FR',

          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            weekendTextStyle: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
            defaultTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            selectedDecoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_violet, _pink]),
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              border: Border.all(color: _violet, width: 2),
              shape: BoxShape.circle,
            ),
            todayTextStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
            selectedTextStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
            markerDecoration: const BoxDecoration(color: Colors.transparent),
            markersMaxCount: 4,
          ),

          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
            rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
            headerPadding: const EdgeInsets.symmetric(vertical: 12),
          ),

          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: GoogleFonts.poppins(
              color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
            weekendStyle: GoogleFonts.poppins(
              color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500),
          ),

          calendarBuilders: CalendarBuilders(
            markerBuilder: (ctx, day, events) {
              if (events.isEmpty) return const SizedBox.shrink();
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: events.take(4).map((e) {
                  return Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: e.color.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              );
            },
          ),

          onDaySelected: (selected, focused) {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
          },
          onPageChanged: (focused) => setState(() => _focusedDay = focused),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _legendDot(_violet, context.tr('Mon anniversaire', 'My birthday')),
            const SizedBox(width: 14),
            _legendDot(_pink, context.tr('Anniversaire de mes amis', 'Friends\' birthdays')),
            const SizedBox(width: 14),
            _legendDot(_cyan, context.tr('Mes événements', 'My events')),
            const SizedBox(width: 14),
            _legendDot(_gold, context.tr('Événements', 'Events')),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11.5, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSelectedDayEvents() {
    if (_selectedDay == null) return const SizedBox.shrink();
    final events = _getEventsForDay(_selectedDay!);
    if (events.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatSelectedDate(_selectedDay!),
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...events.map((e) => _buildEventTile(e)),
        ],
      ),
    );
  }

  String _formatSelectedDate(DateTime d) {
    const months = ['', 'jan', 'fév', 'mar', 'avr', 'mai', 'juin', 'juil', 'août', 'sep', 'oct', 'nov', 'déc'];
    const days = ['', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return '${days[d.weekday]} ${d.day} ${months[d.month]} ${d.year}';
  }

  Widget _buildEventTile(CalendarEvent event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: LiquidGlassCard(
        tintColor: event.color.withOpacity(0.08),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (event.type == EventType.friendBirthday && event.friendPhotoUrl != null && event.friendPhotoUrl!.isNotEmpty)
              CircleAvatar(
                radius: 20,
                backgroundImage: CachedNetworkImageProvider(event.friendPhotoUrl!),
              )
            else
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: event.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(event.emoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                event.title,
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ),
            if (event.type == EventType.friendBirthday && event.uid != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/public-profile/${event.uid}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_violet, _pink]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Voir',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
            if (event.type == EventType.customEvent && event.id != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white54, size: 20),
                tooltip: 'Supprimer',
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await BirthdayService.deleteCustomEvent(event.id!);
                  _loadEvents();
                },
              ),
            ],
            if (event.type == EventType.holiday) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  final prefs = await SharedPreferences.getInstance();
                  String eventId = 'all';
                  final title = event.title.toLowerCase();
                  
                  if (title.contains('valentin')) eventId = 'st_valentin';
                  else if (title.contains('nationale')) eventId = 'fete_nationale';
                  else if (title.contains('noël') || title.contains('noel')) eventId = 'noel';
                  else if (title.contains('mères')) eventId = 'fete_meres';
                  else if (title.contains('pères')) eventId = 'fete_peres';
                  else if (title.contains('musique')) eventId = 'fete_musique';
                  else if (title.contains('grand')) eventId = 'fete_grand_meres';
                  else if (title.contains('halloween')) eventId = 'halloween';
                  else if (title.contains('saint patrick')) eventId = 'saint_patrick';
                  else if (title.contains('monde')) eventId = 'world_cup';
                  
                  if (eventId != 'all') {
                    await prefs.setString('pending_event_filter', eventId);
                  }
                  
                  if (mounted) {
                    context.go('/home-pinterest');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.15),
                    border: Border.all(color: _gold.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Idées',
                    style: GoogleFonts.poppins(color: _gold, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingSection() {
    final now = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final upcoming = <MapEntry<DateTime, List<CalendarEvent>>>[];

    // Trier toutes les dates futures de l'année
    final sortedKeys = _events.keys.toList()..sort();
    for (final date in sortedKeys) {
      if (!date.isBefore(now)) {
        upcoming.add(MapEntry(date, _events[date]!));
      }
    }

    if (upcoming.isEmpty) return const SizedBox.shrink();

    // Prendre les 8 prochains événements pour une vue toujours riche
    final displayedUpcoming = upcoming.take(8).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note_rounded, color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 8),
              Text(
                'Prochains événements',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...displayedUpcoming.expand((entry) {
            const months = ['', 'jan', 'fév', 'mar', 'avr', 'mai', 'juin', 'juil', 'août', 'sep', 'oct', 'nov', 'déc'];
            final diff = entry.key.difference(now).inDays;
            final label = diff == 0
                ? 'Aujourd\'hui ! 🎉'
                : diff == 1
                    ? 'Demain'
                    : 'Dans $diff jours';
            return entry.value.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LiquidGlassCard(
                tintColor: e.color.withOpacity(0.08),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: e.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: e.color.withOpacity(0.3)),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${entry.key.day}',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            months[entry.key.month],
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{27BF}\u{1F1E6}-\u{1F1FF}]', unicode: true), '').trim(),
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            label.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{27BF}\u{1F1E6}-\u{1F1FF}]', unicode: true), '').trim(),
                            style: GoogleFonts.poppins(color: e.color, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        final prefs = await SharedPreferences.getInstance();
                        String eventId = 'all';
                        final title = e.title.toLowerCase();
                        if (title.contains('valentin')) eventId = 'st_valentin';
                        else if (title.contains('nationale')) eventId = 'fete_nationale';
                        else if (title.contains('noël') || title.contains('noel')) eventId = 'noel';
                        else if (title.contains('mères')) eventId = 'fete_meres';
                        else if (title.contains('pères')) eventId = 'fete_peres';
                        else if (title.contains('musique')) eventId = 'fete_musique';
                        else if (title.contains('grand')) eventId = 'fete_grand_meres';
                        else if (title.contains('halloween')) eventId = 'halloween';
                        else if (title.contains('saint patrick')) eventId = 'saint_patrick';
                        else if (title.contains('monde')) eventId = 'world_cup';
                        if (eventId != 'all') {
                          await prefs.setString('pending_event_filter', eventId);
                        }
                        if (mounted) {
                          context.go('/home-pinterest');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _pink.withOpacity(0.15),
                          border: Border.all(color: _pink.withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.card_giftcard_rounded, color: _pink, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              'Idées',
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ));
          }).toList(),
        ],
      ),
    );
  }

  void _showAddChoiceSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A0030),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 18),
            Text(
              context.tr('Ajouter au calendrier', 'Add to calendar'),
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _violet.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('🎂', style: TextStyle(fontSize: 22))),
              ),
              title: Text(
                context.tr('Mon anniversaire', 'My birthday'),
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: Text(
                context.tr('Renseignez votre date de naissance', 'Set your birth date'),
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                _showAddBirthdaySheet();
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _pink.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('🎁', style: TextStyle(fontSize: 22))),
              ),
              title: Text(
                context.tr('Anniversaire d\'un proche', 'Friend / Relative birthday'),
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: Text(
                context.tr('Ami, parent, oncle, conjoint...', 'Friend, parent, uncle, spouse...'),
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                _showAddFriendBirthdaySheet();
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _cyan.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('🎉', style: TextStyle(fontSize: 22))),
              ),
              title: Text(
                context.tr('Nouvel événement personnalisé', 'New custom event'),
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: Text(
                context.tr('Soirée amis, pendaison de crémaillère, fête...', 'Friend gathering, housewarming, party...'),
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                _showAddCustomEventSheet();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFriendBirthdaySheet() {
    int selectedDay = 1;
    int selectedMonth = 1;
    String selectedRelation = 'Ami(e)';
    final nameController = TextEditingController();
    final relations = ['Ami(e)', 'Famille', 'Parent', 'Oncle / Tante', 'Conjoint(e)', 'Collègue'];
    const months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A0030),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Text(
                    'Anniversaire d\'un proche',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Prénom ou nom', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                autofocus: true,
                cursorColor: _pink,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ex: Alexandre, Oncle Marc, Maman...',
                  hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF100720),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _pink, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 14),
              Text('Lien / Relation', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: relations.map((rel) {
                  final isSel = selectedRelation == rel;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedRelation = rel),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? _pink : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSel ? _pink : Colors.white24),
                      ),
                      child: Text(
                        rel,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: isSel ? FontWeight.w600 : FontWeight.normal),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Date de naissance', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedDay,
                          dropdownColor: const Color(0xFF2D0845),
                          items: List.generate(31, (i) => i + 1).map((d) => DropdownMenuItem(value: d, child: Text('$d', style: const TextStyle(color: Colors.white)))).toList(),
                          onChanged: (v) => setModalState(() => selectedDay = v ?? 1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedMonth,
                          dropdownColor: const Color(0xFF2D0845),
                          items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m, child: Text(months[m - 1], style: const TextStyle(color: Colors.white)))).toList(),
                          onChanged: (v) => setModalState(() => selectedMonth = v ?? 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(ctx);
                    try {
                      await BirthdayService.saveCustomEvent(
                        title: 'Anniv $name ($selectedRelation)',
                        emoji: '🎁',
                        day: selectedDay,
                        month: selectedMonth,
                      );
                      _loadEvents();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF1E1435),
                            content: Text('Anniversaire de $name ajouté ! 🎁', style: GoogleFonts.poppins(color: Colors.white)),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Erreur ajout anniversaire: $e');
                    }
                  },
                  child: Text('Enregistrer l\'anniversaire', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCustomEventSheet() {
    int selectedMonth = _selectedDay?.month ?? DateTime.now().month;
    int selectedDay = _selectedDay?.day ?? DateTime.now().day;
    String selectedEmoji = '🎉';
    final titleController = TextEditingController();
    const emojis = ['🎉', '🎁', '🎂', '🍕', '🥂', '🎃', '🎄', '💍', '🏡', '✈️', '🎮', '🏖️'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A0030),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  context.tr('Créer un événement', 'Create an event'),
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Text(context.tr('Nom de l\'événement', 'Event title'), style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: titleController,
                cursorColor: _cyan,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ex: Soirée avec mes amis, Pendaison de crémaillère...',
                  hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF100720),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _cyan, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 14),
              Text(context.tr('Choisir un emoji', 'Choose an emoji'), style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: emojis.map((e) {
                    final isSelected = e == selectedEmoji;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedEmoji = e),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? _cyan.withOpacity(0.3) : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? _cyan : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 20)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jour', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButton<int>(
                            value: selectedDay,
                            dropdownColor: const Color(0xFF1A0030),
                            underline: const SizedBox(),
                            isExpanded: true,
                            style: GoogleFonts.poppins(color: Colors.white),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            items: List.generate(31, (i) => i + 1).map((d) => DropdownMenuItem(
                              value: d,
                              child: Text('$d'),
                            )).toList(),
                            onChanged: (v) => setSheetState(() => selectedDay = v!),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mois', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButton<int>(
                            value: selectedMonth,
                            dropdownColor: const Color(0xFF1A0030),
                            underline: const SizedBox(),
                            isExpanded: true,
                            style: GoogleFonts.poppins(color: Colors.white),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('Janvier')),
                              DropdownMenuItem(value: 2, child: Text('Février')),
                              DropdownMenuItem(value: 3, child: Text('Mars')),
                              DropdownMenuItem(value: 4, child: Text('Avril')),
                              DropdownMenuItem(value: 5, child: Text('Mai')),
                              DropdownMenuItem(value: 6, child: Text('Juin')),
                              DropdownMenuItem(value: 7, child: Text('Juillet')),
                              DropdownMenuItem(value: 8, child: Text('Août')),
                              DropdownMenuItem(value: 9, child: Text('Septembre')),
                              DropdownMenuItem(value: 10, child: Text('Octobre')),
                              DropdownMenuItem(value: 11, child: Text('Novembre')),
                              DropdownMenuItem(value: 12, child: Text('Décembre')),
                            ],
                            onChanged: (v) => setSheetState(() => selectedMonth = v!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_cyan, Color(0xFF3B82F6)]),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextButton(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;
                      await BirthdayService.saveCustomEvent(
                        title: title,
                        day: selectedDay,
                        month: selectedMonth,
                        emoji: selectedEmoji,
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        _loadEvents();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Événement ajouté ! 🎉', style: GoogleFonts.poppins()),
                          backgroundColor: _cyan,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ));
                      }
                    },
                    child: Text(context.tr('Créer l\'événement', 'Create event'), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddBirthdaySheet() {
    int selectedMonth = DateTime.now().month;
    int selectedDay = DateTime.now().day;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A0030),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Mon anniversaire 🎂', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Seuls le jour et le mois sont enregistrés', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('Jour', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButton<int>(
                            value: selectedDay,
                            dropdownColor: const Color(0xFF1A0030),
                            underline: const SizedBox(),
                            isExpanded: true,
                            style: GoogleFonts.poppins(color: Colors.white),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            items: List.generate(31, (i) => i + 1).map((d) => DropdownMenuItem(
                              value: d,
                              child: Text('$d'),
                            )).toList(),
                            onChanged: (v) => setSheetState(() => selectedDay = v!),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Mois', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButton<int>(
                            value: selectedMonth,
                            dropdownColor: const Color(0xFF1A0030),
                            underline: const SizedBox(),
                            isExpanded: true,
                            style: GoogleFonts.poppins(color: Colors.white),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('Janvier')),
                              DropdownMenuItem(value: 2, child: Text('Février')),
                              DropdownMenuItem(value: 3, child: Text('Mars')),
                              DropdownMenuItem(value: 4, child: Text('Avril')),
                              DropdownMenuItem(value: 5, child: Text('Mai')),
                              DropdownMenuItem(value: 6, child: Text('Juin')),
                              DropdownMenuItem(value: 7, child: Text('Juillet')),
                              DropdownMenuItem(value: 8, child: Text('Août')),
                              DropdownMenuItem(value: 9, child: Text('Septembre')),
                              DropdownMenuItem(value: 10, child: Text('Octobre')),
                              DropdownMenuItem(value: 11, child: Text('Novembre')),
                              DropdownMenuItem(value: 12, child: Text('Décembre')),
                            ],
                            onChanged: (v) => setSheetState(() => selectedMonth = v!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF8A2BE2), Color(0xFFEC4899)]),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: TextButton(
                    onPressed: () async {
                      await BirthdayService.saveBirthday(selectedDay, selectedMonth);
                      if (mounted) {
                        Navigator.pop(context);
                        _loadEvents();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Anniversaire enregistré ! 🎂', style: GoogleFonts.poppins()),
                          backgroundColor: const Color(0xFF8A2BE2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ));
                      }
                    },
                    child: Text('Enregistrer', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
