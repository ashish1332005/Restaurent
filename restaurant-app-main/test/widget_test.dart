import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:restaurant_automation/features/system/presentation/system_pages.dart';
import 'package:restaurant_automation/ui_reset/ui_reset_screen.dart';
import 'package:restaurant_automation/core/storage/local_storage.dart';
import 'package:restaurant_automation/main.dart';

void main() {
  late Directory testStorage;
  setUpAll(() async {
    testStorage = await Directory.systemTemp.createTemp('restaurant_ui_test_');
    Hive.init(testStorage.path);
    await LocalStorage.init();
  });
  tearDownAll(() async {
    await Hive.close();
    await testStorage.delete(recursive: true);
  });
  testWidgets('customer QR entry screen renders at 320px without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: UiResetScreen()));
    expect(find.text('Namaste'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    await tester.pump();
  });

  testWidgets('privacy policy renders at narrow mobile width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: LegalDocumentScreen(document: 'privacy')),
    );
    expect(find.text('Privacy Policy'), findsWidgets);
    expect(find.text('Information we collect'), findsOneWidget);
    await tester.pump();
  });

  testWidgets('error page offers safe recovery', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppErrorScreen()));
    expect(find.text('Page not found'), findsOneWidget);
    expect(find.text('Go home'), findsOneWidget);
  });

  testWidgets('offline page offers retry', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OfflineScreen()));
    expect(find.text('You are offline'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('restaurant registration opens from owner login', (tester) async {
    await LocalStorage.clearToken();
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ProviderScope(child: RestaurantApp()));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(
      tester.getBottomRight(find.text('Login')).dy,
      lessThan(700),
      reason: 'Login button should be visible without initial scrolling',
    );
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Create Owner Account'), findsOneWidget);
    expect(find.text('Restaurant Name'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
