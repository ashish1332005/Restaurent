import 'package:flutter/material.dart';

import '../../../../core/network/restaurant_api.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/admin_ui.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});
  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    future = RestaurantApi.getAdminCoupons();
  }

  void reload() => setState(() => future = RestaurantApi.getAdminCoupons());

  @override
  Widget build(BuildContext context) => Padding(
    padding: adminPagePadding(context),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminPageHeader(
          eyebrow: 'PROMOTION HUB',
          title: 'Offers & Coupons',
          subtitle:
              'Create secure coupons that appear instantly in the customer app.',
          trailing: ElevatedButton.icon(
            onPressed: _create,
            icon: const Icon(Icons.add),
            label: const Text('Create Coupon'),
          ),
        ),
        const SizedBox(height: 22),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(RestaurantApi.messageFor(snapshot.error!)),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: reload,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                );
              }
              final rows = snapshot.data ?? const [];
              if (rows.isEmpty) {
                return const Center(
                  child: Text(
                    'No deals found',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                );
              }
              return AdminPanel(
                child: ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, i) {
                    final item = rows[i];
                    final active = item['isActive'] == true;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE8F1FF),
                        child: const Icon(
                          Icons.percent,
                          color: Color(0xFF1565D8),
                        ),
                      ),
                      title: Text(
                        item['code']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        '${item['description'] ?? ''}\nMinimum order: ₹${item['minOrder'] ?? 0}  •  Used: ${item['usedCount'] ?? 0}/${item['usageLimit'] ?? 'Unlimited'}',
                      ),
                      isThreeLine: true,
                      trailing: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Switch(
                            value: active,
                            onChanged: (value) async {
                              await RestaurantApi.updateCoupon(
                                item['_id'].toString(),
                                {'isActive': value},
                              );
                              reload();
                            },
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () => _delete(item),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    ),
  );

  Future<void> _create() async {
    final code = TextEditingController();
    final description = TextEditingController();
    final value = TextEditingController();
    final minimum = TextEditingController(text: '199');
    String type = 'flat';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create coupon'),
          content: SizedBox(
            width: 430,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: code,
                    maxLength: 24,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Coupon code'),
                  ),
                  TextField(
                    controller: description,
                    maxLength: 180,
                    decoration: const InputDecoration(
                      labelText: 'Offer description',
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    items: const [
                      DropdownMenuItem(
                        value: 'flat',
                        child: Text('Flat amount'),
                      ),
                      DropdownMenuItem(
                        value: 'percentage',
                        child: Text('Percentage'),
                      ),
                    ],
                    onChanged: (v) => setDialogState(() => type = v!),
                    decoration: const InputDecoration(
                      labelText: 'Discount type',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: value,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Discount value',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: minimum,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Minimum order',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    if (accepted != true || !mounted) return;
    try {
      final now = DateTime.now();
      await RestaurantApi.createCoupon({
        'code': code.text.trim().toUpperCase(),
        'description': description.text.trim(),
        'discountType': type,
        'discountValue': double.parse(value.text),
        'minOrder': double.tryParse(minimum.text) ?? 0,
        'startsAt': now.toUtc().toIso8601String(),
        'expiresAt': now
            .add(const Duration(days: 30))
            .toUtc()
            .toIso8601String(),
      });
      reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(RestaurantApi.messageFor(error))),
        );
      }
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete coupon?'),
        content: Text('${item['code']} will stop appearing for customers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await RestaurantApi.deleteCoupon(item['_id'].toString());
      reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(RestaurantApi.messageFor(error))),
        );
      }
    }
  }
}
