import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/utils/iconly_compat.dart';
import '/components/liquid_glass.dart';
import '../chat/chat_list_page.dart';
import '../chat/create_chat_bottom_sheet.dart';
import '/components/app_notch.dart';
import '/services/firebase_data_service.dart';

class SocialPageWidget extends StatefulWidget {
  const SocialPageWidget({super.key});

  @override
  State<SocialPageWidget> createState() => _SocialPageWidgetState();
}

class _SocialPageWidgetState extends State<SocialPageWidget> {
  void _openCreateChat({bool forceGroup = false}) {
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
          AppNotch(
            title: 'Social',
            subtitle: 'Interagissez et retrouvez vos amis',
            leading: StreamBuilder<QuerySnapshot>(
              stream: (FirebaseDataService.currentUserId ?? FirebaseAuth.instance.currentUser?.uid) != null
                  ? FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(FirebaseDataService.currentUserId ?? FirebaseAuth.instance.currentUser!.uid)
                      .collection('items')
                      .where('read', isEqualTo: false)
                      .snapshots()
                  : null,
              builder: (context, snap) {
                final unreadCount = snap.data?.docs.length ?? 0;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(IconlyLight.notification, color: Colors.white, size: 26),
                      onPressed: () => context.push('/notifications'),
                      tooltip: 'Notifications',
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEC4899),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
              onPressed: () => _openCreateChat(),
              tooltip: 'Nouvelle discussion ou groupe',
            ),
          ),
          const Expanded(
            child: ChatListPage(showBackButton: false),
          ),
        ],
      ),
    );
  }
}
