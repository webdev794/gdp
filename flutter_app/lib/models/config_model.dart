import '../config.dart';
class StoreModel {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final double deliveryRadiusKm;

  StoreModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.deliveryRadiusKm,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: (json['id'] as num?)?.toInt() ?? 1,
      name: json['name'] ?? AppConfig.storeName,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      deliveryRadiusKm: (json['delivery_radius_km'] as num?)?.toDouble() ?? 25.0,
    );
  }
}

class PromoBanner {
  final String id;
  final String imageUrl;
  final String headline;
  final String? categorySlug;
  final String? linkUrl;
  final String? badge;

  PromoBanner({
    required this.id,
    required this.imageUrl,
    required this.headline,
    this.categorySlug,
    this.linkUrl,
    this.badge,
  });

  factory PromoBanner.fromJson(Map<String, dynamic> json) {
    return PromoBanner(
      id: json['id']?.toString() ?? '',
      imageUrl: json['image_url'] ?? '',
      headline: json['headline'] ?? '',
      categorySlug: json['category_slug'],
      linkUrl: json['link_url'],
      badge: json['badge'],
    );
  }
}

class AppConfigModel {
  final String storeName;
  final String tagline;
  final String logoUrl;
  final String contactEmail;
  final String contactPhone;
  final String contactAddress;
  final String stripePublishableKey;
  final String currency;
  final bool otpEnabled;
  final bool codEnabled;
  final bool enforceRadius;
  final double deliveryFee;
  final double freeDeliveryThreshold;
  final List<PromoBanner> banners;
  final List<StoreModel> stores;

  AppConfigModel({
    this.storeName = AppConfig.storeName,
    this.tagline = 'Fresh groceries, less fuss',
    this.logoUrl = '',
    this.contactEmail = '',
    this.contactPhone = '',
    this.contactAddress = '',
    this.stripePublishableKey = '',
    this.currency = 'USD',
    this.otpEnabled = true,
    this.codEnabled = true,
    this.enforceRadius = true,
    this.deliveryFee = 2.99,
    this.freeDeliveryThreshold = 15.0,
    required this.banners,
    this.stores = const [],
  });

  factory AppConfigModel.defaults() {
    return AppConfigModel(
      storeName: AppConfig.storeName,
      tagline: 'Fresh groceries, less fuss',
      currency: 'USD',
      otpEnabled: true,
      codEnabled: true,
      deliveryFee: 2.99,
      freeDeliveryThreshold: 15.0,
      // Banners and stores come only from Admin (GET /api/config).
      banners: [],
      stores: [],
    );
  }

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    final branding = json['branding'] as Map<String, dynamic>? ?? {};
    final rawBanners = json['banners'] as List? ?? [];
    final rawStores = json['stores'] as List? ?? [];
    return AppConfigModel(
      storeName: branding['store_name'] ?? AppConfig.storeName,
      tagline: branding['tagline'] ?? 'Fresh groceries, less fuss',
      logoUrl: (branding['logo_url'] ?? '').toString(),
      contactEmail: (branding['contact_email'] ?? '').toString(),
      contactPhone: (branding['contact_phone'] ?? '').toString(),
      contactAddress: (branding['contact_address'] ?? '').toString(),
      stripePublishableKey: (json['stripe_publishable_key'] ?? '').toString(),
      currency: (json['currency'] ?? 'usd').toString().toUpperCase(),
      otpEnabled: json['otp_enabled'] ?? true,
      codEnabled: json['cod_enabled'] ?? true,
      enforceRadius: json['enforce_radius'] ?? true,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 2.99,
      freeDeliveryThreshold: (json['free_delivery_threshold'] as num?)?.toDouble() ?? 15.0,
      banners: rawBanners.map((b) => PromoBanner.fromJson(b)).toList(),
      stores: rawStores.map((s) => StoreModel.fromJson(s)).toList(),
    );
  }
}
