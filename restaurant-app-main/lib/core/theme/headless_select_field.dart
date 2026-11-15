import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'hospitality_theme.dart';

class HeadlessSelectItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? leading;

  const HeadlessSelectItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.leading,
  });
}

class HeadlessSelectField<T> extends StatelessWidget {
  final String label;
  final String? hint;
  final T? value;
  final List<HeadlessSelectItem<T>> items;
  final ValueChanged<T> onChanged;
  final IconData? prefixIcon;
  final bool isRequired;

  const HeadlessSelectField({
    super.key,
    required this.label,
    this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.prefixIcon,
    this.isRequired = false,
  });

  HeadlessSelectItem<T>? get _selectedItem {
    try {
      return items.firstWhere((item) => item.value == value);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedItem;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
              if (isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openPicker(context),
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected != null
                        ? HospitalityColors.saffron.withValues(alpha: 0.5)
                        : const Color(0xFFE2E8F0),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    if (selected?.leading != null) ...[
                      selected!.leading!,
                      const SizedBox(width: 10),
                    ] else if (prefixIcon != null || selected?.icon != null) ...[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: (selected?.iconColor ?? HospitalityColors.saffron)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          selected?.icon ?? prefixIcon,
                          color: selected?.iconColor ?? HospitalityColors.saffron,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selected?.label ?? hint ?? 'Select an option',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: selected != null
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected != null
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                          if (selected?.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              selected!.subtitle!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.unfold_more_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPicker(BuildContext context) {
    HapticFeedback.lightImpact();
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    if (isWide) {
      showDialog(
        context: context,
        builder: (dialogCtx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460, maxHeight: 520),
            child: _PickerContent<T>(
              title: label,
              items: items,
              selectedValue: value,
              onSelected: (val) {
                Navigator.pop(dialogCtx);
                onChanged(val);
              },
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) => DraggableScrollableSheet(
          initialChildSize: items.length > 6 ? 0.75 : 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: _PickerContent<T>(
              title: label,
              items: items,
              selectedValue: value,
              scrollController: scrollController,
              onSelected: (val) {
                Navigator.pop(sheetCtx);
                onChanged(val);
              },
            ),
          ),
        ),
      );
    }
  }
}

class _PickerContent<T> extends StatefulWidget {
  final String title;
  final List<HeadlessSelectItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T> onSelected;
  final ScrollController? scrollController;

  const _PickerContent({
    required this.title,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
    this.scrollController,
  });

  @override
  State<_PickerContent<T>> createState() => _PickerContentState<T>();
}

class _PickerContentState<T> extends State<_PickerContent<T>> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((item) {
      if (search.isEmpty) return true;
      final q = search.toLowerCase();
      return item.label.toLowerCase().contains(q) ||
          (item.subtitle?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 20),
                color: const Color(0xFF64748B),
              ),
            ],
          ),
        ),
        if (widget.items.length > 5) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: TextField(
              onChanged: (val) => setState(() => search = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        Flexible(
          child: ListView.separated(
            controller: widget.scrollController,
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final item = filtered[index];
              final isSelected = item.value == widget.selectedValue;

              return Material(
                color: isSelected ? const Color(0xFFFFF7ED) : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isSelected
                        ? HospitalityColors.saffron
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onSelected(item.value);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        if (item.leading != null) ...[
                          item.leading!,
                          const SizedBox(width: 12),
                        ] else if (item.icon != null) ...[
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: (item.iconColor ?? HospitalityColors.saffron)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              item.icon,
                              color: item.iconColor ?? HospitalityColors.saffron,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? const Color(0xFFC2410C)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              if (item.subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: HospitalityColors.saffron,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
