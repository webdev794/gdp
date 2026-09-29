import '../models/category_model.dart';
import '../models/product_model.dart';

/// Catalogue cache, filled only from the store (GET /api/categories, /api/products).
/// No built-in sample products: the app shows exactly what the admin publishes.
class MockDataService {
  static final List<CategoryModel> categories = [];
  static final List<ProductModel> products = [];
}
