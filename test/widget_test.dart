import 'package:flutter_test/flutter_test.dart';
import 'package:soundshare/app/app.dart';

void main() {
  testWidgets('SoundShare splash introduces the app', (tester) async {
    await tester.pumpWidget(const SoundShareApp());
    expect(find.text('soundshare'), findsOneWidget);
    expect(find.text('Share your music. Enjoy every moment.'), findsOneWidget);
  });
}
