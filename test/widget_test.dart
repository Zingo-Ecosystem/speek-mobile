import 'package:flutter_test/flutter_test.dart';

import 'package:speek/main.dart';

void main() {
  testWidgets('App boots to splash and shows the wordmark',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SpeekApp());
    expect(find.text('Speek'), findsWidgets);

    // Let the splash timer fire and route to onboarding so no timers leak.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });
}
