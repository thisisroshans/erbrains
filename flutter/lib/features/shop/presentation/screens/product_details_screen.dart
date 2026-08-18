import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/nocturne.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../controllers/shop_controller.dart';
import '../widgets/product_image_placeholder.dart';

/// Screen 07 · Product details.
class ProductDetailsScreen extends ConsumerWidget {
  const ProductDetailsScreen({
    super.key,
    required this.productId,
    required this.userId,
  });

  final String productId;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productProvider(productId));
    final quantity = ref.watch(productQuantityProvider(productId));

    return Scaffold(
      backgroundColor: NocturneColors.bg,
      body: SafeArea(
        child: productAsync.when(
          data: (product) => ListView(
            children: [
              ProductImagePlaceholder(
                label: product.name,
                imageUrl: product.imageUrl,
                height: 260,
                borderRadius: 0,
              ),
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
                          value: quantity,
                          onDecrement: () =>
                              ref.read(productQuantityProvider(productId).notifier).decrement(),
                          onIncrement: () =>
                              ref.read(productQuantityProvider(productId).notifier).increment(),
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
                                  .read(cartProvider(userId).notifier)
                                  .addToCart(product: product, quantity: quantity);
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
