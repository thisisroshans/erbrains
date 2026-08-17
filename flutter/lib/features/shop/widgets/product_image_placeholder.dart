import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../design_system/nocturne_colors.dart';

/// Stands in for the design's `<image-slot>` placeholders. The backend's
/// `products` table has no image column yet — see docs/API_GAPS.md — so
/// every product renders this until that lands.
class ProductImagePlaceholder extends StatelessWidget {
  const ProductImagePlaceholder({
    super.key,
    this.label,
    this.height,
    this.borderRadius = 8,
  });

  final String? label;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: NocturneColors.neutral800,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            PhosphorIconsRegular.image,
            color: NocturneColors.neutral500,
            size: 22,
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: NocturneColors.neutral500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
