import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class LegalPolicyScreen extends StatelessWidget {
  const LegalPolicyScreen.termsOfService({super.key})
    : _document = _termsOfService;

  const LegalPolicyScreen.privacyPolicy({super.key})
    : _document = _privacyPolicy;

  const LegalPolicyScreen.contentPolicy({super.key})
    : _document = _contentPolicy;

  final _LegalDocument _document;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryLight,
        elevation: 0,
        title: Text(_document.title),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF0F6AA8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _document.eyebrow,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _document.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _document.summary,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Text(
                      'Last updated: July 19, 2026',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ..._document.sections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _PolicySectionCard(section: section),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySectionCard extends StatelessWidget {
  const _PolicySectionCard({required this.section});

  final _LegalSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7EDF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              color: AppTheme.textPrimaryLight,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            section.body,
            style: const TextStyle(
              color: AppTheme.textSecondaryLight,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalDocument {
  const _LegalDocument({
    required this.title,
    required this.eyebrow,
    required this.summary,
    required this.sections,
  });

  final String title;
  final String eyebrow;
  final String summary;
  final List<_LegalSection> sections;
}

class _LegalSection {
  const _LegalSection({required this.title, required this.body});

  final String title;
  final String body;
}

const _termsOfService = _LegalDocument(
  title: 'Terms of Service',
  eyebrow: 'USER AGREEMENT',
  summary:
      'These terms explain how customers can use TasteHub for browsing menus, placing orders, and interacting with restaurant services.',
  sections: [
    _LegalSection(
      title: 'Using TasteHub',
      body:
          'You may use TasteHub to explore menus, place delivery or pickup orders, and manage your customer account. You agree to provide accurate details for orders, payments, and contact information so the restaurant can fulfill requests correctly.',
    ),
    _LegalSection(
      title: 'Orders and Payments',
      body:
          'All placed orders are subject to restaurant availability, pricing, and kitchen acceptance. Payment methods such as UPI, card, wallet, or cash on delivery must be used lawfully. The restaurant may cancel or adjust an order if an item becomes unavailable or if delivery details are incomplete.',
    ),
    _LegalSection(
      title: 'Account Responsibility',
      body:
          'You are responsible for activity under your account, including saved addresses, order history, and preferences. Please keep your login credentials secure and notify support if you believe your account is being used without permission.',
    ),
    _LegalSection(
      title: 'Service Availability',
      body:
          'TasteHub works to keep menus, offers, and ordering tools available, but uninterrupted access cannot be guaranteed at all times. Features, delivery windows, offers, and restaurant content may change as operations evolve.',
    ),
  ],
);

const _privacyPolicy = _LegalDocument(
  title: 'Privacy Policy',
  eyebrow: 'DATA AND PRIVACY',
  summary:
      'This policy describes what customer information TasteHub may store and how it is used to support orders, payments, and service updates.',
  sections: [
    _LegalSection(
      title: 'Information We Collect',
      body:
          'TasteHub may collect your name, phone number, email address, saved addresses, order details, payment preferences, and device-level app usage signals needed to improve the customer journey.',
    ),
    _LegalSection(
      title: 'How We Use Information',
      body:
          'Customer information is used to process orders, send order updates, improve delivery accuracy, personalize menus, and provide support when you report an issue or request help.',
    ),
    _LegalSection(
      title: 'Sharing of Information',
      body:
          'We share only the information required to operate the service, such as delivery details for order fulfillment or payment information for approved payment processing. We do not sell personal information for unrelated advertising use.',
    ),
    _LegalSection(
      title: 'Your Choices',
      body:
          'You may request profile updates, review saved addresses, and control what information you provide while ordering. Some operational information may still need to be retained for billing, compliance, fraud prevention, or order dispute resolution.',
    ),
  ],
);

const _contentPolicy = _LegalDocument(
  title: 'Content Policy',
  eyebrow: 'CONTENT GUIDELINES',
  summary:
      'This policy covers the standards for menu content, customer submissions, profile details, and any material shown inside the TasteHub app experience.',
  sections: [
    _LegalSection(
      title: 'Menu and App Content',
      body:
          'Restaurant descriptions, images, pricing, offers, and category details are intended to be accurate, respectful, and useful for customers. Content may be updated when menus, availability, or promotions change.',
    ),
    _LegalSection(
      title: 'Customer-Provided Content',
      body:
          'Any names, notes, profile details, support messages, or other information you submit should remain lawful, respectful, and free from abusive, misleading, or harmful material.',
    ),
    _LegalSection(
      title: 'Restricted Material',
      body:
          'TasteHub does not allow content that promotes violence, hate, harassment, illegal activity, payment abuse, impersonation, or attempts to exploit restaurant staff, delivery partners, or other users.',
    ),
    _LegalSection(
      title: 'Enforcement',
      body:
          'The restaurant or platform operator may remove content, limit access, or suspend accounts when submitted material violates these guidelines or creates operational, legal, or customer safety risk.',
    ),
  ],
);
