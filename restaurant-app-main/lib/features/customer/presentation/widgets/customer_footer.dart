import 'package:flutter/material.dart';

class CustomerFooter extends StatelessWidget {
  const CustomerFooter({
    super.key,
    required this.onMenuTap,
    required this.onOffersTap,
    required this.onOrdersTap,
    required this.onHelpTap,
  });

  final VoidCallback onMenuTap;
  final VoidCallback onOffersTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onHelpTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF061339),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 26),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565D8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Restaurant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Fresh food, delivered with care.',
                        style: TextStyle(
                          color: Color(0xFF9EACCA),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FooterLink(label: 'Menu', onTap: onMenuTap),
                _FooterLink(label: 'Offers', onTap: onOffersTap),
                _FooterLink(label: 'My orders', onTap: onOrdersTap),
                _FooterLink(label: 'Help', onTap: onHelpTap),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFF233258), height: 1),
            const SizedBox(height: 18),
            const Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: Color(0xFF9EACCA),
                  size: 17,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Secure ordering  •  Fast support',
                    style: TextStyle(
                      color: Color(0xFF9EACCA),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '© ${DateTime.now().year} Restaurant. All rights reserved.',
              style: const TextStyle(
                color: Color(0xFF7483A3),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF12234E),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
