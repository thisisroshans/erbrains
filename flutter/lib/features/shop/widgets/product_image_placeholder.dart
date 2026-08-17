import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../design_system/nocturne_colors.dart';

/// Renders a product's [imageUrl] when present, matching the design's
/// `<image-slot>` mounts; falls back to a plain icon tile (using [label]
/// as a caption) when there's no URL, or it fails to load.
class ProductImagePlaceholder extends StatelessWidget {
  const ProductImagePlaceholder({
    super.key,
    this.label,
    this.imageUrl,
    this.height,
    this.borderRadius = 8,
  });

  final String? label;
  final String? imageUrl;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _Fallback(label: label, radius: radius, height: height);
    }

    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        imageUrl!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _Fallback(label: label, radius: radius, height: height, loading: true);
        },
        errorBuilder: (context, error, stackTrace) =>
            _Fallback(label: label, radius: radius, height: height),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({
    required this.label,
    required this.radius,
    this.height,
    this.loading = false,
  });

  final String? label;
  final BorderRadius radius;
  final double? height;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: NocturneColors.neutral800,
        borderRadius: radius,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: NocturneColors.neutral500),
            )
          else
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
