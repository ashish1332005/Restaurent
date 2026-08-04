import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/admin_ui.dart';

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  void _showNewBookingDialog(BuildContext context) {
    final guestNameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String tableNo = 'T-05';
    int guests = 4;
    String timeSlot = '7:30 PM';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Table Reservation'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: guestNameCtrl,
                decoration: const InputDecoration(labelText: 'Guest Full Name', hintText: 'e.g. Rahul Sharma'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile Number', hintText: '10-digit mobile'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(labelText: 'Special Request', hintText: 'Birthday / High Chair'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4B6BFB)),
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🎉 Reservation confirmed for ${guestNameCtrl.text.isNotEmpty ? guestNameCtrl.text : "Guest"} ($guests Guests @ $timeSlot on Table $tableNo)!'),
                  backgroundColor: const Color(0xFF1FA971),
                ),
              );
            },
            child: const Text('Confirm Booking', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final confirmedCount = _reservations
        .where((reservation) => reservation.status == 'Confirmed')
        .length;

    return Padding(
      padding: adminPagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            eyebrow: 'BOOKING DESK',
            title: 'Stay ahead of guest arrivals.',
            subtitle:
                'See confirmations, guest count, and table readiness in a calmer reservation workflow.',
            trailing: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone_in_talk_rounded),
                  label: const Text('Call Guests'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showNewBookingDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B6BFB),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.event_available_rounded),
                  label: const Text('New Booking'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const AdminInsightStrip(
            children: [
              AdminMiniInfoCard(
                label: 'Bookings today',
                value: '26',
                icon: Icons.calendar_today_rounded,
                color: Color(0xFF4B6BFB),
              ),
              AdminMiniInfoCard(
                label: 'Large parties',
                value: '4',
                icon: Icons.groups_rounded,
                color: Color(0xFFFFA726),
              ),
              AdminMiniInfoCard(
                label: 'Confirmed',
                value: '18',
                icon: Icons.verified_rounded,
                color: Color(0xFF1FA971),
              ),
              AdminMiniInfoCard(
                label: 'Waitlist',
                value: '3',
                icon: Icons.hourglass_bottom_rounded,
                color: AppTheme.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 1180;

                final sideRail = Column(
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
                              'Arrival pulse',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            '$confirmedCount tables are already locked in for the service window.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'The next 90 minutes will be heavy with party sizes above four, so seating discipline matters most now.',
                            style: TextStyle(
                              color: Color(0xFFC8D0DC),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const AdminDetailRow(
                            label: 'Next peak arrival',
                            value: '7:30 PM',
                            valueColor: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          const AdminDetailRow(
                            label: 'VIP guests tonight',
                            value: '2',
                            valueColor: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          const AdminDetailRow(
                            label: 'No-show risk',
                            value: 'Low',
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
                            title: 'Host priorities',
                            subtitle:
                                'What the front desk should focus on before arrivals tighten up.',
                          ),
                          const SizedBox(height: 18),
                          for (var i = 0; i < _hostActions.length; i++) ...[
                            AdminActionTile(
                              icon: _hostActions[i].icon,
                              color: _hostActions[i].color,
                              title: _hostActions[i].title,
                              subtitle: _hostActions[i].subtitle,
                            ),
                            if (i < _hostActions.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    AdminPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AdminSectionHeading(
                            title: 'Upcoming arrivals',
                            subtitle:
                                'The next reservations that need the most attention.',
                          ),
                          const SizedBox(height: 18),
                          for (var i = 0; i < _arrivals.length; i++) ...[
                            AdminActionTile(
                              icon: Icons.table_restaurant_rounded,
                              color: _arrivals[i].color,
                              title: _arrivals[i].title,
                              subtitle: _arrivals[i].subtitle,
                              trailing: Text(
                                _arrivals[i].time,
                                style: TextStyle(
                                  color: _arrivals[i].color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (i < _arrivals.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ],
                );

                final tablePanel = AdminPanel(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdminSectionHeading(
                        title: 'Upcoming reservations',
                        subtitle:
                            '${_reservations.length} bookings with table, guest count, and arrival status visible in one place.',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FC),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Host desk synced',
                            style: TextStyle(
                              color: AppTheme.textSecondaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: [
                            AdminResponsiveDataTable(
                              minWidth: 980,
                              columnSpacing: 22,
                              headingRowColor: WidgetStateProperty.all(
                                const Color(0xFFF7F8FC),
                              ),
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'Customer',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Date & Time',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Guests',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Table',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Source',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Actions',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              rows: _reservations
                                  .map(_buildReservationRow)
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );

                if (stacked) {
                  return ListView(
                    children: [
                      sideRail,
                      const SizedBox(height: 18),
                      SizedBox(height: 620, child: tablePanel),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 360, child: ListView(children: [sideRail])),
                    const SizedBox(width: 18),
                    Expanded(child: tablePanel),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildReservationRow(_ReservationItem item) {
    return DataRow(
      cells: [
        DataCell(
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        DataCell(Text(item.time)),
        DataCell(Text(item.guests)),
        DataCell(
          Text(item.table, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        DataCell(Text(item.source)),
        DataCell(AdminStatusChip(label: item.status, color: item.statusColor)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check_rounded, color: Color(0xFF1FA971)),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.call_rounded, color: Color(0xFF4B6BFB)),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.cancel_rounded,
                  color: AppTheme.primaryColor,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReservationItem {
  const _ReservationItem({
    required this.name,
    required this.time,
    required this.guests,
    required this.table,
    required this.source,
    required this.status,
    required this.statusColor,
  });

  final String name;
  final String time;
  final String guests;
  final String table;
  final String source;
  final String status;
  final Color statusColor;
}

class _HostAction {
  const _HostAction({
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

class _ArrivalCard {
  const _ArrivalCard({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String time;
  final Color color;
}

const _reservations = [
  _ReservationItem(
    name: 'Sarah Connor',
    time: 'Saturday, July 18 • 7:00 PM',
    guests: '4',
    table: 'T3',
    source: 'Phone',
    status: 'Confirmed',
    statusColor: Color(0xFF1FA971),
  ),
  _ReservationItem(
    name: 'Bruce Wayne',
    time: 'Saturday, July 18 • 8:30 PM',
    guests: '2',
    table: 'T1',
    source: 'App',
    status: 'Pending',
    statusColor: Color(0xFFFFA726),
  ),
  _ReservationItem(
    name: 'Clark Kent',
    time: 'Sunday, July 19 • 1:00 PM',
    guests: '6',
    table: 'T5',
    source: 'Walk-in call',
    status: 'Confirmed',
    statusColor: Color(0xFF1FA971),
  ),
  _ReservationItem(
    name: 'Diana Prince',
    time: 'Saturday, July 18 • 7:45 PM',
    guests: '5',
    table: 'T8',
    source: 'Instagram DM',
    status: 'VIP',
    statusColor: Color(0xFF4B6BFB),
  ),
];

const _hostActions = [
  _HostAction(
    icon: Icons.notifications_active_rounded,
    color: AppTheme.primaryColor,
    title: 'Reconfirm pending bookings',
    subtitle:
        'Bruce Wayne still needs a final confirmation for the 8:30 PM slot.',
  ),
  _HostAction(
    icon: Icons.chair_alt_rounded,
    color: Color(0xFF4B6BFB),
    title: 'Stage larger tables early',
    subtitle: 'Two parties of five or more arrive before 8 PM tonight.',
  ),
  _HostAction(
    icon: Icons.celebration_rounded,
    color: Color(0xFF1FA971),
    title: 'Flag VIP experience',
    subtitle: 'Diana Prince requested a quieter corner table and fast seating.',
  ),
];

const _arrivals = [
  _ArrivalCard(
    title: 'Sarah Connor • T3',
    subtitle: 'Birthday dinner • 4 guests',
    time: '7:00 PM',
    color: Color(0xFF1FA971),
  ),
  _ArrivalCard(
    title: 'Diana Prince • T8',
    subtitle: 'VIP seating • 5 guests',
    time: '7:45 PM',
    color: Color(0xFF4B6BFB),
  ),
  _ArrivalCard(
    title: 'Bruce Wayne • T1',
    subtitle: 'Pending confirmation • 2 guests',
    time: '8:30 PM',
    color: Color(0xFFFFA726),
  ),
];
