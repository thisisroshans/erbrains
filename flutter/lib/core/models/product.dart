class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String? description;
  final double price;
  final int stock;

  /// The backend's `products` table has no image column today — see
  /// docs/API_GAPS.md. Always null until that lands; screens fall back to
  /// a placeholder tile (matching the design's `image-slot` placeholders).
  final String? imageUrl;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: double.parse(json['price'].toString()),
      stock: (json['stock'] as num).toInt(),
      imageUrl: json['image_url'] as String?,
    );
  }
}
