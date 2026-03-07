import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '/components/liquid_glass.dart';

class CreateChatBottomSheet extends StatefulWidget {
  const CreateChatBottomSheet({super.key});

  @override
  State<CreateChatBottomSheet> createState() => _CreateChatBottomSheetState();
}

class _CreateChatBottomSheetState extends State<CreateChatBottomSheet> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Color violetColor = const Color(0xFF8A2BE2);
  bool _isGroup = false;
  
  // Dummy contacts
  final List<Map<String, dynamic>> _contacts = [
    {'id': '1', 'name': 'Marie', 'color': 0xFFEC4899},
    {'id': '2', 'name': 'Thomas', 'color': 0xFF8A2BE2},
    {'id': '3', 'name': 'Camille', 'color': 0xFF3B82F6},
    {'id': '4', 'name': 'Sophie', 'color': 0xFF10B981},
    {'id': '5', 'name': 'Lucas', 'color': 0xFFF59E0B},
  ];
  
  final Set<String> _selectedContacts = {};

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _createChat() {
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

    HapticFeedback.mediumImpact();
    context.pop(); // Close bottom sheet
    
    // Create dummy chat object and go to chat room
    final chatData = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': _isGroup ? _groupNameController.text.trim() : _contacts.firstWhere((c) => c['id'] == _selectedContacts.first)['name'],
      'isGroup': _isGroup,
      'participants': _selectedContacts.length + 1,
    };
    
    context.push('/chat-room/${chatData['id']}', extra: chatData);
  }

  @override
  Widget build(BuildContext context) {
    // Determine automatically if it should be a group
    _isGroup = _selectedContacts.length > 1 || _groupNameController.text.isNotEmpty;

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
            'Nouvelle Conversation',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                final isSelected = _selectedContacts.contains(contact['id']);
                
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
                    child: Text(
                      contact['name'].substring(0, 1),
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
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
                child: Text(
                  _selectedContacts.length > 1 ? 'Créer le groupe' : 'Démarrer le chat',
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
