import 'package:flutter/material.dart';

class FavouritesWidget extends StatefulWidget {
  const FavouritesWidget({Key? key, this.forceGroup, this.suggestedGroupName, this.product, this.profile}) : super(key: key);
  final dynamic forceGroup;
  final dynamic suggestedGroupName;
  final dynamic product;
  final dynamic profile;
  @override
  State<FavouritesWidget> createState() => _FavouritesWidgetState();
  static void show(BuildContext context, dynamic product) {}
}

class _FavouritesWidgetState extends State<FavouritesWidget> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
