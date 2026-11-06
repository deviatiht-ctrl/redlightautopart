class OrderItem {
  final String id;
  final String? productId;
  final String? productName;
  final String? productImage;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    required this.id,
    this.productId,
    this.productName,
    this.productImage,
    required this.quantity,
    required this.unitPrice,
  });

  double get lineTotal => unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = (json['redlight_products'] ?? json['products']) as Map?;
    final images = (product?['images'] as List?)?.cast<String>() ?? const [];
    return OrderItem(
      id: json['id'] as String,
      productId: json['product_id'] as String?,
      productName: product?['name'] as String?,
      productImage: images.isNotEmpty ? images.first : null,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unit_price'] as num).toDouble(),
    );
  }
}

class AppOrder {
  final String id;
  final String? userId;
  final String status;
  final String paymentStatus;
  final double total;
  final String? deliveryAddress;
  final String? paymentMethod;
  final DateTime? createdAt;
  final List<OrderItem> items;

  const AppOrder({
    required this.id,
    this.userId,
    required this.status,
    this.paymentStatus = 'unpaid',
    required this.total,
    this.deliveryAddress,
    this.paymentMethod,
    this.createdAt,
    this.items = const [],
  });

  int get itemCount => items.fold(0, (sum, e) => sum + e.quantity);

  factory AppOrder.fromJson(Map<String, dynamic> json) => AppOrder(
    id: json['id'] as String,
    userId: json['user_id'] as String?,
    status: json['status'] as String? ?? 'pending',
    paymentStatus: json['payment_status'] as String? ?? 'unpaid',
    total: (json['total'] as num).toDouble(),
    deliveryAddress: json['delivery_address'] as String?,
    paymentMethod: json['payment_method'] as String?,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    items:
        ((json['redlight_order_items'] ?? json['order_items']) as List?)
            ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}
