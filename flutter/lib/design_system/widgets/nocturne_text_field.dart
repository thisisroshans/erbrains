import 'package:flutter/material.dart';

import '../nocturne_colors.dart';

/// `.field` + `.input` — a labelled text field on the surface fill.
class NocturneTextField extends StatelessWidget {
  const NocturneTextField({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.errorText,
    this.enabled = true,
    this.autofillHints,
  });

  final String label;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? errorText;
  final bool enabled;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: NocturneColors.text.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          enabled: enabled,
          autofillHints: autofillHints,
          style: const TextStyle(fontSize: 14, color: NocturneColors.text),
          cursorColor: NocturneColors.accent,
          decoration: InputDecoration(
            errorText: errorText,
            isDense: true,
          ),
        ),
      ],
    );
  }
}
