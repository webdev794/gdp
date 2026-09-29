import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/review_model.dart';

class ReviewService {
  static const String _storageKey = 'grocerly_product_reviews';
  static final Map<String, List<ReviewModel>> _reviewsByProduct = {};

  /// Global notifier to trigger UI rebuilds when a new review is added
  static final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  /// Load persisted reviews from device disk
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString(_storageKey);
      if (savedStr != null && savedStr.isNotEmpty) {
        final Map<String, dynamic> rawMap = json.decode(savedStr);
        _reviewsByProduct.clear();
        rawMap.forEach((productId, list) {
          if (list is List) {
            _reviewsByProduct[productId] = list
                .map((item) => ReviewModel.fromJson(Map<String, dynamic>.from(item)))
                .toList();
          }
        });
      }
    } catch (_) {}
  }

  /// Persist current reviews map to device disk
  static Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> rawMap = {};
      _reviewsByProduct.forEach((productId, reviews) {
        rawMap[productId] = reviews.map((r) => r.toJson()).toList();
      });
      await prefs.setString(_storageKey, json.encode(rawMap));
    } catch (_) {}
  }

  /// Get all customer reviews for a specific product
  static List<ReviewModel> getReviews(String productId) {
    return List.unmodifiable(_reviewsByProduct[productId] ?? []);
  }

  /// Count of customer reviews for a specific product
  static int getReviewCount(String productId) {
    return _reviewsByProduct[productId]?.length ?? 0;
  }

  /// Calculate real-time dynamic average star rating for a product (0.0 if no reviews)
  static double getAverageRating(String productId) {
    final list = _reviewsByProduct[productId];
    if (list == null || list.isEmpty) return 0.0;
    final double total = list.fold(0.0, (sum, r) => sum + r.rating);
    final double avg = total / list.length;
    return double.parse(avg.toStringAsFixed(1));
  }

  /// Add a new verified customer review strictly scoped to this product
  static Future<ReviewModel> addReview({
    required String productId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    final newReview = ReviewModel(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      productId: productId,
      userId: userId,
      userName: userName.isNotEmpty ? userName : 'Verified Customer',
      rating: rating.clamp(1.0, 5.0),
      comment: comment.trim(),
      createdAt: DateTime.now(),
    );

    if (!_reviewsByProduct.containsKey(productId)) {
      _reviewsByProduct[productId] = [];
    }
    // Insert at front so newest reviews appear first
    _reviewsByProduct[productId]!.insert(0, newReview);

    await _saveToDisk();
    changeNotifier.value++;
    return newReview;
  }

  /// Clear reviews (used in test suite)
  @visibleForTesting
  static void clearMemoryForTesting() {
    _reviewsByProduct.clear();
    changeNotifier.value = 0;
  }
}
