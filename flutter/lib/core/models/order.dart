class Order {
  const Order({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.itemCount,
  });

  final String id;
  final String userId;
  final double totalAmount;
  final String status;
  final DateTime createdAt;

  /// `GET /orders` doesn't join `order_items` to return a count today —
  /// see docs/API_GAPS.md. Null until that lands; the Order History screen
  /// omits the "N items" line when this is null rather than fabricating it.
  final int? itemCount;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      totalAmount: double.parse(json['total_amount'].toString()),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      itemCount: json['item_count'] != null
          ? (json['item_count'] as num).toInt()
          : null,
    );
  }
}
