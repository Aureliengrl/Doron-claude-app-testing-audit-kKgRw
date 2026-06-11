import 'package:flutter/material.dart';

class AestheticBottomSheetNotch extends StatelessWidget {
  const AestheticBottomSheetNotch({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }
}
