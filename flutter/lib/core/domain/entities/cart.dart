class CartItem {
  const CartItem({
    required this.cartItemId,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.imageUrl,
    this.pendingSync = false,
  });

  final String cartItemId;
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final double subtotal;
  final String? imageUrl;

  /// True for a line item that only exists because of a queued, not-yet-
  /// synced [CartMutation] — either newly added offline (in which case
  /// [cartItemId] is a `local:<mutation id>` placeholder, not a real
  /// backend id — see cart_sync/effective_cart.dart) or an existing item
  /// with a queued quantity change still pending. Never true for anything
  /// read straight from `GET /cart`.
  final bool pendingSync;

  CartItem copyWith({int? quantity, double? subtotal, bool? pendingSync}) {
    return CartItem(
      cartItemId: cartItemId,
      productId: productId,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
      imageUrl: imageUrl,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartItemId: json['cart_item_id'] as String,
      productId: json['product_id'] as String,
      name: json['name'] as String,
      price: double.parse(json['price'].toString()),
      quantity: (json['quantity'] as num).toInt(),
      subtotal: double.parse(json['subtotal'].toString()),
      imageUrl: json['image_url'] as String?,
      pendingSync: json['pending_sync'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'cart_item_id': cartItemId,
        'product_id': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'subtotal': subtotal,
        'image_url': imageUrl,
        'pending_sync': pendingSync,
      };
}

class Cart {
  const Cart({required this.items, required this.totalAmount});

  final List<CartItem> items;
  final double totalAmount;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  static const Cart empty = Cart(items: [], totalAmount: 0);

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      items: (json['items'] as List<dynamic>)
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAmount: double.parse(json['totalAmount'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((i) => i.toJson()).toList(),
        'totalAmount': totalAmount,
      };
}
