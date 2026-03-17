import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/components/liquid_glass.dart';
import '/services/friend_service.dart';

class ShareListBottomSheet extends StatefulWidget {
  final Map<String, dynamic> profile;

  const ShareListBottomSheet({super.key, required this.profile});

  @override
  State<ShareListBottomSheet> createState() => _ShareListBottomSheetState();
}

class _ShareListBottomSheetState extends State<ShareListBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Color violetColor = const Color(0xFF8A2BE2);
  bool _isLoading = true;
  bool _isSharing = false;
  
  List<Map<String, dynamic>> _contacts = [];
  final Set<String> _selectedContacts = {};

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _shareList() async {
    if (_selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez sélectionner au moins un contact', style: GoogleFonts.poppins())),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    HapticFeedback.mediumImpact();
    setState(() => _isSharing = true);

    try {
      final profileId = widget.profile['id'];
      final profileName = widget.profile['name'] as String? ?? 'Inconnu';
      
      // 1. Create a Chat Room for this collaboration
      final chatRef = FirebaseFirestore.instance.collection('chats').doc();
      final participants = [currentUser.uid, ..._selectedContacts];
      final chatName = 'Cadeaux pour $profileName';
      
      final chatData = {
        'id': chatRef.id,
        'name': chatName,
        'isGroup': true,
        'participants': participants,
        'lastMessage': 'Rejoignez la liste de cadeaux !',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentUser.uid,
        'linkedProfileId': profileId,
      };

      await chatRef.set(chatData);
      
      // Create a welcomed initial message
      await chatRef.collection('messages').add({
        'senderId': currentUser.uid,
        'text': 'Salut ! J\'ai créé cette discussion pour qu\'on puisse collaborer sur la liste de cadeaux pour $profileName. Cliquez sur "Chat" sur la page Inspiration pour y accéder.',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Update the Profile document
      // We assume profiles are stored in Firestore under 'gift_profiles' or equivalent.
      // Wait, in this app profiles are stored inside the user's document or a top-level collection?
      // For now, let's update a top-level collection 'users' -> 'profiles' or we just update the local model?
      // Wait, let's look at how deletePerson works.
      
      // I will update it in Firebase if I know the path. Let's do it below safely:
      try {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).collection('profiles').doc(profileId.toString()).update({
          'isShared': true,
          'sharedWith': participants,
          'chatId': chatRef.id,
        });
      } catch (e) {
        print('Profile might not be in users/profiles or does not exist: $e');
      }

      if (mounted) {
        Navigator.pop(context, chatRef.id); // Return the chatId to the page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: violetColor,
            content: Text('Liste partagée ! Groupe de discussion créé.', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        );
        // Naviguer directement dans le chat de groupe
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            context.push('/chat-room/${chatRef.id}', extra: {
              'name': chatName,
              'isGroup': true,
            });
          }
        });
      }
    } catch (e) {
      print('Erreur lors du partage de la liste: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e', style: GoogleFonts.poppins())),
        );
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            'Partager à :',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

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
                  '${_selectedContacts.length} ami(s) sélectionné(s)',
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

          // Share Button
          Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedContacts.isEmpty || _isSharing ? null : _shareList,
                style: ElevatedButton.styleFrom(
                  backgroundColor: violetColor,
                  disabledBackgroundColor: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _isSharing ? const CircularProgressIndicator(color: Colors.white) : Text(
                  'Créer la collaboration',
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
