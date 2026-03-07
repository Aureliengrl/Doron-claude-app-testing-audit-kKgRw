import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/components/liquid_glass.dart';
import 'create_chat_bottom_sheet.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final Color violetColor = const Color(0xFF8A2BE2);
  final List<Map<String, dynamic>> _mockChats = [
    {
      'id': '1',
      'name': 'Groupe Cadeaux Noël',
      'isGroup': true,
      'lastMessage': 'Est-ce qu\'on prend le parfum ou la montre pour maman ?',
      'time': '10:42',
      'unread': 2,
      'participants': 4,
    },
    {
      'id': '2',
      'name': 'Marie',
      'isGroup': false,
      'lastMessage': 'Merci pour ta suggestion !',
      'time': 'Hier',
      'unread': 0,
      'participants': 2,
    },
    {
      'id': '3',
      'name': 'Anniversaire Thomas',
      'isGroup': true,
      'lastMessage': 'J\'ai partagé la liste de cadeaux en PDF.',
      'time': 'Lun',
      'unread': 0,
      'participants': 6,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildChatsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: const FractionallySizedBox(
                heightFactor: 0.85,
                child: CreateChatBottomSheet(),
              ),
            ),
          );
        },
        backgroundColor: violetColor,
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => context.pop(),
                splashRadius: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Messages',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildChatsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _mockChats.length,
      itemBuilder: (context, index) {
        final chat = _mockChats[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                context.push('/chat-room/${chat['id']}', extra: chat);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: chat['isGroup'] == true 
                            ? [const Color(0xFF8A2BE2), const Color(0xFF4A148C)]
                            : [const Color(0xFFEC4899), const Color(0xFF9C27B0)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          chat['isGroup'] == true ? Icons.groups : Icons.person,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Infos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  chat['name'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: chat['unread'] > 0 ? FontWeight.bold : FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                chat['time'],
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: chat['unread'] > 0 ? const Color(0xFFEC4899) : Colors.white.withOpacity(0.5),
                                  fontWeight: chat['unread'] > 0 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chat['lastMessage'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (chat['unread'] > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEC4899),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${chat['unread']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1, end: 0),
        );
      },
    );
  }
}
