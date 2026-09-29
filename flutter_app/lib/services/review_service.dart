import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/review_model.dart';
import 'api_service.dart';

/// Product reviews from the store (GET/POST /api/products/{slug}/reviews), so
/// ratings written on the website show in the app and vice versa.
class ReviewService {
  static final Map<String, List<ReviewModel>> _reviewsByProduct = {};
  static final Map<String, double> _average = {};
  static final Map<String, int> _count = {};

  /// Bumped whenever reviews change, so product cards and sheets rebuild.
  static final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  static Future<void> init() async {}

  /// Card stars come with the product list (rating_avg / rating_count).
  static void recordSummary(String productId, double? average, int count) {
    _average[productId] = average ?? 0.0;
    _count[productId] = count;
  }

  static List<ReviewModel> getReviews(String productId) => List.unmodifiable(_reviewsByProduct[productId] ?? []);
  static int getReviewCount(String productId) => _count[productId] ?? 0;
  static double getAverageRating(String productId) => double.parse((_average[productId] ?? 0.0).toStringAsFixed(1));

  static Future<void> load(String productId, String slug) async {
    try {
      final res = await http
          .get(Uri.parse('${ApiService.baseUrl}/products/$slug/reviews'), headers: ApiService.headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final data = json.decode(res.body);
      _reviewsByProduct[productId] = (data['data'] as List? ?? [])
          .map((r) => ReviewModel.fromJson(Map<String, dynamic>.from(r)))
          .toList();
      final summary = data['summary'] ?? {};
      recordSummary(productId, (summary['average'] as num?)?.toDouble(), (summary['count'] as num?)?.toInt() ?? 0);
      changeNotifier.value++;
    } catch (_) {}
  }

  /// Rate one item on one of the customer's orders (once per item per order).
  static Future<ReviewModel> reviewOrderItem({
    required String orderId,
    required String productId,
    required int rating,
    required String comment,
  }) async {
    final res = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/orders/$orderId/reviews'),
          headers: ApiService.headers,
          body: json.encode({'product_id': int.tryParse(productId) ?? productId, 'rating': rating.clamp(1, 5), 'comment': comment.trim()}),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw ApiException(ApiService.errorMessage(res, 'Your review could not be saved.'));
    }
    changeNotifier.value++;
    return ReviewModel.fromJson(Map<String, dynamic>.from(json.decode(res.body)['data']));
  }

  @visibleForTesting
  static void clearMemoryForTesting() {
    _reviewsByProduct.clear();
    _average.clear();
    _count.clear();
    changeNotifier.value = 0;
  }
}
