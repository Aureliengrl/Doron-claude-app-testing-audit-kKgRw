import 'package:flutter/material.dart';

class CreateChatBottomSheet extends StatefulWidget {
  const CreateChatBottomSheet({Key? key, this.forceGroup, this.suggestedGroupName, this.product, this.profile}) : super(key: key);
  final dynamic forceGroup;
  final dynamic suggestedGroupName;
  final dynamic product;
  final dynamic profile;
  @override
  State<CreateChatBottomSheet> createState() => _CreateChatBottomSheetState();
  static void show(BuildContext context, dynamic product) {}
}

class _CreateChatBottomSheetState extends State<CreateChatBottomSheet> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
