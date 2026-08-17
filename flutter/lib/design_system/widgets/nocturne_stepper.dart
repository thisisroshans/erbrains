import 'package:flutter/material.dart';

import '../nocturne_colors.dart';

/// `.stepper` + `.step-btn` — a quantity increment/decrement control.
class NocturneStepper extends StatelessWidget {
  const NocturneStepper({
    super.key,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    this.size = 26,
    this.minValue = 1,
  });

  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final double size;
  final int minValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove,
          size: size,
          onPressed: value > minValue ? onDecrement : null,
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: NocturneColors.text),
          ),
        ),
        _StepButton(icon: Icons.add, size: size, onPressed: onIncrement),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.size,
    required this.onPressed,
  });

  final IconData icon;
  final double size;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Opacity(
          opacity: disabled ? 0.4 : 1,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: NocturneColors.neutral600, width: 1),
              color: NocturneColors.neutral800,
            ),
            child: Icon(icon, size: size * 0.5, color: NocturneColors.text),
          ),
        ),
      ),
    );
  }
}
