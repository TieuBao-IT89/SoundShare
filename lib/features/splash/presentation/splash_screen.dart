import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/aurora_widgets.dart';
import '../../../l10n/l10n.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) context.go('/');
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: AuroraBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: FadeTransition(
              opacity: reduced
                  ? const AlwaysStoppedAnimation(1)
                  : CurvedAnimation(parent: controller, curve: Curves.easeOut),
              child: ScaleTransition(
                scale: reduced
                    ? const AlwaysStoppedAnimation(1)
                    : Tween<double>(begin: .96, end: 1).animate(
                        CurvedAnimation(
                          parent: controller,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AuroraLogo(size: 96),
                    const SizedBox(height: 24),
                    Text(
                      context.l10n.appName,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.brandTagline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
