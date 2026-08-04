import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/admin_ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: adminPagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            eyebrow: 'SYSTEM SETTINGS',
            title:
                'Keep business preferences organized and easier to maintain.',
            subtitle:
                'Group key restaurant, tax, printer, and integration controls into a clearer admin setup.',
            trailing: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('View Changes'),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const AdminInsightStrip(
            children: [
              AdminMiniInfoCard(
                label: 'Connected printers',
                value: '2',
                icon: Icons.print_rounded,
                color: Color(0xFF4B6BFB),
              ),
              AdminMiniInfoCard(
                label: 'API keys live',
                value: '3',
                icon: Icons.vpn_key_rounded,
                color: Color(0xFF1FA971),
              ),
              AdminMiniInfoCard(
                label: 'Tax profiles',
                value: '2',
                icon: Icons.receipt_long_rounded,
                color: AppTheme.primaryColor,
              ),
              AdminMiniInfoCard(
                label: 'Pending review',
                value: '1',
                icon: Icons.warning_rounded,
                color: Color(0xFFFFA726),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 1160;

                final profileRail = Column(
                  children: [
                    AdminPanel(
                      color: const Color(0xFF101522),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Control center',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Your core business settings are healthy, but tax review and printer fallback should be checked before the next billing cycle.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'This space keeps the most sensitive configuration areas visible so ops teams can update them confidently.',
                            style: TextStyle(
                              color: Color(0xFFC8D0DC),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const AdminDetailRow(
                            label: 'Last config save',
                            value: 'Today • 2:14 PM',
                            valueColor: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          const AdminDetailRow(
                            label: 'Audit mode',
                            value: 'Enabled',
                            valueColor: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          const AdminDetailRow(
                            label: 'Next compliance review',
                            value: 'July 24, 2026',
                            valueColor: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    AdminPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AdminSectionHeading(
                            title: 'Review queue',
                            subtitle: 'A few settings worth revisiting soon.',
                          ),
                          const SizedBox(height: 18),
                          for (var i = 0; i < _settingAlerts.length; i++) ...[
                            AdminActionTile(
                              icon: _settingAlerts[i].icon,
                              color: _settingAlerts[i].color,
                              title: _settingAlerts[i].title,
                              subtitle: _settingAlerts[i].subtitle,
                            ),
                            if (i < _settingAlerts.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ],
                );

                final settingsContent = Column(
                  children: const [
                    _GeneralSettingsPanel(),
                    SizedBox(height: 18),
                    _OperationsSettingsPanel(),
                  ],
                );

                if (stacked) {
                  return ListView(
                    children: [
                      profileRail,
                      const SizedBox(height: 18),
                      settingsContent,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 340,
                      child: ListView(children: [profileRail]),
                    ),
                    const SizedBox(width: 18),
                    Expanded(child: ListView(children: [settingsContent])),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneralSettingsPanel extends StatelessWidget {
  const _GeneralSettingsPanel();

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeading(
            title: 'General settings',
            subtitle:
                'Restaurant identity, communication, and billing defaults.',
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;

              final fields = [
                _buildInputField('Restaurant Name', 'TasteHub Downtown'),
                _buildInputField('Contact Email', 'ops@tastehub.com'),
                _buildInputField('Contact Phone', '+91 98XXXXXX21'),
              ];

              if (compact) {
                return Column(
                  children: [
                    for (var i = 0; i < fields.length; i++) ...[
                      fields[i],
                      if (i < fields.length - 1) const SizedBox(height: 16),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: fields[0]),
                  const SizedBox(width: 16),
                  Expanded(child: fields[1]),
                  const SizedBox(width: 16),
                  Expanded(child: fields[2]),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const AdminActionTile(
            icon: Icons.store_mall_directory_rounded,
            color: Color(0xFF4B6BFB),
            title: 'Branch identity is synced',
            subtitle:
                'The current branch name, invoices, and customer-facing headers match the live app.',
          ),
          const SizedBox(height: 24),
          const AdminSectionHeading(
            title: 'Tax configuration',
            subtitle: 'Default tax percentages used across bills.',
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;

              final taxFields = [
                _buildInputField('Default GST (%)', '5'),
                _buildInputField('Service Charge (%)', '2'),
              ];

              if (compact) {
                return Column(
                  children: [
                    taxFields[0],
                    const SizedBox(height: 16),
                    taxFields[1],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: taxFields[0]),
                  const SizedBox(width: 16),
                  Expanded(child: taxFields[1]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OperationsSettingsPanel extends StatelessWidget {
  const _OperationsSettingsPanel();

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeading(
            title: 'Operations and integrations',
            subtitle:
                'Printer routing, platform credentials, and fallback controls.',
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;

              final printerFields = [
                _buildInputField('Kitchen Printer IP', '192.168.0.101'),
                _buildInputField('Cashier Printer IP', '192.168.0.118'),
              ];

              return Column(
                children: [
                  if (compact) ...[
                    printerFields[0],
                    const SizedBox(height: 16),
                    printerFields[1],
                  ] else ...[
                    Row(
                      children: [
                        Expanded(child: printerFields[0]),
                        const SizedBox(width: 16),
                        Expanded(child: printerFields[1]),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  const AdminActionTile(
                    icon: Icons.print_rounded,
                    color: Color(0xFF1FA971),
                    title: 'Printer fallback ready',
                    subtitle:
                        'If the kitchen printer drops, tickets automatically reroute to the expo station.',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const AdminSectionHeading(
            title: 'Integration keys',
            subtitle: 'Secure platform credentials for payment and maps.',
          ),
          const SizedBox(height: 18),
          _buildInputField(
            'Stripe API Key',
            'sk_live_xxxxxxxxxx',
            obscure: true,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            'Google Maps API Key',
            'AIza_xxxxxxxxxx',
            obscure: true,
          ),
          const SizedBox(height: 20),
          const AdminActionTile(
            icon: Icons.shield_rounded,
            color: AppTheme.primaryColor,
            title: 'Secrets are masked by default',
            subtitle:
                'Only privileged admins can reveal or rotate production keys from this panel.',
          ),
        ],
      ),
    );
  }
}

Widget _buildInputField(String label, String value, {bool obscure = false}) {
  return TextFormField(
    obscureText: obscure,
    initialValue: value,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: const Color(0xFFF7F8FC),
    ),
  );
}

class _SettingAlert {
  const _SettingAlert({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
}

const _settingAlerts = [
  _SettingAlert(
    icon: Icons.warning_rounded,
    color: Color(0xFFFFA726),
    title: 'Printer backup tested 12 days ago',
    subtitle:
        'Run another failover check before the next busy weekend service.',
  ),
  _SettingAlert(
    icon: Icons.receipt_long_rounded,
    color: AppTheme.primaryColor,
    title: 'Tax profile review pending',
    subtitle:
        'GST verification is scheduled before the next audit on July 24, 2026.',
  ),
  _SettingAlert(
    icon: Icons.cloud_done_rounded,
    color: Color(0xFF1FA971),
    title: 'Payment gateway healthy',
    subtitle: 'No recent token failures or callback mismatches were detected.',
  ),
];
