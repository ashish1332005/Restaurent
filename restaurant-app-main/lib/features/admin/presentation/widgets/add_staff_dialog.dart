import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddStaffDialog extends StatefulWidget {
  const AddStaffDialog({
    super.key,
    required this.onStaffAdded,
    this.initialData,
  });

  final Function(Map<String, dynamic> staff) onStaffAdded;
  final Map<String, dynamic>? initialData;

  @override
  State<AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<AddStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  String _selectedRole = 'Waiter';
  String _selectedShift = 'Morning';
  String _selectedStatus = 'Active';
  bool _obscurePassword = true;

  final List<String> _roles = ['Manager', 'Waiter', 'Cashier', 'Kitchen'];
  final List<String> _shifts = ['Morning', 'Evening', 'Night', 'Full Day'];
  final List<String> _statuses = ['Active', 'Disabled'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?['name'] ?? '');
    _phoneController = TextEditingController(text: widget.initialData?['phone'] ?? '');
    _passwordController = TextEditingController(text: widget.initialData?['password'] ?? '');
    if (widget.initialData != null) {
      if (_roles.contains(widget.initialData!['role'])) {
        _selectedRole = widget.initialData!['role'];
      }
      if (_shifts.contains(widget.initialData!['shift'])) {
        _selectedShift = widget.initialData!['shift'];
      }
      if (_statuses.contains(widget.initialData!['status'])) {
        _selectedStatus = widget.initialData!['status'];
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final staffData = {
        'id': widget.initialData?['id'] ?? 'st_${DateTime.now().millisecondsSinceEpoch}',
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'password': _passwordController.text.trim(),
        'role': _selectedRole,
        'shift': _selectedShift,
        'status': _selectedStatus,
        'createdAt': widget.initialData?['createdAt'] ?? DateTime.now().toIso8601String(),
      };
      widget.onStaffAdded(staffData);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialData != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Staff Credentials' : 'Add New Team Member',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isEditing
                      ? 'Update credentials or toggle access permissions.'
                      : 'Grant role-based login credentials for your staff member.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 20),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g. John Doe',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return 'Enter a valid staff name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number (Login ID)',
                    hintText: '10-digit mobile number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.length != 10) {
                      return 'Enter a valid 10-digit mobile number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Password / PIN Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Login Password / PIN',
                    hintText: 'Minimum 6 digits/characters',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Role & Shift Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                        ),
                        items: _roles.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRole = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedShift,
                        decoration: const InputDecoration(
                          labelText: 'Shift',
                          border: OutlineInputBorder(),
                        ),
                        items: _shifts.map((shift) {
                          return DropdownMenuItem(
                            value: shift,
                            child: Text(shift),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedShift = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Status Toggle Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Account Status',
                    border: OutlineInputBorder(),
                  ),
                  items: _statuses.map((status) {
                    final isActive = status == 'Active';
                    return DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Icon(
                            isActive ? Icons.check_circle_rounded : Icons.block_rounded,
                            color: isActive ? const Color(0xFF1FA971) : const Color(0xFFEF4444),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(status),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  },
                ),

                const SizedBox(height: 24),

                // Submit Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B6BFB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(isEditing ? Icons.save_rounded : Icons.person_add_rounded, size: 18),
                      label: Text(isEditing ? 'Save Changes' : 'Grant Access'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
