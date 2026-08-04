import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../application/customer_cart_provider.dart';
import '../../application/customer_profile_provider.dart';
import '../../domain/models/customer_profile.dart';
import '../widgets/customer_ui.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  bool _didSeedControllers = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(customerProfileProvider);
    final orderHistory = ref.watch(customerOrderHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: profileState.when(
        data: (profile) {
          _seedControllers(profile);

          return Column(
            children: [
              _ProfileTopBar(
                isSaving: _isSaving,
                onBackTap: () => context.pop(),
                onSaveTap: _isSaving ? null : _handleSave,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                  children: [
                    _ProfileEditorCard(
                      profile: profile,
                      nameController: _nameController,
                      emailController: _emailController,
                      phoneController: _phoneController,
                      addressController: _addressController,
                    ),
                    const SizedBox(height: 18),
                    _OrdersSection(orderHistory: orderHistory),
                    const SizedBox(height: 18),
                    _SavedCardsSection(cards: profile.savedCards),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Profile load nahi ho paya. Please try again.',
              style: const TextStyle(
                color: AppTheme.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  void _seedControllers(CustomerProfile profile) {
    if (_didSeedControllers) return;
    _nameController.text = profile.name;
    _emailController.text = profile.email;
    _phoneController.text = profile.phone;
    _addressController.text = profile.address;
    _didSeedControllers = true;
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final result = await ref
          .read(customerProfileProvider.notifier)
          .saveProfile(
            name: _nameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            address: _addressController.text,
          );

      if (!mounted) return;

      _didSeedControllers = false;
      _seedControllers(result.profile);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              result.savedToServer
                  ? 'Profile updated successfully.'
                  : 'Profile updated in app. Backend sync will need a signed-in API user.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({
    required this.isSaving,
    required this.onBackTap,
    required this.onSaveTap,
  });

  final bool isSaving;
  final VoidCallback onBackTap;
  final VoidCallback? onSaveTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F6AA8),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 16),
          child: Row(
            children: [
              InkWell(
                onTap: onBackTap,
                borderRadius: BorderRadius.circular(18),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'My Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: onSaveTap,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.white70, width: 2),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'SAVE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileEditorCard extends StatelessWidget {
  const _ProfileEditorCard({
    required this.profile,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.addressController,
  });

  final CustomerProfile profile;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: const BoxDecoration(
              color: Color(0xFFD7EBFB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF0F6AA8),
                  backgroundImage: profile.avatarUrl.trim().isEmpty
                      ? null
                      : NetworkImage(profile.avatarUrl),
                  child: profile.avatarUrl.trim().isEmpty
                      ? Text(
                          profile.firstInitial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _ProfileTextField(
                        controller: nameController,
                        hintText: 'Full Name*',
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _ProfileTextField(
                        controller: addressController,
                        hintText: 'Address*',
                        textInputAction: TextInputAction.next,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _InfoRowField(
            icon: Icons.call_outlined,
            controller: phoneController,
            hintText: 'Phone Number',
            keyboardType: TextInputType.phone,
          ),
          const Divider(height: 1),
          _InfoRowField(
            icon: Icons.mail_outline_rounded,
            controller: emailController,
            hintText: 'Please add your Email',
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.hintText,
    this.textInputAction,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputAction? textInputAction;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: textInputAction,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppTheme.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF5B6470), fontSize: 18),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFB7C0C8)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0F6AA8), width: 2),
        ),
      ),
    );
  }
}

class _InfoRowField extends StatelessWidget {
  const _InfoRowField({
    required this.icon,
    required this.controller,
    required this.hintText,
    this.keyboardType,
  });

  final IconData icon;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF5F6368), size: 34),
          const SizedBox(width: 18),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF6B7280),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersSection extends StatelessWidget {
  const _OrdersSection({required this.orderHistory});

  final List<CustomerOrderHistoryEntry> orderHistory;

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Your Orders',
      subtitle: 'Abhi tak customer ne kya order kiya hai.',
      child: orderHistory.isEmpty
          ? const Text(
              'Abhi tak koi order history saved nahi hai.',
              style: TextStyle(
                color: AppTheme.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < orderHistory.length && i < 5; i++) ...[
                  _OrderRow(order: orderHistory[i]),
                  if (i < orderHistory.length - 1 && i < 4)
                    const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _SavedCardsSection extends StatelessWidget {
  const _SavedCardsSection({required this.cards});

  final List<CustomerSavedCard> cards;

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'My Saved Cards',
      subtitle: 'Customer ke saved payment cards.',
      child: cards.isEmpty
          ? const Text(
              'Abhi tak koi saved card available nahi hai.',
              style: TextStyle(
                color: AppTheme.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  _SavedCardRow(card: cards[i]),
                  if (i < cards.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _SectionContainer extends StatelessWidget {
  const _SectionContainer({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomerSectionCard(
      title: title,
      subtitle: subtitle,
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final CustomerOrderHistoryEntry order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order ${order.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.itemCount} items • ${_formatOrderDate(order.placedAt)}',
                  style: const TextStyle(
                    color: AppTheme.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatPrice(order.total),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedCardRow extends StatelessWidget {
  const _SavedCardRow({required this.card});

  final CustomerSavedCard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFCE7F3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.credit_card_rounded,
              color: Color(0xFFBE185D),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${card.brand} • ${card.label}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${card.maskedNumber} • Exp ${card.expiryLabel}',
                  style: const TextStyle(
                    color: AppTheme.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatOrderDate(DateTime value) {
  const months = <String>[
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
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}
