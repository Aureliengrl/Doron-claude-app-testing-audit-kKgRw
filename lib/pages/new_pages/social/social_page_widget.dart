import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/components/liquid_glass.dart';
import '../chat/chat_list_page.dart';
import '../chat/create_chat_bottom_sheet.dart';
import 'friends_page.dart';
import 'package:flutter/services.dart';

class SocialPageWidget extends StatefulWidget {
  const SocialPageWidget({super.key});

  @override
  State<SocialPageWidget> createState() => _SocialPageWidgetState();
}

class _SocialPageWidgetState extends State<SocialPageWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCreateChat(BuildContext context, {bool forceGroup = false}) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: CreateChatBottomSheet(forceGroup: forceGroup),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: Column(
        children: [
          // En-tête avec effet verre et dégradé
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8A2BE2), Color(0xFFEC4899)],
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('💬', style: TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Text(
                              'Social',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        // Boutons d'action globaux dynamiques selon l'onglet
                        AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, _) {
                            if (_tabController.index == 0) {
                              return Row(
                                children: [
                                  Tooltip(
                                    message: 'Nouveau groupe',
                                    child: GestureDetector(
                                      onTap: () => _openCreateChat(context, forceGroup: true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.group_add, color: Colors.white, size: 18),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Groupe',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit_square, color: Colors.white),
                                    onPressed: () => _openCreateChat(context, forceGroup: false),
                                    splashRadius: 24,
                                    tooltip: 'Nouveau message',
                                  ),
                                ],
                              );
                            } else {
                              return Tooltip(
                                message: 'Inviter un ami sur l\'app',
                                child: IconButton(
                                  icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    // Share deep link or show invite dialog logic
                                  },
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // TabBar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0xFF8A2BE2).withOpacity(0.4),
                          border: Border.all(color: const Color(0xFF8A2BE2).withOpacity(0.8), width: 1),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white54,
                        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
                        tabs: const [
                          Tab(text: 'Messages'),
                          Tab(text: 'Amis'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const ChatListPage(showBackButton: false),
                const FriendsPage(showBackButton: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
