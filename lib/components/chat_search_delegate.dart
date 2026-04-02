import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Recherche dans les messages d'un chat.
class ChatSearchDelegate extends SearchDelegate<String?> {
  final String chatId;
  static const _violet = Color(0xFF8A2BE2);

  ChatSearchDelegate({required this.chatId})
      : super(
          searchFieldLabel: 'Rechercher un message...',
          searchFieldStyle: GoogleFonts.poppins(color: Colors.white70, fontSize: 15),
        );

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A0015),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      scaffoldBackgroundColor: const Color(0xFF0A0015),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: GoogleFonts.poppins(color: Colors.white38),
        border: InputBorder.none,
      ),
      textTheme: TextTheme(
        titleLarge: GoogleFonts.poppins(color: Colors.white),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white54),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    if (query.trim().isEmpty) {
      return Center(
        child: Text(
          'Tapez pour rechercher',
          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 14),
        ),
      );
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(200)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _violet),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'Aucun message trouvé',
              style: GoogleFonts.poppins(color: Colors.white38),
            ),
          );
        }

        final queryLower = query.toLowerCase();
        final matchingDocs = snapshot.data!.docs.where((doc) {
          final text =
              ((doc.data() as Map<String, dynamic>)['text'] as String? ?? '')
                  .toLowerCase();
          return text.contains(queryLower);
        }).toList();

        if (matchingDocs.isEmpty) {
          return Center(
            child: Text(
              'Aucun résultat pour "$query"',
              style: GoogleFonts.poppins(color: Colors.white38),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: matchingDocs.length,
          itemBuilder: (context, index) {
            final data =
                matchingDocs[index].data() as Map<String, dynamic>;
            final text = data['text'] as String? ?? '';
            final timestamp = data['timestamp'] as Timestamp?;
            final time = timestamp != null
                ? '${timestamp.toDate().day}/${timestamp.toDate().month} ${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                : '';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _highlightMatch(text, query),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: GoogleFonts.poppins(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _highlightMatch(String text, String query) {
    // Simple approach — just return the text, the rich highlight
    // would require RichText widget
    return text;
  }
}
