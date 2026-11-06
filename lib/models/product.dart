class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? categoryId;
  final String? categoryName;
  final List<String> compatibleModels;
  final List<String> images;
  final bool isDemo;
  final DateTime? createdAt;
  final int soldCount;

  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.stock = 0,
    this.categoryId,
    this.categoryName,
    this.compatibleModels = const [],
    this.images = const [],
    this.isDemo = false,
    this.createdAt,
    this.soldCount = 0,
  });

  bool get isInStock => stock > 0;
  bool get isLowStock => stock > 0 && stock <= 5;
  String? get imageUrl => images.isNotEmpty ? images.first : null;

  /// Premye mo nan chak modèl konpatib = mak la (ex: "Toyota").
  String? get primaryBrand {
    for (final model in compatibleModels) {
      final brand = model.split(' ').first;
      if (brand.toLowerCase() != 'universal') return brand;
    }
    return compatibleModels.isNotEmpty ? 'Universal' : null;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final embeddedItems = (json['redlight_order_items'] ?? json['order_items']) as List?;
    final sold = embeddedItems == null
        ? 0
        : embeddedItems.fold<int>(
            0,
            (sum, e) => sum + ((e as Map)['quantity'] as num? ?? 0).toInt(),
          );

    final catMap = (json['redlight_categories'] ?? json['categories']) as Map?;

    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      categoryId: json['category_id'] as String?,
      categoryName: catMap?['name'] as String?,
      compatibleModels:
          (json['compatible_models'] as List?)?.cast<String>() ?? const [],
      images: (json['images'] as List?)?.cast<String>() ?? const [],
      isDemo: json['is_demo'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      soldCount: sold,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'price': price,
    'stock': stock,
    'category_id': categoryId,
    'compatible_models': compatibleModels,
    'images': images,
    'is_demo': isDemo,
  };
}
