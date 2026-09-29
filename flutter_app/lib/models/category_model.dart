import '../config.dart';
class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String icon;
  final String badgeColor;
  final String? imageUrl;

  CategoryModel({
    required this.id,
    required this.name,
    this.slug = '',
    required this.icon,
    this.badgeColor = '0xFFE8F5E9',
    this.imageUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final slug = json['slug']?.toString() ?? '';
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

    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Category',
      slug: slug,
      icon: _getEmojiForCategory(slug, json['name']?.toString() ?? ''),
      badgeColor: '0xFFE8F5E9',
      imageUrl: fullImg,
    );
  }

  static String _getEmojiForCategory(String slug, String name) {
    final s = slug.toLowerCase();
    final n = name.toLowerCase();
    if (s.contains('produce') || n.contains('fruit') || n.contains('veg')) return '🥦';
    if (s.contains('dairy') || n.contains('milk') || n.contains('egg')) return '🥛';
    if (s.contains('pantry') || n.contains('atta') || n.contains('dal')) return '🌾';
    if (s.contains('snack') || n.contains('munch')) return '🍿';
    if (s.contains('beverage') || n.contains('drink') || n.contains('juice')) return '🧃';
    if (s.contains('bakery') || n.contains('biscuit') || n.contains('bread')) return '🍞';
    if (s.contains('sweet') || n.contains('chocolate')) return '🍫';
    if (s.contains('meat') || n.contains('chicken') || n.contains('fish')) return '🍗';
    if (s.contains('frozen')) return '🧊';
    if (s.contains('tea') || n.contains('coffee')) return '☕';
    if (s.contains('sauce') || n.contains('spread')) return '🍯';
    if (s.contains('clean')) return '🧼';
    if (s.contains('personal') || n.contains('care')) return '🧴';
    if (s.contains('baby')) return '🍼';
    if (s.contains('home') || n.contains('kitchen')) return '🏡';
    if (s.contains('paan')) return '🍃';
    if (s.contains('pharma') || n.contains('well')) return '💊';
    if (s.contains('pet')) return '🐾';
    return '🛒';
  }
}
