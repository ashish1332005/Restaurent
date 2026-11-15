import 'package:flutter/material.dart';
import '../../animations/flutterfx/bouncy_tap.dart';
import 'shadcn_theme.dart';

class ShadcnTabs<T> extends StatelessWidget {
  const ShadcnTabs({
    super.key,
    required this.selected,
    required this.items,
    required this.onChanged,
  });

  final T selected;
  final List<(T, String, IconData?)> items;
  final void Function(T value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ShadcnColors.muted,
        borderRadius: BorderRadius.circular(ShadcnRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final isSelected = item.$1 == selected;
          return BouncyTap(
            onTap: () => onChanged(item.$1),
            scaleDown: 0.96,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(ShadcnRadius.sm),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.$3 != null) ...[
                    Icon(
                      item.$3,
                      size: 15,
                      color: isSelected
                          ? ShadcnColors.foreground
                          : ShadcnColors.mutedForeground,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    item.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? ShadcnColors.foreground
                          : ShadcnColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
