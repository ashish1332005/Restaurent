import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/restaurant_api.dart';

class AdminStaffPanel extends StatefulWidget {
  const AdminStaffPanel({super.key, required this.branchId});
  final String? branchId;
  @override
  State<AdminStaffPanel> createState() => _AdminStaffPanelState();
}

class _AdminStaffPanelState extends State<AdminStaffPanel> {
  List<Map<String, dynamic>> staff = [], roles = [];
  bool loading = true;
  String query = '', roleFilter = 'All';
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AdminStaffPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branchId != widget.branchId) _load();
  }

  Future<void> _load() async {
    if (widget.branchId == null) {
      if (mounted) setState(() => loading = false);
      return;
    }
    setState(() => loading = true);
    try {
      final data = await Future.wait([
        RestaurantApi.getStaffUsers(branchId: widget.branchId),
        RestaurantApi.getAssignableRoles(),
      ]);
      if (mounted)
        setState(() {
          staff = data[0];
          roles = data[1];
          loading = false;
          if (roleFilter != 'All' && !roles.any((r) => r['name'] == roleFilter))
            roleFilter = 'All';
        });
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        _message(RestaurantApi.messageFor(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = staff.where((u) => u['status'] == 'Active').length;
    final visible = staff.where((u) {
      final role = u['role'] is Map ? '${u['role']['name']}' : '';
      final text = '${u['name']} ${u['phone']} ${u['email'] ?? ''}'
          .toLowerCase();
      return text.contains(query.toLowerCase()) &&
          (roleFilter == 'All' || role == roleFilter);
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Staff management',
              style: GoogleFonts.playfairDisplay(
                fontSize: 27,
                fontWeight: FontWeight.w700,
              ),
            ),
            _badge('Total', staff.length, const Color(0xFF3B74B9)),
            _badge('Active', active, const Color(0xFF2F8A61)),
            FilledButton.icon(
              onPressed: roles.isEmpty ? null : () => _staffDialog(),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add staff'),
            ),
            IconButton(
              onPressed: _load,
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 330,
              child: TextField(
                onChanged: (v) => setState(() => query = v),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search name, phone or email',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                initialValue: roleFilter,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: ['All', ...roles.map((r) => '${r['name']}')]
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => roleFilter = v ?? 'All'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(45),
              child: CircularProgressIndicator(),
            ),
          )
        else
          _staffGrid(visible),
      ],
    );
  }

  Widget _staffGrid(List<Map<String, dynamic>> records) => LayoutBuilder(
    builder: (_, box) {
      if (records.isEmpty)
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(42),
          decoration: _box(),
          child: const Text(
            'No staff members found.',
            textAlign: TextAlign.center,
          ),
        );
      final columns = box.maxWidth >= 1100
          ? 3
          : box.maxWidth >= 700
          ? 2
          : 1;
      final width = (box.maxWidth - (columns - 1) * 14) / columns;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: records
            .map((u) => SizedBox(width: width, child: _staffCard(u)))
            .toList(),
      );
    },
  );
  Widget _staffCard(Map<String, dynamic> user) {
    final role = user['role'] is Map ? '${user['role']['name']}' : 'Staff';
    final status = '${user['status'] ?? 'Inactive'}';
    final active = status == 'Active';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFFFF1D6),
                child: Text(
                  _initials('${user['name']}'),
                  style: const TextStyle(
                    color: Color(0xFFD66A2C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user['name']}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      role,
                      style: const TextStyle(color: Color(0xFF667085)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color:
                      (active
                              ? const Color(0xFF2F8A61)
                              : const Color(0xFFC84435))
                          .withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: active
                        ? const Color(0xFF2F8A61)
                        : const Color(0xFFC84435),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 26),
          _detail(Icons.phone_outlined, '${user['phone'] ?? '—'}'),
          _detail(Icons.email_outlined, '${user['email'] ?? 'No email'}'),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _staffDialog(user: user),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit staff'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF667085)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
  Future<void> _staffDialog({Map<String, dynamic>? user}) async {
    final editing = user != null;
    final name = TextEditingController(text: user?['name']?.toString() ?? ''),
        phone = TextEditingController(text: user?['phone']?.toString() ?? ''),
        email = TextEditingController(text: user?['email']?.toString() ?? ''),
        password = TextEditingController();
    String? roleId = editing && user['role'] is Map
        ? '${user['role']['_id']}'
        : null;
    String status = '${user?['status'] ?? 'Active'}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialog) => AlertDialog(
          title: Text(editing ? 'Edit staff' : 'Add staff member'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Full name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phone,
                    enabled: !editing,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email (optional)',
                    ),
                  ),
                  if (!editing) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Temporary password',
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: roleId,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: roles
                        .map(
                          (r) => DropdownMenuItem(
                            value: '${r['_id']}',
                            child: Text('${r['name']}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialog(() => roleId = v),
                  ),
                  if (editing) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Account status',
                      ),
                      items: ['Active', 'Inactive', 'Suspended']
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (v) => setDialog(() => status = v ?? status),
                    ),
                  ],
                ],
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
              child: Text(editing ? 'Save changes' : 'Create staff'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (name.text.trim().length < 2 ||
        roleId == null ||
        (!editing &&
            (phone.text.trim().length < 10 || password.text.length < 6))) {
      _message('Enter valid staff details, role and 6+ character password.');
      return;
    }
    try {
      if (editing) {
        await RestaurantApi.updateStaffUser('${user['_id']}', {
          'name': name.text.trim(),
          if (email.text.trim().isNotEmpty) 'email': email.text.trim(),
          'role': roleId,
          'status': status,
        });
      } else {
        await RestaurantApi.createStaffUser({
          'branchId': widget.branchId,
          'name': name.text.trim(),
          'phone': phone.text.trim(),
          if (email.text.trim().isNotEmpty) 'email': email.text.trim(),
          'password': password.text,
          'role': roleId,
          'status': 'Active',
        });
      }
      await _load();
      if (mounted)
        _message(editing ? 'Staff updated.' : 'Staff account created.');
    } catch (e) {
      if (mounted) _message(RestaurantApi.messageFor(e));
    }
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  Widget _badge(String label, int count, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      '$label $count',
      style: TextStyle(color: color, fontWeight: FontWeight.w700),
    ),
  );
  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFE6DED2)),
  );
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
}
