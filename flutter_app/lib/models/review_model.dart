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
    id: json['id'] ?? '',
    productId: json['product_id'] ?? '',
    userId: json['user_id'] ?? '',
    userName: json['user_name'] ?? 'Verified Customer',
    rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
    comment: json['comment'] ?? '',
    createdAt: json['created_at'] != null
        ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
        : DateTime.now(),
  );
}
