import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bingoals_mobile/app.dart';

void main() {
  testWidgets('App loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BingoalsApp(),
      ),
    );

    // Verify that the splash screen loads with the app name
    expect(find.text('Bingoals'), findsOneWidget);
  });
}
