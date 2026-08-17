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

  /// Currently seeded with placeholder images (placehold.co) rather than
  /// real product photography — see database/seed.sql. Screens fall back
  /// to a plain tile (matching the design's `image-slot` placeholders)
  /// whenever this is null or fails to load.
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
