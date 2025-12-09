// This is a basic Flutter widget test for SuperMart Manager app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:super_market_helper/main.dart';

void main() {
  testWidgets('SuperMart Manager app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SuperMartApp());

    // Verify that the login screen is displayed
    expect(find.text('SuperMart Manager'), findsOneWidget);
  });
}
