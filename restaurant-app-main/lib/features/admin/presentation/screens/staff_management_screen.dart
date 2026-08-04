import 'package:flutter/material.dart';
import '../../../../core/storage/local_storage.dart';
import '../widgets/add_staff_dialog.dart';
import '../widgets/admin_ui.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  List<Map<String, dynamic>> _staffList = [];
  String _searchQuery = '';
  String _selectedRoleFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  void _loadStaffData() {
    setState(() {
      _staffList = LocalStorage.getStaffList();
    });
  }

  void _openAddStaffDialog([Map<String, dynamic>? initialData]) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AddStaffDialog(
        initialData: initialData,
        onStaffAdded: (staffData) async {
          if (initialData != null) {
            await LocalStorage.updateStaffMember(staffData['id'], staffData);
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(content: Text('Staff "${staffData['name']}" updated successfully.')),
              );
            }
          } else {
            await LocalStorage.addStaffMember(staffData);
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('🎉 Staff member "${staffData['name']}" created with role ${staffData['role']}.'),
                  backgroundColor: const Color(0xFF1FA971),
                ),
              );
            }
          }
          _loadStaffData();
        },
      ),
    );
  }

  Future<void> _toggleStaffStatus(Map<String, dynamic> staff) async {
    final currentStatus = staff['status'] ?? 'Active';
    final newStatus = currentStatus == 'Active' ? 'Disabled' : 'Active';

    await LocalStorage.updateStaffMember(staff['id'], {'status': newStatus});
    _loadStaffData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'Active'
                ? 'Access granted for ${staff['name']}'
                : 'Access disabled for ${staff['name']}',
          ),
          backgroundColor: newStatus == 'Active' ? const Color(0xFF1FA971) : const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _deleteStaff(Map<String, dynamic> staff) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Revoke Access for ${staff['name']}?'),
        content: const Text(
          'This will delete their login credentials. They will no longer be able to log in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete Access', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await LocalStorage.deleteStaffMember(staff['id']);
      _loadStaffData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Access revoked for ${staff['name']}.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeStaffCount = _staffList.where((s) => s['status'] == 'Active').length;
    final waitersCount = _staffList.where((s) => s['role'] == 'Waiter').length;
    final cashiersCount = _staffList.where((s) => s['role'] == 'Cashier').length;
    final kitchenCount = _staffList.where((s) => s['role'] == 'Kitchen').length;

    final filteredList = _staffList.where((staff) {
      final matchesSearch = staff['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          staff['phone'].toString().contains(_searchQuery);
      final matchesRole = _selectedRoleFilter == 'All' || staff['role'] == _selectedRoleFilter;
      return matchesSearch && matchesRole;
    }).toList();

    return Padding(
      padding: adminPagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            eyebrow: 'TEAM & ACCESS CONTROL',
            title: 'Manage Staff Login & Role Delegation',
            subtitle:
                'Grant role-based login credentials to Waiters, Cashiers, Kitchen Staff, and Managers.',
            trailing: ElevatedButton.icon(
              onPressed: () => _openAddStaffDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B6BFB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add Employee'),
            ),
          ),
          const SizedBox(height: 22),

          // Stat Cards
          AdminInsightStrip(
            children: [
              AdminMiniInfoCard(
                label: 'Active Staff Accounts',
                value: '$activeStaffCount / ${_staffList.length}',
                icon: Icons.groups_rounded,
                color: const Color(0xFF4B6BFB),
              ),
              AdminMiniInfoCard(
                label: 'Waiters Active',
                value: '$waitersCount',
                icon: Icons.table_bar_rounded,
                color: const Color(0xFF1FA971),
              ),
              AdminMiniInfoCard(
                label: 'Cashiers / KDS Staff',
                value: '${cashiersCount + kitchenCount}',
                icon: Icons.point_of_sale_rounded,
                color: const Color(0xFFFFA726),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Roster Table Panel
          Expanded(
            child: AdminPanel(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AdminSectionHeading(
                        title: 'Employee Roster & Login Credentials',
                        subtitle:
                            'Monitor active credentials, assigned roles, and toggle login access.',
                      ),
                      Row(
                        children: [
                          // Search Box
                          SizedBox(
                            width: 220,
                            height: 40,
                            child: TextField(
                              onChanged: (val) => setState(() => _searchQuery = val),
                              decoration: InputDecoration(
                                hintText: 'Search name / phone...',
                                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Role Filter Dropdown
                          DropdownButton<String>(
                            value: _selectedRoleFilter,
                            underline: const SizedBox(),
                            items: ['All', 'Manager', 'Waiter', 'Cashier', 'Kitchen'].map((role) {
                              return DropdownMenuItem(
                                value: role,
                                child: Text('Role: $role', style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedRoleFilter = val);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: filteredList.isEmpty
                        ? const Center(
                            child: Text(
                              'No staff members found matching search.',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          )
                        : ListView(
                            children: [
                              AdminResponsiveDataTable(
                                minWidth: 840,
                                columnSpacing: 20,
                                headingRowColor: WidgetStateProperty.all(
                                  const Color(0xFFF7F8FC),
                                ),
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'Employee Name',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Login Phone',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Role',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Shift',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Login Access',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Actions',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                                rows: filteredList.map((staff) => _buildStaffRow(staff)).toList(),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildStaffRow(Map<String, dynamic> staff) {
    final name = staff['name'] ?? 'Staff Member';
    final phone = staff['phone'] ?? '-';
    final role = staff['role'] ?? 'Waiter';
    final shift = staff['shift'] ?? 'Full Day';
    final status = staff['status'] ?? 'Active';
    final isActive = status == 'Active';
    final statusColor = isActive ? const Color(0xFF1FA971) : const Color(0xFFEF4444);

    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.12),
                child: Text(
                  name[0].toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    'PIN: ${staff['password'] ?? '******'}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
        ),
        DataCell(
          Text(phone, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4B6BFB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              role,
              style: const TextStyle(
                color: Color(0xFF4B6BFB),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(Text(shift)),
        DataCell(
          InkWell(
            onTap: () => _toggleStaffStatus(staff),
            child: AdminStatusChip(
              label: isActive ? 'Active' : 'Disabled',
              color: statusColor,
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Edit Credentials',
                icon: const Icon(Icons.edit_rounded, color: Color(0xFF4B6BFB), size: 20),
                onPressed: () => _openAddStaffDialog(staff),
              ),
              IconButton(
                tooltip: isActive ? 'Disable Access' : 'Enable Access',
                icon: Icon(
                  isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                  color: isActive ? const Color(0xFFFFA726) : const Color(0xFF1FA971),
                  size: 20,
                ),
                onPressed: () => _toggleStaffStatus(staff),
              ),
              IconButton(
                tooltip: 'Delete Account',
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                onPressed: () => _deleteStaff(staff),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
