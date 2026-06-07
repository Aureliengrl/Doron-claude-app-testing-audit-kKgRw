import 'package:flutter/material.dart';

class TicketSuccessWidget extends StatefulWidget {
  const TicketSuccessWidget({Key? key, this.forceGroup, this.suggestedGroupName, this.product, this.profile}) : super(key: key);
  final dynamic forceGroup;
  final dynamic suggestedGroupName;
  final dynamic product;
  final dynamic profile;
  @override
  State<TicketSuccessWidget> createState() => _TicketSuccessWidgetState();
  static void show(BuildContext context, dynamic product) {}
}

class _TicketSuccessWidgetState extends State<TicketSuccessWidget> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
