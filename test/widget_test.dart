import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundshare/app/app.dart';
import 'package:soundshare/l10n/l10n.dart';

void main() {
  testWidgets('SoundShare splash introduces the app', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SoundShareApp(authenticationRequired: false)),
    );
    expect(find.text(appCopy.appName), findsOneWidget);
    expect(find.text(appCopy.brandTagline), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
