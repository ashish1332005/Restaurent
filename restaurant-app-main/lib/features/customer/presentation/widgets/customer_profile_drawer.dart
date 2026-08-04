import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/app_theme.dart';

class CustomerProfileDrawer extends StatelessWidget {
  const CustomerProfileDrawer({
    super.key,
    required this.userName,
    required this.phoneNumber,
    required this.onNavigate,
  });

  final String userName;
  final String phoneNumber;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Drawer(
      width: width > 520 ? 390 : width * .86,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 24, 18, 22),
              color: const Color(0xFFF0F8FF),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFF49A9E8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $userName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          phoneNumber,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475467),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => onNavigate('/customer/profile'),
                    child: const Text(
                      'Edit',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _item(
                    Icons.restaurant_menu_rounded,
                    'Menu',
                    '/customer/menu',
                  ),
                  _item(
                    Icons.local_offer_outlined,
                    'Deals & Offers',
                    '/customer/offers',
                  ),
                  const _DrawerDivider(),
                  _item(
                    Icons.delivery_dining_outlined,
                    'Track Order',
                    '/customer/orders',
                  ),
                  _item(
                    Icons.history_rounded,
                    'Order History',
                    '/customer/orders',
                  ),
                  const _DrawerDivider(),
                  _item(
                    Icons.description_outlined,
                    'Terms & Conditions',
                    '/terms-of-service',
                  ),
                  _item(
                    Icons.support_agent_rounded,
                    'Contact Us',
                    '/customer/profile',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await LocalStorage.clearToken();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Logout',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'TasteHub  •  v1.0.0',
                style: TextStyle(color: Color(0xFF98A2B3), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String title, String path, {String? badge}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 3),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7F9),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: AppTheme.textPrimaryLight, size: 23),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF344054),
              ),
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 9),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF7DD3FC)],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF98A2B3),
      ),
      onTap: () => onNavigate(path),
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 22, vertical: 7),
    child: Divider(height: 1),
  );
}
