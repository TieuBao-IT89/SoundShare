import 'package:flutter/material.dart';

bool openWebAccount() => false;

class WebAuthGate extends StatelessWidget {
  const WebAuthGate({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}
