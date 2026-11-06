import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import 'aurora_widgets.dart';

class AuthenticationHeader extends StatelessWidget {
  const AuthenticationHeader({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const AuroraLogo(size: 30),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          context.l10n.appName,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
      ),
    ],
  );
}

class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      const AuthenticationHeader(),
      SizedBox(height: compact ? 28 : 56),
      Text(
        context.l10n.authTagline,
        style: const TextStyle(color: AppColors.cyan, fontSize: 12),
      ),
      const SizedBox(height: 16),
      Text(
        context.l10n.authHeadline,
        style: TextStyle(
          fontSize: compact ? 30 : 46,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.3,
          height: 1.2,
        ),
      ),
      const SizedBox(height: 20),
      Text(
        context.l10n.authDescription,
        style: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 15,
          height: 1.8,
        ),
      ),
      SizedBox(
        height: compact ? 200 : 300,
        width: double.infinity,
        child: const ExcludeSemantics(
          child: CustomPaint(painter: _WaveCoverPainter()),
        ),
      ),
    ],
  );
}

class AuthenticationScaffold extends StatefulWidget {
  const AuthenticationScaffold({
    super.key,
    required this.child,
    this.welcome = false,
  });
  final Widget child;
  final bool welcome;
  @override
  State<AuthenticationScaffold> createState() => _AuthenticationScaffoldState();
}

class _AuthenticationScaffoldState extends State<AuthenticationScaffold> {
  final contentKey = GlobalKey();
  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: true,
    body: LayoutBuilder(
      builder: (context, bounds) {
        final content = KeyedSubtree(key: contentKey, child: widget.child);
        if (bounds.maxWidth < 1000) {
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.welcome &&
                          MediaQuery.viewInsetsOf(context).bottom == 0)
                        const AuthBrandPanel(compact: true),
                      content,
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return Row(
          children: [
            Expanded(
              flex: 7,
              child: DecoratedBox(
                decoration: const BoxDecoration(gradient: AppGradients.soft),
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(48),
                      child: const SizedBox(
                        width: 560,
                        child: AuthBrandPanel(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: ColoredBox(
                color: AppColors.secondaryBackground,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: content,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _WaveCoverPainter extends CustomPainter {
  const _WaveCoverPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 420, size.height / 300);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.rotate(-.16);
    final ink = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(
      const Offset(84, 0),
      124,
      Paint()..color = AppColors.background,
    );
    for (var radius = 90.0; radius <= 124; radius += 8) {
      canvas.drawCircle(const Offset(84, 0), radius, ink);
    }
    final cover = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-170, -124, 252, 248),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      cover,
      Paint()..shader = AppGradients.soft.createShader(cover.outerRect),
    );
    canvas.drawRRect(cover, ink);
    final wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = const LinearGradient(
        colors: [AppColors.primary, AppColors.mystic, AppColors.cyan],
      ).createShader(cover.outerRect);
    for (var line = 0; line < 5; line++) {
      final path = Path();
      for (var x = -150.0; x < 66; x += 2) {
        final y = math.sin((x + 150) / 30) * 64 + line * 10 - 20;
        if (x == -150) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, wave);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
