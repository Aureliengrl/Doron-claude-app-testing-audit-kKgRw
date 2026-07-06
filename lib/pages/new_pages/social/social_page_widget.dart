import 'package:flutter/material.dart';
import '/components/liquid_glass.dart';
import '../chat/chat_list_page.dart';
import '/components/app_notch.dart';

class SocialPageWidget extends StatefulWidget {
  const SocialPageWidget({super.key});

  @override
  State<SocialPageWidget> createState() => _SocialPageWidgetState();
}

class _SocialPageWidgetState extends State<SocialPageWidget> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: Column(
        children: [
          AppNotch(
            title: 'Social',
            subtitle: 'Vos discussions',
          ),
          Expanded(
            child: ChatListPage(showBackButton: false),
          ),
        ],
      ),
    );
  }
}
