import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/nocturne.dart';
import '../cart/cart_provider.dart';
import 'shop_providers.dart';
import 'widgets/product_image_placeholder.dart';

/// Screen 07 · Product details.
class ProductDetailsScreen extends ConsumerStatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.productId,
    required this.userId,
  });

  final String productId;
  final String userId;

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productProvider(widget.productId));

    return Scaffold(
      backgroundColor: NocturneColors.bg,
      body: SafeArea(
        child: productAsync.when(
          data: (product) => ListView(
            children: [
              ProductImagePlaceholder(label: product.name, height: 260, borderRadius: 0),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name, style: NocturneType.h4),
                              if (product.stock <= 5 && product.stock > 0)
                                Text('Only ${product.stock} left', style: NocturneType.caption)
                              else if (product.stock == 0)
                                Text('Out of stock', style: NocturneType.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: NocturneColors.accent300,
                      ),
                    ),
                    if (product.description != null)
                      Text(
                        product.description!,
                        style: NocturneType.bodySmall.copyWith(
                          color: NocturneColors.neutral300,
                          height: 1.5,
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Quantity', style: NocturneType.caption),
                        NocturneStepper(
                          value: _quantity,
                          onDecrement: () => setState(() => _quantity--),
                          onIncrement: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                    NocturneButton(
                      label: 'Add to cart',
                      block: true,
                      onPressed: product.stock == 0
                          ? null
                          : () async {
                              final ok = await ref
                                  .read(cartProvider(widget.userId).notifier)
                                  .addToCart(productId: product.id, quantity: _quantity);
                              if (ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Added ${product.name} to cart')),
                                );
                              }
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text('Could not load product: $err', style: NocturneType.caption),
          ),
        ),
      ),
    );
  }
}
