import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import 'aurora_widgets.dart';

class AuthenticationHeader extends StatelessWidget {
  const AuthenticationHeader({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const AuroraLogo(size: 58),
      const SizedBox(height: 16),
      Text(
        context.l10n.appName,
        style: TextStyle(
          fontSize: compact ? 24 : 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        context.l10n.brandTagline,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
      ),
    ],
  );
}

class AuthenticationScaffold extends StatelessWidget {
  const AuthenticationScaffold({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: AuroraBackground(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}
