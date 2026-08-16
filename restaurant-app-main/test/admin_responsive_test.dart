import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:restaurant_automation/core/storage/local_storage.dart';
import 'package:restaurant_automation/features/admin/presentation/admin_operations_panel.dart';

void main() {
  late Directory testStorage;
  setUpAll(() async {
    testStorage = await Directory.systemTemp.createTemp(
      'admin_responsive_test_',
    );
    Hive.init(testStorage.path);
    await LocalStorage.init();
  });
  tearDownAll(() async {
    await Hive.close();
    await testStorage.delete(recursive: true);
  });

  final orders = <Map<String, dynamic>>[
    {
      '_id': 'order_1234567890',
      'orderNumber': 'ORD-1234567890',
      'status': 'Preparing',
      'paymentStatus': 'Unpaid',
      'total': 1450,
      'createdAt': DateTime.now().toIso8601String(),
      'tableId': {'_id': 'table_1', 'name': 'Family Celebration Table 12'},
      'customerName': 'A Customer With A Very Long Display Name',
      'items': [
        {
          'quantity': 2,
          'menuItem': {'name': 'Paneer Butter Masala Family Portion'},
        },
      ],
    },
  ];
  final menu = <Map<String, dynamic>>[
    {
      '_id': 'menu_1',
      'name': 'Hyderabadi Dum Biryani Special Family Platter',
      'description':
          'A deliberately long description used to validate narrow mobile layouts.',
      'basePrice': 899,
      'isAvailable': true,
      'categoryId': {'name': 'Chef Special Main Course'},
      'taxRate': 5,
      'discount': 0,
    },
  ];
  final tables = <Map<String, dynamic>>[
    {
      '_id': 'table_1',
      'name': 'Family Celebration Table 12',
      'status': 'Occupied',
      'capacity': 8,
    },
  ];

  for (final page in <int, String>{
    1: 'Orders',
    2: 'Menu',
    3: 'Tables',
    4: 'Kitchen',
    5: 'POS',
  }.entries) {
    testWidgets('${page.value} page has no RenderFlex overflow at 320px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: AdminOperationsPanel(
                page: page.key,
                data: Future.value([orders, menu, tables]),
                reload: () {},
                branchId: 'branch_1',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final page in <int, String>{
    6: 'Waiter',
    7: 'Inventory',
    8: 'Staff',
    9: 'Attendance',
    10: 'Reports',
    11: 'Settings',
  }.entries) {
    testWidgets('${page.value} empty state has no overflow at 320px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: AdminOperationsPanel(
                page: page.key,
                data: Future.value([orders, menu, tables]),
                reload: () {},
                branchId: null,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
