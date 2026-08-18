/// One queued, not-yet-applied write against the cart or an order —
/// the cart/order equivalent of [HealthReading]'s offline queue, applied
/// in write order by `CartSyncManager`. See docs/OFFLINE_SYNC.md.
enum CartMutationType { add, setQuantity, remove, placeOrder }

enum CartMutationStatus { pending, failed }

class CartMutation {
  const CartMutation({
    required this.localId,
    required this.type,
    required this.createdAt,
    this.productId,
    this.productName,
    this.productPrice,
    this.productImageUrl,
    this.cartItemId,
    this.quantity,
    this.status = CartMutationStatus.pending,
    this.attempts = 0,
  });

  final String localId;
  final CartMutationType type;
  final DateTime createdAt;

  // [CartMutationType.add] only — a denormalized snapshot of the product
  // being added (captured from the already-loaded [Product] at the call
  // site), so the effective-cart projection can render an offline-created
  // line item without a separate catalog lookup. Mirrors the backend's own
  // `order_items.price_at_purchase` snapshot-at-write-time pattern.
  final String? productId;
  final String? productName;
  final double? productPrice;
  final String? productImageUrl;

  /// [CartMutationType.setQuantity] / [CartMutationType.remove] target.
  /// Either a real backend `cart_item_id`, or a `local:<mutation id>`
  /// placeholder referencing a line item created by a still-unsynced
  /// [CartMutationType.add] — rewritten to the real id in place once that
  /// add mutation syncs (see `CartSyncStore.rewriteCartItemId`), so a
  /// dependent mutation drained in a later session still resolves
  /// correctly even if the app was killed in between.
  final String? cartItemId;

  /// [CartMutationType.add] / [CartMutationType.setQuantity] only.
  final int? quantity;

  final CartMutationStatus status;

  /// Consecutive failed drain attempts — see [CartMutationStatus.failed].
  final int attempts;

  /// The synthetic cart-item id an [CartMutationType.add] mutation stands
  /// in for until it syncs — see [cartItemId]'s doc.
  String get localCartItemId => 'local:$localId';

  CartMutation copyWith({CartMutationStatus? status, int? attempts, String? cartItemId}) {
    return CartMutation(
      localId: localId,
      type: type,
      createdAt: createdAt,
      productId: productId,
      productName: productName,
      productPrice: productPrice,
      productImageUrl: productImageUrl,
      cartItemId: cartItemId ?? this.cartItemId,
      quantity: quantity,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
    );
  }

  Map<String, dynamic> toHiveMap() => {
        'local_id': localId,
        'type': type.name,
        'created_at': createdAt.toUtc().toIso8601String(),
        'product_id': productId,
        'product_name': productName,
        'product_price': productPrice,
        'product_image_url': productImageUrl,
        'cart_item_id': cartItemId,
        'quantity': quantity,
        'status': status.name,
        'attempts': attempts,
      };

  factory CartMutation.fromHiveMap(Map<dynamic, dynamic> row) => CartMutation(
        localId: row['local_id'] as String,
        type: CartMutationType.values.firstWhere((t) => t.name == row['type']),
        createdAt: DateTime.parse(row['created_at'] as String),
        productId: row['product_id'] as String?,
        productName: row['product_name'] as String?,
        productPrice: (row['product_price'] as num?)?.toDouble(),
        productImageUrl: row['product_image_url'] as String?,
        cartItemId: row['cart_item_id'] as String?,
        quantity: row['quantity'] as int?,
        status: CartMutationStatus.values.firstWhere(
          (s) => s.name == row['status'],
          orElse: () => CartMutationStatus.pending,
        ),
        attempts: (row['attempts'] as int?) ?? 0,
      );
}
