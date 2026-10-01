/// Money field from the API: `<key>_cents` (integer cents) when present, else `<key>` in dollars.
double _money(Map<String, dynamic> json, String key) {
  final cents = json['${key}_cents'];
  if (cents is num) return cents / 100.0;
  return (json[key] as num?)?.toDouble() ?? 0.0;
}

/// Store order statuses -> the app's display statuses.
/// Server: pending_payment, confirmed, packing, ready_for_delivery, out_for_delivery, completed, cancelled.
String _appStatus(String? status) {
  switch (status) {
    case 'completed':
      return 'delivered';
    case 'ready_for_delivery':
      return 'packing';
    case null:
      return 'confirmed';
    default:
      return status;
  }
}

String _addressText(dynamic address) {
  if (address is Map) {
    return [address['line1'], address['line2'], address['city'], address['state']]
        .where((p) => p != null && p.toString().trim().isNotEmpty)
        .join(', ');
  }
  return address?.toString() ?? '';
}

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String unit;
  final String emoji;
  final String? imageUrl;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.emoji,
    this.imageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name'] ?? json['name'] ?? 'Item',
      unit: json['variant_label'] ?? json['unit'] ?? '',
      emoji: json['emoji'] ?? '🛒',
      imageUrl: json['image_url'],
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      // The store API sends money in cents (unit_price_cents / line_total_cents).
      unitPrice: _money(json, 'unit_price'),
      totalPrice: json['line_total_cents'] != null ? _money(json, 'line_total') : _money(json, 'total_price'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'product_name': productName,
    'unit': unit,
    'emoji': emoji,
    'image_url': imageUrl,
    'quantity': quantity,
    'unit_price': unitPrice,
    'total_price': totalPrice,
  };
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String status; // 'confirmed', 'packing', 'out_for_delivery', 'delivered', 'cancelled'
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double discount;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String deliveryAddress;
  final String deliveryCode; // 4-digit OTP for rider handover
  final DateTime createdAt;
  final String? riderName;
  final String? riderPhone;
  final String? riderVehicle;
  final double riderRating;
  final double? riderReviewRating;
  final String? riderReviewComment;
  /// Item ratings the customer gave on this order: product id -> stars (1..5).
  final Map<String, int> itemRatings;
  /// Gift card balance left for a later order (only in the checkout reply).
  final double? giftCardRemaining;
  /// Why the store cancelled the order (shown to the customer); null otherwise.
  final String? cancelReason;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.deliveryAddress,
    required this.deliveryCode,
    required this.createdAt,
    this.riderName,
    this.riderPhone,
    this.riderVehicle,
    this.riderRating = 4.9,
    this.riderReviewRating,
    this.riderReviewComment,
    this.itemRatings = const {},
    this.giftCardRemaining,
    this.cancelReason,
  });

  OrderModel copyWith({
    String? status,
    double? riderReviewRating,
    String? riderReviewComment,
    String? riderName,
    String? riderPhone,
    String? riderVehicle,
    double? riderRating,
    Map<String, int>? itemRatings,
  }) {
    return OrderModel(
      id: id,
      orderNumber: orderNumber,
      status: status ?? this.status,
      items: items,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      tax: tax,
      discount: discount,
      total: total,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      deliveryAddress: deliveryAddress,
      deliveryCode: deliveryCode,
      createdAt: createdAt,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      riderVehicle: riderVehicle ?? this.riderVehicle,
      riderRating: riderRating ?? this.riderRating,
      riderReviewRating: riderReviewRating ?? this.riderReviewRating,
      riderReviewComment: riderReviewComment ?? this.riderReviewComment,
      itemRatings: itemRatings ?? this.itemRatings,
      giftCardRemaining: giftCardRemaining,
      cancelReason: cancelReason,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    return OrderModel(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number'] ?? '#${json['id']}',
      status: _appStatus(json['status']?.toString()),
      items: rawItems.map((i) => OrderItem.fromJson(i)).toList(),
      subtotal: _money(json, 'subtotal'),
      // Delivery + handling + small-basket fees, as one "delivery & fees" line.
      deliveryFee: _money(json, 'delivery_fee') + _money(json, 'handling_fee') + _money(json, 'small_cart_fee'),
      tax: _money(json, 'tax'),
      discount: json['gift_card_discount_cents'] != null ? _money(json, 'gift_card_discount') : _money(json, 'discount'),
      total: _money(json, 'total'),
      paymentMethod: (json['payment_method'] ?? 'card').toString().toUpperCase(),
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      deliveryAddress: _addressText(json['delivery_address']),
      deliveryCode: json['delivery_code']?.toString() ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'])?.toLocal() ?? DateTime.now() : DateTime.now(),
      riderName: json['rider']?['name'] ?? json['courier_name'] ?? json['rider_name'],
      riderPhone: json['rider']?['phone'] ?? json['rider_phone'],
      riderVehicle: json['rider']?['vehicle'] ?? json['rider_vehicle'],
      riderRating: (json['rider']?['rating'] as num?)?.toDouble() ?? 0,
      riderReviewRating: (json['rider_review']?['rating'] as num?)?.toDouble(),
      riderReviewComment: json['rider_review']?['comment'],
      cancelReason: json['cancelled_by'] == 'admin' && (json['cancel_reason']?.toString() ?? '').isNotEmpty ? json['cancel_reason'].toString() : null,
      giftCardRemaining: (json['gift_card_remaining_cents'] as num?) == null ? null : (json['gift_card_remaining_cents'] as num) / 100.0,
      itemRatings: {
        for (final r in (json['product_reviews'] as List? ?? []))
          r['product_id'].toString(): (r['rating'] as num?)?.toInt() ?? 0,
      },
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_number': orderNumber,
    'status': status,
    'items': items.map((i) => i.toJson()).toList(),
    'subtotal': subtotal,
    'delivery_fee': deliveryFee,
    'tax': tax,
    'discount': discount,
    'total': total,
    'payment_method': paymentMethod,
    'payment_status': paymentStatus,
    'delivery_address': deliveryAddress,
    'delivery_code': deliveryCode,
    'created_at': createdAt.toIso8601String(),
    'rider_name': riderName,
    'rider_phone': riderPhone,
    'rider_vehicle': riderVehicle,
    'rider_rating': riderRating,
  };
}
