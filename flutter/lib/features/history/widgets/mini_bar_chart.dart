import 'package:flutter/material.dart';

import '../../../design_system/nocturne_colors.dart';

/// Mirrors screen 04's "Steps this week" bars — one taller accent bar for
/// today, the rest in the dim accent-700 tone.
class MiniBarChart extends StatelessWidget {
  const MiniBarChart({super.key, required this.values, this.height = 60});

  final List<double> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maxV = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: FractionallySizedBox(
                heightFactor: (values[i] / maxV).clamp(0.04, 1.0),
                alignment: Alignment.bottomCenter,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: i == values.length - 1
                        ? NocturneColors.accent300
                        : NocturneColors.accent700,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
