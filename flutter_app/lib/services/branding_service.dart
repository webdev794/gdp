import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/config_model.dart';

/// Store branding + contact details from Admin -> Store settings (GET /api/config).
/// Cached on the device so the logo and name show instantly on the next launch.
class BrandingService {
  static const String _prefix = 'branding_';

  static String storeName = AppConfig.storeName;
  static String tagline = 'Fresh groceries, less fuss';
  static String logoUrl = '';
  static String contactEmail = '';
  static String contactPhone = '';
  static String contactAddress = 'Kakatown Highway, Margibi County, Kakata, Liberia';

  /// Store name for use inside sentences: "TUDEE SHOPPING CENTER" -> "Tudee Shopping Center".
  static String get proseName {
    if (storeName != storeName.toUpperCase()) return storeName;
    return storeName
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  /// Absolute URL for a media path the API returns (often "/api/media/file/...").
  static String absolute(String url) => AppConfig.media(url);

  static Future<void> init() async {
    try {
      final p = await SharedPreferences.getInstance();
      storeName = p.getString('${_prefix}store_name') ?? storeName;
      tagline = p.getString('${_prefix}tagline') ?? tagline;
      logoUrl = p.getString('${_prefix}logo_url') ?? logoUrl;
      contactEmail = p.getString('${_prefix}contact_email') ?? contactEmail;
      contactPhone = p.getString('${_prefix}contact_phone') ?? contactPhone;
      contactAddress = p.getString('${_prefix}contact_address') ?? contactAddress;
    } catch (_) {}
  }

  static Future<void> apply(AppConfigModel config) async {
    storeName = config.storeName;
    tagline = config.tagline;
    logoUrl = absolute(config.logoUrl);
    contactEmail = config.contactEmail;
    contactPhone = config.contactPhone;
    if (config.contactAddress.isNotEmpty) contactAddress = config.contactAddress;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('${_prefix}store_name', storeName);
      await p.setString('${_prefix}tagline', tagline);
      await p.setString('${_prefix}logo_url', logoUrl);
      await p.setString('${_prefix}contact_email', contactEmail);
      await p.setString('${_prefix}contact_phone', contactPhone);
      await p.setString('${_prefix}contact_address', contactAddress);
    } catch (_) {}
  }
}

/// The store logo set in Admin -> Store settings, falling back to the bundled one.
class BrandLogo extends StatelessWidget {
  final double height;

  const BrandLogo({super.key, this.height = 48});

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset('assets/brand/logo.png', height: height, fit: BoxFit.contain);
    if (BrandingService.logoUrl.isEmpty) return fallback;
    return Image.network(
      BrandingService.logoUrl,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (_, child, progress) => progress == null ? child : SizedBox(height: height),
    );
  }
}

/// Store address, email and phone — lines with no value are left out.
class StoreContactCard extends StatelessWidget {
  const StoreContactCard({super.key});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 12, color: Colors.black87, height: 1.4);
    Widget row(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(child: SelectableText(text, style: style)),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(BrandingService.proseName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        if (BrandingService.contactAddress.isNotEmpty) row(Icons.location_on_outlined, BrandingService.contactAddress),
        if (BrandingService.contactEmail.isNotEmpty) row(Icons.email_outlined, BrandingService.contactEmail),
        if (BrandingService.contactPhone.isNotEmpty) row(Icons.phone_outlined, BrandingService.contactPhone),
      ],
    );
  }
}
