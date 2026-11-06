import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundshare/app/theme/app_theme.dart';
import 'package:soundshare/features/auth/presentation/account_management.dart';
import 'package:soundshare/l10n/l10n.dart';

void main() {
  testWidgets('Account management opens once while provider UI is active', (
    tester,
  ) async {
    var calls = 0;
    final closed = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: AccountManagementButton(
            onOpen: () {
              calls++;
              return closed.future;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text(appCopy.manageAccount));
    await tester.pump();
    expect(calls, 1);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
    closed.complete();
    await tester.pumpAndSettle();
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Account UI failure stays localized and safe', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: AccountManagementButton(
            onOpen: () async {
              throw StateError('private provider details');
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text(appCopy.manageAccount));
    await tester.pumpAndSettle();
    expect(find.text(appCopy.accountOpenFailed), findsOneWidget);
    expect(find.textContaining('private provider details'), findsNothing);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });
}
