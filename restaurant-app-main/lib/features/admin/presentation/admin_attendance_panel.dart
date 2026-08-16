import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/restaurant_api.dart';

class AdminAttendancePanel extends StatefulWidget {
  const AdminAttendancePanel({super.key, required this.branchId});
  final String? branchId;
  @override
  State<AdminAttendancePanel> createState() => _AdminAttendancePanelState();
}

class _AdminAttendancePanelState extends State<AdminAttendancePanel> {
  DateTime date = DateTime.now();
  List<Map<String, dynamic>> shifts = [], staff = [];
  bool loading = true;
  final busy = <String>{};
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AdminAttendancePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branchId != widget.branchId) _load();
  }

  String get dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  Future<void> _load() async {
    if (widget.branchId == null) {
      if (mounted) setState(() => loading = false);
      return;
    }
    setState(() => loading = true);
    try {
      final data = await Future.wait([
        RestaurantApi.getAttendance(branchId: widget.branchId!, date: dateKey),
        RestaurantApi.getStaffUsers(branchId: widget.branchId),
      ]);
      if (mounted)
        setState(() {
          shifts = data[0];
          staff = data[1].where((u) => u['status'] == 'Active').toList();
          loading = false;
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
    final present = shifts
            .where(
              (s) => ['Present', 'Late', 'Completed'].contains(s['status']),
            )
            .length,
        late = shifts.where((s) => s['status'] == 'Late').length,
        done = shifts.where((s) => s['status'] == 'Completed').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Attendance & shifts',
              style: GoogleFonts.playfairDisplay(
                fontSize: 27,
                fontWeight: FontWeight.w700,
              ),
            ),
            _badge('Scheduled', shifts.length, const Color(0xFF3B74B9)),
            _badge('Present', present, const Color(0xFF2F8A61)),
            _badge('Late', late, const Color(0xFFC84435)),
            _badge('Completed', done, const Color(0xFF6B55A3)),
            FilledButton.icon(
              onPressed: staff.isEmpty ? null : _schedule,
              icon: const Icon(Icons.add_alarm),
              label: const Text('Schedule shift'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: _box(),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                tooltip: 'Previous day',
                onPressed: () => _changeDay(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                _dateLabel(),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              IconButton(
                tooltip: 'Next day',
                onPressed: () => _changeDay(1),
                icon: const Icon(Icons.chevron_right),
              ),
              IconButton(
                tooltip: 'Choose date',
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_outlined),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
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
          _list(),
      ],
    );
  }

  Widget _list() => Container(
    decoration: _box(),
    child: Column(
      children: [
        if (shifts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(42),
            child: Text('No shifts scheduled for this date.'),
          )
        else
          ...shifts.map((shift) {
            final user = shift['userId'] is Map
                ? shift['userId'] as Map
                : const {};
            final id = '${shift['_id']}', status = '${shift['status']}';
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFFFE7D6),
                child: Text(_initials('${user['name'] ?? 'S'}')),
              ),
              title: Text(
                '${user['name'] ?? 'Staff'}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${_time(shift['scheduledStart'])} – ${_time(shift['scheduledEnd'])} · $status${'${shift['notes'] ?? ''}'.isEmpty ? '' : ' · ${shift['notes']}'}',
              ),
              trailing: busy.contains(id)
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : status == 'Scheduled'
                  ? FilledButton(
                      onPressed: () => _clock(id, true),
                      child: const Text('Clock in'),
                    )
                  : shift['clockOut'] == null
                  ? FilledButton(
                      onPressed: () => _clock(id, false),
                      child: const Text('Clock out'),
                    )
                  : const Icon(Icons.check_circle, color: Color(0xFF2F8A61)),
            );
          }),
      ],
    ),
  );
  Future<void> _schedule() async {
    String? userId;
    final start = TextEditingController(text: '10:00'),
        end = TextEditingController(text: '19:00'),
        notes = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialog) => AlertDialog(
          title: const Text('Schedule staff shift'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: userId,
                  decoration: const InputDecoration(labelText: 'Staff member'),
                  items: staff
                      .map(
                        (u) => DropdownMenuItem(
                          value: '${u['_id']}',
                          child: Text(
                            '${u['name']} · ${u['role'] is Map ? u['role']['name'] : 'Staff'}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialog(() => userId = v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: start,
                        decoration: const InputDecoration(
                          labelText: 'Start HH:mm',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: end,
                        decoration: const InputDecoration(
                          labelText: 'End HH:mm',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notes,
                  decoration: const InputDecoration(
                    labelText: 'Shift note (optional)',
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
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save shift'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || userId == null) return;
    final from = _combine(start.text), to = _combine(end.text);
    if (from == null || to == null || !to.isAfter(from)) {
      _message('Enter valid shift times in HH:mm format.');
      return;
    }
    try {
      await RestaurantApi.scheduleShift({
        'branchId': widget.branchId,
        'userId': userId,
        'scheduledStart': from.toUtc().toIso8601String(),
        'scheduledEnd': to.toUtc().toIso8601String(),
        'notes': notes.text.trim(),
      });
      await _load();
      if (mounted) _message('Shift scheduled.');
    } catch (e) {
      if (mounted) _message(RestaurantApi.messageFor(e));
    }
  }

  Future<void> _clock(String id, bool clockIn) async {
    setState(() => busy.add(id));
    try {
      await RestaurantApi.clockAttendance(id, clockIn);
      await _load();
      if (mounted)
        _message(clockIn ? 'Clock-in recorded.' : 'Clock-out recorded.');
    } catch (e) {
      if (mounted) _message(RestaurantApi.messageFor(e));
    } finally {
      if (mounted) setState(() => busy.remove(id));
    }
  }

  DateTime? _combine(String raw) {
    final p = raw.split(':');
    if (p.length != 2) return null;
    final h = int.tryParse(p[0]), m = int.tryParse(p[1]);
    if (h == null || m == null || h > 23 || m > 59) return null;
    return DateTime(date.year, date.month, date.day, h, m);
  }

  void _changeDay(int days) {
    setState(() => date = date.add(Duration(days: days)));
    _load();
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (value != null) {
      setState(() => date = value);
      _load();
    }
  }

  String _dateLabel() =>
      ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][date.weekday % 7] +
      ', ${date.day}/${date.month}/${date.year}';
  String _time(dynamic raw) {
    final d = DateTime.tryParse('$raw')?.toLocal();
    return d == null
        ? '—'
        : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _initials(String value) => value
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((p) => p.isEmpty ? '' : p[0].toUpperCase())
      .join();
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
    border: Border.all(color: const Color(0xFFECE2D9)),
  );
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
}
