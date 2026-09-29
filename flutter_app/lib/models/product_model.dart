import '../config.dart';
import '../services/review_service.dart';
class ProductVariantModel {
  final String id;
  final String productId;
  final String label;
  final String sku;
  final double price;
  final double? comparePrice;
  final int inventoryQuantity;
  final String? imageUrl;
  final bool isActive;

  ProductVariantModel({
    required this.id,
    required this.productId,
    required this.label,
    required this.sku,
    required this.price,
    this.comparePrice,
    this.inventoryQuantity = 0,
    this.imageUrl,
    this.isActive = true,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    double p = 0.0;
    if (json['price_cents'] != null) {
      p = (json['price_cents'] as num).toDouble() / 100.0;
    } else if (json['price'] != null) {
      p = (json['price'] as num).toDouble();
    }

    double? cp;
    if (json['compare_at_price_cents'] != null) {
      cp = (json['compare_at_price_cents'] as num).toDouble() / 100.0;
    } else if (json['compare_price'] != null) {
      cp = (json['compare_price'] as num).toDouble();
    }

    final rawImg = json['image_url']?.toString();
    String? fullImg;
    if (rawImg != null && rawImg.isNotEmpty) {
      if (rawImg.startsWith('http')) {
        fullImg = rawImg;
      } else if (rawImg.startsWith('/')) {
        fullImg = '${AppConfig.siteUrl}$rawImg';
      } else {
        fullImg = '${AppConfig.siteUrl}/$rawImg';
      }
    }

    return ProductVariantModel(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Option',
      sku: json['sku']?.toString() ?? '',
      price: p,
      comparePrice: cp,
      inventoryQuantity: (json['inventory_quantity'] as num?)?.toInt() ?? 0,
      imageUrl: fullImg,
      isActive: json['is_active'] != false,
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final String categoryId;
  final double price;
  final double? comparePrice;
  final String unit;
  final String imageEmoji;
  final String? imageUrl;
  final String? badgeText;
  final double rating;
  final int reviewCount;
  final bool inStock;
  final String slug;

  // Full Database / Backend Fields
  final String? description;
  final String? sku;
  final int? inventoryQuantity;
  final String? categoryName;
  final String? categorySlug;
  final String? categoryImageUrl;
  final List<ProductVariantModel> variants;
  final List<String> galleryImages;
  final bool isActive;
  final double? priceMin;
  final double? priceMax;
  final String? createdAt;
  final String? updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    this.comparePrice,
    required this.unit,
    required this.imageEmoji,
    this.imageUrl,
    this.badgeText,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.inStock = true,
    this.slug = '',
    this.description,
    this.sku,
    this.inventoryQuantity,
    this.categoryName,
    this.categorySlug,
    this.categoryImageUrl,
    this.variants = const [],
    this.galleryImages = const [],
    this.isActive = true,
    this.priceMin,
    this.priceMax,
    this.createdAt,
    this.updatedAt,
  });

  double get displayRating => (rating as dynamic) ?? 0.0;
  double get displayPrice => (price as dynamic) ?? 0.0;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    double parsedPrice = 0.0;
    if (json.containsKey('price_cents') && json['price_cents'] != null) {
      parsedPrice = (json['price_cents'] as num).toDouble() / 100.0;
    } else if (json.containsKey('price') && json['price'] != null) {
      parsedPrice = (json['price'] as num).toDouble();
    }

    double? parsedComparePrice;
    if (json['compare_at_price_cents'] != null) {
      parsedComparePrice = (json['compare_at_price_cents'] as num).toDouble() / 100.0;
    } else if (json['compare_price'] != null) {
      parsedComparePrice = (json['compare_price'] as num).toDouble();
    }

    double? pMin;
    if (json['price_min_cents'] != null) {
      pMin = (json['price_min_cents'] as num).toDouble() / 100.0;
    }
    double? pMax;
    if (json['price_max_cents'] != null) {
      pMax = (json['price_max_cents'] as num).toDouble() / 100.0;
    }

    final rawImg = json['image_url']?.toString();
    String? fullImg;
    if (rawImg != null && rawImg.isNotEmpty) {
      if (rawImg.startsWith('http')) {
        fullImg = rawImg;
      } else if (rawImg.startsWith('/')) {
        fullImg = '${AppConfig.siteUrl}$rawImg';
      } else {
        fullImg = '${AppConfig.siteUrl}/$rawImg';
      }
    }

    // Gallery images
    final List<String> gallery = [];
    if (json['images'] != null && json['images'] is List) {
      for (final img in (json['images'] as List)) {
        final u = img['image_url']?.toString();
        if (u != null && u.isNotEmpty) {
          if (u.startsWith('http')) {
            gallery.add(u);
          } else if (u.startsWith('/')) {
            gallery.add('${AppConfig.siteUrl}$u');
          } else {
            gallery.add('${AppConfig.siteUrl}/$u');
          }
        }
      }
    }

    // Variants
    final List<ProductVariantModel> varList = [];
    if (json['variants'] != null && json['variants'] is List) {
      for (final v in (json['variants'] as List)) {
        if (v is Map<String, dynamic>) {
          varList.add(ProductVariantModel.fromJson(v));
        } else if (v is Map) {
          varList.add(ProductVariantModel.fromJson(Map<String, dynamic>.from(v)));
        }
      }
    }

    final catId = json['category_id']?.toString() ?? json['category']?['id']?.toString() ?? '';
    final catName = json['category']?['name']?.toString();
    final catSlug = json['category']?['slug']?.toString();
    final catImg = json['category']?['image_url']?.toString();
    final prodName = json['name']?.toString() ?? 'Product';
    final slug = json['slug']?.toString() ?? '';
    final isOut = json['out_of_stock'] == true;
    if (json.containsKey('rating_count')) {
      ReviewService.recordSummary(json['id']?.toString() ?? '', (json['rating_avg'] as num?)?.toDouble(), (json['rating_count'] as num?)?.toInt() ?? 0);
    }
    final qty = (json['inventory_quantity'] as num?)?.toInt();
    final inStock = !isOut && (qty == null || qty > 0);
    final desc = json['description']?.toString();
    final sku = json['sku']?.toString();
    final isActive = json['is_active'] != false;
    final createdAt = json['created_at']?.toString();
    final updatedAt = json['updated_at']?.toString();

    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: prodName,
      categoryId: catId,
      price: parsedPrice,
      comparePrice: parsedComparePrice,
      unit: json['unit'] ?? json['sku'] ?? '1 pack',
      imageEmoji: _getEmojiForProduct(prodName, catName ?? ''),
      imageUrl: fullImg,
      badgeText: (parsedComparePrice != null && parsedComparePrice > parsedPrice)
          ? '${(((parsedComparePrice - parsedPrice) / parsedComparePrice) * 100).round()}% OFF'
          : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      inStock: inStock,
      slug: slug,
      description: desc,
      sku: sku,
      inventoryQuantity: qty,
      categoryName: catName,
      categorySlug: catSlug,
      categoryImageUrl: catImg,
      variants: varList,
      galleryImages: gallery,
      isActive: isActive,
      priceMin: pMin,
      priceMax: pMax,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Same name -> emoji list as the website (web/src/Storefront.jsx PRODUCT_EMOJI),
  // shown when a product has no image; anything else gets the cart 🛒.
  static final List<MapEntry<RegExp, String>> _productEmoji = [
    for (final e in const [
      ['banana', '🍌'], ['apple', '🍎'], ['egg', '🥚'], ['milk', '🥛'],
      ['rice', '🍚'], ['pasta|noodle|spaghetti', '🍝'], ['bread|loaf|bun', '🍞'],
      ['cheese', '🧀'], ['butter', '🧈'], ['yog[hu]|yoghurt', '🥣'],
      ['tomato', '🍅'], ['potato', '🥔'], ['onion|garlic', '🧅'],
      ['carrot', '🥕'], ['orange|citrus', '🍊'], ['grape', '🍇'],
      ['berr|blueberr|strawberr', '🫐'], ['lemon|lime', '🍋'], ['avocado', '🥑'],
      ['chicken|poultry', '🍗'], ['fish|salmon|tuna', '🐟'], ['coffee', '☕'],
      [r'\btea\b', '🍵'], ['water', '💧'], ['juice', '🧃'], ['oil', '🫙'],
      ['sugar', '🍬'], ['salt', '🧂'], ['chocolate|cookie|biscuit', '🍪'],
      ['chip|crisp', '🍟'], ['corn', '🌽'], ['bean|lentil', '🫘'],
      ['flour|wheat', '🌾'], ['honey', '🍯'], ['pepper|chil', '🌶️'],
      ['mushroom', '🍄'], ['broccoli', '🥦'], ['lettuce|spinach|kale|salad', '🥬'],
    ])
      MapEntry(RegExp(e[0], caseSensitive: false), e[1]),
  ];

  static String _getEmojiForProduct(String name, String catName) {
    for (final e in _productEmoji) {
      if (e.key.hasMatch(name)) return e.value;
    }
    return '🛒';
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? categoryId,
    double? price,
    double? comparePrice,
    String? unit,
    String? imageEmoji,
    String? imageUrl,
    String? badgeText,
    double? rating,
    int? reviewCount,
    bool? inStock,
    String? slug,
    String? description,
    String? sku,
    int? inventoryQuantity,
    String? categoryName,
    String? categorySlug,
    String? categoryImageUrl,
    List<ProductVariantModel>? variants,
    List<String>? galleryImages,
    bool? isActive,
    double? priceMin,
    double? priceMax,
    String? createdAt,
    String? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      comparePrice: comparePrice ?? this.comparePrice,
      unit: unit ?? this.unit,
      imageEmoji: imageEmoji ?? this.imageEmoji,
      imageUrl: imageUrl ?? this.imageUrl,
      badgeText: badgeText ?? this.badgeText,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      inStock: inStock ?? this.inStock,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      inventoryQuantity: inventoryQuantity ?? this.inventoryQuantity,
      categoryName: categoryName ?? this.categoryName,
      categorySlug: categorySlug ?? this.categorySlug,
      categoryImageUrl: categoryImageUrl ?? this.categoryImageUrl,
      variants: variants ?? this.variants,
      galleryImages: galleryImages ?? this.galleryImages,
      isActive: isActive ?? this.isActive,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
