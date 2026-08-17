class Order {
  const Order({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.itemCount,
  });

  final String id;
  final String userId;
  final double totalAmount;
  final String status;
  final DateTime createdAt;

  /// From `GET /orders`' `item_count` aggregate (a `COUNT` subquery over
  /// `order_items` — see api/app.js).
  final int itemCount;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      totalAmount: double.parse(json['total_amount'].toString()),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      itemCount: (json['item_count'] as num).toInt(),
    );
  }
}
