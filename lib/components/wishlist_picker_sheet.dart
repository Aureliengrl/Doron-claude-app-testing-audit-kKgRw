import 'package:flutter/material.dart';

class WishlistPickerSheet extends StatefulWidget {
  const WishlistPickerSheet({Key? key, this.forceGroup, this.suggestedGroupName, this.product, this.profile}) : super(key: key);
  final dynamic forceGroup;
  final dynamic suggestedGroupName;
  final dynamic product;
  final dynamic profile;
  @override
  State<WishlistPickerSheet> createState() => _WishlistPickerSheetState();
  static void show(BuildContext context, dynamic product) {}
}

class _WishlistPickerSheetState extends State<WishlistPickerSheet> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
