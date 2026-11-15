import 'package:flutter/material.dart';

class AnimatedPriceTicker extends StatelessWidget {
  const AnimatedPriceTicker({
    super.key,
    required this.amount,
    this.prefix = '₹',
    this.style,
  });

  final double amount;
  final String prefix;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: amount, end: amount),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          '$prefix${value.toStringAsFixed(0)}',
          style: style,
        );
      },
    );
  }
}
