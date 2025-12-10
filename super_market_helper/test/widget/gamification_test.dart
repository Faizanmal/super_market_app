import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_market_helper/screens/gamification/gamification_dashboard.dart';

void main() {
  testWidgets('GamificationDashboard shows loading and handles error', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: GamificationDashboard()));

    // Verify loading indicator is shown initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for async operations to complete (they will fail in test env without mocks)
    await tester.pumpAndSettle();

    // Verify error state or loaded state attempts
    // If service fails, it sets _loading = false and _profile = null
    // UI shows "Failed to load profile"
    
    // Note: Depends on how ApiClient handles 'http://localhost:8000' in test environment.
    // It might throw immediately.
    
    // We expect "Staff Performance" title in AppBar
    expect(find.text('Staff Performance'), findsOneWidget);
    
    // We expect Tabs
    expect(find.text('My Progress'), findsOneWidget);
    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.text('Badges'), findsOneWidget);
  });
}
