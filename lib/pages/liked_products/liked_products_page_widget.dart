import 'package:flutter/material.dart';

class LikedProductsPageWidget extends StatefulWidget {
  const LikedProductsPageWidget({Key? key, this.forceGroup, this.suggestedGroupName, this.product, this.profile}) : super(key: key);
  final dynamic forceGroup;
  final dynamic suggestedGroupName;
  final dynamic product;
  final dynamic profile;
  @override
  State<LikedProductsPageWidget> createState() => _LikedProductsPageWidgetState();
  static void show(BuildContext context, dynamic product) {}
  static const String routeName = 'LikedProductsPage';
  static const String routePath = '/likedProductsPage';
}

class _LikedProductsPageWidgetState extends State<LikedProductsPageWidget> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
