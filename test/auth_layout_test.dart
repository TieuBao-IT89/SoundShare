import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundshare/app/theme/app_theme.dart';
import 'package:soundshare/core/widgets/authentication_header.dart';
import 'package:soundshare/l10n/l10n.dart';

void main() {
  for (final width in [320.0, 390.0, 430.0, 768.0, 1024.0, 1280.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Auth welcome fits $width at ${scale}x', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            home: AuthenticationScaffold(
              welcome: true,
              child: FilledButton(
                onPressed: () {},
                child: const Text('Tiếp tục'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(appCopy.authHeadline), findsOneWidget);
      });
    }
  }
  testWidgets(
    'A responsive breakpoint keeps entered form state and keyboard access',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: const AuthenticationScaffold(
            child: TextField(
              decoration: InputDecoration(labelText: 'Email kiểm thử'),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'fixture@example.invalid');
      tester.view.physicalSize = const Size(1280, 900);
      await tester.pumpAndSettle();
      expect(find.text('fixture@example.invalid'), findsOneWidget);
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(320, 640);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.tap(find.byType(TextField));
      expect(find.text('fixture@example.invalid'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
