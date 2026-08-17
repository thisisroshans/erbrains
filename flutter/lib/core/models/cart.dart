class CartItem {
  const CartItem({
    required this.cartItemId,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.imageUrl,
  });

  final String cartItemId;
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final double subtotal;
  final String? imageUrl;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartItemId: json['cart_item_id'] as String,
      productId: json['product_id'] as String,
      name: json['name'] as String,
      price: double.parse(json['price'].toString()),
      quantity: (json['quantity'] as num).toInt(),
      subtotal: double.parse(json['subtotal'].toString()),
      imageUrl: json['image_url'] as String?,
    );
  }
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
}
