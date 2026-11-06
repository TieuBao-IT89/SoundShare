import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundshare/app/theme/app_theme.dart';
import 'package:soundshare/core/services/api_client.dart';
import 'package:soundshare/features/community/presentation/profile_account_menu.dart';
import 'package:soundshare/l10n/l10n.dart';

void main() {
  for (final viewport in [(320.0, 2.0), (1280.0, 1.0)]) {
    testWidgets('Account menu opens provider once and signs out at $viewport', (
      tester,
    ) async {
      tester.view.physicalSize = Size(viewport.$1, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = viewport.$2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      var opened = 0, signedOut = 0;
      final closed = Completer<void>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            signOutProvider.overrideWithValue(() async {
              signedOut++;
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Align(
                alignment: Alignment.topRight,
                child: ProfileAccountMenu(
                  onOpenAccount: () {
                    opened++;
                    return closed.future;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip(appCopy.accountSection));
      await tester.pumpAndSettle();
      await tester.tap(find.text(appCopy.manageAccount));
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(
        tester
            .widget<PopupMenuButton<dynamic>>(
              find.byWidgetPredicate(
                (widget) => widget is PopupMenuButton<dynamic>,
              ),
            )
            .enabled,
        isFalse,
      );
      closed.complete();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(appCopy.accountSection));
      await tester.pumpAndSettle();
      await tester.tap(find.text(appCopy.signOut));
      await tester.pumpAndSettle();
      expect(signedOut, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Menu failures stay localized and allow retry', (tester) async {
    Future<void> unavailable() async =>
        throw StateError('private provider details');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [signOutProvider.overrideWithValue(unavailable)],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(body: ProfileAccountMenu(onOpenAccount: unavailable)),
        ),
      ),
    );
    for (final item in [
      (appCopy.manageAccount, appCopy.accountOpenFailed),
      (appCopy.signOut, appCopy.signOutFailed),
    ]) {
      await tester.tap(find.byTooltip(appCopy.accountSection));
      await tester.pumpAndSettle();
      await tester.tap(find.text(item.$1));
      await tester.pumpAndSettle();
      expect(find.text(item.$2), findsOneWidget);
      expect(find.textContaining('private provider details'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }
  });
}
