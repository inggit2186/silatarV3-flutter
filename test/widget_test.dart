// Basic Flutter widget test for SILATAR V2

import 'package:flutter_test/flutter_test.dart';
import 'package:silatar_v2/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SILATARApp());

    // Verify that app launches with splash screen
    expect(find.text('SILATAR V2'), findsOneWidget);
  });
}
