import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/models/product.dart';
import '../../design_system/nocturne.dart';
import '../cart/cart_provider.dart';
import '../cart/cart_screen.dart';
import 'product_details_screen.dart';
import 'shop_providers.dart';
import 'widgets/product_image_placeholder.dart';

/// Screen 06 · Product listing (Shop tab).
class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final cartCount = ref.watch(cartProvider(userId)).cart.itemCount;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Shop', style: NocturneType.h4),
                NocturneBadgeIcon(
                  icon: const Icon(PhosphorIconsRegular.bag, color: NocturneColors.text),
                  count: cartCount,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CartScreen(userId: userId)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: productsAsync.when(
                data: (products) => RefreshIndicator(
                  onRefresh: () => ref.refresh(productsProvider.future),
                  child: GridView.builder(
                    itemCount: products.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemBuilder: (context, i) => _ProductTile(
                      product: products[i],
                      userId: userId,
                    ),
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Text('Could not load products: $err', style: NocturneType.caption),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  const _ProductTile({required this.product, required this.userId});

  final Product product;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NocturneCard(
      padding: const EdgeInsets.all(10),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(productId: product.id, userId: userId),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Expanded(
            child: ProductImagePlaceholder(label: product.name),
          ),
          Text(
            product.name,
            style: NocturneType.bodySmall.copyWith(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, color: NocturneColors.accent300),
              ),
              NocturneIconButton(
                icon: const Icon(PhosphorIconsBold.plus),
                size: 26,
                semanticLabel: 'Add ${product.name} to cart',
                onPressed: () => ref
                    .read(cartProvider(userId).notifier)
                    .addToCart(productId: product.id, quantity: 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
