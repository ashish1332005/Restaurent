import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_automation/core/theme/app_theme.dart';

void main() {
  testWidgets('restaurant app theme renders correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Text('Restaurant Automation')),
      ),
    );

    expect(find.text('Restaurant Automation'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
