import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/restaurant_api.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/theme/hospitality_theme.dart';
import '../../../core/theme/royal_admin_ui.dart';
import '../../../core/services/qr_download_service.dart';
import 'admin_attendance_panel.dart';
import 'admin_inventory_panel.dart';
import 'admin_kitchen_panel.dart';
import 'admin_pos_panel.dart';
import 'admin_reports_panel.dart';
import 'admin_settings_panel.dart';
import 'admin_staff_panel.dart';
import 'admin_waiter_panel.dart';

class AdminOperationsPanel extends StatelessWidget {
  const AdminOperationsPanel({
    super.key,
    required this.page,
    required this.data,
    required this.reload,
    required this.branchId,
  });
  final int page;
  final Future<List<List<Map<String, dynamic>>>> data;
  final VoidCallback reload;
  final String? branchId;
  bool get _subscriptionAllowsWrites =>
      LocalStorage.getRole() == 'Super Admin' ||
      LocalStorage.isSubscriptionActive();
  bool get _writeBlocked => branchId == null || !_subscriptionAllowsWrites;

  Widget _writeNotice() => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1E7),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFFCDAA)),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: Color(0xFFC95B20)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            branchId == null
                ? 'Select a branch before adding restaurant data.'
                : 'Your subscription is inactive or expired. Renew it to add or edit data.',
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<List<Map<String, dynamic>>>>(
        future: data,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(50),
                child: CircularProgressIndicator(),
              ),
            );
          if (snapshot.hasError)
            return Center(
              child: Text(RestaurantApi.messageFor(snapshot.error!)),
            );
          final orders = snapshot.data![0],
              menu = snapshot.data![1],
              tables = snapshot.data![2];
          return switch (page) {
            1 => _orders(context, orders),
            2 => _menu(context, menu),
            3 => _tables(context, tables),
            4 => AdminKitchenPanel(
              initialOrders: orders,
              branchId: branchId,
              reloadAdmin: reload,
            ),
            5 => AdminPosPanel(
              menu: menu,
              tables: tables,
              branchId: branchId,
              reload: reload,
            ),
            6 => AdminWaiterPanel(
              initialOrders: orders,
              initialTables: tables,
              branchId: branchId,
              reloadAdmin: reload,
            ),
            7 => AdminInventoryPanel(branchId: branchId),
            8 => AdminStaffPanel(branchId: branchId),
            9 => AdminAttendancePanel(branchId: branchId),
            10 => AdminReportsPanel(branchId: branchId),
            11 => AdminSettingsPanel(branchId: branchId),
            _ => const SizedBox.shrink(),
          };
        },
      );

  Widget _orders(BuildContext context, List<Map<String, dynamic>> orders) {
    final active = orders
        .where((order) => !['Paid', 'Cancelled'].contains(order['status']))
        .length;
    final ready = orders.where((order) => order['status'] == 'Ready').length;
    final unpaid = orders
        .where(
          (order) =>
              order['paymentStatus'] != 'Paid' &&
              order['status'] != 'Cancelled',
        )
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _operationsHero(
          title: 'Live service',
          subtitle: 'Track every order from acceptance to payment.',
          badges: [
            _serviceBadge('Active', active, HospitalityColors.turmeric),
            _serviceBadge('Ready', ready, const Color(0xFF62C58B)),
            _serviceBadge('Unpaid', unpaid, const Color(0xFFFF9C8F)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 0),
              if (orders.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 42,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: HospitalityColors.surface,
                    borderRadius: BorderRadius.circular(
                      HospitalityRadius.medium,
                    ),
                    border: Border.all(color: HospitalityColors.outline),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 38,
                        color: HospitalityColors.saffron,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No orders yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'New QR, waiter and POS orders will appear here.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1080
                        ? 3
                        : constraints.maxWidth >= 680
                        ? 2
                        : 1;
                    final gap = 12.0;
                    final width =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: orders
                          .map(
                            (order) => SizedBox(
                              width: width,
                              child: _liveOrderCard(context, order),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _operationsHero({
    required String title,
    required String subtitle,
    required List<Widget> badges,
  }) {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return SizedBox(
      height: 190,
      width: double.infinity,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: RoyalAdminColors.navy),
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _OperationsArchPainter()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 36, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.playfairDisplay(
                                color: RoyalAdminColors.goldLight,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: RoyalAdminColors.ivory,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              size: 17,
                              color: RoyalAdminColors.gold,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${now.day} ${months[now.month - 1]}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Wrap(spacing: 8, runSpacing: 6, children: badges),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceBadge(String label, int count, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label + ' ' + count.toString(),
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
    ),
  );

  Widget _liveOrderCard(BuildContext context, Map<String, dynamic> order) {
    final status = (order['status'] ?? 'Pending').toString();
    final payment = (order['paymentStatus'] ?? 'Unpaid').toString();
    final tableData = order['tableId'];
    final table = tableData is Map
        ? (tableData['name'] ?? 'Table').toString()
        : (order['orderType'] ?? 'Takeaway').toString();
    final customer = (order['customerName'] ?? 'Guest').toString();
    final items = (order['items'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final color = _orderStatusColor(status);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RoyalAdminColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12071A31),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.receipt_long_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      table,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Order ' + _id(order['_id']),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Update order status',
                onSelected: (value) => _orderStatus(context, order, value),
                itemBuilder: (_) =>
                    [
                          'Accepted',
                          'Preparing',
                          'Ready',
                          'Served',
                          'Bill Requested',
                          'Cancelled',
                        ]
                        .map(
                          (value) =>
                              PopupMenuItem(value: value, child: Text(value)),
                        )
                        .toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            customer + ' - ' + items.length.toString() + ' line items',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              items
                  .take(2)
                  .map((raw) {
                    final menuItem = raw['menuItem'];
                    final name = menuItem is Map
                        ? (menuItem['name'] ?? 'Menu item')
                        : 'Menu item';
                    return (raw['quantity'] ?? 1).toString() +
                        'x ' +
                        name.toString();
                  })
                  .join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    _orderChip(status, color),
                    _orderChip(
                      payment,
                      payment == 'Paid'
                          ? HospitalityColors.leaf
                          : HospitalityColors.saffron,
                    ),
                  ],
                ),
              ),
              Text(
                'Rs ' + (order['total'] ?? 0).toString(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: HospitalityColors.saffronDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orderChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
    ),
  );

  Color _orderStatusColor(String status) => switch (status) {
    'Ready' => HospitalityColors.leaf,
    'Preparing' => HospitalityColors.saffron,
    'Cancelled' => HospitalityColors.danger,
    'Served' || 'Paid' => const Color(0xFF3456A4),
    _ => const Color(0xFFC58A1D),
  };

  Widget _menu(BuildContext context, List<Map<String, dynamic>> menu) {
    final available = menu.where((item) => item['isAvailable'] != false).length;
    final drafts = menu
        .where((item) => item['publishStatus'] == 'Draft')
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_writeBlocked) _writeNotice(),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: _writeBlocked ? null : () => _editMenuItem(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add menu item'),
            ),
            OutlinedButton.icon(
              onPressed: _writeBlocked ? null : () => _addCategory(context),
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('Add category'),
            ),
            PopupMenuButton<String>(
              enabled: !_writeBlocked || branchId != null,
              tooltip: 'Menu tools',
              onSelected: (value) {
                if (value == 'manage') _manageCategories(context);
                if (value == 'bulk') _bulkMenuActions(context, menu);
                if (value == 'items') _reorderMenu(context, menu);
                if (value == 'categories') _reorderCategoryList(context);
                if (value == 'history') _menuHistory(context);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'manage',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.category_outlined),
                    title: Text('Manage categories'),
                  ),
                ),
                if (menu.isNotEmpty)
                  const PopupMenuItem(
                    value: 'bulk',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.library_add_check_outlined),
                      title: Text('Bulk actions'),
                    ),
                  ),
                if (menu.length > 1)
                  const PopupMenuItem(
                    value: 'items',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.swap_vert_rounded),
                      title: Text('Order menu items'),
                    ),
                  ),
                const PopupMenuItem(
                  value: 'categories',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.low_priority_rounded),
                    title: Text('Order categories'),
                  ),
                ),
                if (branchId != null)
                  const PopupMenuItem(
                    value: 'history',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.history_rounded),
                      title: Text('Change history'),
                    ),
                  ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: HospitalityColors.outline),
                  borderRadius: BorderRadius.circular(HospitalityRadius.medium),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, size: 19),
                    SizedBox(width: 7),
                    Text('Menu tools'),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HospitalityColors.ink,
            borderRadius: BorderRadius.circular(HospitalityRadius.medium),
          ),
          child: Wrap(
            spacing: 18,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your menu',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'What guests see after scanning the table QR.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  _menuSummaryChip(menu.length.toString() + ' items'),
                  _menuSummaryChip(available.toString() + ' live'),
                  if (drafts > 0)
                    _menuSummaryChip(drafts.toString() + ' drafts'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (menu.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: HospitalityColors.surface,
              borderRadius: BorderRadius.circular(HospitalityRadius.medium),
              border: Border.all(color: HospitalityColors.outline),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.restaurant_menu_rounded,
                  size: 36,
                  color: HospitalityColors.saffron,
                ),
                const SizedBox(height: 10),
                Text(
                  'Your menu is empty',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Add your first dish or thali to start taking QR orders.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1060
                  ? 3
                  : constraints.maxWidth >= 680
                  ? 2
                  : 1;
              final gap = 12.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: menu
                    .map(
                      (item) => SizedBox(
                        width: width,
                        child: _menuFoodCard(context, item),
                      ),
                    )
                    .toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _menuSummaryChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _menuFoodCard(BuildContext context, Map<String, dynamic> item) {
    final image = RestaurantApi.mediaUrl(item['imageUrl'] ?? item['image']);
    final hindi = (item['nameHi'] ?? '').toString().trim();
    final category = item['categoryId'] is Map
        ? (item['categoryId']['name'] ?? 'Uncategorized').toString()
        : 'Uncategorized';
    final available = item['isAvailable'] != false;
    final publish = (item['publishStatus'] ?? 'Published').toString();
    return Container(
      height: 164,
      decoration: BoxDecoration(
        color: HospitalityColors.surface,
        borderRadius: BorderRadius.circular(HospitalityRadius.medium),
        border: Border.all(color: HospitalityColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 104,
            height: double.infinity,
            child: image.isEmpty
                ? _menuImageFallback(item)
                : Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _menuImageFallback(item),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          (item['name'] ?? 'Menu item').toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Item actions',
                        onSelected: (action) {
                          if (action == 'preview')
                            _previewMenuItem(context, item);
                          if (action == 'edit')
                            _editMenuItem(context, item: item);
                          if (action == 'duplicate')
                            _duplicateMenuItem(context, item);
                          if (action == 'delete')
                            _deleteMenuItem(context, item);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'preview',
                            child: Text('Customer preview'),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit item'),
                          ),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Text('Duplicate as draft'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete item'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (hindi.isNotEmpty)
                    Text(
                      hindi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rs ' + (item['basePrice'] ?? 0).toString(),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: HospitalityColors.saffronDark,
                                  ),
                            ),
                            Text(
                              publish +
                                  ' - ' +
                                  (available ? 'Available' : 'Unavailable'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: available
                                        ? HospitalityColors.leaf
                                        : HospitalityColors.danger,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: available,
                        onChanged: _writeBlocked
                            ? null
                            : (value) => _availability(context, item, value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuImageFallback(Map<String, dynamic> item) => ColoredBox(
    color: HospitalityColors.softSaffron,
    child: Center(
      child: Icon(
        item['isVeg'] == false ? Icons.set_meal_rounded : Icons.eco_rounded,
        color: HospitalityColors.saffron,
        size: 30,
      ),
    ),
  );

  Future<void> _addCategory(BuildContext context) async {
    final name = TextEditingController();
    final nameHi = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Category name (English)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameHi,
              decoration: const InputDecoration(
                labelText: 'Category name (Hindi, optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != true || name.text.trim().isEmpty || branchId == null) return;
    try {
      await RestaurantApi.createCategory({
        'name': name.text.trim(),
        'nameHi': nameHi.text.trim(),
        'branchId': branchId,
        'isActive': true,
      });
    } catch (error) {
      if (context.mounted) _message(context, RestaurantApi.messageFor(error));
      return;
    }
    if (!context.mounted) return;
    _message(context, 'Category added successfully.');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) reload();
    });
  }

  Future<void> _manageCategories(BuildContext context) async {
    if (branchId == null) return;
    final categories = await RestaurantApi.getCategories(branchId: branchId);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Categories'),
        content: SizedBox(
          width: 430,
          child: categories.isEmpty
              ? const Text('No categories yet.')
              : ListView(
                  shrinkWrap: true,
                  children: categories
                      .map(
                        (category) => ListTile(
                          title: Text('${category['name']}'),
                          trailing: Wrap(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  _renameCategory(context, category);
                                },
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  _deleteCategory(context, category);
                                },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameCategory(
    BuildContext context,
    Map<String, dynamic> category,
  ) async {
    final name = TextEditingController(text: '${category['name'] ?? ''}');
    final nameHi = TextEditingController(text: '${category['nameHi'] ?? ''}');
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Category name (English)',
              ),
            ),
            TextField(
              controller: nameHi,
              decoration: const InputDecoration(
                labelText: 'Category name (Hindi, optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (save != true || name.text.trim().isEmpty) return;
    try {
      await RestaurantApi.updateCategory('${category['_id']}', {
        'name': name.text.trim(),
        'nameHi': nameHi.text.trim(),
      });
      reload();
    } catch (error) {
      if (context.mounted) _message(context, RestaurantApi.messageFor(error));
    }
  }

  Future<void> _deleteCategory(
    BuildContext context,
    Map<String, dynamic> category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'Delete ${category['name']}? Categories containing menu items cannot be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await RestaurantApi.deleteCategory('${category['_id']}');
      reload();
    } catch (error) {
      if (context.mounted) _message(context, RestaurantApi.messageFor(error));
    }
  }

  Future<void> _duplicateMenuItem(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    try {
      await RestaurantApi.duplicateMenuItem('${item['_id']}');
      if (context.mounted) {
        _message(
          context,
          '${item['name']} duplicated as an unavailable draft.',
        );
      }
      reload();
    } catch (error) {
      if (context.mounted) _message(context, RestaurantApi.messageFor(error));
    }
  }

  Future<void> _bulkMenuActions(
    BuildContext context,
    List<Map<String, dynamic>> menu,
  ) async {
    if (branchId == null) return;
    final selected = <String>{};
    var action = 'publish:Published';
    final apply = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 20,
          ),
          title: const Text('Bulk menu actions'),
          content: SizedBox(
            width: 640,
            height: 480,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: action,
                  decoration: const InputDecoration(labelText: 'Action'),
                  items: const [
                    DropdownMenuItem(
                      value: 'publish:Published',
                      child: Text('Publish selected'),
                    ),
                    DropdownMenuItem(
                      value: 'publish:Draft',
                      child: Text('Move selected to draft'),
                    ),
                    DropdownMenuItem(
                      value: 'availability:true',
                      child: Text('Mark selected available'),
                    ),
                    DropdownMenuItem(
                      value: 'availability:false',
                      child: Text('Mark selected unavailable'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) action = value;
                  },
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: selected.length == menu.length,
                  tristate:
                      selected.isNotEmpty && selected.length != menu.length,
                  onChanged: (checked) => setDialogState(() {
                    selected.clear();
                    if (checked == true) {
                      selected.addAll(menu.map((item) => '${item['_id']}'));
                    }
                  }),
                  title: Text('Select all (${menu.length})'),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: menu.length,
                    itemBuilder: (_, index) {
                      final item = menu[index];
                      final id = '${item['_id']}';
                      return CheckboxListTile(
                        value: selected.contains(id),
                        onChanged: (checked) => setDialogState(() {
                          checked == true
                              ? selected.add(id)
                              : selected.remove(id);
                        }),
                        title: Text('${item['name']}'),
                        subtitle: Text(
                          '${item['publishStatus'] ?? 'Published'}',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: Text('Apply to ${selected.length}'),
            ),
          ],
        ),
      ),
    );
    if (apply != true) return;
    final parts = action.split(':');
    final value = parts[0] == 'availability' ? parts[1] == 'true' : parts[1];
    try {
      await RestaurantApi.bulkUpdateMenuItems(
        branchId: branchId!,
        ids: selected.toList(),
        action: parts[0],
        value: value,
      );
      if (context.mounted) _message(context, 'Bulk action completed.');
      reload();
    } catch (error) {
      if (context.mounted) _message(context, RestaurantApi.messageFor(error));
    }
  }

  Future<void> _reorderMenu(
    BuildContext context,
    List<Map<String, dynamic>> menu,
  ) async {
    if (branchId == null) return;
    final ordered = menu.map((item) => Map<String, dynamic>.from(item)).toList()
      ..sort(
        (a, b) => ((a['displayOrder'] as num?) ?? 0).compareTo(
          (b['displayOrder'] as num?) ?? 0,
        ),
      );
    final save = await _showOrderingDialog(
      context,
      'Order menu items',
      ordered,
    );
    if (save != true) return;
    try {
      await RestaurantApi.reorderMenuItems(
        branchId!,
        ordered
            .asMap()
            .entries
            .map((entry) => {'id': '${entry.value['_id']}', 'order': entry.key})
            .toList(),
      );
      reload();
    } catch (error) {
      if (context.mounted) _message(context, RestaurantApi.messageFor(error));
    }
  }

  Future<void> _reorderCategoryList(BuildContext context) async {
    if (branchId == null) return;
    final categories = await RestaurantApi.getCategories(branchId: branchId);
    if (!context.mounted) return;
    if (categories.length < 2) {
      _message(context, 'Add at least two categories to reorder.');
      return;
    }
    categories.sort(
      (a, b) =>
          ((a['order'] as num?) ?? 0).compareTo((b['order'] as num?) ?? 0),
    );
    final save = await _showOrderingDialog(
      context,
      'Order categories',
      categories,
    );
    if (save != true) return;
    try {
      await RestaurantApi.reorderCategories(
        branchId!,
        categories
            .asMap()
            .entries
            .map((entry) => {'id': '${entry.value['_id']}', 'order': entry.key})
            .toList(),
      );
      reload();
    } catch (error) {
      if (context.mounted) _message(context, RestaurantApi.messageFor(error));
    }
  }

  Future<bool?> _showOrderingDialog(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> rows,
  ) => showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (_, setDialogState) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 480,
          height: 470,
          child: ReorderableListView.builder(
            itemCount: rows.length,
            onReorderItem: (oldIndex, newIndex) => setDialogState(() {
              if (newIndex > oldIndex) newIndex--;
              final row = rows.removeAt(oldIndex);
              rows.insert(newIndex, row);
            }),
            itemBuilder: (_, index) => ListTile(
              key: ValueKey('${rows[index]['_id']}'),
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text('${rows[index]['name']}'),
              trailing: const Icon(Icons.drag_handle),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save order'),
          ),
        ],
      ),
    ),
  );

  Future<void> _menuHistory(BuildContext context) async {
    if (branchId == null) return;
    try {
      final history = await RestaurantApi.getMenuHistory(branchId!);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 20,
          ),
          title: const Text('Menu change history'),
          content: SizedBox(
            width: 620,
            height: 500,
            child: history.isEmpty
                ? const Center(child: Text('No menu changes recorded yet.'))
                : ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final entry = history[index];
                      final actor = entry['actorId'] is Map
                          ? entry['actorId']['name']
                          : 'Staff';
                      final date = DateTime.tryParse(
                        '${entry['createdAt']}',
                      )?.toLocal();
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.history)),
                        title: Text(
                          '${entry['action']}  -  ${entry['resourceType']}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${entry['summary'] ?? ''}\n$actor  -  ${date ?? ''}',
                        ),
                        isThreeLine: true,
                        trailing:
                            entry['before'] == null ||
                                LocalStorage.getRole() != 'Restaurant Admin'
                            ? null
                            : TextButton(
                                onPressed: () async {
                                  Navigator.pop(dialogContext);
                                  await _restoreHistory(context, entry);
                                },
                                child: const Text('Restore'),
                              ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (context.mounted) _message(context, RestaurantApi.messageFor(error));
    }
  }

  Future<void> _restoreHistory(
    BuildContext context,
    Map<String, dynamic> entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore previous menu state?'),
        content: const Text(
          'Current values will remain in history, so this action can be audited.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await RestaurantApi.restoreMenuHistory('${entry['_id']}');
      if (context.mounted) _message(context, 'Previous menu state restored.');
      reload();
    } catch (error) {
      if (context.mounted) _message(context, RestaurantApi.messageFor(error));
    }
  }

  Future<void> _previewMenuItem(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final image = RestaurantApi.mediaUrl(item['imageUrl'] ?? item['image']);
    final hindiName = '${item['nameHi'] ?? ''}'.trim();
    final dietary = ((item['dietaryTags'] as List?) ?? const [])
        .map((value) => '$value')
        .toList();
    final allergens = ((item['allergens'] as List?) ?? const [])
        .map((value) => '$value')
        .toList();
    await showDialog<void>(
      context: context,
      builder: (previewContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (image.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      image,
                      height: 190,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        height: 120,
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          Chip(
                            label: Text(
                              '${item['publishStatus'] ?? 'Published'}',
                            ),
                          ),
                          if (item['itemType'] != null)
                            Chip(label: Text('${item['itemType']}')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${item['name'] ?? 'Menu item'}',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (hindiName.isNotEmpty)
                        Text(
                          hindiName,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Rs ${((item['basePrice'] as num?) ?? 0).toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFF236B4E),
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if ('${item['description'] ?? ''}'.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('${item['description']}'),
                      ],
                      if (dietary.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: dietary
                              .map((tag) => Chip(label: Text(tag)))
                              .toList(),
                        ),
                      ],
                      if (allergens.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Contains: ${allergens.join(', ')}',
                          style: const TextStyle(
                            color: Color(0xFFB42318),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (item['publishStatus'] == 'Scheduled' &&
                          item['publishAt'] != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Publishes: ${DateTime.tryParse('${item['publishAt']}')?.toLocal() ?? item['publishAt']}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(previewContext),
                          child: const Text('Close preview'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editMenuItem(
    BuildContext context, {
    Map<String, dynamic>? item,
  }) async {
    if (branchId == null) return;
    final categories = await RestaurantApi.getCategories(branchId: branchId);
    if (!context.mounted) return;
    if (categories.isEmpty) {
      _message(context, 'Create a category first.');
      return;
    }
    final name = TextEditingController(text: '${item?['name'] ?? ''}');
    final nameHi = TextEditingController(text: '${item?['nameHi'] ?? ''}');
    final description = TextEditingController(
      text: '${item?['description'] ?? ''}',
    );
    final descriptionHi = TextEditingController(
      text: '${item?['descriptionHi'] ?? ''}',
    );
    final price = TextEditingController(text: '${item?['basePrice'] ?? ''}');
    final tax = TextEditingController(text: '${item?['taxRate'] ?? 5}');
    final discount = TextEditingController(text: '${item?['discount'] ?? 0}');
    final variantItems = <Map<String, dynamic>>[
      ...((item?['variants'] as List?) ?? const []).whereType<Map>().map(
        (entry) => Map<String, dynamic>.from(entry),
      ),
    ];
    final modifierItems = <Map<String, dynamic>>[
      ...((item?['modifiers'] as List?) ?? const []).whereType<Map>().map(
        (entry) => Map<String, dynamic>.from(entry),
      ),
    ];
    var categoryId = item?['categoryId'] is Map
        ? '${item!['categoryId']['_id']}'
        : '${item?['categoryId'] ?? categories.first['_id']}';
    if (!categories.any((category) => '${category['_id']}' == categoryId))
      categoryId = '${categories.first['_id']}';
    var isVeg = item?['isVeg'] != false;
    var isAvailable = item?['isAvailable'] != false;
    const publishStatuses = <String>['Draft', 'Published', 'Scheduled'];
    var publishStatus = '${item?['publishStatus'] ?? 'Published'}';
    if (!publishStatuses.contains(publishStatus)) publishStatus = 'Published';
    DateTime? publishAt = DateTime.tryParse(
      '${item?['publishAt'] ?? ''}',
    )?.toLocal();
    const spiceLevels = <String>['None', 'Mild', 'Medium', 'Hot', 'Extra Hot'];
    const dietaryOptions = <String>[
      'Vegan',
      'Jain',
      'Gluten-Free',
      'Dairy-Free',
      'Nut-Free',
      'High-Protein',
    ];
    const allergenOptions = <String>[
      'Milk',
      'Nuts',
      'Gluten',
      'Soy',
      'Egg',
      'Sesame',
    ];
    var spiceLevel = '${item?['spiceLevel'] ?? 'None'}';
    if (!spiceLevels.contains(spiceLevel)) spiceLevel = 'None';
    final dietaryTags = <String>{
      ...((item?['dietaryTags'] as List?) ?? const []).map((value) => '$value'),
    };
    final allergens = <String>{
      ...((item?['allergens'] as List?) ?? const []).map((value) => '$value'),
    };
    const itemTypes = <String>[
      'Single Item',
      'Combo',
      'Thali',
      'Buffet',
      'Customizable Meal',
    ];
    var itemType = '${item?['itemType'] ?? 'Single Item'}';
    if (!itemTypes.contains(itemType)) itemType = 'Single Item';
    final savedThali = item?['thaliConfig'] is Map
        ? Map<String, dynamic>.from(item!['thaliConfig'] as Map)
        : <String, dynamic>{};
    var serviceType = '${savedThali['serviceType'] ?? 'Limited'}';
    var dineInOnly = savedThali['dineInOnly'] != false;
    final servingDuration = TextEditingController(
      text: '${savedThali['servingDurationMinutes'] ?? 60}',
    );
    final includedItems = <Map<String, dynamic>>[
      ...((savedThali['includedItems'] as List?) ?? const [])
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry)),
    ];
    const weekDays = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final schedule = item?['availabilitySchedule'] is Map
        ? Map<String, dynamic>.from(item!['availabilitySchedule'] as Map)
        : <String, dynamic>{};
    final selectedDays = <String>{
      ...((schedule['days'] as List?) ?? const []).map((day) => '$day'),
    };
    final startTime = TextEditingController(
      text: '${schedule['startTime'] ?? ''}',
    );
    final endTime = TextEditingController(text: '${schedule['endTime'] ?? ''}');
    PlatformFile? selectedPhoto;
    Uint8List? selectedPhotoBytes;
    var imageUrl = (item?['imageUrl'] ?? item?['image'] ?? '')
        .toString()
        .trim();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 760,
              maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.90,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu_rounded,
                          color: Color(0xFFD66A2C),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item == null ? 'Add menu item' : 'Edit menu item',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Add details, pricing and availability before publishing.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(dialogContext, false),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _menuFormHeading(
                            dialogContext,
                            'Basic details',
                            'English and Hindi information shown to guests',
                          ),
                          TextField(
                            controller: name,
                            decoration: const InputDecoration(
                              labelText: 'Item name (English)',
                            ),
                          ),
                          TextField(
                            controller: nameHi,
                            decoration: const InputDecoration(
                              labelText: 'Item name (Hindi, optional)',
                            ),
                          ),
                          TextField(
                            controller: description,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Description (English)',
                            ),
                          ),
                          TextField(
                            controller: descriptionHi,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Description (Hindi, optional)',
                            ),
                          ),
                          const SizedBox(height: 12),
                          _menuFormHeading(
                            dialogContext,
                            'Food photo',
                            'A clear landscape image works best',
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8F1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: selectedPhotoBytes != null
                                      ? Image.memory(
                                          selectedPhotoBytes!,
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                        )
                                      : imageUrl.isNotEmpty
                                      ? Image.network(
                                          RestaurantApi.mediaUrl(imageUrl),
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const SizedBox(
                                                width: 64,
                                                height: 64,
                                                child: Icon(
                                                  Icons.broken_image_outlined,
                                                ),
                                              ),
                                        )
                                      : const SizedBox(
                                          width: 64,
                                          height: 64,
                                          child: Icon(
                                            Icons.add_photo_alternate_outlined,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Food photo',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        selectedPhoto?.name ??
                                            (imageUrl.isEmpty
                                                ? 'JPEG, PNG or WebP - max 3 MB'
                                                : 'Current photo'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final file = await FilePicker.pickFile(
                                      type: FileType.custom,
                                      allowedExtensions: const [
                                        'jpg',
                                        'jpeg',
                                        'png',
                                        'webp',
                                      ],
                                    );
                                    if (file == null) return;
                                    final length = await file.length();
                                    if (length > 3 * 1024 * 1024) {
                                      if (dialogContext.mounted) {
                                        _message(
                                          dialogContext,
                                          'Choose an image smaller than 3 MB.',
                                        );
                                      }
                                      return;
                                    }
                                    final bytes = await file.readAsBytes();
                                    setDialogState(() {
                                      selectedPhoto = file;
                                      selectedPhotoBytes = bytes;
                                    });
                                  },
                                  child: Text(
                                    imageUrl.isEmpty ? 'Choose' : 'Replace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _menuFormHeading(
                            dialogContext,
                            'Menu setup',
                            'Category, meal type and guest preferences',
                          ),
                          DropdownButtonFormField<String>(
                            initialValue: categoryId,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                            ),
                            items: categories
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: '${category['_id']}',
                                    child: Text('${category['name']}'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) categoryId = value;
                            },
                          ),
                          DropdownButtonFormField<String>(
                            initialValue: itemType,
                            decoration: const InputDecoration(
                              labelText: 'Item type',
                            ),
                            items: itemTypes
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => itemType = value);
                              }
                            },
                          ),
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: const Text('Dietary, spice & allergens'),
                            subtitle: const Text(
                              'Optional customer-facing details',
                            ),
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: spiceLevel,
                                decoration: const InputDecoration(
                                  labelText: 'Spice level',
                                  prefixIcon: Icon(
                                    Icons.local_fire_department_outlined,
                                  ),
                                ),
                                items: spiceLevels
                                    .map(
                                      (level) => DropdownMenuItem(
                                        value: level,
                                        child: Text(level),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() => spiceLevel = value);
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Dietary tags',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                  spacing: 7,
                                  runSpacing: 7,
                                  children: dietaryOptions
                                      .map(
                                        (tag) => FilterChip(
                                          label: Text(tag),
                                          selected: dietaryTags.contains(tag),
                                          onSelected: (selected) =>
                                              setDialogState(() {
                                                selected
                                                    ? dietaryTags.add(tag)
                                                    : dietaryTags.remove(tag);
                                              }),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Contains allergens',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Select every allergen present in this item.',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                  spacing: 7,
                                  runSpacing: 7,
                                  children: allergenOptions
                                      .map(
                                        (allergen) => FilterChip(
                                          label: Text(allergen),
                                          selected: allergens.contains(
                                            allergen,
                                          ),
                                          selectedColor: const Color(
                                            0xFFFFD8D2,
                                          ),
                                          onSelected: (selected) =>
                                              setDialogState(() {
                                                selected
                                                    ? allergens.add(allergen)
                                                    : allergens.remove(
                                                        allergen,
                                                      );
                                              }),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                          if (itemType == 'Thali') ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8F1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFFFD8BA),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Thali setup',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SegmentedButton<String>(
                                    segments: const [
                                      ButtonSegment(
                                        value: 'Limited',
                                        label: Text('Limited'),
                                      ),
                                      ButtonSegment(
                                        value: 'Unlimited',
                                        label: Text('Unlimited'),
                                      ),
                                    ],
                                    selected: {serviceType},
                                    onSelectionChanged: (value) =>
                                        setDialogState(
                                          () => serviceType = value.first,
                                        ),
                                  ),
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    value: dineInOnly,
                                    onChanged: (value) => setDialogState(
                                      () => dineInOnly = value,
                                    ),
                                    title: const Text('Dine-in only'),
                                    subtitle: const Text(
                                      'Recommended for refill-based thalis',
                                    ),
                                  ),
                                  TextField(
                                    controller: servingDuration,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Serving duration (minutes)',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Included dishes',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () async {
                                          final dish = await _editThaliDish(
                                            dialogContext,
                                          );
                                          if (dish != null) {
                                            setDialogState(
                                              () => includedItems.add(dish),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add dish'),
                                      ),
                                    ],
                                  ),
                                  if (includedItems.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      child: Text('Add at least one dish.'),
                                    ),
                                  ...includedItems.asMap().entries.map((entry) {
                                    final dish = entry.value;
                                    final refill =
                                        '${dish['refillPolicy'] ?? 'None'}';
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      title: Text(
                                        '${dish['name'] ?? ''}${('${dish['nameHi'] ?? ''}').isEmpty ? '' : '  -  ${dish['nameHi']}'}',
                                      ),
                                      subtitle: Text(
                                        '${dish['quantity']} ${dish['unit']}  -  Refill: $refill${refill == 'Limited' ? ' (${dish['refillLimit']})' : ''}',
                                      ),
                                      trailing: Wrap(
                                        children: [
                                          IconButton(
                                            tooltip: 'Edit dish',
                                            onPressed: () async {
                                              final updated =
                                                  await _editThaliDish(
                                                    dialogContext,
                                                    dish: dish,
                                                  );
                                              if (updated != null) {
                                                setDialogState(
                                                  () =>
                                                      includedItems[entry.key] =
                                                          updated,
                                                );
                                              }
                                            },
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Remove dish',
                                            onPressed: () => setDialogState(
                                              () => includedItems.removeAt(
                                                entry.key,
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: const Text('Availability schedule'),
                            subtitle: const Text(
                              'Uses the branch timezone configured in Settings',
                            ),
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: weekDays
                                      .map(
                                        (day) => FilterChip(
                                          label: Text(day.substring(0, 3)),
                                          selected: selectedDays.contains(day),
                                          onSelected: (selected) =>
                                              setDialogState(() {
                                                selected
                                                    ? selectedDays.add(day)
                                                    : selectedDays.remove(day);
                                              }),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: startTime,
                                      decoration: const InputDecoration(
                                        labelText: 'Start time (HH:mm)',
                                        hintText: '11:00',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: endTime,
                                      decoration: const InputDecoration(
                                        labelText: 'End time (HH:mm)',
                                        hintText: '16:00',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          _menuFormHeading(
                            dialogContext,
                            'Pricing',
                            'Base price, tax and optional discount',
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: price,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Base price',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: tax,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Tax %',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: discount,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Discount %',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _menuOptionSection(
                            title: 'Variants',
                            emptyText: 'No variants. Base price will be used.',
                            addLabel: 'Add variant',
                            items: variantItems,
                            onAdd: () async {
                              final value = await _editMenuOption(
                                dialogContext,
                                isVariant: true,
                              );
                              if (value != null) {
                                setDialogState(() => variantItems.add(value));
                              }
                            },
                            onEdit: (index) async {
                              final value = await _editMenuOption(
                                dialogContext,
                                isVariant: true,
                                option: variantItems[index],
                              );
                              if (value != null) {
                                setDialogState(
                                  () => variantItems[index] = value,
                                );
                              }
                            },
                            onDelete: (index) => setDialogState(
                              () => variantItems.removeAt(index),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _menuOptionSection(
                            title: 'Add-ons',
                            emptyText: 'No optional extras added.',
                            addLabel: 'Add add-on',
                            items: modifierItems,
                            onAdd: () async {
                              final value = await _editMenuOption(
                                dialogContext,
                                isVariant: false,
                              );
                              if (value != null) {
                                setDialogState(() => modifierItems.add(value));
                              }
                            },
                            onEdit: (index) async {
                              final value = await _editMenuOption(
                                dialogContext,
                                isVariant: false,
                                option: modifierItems[index],
                              );
                              if (value != null) {
                                setDialogState(
                                  () => modifierItems[index] = value,
                                );
                              }
                            },
                            onDelete: (index) => setDialogState(
                              () => modifierItems.removeAt(index),
                            ),
                          ),
                          SwitchListTile(
                            value: isVeg,
                            onChanged: (value) =>
                                setDialogState(() => isVeg = value),
                            title: const Text('Vegetarian'),
                          ),
                          SwitchListTile(
                            value: isAvailable,
                            onChanged: (value) =>
                                setDialogState(() => isAvailable = value),
                            title: const Text('Available'),
                            subtitle: const Text(
                              'Kitchen can currently prepare this item',
                            ),
                          ),
                          const Divider(),
                          _menuFormHeading(
                            dialogContext,
                            'Publishing',
                            'Control when this item appears on the QR menu',
                          ),
                          DropdownButtonFormField<String>(
                            initialValue: publishStatus,
                            decoration: const InputDecoration(
                              labelText: 'Customer menu status',
                              prefixIcon: Icon(Icons.publish_outlined),
                            ),
                            items: publishStatuses
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  publishStatus = value;
                                  if (value != 'Scheduled') publishAt = null;
                                });
                              }
                            },
                          ),
                          if (publishStatus == 'Scheduled')
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.schedule,
                                color: Color(0xFFD66A2C),
                              ),
                              title: Text(
                                publishAt == null
                                    ? 'Choose publish date and time'
                                    : MaterialLocalizations.of(
                                        dialogContext,
                                      ).formatFullDate(publishAt!),
                              ),
                              subtitle: Text(
                                publishAt == null
                                    ? 'Required - uses an exact time'
                                    : TimeOfDay.fromDateTime(
                                        publishAt!,
                                      ).format(dialogContext),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                final initial =
                                    publishAt ??
                                    DateTime.now().add(
                                      const Duration(hours: 1),
                                    );
                                final date = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: initial,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 730),
                                  ),
                                );
                                if (date == null || !dialogContext.mounted)
                                  return;
                                final time = await showTimePicker(
                                  context: dialogContext,
                                  initialTime: TimeOfDay.fromDateTime(initial),
                                );
                                if (time == null) return;
                                setDialogState(() {
                                  publishAt = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Save item'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (saved != true) return;
    final basePrice = double.tryParse(price.text);
    if (name.text.trim().isEmpty || basePrice == null || basePrice < 0) {
      if (context.mounted) {
        _message(context, 'Enter a valid item name and price.');
      }
      return;
    }
    if (publishStatus == 'Scheduled' &&
        (publishAt == null || !publishAt!.isAfter(DateTime.now()))) {
      if (context.mounted) {
        _message(context, 'Choose a future publish date and time.');
      }
      return;
    }
    if (itemType == 'Thali' && includedItems.isEmpty) {
      if (context.mounted) {
        _message(context, 'Add at least one dish to the thali.');
      }
      return;
    }
    final duration = int.tryParse(servingDuration.text);
    if (itemType == 'Thali' &&
        (duration == null || duration < 10 || duration > 300)) {
      if (context.mounted) {
        _message(context, 'Serving duration must be 10 to 300 minutes.');
      }
      return;
    }
    final timePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
    if ((startTime.text.isNotEmpty && !timePattern.hasMatch(startTime.text)) ||
        (endTime.text.isNotEmpty && !timePattern.hasMatch(endTime.text))) {
      if (context.mounted) {
        _message(context, 'Use HH:mm format for availability time.');
      }
      return;
    }
    if (_hasDuplicateOptionNames(variantItems) ||
        _hasDuplicateOptionNames(modifierItems)) {
      if (context.mounted) {
        _message(context, 'Variant and add-on names must be unique.');
      }
      return;
    }
    if (selectedPhoto != null) {
      try {
        imageUrl = await RestaurantApi.uploadImage(
          selectedPhotoBytes!,
          selectedPhoto!.name,
        );
      } catch (error) {
        if (context.mounted) {
          _message(context, RestaurantApi.messageFor(error));
        }
        return;
      }
    }
    final body = {
      'branchId': branchId,
      'categoryId': categoryId,
      'itemType': itemType,
      'name': name.text.trim(),
      'nameHi': nameHi.text.trim(),
      'description': description.text.trim(),
      'descriptionHi': descriptionHi.text.trim(),
      'imageUrl': imageUrl,
      'basePrice': basePrice,
      'taxRate': double.tryParse(tax.text) ?? 0,
      'discount': double.tryParse(discount.text) ?? 0,
      'variants': variantItems,
      'modifiers': modifierItems,
      'isVeg': isVeg,
      'spiceLevel': spiceLevel,
      'dietaryTags': dietaryTags.toList(),
      'allergens': allergens.toList(),
      'isAvailable': isAvailable,
      'publishStatus': publishStatus,
      'publishAt': publishStatus == 'Scheduled'
          ? publishAt!.toUtc().toIso8601String()
          : null,
      'thaliConfig': itemType == 'Thali'
          ? {
              'serviceType': serviceType,
              'dineInOnly': dineInOnly,
              'servingDurationMinutes': duration,
              'includedItems': includedItems,
            }
          : null,
      'availabilitySchedule':
          selectedDays.isEmpty &&
              startTime.text.trim().isEmpty &&
              endTime.text.trim().isEmpty
          ? null
          : {
              'days': selectedDays.toList(),
              'startTime': startTime.text.trim(),
              'endTime': endTime.text.trim(),
            },
    };
    try {
      if (item == null) {
        await RestaurantApi.createMenuItem(body);
      } else {
        await RestaurantApi.updateMenuItem('${item['_id']}', body);
      }
      reload();
    } catch (error) {
      if (context.mounted) _message(context, RestaurantApi.messageFor(error));
    }
  }

  Widget _menuFormHeading(
    BuildContext context,
    String title,
    String subtitle,
  ) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 10),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );

  Widget _menuOptionSection({
    required String title,
    required String emptyText,
    required String addLabel,
    required List<Map<String, dynamic>> items,
    required VoidCallback onAdd,
    required ValueChanged<int> onEdit,
    required ValueChanged<int> onDelete,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F5FC),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE3D9EE)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(addLabel),
            ),
          ],
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              emptyText,
              style: const TextStyle(color: Colors.black54),
            ),
          )
        else
          ...items.asMap().entries.map((entry) {
            final option = entry.value;
            final hindi = '${option['nameHi'] ?? ''}'.trim();
            return ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                '${option['name'] ?? ''}${hindi.isEmpty ? '' : '  -  $hindi'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: (option['sku']?.toString().trim().isNotEmpty ?? false)
                  ? Text('SKU: ${option['sku']}')
                  : null,
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFFFF1D6),
                child: Text(
                  'Rs ${((option['price'] as num?) ?? 0).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              trailing: Wrap(
                spacing: 0,
                children: [
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () => onEdit(entry.key),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: () => onDelete(entry.key),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            );
          }),
      ],
    ),
  );

  Future<Map<String, dynamic>?> _editMenuOption(
    BuildContext context, {
    required bool isVariant,
    Map<String, dynamic>? option,
  }) async {
    final name = TextEditingController(text: '${option?['name'] ?? ''}');
    final nameHi = TextEditingController(text: '${option?['nameHi'] ?? ''}');
    final price = TextEditingController(text: '${option?['price'] ?? ''}');
    final sku = TextEditingController(text: '${option?['sku'] ?? ''}');
    var errorText = '';
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (optionContext) => StatefulBuilder(
        builder: (_, setOptionState) => AlertDialog(
          title: Text(
            '${option == null ? 'Add' : 'Edit'} ${isVariant ? 'variant' : 'add-on'}',
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    autofocus: true,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Name (English)',
                    ),
                  ),
                  TextField(
                    controller: nameHi,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Item name (Hindi, optional)',
                    ),
                  ),
                  TextField(
                    controller: price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: isVariant ? 'Selling price' : 'Extra price',
                      prefixText: 'Rs  ',
                    ),
                  ),
                  if (isVariant)
                    TextField(
                      controller: sku,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        labelText: 'SKU (optional)',
                        hintText: 'THALI-LARGE',
                      ),
                    ),
                  if (errorText.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        errorText,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(optionContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(price.text);
                if (name.text.trim().isEmpty || amount == null || amount < 0) {
                  setOptionState(() {
                    errorText = 'Enter a valid name and price.';
                  });
                  return;
                }
                Navigator.pop(optionContext, <String, dynamic>{
                  'name': name.text.trim(),
                  'nameHi': nameHi.text.trim(),
                  'price': amount,
                  if (isVariant) 'sku': sku.text.trim(),
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasDuplicateOptionNames(List<Map<String, dynamic>> items) {
    final names = items
        .map((entry) => '${entry['name'] ?? ''}'.trim().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toList();
    return names.toSet().length != names.length;
  }

  Future<Map<String, dynamic>?> _editThaliDish(
    BuildContext context, {
    Map<String, dynamic>? dish,
  }) async {
    final name = TextEditingController(text: '${dish?['name'] ?? ''}');
    final nameHi = TextEditingController(text: '${dish?['nameHi'] ?? ''}');
    final quantity = TextEditingController(text: '${dish?['quantity'] ?? 1}');
    final unit = TextEditingController(text: '${dish?['unit'] ?? 'portion'}');
    final refillLimit = TextEditingController(
      text: '${dish?['refillLimit'] ?? 1}',
    );
    final extraPrice = TextEditingController(
      text: '${dish?['extraServingPrice'] ?? 0}',
    );
    var refillPolicy = '${dish?['refillPolicy'] ?? 'None'}';
    var isRequired = dish?['isRequired'] != false;
    var replacementAllowed = dish?['replacementAllowed'] == true;
    var errorText = '';
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dishContext) => StatefulBuilder(
        builder: (_, setDishState) => AlertDialog(
          title: Text(
            dish == null ? 'Add included dish' : 'Edit included dish',
          ),
          content: SizedBox(
            width: 430,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Dish name (English)',
                    ),
                  ),
                  TextField(
                    controller: nameHi,
                    decoration: const InputDecoration(
                      labelText: 'Item name (Hindi, optional)',
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: quantity,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: unit,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            hintText: 'piece / bowl',
                          ),
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: refillPolicy,
                    decoration: const InputDecoration(labelText: 'Refill rule'),
                    items: const ['None', 'Limited', 'Unlimited']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDishState(() => refillPolicy = value);
                      }
                    },
                  ),
                  if (refillPolicy == 'Limited')
                    TextField(
                      controller: refillLimit,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Maximum refills',
                      ),
                    ),
                  TextField(
                    controller: extraPrice,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Extra serving price',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isRequired,
                    onChanged: (value) =>
                        setDishState(() => isRequired = value),
                    title: const Text('Required in thali'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: replacementAllowed,
                    onChanged: (value) =>
                        setDishState(() => replacementAllowed = value),
                    title: const Text('Customer may request replacement'),
                  ),
                  if (errorText.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        errorText,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dishContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(quantity.text);
                final limit = int.tryParse(refillLimit.text);
                final servingPrice = double.tryParse(extraPrice.text);
                if (name.text.trim().isEmpty ||
                    amount == null ||
                    amount <= 0 ||
                    unit.text.trim().isEmpty ||
                    servingPrice == null ||
                    servingPrice < 0 ||
                    (refillPolicy == 'Limited' &&
                        (limit == null || limit < 1))) {
                  setDishState(() {
                    errorText =
                        'Enter valid dish, quantity and refill details.';
                  });
                  return;
                }
                Navigator.pop(dishContext, <String, dynamic>{
                  'name': name.text.trim(),
                  'nameHi': nameHi.text.trim(),
                  'quantity': amount,
                  'unit': unit.text.trim(),
                  'refillPolicy': refillPolicy,
                  if (refillPolicy == 'Limited') 'refillLimit': limit,
                  'extraServingPrice': servingPrice,
                  'isRequired': isRequired,
                  'replacementAllowed': replacementAllowed,
                });
              },
              child: const Text('Save dish'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _availability(
    BuildContext context,
    Map<String, dynamic> item,
    bool value,
  ) async {
    try {
      await RestaurantApi.setMenuItemAvailability('${item['_id']}', value);
      reload();
    } catch (error) {
      if (context.mounted) _message(context, RestaurantApi.messageFor(error));
    }
  }

  Future<void> _deleteMenuItem(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete menu item?'),
        content: Text('${item['name']} will be removed from this branch.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await RestaurantApi.deleteMenuItem('${item['_id']}');
      reload();
    } catch (error) {
      if (context.mounted) _message(context, RestaurantApi.messageFor(error));
    }
  }

  Widget _tables(BuildContext context, List<Map<String, dynamic>> tables) {
    final available = tables
        .where((table) => table['status'] == 'Available')
        .length;
    final occupied = tables
        .where((table) => table['status'] == 'Occupied')
        .length;
    final cleaning = tables
        .where((table) => table['status'] == 'Cleaning')
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _operationsHero(
          title: 'Dining floor',
          subtitle: 'Manage tables, readiness and QR ordering.',
          badges: [
            _floorBadge('Available', available, const Color(0xFF62C58B)),
            _floorBadge('Occupied', occupied, HospitalityColors.turmeric),
            _floorBadge('Cleaning', cleaning, const Color(0xFFFF9C8F)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_writeBlocked) _writeNotice(),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _writeBlocked ? null : () => _editTable(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add table'),
              ),
              const SizedBox(height: 14),
              if (tables.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 42,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: HospitalityColors.surface,
                    borderRadius: BorderRadius.circular(
                      HospitalityRadius.medium,
                    ),
                    border: Border.all(color: HospitalityColors.outline),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.table_restaurant_outlined,
                        size: 38,
                        color: HospitalityColors.saffron,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No tables added',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Add a table to generate its secure customer QR.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1080
                        ? 4
                        : constraints.maxWidth >= 760
                        ? 3
                        : constraints.maxWidth >= 500
                        ? 2
                        : 1;
                    final gap = 12.0;
                    final width =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: tables
                          .map(
                            (table) => SizedBox(
                              width: width,
                              child: _tableVisualCard(context, table),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _floorBadge(String label, int value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label + ' ' + value.toString(),
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
    ),
  );

  Widget _tableVisualCard(BuildContext context, Map<String, dynamic> table) {
    final name = (table['name'] ?? 'Table').toString();
    final status = (table['status'] ?? 'Available').toString();
    final qrActive = table['qrTokenActive'] != false;
    final color = _tableStatusColor(status);
    final circular = table['shape'] == 'Circle';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HospitalityColors.surface,
        borderRadius: BorderRadius.circular(HospitalityRadius.medium),
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  shape: circular ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: circular ? null : BorderRadius.circular(13),
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Icon(
                  Icons.table_restaurant_rounded,
                  color: color,
                  size: 27,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      (table['capacity'] ?? 0).toString() + ' seats',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Table actions',
                onSelected: (action) => _tableAction(context, table, action),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'Available',
                    child: Text('Mark available'),
                  ),
                  PopupMenuItem(
                    value: 'Occupied',
                    child: Text('Mark occupied'),
                  ),
                  PopupMenuItem(
                    value: 'Reserved',
                    child: Text('Mark reserved'),
                  ),
                  PopupMenuItem(
                    value: 'Cleaning',
                    child: Text('Mark cleaning'),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 'edit', child: Text('Edit table')),
                  PopupMenuItem(value: 'qr', child: Text('Generate new QR')),
                  PopupMenuItem(
                    value: 'toggleQr',
                    child: Text('Activate / deactivate QR'),
                  ),
                  PopupMenuItem(value: 'delete', child: Text('Delete table')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _tableStateChip(status, color)),
              const SizedBox(width: 6),
              _tableStateChip(
                qrActive ? 'QR active' : 'QR paused',
                qrActive ? HospitalityColors.leaf : HospitalityColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _writeBlocked
                      ? null
                      : () => _tableAction(context, table, 'qr'),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                  label: const Text('New QR'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: qrActive
                    ? 'Pause QR ordering'
                    : 'Activate QR ordering',
                onPressed: _writeBlocked
                    ? null
                    : () => _tableAction(context, table, 'toggleQr'),
                icon: Icon(
                  qrActive
                      ? Icons.pause_circle_outline_rounded
                      : Icons.play_circle_outline_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableStateChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
    ),
  );

  Color _tableStatusColor(String status) => switch (status) {
    'Occupied' => HospitalityColors.saffron,
    'Reserved' => const Color(0xFF7546A8),
    'Cleaning' => const Color(0xFF3456A4),
    _ => HospitalityColors.leaf,
  };

  Future<void> _tableAction(
    BuildContext context,
    Map<String, dynamic> table,
    String action,
  ) async {
    if (['Available', 'Occupied', 'Reserved', 'Cleaning'].contains(action)) {
      await _tableStatus(context, table, action);
      return;
    }
    if (action == 'edit') {
      await _editTable(context, table: table);
      return;
    }
    if (action == 'qr') {
      await _rotateQr(context, table);
      return;
    }
    if (action == 'toggleQr') {
      try {
        await RestaurantApi.setTableQrActive(
          '${table['_id']}',
          table['qrTokenActive'] == false,
        );
        reload();
      } catch (error) {
        if (context.mounted) _message(context, RestaurantApi.messageFor(error));
      }
      return;
    }
    if (action == 'delete') await _deleteTable(context, table);
  }

  Future<void> _editTable(
    BuildContext context, {
    Map<String, dynamic>? table,
  }) async {
    if (branchId == null) return;
    final name = TextEditingController(text: '${table?['name'] ?? ''}');
    final capacity = TextEditingController(text: '${table?['capacity'] ?? 4}');
    var shape = '${table?['shape'] ?? 'Rectangle'}';
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 20,
          ),
          title: Text(table == null ? 'Add table' : 'Edit table'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Table name / number',
                  ),
                ),
                TextField(
                  controller: capacity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Capacity'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: shape,
                  decoration: const InputDecoration(labelText: 'Shape'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Rectangle',
                      child: Text('Rectangle'),
                    ),
                    DropdownMenuItem(value: 'Circle', child: Text('Circle')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => shape = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    final seats = int.tryParse(capacity.text);
    if (name.text.trim().isEmpty || seats == null || seats < 1) {
      if (context.mounted)
        _message(context, 'Enter a valid table name and capacity.');
      return;
    }
    try {
      if (table == null) {
        final created = await RestaurantApi.createTable({
          'branchId': branchId,
          'name': name.text.trim(),
          'capacity': seats,
          'shape': shape,
        });
        if (context.mounted && created['qrToken'] != null)
          await _showQr(
            context,
            '${created['name'] ?? name.text}',
            '${created['qrToken']}',
          );
      } else {
        await RestaurantApi.updateTable('${table['_id']}', {
          'name': name.text.trim(),
          'capacity': seats,
          'shape': shape,
        });
      }
      reload();
    } catch (error) {
      if (context.mounted) _message(context, RestaurantApi.messageFor(error));
    }
  }

  Future<void> _rotateQr(
    BuildContext context,
    Map<String, dynamic> table,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Generate new QR?'),
        content: const Text('The previous QR will stop working immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final result = await RestaurantApi.rotateTableQr('${table['_id']}');
      if (context.mounted)
        await _showQr(context, '${table['name']}', '${result['qrToken']}');
      reload();
    } catch (error) {
      if (context.mounted) _message(context, RestaurantApi.messageFor(error));
    }
  }

  String _customerQrUrl(String token) {
    const configured = String.fromEnvironment('CUSTOMER_APP_URL');
    final base = configured.trim().replaceFirst(RegExp(r'/$'), '');
    if (base.isNotEmpty) return '$base/table/${Uri.encodeComponent(token)}';
    if (kIsWeb && Uri.base.hasAuthority) {
      return '${Uri.base.origin}/table/${Uri.encodeComponent(token)}';
    }
    return token;
  }

  Future<void> _showQr(
    BuildContext context,
    String tableName,
    String token,
  ) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('$tableName QR'),
      content: SizedBox(
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: _customerQrUrl(token),
              size: 220,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 10),
            const Text(
              "Save or print this QR. Scanning it opens this table's customer menu.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () =>
              _downloadQr(context, tableName, _customerQrUrl(token)),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Download PNG'),
        ),
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: _customerQrUrl(token)));
            if (dialogContext.mounted)
              _message(dialogContext, 'Customer QR link copied.');
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy token'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Done'),
        ),
      ],
    ),
  );

  Future<void> _downloadQr(
    BuildContext context,
    String tableName,
    String token,
  ) async {
    try {
      final painter = QrPainter(
        data: token,
        version: QrVersions.auto,
        gapless: true,
        color: Colors.black,
        emptyColor: Colors.white,
      );
      final byteData = await painter.toImageData(
        1024,
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) throw StateError('Could not render QR image.');
      final safeName = tableName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      await downloadQrPng(byteData.buffer.asUint8List(), '${safeName}_QR.png');
    } catch (error) {
      if (context.mounted)
        _message(
          context,
          error.toString().replaceFirst('Unsupported operation: ', ''),
        );
    }
  }

  Future<void> _deleteTable(
    BuildContext context,
    Map<String, dynamic> table,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete table?'),
        content: Text(
          '${table['name']} must be Available and have no active customer session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await RestaurantApi.deleteTable('${table['_id']}');
      reload();
    } catch (error) {
      if (context.mounted) _message(context, RestaurantApi.messageFor(error));
    }
  }

  String _id(dynamic raw) {
    final value = '$raw';
    return value.length > 6
        ? value.substring(value.length - 6).toUpperCase()
        : value;
  }

  Future<void> _orderStatus(
    BuildContext context,
    Map<String, dynamic> order,
    String status,
  ) async {
    try {
      await RestaurantApi.updateOrderStatus('${order['_id']}', status);
      reload();
    } catch (error) {
      if (context.mounted) {
        _message(context, RestaurantApi.messageFor(error));
      }
    }
  }

  Future<void> _tableStatus(
    BuildContext context,
    Map<String, dynamic> table,
    String status,
  ) async {
    try {
      await RestaurantApi.updateTableStatus('${table['_id']}', status);
      reload();
    } catch (error) {
      if (context.mounted) {
        _message(context, RestaurantApi.messageFor(error));
      }
    }
  }

  void _message(BuildContext context, String text) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
}

class _OperationsArchPainter extends CustomPainter {
  const _OperationsArchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..color = RoyalAdminColors.gold.withValues(alpha: .52)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final faint = Paint()
      ..color = RoyalAdminColors.gold.withValues(alpha: .14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = size.width / 2;
    final arch = Path()
      ..moveTo(15, 82)
      ..cubicTo(15, 26, center - 82, 42, center, 8)
      ..cubicTo(center + 82, 42, size.width - 15, 26, size.width - 15, 82);
    canvas.drawPath(arch, gold);
    canvas.drawLine(const Offset(15, 0), const Offset(15, 82), faint);
    canvas.drawLine(
      Offset(size.width - 15, 0),
      Offset(size.width - 15, 82),
      faint,
    );
  }

  @override
  bool shouldRepaint(covariant _OperationsArchPainter oldDelegate) => false;
}
