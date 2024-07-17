import 'package:flutter/material.dart';

class DisableBackSwipe extends StatelessWidget {
  const DisableBackSwipe({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(onWillPop: () async => true, child: child);
  }
}