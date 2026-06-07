import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/services/birthday_service.dart';
import '/utils/app_tr.dart';
import '/components/liquid_glass.dart';

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

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<CalendarEvent>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadEvents();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: _violet),
              ),
            )
          else ...[
            SliverToBoxAdapter(child: _buildCalendar()),
            SliverToBoxAdapter(child: _buildLegend()),
            SliverToBoxAdapter(child: _buildSelectedDayEvents()),
            SliverToBoxAdapter(child: _buildUpcomingSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: LiquidGlassTokens.pageDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        context.tr('Calendrier', 'Calendar'),
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          tooltip: 'Ajouter mon anniversaire',
          onPressed: _showAddBirthdaySheet,
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
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
            markersMaxCount: 3,
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
                children: events.take(3).map((e) {
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
      child: Row(
        children: [
          _legendDot(_violet, 'Mon anniv'),
          const SizedBox(width: 16),
          _legendDot(_pink, 'Amis'),
          const SizedBox(width: 16),
          _legendDot(_gold, 'Fêtes'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: event.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: event.color.withOpacity(0.3)),
      ),
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
          if (event.type == EventType.holiday) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.push('/inspiration'),
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
    );
  }

  Widget _buildUpcomingSection() {
    // Prochains événements dans les 30 jours
    final now = DateTime.now();
    final end = now.add(const Duration(days: 30));
    final upcoming = <MapEntry<DateTime, List<CalendarEvent>>>[];

    for (final entry in _events.entries) {
      if (entry.key.isAfter(now) && entry.key.isBefore(end)) {
        upcoming.add(entry);
      }
    }
    upcoming.sort((a, b) => a.key.compareTo(b.key));

    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('À venir — 30 prochains jours',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...upcoming.expand((entry) {
            const months = ['', 'jan', 'fév', 'mar', 'avr', 'mai', 'juin', 'juil', 'août', 'sep', 'oct', 'nov', 'déc'];
            final diff = entry.key.difference(now).inDays;
            final label = diff == 0 ? 'Aujourd\'hui'
                : diff == 1 ? 'Demain'
                : 'Dans $diff jours';
            return entry.value.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text(
                          '${entry.key.day}',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          months[entry.key.month],
                          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.title,
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        Text(label,
                          style: GoogleFonts.poppins(color: e.color, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ));
          }).toList(),
        ],
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
              Text('Mon anniversaire ??', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Seuls le jour et le mois sont enregistrés', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 24),
              Row(
                children: [
                  // Jour
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
                  // Mois
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
                        _loadEvents(); // Refresh
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Anniversaire enregistré ! ??', style: GoogleFonts.poppins()),
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
