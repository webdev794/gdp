class ReviewModel {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'user_id': userId,
    'user_name': userName,
    'rating': rating,
    'comment': comment,
    'created_at': createdAt.toIso8601String(),
  };

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    id: json['id']?.toString() ?? '',
    productId: json['product_id']?.toString() ?? '',
    userId: json['user_id']?.toString() ?? '',
    // Store sends "author" (first name + last initial).
    userName: (json['author'] ?? json['user_name'] ?? 'Customer').toString(),
    rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
    comment: json['comment']?.toString() ?? '',
    createdAt: DateTime.tryParse((json['updated_at'] ?? json['created_at'] ?? '').toString())?.toLocal() ?? DateTime.now(),
  );
}
