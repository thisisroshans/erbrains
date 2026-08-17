import 'package:flutter/material.dart';

import '../nocturne_colors.dart';

/// `.seg` + `.seg-opt` — a segmented choice control (e.g. Daily / Weekly).
class NocturneSegmentedControl<T> extends StatelessWidget {
  const NocturneSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<NocturneSegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: NocturneColors.divider, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0)
              Container(width: 1, height: 24, color: NocturneColors.divider),
            _SegOption(
              label: options[i].label,
              selected: options[i].value == value,
              onTap: () => onChanged(options[i].value),
            ),
          ],
        ],
      ),
    );
  }
}

class NocturneSegmentOption<T> {
  const NocturneSegmentOption({required this.label, required this.value});

  final String label;
  final T value;
}

class _SegOption extends StatelessWidget {
  const _SegOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: selected
              ? BoxDecoration(
                  border: Border.all(color: NocturneColors.accent, width: 1),
                )
              : null,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: selected ? NocturneColors.accent : NocturneColors.text,
            ),
          ),
        ),
      ),
    );
  }
}
