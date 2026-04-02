import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/friend_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/components/liquid_glass.dart';

class CreateChatBottomSheet extends StatefulWidget {
  /// Si true, force le mode création de groupe (nom requis, titre "Nouveau Groupe")
  final bool forceGroup;
  const CreateChatBottomSheet({super.key, this.forceGroup = false});

  @override
  State<CreateChatBottomSheet> createState() => _CreateChatBottomSheetState();
}

class _CreateChatBottomSheetState extends State<CreateChatBottomSheet> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Color violetColor = const Color(0xFF8A2BE2);
  bool _isGroup = false;
  bool _isLoading = true;
  bool _isCreating = false;
  
  List<Map<String, dynamic>> _contacts = [];
  final Set<String> _selectedContacts = {};

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      // Charge uniquement les amis (pas tous les utilisateurs)
      final friends = await FriendService.getFriendsStream().first;
      if (mounted) {
        setState(() {
          _contacts = friends.map((f) => {
                'id': f['uid'] as String? ?? f['id'] as String? ?? '',
                'name': f['displayName'] as String? ?? 'Ami',
                'photoUrl': f['photoUrl'] as String? ?? '',
                'color': 0xFF8A2BE2,
              }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading contacts: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createChat() async {
    if (_selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez sélectionner au moins un contact', style: GoogleFonts.poppins())),
      );
      return;
    }
    if (_isGroup && _groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez donner un nom au groupe', style: GoogleFonts.poppins())),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    HapticFeedback.mediumImpact();
    setState(() => _isCreating = true);

    try {
      // For 1-on-1 chats, use getOrCreateDirectChat to reuse existing conversations
      if (!_isGroup && _selectedContacts.length == 1) {
        final friendUid = _selectedContacts.first;
        final chatId = await FriendService.getOrCreateDirectChat(friendUid);

        if (mounted) {
          context.pop();
          context.push('/chat-room/$chatId');
        }
        return;
      }

      // Group chat: create a new one
      final chatRef = FirebaseFirestore.instance.collection('chats').doc();
      final participants = [currentUser.uid, ..._selectedContacts];

      String chatName = '';
      if (_isGroup) {
        chatName = _groupNameController.text.trim();
      }

      final chatData = {
        'id': chatRef.id,
        'name': chatName,
        'isGroup': _isGroup,
        'participants': participants,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentUser.uid,
      };

      await chatRef.set(chatData);

      if (mounted) {
        context.pop();
        context.push('/chat-room/${chatRef.id}', extra: chatData);
      }
    } catch (e) {
      debugPrint('Erreur lors de la création du chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e', style: GoogleFonts.poppins())),
        );
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine automatically if it should be a group
    _isGroup = widget.forceGroup || _selectedContacts.length > 1 || _groupNameController.text.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: LiquidGlassTokens.pageDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              height: 6,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          
          Text(
            widget.forceGroup ? '👥 Nouveau Groupe' : 'Nouvelle Conversation',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (widget.forceGroup)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Sélectionnez vos amis pour créer un groupe',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.5)),
              ),
            ),
          const SizedBox(height: 24),
          
          // Group Name Input (appears if multi-select or manually typing)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isGroup ? 60 : 0,
              child: _isGroup ? CustomTextField(
                controller: _groupNameController,
                hint: 'Nom du groupe (Optionnel)',
                icon: Icons.group_work,
              ) : const SizedBox.shrink(),
            ),
          ),
          if (_isGroup) const SizedBox(height: 16),

          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: CustomTextField(
              controller: _searchController,
              hint: 'Chercher un ami...',
              icon: Icons.search,
            ),
          ),
          const SizedBox(height: 16),
          
          // Selected Count
          if (_selectedContacts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_selectedContacts.length} sélectionné(s)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: violetColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Contacts List
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF8A2BE2)))
              : _contacts.isEmpty 
                ? Center(
                    child: Text(
                      'Aucun ami trouvé',
                      style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.5)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      final contact = _contacts[index];
                      final isSelected = _selectedContacts.contains(contact['id']);
                      final photoUrl = contact['photoUrl'] as String;
                      
                      return ListTile(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (isSelected) {
                              _selectedContacts.remove(contact['id']);
                            } else {
                              _selectedContacts.add(contact['id']!);
                            }
                          });
                        },
                        leading: CircleAvatar(
                          backgroundColor: Color(contact['color'] as int),
                          backgroundImage: photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
                          child: photoUrl.isEmpty ? Text(
                            contact['name'].substring(0, 1).toUpperCase(),
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                          ) : null,
                        ),
                        title: Text(
                          contact['name'],
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        trailing: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? violetColor : Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                            color: isSelected ? violetColor : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                      );
                    },
                  ),
          ),

          // Create Button
          Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedContacts.isEmpty ? null : _createChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: violetColor,
                  disabledBackgroundColor: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _isCreating ? const CircularProgressIndicator(color: Colors.white) : Text(
                  _isGroup ? 'Créer le groupe' : 'Démarrer le chat',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedContacts.isEmpty ? Colors.white.withOpacity(0.4) : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.white.withOpacity(0.5)),
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.4)),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
